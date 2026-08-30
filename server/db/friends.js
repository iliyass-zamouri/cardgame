const { randomUUID } = require('crypto');
const { getPool } = require('./pool');

const USERNAME_REGEX = /^[a-z0-9_]{3,20}$/;

function isValidUsernameFormat(username) {
  if (typeof username !== 'string') return false;
  return USERNAME_REGEX.test(username.trim().toLowerCase());
}

function normalizeUsername(username) {
  if (typeof username !== 'string') return '';
  return username.trim().toLowerCase();
}

async function ensureFriendsSchema() {
  const pool = getPool();
  const conn = await pool.getConnection();
  try {
    await conn.query(`
      CREATE TABLE IF NOT EXISTS friendships (
        id VARCHAR(64) NOT NULL PRIMARY KEY,
        player_id VARCHAR(64) NOT NULL,
        friend_id VARCHAR(64) NOT NULL,
        status ENUM('pending', 'accepted', 'declined', 'blocked') NOT NULL DEFAULT 'pending',
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        UNIQUE KEY uq_friendship_pair (player_id, friend_id),
        KEY idx_friendships_player_status (player_id, status),
        KEY idx_friendships_friend_status (friend_id, status)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    `);
  } finally {
    conn.release();
  }
}

/**
 * Check if username is available (optionally ignoring currentPlayerId).
 */
async function isUsernameAvailable(username, currentPlayerId = null) {
  const normalized = normalizeUsername(username);
  if (!isValidUsernameFormat(normalized)) {
    return { available: false, reason: 'invalid_format' };
  }
  const pool = getPool();
  const [rows] = await pool.execute(
    `SELECT id FROM players WHERE LOWER(username) = :username LIMIT 1`,
    { username: normalized },
  );
  if (rows.length === 0) {
    return { available: true, username: normalized };
  }
  if (currentPlayerId && rows[0].id === currentPlayerId) {
    return { available: true, username: normalized, isCurrent: true };
  }
  return { available: false, reason: 'username_taken' };
}

/**
 * Update a player's profile (display_name and/or username).
 */
async function updatePlayerProfile({ playerId, name, username }) {
  if (!playerId) throw new Error('playerId is required');
  const pool = getPool();

  const updates = [];
  const params = { playerId };

  if (typeof name === 'string' && name.trim()) {
    const trimmedName = name.trim().slice(0, 64);
    updates.push('display_name = :displayName');
    params.displayName = trimmedName;
  }

  if (typeof username === 'string' && username.trim()) {
    const normalized = normalizeUsername(username);
    if (!isValidUsernameFormat(normalized)) {
      const err = new Error('Username must be 3-20 characters: lowercase letters, numbers, underscores');
      err.code = 'invalid_format';
      throw err;
    }
    // Check collision
    const avail = await isUsernameAvailable(normalized, playerId);
    if (!avail.available) {
      const err = new Error('Username is already taken');
      err.code = 'username_taken';
      throw err;
    }
    updates.push('username = :username');
    params.username = normalized;
  }

  if (updates.length === 0) {
    // Return existing
    const [rows] = await pool.execute(
      `SELECT id, display_name, username, auth_type, money, chips, elo, total_points, wins, losses, draws FROM players WHERE id = :playerId LIMIT 1`,
      { playerId },
    );
    return rows[0] || null;
  }

  await pool.execute(
    `UPDATE players SET ${updates.join(', ')}, last_seen_at = CURRENT_TIMESTAMP WHERE id = :playerId`,
    params,
  );

  const [rows] = await pool.execute(
    `SELECT id, display_name, username, auth_type, money, chips, elo, total_points, wins, losses, draws FROM players WHERE id = :playerId LIMIT 1`,
    { playerId },
  );
  return rows[0] || null;
}

/**
 * Search players by username or display_name prefix/substring.
 * Also computes friendship relationship to the requesting playerId.
 */
