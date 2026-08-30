const { randomUUID } = require('crypto');
const { getPool } = require('./pool');
const { generateGuestIdentity } = require('../auth/guest_name');

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
  } finally {
    conn.release();
  }
}

/**
 * Acquire an idle bot user or create a new bot record in MySQL.
 * @param {Set<string>|Array<string>} activeBotPlayerIds
 * @returns {Promise<{ playerId: string, displayName: string, username: string, elo: number }>}
 */
async function acquireBotUser(activeBotPlayerIds = new Set()) {
  const activeSet = activeBotPlayerIds instanceof Set
    ? activeBotPlayerIds
    : new Set(activeBotPlayerIds || []);

  let pool;
  try {
    pool = getPool();
  } catch {
    pool = null;
  }

  if (!pool) {
    // In-memory fallback for tests without DB connection
    const id = `bot-${randomUUID()}`;
    const identity = generateGuestIdentity();
    return {
      playerId: id,
      displayName: identity.name,
      username: identity.username,
      elo: 1000,
    };
  }

  const [rows] = await pool.execute(
    `SELECT id, display_name, username, elo
     FROM players
     WHERE is_bot = 1
     ORDER BY last_seen_at ASC`,
  );

  const idleBots = rows.filter((row) => !activeSet.has(row.id));
  if (idleBots.length > 0) {
    const selected = idleBots[Math.floor(Math.random() * idleBots.length)];
    await pool.execute(
      `UPDATE players SET last_seen_at = CURRENT_TIMESTAMP WHERE id = :id`,
      { id: selected.id },
    );
    return {
      playerId: selected.id,
      displayName: selected.display_name || 'Bot',
      username: selected.username || 'bot',
      elo: selected.elo ?? 1000,
    };
  }

  // Create new bot player
  for (let attempt = 0; attempt < 5; attempt += 1) {
    const id = `bot-${randomUUID()}`;
    const identity = generateGuestIdentity();
    try {
      await pool.execute(
        `INSERT INTO players (
           id, display_name, username, auth_type, is_bot, elo, total_points, wins, losses, draws
         ) VALUES (
           :id, :displayName, :username, 'guest', 1, 1000, 0, 0, 0, 0
         )`,
        {
          id,
          displayName: identity.name,
          username: identity.username,
        },
      );
      return {
        playerId: id,
        displayName: identity.name,
        username: identity.username,
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
};
