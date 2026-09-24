const { getPool } = require('./pool');

const PREF_COLUMNS = {
  invites: 'notify_invites',
  social: 'notify_social',
  ranking: 'notify_ranking',
  marketing: 'notify_marketing',
};

const SQL_IN_CHUNK = 2000;

function chunkArray(items, size) {
  if (!items.length) return [];
  const out = [];
  for (let i = 0; i < items.length; i += size) {
    out.push(items.slice(i, i + size));
  }
  return out;
}

async function columnExists(conn, table, column) {
  const [rows] = await conn.query(
    `SELECT 1 AS ok
     FROM information_schema.COLUMNS
     WHERE TABLE_SCHEMA = DATABASE()
       AND TABLE_NAME = :table
       AND COLUMN_NAME = :column
     LIMIT 1`,
    { table, column },
  );
  return rows.length > 0;
}

async function ensurePushSchema() {
  const pool = getPool();
  const conn = await pool.getConnection();
  try {
    await conn.query(`
      CREATE TABLE IF NOT EXISTS device_tokens (
        id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
        player_id VARCHAR(64) NOT NULL,
        token VARCHAR(512) NOT NULL,
        platform ENUM('android', 'ios') NOT NULL,
        updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        UNIQUE KEY uq_device_tokens_token (token),
        KEY idx_device_tokens_player (player_id),
        CONSTRAINT fk_device_tokens_player
          FOREIGN KEY (player_id) REFERENCES players (id) ON DELETE CASCADE
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    `);

    await conn.query(`
      CREATE TABLE IF NOT EXISTS player_notifications (
        id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
        player_id VARCHAR(64) NOT NULL,
        type VARCHAR(64) NOT NULL,
        category ENUM('invites', 'social', 'ranking', 'marketing') NOT NULL,
        title VARCHAR(128) NOT NULL,
        body VARCHAR(512) NOT NULL,
        data_json JSON NULL,
        read_at TIMESTAMP NULL,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        KEY idx_player_notifications_player_created (player_id, created_at),
        KEY idx_player_notifications_player_unread (player_id, read_at),
        CONSTRAINT fk_player_notifications_player
          FOREIGN KEY (player_id) REFERENCES players (id) ON DELETE CASCADE
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    `);

    for (const col of [
      'notify_invites',
      'notify_social',
      'notify_ranking',
      'notify_marketing',
    ]) {
      if (!(await columnExists(conn, 'players', col))) {
        await conn.query(
          `ALTER TABLE players ADD COLUMN ${col} TINYINT(1) NOT NULL DEFAULT 1`,
        );
      }
    }
  } finally {
    conn.release();
  }
}

async function playerExists(playerId) {
  const [rows] = await getPool().execute(
    `SELECT id FROM players WHERE id = :playerId LIMIT 1`,
    { playerId },
  );
  return rows.length > 0;
}

async function upsertDeviceToken({ playerId, token, platform }) {
  await getPool().execute(
    `INSERT INTO device_tokens (player_id, token, platform)
     VALUES (:playerId, :token, :platform)
     ON DUPLICATE KEY UPDATE
       player_id = VALUES(player_id),
       platform = VALUES(platform),
       updated_at = CURRENT_TIMESTAMP`,
    { playerId, token, platform },
  );
  return { ok: true };
}

async function removeDeviceToken({ playerId, token }) {
  if (playerId) {
    await getPool().execute(
      `DELETE FROM device_tokens
       WHERE token = :token AND player_id = :playerId`,
      { token, playerId },
    );
  } else {
    await getPool().execute(`DELETE FROM device_tokens WHERE token = :token`, {
      token,
    });
  }
  return { ok: true };
}

async function removeDeviceTokens(tokens) {
  if (!tokens.length) return;
  for (const batch of chunkArray(tokens, SQL_IN_CHUNK)) {
    const placeholders = batch.map((_, i) => `:t${i}`).join(', ');
    const params = Object.fromEntries(batch.map((t, i) => [`t${i}`, t]));
    await getPool().execute(
      `DELETE FROM device_tokens WHERE token IN (${placeholders})`,
      params,
    );
  }
}