async function searchPlayers({ query, playerId, limit = 20, onlinePlayerIds = new Set() }) {
  if (!query || typeof query !== 'string' || !query.trim()) {
    return { players: [] };
  }
  const cleanQuery = query.trim().toLowerCase().replace(/^@/, '');
  if (!cleanQuery) return { players: [] };

  const pool = getPool();
  const maxLimit = Math.min(Math.max(Number(limit) || 20, 1), 50);

  // Search by username prefix, username substring, or display_name substring
  const [rows] = await pool.execute(
    `SELECT id, display_name, username, elo, total_points, wins, losses, draws
     FROM players
     WHERE LOWER(username) LIKE :pattern OR LOWER(display_name) LIKE :pattern
     ORDER BY
       CASE
         WHEN LOWER(username) = :exact THEN 0
         WHEN LOWER(username) LIKE :prefix THEN 1
         WHEN LOWER(display_name) LIKE :prefix THEN 2
         ELSE 3
       END,
       elo DESC
     LIMIT ${maxLimit}`,
    {
      exact: cleanQuery,
      prefix: `${cleanQuery}%`,
      pattern: `%${cleanQuery}%`,
    },
  );

  if (rows.length === 0) return { players: [] };

  // Fetch friendship relations with target players if playerId provided
  const targetIds = rows.map((r) => r.id);
  const relations = new Map();

  if (playerId && targetIds.length > 0) {
    // Both directions
    const [relRows] = await pool.execute(
      `SELECT id, player_id, friend_id, status
       FROM friendships
       WHERE (player_id = :playerId AND friend_id IN (${targetIds.map((_, i) => `:t${i}`).join(', ')}))
          OR (friend_id = :playerId AND player_id IN (${targetIds.map((_, i) => `:t${i}`).join(', ')}))`,
      {
        playerId,
        ...Object.fromEntries(targetIds.map((id, i) => [`t${i}`, id])),
      },
    );

    for (const rel of relRows) {
      if (rel.status === 'accepted') {
        const other = rel.player_id === playerId ? rel.friend_id : rel.player_id;
        relations.set(other, { status: 'accepted', friendshipId: rel.id });
      } else if (rel.status === 'pending') {
        if (rel.player_id === playerId) {
          relations.set(rel.friend_id, { status: 'pending_sent', friendshipId: rel.id });
        } else {
          relations.set(rel.player_id, { status: 'pending_received', friendshipId: rel.id });
        }
      }
    }
  }

  const results = rows.map((row) => {
    let relationship = 'none';
    let friendshipId = null;
    if (playerId && row.id === playerId) {
      relationship = 'self';
    } else if (relations.has(row.id)) {
      const rel = relations.get(row.id);
      relationship = rel.status;
      friendshipId = rel.friendshipId;
    }

    return {
      playerId: row.id,
      name: row.display_name,
      username: row.username,
      elo: row.elo,
      totalPoints: row.total_points,
      wins: row.wins,
      losses: row.losses,
      draws: row.draws,
      relationship,
      friendshipId,
      isOnline: onlinePlayerIds.has(row.id),
    };
  });

  return { players: results };
}

/**
 * Get all friends & pending requests for a player.
 */
