const { randomUUID } = require('crypto');
const { getPool } = require('./pool');
const { generateGuestIdentity } = require('../auth/guest_name');
const { AVATAR_CATALOG } = require('./marketplace');

const BOT_AVATAR_IDS = AVATAR_CATALOG && AVATAR_CATALOG.length > 0
  ? AVATAR_CATALOG.map((a) => a.id)
  : ['default', 'blue', 'red', 'bronze', 'silver', 'joker-girl', 'violet-joker-girl', 'violet-queen', 'queen-of-heart', 'golden-king'];

const BOT_COUNTRIES = [
  'US', 'GB', 'FR', 'ES', 'PT', 'DE', 'IT', 'BR', 'MX', 'AR', 'CA', 'MA',
  'EG', 'DZ', 'TN', 'SA', 'AE', 'TR', 'RU', 'UA', 'PL', 'NL', 'SE', 'IN',
  'JP', 'KR', 'CN', 'AU', 'ZA', 'NG', 'CO', 'CL',
];

function getRandomBotCountry() {
  return BOT_COUNTRIES[Math.floor(Math.random() * BOT_COUNTRIES.length)];
}

function getRandomBotAvatarId() {
  return BOT_AVATAR_IDS[Math.floor(Math.random() * BOT_AVATAR_IDS.length)] || 'default';
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
  if (rows.length > 0) return;
  await conn.query(`ALTER TABLE \`${table}\` ADD COLUMN ${definition}`);
}

async function addIndexIfMissing(conn, table, indexName, indexSql) {
  const [rows] = await conn.query(
    `SELECT 1 AS ok
     FROM information_schema.STATISTICS
     WHERE TABLE_SCHEMA = DATABASE()
       AND TABLE_NAME = :table
       AND INDEX_NAME = :indexName
     LIMIT 1`,
    { table, indexName },
  );
  if (rows.length > 0) return;
  await conn.query(`ALTER TABLE \`${table}\` ADD ${indexSql}`);
}

/** Idempotent schema migration for bot player support. */
async function ensureBotSchema() {
  const pool = getPool();
  const conn = await pool.getConnection();
  try {
    await addColumnIfMissing(
      conn,
      'players',
      'is_bot',
      'is_bot TINYINT(1) NOT NULL DEFAULT 0',
    );
    await addIndexIfMissing(
      conn,
      'players',
      'idx_players_is_bot',
      'KEY idx_players_is_bot (is_bot)',
    );
    // Give existing players/bots without a country a random one (ranking schema
    // adds the column first). Real logins overwrite it via detected geo.
    const [bots] = await conn.query(
      `SELECT id FROM players WHERE country_code IS NULL`,
    );
    for (const row of bots) {
      await conn.query(`UPDATE players SET country_code = ? WHERE id = ?`, [
        getRandomBotCountry(),
        row.id,
      ]);
    }
  } finally {
    conn.release();
  }
}

/** A bot keeps one face: stored avatar, or a new random one saved for next time. */
async function stableBotAvatar(pool, row) {
  if (row.avatar_id && row.avatar_id !== 'default') return row.avatar_id;
  const avatarId = getRandomBotAvatarId();
  await pool.execute(
    `UPDATE players SET avatar_id = :avatarId WHERE id = :id`,
    { avatarId, id: row.id },
  );
  return avatarId;
}

function botUserFromRow(row, avatarId) {
  return {
    playerId: row.id,
    displayName: row.display_name || 'Bot',
    username: row.username || 'bot',
    avatarId,
    elo: row.elo ?? 1000,
    countryCode: row.country_code || null,
  };
}

function poolOrNull() {
  try {
    return getPool();
  } catch {
    return null;
  }
}

const botIdCache = new Map();

/** True when the player row is a bot (cached; bot ids never change kind). */
async function isBotPlayer(playerId) {
  if (!playerId) return false;
  if (botIdCache.has(playerId)) return botIdCache.get(playerId);
  const pool = poolOrNull();
  if (!pool) return playerId.startsWith('bot-');
  const [rows] = await pool.execute(
    `SELECT is_bot FROM players WHERE id = :playerId LIMIT 1`,
    { playerId },
  );
  const isBot = rows.length > 0 && Number(rows[0].is_bot) === 1;
  botIdCache.set(playerId, isBot);
  return isBot;
}