async function listTokensForPlayers(playerIds, category) {
  const unique = [
    ...new Set(
      (playerIds || []).filter((id) => typeof id === 'string' && id.trim()),
    ),
  ].map((id) => id.trim());
  if (!unique.length) return [];

  const prefCol = PREF_COLUMNS[category];
  if (!prefCol) throw new Error(`Unknown notify category: ${category}`);

  const out = [];
  for (const batch of chunkArray(unique, SQL_IN_CHUNK)) {
    const placeholders = batch.map((_, i) => `:p${i}`).join(', ');
    const params = Object.fromEntries(batch.map((id, i) => [`p${i}`, id]));
    const [rows] = await getPool().execute(
      `SELECT dt.player_id AS playerId, dt.token, dt.platform
       FROM device_tokens dt
       INNER JOIN players p ON p.id = dt.player_id
       WHERE dt.player_id IN (${placeholders})
         AND p.${prefCol} = 1`,
      params,
    );
    for (const row of rows) {
      out.push({
        playerId: row.playerId,
        token: row.token,
        platform: row.platform,
      });
    }
  }
  return out;
}

async function listMarketingTokens() {
  const [rows] = await getPool().execute(
    `SELECT dt.player_id AS playerId, dt.token, dt.platform
     FROM device_tokens dt
     INNER JOIN players p ON p.id = dt.player_id
     WHERE p.notify_marketing = 1`,
  );
  return rows.map((row) => ({
    playerId: row.playerId,
    token: row.token,
    platform: row.platform,
  }));
}

async function listPlayerIdsWithNotifyPref(category) {
  const prefCol = PREF_COLUMNS[category];
  if (!prefCol) throw new Error(`Unknown notify category: ${category}`);
  const [rows] = await getPool().execute(
    `SELECT id FROM players WHERE ${prefCol} = 1 AND is_bot = 0`,
  );
  return rows.map((row) => row.id);
}

/**
 * Normalize marketing blast audience filters.
 * Matches played = wins + losses + draws (no matches_played column).
 * @param {{
 *   maxLastSeenDays?: number,
 *   requirePushToken?: boolean,
 *   limit?: number,
 *   minMatchesPlayed?: number,
 *   maxMatchesPlayed?: number,
 *   minWins?: number,
 *   maxWins?: number,
 *   platforms?: string[] | string,
 * }} [args]
 */
function normalizeMarketingAudienceArgs({
  maxLastSeenDays = 30,
  requirePushToken = true,
  limit = 50000,
  minMatchesPlayed,
  maxMatchesPlayed,
  minWins,
  maxWins,
  platforms,
} = {}) {
  const days = Math.min(
    Math.max(Math.floor(Number(maxLastSeenDays) || 30), 1),
    90,
  );
  const safeLimit = Math.min(
    Math.max(Math.floor(Number(limit) || 50000), 1),
    100000,
  );
  const platformRaw = Array.isArray(platforms)
    ? platforms
    : typeof platforms === 'string' && platforms.trim()
      ? [platforms]
      : [];
  const platformList = [
    ...new Set(
      platformRaw
        .map((p) => String(p).trim().toLowerCase())
        .filter((p) => p === 'android' || p === 'ios'),
    ),
  ];
  return {
    days,
    safeLimit,
    requirePushToken: requirePushToken !== false,
    minMatchesPlayed,
    maxMatchesPlayed,
    minWins,
    maxWins,
    platformList,
  };
}

/**
 * @param {ReturnType<typeof normalizeMarketingAudienceArgs>} norm
 */
function buildMarketingAudienceSql(norm) {
  const needTokenJoin = norm.requirePushToken || norm.platformList.length > 0;
  const joinSql = needTokenJoin
    ? 'INNER JOIN device_tokens dt ON dt.player_id = p.id'
    : '';

  /** @type {string[]} */
  const extra = [];
  /** @type {Record<string, string | number>} */
  const params = {};

  const matchesExpr = '(p.wins + p.losses + p.draws)';

  if (
    norm.minMatchesPlayed != null &&
    Number.isFinite(Number(norm.minMatchesPlayed))
  ) {
    extra.push(`${matchesExpr} >= :minMatchesPlayed`);
    params.minMatchesPlayed = Math.max(
      0,
      Math.floor(Number(norm.minMatchesPlayed)),
    );
  }
  if (
    norm.maxMatchesPlayed != null &&
    Number.isFinite(Number(norm.maxMatchesPlayed))
  ) {
    extra.push(`${matchesExpr} <= :maxMatchesPlayed`);
    params.maxMatchesPlayed = Math.max(
      0,
      Math.floor(Number(norm.maxMatchesPlayed)),
    );
  }
  if (norm.minWins != null && Number.isFinite(Number(norm.minWins))) {
    extra.push('p.wins >= :minWins');
    params.minWins = Math.max(0, Math.floor(Number(norm.minWins)));
  }
  if (norm.maxWins != null && Number.isFinite(Number(norm.maxWins))) {
    extra.push('p.wins <= :maxWins');
    params.maxWins = Math.max(0, Math.floor(Number(norm.maxWins)));
  }

  if (norm.platformList.length) {
    const placeholders = norm.platformList.map((_, i) => {
      const key = `plat${i}`;
      params[key] = norm.platformList[i];
      return `:${key}`;
    });
    extra.push(`dt.platform IN (${placeholders.join(', ')})`);
  }

  const extraSql = extra.length ? ` AND ${extra.join(' AND ')}` : '';
  const whereSql = `p.notify_marketing = 1
       AND p.is_bot = 0
       AND p.last_seen_at >= (UTC_TIMESTAMP() - INTERVAL ${norm.days} DAY)
       ${extraSql}`;

  return { joinSql, whereSql, params };
}

