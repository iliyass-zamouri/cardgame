const { getPool } = require('./pool');
const { DAY_MS } = require('../app_review');

/**
 * app_reviews keeps every rating (a player re-prompted later gets a new row).
 * app_review_state is one row per player, made the first time an app build
 * with the rating prompt asks for its status, so a row also means "this
 * player's app can open /rate". app_review_events feeds the admin funnel.
 */
async function ensureAppReviewSchema() {
  const pool = getPool();
  await pool.query(`
    CREATE TABLE IF NOT EXISTS app_reviews (
      id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
      player_id VARCHAR(64) NOT NULL,
      stars TINYINT UNSIGNED NOT NULL,
      tags VARCHAR(128) NULL,
      comment VARCHAR(1000) NULL,
      trigger_source VARCHAR(16) NOT NULL,
      platform VARCHAR(16) NOT NULL,
      app_version VARCHAR(32) NULL,
      locale CHAR(2) NOT NULL DEFAULT 'en',
      store_redirected TINYINT(1) NOT NULL DEFAULT 0,
      handled TINYINT(1) NOT NULL DEFAULT 0,
      created_at_ms BIGINT NOT NULL,
      feedback_at_ms BIGINT NULL,
      KEY idx_ar_time (created_at_ms),
      KEY idx_ar_stars_time (stars, created_at_ms),
      KEY idx_ar_player (player_id, created_at_ms),
      CONSTRAINT fk_ar_player FOREIGN KEY (player_id) REFERENCES players (id) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  `);
  await pool.query(`
    CREATE TABLE IF NOT EXISTS app_review_state (
      player_id VARCHAR(64) NOT NULL PRIMARY KEY,
      platform VARCHAR(16) NOT NULL,
      app_version VARCHAR(32) NULL,
      locale CHAR(2) NOT NULL DEFAULT 'en',
      prompts_shown INT UNSIGNED NOT NULL DEFAULT 0,
      last_prompt_at_ms BIGINT NULL,
      last_dismissed_at_ms BIGINT NULL,
      last_stars TINYINT UNSIGNED NULL,
      last_rated_at_ms BIGINT NULL,
      last_redirected_at_ms BIGINT NULL,
      push_sent_at_ms BIGINT NULL,
      push_opened_at_ms BIGINT NULL,
      updated_at_ms BIGINT NOT NULL,
      KEY idx_ars_push (push_sent_at_ms, last_rated_at_ms),
      CONSTRAINT fk_ars_player FOREIGN KEY (player_id) REFERENCES players (id) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  `);
  await pool.query(`
    CREATE TABLE IF NOT EXISTS app_review_events (
      id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
      player_id VARCHAR(64) NOT NULL,
      kind VARCHAR(16) NOT NULL,
      trigger_source VARCHAR(16) NULL,
      at_ms BIGINT NOT NULL,
      KEY idx_are_kind_time (kind, at_ms),
      CONSTRAINT fk_are_player FOREIGN KEY (player_id) REFERENCES players (id) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  `);
}

function numberOrNull(value) {
  return value == null ? null : Number(value);
}

function mapState(row) {
  if (!row) return null;
  return {
    platform: row.platform,
    appVersion: row.app_version,
    locale: row.locale,
    promptsShown: Number(row.prompts_shown),
    lastPromptAtMs: numberOrNull(row.last_prompt_at_ms),
    lastDismissedAtMs: numberOrNull(row.last_dismissed_at_ms),
    lastStars: numberOrNull(row.last_stars),
    lastRatedAtMs: numberOrNull(row.last_rated_at_ms),
    lastRedirectedAtMs: numberOrNull(row.last_redirected_at_ms),
    pushSentAtMs: numberOrNull(row.push_sent_at_ms),
    pushOpenedAtMs: numberOrNull(row.push_opened_at_ms),
  };
}

/**
 * Records the device facts and returns what the eligibility rules read.
 * Null when the player doesn't exist.
 */