async function getPlayerFriends({ playerId, onlinePlayerIds = new Set() }) {
  if (!playerId) return { friends: [], incomingRequests: [], outgoingRequests: [] };

  const pool = getPool();

  // 1. Accepted friendships (either direction)
  const [acceptedRows] = await pool.execute(
    `SELECT
       f.id AS friendship_id,
       f.created_at AS friendship_since,
       p.id AS player_id,
       p.display_name,
       p.username,
       p.elo,
       p.total_points,
       p.wins,
       p.losses,
       p.draws
     FROM friendships f
     INNER JOIN players p
       ON p.id = (CASE WHEN f.player_id = :playerId THEN f.friend_id ELSE f.player_id END)
     WHERE (f.player_id = :playerId OR f.friend_id = :playerId)
       AND f.status = 'accepted'
     ORDER BY p.display_name ASC`,
    { playerId },
  );

  // 2. Incoming pending requests (others sent to playerId)
  const [incomingRows] = await pool.execute(
    `SELECT
       f.id AS request_id,
       f.created_at,
       p.id AS player_id,
       p.display_name,
       p.username,
       p.elo,
       p.total_points,
       p.wins,
       p.losses,
       p.draws
     FROM friendships f
     INNER JOIN players p ON p.id = f.player_id
     WHERE f.friend_id = :playerId AND f.status = 'pending'
     ORDER BY f.created_at DESC`,
    { playerId },
  );

  // 3. Outgoing pending requests (playerId sent to others)
  const [outgoingRows] = await pool.execute(
    `SELECT
       f.id AS request_id,
       f.created_at,
       p.id AS player_id,
       p.display_name,
       p.username,
       p.elo,
       p.total_points,
       p.wins,
       p.losses,
       p.draws
     FROM friendships f
     INNER JOIN players p ON p.id = f.friend_id
     WHERE f.player_id = :playerId AND f.status = 'pending'
     ORDER BY f.created_at DESC`,
    { playerId },
  );

  const friends = acceptedRows.map((r) => ({
    friendshipId: r.friendship_id,
    playerId: r.player_id,
    name: r.display_name,
    username: r.username,
    elo: r.elo,
    totalPoints: r.total_points,
    wins: r.wins,
    losses: r.losses,
    draws: r.draws,
    isOnline: onlinePlayerIds.has(r.player_id),
    since: r.friendship_since instanceof Date ? r.friendship_since.toISOString() : r.friendship_since,
  }));

  // Sort friends: online first, then Elo desc, then name
  friends.sort((a, b) => {
    if (a.isOnline !== b.isOnline) return a.isOnline ? -1 : 1;
    if (a.elo !== b.elo) return b.elo - a.elo;
    return (a.name || '').localeCompare(b.name || '');
  });

  const incomingRequests = incomingRows.map((r) => ({
    requestId: r.request_id,
    playerId: r.player_id,
    name: r.display_name,
    username: r.username,
    elo: r.elo,
    totalPoints: r.total_points,
    wins: r.wins,
    losses: r.losses,
    draws: r.draws,
    isOnline: onlinePlayerIds.has(r.player_id),
    createdAt: r.created_at instanceof Date ? r.created_at.toISOString() : r.created_at,
  }));

  const outgoingRequests = outgoingRows.map((r) => ({
    requestId: r.request_id,
    playerId: r.player_id,
    name: r.display_name,
    username: r.username,
    elo: r.elo,
    totalPoints: r.total_points,
    wins: r.wins,
    losses: r.losses,
    draws: r.draws,
    isOnline: onlinePlayerIds.has(r.player_id),
    createdAt: r.created_at instanceof Date ? r.created_at.toISOString() : r.created_at,
  }));

  return { friends, incomingRequests, outgoingRequests };
}

/**
 * Send a friend request. If reciprocal request already exists, auto-accepts.
 */
async function sendFriendRequest({ playerId, targetPlayerId, targetUsername }) {
  if (!playerId) throw new Error('playerId is required');

  const pool = getPool();

  let resolvedTargetId = targetPlayerId;
  if (!resolvedTargetId && targetUsername) {
    const norm = normalizeUsername(targetUsername);
    const [pRows] = await pool.execute(
      `SELECT id FROM players WHERE LOWER(username) = :username LIMIT 1`,
      { username: norm },
    );
    if (pRows.length === 0) {
      const err = new Error('Player not found');
      err.code = 'player_not_found';
      throw err;
    }
    resolvedTargetId = pRows[0].id;
  }

  if (!resolvedTargetId) {
    const err = new Error('targetPlayerId or targetUsername required');
    err.code = 'invalid_target';
    throw err;
  }

  if (playerId === resolvedTargetId) {
    const err = new Error('Cannot add yourself as a friend');
    err.code = 'cannot_friend_self';
    throw err;
  }

  // Check reciprocal request
  const [recip] = await pool.execute(
    `SELECT id, status FROM friendships WHERE player_id = :targetId AND friend_id = :playerId LIMIT 1`,
    { targetId: resolvedTargetId, playerId },
  );

  if (recip.length > 0) {
    if (recip[0].status === 'accepted') {
      return { status: 'accepted', friendshipId: recip[0].id, alreadyFriends: true };
    }
    if (recip[0].status === 'pending') {
      // Reciprocal pending exists -> Auto-accept!
      await pool.execute(
        `UPDATE friendships SET status = 'accepted' WHERE id = :id`,
        { id: recip[0].id },
      );
      return { status: 'accepted', friendshipId: recip[0].id, autoAccepted: true };
    }
  }

  // Check direct request
  const [existing] = await pool.execute(
    `SELECT id, status FROM friendships WHERE player_id = :playerId AND friend_id = :targetId LIMIT 1`,
    { playerId, targetId: resolvedTargetId },
  );

  if (existing.length > 0) {
    if (existing[0].status === 'accepted') {
      return { status: 'accepted', friendshipId: existing[0].id, alreadyFriends: true };
    }
    if (existing[0].status === 'pending') {
      return { status: 'pending', requestId: existing[0].id, alreadyPending: true };
    }
    // Re-open declined/canceled
    await pool.execute(
      `UPDATE friendships SET status = 'pending' WHERE id = :id`,
      { id: existing[0].id },
    );
    return { status: 'pending', requestId: existing[0].id, reOpened: true };
  }

  const id = `friendship-${randomUUID()}`;
  await pool.execute(
    `INSERT INTO friendships (id, player_id, friend_id, status)
     VALUES (:id, :playerId, :targetId, 'pending')`,
    { id, playerId, targetId: resolvedTargetId },
  );

  return { status: 'pending', requestId: id };
}

