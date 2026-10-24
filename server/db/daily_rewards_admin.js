// Queries behind the admin "Daily rewards" tab: Performance stats, the
// Players lookup, and the support fixes made from it.

const crypto = require('crypto');
const { getPool } = require('./pool');
const { fillDays } = require('../admin/stats');
const { grantRewards } = require('./rewards');
const { loadDailyContext, statusFromContext } = require('./daily_rewards');
const { CYCLE_DAYS, addDays, computeStreakState, planRestore } = require('../daily_rewards');

const DAY_MS = 86_400_000;
const STREAK_BUCKETS = ['1-2', '3-6', '7-13', '14-29', '30+'];

function withCode(code, message, details = {}) {
  return Object.assign(new Error(message), { code, details });
}

function n(value) {
  return Number(value) || 0;
}

function parseJson(value) {
  return typeof value === 'string' ? JSON.parse(value) : value;
}

function toIso(value) {
  if (value == null) return null;
  return value instanceof Date ? value.toISOString() : String(value);
}

/** Fills the gaps so every chart has a point for each day, cycle day and bucket. */
function shapeDailyStats({ totals, comebacks, byDay, byCycleDay, streaks, reach }, days) {
  const perCycleDay = new Map(byCycleDay.map((row) => [n(row.day), n(row.claims)]));
  const perBucket = new Map(streaks.map((row) => [row.bucket, n(row.players)]));
  return {
    days,
    totals: {
      claims: n(totals.claims),
      claimers: n(totals.claimers),
      boosted: n(totals.boosted),
      rescues: n(totals.rescues),
      rescueChips: n(totals.rescueChips),
      freezesUsed: n(totals.freezesUsed),
      comebacks: n(comebacks),
    },
    reach: {
      claimers24h: n(reach.claimers24h),
      active24h: n(reach.active24h),
      claimers7d: n(reach.claimers7d),
      active7d: n(reach.active7d),
    },
    byDay: fillDays(byDay, days, ['claims', 'boosted', 'rescued']),
    byCycleDay: Array.from({ length: CYCLE_DAYS }, (_, index) => ({
      day: index + 1,
      claims: perCycleDay.get(index + 1) ?? 0,
    })),
    streaks: STREAK_BUCKETS.map((bucket) => ({ bucket, players: perBucket.get(bucket) ?? 0 })),
  };
}

/** Performance view. Day series use the player's local day. */
async function getDailyRewardStats({ nowMs, days = 30 }) {
  const span = Math.min(90, Math.max(7, Math.round(Number(days)) || 30));
  const sinceMs = nowMs - span * DAY_MS;
  const weekAgoMs = nowMs - 7 * DAY_MS;
  const pool = getPool();

  const [[totals]] = await pool.execute(
    `SELECT COUNT(*) AS claims,
            COUNT(DISTINCT player_id) AS claimers,
            COALESCE(SUM(boosted), 0) AS boosted,
            COALESCE(SUM(rescue_chips > 0), 0) AS rescues,
            COALESCE(SUM(rescue_chips), 0) AS rescueChips,
            COALESCE(SUM(freezes_used), 0) AS freezesUsed
     FROM daily_reward_claims
     WHERE kind = 'daily' AND claimed_at_ms >= :sinceMs`,
    { sinceMs },
  );
  const [[{ comebacks }]] = await pool.execute(
    `SELECT COUNT(*) AS comebacks FROM daily_reward_claims
     WHERE kind = 'comeback' AND claimed_at_ms >= :sinceMs`,
    { sinceMs },
  );
  // Each claim lands in one series: a rescued claim counts as rescued even if it was boosted.
  const [byDay] = await pool.execute(
    `SELECT local_date AS day,
            COUNT(*) AS claims,
            COALESCE(SUM(boosted = 1 AND rescue_chips = 0), 0) AS boosted,
            COALESCE(SUM(rescue_chips > 0), 0) AS rescued
     FROM daily_reward_claims
     WHERE kind = 'daily' AND claimed_at_ms >= :sinceMs
     GROUP BY local_date`,
    { sinceMs },
  );
  const [byCycleDay] = await pool.execute(
    `SELECT cycle_day AS day, COUNT(*) AS claims FROM daily_reward_claims
     WHERE kind = 'daily' AND claimed_at_ms >= :sinceMs
     GROUP BY cycle_day`,
    { sinceMs },
  );
  const [streaks] = await pool.execute(
    `SELECT CASE
              WHEN streak_count >= 30 THEN '30+'
              WHEN streak_count >= 14 THEN '14-29'
              WHEN streak_count >= 7 THEN '7-13'
              WHEN streak_count >= 3 THEN '3-6'
              ELSE '1-2'
            END AS bucket,
            COUNT(*) AS players
     FROM daily_reward_state
     WHERE streak_count > 0 AND last_claim_at_ms >= :weekAgoMs
     GROUP BY bucket`,
    { weekAgoMs },
  );
  const [[claimers]] = await pool.execute(
    `SELECT COUNT(DISTINCT CASE WHEN claimed_at_ms >= :dayAgoMs THEN player_id END) AS claimers24h,
            COUNT(DISTINCT player_id) AS claimers7d
     FROM daily_reward_claims
     WHERE kind = 'daily' AND claimed_at_ms >= :weekAgoMs`,
    { dayAgoMs: nowMs - DAY_MS, weekAgoMs },
  );
  // Same definition as the Overview's DAU and WAU in server/admin/stats.js.
  const [[active]] = await pool.execute(
    `SELECT COALESCE(SUM(is_bot = 0 AND last_seen_at >= UTC_TIMESTAMP() - INTERVAL 1 DAY), 0) AS active24h,
            COALESCE(SUM(is_bot = 0 AND last_seen_at >= UTC_TIMESTAMP() - INTERVAL 7 DAY), 0) AS active7d
     FROM players`,
  );

  return shapeDailyStats(
    { totals, comebacks, byDay, byCycleDay, streaks, reach: { ...claimers, ...active } },
    span,
  );
}