async function touchReviewState(playerId, { platform, appVersion, locale }, nowMs) {
  const pool = getPool();
  await pool.execute(
    `INSERT INTO app_review_state (player_id, platform, app_version, locale, updated_at_ms)
     SELECT id, :platform, :appVersion, :locale, :nowMs FROM players WHERE id = :playerId
     ON DUPLICATE KEY UPDATE
       platform = VALUES(platform),
       app_version = VALUES(app_version),
       locale = VALUES(locale),
       updated_at_ms = VALUES(updated_at_ms)`,
    { playerId, platform, appVersion, locale, nowMs },
  );
  const [rows] = await pool.execute(
    `SELECT p.wins, p.losses, p.draws, UNIX_TIMESTAMP(p.created_at) AS created_s, s.*
     FROM players p
     LEFT JOIN app_review_state s ON s.player_id = p.id
     WHERE p.id = :playerId
     LIMIT 1`,
    { playerId },
  );
  const row = rows[0];
  if (!row) return null;
  return {
    player: {
      matchesPlayed: Number(row.wins) + Number(row.losses) + Number(row.draws),
      wins: Number(row.wins),
      createdAtMs: row.created_s == null ? null : Math.round(Number(row.created_s) * 1000),
    },
    state: mapState(row.prompts_shown == null ? null : row),
  };
}

async function recordEvent(conn, playerId, kind, trigger, nowMs) {
  await conn.execute(
    `INSERT INTO app_review_events (player_id, kind, trigger_source, at_ms)
     VALUES (:playerId, :kind, :trigger, :nowMs)`,
    { playerId, kind, trigger: trigger ?? null, nowMs },
  );
}

/** The app put the prompt on screen. `counts` is false for prompts the player opened. */
async function recordPromptShown(playerId, trigger, counts, nowMs) {
  const pool = getPool();
  await pool.execute(
    `UPDATE app_review_state
     SET prompts_shown = prompts_shown + :increment, last_prompt_at_ms = :nowMs, updated_at_ms = :nowMs
     WHERE player_id = :playerId`,
    { playerId, increment: counts ? 1 : 0, nowMs },
  );
  await recordEvent(pool, playerId, 'shown', trigger, nowMs);
}

async function recordDismiss(playerId, trigger, nowMs) {
  const pool = getPool();
  await pool.execute(
    `UPDATE app_review_state
     SET last_dismissed_at_ms = :nowMs, updated_at_ms = :nowMs
     WHERE player_id = :playerId`,
    { playerId, nowMs },
  );
  await recordEvent(pool, playerId, 'dismissed', trigger, nowMs);
}

async function recordPushOpened(playerId, nowMs) {
  const pool = getPool();
  const [result] = await pool.execute(
    `UPDATE app_review_state
     SET push_opened_at_ms = :nowMs, updated_at_ms = :nowMs
     WHERE player_id = :playerId AND push_sent_at_ms IS NOT NULL AND push_opened_at_ms IS NULL`,
    { playerId, nowMs },
  );
  if (result.affectedRows) await recordEvent(pool, playerId, 'push_opened', 'push', nowMs);
}

/** Last rating time, for the double-submit guard. */
async function lastRatedAtMs(playerId) {
  const [rows] = await getPool().execute(
    'SELECT last_rated_at_ms FROM app_review_state WHERE player_id = :playerId LIMIT 1',
    { playerId },
  );
  return numberOrNull(rows[0]?.last_rated_at_ms);
}

/** Saves a rating and returns its id. */
async function insertReview({ playerId, stars, trigger, platform, appVersion, locale, storeRedirected, nowMs }) {
  const conn = await getPool().getConnection();
  try {
    await conn.beginTransaction();
    const [result] = await conn.execute(
      `INSERT INTO app_reviews
         (player_id, stars, trigger_source, platform, app_version, locale, store_redirected, created_at_ms)
       VALUES (:playerId, :stars, :trigger, :platform, :appVersion, :locale, :redirected, :nowMs)`,
      { playerId, stars, trigger, platform, appVersion, locale, redirected: storeRedirected ? 1 : 0, nowMs },
    );
    await conn.execute(
      `INSERT INTO app_review_state
         (player_id, platform, app_version, locale, last_stars, last_rated_at_ms, last_redirected_at_ms, updated_at_ms)
       VALUES (:playerId, :platform, :appVersion, :locale, :stars, :nowMs, :redirectedAt, :nowMs)
       ON DUPLICATE KEY UPDATE
         last_stars = VALUES(last_stars),
         last_rated_at_ms = VALUES(last_rated_at_ms),
         last_redirected_at_ms = COALESCE(VALUES(last_redirected_at_ms), last_redirected_at_ms),
         updated_at_ms = VALUES(updated_at_ms)`,
      {
        playerId,
        platform,
        appVersion,
        locale,
        stars,
        nowMs,
        redirectedAt: storeRedirected ? nowMs : null,
      },
    );
    await recordEvent(conn, playerId, 'rated', trigger, nowMs);
    await conn.commit();
    return Number(result.insertId);
  } catch (error) {
    await conn.rollback();
    throw error;
  } finally {
    conn.release();
  }
}