/**
 * @param {Parameters<typeof normalizeMarketingAudienceArgs>[0]} [args]
 * @returns {Promise<string[]>}
 */
async function listMarketingBlastAudience(args = {}) {
  const norm = normalizeMarketingAudienceArgs(args);
  const { joinSql, whereSql, params } = buildMarketingAudienceSql(norm);
  const [rows] = await getPool().execute(
    `SELECT p.id
     FROM players p
     ${joinSql}
     WHERE ${whereSql}
     GROUP BY p.id
     ORDER BY MAX(p.last_seen_at) DESC
     LIMIT ${norm.safeLimit}`,
    params,
  );
  return rows.map((row) => row.id);
}

/**
 * @param {Parameters<typeof normalizeMarketingAudienceArgs>[0]} [args]
 * @returns {Promise<number>}
 */
async function countMarketingBlastAudience(args = {}) {
  const norm = normalizeMarketingAudienceArgs(args);
  const { joinSql, whereSql, params } = buildMarketingAudienceSql(norm);
  const [rows] = await getPool().execute(
    `SELECT COUNT(*) AS count FROM (
       SELECT p.id
       FROM players p
       ${joinSql}
       WHERE ${whereSql}
       GROUP BY p.id
     ) AS audience`,
    params,
  );
  return Number(rows[0]?.count) || 0;
}

async function getNotifyPrefs(playerId) {
  const [rows] = await getPool().execute(
    `SELECT notify_invites, notify_social, notify_ranking, notify_marketing
     FROM players WHERE id = :playerId LIMIT 1`,
    { playerId },
  );
  if (!rows.length) return null;
  const row = rows[0];
  return {
    invites: Boolean(row.notify_invites),
    social: Boolean(row.notify_social),
    ranking: Boolean(row.notify_ranking),
    marketing: Boolean(row.notify_marketing),
  };
}

async function updateNotifyPrefs({
  playerId,
  invites,
  social,
  ranking,
  marketing,
}) {
  const sets = [];
  const params = { playerId };
  if (typeof invites === 'boolean') {
    sets.push('notify_invites = :invites');
    params.invites = invites ? 1 : 0;
  }
  if (typeof social === 'boolean') {
    sets.push('notify_social = :social');
    params.social = social ? 1 : 0;
  }
  if (typeof ranking === 'boolean') {
    sets.push('notify_ranking = :ranking');
    params.ranking = ranking ? 1 : 0;
  }
  if (typeof marketing === 'boolean') {
    sets.push('notify_marketing = :marketing');
    params.marketing = marketing ? 1 : 0;
  }
  if (!sets.length) return getNotifyPrefs(playerId);

  const [result] = await getPool().execute(
    `UPDATE players SET ${sets.join(', ')}, last_seen_at = CURRENT_TIMESTAMP
     WHERE id = :playerId`,
    params,
  );
  if (!result.affectedRows) {
    const err = new Error('Player not found');
    err.code = 'not_found';
    throw err;
  }
  return getNotifyPrefs(playerId);
}