/** Players view: one player's streak, recent claims and support history. */
async function getDailyRewardPlayer({ playerId, nowMs, config, debug = false }) {
  const pool = getPool();
  const [players] = await pool.execute(
    `SELECT id, display_name, username, money, chips, is_bot, created_at, last_seen_at
     FROM players WHERE id = :playerId LIMIT 1`,
    { playerId },
  );
  if (players.length === 0) throw withCode('player_not_found', 'Player not found');
  const player = players[0];

  const context = await loadDailyContext(pool, playerId);
  const [claims] = await pool.execute(
    `SELECT kind, local_date, cycle_day, calendar_id, boosted, rescue_chips, freezes_used,
            granted, claimed_at_ms
     FROM daily_reward_claims WHERE player_id = :playerId
     ORDER BY claimed_at_ms DESC LIMIT 15`,
    { playerId },
  );
  const [support] = await pool.execute(
    `SELECT action, detail, created_at_ms FROM daily_reward_support_log
     WHERE player_id = :playerId ORDER BY created_at_ms DESC LIMIT 20`,
    { playerId },
  );

  const { input } = context;
  return {
    debug,
    player: {
      id: player.id,
      name: player.display_name ?? null,
      username: player.username ?? null,
      money: n(player.money),
      chips: n(player.chips),
      isBot: Boolean(player.is_bot),
      createdAt: toIso(player.created_at),
      lastSeenAt: toIso(player.last_seen_at),
    },
    streak: {
      position: input.position,
      count: input.count,
      best: input.best,
      cycles: input.cycles,
      lastClaimDate: input.lastDate,
      lastClaimAtMs: input.lastAtMs,
      lastComebackAtMs: input.lastComebackAtMs,
      tzOffsetMinutes: context.storedOffset,
      freezes: input.freezes,
      coinBoostRemainingSeconds: Math.max(0, Math.ceil((context.coinBoostUntilMs - nowMs) / 1000)),
    },
    // The player's own clock, as their app would see it.
    status: statusFromContext(context, nowMs, context.storedOffset ?? 0, config),
    claims: claims.map((row) => ({
      kind: row.kind,
      localDate: row.local_date,
      cycleDay: row.cycle_day,
      calendarId: row.calendar_id,
      boosted: Boolean(row.boosted),
      rescueChips: n(row.rescue_chips),
      freezesUsed: n(row.freezes_used),
      granted: parseJson(row.granted),
      claimedAtMs: n(row.claimed_at_ms),
    })),
    support: support.map((row) => ({
      action: row.action,
      detail: parseJson(row.detail),
      createdAtMs: n(row.created_at_ms),
    })),
  };
}

