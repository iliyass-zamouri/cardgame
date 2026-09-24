const { getPool } = require('../db/pool');

function dayKey(value) {
  if (!value) return '';
  if (value instanceof Date) return value.toISOString().slice(0, 10);
  return String(value).slice(0, 10);
}

function toIso(value) {
  if (!value) return null;
  if (value instanceof Date) return value.toISOString();
  return String(value);
}

function fillDays(rows, n, keys) {
  const byDay = new Map();
  for (const row of rows) {
    byDay.set(dayKey(row.day), row);
  }
  const now = new Date();
  const out = [];
  for (let i = n - 1; i >= 0; i -= 1) {
    const d = new Date(
      Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() - i),
    );
    const key = d.toISOString().slice(0, 10);
    const row = byDay.get(key) || {};
    /** @type {Record<string, number|string>} */
    const point = { day: key };
    for (const k of keys) {
      point[k] = Number(row[k]) || 0;
    }
    out.push(point);
  }
  return out;
}

function n(value) {
  return Number(value) || 0;
}

function mapAdminPlayer(row) {
  if (!row) return null;
  const wins = n(row.wins);
  const losses = n(row.losses);
  const draws = n(row.draws);
  const matchesPlayed = wins + losses + draws;
  return {
    playerId: row.id,
    name: row.display_name,
    username: row.username,
    email: row.email || null,
    authType: row.auth_type || 'guest',
    googleSub: row.google_sub || null,
    avatarId: row.avatar_id || 'default',
    createdAt: toIso(row.created_at),
    lastSeenAt: toIso(row.last_seen_at),
    matchesPlayed,
    wins,
    losses,
    draws,
    elo: n(row.elo),
    totalPoints: n(row.total_points),
    money: n(row.money),
    chips: n(row.chips),
    lastIp: row.last_ip ?? null,
    winRate: matchesPlayed > 0 ? Math.round((wins / matchesPlayed) * 100) : 0,
  };
}

const PLAYER_SELECT = `id, display_name, username, auth_type, google_sub, email, avatar_id,
            created_at, last_seen_at, wins, losses, draws, elo, total_points,
            money, chips, last_ip`;

/**
 * Aggregate KPIs / charts for the ops dashboard.
 */
