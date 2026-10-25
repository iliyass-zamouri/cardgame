const crypto = require('crypto');
const { getPool } = require('./pool');
const {
  getPlayerInventory,
  getAdRewardMoney,
  AVATAR_CATALOG,
  DECK_CATALOG,
  MONEY_PER_CHIP,
  STARTING_MONEY,
  AD_REWARD_DAILY_CAP,
} = require('./marketplace');
const { grantRewards, applyBalances } = require('./rewards');
const {
  BOOSTER_IDS,
  LIMITS,
  localDateOf,
  resolveOffset,
  computeStreakState,
  planClaim,
  applyClaim,
  pickCalendar,
  comebackStatus,
  buildDailyStatus,
  disabledStatus,
} = require('../daily_rewards');
const { activeBoostFromRow } = require('../boosts');

const ERROR_MESSAGES = {
  invalid_choice: 'choice must be rescue or restart',
  streak_broken: 'Your streak is broken. Rescue it or start over.',
  insufficient_funds: 'Not enough chips to rescue the streak',
  daily_disabled: 'Daily rewards are turned off',
  comeback_unavailable: 'No welcome-back bonus is available right now',
};

function withCode(code, message, details = {}) {
  return Object.assign(new Error(message), { code, details });
}

function toNumberOrNull(value) {
  return value == null ? null : Number(value);
}

function parseJson(value) {
  return typeof value === 'string' ? JSON.parse(value) : value;
}

/** The ids the admin may reference, from the same catalog the shop sells from. */
function rewardCatalog() {
  return {
    avatarIds: new Set(AVATAR_CATALOG.map((item) => item.id)),
    deckIds: new Set(DECK_CATALOG.map((item) => item.id)),
  };
}

/** Read-only catalog for the admin tab's pickers and its economy estimate. */
function rewardCatalogBody() {
  const pick = ({ id, name, price, currency }) => ({ id, name, price, currency });
  return {
    currencies: ['money', 'chips'],
    avatars: AVATAR_CATALOG.map(pick),
    decks: DECK_CATALOG.map(pick),
    boosters: BOOSTER_IDS,
    limits: LIMITS,
    moneyPerChip: MONEY_PER_CHIP,
    startingMoney: STARTING_MONEY,
    adRewardMoney: getAdRewardMoney(),
    adDailyCap: AD_REWARD_DAILY_CAP,
  };
}

async function ensureDailyRewardsSchema() {
  const pool = getPool();
  await pool.query(`
    CREATE TABLE IF NOT EXISTS daily_reward_state (
      player_id VARCHAR(64) NOT NULL PRIMARY KEY,
      streak_position TINYINT UNSIGNED NOT NULL DEFAULT 0,
      streak_count INT UNSIGNED NOT NULL DEFAULT 0,
      best_streak INT UNSIGNED NOT NULL DEFAULT 0,
      cycles_completed INT UNSIGNED NOT NULL DEFAULT 0,
      last_claim_local_date CHAR(10) NULL,
      last_claim_at_ms BIGINT NULL,
      tz_offset_minutes SMALLINT NULL,
      tz_changed_at_ms BIGINT NULL,
      last_comeback_at_ms BIGINT NULL,
      last_reminder_date CHAR(10) NULL,
      CONSTRAINT fk_drs_player FOREIGN KEY (player_id) REFERENCES players (id) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  `);
  await pool.query(`
    CREATE TABLE IF NOT EXISTS daily_reward_claims (
      id VARCHAR(64) NOT NULL PRIMARY KEY,
      player_id VARCHAR(64) NOT NULL,
      kind ENUM('daily', 'comeback') NOT NULL,
      local_date CHAR(10) NOT NULL,
      cycle_day TINYINT UNSIGNED NULL,
      calendar_id VARCHAR(40) NULL,
      boosted TINYINT(1) NOT NULL DEFAULT 0,
      rescue_chips INT UNSIGNED NOT NULL DEFAULT 0,
      freezes_used INT UNSIGNED NOT NULL DEFAULT 0,
      granted JSON NOT NULL,
      claimed_at_ms BIGINT NOT NULL,
      UNIQUE KEY uq_drc_player_kind_date (player_id, kind, local_date),
      KEY idx_drc_player_time (player_id, claimed_at_ms),
      CONSTRAINT fk_drc_player FOREIGN KEY (player_id) REFERENCES players (id) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  `);
  await pool.query(`
    CREATE TABLE IF NOT EXISTS player_boosters (
      player_id VARCHAR(64) NOT NULL,
      booster_id VARCHAR(32) NOT NULL,
      quantity INT UNSIGNED NOT NULL DEFAULT 0,
      active_until_ms BIGINT NOT NULL DEFAULT 0,
      PRIMARY KEY (player_id, booster_id),
      CONSTRAINT fk_pb_player FOREIGN KEY (player_id) REFERENCES players (id) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  `);
  // Fixes made from the admin tab's Players view, shown back on that player.
  await pool.query(`
    CREATE TABLE IF NOT EXISTS daily_reward_support_log (
      id VARCHAR(64) NOT NULL PRIMARY KEY,
      player_id VARCHAR(64) NOT NULL,
      action VARCHAR(32) NOT NULL,
      detail JSON NOT NULL,
      created_at_ms BIGINT NOT NULL,
      KEY idx_drsl_player_time (player_id, created_at_ms),
      CONSTRAINT fk_drsl_player FOREIGN KEY (player_id) REFERENCES players (id) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  `);
}