async function runSupportAction(conn, { playerId, action, quantity, days, nowMs, config, context }) {
  const { input } = context;

  if (action === 'restore') {
    const offset = context.storedOffset ?? 0;
    const streak = computeStreakState(input, nowMs, offset, config);
    const restored = planRestore(streak, nowMs, offset, config);
    if (restored.error) {
      throw withCode('streak_not_broken', 'This streak is not broken, so there is nothing to restore');
    }
    await conn.execute(
      `UPDATE daily_reward_state
       SET last_claim_local_date = :lastDate, last_claim_at_ms = :lastAtMs
       WHERE player_id = :playerId`,
      { playerId, lastDate: restored.lastDate, lastAtMs: restored.lastAtMs },
    );
    return { from: input.lastDate, to: restored.lastDate, day: streak.lastDay, count: streak.count };
  }

  if (action === 'gift_freeze') {
    await grantRewards(conn, playerId, [{ type: 'booster', boosterId: 'streak_freeze', quantity }], {
      nowMs,
    });
    return { quantity, freezes: input.freezes + quantity };
  }

  if (action === 'shift_days') {
    const shiftMs = days * DAY_MS;
    const earlier = (ms) => (ms == null ? null : ms - shiftMs);
    await conn.execute(
      `UPDATE daily_reward_state
       SET last_claim_local_date = :lastDate, last_claim_at_ms = :lastAtMs,
           last_comeback_at_ms = :lastComebackAtMs, tz_changed_at_ms = :tzChangedAtMs
       WHERE player_id = :playerId`,
      {
        playerId,
        lastDate: input.lastDate ? addDays(input.lastDate, -days) : null,
        lastAtMs: earlier(input.lastAtMs),
        lastComebackAtMs: earlier(input.lastComebackAtMs),
        tzChangedAtMs: earlier(context.tzChangedAtMs),
      },
    );
    // Oldest first, so no row lands on a date that another row still holds.
    await conn.execute(
      `UPDATE daily_reward_claims
       SET local_date = DATE_FORMAT(DATE_SUB(STR_TO_DATE(local_date, '%Y-%m-%d'), INTERVAL :days DAY), '%Y-%m-%d'),
           claimed_at_ms = claimed_at_ms - :shiftMs
       WHERE player_id = :playerId
       ORDER BY local_date ASC`,
      { playerId, days, shiftMs },
    );
    await conn.execute(
      `UPDATE player_boosters SET active_until_ms = GREATEST(0, active_until_ms - :shiftMs)
       WHERE player_id = :playerId AND active_until_ms > 0`,
      { playerId, shiftMs },
    );
    return { days };
  }

  // reset: the support log keeps its rows, so the history survives.
  await conn.execute(`DELETE FROM daily_reward_claims WHERE player_id = :playerId`, { playerId });
  await conn.execute(`DELETE FROM player_boosters WHERE player_id = :playerId`, { playerId });
  await conn.execute(`DELETE FROM daily_reward_state WHERE player_id = :playerId`, { playerId });
  return { cleared: true };
}

/**
 * One support fix, in a transaction with the usual lock order (players, then
 * streak state, then boosters), logged on the player. Returns what changed.
 */
async function applySupportAction({ playerId, action, quantity, days, nowMs, config }) {
  const conn = await getPool().getConnection();
  try {
    await conn.beginTransaction();
    const context = await loadDailyContext(conn, playerId, { lock: true });
    const detail = await runSupportAction(conn, {
      playerId,
      action,
      quantity,
      days,
      nowMs,
      config,
      context,
    });
    await conn.execute(
      `INSERT INTO daily_reward_support_log (id, player_id, action, detail, created_at_ms)
       VALUES (:id, :playerId, :action, :detail, :nowMs)`,
      { id: `support-${crypto.randomUUID()}`, playerId, action, detail: JSON.stringify(detail), nowMs },
    );
    await conn.commit();
    console.log('[admin/daily-rewards] support', { playerId, action, ...detail });
    return detail;
  } catch (error) {
    await conn.rollback().catch(() => {});
    throw error;
  } finally {
    conn.release();
  }
}

module.exports = {
  shapeDailyStats,
  getDailyRewardStats,
  getDailyRewardPlayer,
  applySupportAction,
};