async function getAdminDashboardStats() {
  const pool = getPool();

  const [
    [playerRows],
    [matchRows],
    [signupRows],
    [matchDayRows],
    [matchTypeRows],
    [recentMatchRows],
    [recentPlayerRows],
    [iapRows],
    [iapDayRows],
    [socialRows],
    [ownedRows],
    [pushPrefRows],
    [engagementRows],
    [newUserRecentRows],
  ] = await Promise.all([
    pool.execute(
      `SELECT
         COUNT(*) AS total,
         SUM(is_bot = 0) AS humans,
         SUM(is_bot = 1) AS bots,
         SUM(is_bot = 0 AND auth_type = 'guest') AS guest,
         SUM(is_bot = 0 AND auth_type = 'google') AS google,
         SUM(is_bot = 0 AND email IS NOT NULL AND email != '') AS with_email,
         SUM(is_bot = 0 AND last_seen_at >= UTC_TIMESTAMP() - INTERVAL 1 DAY) AS dau,
         SUM(is_bot = 0 AND last_seen_at >= UTC_TIMESTAMP() - INTERVAL 7 DAY) AS wau,
         SUM(is_bot = 0 AND last_seen_at >= UTC_TIMESTAMP() - INTERVAL 30 DAY) AS mau,
         SUM(is_bot = 0 AND created_at >= UTC_DATE()) AS signups_today,
         SUM(is_bot = 0 AND created_at >= UTC_TIMESTAMP() - INTERVAL 1 HOUR) AS signups_1h,
         SUM(is_bot = 0 AND created_at >= UTC_TIMESTAMP() - INTERVAL 1 DAY) AS signups_24h,
         SUM(is_bot = 0 AND created_at >= UTC_TIMESTAMP() - INTERVAL 7 DAY) AS signups_7d
       FROM players`,
    ),
    pool.execute(
      `SELECT
         COUNT(*) AS total,
         SUM(created_at >= UTC_DATE()) AS started_today,
         SUM(created_at >= UTC_TIMESTAMP() - INTERVAL 7 DAY) AS started_7d,
         COALESCE(SUM(stake_per_player), 0) AS stake_sum,
         COALESCE(SUM(pot_amount), 0) AS pot_sum,
         COALESCE(AVG(pot_amount), 0) AS pot_avg
       FROM matches`,
    ),
    pool.execute(
      `SELECT DATE_FORMAT(created_at, '%Y-%m-%d') AS day, COUNT(*) AS count
       FROM players
       WHERE is_bot = 0 AND created_at >= UTC_DATE() - INTERVAL 13 DAY
       GROUP BY DATE_FORMAT(created_at, '%Y-%m-%d')
       ORDER BY day`,
    ),
    pool.execute(
      `SELECT DATE_FORMAT(created_at, '%Y-%m-%d') AS day,
              COUNT(*) AS started
       FROM matches
       WHERE created_at >= UTC_DATE() - INTERVAL 13 DAY
       GROUP BY DATE_FORMAT(created_at, '%Y-%m-%d')
       ORDER BY day`,
    ),
    pool.execute(
      `SELECT match_type AS mode, COUNT(*) AS count
       FROM matches
       WHERE created_at >= UTC_DATE() - INTERVAL 30 DAY
       GROUP BY match_type
       ORDER BY count DESC`,
    ),
    pool.execute(
      `SELECT
         m.id,
         m.room_id AS roomId,
         m.match_type AS mode,
         m.stake_per_player AS stakePerPlayer,
         m.pot_amount AS potAmount,
         m.winner_player_id AS winnerPlayerId,
         m.created_at AS startedAt,
         COUNT(mp.player_id) AS playerCount,
         SUM(CASE WHEN p.is_bot = 1 THEN 1 ELSE 0 END) AS botCount,
         GROUP_CONCAT(
           CONCAT(
             COALESCE(NULLIF(p.display_name, ''), LEFT(mp.player_id, 8)),
             ':',
             mp.result
           )
           ORDER BY mp.seat
           SEPARATOR ', '
         ) AS roster
       FROM matches m
       LEFT JOIN match_players mp ON mp.match_id = m.id
       LEFT JOIN players p ON p.id = mp.player_id
       WHERE m.created_at >= UTC_DATE() - INTERVAL 30 DAY
       GROUP BY m.id, m.room_id, m.match_type, m.stake_per_player,
                m.pot_amount, m.winner_player_id, m.created_at
       ORDER BY m.created_at DESC
       LIMIT 25`,
    ),
    pool.execute(
      `SELECT ${PLAYER_SELECT}
       FROM players
       WHERE is_bot = 0
       ORDER BY last_seen_at DESC
       LIMIT 40`,
    ),
    pool.execute(
      `SELECT COUNT(*) AS count
       FROM iap_redemptions`,
    ),
    pool.execute(
      `SELECT DATE_FORMAT(created_at, '%Y-%m-%d') AS day,
              COUNT(*) AS count
       FROM iap_redemptions
       WHERE created_at >= UTC_DATE() - INTERVAL 13 DAY
       GROUP BY DATE_FORMAT(created_at, '%Y-%m-%d')
       ORDER BY day`,
    ),
    pool.execute(
      `SELECT
         (SELECT COUNT(*) FROM friendships WHERE status = 'accepted') AS friends,
         (SELECT COUNT(*) FROM friendships WHERE status = 'pending') AS pending`,
    ),
    pool.execute(`SELECT COUNT(*) AS grants FROM player_items`),
    pool.execute(
      `SELECT
         SUM(notify_invites = 1) AS invites,
         SUM(notify_social = 1) AS social,
         SUM(notify_ranking = 1) AS ranking,
         SUM(notify_marketing = 1) AS marketing,
         (SELECT COUNT(DISTINCT player_id) FROM device_tokens) AS with_token
       FROM players
       WHERE is_bot = 0`,
    ),
    pool.execute(
      `SELECT
         SUM(wins + losses + draws = 0) AS never_played,
         SUM(wins + losses + draws BETWEEN 1 AND 4) AS low,
         SUM(wins + losses + draws BETWEEN 5 AND 19) AS mid,
         SUM(wins + losses + draws >= 20) AS high
       FROM players
       WHERE is_bot = 0`,
    ),
    pool.execute(
      `SELECT ${PLAYER_SELECT}
       FROM players
       WHERE is_bot = 0
         AND created_at >= UTC_TIMESTAMP() - INTERVAL 7 DAY
       ORDER BY created_at DESC
       LIMIT 80`,
    ),
  ]);

  const p = playerRows[0] || {};
  const m = matchRows[0] || {};
  const iap = iapRows[0] || {};
  const social = socialRows[0] || {};
  const owned = ownedRows[0] || {};
  const push = pushPrefRows[0] || {};
  const eng = engagementRows[0] || {};

  const matchDays = fillDays(matchDayRows, 14, ['started']);
  for (const d of matchDays) {
    d.aborted = 0;
    d.finished = d.started;
  }

  return {
    generatedAt: new Date().toISOString(),
    players: {
      total: n(p.total),
      humans: n(p.humans),
      bots: n(p.bots),
      guest: n(p.guest),
      google: n(p.google),
      apple: 0,
      withEmail: n(p.with_email),
      dau: n(p.dau),
      wau: n(p.wau),
      mau: n(p.mau),
      signupsToday: n(p.signups_today),
      signups1h: n(p.signups_1h),
      signups24h: n(p.signups_24h),
      signups7d: n(p.signups_7d),
    },
    matches: {
      total: n(m.total),
      active: 0,
      finished: n(m.total),
      aborted: 0,
      startedToday: n(m.started_today),
      finishedToday: n(m.started_today),
      started7d: n(m.started_7d),
      stakeSum: n(m.stake_sum),
      potSum: n(m.pot_sum),
      potAvg: Math.round(n(m.pot_avg)),
    },
    matchQuality: {
      started7d: n(m.started_7d),
      finished7d: n(m.started_7d),
      aborted7d: 0,
      finishRate7d: n(m.started_7d) ? 100 : 0,
      abortRate7d: 0,
      random7d: n(m.started_7d),
      private7d: 0,
    },
    outcomes: {},
    modes: matchTypeRows.map((row) => ({
      mode: row.mode,
      count: n(row.count),
    })),
    maps: [],
    maps7d: [],
    maps24h: [],
    topMap: { last24h: null, last7d: null, last30d: null },
    signupsByDay: fillDays(signupRows, 14, ['count']),
    matchesByDay: matchDays,
    iap: {
      count: n(iap.count),
      gems: 0,
      coins: 0,
      byDay: fillDays(iapDayRows, 14, ['count']).map((d) => ({
        ...d,
        gems: 0,
      })),
    },
    social: {
      friends: n(social.friends),
      pending: n(social.pending),
      referrals: 0,
      ownedItems: n(owned.grants),
    },
    push: {
      invites: n(push.invites),
      social: n(push.social),
      ranking: n(push.ranking),
      marketing: n(push.marketing),
      withToken: n(push.with_token),
    },
    engagement: {
      neverPlayed: n(eng.never_played),
      low: n(eng.low),
      mid: n(eng.mid),
      high: n(eng.high),
      rewardClaims: 0,
      rewardOffers: 0,
    },
    newUsers: {
      last1h: { count: n(p.signups_1h), byVersion: [] },
      last24h: { count: n(p.signups_24h), byVersion: [] },
      last7d: { count: n(p.signups_7d), byVersion: [] },
      recent: newUserRecentRows.map(mapAdminPlayer),
    },
    recentMatches: recentMatchRows.map((row) => ({
      publicId: row.id,
      roomId: row.roomId,
      mapId: null,
      mode: row.mode,
      status: 'finished',
      outcome: row.winnerPlayerId ? 'winner' : 'draw',
      startedAt: toIso(row.startedAt),
      endedAt: toIso(row.startedAt),
      stakePerPlayer: n(row.stakePerPlayer),
      potAmount: n(row.potAmount),
      playerCount: n(row.playerCount),
      botCount: n(row.botCount),
      roster: row.roster || '',
    })),
    recentPlayers: recentPlayerRows.map(mapAdminPlayer),
    decisions: [],
    challengeSummary: {},
  };
}