/**
 * Loads everything a streak decision needs. With `lock`, it takes row locks in
 * the order players, then streak state, then boosters. Every money or streak
 * writer uses that order, so the transactions cannot deadlock.
 */
async function loadDailyContext(db, playerId, { lock = false } = {}) {
  const suffix = lock ? 'FOR UPDATE' : '';
  const [players] = await db.execute(
    `SELECT money, chips, created_at FROM players WHERE id = :playerId LIMIT 1 ${suffix}`,
    { playerId },
  );
  if (players.length === 0) throw withCode('player_not_found', 'Player not found');
  const player = players[0];

  if (lock) {
    await db.execute(`INSERT IGNORE INTO daily_reward_state (player_id) VALUES (:playerId)`, {
      playerId,
    });
  }
  const [states] = await db.execute(
    `SELECT * FROM daily_reward_state WHERE player_id = :playerId ${suffix}`,
    { playerId },
  );
  const [boosters] = await db.execute(
    `SELECT booster_id, quantity, active_until_ms, active_from_ms, preset_id, percent, max_bonus FROM player_boosters
     WHERE player_id = :playerId ${suffix}`,
    { playerId },
  );

  const row = states[0] ?? null;
  const boosterRow = (id) => boosters.find((booster) => booster.booster_id === id);
  const freezes = Number(boosterRow('streak_freeze')?.quantity) || 0;
  const createdAtMs = new Date(player.created_at).getTime();

  return {
    money: Number(player.money) || 0,
    chips: Number(player.chips) || 0,
    storedOffset: row?.tz_offset_minutes ?? null,
    tzChangedAtMs: toNumberOrNull(row?.tz_changed_at_ms),
    coinBoostRow: boosterRow('coin_boost') ?? null,
    input: {
      position: row?.streak_position ?? 0,
      count: row?.streak_count ?? 0,
      best: row?.best_streak ?? 0,
      cycles: row?.cycles_completed ?? 0,
      lastDate: row?.last_claim_local_date ?? null,
      lastAtMs: toNumberOrNull(row?.last_claim_at_ms),
      lastComebackAtMs: toNumberOrNull(row?.last_comeback_at_ms),
      freezes,
      createdAtMs,
    },
  };
}

async function saveOffset(conn, playerId, offset) {
  await conn.execute(
    `UPDATE daily_reward_state SET tz_offset_minutes = :value, tz_changed_at_ms = :changedAtMs
     WHERE player_id = :playerId`,
    { playerId, value: offset.value, changedAtMs: offset.changedAtMs },
  );
}

async function storedDailyGrant(conn, playerId, localDate) {
  const [rows] = await conn.execute(
    `SELECT granted FROM daily_reward_claims
     WHERE player_id = :playerId AND kind = 'daily' AND local_date = :localDate
     LIMIT 1`,
    { playerId, localDate },
  );
  return rows[0] ? parseJson(rows[0].granted) : [];
}

