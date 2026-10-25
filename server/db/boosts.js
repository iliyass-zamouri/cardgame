const crypto = require('crypto');
const { getPool } = require('./pool');
const { findPreset, activeBoostFromRow, activationDecision, boostView, seatBoost } = require('../boosts');

const ERROR_MESSAGES = {
  boost_not_found: 'That boost is not in your inventory',
  boost_conflict: 'Another boost is running. It can start when that one ends.',
};

function withCode(code, message, details = {}) {
  return Object.assign(new Error(message), { code, details });
}

async function addColumnIfMissing(conn, table, column, definition) {
  const [rows] = await conn.query(
    `SELECT 1 AS ok
     FROM information_schema.COLUMNS
     WHERE TABLE_SCHEMA = DATABASE()
       AND TABLE_NAME = :table
       AND COLUMN_NAME = :column
     LIMIT 1`,
    { table, column },
  );
  if (rows.length > 0) return false;
  await conn.query(`ALTER TABLE \`${table}\` ADD COLUMN ${definition}`);
  return true;
}

/**
 * The `player_boosters` coin_boost row is the running boost. It keeps the
 * value it was activated with. `player_boost_items` holds the boosts waiting
 * to be activated, one row per reward. Runs after the daily rewards schema.
 */
async function ensureBoostsSchema() {
  const pool = getPool();
  const conn = await pool.getConnection();
  try {
    await addColumnIfMissing(conn, 'player_boosters', 'preset_id', 'preset_id VARCHAR(32) NULL');
    await addColumnIfMissing(conn, 'player_boosters', 'percent', 'percent TINYINT UNSIGNED NULL');
    await addColumnIfMissing(conn, 'player_boosters', 'max_bonus', 'max_bonus INT UNSIGNED NULL');
    await addColumnIfMissing(conn, 'player_boosters', 'active_from_ms', 'active_from_ms BIGINT NULL');
  } finally {
    conn.release();
  }
  await pool.query(`
    CREATE TABLE IF NOT EXISTS player_boost_items (
      id VARCHAR(64) NOT NULL PRIMARY KEY,
      player_id VARCHAR(64) NOT NULL,
      preset_id VARCHAR(32) NOT NULL,
      percent TINYINT UNSIGNED NOT NULL,
      max_bonus INT UNSIGNED NOT NULL,
      minutes INT UNSIGNED NOT NULL,
      source VARCHAR(16) NOT NULL,
      granted_at_ms BIGINT NOT NULL,
      KEY idx_pbi_player (player_id, granted_at_ms),
      CONSTRAINT fk_pbi_player FOREIGN KEY (player_id) REFERENCES players (id) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  `);
}

function presetsOf(config) {
  return config.boosters.coin_boost.presets;
}

async function readActiveRow(db, playerId, { lock = false } = {}) {
  const [rows] = await db.execute(
    `SELECT active_until_ms, active_from_ms, preset_id, percent, max_bonus FROM player_boosters
     WHERE player_id = :playerId AND booster_id = 'coin_boost' ${lock ? 'FOR UPDATE' : ''}`,
    { playerId },
  );
  return rows[0] ?? null;
}

/** Runs `item` now, or adds its time to the running boost of the same value. */
async function runItem(conn, playerId, item, active, nowMs) {
  const decision = activationDecision(active, item, nowMs);
  if (decision.action === 'conflict') return decision;
  // An extension keeps the run's start, so the whole run reads as one.
  const fromMs = decision.action === 'extend' ? active.fromMs ?? nowMs : nowMs;
  await conn.execute(
    `INSERT INTO player_boosters
       (player_id, booster_id, quantity, active_until_ms, active_from_ms, preset_id, percent, max_bonus)
     VALUES (:playerId, 'coin_boost', 0, :untilMs, :fromMs, :presetId, :percent, :maxBonus) AS new
     ON DUPLICATE KEY UPDATE active_until_ms = new.active_until_ms, active_from_ms = new.active_from_ms,
       preset_id = new.preset_id, percent = new.percent, max_bonus = new.max_bonus`,
    {
      playerId,
      untilMs: decision.untilMs,
      fromMs,
      presetId: item.presetId,
      percent: item.percent,
      maxBonus: item.maxBonus,
    },
  );
  return decision;
}

/**
 * Adds a Coin Boost reward to the inventory inside the caller's transaction.
 * The caller holds the player's boosters lock (see loadDailyContext). With
 * `autoActivate` (app builds from before the inventory), a boost that fits
 * the running one starts at once, as it used to.
 */