async function insertPlayerNotifications({
  playerIds,
  type,
  category,
  title,
  body,
  data,
}) {
  const unique = [
    ...new Set(
      (playerIds || [])
        .filter((id) => typeof id === 'string' && id.trim())
        .map((id) => id.trim()),
    ),
  ];
  if (!unique.length) return 0;

  const prefCol = PREF_COLUMNS[category];
  if (!prefCol) throw new Error(`Unknown notify category: ${category}`);

  const notifType =
    typeof type === 'string' && type.trim() ? type.trim().slice(0, 64) : 'unknown';
  const notifTitle =
    typeof title === 'string' ? title.trim().slice(0, 128) : '';
  const notifBody = typeof body === 'string' ? body.trim().slice(0, 512) : '';
  if (!notifTitle || !notifBody) return 0;

  const dataJson =
    data && typeof data === 'object' ? JSON.stringify(data) : null;

  let inserted = 0;
  for (const batch of chunkArray(unique, SQL_IN_CHUNK)) {
    const placeholders = batch.map((_, i) => `:p${i}`).join(', ');
    const params = {
      type: notifType,
      category,
      title: notifTitle,
      body: notifBody,
      dataJson,
      ...Object.fromEntries(batch.map((id, i) => [`p${i}`, id])),
    };
    const [result] = await getPool().execute(
      `INSERT INTO player_notifications
         (player_id, type, category, title, body, data_json)
       SELECT p.id, :type, :category, :title, :body, :dataJson
       FROM players p
       WHERE p.id IN (${placeholders})
         AND p.${prefCol} = 1
         AND p.is_bot = 0`,
      params,
    );
    inserted += result.affectedRows || 0;
  }
  return inserted;
}

async function listPlayerNotifications({ playerId, limit = 50, offset = 0 }) {
  const safeLimit = Math.min(Math.max(Number(limit) || 50, 1), 100);
  const safeOffset = Math.max(Number(offset) || 0, 0);

  const [rows] = await getPool().execute(
    `SELECT id, type, category, title, body, data_json AS dataJson,
            read_at AS readAt, created_at AS createdAt
     FROM player_notifications
     WHERE player_id = :playerId
     ORDER BY created_at DESC, id DESC
     LIMIT ${safeLimit} OFFSET ${safeOffset}`,
    { playerId },
  );

  const [countRows] = await getPool().execute(
    `SELECT
       COUNT(*) AS total,
       SUM(CASE WHEN read_at IS NULL THEN 1 ELSE 0 END) AS unread
     FROM player_notifications
     WHERE player_id = :playerId`,
    { playerId },
  );
  const counts = countRows[0] || {};

  return {
    notifications: rows.map((row) => {
      let data = null;
      if (row.dataJson != null) {
        if (typeof row.dataJson === 'string') {
          try {
            data = JSON.parse(row.dataJson);
          } catch {
            data = null;
          }
        } else if (typeof row.dataJson === 'object') {
          data = row.dataJson;
        }
      }
      return {
        id: Number(row.id),
        type: row.type,
        category: row.category,
        title: row.title,
        body: row.body,
        data,
        read: row.readAt != null,
        createdAt:
          row.createdAt instanceof Date
            ? row.createdAt.toISOString()
            : String(row.createdAt),
      };
    }),
    total: Number(counts.total) || 0,
    unreadCount: Number(counts.unread) || 0,
  };
}

async function markPlayerNotificationsRead({ playerId, ids, all = false }) {
  if (all) {
    await getPool().execute(
      `UPDATE player_notifications
       SET read_at = CURRENT_TIMESTAMP
       WHERE player_id = :playerId AND read_at IS NULL`,
      { playerId },
    );
  } else {
    const uniqueIds = [
      ...new Set(
        (ids || [])
          .map((id) => Number(id))
          .filter((id) => Number.isFinite(id) && id > 0),
      ),
    ];
    if (!uniqueIds.length) {
      return listPlayerNotifications({ playerId, limit: 1 });
    }
    const placeholders = uniqueIds.map((_, i) => `:id${i}`).join(', ');
    const params = {
      playerId,
      ...Object.fromEntries(uniqueIds.map((id, i) => [`id${i}`, id])),
    };
    await getPool().execute(
      `UPDATE player_notifications
       SET read_at = CURRENT_TIMESTAMP
       WHERE player_id = :playerId
         AND id IN (${placeholders})
         AND read_at IS NULL`,
      params,
    );
  }

  const [countRows] = await getPool().execute(
    `SELECT
       COUNT(*) AS total,
       SUM(CASE WHEN read_at IS NULL THEN 1 ELSE 0 END) AS unread
     FROM player_notifications
     WHERE player_id = :playerId`,
    { playerId },
  );
  const counts = countRows[0] || {};
  return {
    ok: true,
    total: Number(counts.total) || 0,
    unreadCount: Number(counts.unread) || 0,
  };
}

module.exports = {
  ensurePushSchema,
  playerExists,
  upsertDeviceToken,
  removeDeviceToken,
  removeDeviceTokens,
  listTokensForPlayers,
  listMarketingTokens,
  listPlayerIdsWithNotifyPref,
  listMarketingBlastAudience,
  countMarketingBlastAudience,
  getNotifyPrefs,
  updateNotifyPrefs,
  insertPlayerNotifications,
  listPlayerNotifications,
  markPlayerNotificationsRead,
};