/** Adds the "what could be better" answer. False when the review isn't this player's. */
async function addReviewFeedback({ reviewId, playerId, tags, comment, nowMs }) {
  const pool = getPool();
  const [result] = await pool.execute(
    `UPDATE app_reviews
     SET tags = :tags, comment = :comment, feedback_at_ms = :nowMs
     WHERE id = :reviewId AND player_id = :playerId`,
    { reviewId, playerId, tags: tags.length ? tags.join(',') : null, comment, nowMs },
  );
  if (!result.affectedRows) return false;
  await recordEvent(pool, playerId, 'feedback', null, nowMs);
  return true;
}

// ---------------------------------------------------------------- admin

function clampInt(value, fallback, min, max) {
  const parsed = Number.parseInt(String(value ?? ''), 10);
  if (!Number.isFinite(parsed)) return fallback;
  return Math.min(Math.max(parsed, min), max);
}

function listFilters({ stars, hasComment, platform, handled } = {}) {
  const where = [];
  const params = {};
  const starList = String(stars ?? '')
    .split(',')
    .map((value) => Number.parseInt(value, 10))
    .filter((value) => value >= 1 && value <= 5);
  if (starList.length) {
    where.push(`r.stars IN (${starList.map((_, i) => `:star${i}`).join(', ')})`);
    starList.forEach((value, i) => {
      params[`star${i}`] = value;
    });
  }
  if (hasComment === '1' || hasComment === true) {
    where.push("(r.comment IS NOT NULL OR r.tags IS NOT NULL)");
  }
  if (typeof platform === 'string' && platform && platform !== 'all') {
    where.push('r.platform = :platform');
    params.platform = platform;
  }
  if (handled === '0' || handled === '1') {
    where.push('r.handled = :handled');
    params.handled = Number(handled);
  }
  return { whereSql: where.length ? `WHERE ${where.join(' AND ')}` : '', params };
}

function mapReview(row) {
  return {
    id: Number(row.id),
    playerId: row.player_id,
    playerName: row.display_name || row.username || null,
    stars: Number(row.stars),
    tags: row.tags ? row.tags.split(',') : [],
    comment: row.comment,
    trigger: row.trigger_source,
    platform: row.platform,
    appVersion: row.app_version,
    locale: row.locale,
    storeRedirected: Boolean(row.store_redirected),
    handled: Boolean(row.handled),
    createdAtMs: Number(row.created_at_ms),
    feedbackAtMs: numberOrNull(row.feedback_at_ms),
  };
}

/** Newest first, with the filters the Feedback view offers. */
async function listReviews(query = {}) {
  const limit = clampInt(query.limit, 25, 1, 200);
  const offset = clampInt(query.offset, 0, 0, 1_000_000);
  const { whereSql, params } = listFilters(query);
  const pool = getPool();
  const [rows] = await pool.execute(
    `SELECT r.*, p.display_name, p.username
     FROM app_reviews r
     LEFT JOIN players p ON p.id = r.player_id
     ${whereSql}
     ORDER BY r.created_at_ms DESC, r.id DESC
     LIMIT ${limit} OFFSET ${offset}`,
    params,
  );
  const [countRows] = await pool.execute(
    `SELECT COUNT(*) AS total FROM app_reviews r ${whereSql}`,
    params,
  );
  return { items: rows.map(mapReview), total: Number(countRows[0]?.total) || 0, limit, offset };
}

async function setReviewHandled(reviewId, handled) {
  const [result] = await getPool().execute(
    'UPDATE app_reviews SET handled = :handled WHERE id = :reviewId',
    { reviewId, handled: handled ? 1 : 0 },
  );
  return result.affectedRows > 0;
}