/**
 * @param {string[]} playerIds
 */
async function getPlayersByIds(playerIds) {
  const unique = [
    ...new Set(
      (playerIds || []).filter((id) => typeof id === 'string' && id.trim()),
    ),
  ].slice(0, 200);
  if (!unique.length) return [];
  const pool = getPool();
  const placeholders = unique.map((_, i) => `:id${i}`).join(', ');
  const params = Object.fromEntries(unique.map((id, i) => [`id${i}`, id]));
  const [rows] = await pool.execute(
    `SELECT ${PLAYER_SELECT}
     FROM players
     WHERE id IN (${placeholders})`,
    params,
  );
  return rows.map(mapAdminPlayer);
}

/**
 * @param {{ query: string, limit?: number|string|null }} args
 */
async function searchAdminPlayers({ query, limit = 40 } = {}) {
  const raw = typeof query === 'string' ? query.trim() : '';
  if (raw.length < 1) return [];
  const safeLimit = Math.max(1, Math.min(60, Number(limit) || 40));
  const escaped = raw.toLowerCase().replace(/[\\%_]/g, (ch) => `\\${ch}`);
  const like = `%${escaped}%`;
  const pool = getPool();
  const [rows] = await pool.execute(
    `SELECT ${PLAYER_SELECT}
     FROM players
     WHERE is_bot = 0
       AND (
         LOWER(id) LIKE :like ESCAPE '\\\\'
         OR LOWER(COALESCE(username, '')) LIKE :like ESCAPE '\\\\'
         OR LOWER(COALESCE(display_name, '')) LIKE :like ESCAPE '\\\\'
         OR LOWER(COALESCE(email, '')) LIKE :like ESCAPE '\\\\'
         OR COALESCE(last_ip, '') LIKE :like ESCAPE '\\\\'
         OR LOWER(COALESCE(google_sub, '')) LIKE :like ESCAPE '\\\\'
       )
     ORDER BY last_seen_at DESC
     LIMIT ${safeLimit}`,
    { like },
  );
  return rows.map(mapAdminPlayer);
}