/**
 * Accept an incoming friend request.
 */
async function acceptFriendRequest({ playerId, requesterId, requestId }) {
  if (!playerId) throw new Error('playerId is required');
  const pool = getPool();

  let query = `UPDATE friendships SET status = 'accepted' WHERE status = 'pending' AND friend_id = :playerId`;
  const params = { playerId };

  if (requestId) {
    query += ` AND id = :requestId`;
    params.requestId = requestId;
  } else if (requesterId) {
    query += ` AND player_id = :requesterId`;
    params.requesterId = requesterId;
  } else {
    throw new Error('requestId or requesterId required');
  }

  const [result] = await pool.execute(query, params);
  if (result.affectedRows === 0) {
    const err = new Error('Friend request not found');
    err.code = 'request_not_found';
    throw err;
  }
  return { success: true };
}

/**
 * Decline an incoming friend request.
 */
async function declineFriendRequest({ playerId, requesterId, requestId }) {
  if (!playerId) throw new Error('playerId is required');
  const pool = getPool();

  let query = `DELETE FROM friendships WHERE status = 'pending' AND friend_id = :playerId`;
  const params = { playerId };

  if (requestId) {
    query += ` AND id = :requestId`;
    params.requestId = requestId;
  } else if (requesterId) {
    query += ` AND player_id = :requesterId`;
    params.requesterId = requesterId;
  } else {
    throw new Error('requestId or requesterId required');
  }

  const [result] = await pool.execute(query, params);
  return { success: result.affectedRows > 0 };
}

/**
 * Cancel an outgoing friend request.
 */
async function cancelFriendRequest({ playerId, targetPlayerId, requestId }) {
  if (!playerId) throw new Error('playerId is required');
  const pool = getPool();

  let query = `DELETE FROM friendships WHERE status = 'pending' AND player_id = :playerId`;
  const params = { playerId };

  if (requestId) {
    query += ` AND id = :requestId`;
    params.requestId = requestId;
  } else if (targetPlayerId) {
    query += ` AND friend_id = :targetPlayerId`;
    params.targetPlayerId = targetPlayerId;
  } else {
    throw new Error('requestId or targetPlayerId required');
  }

  const [result] = await pool.execute(query, params);
  return { success: result.affectedRows > 0 };
}

/**
 * Remove an existing friendship.
 */
async function removeFriend({ playerId, friendId, friendshipId }) {
  if (!playerId) throw new Error('playerId is required');
  const pool = getPool();

  let query = `DELETE FROM friendships WHERE (player_id = :playerId AND friend_id = :friendId) OR (friend_id = :playerId AND player_id = :friendId)`;
  const params = { playerId, friendId: friendId || '' };

  if (friendshipId) {
    query = `DELETE FROM friendships WHERE id = :friendshipId AND (player_id = :playerId OR friend_id = :playerId)`;
    params.friendshipId = friendshipId;
  }

  const [result] = await pool.execute(query, params);
  return { success: result.affectedRows > 0 };
}

module.exports = {
  isValidUsernameFormat,
  normalizeUsername,
  ensureFriendsSchema,
  isUsernameAvailable,
  updatePlayerProfile,
  searchPlayers,
  getPlayerFriends,
  sendFriendRequest,
  acceptFriendRequest,
  declineFriendRequest,
  cancelFriendRequest,
  removeFriend,
};