function escapeCsv(value) {
  let s = value == null ? '' : String(value);
  // Comments are player-written: keep spreadsheet apps from running them as formulas.
  if (/^[=+\-@\t\r]/.test(s)) s = `'${s}`;
  if (/[",\n\r]/.test(s)) return `"${s.replace(/"/g, '""')}"`;
  return s;
}

/** @returns {Promise<{ csv: string, count: number }>} */
async function exportReviewsCsv(query = {}) {
  const { whereSql, params } = listFilters(query);
  const [rows] = await getPool().execute(
    `SELECT r.*, p.display_name, p.username
     FROM app_reviews r
     LEFT JOIN players p ON p.id = r.player_id
     ${whereSql}
     ORDER BY r.created_at_ms DESC, r.id DESC
     LIMIT 50000`,
    params,
  );
  const header = [
    'id', 'createdAt', 'playerId', 'player', 'stars', 'tags', 'comment',
    'trigger', 'platform', 'appVersion', 'locale', 'storeRedirected', 'handled',
  ];
  const lines = [header.join(',')];
  for (const review of rows.map(mapReview)) {
    lines.push(
      [
        review.id,
        new Date(review.createdAtMs).toISOString(),
        review.playerId,
        review.playerName,
        review.stars,
        review.tags.join(' '),
        review.comment,
        review.trigger,
        review.platform,
        review.appVersion,
        review.locale,
        review.storeRedirected ? 1 : 0,
        review.handled ? 1 : 0,
      ]
        .map(escapeCsv)
        .join(','),
    );
  }
  return { csv: `${lines.join('\n')}\n`, count: rows.length };
}

/** Everything the Overview view shows for the last `days` days. */
async function getReviewStats({ days, nowMs, storeMinStars }) {
  const span = clampInt(days, 30, 1, 365);
  const sinceMs = nowMs - span * DAY_MS;
  const pool = getPool();
  const params = { sinceMs, storeMinStars };

  const [[totals], [distribution], [daily], [byPlatform], [byTrigger], [events], [allTime]] =
    await Promise.all([
      pool.execute(
        `SELECT COUNT(*) AS ratings, AVG(stars) AS average,
           SUM(stars >= :storeMinStars) AS happy,
           SUM(store_redirected) AS redirected,
           SUM(comment IS NOT NULL OR tags IS NOT NULL) AS withFeedback,
           SUM(handled = 0 AND (comment IS NOT NULL OR tags IS NOT NULL)) AS unhandled
         FROM app_reviews WHERE created_at_ms >= :sinceMs`,
        params,
      ),
      pool.execute(
        `SELECT stars, COUNT(*) AS count FROM app_reviews
         WHERE created_at_ms >= :sinceMs GROUP BY stars`,
        params,
      ),
      pool.execute(
        `SELECT DATE(FROM_UNIXTIME(created_at_ms / 1000)) AS day, COUNT(*) AS count, AVG(stars) AS average
         FROM app_reviews WHERE created_at_ms >= :sinceMs
         GROUP BY day ORDER BY day`,
        params,
      ),
      pool.execute(
        `SELECT platform, COUNT(*) AS count, AVG(stars) AS average, SUM(store_redirected) AS redirected
         FROM app_reviews WHERE created_at_ms >= :sinceMs
         GROUP BY platform ORDER BY count DESC`,
        params,
      ),
      pool.execute(
        `SELECT trigger_source AS source,
           SUM(kind = 'shown') AS shown,
           SUM(kind = 'dismissed') AS dismissed,
           SUM(kind = 'rated') AS rated
         FROM app_review_events
         WHERE at_ms >= :sinceMs AND trigger_source IS NOT NULL
         GROUP BY trigger_source`,
        params,
      ),
      pool.execute(
        `SELECT kind, COUNT(*) AS count FROM app_review_events
         WHERE at_ms >= :sinceMs GROUP BY kind`,
        params,
      ),
      pool.execute('SELECT COUNT(*) AS ratings, AVG(stars) AS average FROM app_reviews'),
    ]);

  const total = totals[0] || {};
  const funnel = Object.fromEntries(events.map((row) => [row.kind, Number(row.count)]));
  const average = (value) => (value == null ? null : Math.round(Number(value) * 100) / 100);
  return {
    days: span,
    ratings: Number(total.ratings) || 0,
    average: average(total.average),
    happy: Number(total.happy) || 0,
    redirected: Number(total.redirected) || 0,
    withFeedback: Number(total.withFeedback) || 0,
    unhandled: Number(total.unhandled) || 0,
    allTime: { ratings: Number(allTime[0]?.ratings) || 0, average: average(allTime[0]?.average) },
    distribution: [1, 2, 3, 4, 5].map((stars) => ({
      stars,
      count: Number(distribution.find((row) => Number(row.stars) === stars)?.count) || 0,
    })),
    daily: daily.map((row) => ({
      day: row.day instanceof Date ? row.day.toISOString().slice(0, 10) : String(row.day),
      count: Number(row.count),
      average: average(row.average),
    })),
    byPlatform: byPlatform.map((row) => ({
      platform: row.platform,
      count: Number(row.count),
      average: average(row.average),
      redirected: Number(row.redirected) || 0,
    })),
    byTrigger: byTrigger.map((row) => ({
      trigger: row.source,
      shown: Number(row.shown) || 0,
      dismissed: Number(row.dismissed) || 0,
      rated: Number(row.rated) || 0,
    })),
    funnel: {
      shown: funnel.shown || 0,
      dismissed: funnel.dismissed || 0,
      rated: funnel.rated || 0,
      feedback: funnel.feedback || 0,
      pushSent: funnel.push_sent || 0,
      pushOpened: funnel.push_opened || 0,
    },
  };
}

// ---------------------------------------------------------------- auto push

function pushCandidateSql(config, nowMs) {
  const { push, rules } = config;
  return {
    sql: `FROM app_review_state s
       INNER JOIN players p ON p.id = s.player_id
       WHERE s.last_rated_at_ms IS NULL
         AND s.push_sent_at_ms IS NULL
         AND s.prompts_shown < :maxPrompts
         AND (s.last_prompt_at_ms IS NULL OR s.last_prompt_at_ms <= :cooldownCutoff)
         AND p.is_bot = 0
         AND p.notify_marketing = 1
         AND (p.wins + p.losses + p.draws) >= :minMatches
         AND p.created_at <= (UTC_TIMESTAMP() - INTERVAL ${push.minDaysSinceInstall} DAY)
         AND p.last_seen_at <= (UTC_TIMESTAMP() - INTERVAL ${push.idleHours} HOUR)
         AND p.last_seen_at >= (UTC_TIMESTAMP() - INTERVAL 30 DAY)
         AND EXISTS (SELECT 1 FROM device_tokens dt WHERE dt.player_id = p.id)`,
    params: {
      maxPrompts: rules.maxPrompts,
      cooldownCutoff: nowMs - rules.cooldownDays * DAY_MS,
      minMatches: push.minMatchesPlayed,
    },
  };
}

/** Players the automatic push would reach now, most recently active first. */
async function selectPushCandidates(config, nowMs, limit) {
  const { sql, params } = pushCandidateSql(config, nowMs);
  const safeLimit = clampInt(limit, 200, 1, 5000);
  const [rows] = await getPool().execute(
    `SELECT s.player_id, s.locale ${sql} ORDER BY p.last_seen_at DESC LIMIT ${safeLimit}`,
    params,
  );
  return rows.map((row) => ({ playerId: row.player_id, locale: row.locale }));
}

async function countPushCandidates(config, nowMs) {
  const { sql, params } = pushCandidateSql(config, nowMs);
  const [rows] = await getPool().execute(`SELECT COUNT(*) AS count ${sql}`, params);
  return Number(rows[0]?.count) || 0;
}

async function markPushSent(playerIds, nowMs) {
  if (!playerIds.length) return;
  const pool = getPool();
  const params = { nowMs };
  const placeholders = playerIds.map((id, i) => {
    params[`p${i}`] = id;
    return `:p${i}`;
  });
  await pool.execute(
    `UPDATE app_review_state SET push_sent_at_ms = :nowMs, updated_at_ms = :nowMs
     WHERE player_id IN (${placeholders.join(', ')})`,
    params,
  );
  const values = playerIds.map((_, i) => `(:p${i}, 'push_sent', 'push', :nowMs)`);
  await pool.execute(
    `INSERT INTO app_review_events (player_id, kind, trigger_source, at_ms) VALUES ${values.join(', ')}`,
    params,
  );
}

module.exports = {
  ensureAppReviewSchema,
  touchReviewState,
  recordPromptShown,
  recordDismiss,
  recordPushOpened,
  lastRatedAtMs,
  insertReview,
  addReviewFeedback,
  listReviews,
  setReviewHandled,
  exportReviewsCsv,
  getReviewStats,
  selectPushCandidates,
  countPushCandidates,
  markPushSent,
};