/** The player-facing status for a loaded context. */
function statusFromContext(context, nowMs, offsetMinutes, config) {
  if (!config.enabled) return disabledStatus(nowMs, offsetMinutes);
  const streak = computeStreakState(context.input, nowMs, offsetMinutes, config);
  return buildDailyStatus({
    streak,
    calendar: pickCalendar(config, streak.localDate),
    config,
    nowMs,
    offsetMinutes,
    activeBoost: activeBoostFromRow(context.coinBoostRow, config.boosters.coin_boost.presets, nowMs),
    comeback: comebackStatus(context.input, nowMs, config),
  });
}

/** GET /daily-reward. A pure read: the reset happens on claim, not on read. */
async function getDailyRewardStatus({ playerId, nowMs, tzOffsetMinutes, config }) {
  const context = await loadDailyContext(getPool(), playerId);
  const offset = resolveOffset({
    requested: tzOffsetMinutes,
    stored: context.storedOffset,
    changedAtMs: context.tzChangedAtMs,
    nowMs,
  });
  return statusFromContext(context, nowMs, offset.value, config);
}

/**
 * POST /daily-reward/claim. Idempotent: a repeat in the same local day returns
 * the stored grant with `alreadyClaimed: true`. Balances, streak and claim
 * record all change in one transaction.
 */
async function claimDailyReward({
  playerId,
  nowMs,
  tzOffsetMinutes,
  boosted = false,
  choice = null,
  boostInventory = false,
  config,
  randomInt = crypto.randomInt,
}) {
  if (!config.enabled) throw withCode('daily_disabled', ERROR_MESSAGES.daily_disabled);

  const conn = await getPool().getConnection();
  try {
    await conn.beginTransaction();
    const context = await loadDailyContext(conn, playerId, { lock: true });
    const offset = resolveOffset({
      requested: tzOffsetMinutes,
      stored: context.storedOffset,
      changedAtMs: context.tzChangedAtMs,
      nowMs,
    });
    const streak = computeStreakState(context.input, nowMs, offset.value, config);

    if (streak.state === 'claimed') {
      await saveOffset(conn, playerId, offset);
      const granted = await storedDailyGrant(conn, playerId, context.input.lastDate);
      await conn.commit();
      return {
        alreadyClaimed: true,
        granted,
        status: await getDailyRewardStatus({ playerId, nowMs, tzOffsetMinutes, config }),
      };
    }

    const decision = planClaim(streak, choice);
    if (decision.error) {
      throw withCode(decision.error, ERROR_MESSAGES[decision.error] ?? decision.error, decision.details);
    }
    const { plan } = decision;
    if (plan.chipCost > context.chips) {
      throw withCode('insufficient_funds', ERROR_MESSAGES.insufficient_funds, {
        chipsNeeded: plan.chipCost,
      });
    }

    const calendar = pickCalendar(config, streak.localDate);
    const multiplier = boosted && config.adBoost.enabled ? config.adBoost.multiplier : 1;
    const grant = await grantRewards(conn, playerId, calendar.days[plan.nextDay - 1].rewards, {
      multiplier,
      nowMs,
      chests: config.chests,
      boostPresets: config.boosters.coin_boost.presets,
      source: 'daily',
      autoActivateBoosts: !boostInventory,
      randomInt,
    });
    await applyBalances(conn, playerId, { money: grant.money, chips: grant.chips - plan.chipCost });

    const next = applyClaim(streak, plan);
    await conn.execute(
      `UPDATE daily_reward_state
       SET streak_position = :position, streak_count = :count, best_streak = :best,
           cycles_completed = :cycles, last_claim_local_date = :localDate,
           last_claim_at_ms = :nowMs, tz_offset_minutes = :offset, tz_changed_at_ms = :changedAtMs
       WHERE player_id = :playerId`,
      {
        playerId,
        position: next.position,
        count: next.count,
        best: next.best,
        cycles: next.cycles,
        localDate: streak.localDate,
        nowMs,
        offset: offset.value,
        changedAtMs: offset.changedAtMs,
      },
    );
    if (plan.freezesUsed > 0) {
      await conn.execute(
        `UPDATE player_boosters SET quantity = quantity - :used
         WHERE player_id = :playerId AND booster_id = 'streak_freeze'`,
        { playerId, used: plan.freezesUsed },
      );
    }
    await conn.execute(
      `INSERT INTO daily_reward_claims
         (id, player_id, kind, local_date, cycle_day, calendar_id, boosted, rescue_chips,
          freezes_used, granted, claimed_at_ms)
       VALUES
         (:id, :playerId, 'daily', :localDate, :cycleDay, :calendarId, :boosted, :rescueChips,
          :freezesUsed, :granted, :nowMs)`,
      {
        id: `daily-${crypto.randomUUID()}`,
        playerId,
        localDate: streak.localDate,
        cycleDay: plan.nextDay,
        calendarId: calendar.id,
        boosted: multiplier > 1 ? 1 : 0,
        rescueChips: plan.chipCost,
        freezesUsed: plan.freezesUsed,
        granted: JSON.stringify(grant.granted),
        nowMs,
      },
    );
    await conn.commit();

    const inventory = await getPlayerInventory(playerId);
    return {
      alreadyClaimed: false,
      day: plan.nextDay,
      calendarId: calendar.id,
      boosted: multiplier > 1,
      granted: grant.granted,
      chipsSpent: plan.chipCost,
      freezesUsed: plan.freezesUsed,
      graceUsed: plan.graceUsed,
      rescued: plan.rescued,
      streakReset: !plan.continues,
      streak: { count: next.count, best: next.best, position: next.position, cycle: next.cycles },
      money: inventory.money,
      chips: inventory.chips,
      ownedAvatars: inventory.ownedAvatars,
      ownedDecks: inventory.ownedDecks,
      status: await getDailyRewardStatus({ playerId, nowMs, tzOffsetMinutes, config }),
    };
  } catch (error) {
    await conn.rollback().catch(() => {});
    throw error;
  } finally {
    conn.release();
  }
}