/**
 * Google-auth players for Data tab (emails from Google sign-in).
 * @param {{ withEmailOnly?: boolean, limit?: number|string|null }} [args]
 */
async function listAdminGooglePlayers({ withEmailOnly = false, limit = 5000 } = {}) {
  const safeLimit = Math.max(1, Math.min(20000, Number(limit) || 5000));
  const pool = getPool();
  const emailClause = withEmailOnly
    ? ` AND email IS NOT NULL AND email != ''`
    : '';
  const [rows] = await pool.execute(
    `SELECT ${PLAYER_SELECT}
     FROM players
     WHERE is_bot = 0 AND auth_type = 'google'${emailClause}
     ORDER BY
       CASE WHEN email IS NULL OR email = '' THEN 1 ELSE 0 END,
       created_at DESC
     LIMIT ${safeLimit}`,
  );
  return rows.map(mapAdminPlayer);
}

/**
 * @returns {Promise<{ csv: string, count: number }>}
 */
async function exportAdminGooglePlayersCsv() {
  const rows = await listAdminGooglePlayers({ limit: 20000 });
  const header = [
    'email',
    'playerId',
    'username',
    'name',
    'googleSub',
    'createdAt',
    'lastSeenAt',
    'matchesPlayed',
    'wins',
    'losses',
    'elo',
    'money',
    'chips',
  ];
  const escapeCsv = (value) => {
    const s = value == null ? '' : String(value);
    if (/[",\n\r]/.test(s)) return `"${s.replace(/"/g, '""')}"`;
    return s;
  };
  const lines = [header.join(',')];
  for (const row of rows) {
    lines.push(
      [
        row.email,
        row.playerId,
        row.username,
        row.name,
        row.googleSub,
        row.createdAt,
        row.lastSeenAt,
        row.matchesPlayed,
        row.wins,
        row.losses,
        row.elo,
        row.money,
        row.chips,
      ]
        .map(escapeCsv)
        .join(','),
    );
  }
  return { csv: `${lines.join('\n')}\n`, count: rows.length };
}

module.exports = {
  getAdminDashboardStats,
  getPlayersByIds,
  searchAdminPlayers,
  listAdminGooglePlayers,
  exportAdminGooglePlayersCsv,
};
