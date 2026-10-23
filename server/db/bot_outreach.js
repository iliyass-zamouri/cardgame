const { randomUUID } = require('crypto');
const { getPool } = require('./pool');

/** Log of bot-initiated friend requests and invites, used for caps. */
async function ensureBotOutreachSchema() {
  const pool = getPool();
  await pool.query(`
    CREATE TABLE IF NOT EXISTS bot_outreach (
      id VARCHAR(64) NOT NULL PRIMARY KEY,
      player_id VARCHAR(64) NOT NULL,
      bot_id VARCHAR(64) NOT NULL,
      kind ENUM('friendRequest', 'invite') NOT NULL,
      created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      KEY idx_bot_outreach_player (player_id, created_at),
      KEY idx_bot_outreach_pair (player_id, bot_id, kind)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  `);
}

async function recordOutreach({ playerId, botId, kind }) {
  await getPool().execute(
    `INSERT INTO bot_outreach (id, player_id, bot_id, kind)
     VALUES (:id, :playerId, :botId, :kind)`,
    { id: `bo-${randomUUID()}`, playerId, botId, kind },
  );
}

/**
 * Outreach history of one player: counts per kind in the last day, the
 * latest event time and bots that asked them for friendship in 30 days.
 */
async function outreachSummary(playerId) {
  const pool = getPool();
  // Ages come from MySQL itself, so server/DB time zones can't skew them.
  const [rows] = await pool.execute(
    `SELECT bot_id, kind, TIMESTAMPDIFF(SECOND, created_at, NOW()) AS age_s
     FROM bot_outreach
     WHERE player_id = :playerId AND created_at >= (NOW() - INTERVAL 30 DAY)
     ORDER BY created_at DESC`,
    { playerId },
  );
  const day = 24 * 60 * 60;
  const summary = {
    friendRequestsToday: 0,
    invitesToday: 0,
    lastAt: rows.length > 0 ? Date.now() - Number(rows[0].age_s) * 1000 : null,
    askedByBots: new Set(),
  };
  for (const row of rows) {
    const today = Number(row.age_s) < day;
    if (row.kind === 'friendRequest') {
      summary.askedByBots.add(row.bot_id);
      if (today) summary.friendRequestsToday += 1;
    } else if (today) {
      summary.invitesToday += 1;
    }
  }
  return summary;
}

/** Pending friend requests bots sent to this player that are still unanswered. */
async function pendingBotRequestCount(playerId) {
  const [rows] = await getPool().execute(
    `SELECT COUNT(*) AS n FROM friendships f
     JOIN players p ON p.id = f.player_id
     WHERE f.friend_id = :playerId AND f.status = 'pending' AND p.is_bot = 1`,
    { playerId },
  );
  return Number(rows[0]?.n || 0);
}

/**
 * Real players worth a push: they have a device, have played or finished the
 * tutorial, came back within 30 days but not in the last [minAwayHours].
 */
async function listOfflineTargets({ limit = 5, minAwayHours = 6, excludeIds = [] } = {}) {
  const [rows] = await getPool().execute(
    `SELECT p.id, p.country_code, p.elo
     FROM players p
     WHERE p.is_bot = 0
       AND (p.tutorial_done = 1 OR p.wins + p.losses + p.draws > 0)
       AND p.last_seen_at >= (NOW() - INTERVAL 30 DAY)
       AND p.last_seen_at <= (NOW() - INTERVAL :hours HOUR)
       AND EXISTS (SELECT 1 FROM device_tokens d WHERE d.player_id = p.id)
     ORDER BY RAND()
     LIMIT 50`,
    { hours: minAwayHours },
  );
  const exclude = new Set(excludeIds);
  return rows
    .filter((row) => !exclude.has(row.id))
    .slice(0, limit)
    .map((row) => ({ playerId: row.id, countryCode: row.country_code, elo: row.elo ?? 1000 }));
}

/** Basic info for a set of human players (eligibility + quiet hours). */
async function loadHumanProfiles(playerIds) {
  if (!playerIds.length) return new Map();
  const placeholders = playerIds.map((_, i) => `:p${i}`).join(', ');
  const params = Object.fromEntries(playerIds.map((id, i) => [`p${i}`, id]));
  const [rows] = await getPool().execute(
    `SELECT id, country_code, elo, is_bot, tutorial_done, wins + losses + draws AS games
     FROM players WHERE id IN (${placeholders})`,
    params,
  );
  return new Map(
    rows.map((row) => [
      row.id,
      {
        playerId: row.id,
        countryCode: row.country_code,
        elo: row.elo ?? 1000,
        isBot: Number(row.is_bot) === 1,
        eligible: Number(row.tutorial_done) === 1 || Number(row.games) > 0,
      },
    ]),
  );
}

module.exports = {
  ensureBotOutreachSchema,
  recordOutreach,
  outreachSummary,
  pendingBotRequestCount,
  listOfflineTargets,
  loadHumanProfiles,
};