/** POST /daily-reward/comeback/claim. One bonus per cooldown, separate from the streak. */
async function claimComeback({
  playerId,
  nowMs,
  tzOffsetMinutes,
  boostInventory = false,
  config,
  randomInt = crypto.randomInt,
}) {
  if (!config.enabled || !config.comeback.enabled) {
    throw withCode('comeback_unavailable', ERROR_MESSAGES.comeback_unavailable);
  }

  const conn = await getPool().getConnection();
  try {
    await conn.beginTransaction();
    const context = await loadDailyContext(conn, playerId, { lock: true });
    const offset = resolveOffset({
      requested: tzOffsetMinutes,
      stored: context.storedOffset,
      changedAtMs: context.tzChangedAtMs,
      nowMs,
    });
    const comeback = comebackStatus(context.input, nowMs, config);
    if (!comeback.available) {
      throw withCode('comeback_unavailable', ERROR_MESSAGES.comeback_unavailable);
    }

    const grant = await grantRewards(conn, playerId, comeback.rewards, {
      multiplier: 1,
      nowMs,
      chests: config.chests,
      boostPresets: config.boosters.coin_boost.presets,
      source: 'comeback',
      autoActivateBoosts: !boostInventory,
      randomInt,
    });
    await applyBalances(conn, playerId, { money: grant.money, chips: grant.chips });
    await saveOffset(conn, playerId, offset);
    await conn.execute(
      `UPDATE daily_reward_state SET last_comeback_at_ms = :nowMs WHERE player_id = :playerId`,
      { playerId, nowMs },
    );
    await conn.execute(
      `INSERT INTO daily_reward_claims
         (id, player_id, kind, local_date, boosted, rescue_chips, freezes_used, granted, claimed_at_ms)
       VALUES (:id, :playerId, 'comeback', :localDate, 0, 0, 0, :granted, :nowMs)`,
      {
        id: `daily-${crypto.randomUUID()}`,
        playerId,
        localDate: localDateOf(nowMs, offset.value),
        granted: JSON.stringify(grant.granted),
        nowMs,
      },
    );
    await conn.commit();

    const inventory = await getPlayerInventory(playerId);
    return {
      granted: grant.granted,
      money: inventory.money,
      chips: inventory.chips,
      ownedAvatars: inventory.ownedAvatars,
      ownedDecks: inventory.ownedDecks,
      status: await getDailyRewardStatus({ playerId, nowMs, tzOffsetMinutes, config }),
    };
  } catch (error) {
    await conn.rollback().catch(() => {});
    throw error;
  } finally {
    conn.release();
  }
}

module.exports = {
  ensureDailyRewardsSchema,
  rewardCatalog,
  rewardCatalogBody,
  loadDailyContext,
  statusFromContext,
  getDailyRewardStatus,
  claimDailyReward,
  claimComeback,
};