async function grantBoostItem(conn, playerId, reward, { presets, nowMs, source, autoActivate = false }) {
  const preset = findPreset(presets, reward.presetId) ?? presets[0];
  const item = {
    presetId: preset.id,
    percent: preset.percent,
    maxBonus: preset.maxBonus,
    minutes: reward.minutes,
  };
  const entry = {
    type: 'booster',
    boosterId: 'coin_boost',
    presetId: preset.id,
    percent: preset.percent,
    maxBonus: preset.maxBonus,
    tier: preset.tier,
    minutes: reward.minutes,
  };

  if (autoActivate) {
    const active = activeBoostFromRow(await readActiveRow(conn, playerId, { lock: true }), presets, nowMs);
    const decision = await runItem(conn, playerId, item, active, nowMs);
    if (decision.action !== 'conflict') return { ...entry, activated: true, activeUntilMs: decision.untilMs };
  }

  const itemId = `boost-${crypto.randomUUID()}`;
  await conn.execute(
    `INSERT INTO player_boost_items (id, player_id, preset_id, percent, max_bonus, minutes, source, granted_at_ms)
     VALUES (:id, :playerId, :presetId, :percent, :maxBonus, :minutes, :source, :nowMs)`,
    { id: itemId, playerId, ...item, source, nowMs },
  );
  return { ...entry, itemId, activated: false };
}

async function viewFor(db, playerId, config, nowMs) {
  const presets = presetsOf(config);
  const active = activeBoostFromRow(await readActiveRow(db, playerId), presets, nowMs);
  const [items] = await db.execute(
    `SELECT id, preset_id, percent, max_bonus, minutes FROM player_boost_items
     WHERE player_id = :playerId ORDER BY granted_at_ms, id`,
    { playerId },
  );
  return boostView({ active, items, presets, nowMs });
}

/** GET /boosts. */
async function getBoosts({ playerId, nowMs, config }) {
  return viewFor(getPool(), playerId, config, nowMs);
}

/**
 * POST /boosts/activate. Locks the running boost, then the item, the same
 * order a claim takes, so the two cannot deadlock.
 */
async function activateBoost({ playerId, itemId, nowMs, config }) {
  const presets = presetsOf(config);
  const conn = await getPool().getConnection();
  try {
    await conn.beginTransaction();
    await conn.execute(
      `INSERT IGNORE INTO player_boosters (player_id, booster_id, quantity, active_until_ms)
       VALUES (:playerId, 'coin_boost', 0, 0)`,
      { playerId },
    );
    const active = activeBoostFromRow(await readActiveRow(conn, playerId, { lock: true }), presets, nowMs);
    const [rows] = await conn.execute(
      `SELECT id, preset_id, percent, max_bonus, minutes FROM player_boost_items
       WHERE id = :itemId AND player_id = :playerId FOR UPDATE`,
      { itemId, playerId },
    );
    if (rows.length === 0) throw withCode('boost_not_found', ERROR_MESSAGES.boost_not_found);
    const row = rows[0];
    const item = {
      presetId: row.preset_id,
      percent: Number(row.percent),
      maxBonus: Number(row.max_bonus),
      minutes: Number(row.minutes),
    };

    const decision = await runItem(conn, playerId, item, active, nowMs);
    if (decision.action === 'conflict') {
      await conn.rollback();
      throw withCode('boost_conflict', ERROR_MESSAGES.boost_conflict, {
        boosts: await viewFor(getPool(), playerId, config, nowMs),
      });
    }
    await conn.execute(`DELETE FROM player_boost_items WHERE id = :itemId`, { itemId });
    await conn.commit();
    return {
      action: decision.action,
      minutes: item.minutes,
      boosts: await viewFor(getPool(), playerId, config, nowMs),
    };
  } catch (error) {
    await conn.rollback().catch(() => {});
    throw error;
  } finally {
    conn.release();
  }
}

/**
 * The boost each player carries into a money match, keyed by player id. Read
 * at kickoff, so a boost that ends mid-match still pays that match.
 */
async function seatBoostsFor(playerIds, { nowMs, config }) {
  const ids = playerIds.filter(Boolean);
  if (ids.length === 0) return {};
  const presets = presetsOf(config);
  const params = Object.fromEntries(ids.map((id, index) => [`id${index}`, id]));
  const [rows] = await getPool().execute(
    `SELECT player_id, active_until_ms, preset_id, percent, max_bonus FROM player_boosters
     WHERE booster_id = 'coin_boost' AND player_id IN (${Object.keys(params).map((key) => `:${key}`).join(', ')})`,
    params,
  );
  const out = {};
  for (const row of rows) {
    const boost = seatBoost(activeBoostFromRow(row, presets, nowMs));
    if (boost) out[row.player_id] = boost;
  }
  return out;
}

module.exports = {
  ensureBoostsSchema,
  readActiveRow,
  grantBoostItem,
  getBoosts,
  activateBoost,
  seatBoostsFor,
};