/** All bot users (id, name, elo, avatar, country). */
async function listBotUsers() {
  const pool = poolOrNull();
  if (!pool) return [];
  const [rows] = await pool.execute(
    `SELECT id, display_name, username, elo, avatar_id, country_code
     FROM players
     WHERE is_bot = 1`,
  );
  for (const row of rows) botIdCache.set(row.id, true);
  return rows.map((row) => botUserFromRow(row, row.avatar_id || 'default'));
}

/**
 * Acquire an idle bot user or create a new bot record in MySQL.
 * With [playerId], acquire that specific bot (e.g. a bot friend).
 * @param {Set<string>|Array<string>} activeBotPlayerIds
 * @param {{ playerId?: string }} [options]
 * @returns {Promise<{ playerId: string, displayName: string, username: string, avatarId: string, elo: number } | null>}
 */
async function acquireBotUser(activeBotPlayerIds = new Set(), { playerId = null } = {}) {
  const activeSet = activeBotPlayerIds instanceof Set
    ? activeBotPlayerIds
    : new Set(activeBotPlayerIds || []);

  const pool = poolOrNull();
  if (!pool) {
    if (playerId && activeSet.has(playerId)) return null;
    // In-memory fallback for tests without DB connection
    const id = playerId || `bot-${randomUUID()}`;
    const identity = generateGuestIdentity();
    return {
      playerId: id,
      displayName: identity.name,
      username: identity.username,
      avatarId: getRandomBotAvatarId(),
      elo: 1000,
    };
  }

  const [rows] = await pool.execute(
    `SELECT id, display_name, username, elo, avatar_id, country_code
     FROM players
     WHERE is_bot = 1
     ORDER BY last_seen_at ASC`,
  );

  if (playerId) {
    const wanted = rows.find((row) => row.id === playerId);
    if (!wanted || activeSet.has(playerId)) return null;
    await pool.execute(
      `UPDATE players SET last_seen_at = CURRENT_TIMESTAMP WHERE id = :id`,
      { id: wanted.id },
    );
    return botUserFromRow(wanted, await stableBotAvatar(pool, wanted));
  }

  const idleBots = rows.filter((row) => !activeSet.has(row.id));
  if (idleBots.length > 0) {
    const selected = idleBots[Math.floor(Math.random() * idleBots.length)];
    await pool.execute(
      `UPDATE players SET last_seen_at = CURRENT_TIMESTAMP WHERE id = :id`,
      { id: selected.id },
    );
    return botUserFromRow(selected, await stableBotAvatar(pool, selected));
  }

  // Create new bot player
  for (let attempt = 0; attempt < 5; attempt += 1) {
    const id = `bot-${randomUUID()}`;
    const identity = generateGuestIdentity();
    const avatarId = getRandomBotAvatarId();
    try {
      await pool.execute(
        `INSERT INTO players (
           id, display_name, username, auth_type, is_bot, elo, total_points, wins, losses, draws,
           country_code, avatar_id
         ) VALUES (
           :id, :displayName, :username, 'guest', 1, 1000, 0, 0, 0, 0, :countryCode, :avatarId
         )`,
        {
          id,
          displayName: identity.name,
          username: identity.username,
          countryCode: getRandomBotCountry(),
          avatarId,
        },
      );
      botIdCache.set(id, true);
      return {
        playerId: id,
        displayName: identity.name,
        username: identity.username,
        avatarId,
        elo: 1000,
      };
    } catch (err) {
      if (err.code === 'ER_DUP_ENTRY' && attempt < 4) {
        continue;
      }
      throw err;
    }
  }

  throw new Error('Failed to create bot user');
}

module.exports = {
  ensureBotSchema,
  acquireBotUser,
  isBotPlayer,
  listBotUsers,
};
