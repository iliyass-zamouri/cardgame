const { getPool } = require('./pool');

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
  if (rows.length === 0) {
    await conn.query(`ALTER TABLE ${table} ADD COLUMN ${column} ${definition}`);
  }
}

async function ensureSessionSchema() {
  const pool = getPool();
  const conn = await pool.getConnection();
  try {
    await addColumnIfMissing(
      conn,
      'players',
      'token_version',
      'INT NOT NULL DEFAULT 0',
    );
    await conn.query(`
      CREATE TABLE IF NOT EXISTS player_reports (
        id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        reporter_id VARCHAR(64) NOT NULL,
        target_id VARCHAR(64) NOT NULL,
        reason VARCHAR(64) NOT NULL,
        details VARCHAR(512) NULL,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        KEY idx_reports_target (target_id),
        KEY idx_reports_reporter (reporter_id),
        CONSTRAINT fk_reports_reporter FOREIGN KEY (reporter_id) REFERENCES players (id) ON DELETE CASCADE,
        CONSTRAINT fk_reports_target FOREIGN KEY (target_id) REFERENCES players (id) ON DELETE CASCADE
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    `);
  } finally {
    conn.release();
  }
}

async function getPlayerTokenVersion(playerId) {
  if (!playerId) return null;
  const [rows] = await getPool().execute(
    `SELECT token_version FROM players WHERE id = :playerId LIMIT 1`,
    { playerId },
  );
  if (rows.length === 0) return null;
  return Number(rows[0].token_version) || 0;
}

async function bumpTokenVersion(playerId) {
  if (!playerId) return null;
  await getPool().execute(
    `UPDATE players SET token_version = token_version + 1 WHERE id = :playerId`,
    { playerId },
  );
  return getPlayerTokenVersion(playerId);
}

async function deletePlayerAccount(playerId) {
  if (!playerId) {
    const error = new Error('playerId is required');
    error.code = 'invalid_player_id';
    throw error;
  }
  const pool = getPool();
  const [result] = await pool.execute(
    `DELETE FROM players WHERE id = :playerId`,
    { playerId },
  );
  if (!result.affectedRows) {
    const error = new Error('Player not found');
    error.code = 'player_not_found';
    throw error;
  }
  return { deleted: true, playerId };
}

async function createPlayerReport({ reporterId, targetId, reason, details }) {
  if (!reporterId || !targetId) {
    const error = new Error('reporter and target required');
    error.code = 'invalid_report';
    throw error;
  }
  if (reporterId === targetId) {
    const error = new Error('Cannot report yourself');
    error.code = 'invalid_report';
    throw error;
  }
  const safeReason = String(reason || 'other').trim().slice(0, 64) || 'other';
  const safeDetails =
    details != null ? String(details).trim().slice(0, 512) : null;
  const [result] = await getPool().execute(
    `INSERT INTO player_reports (reporter_id, target_id, reason, details)
     VALUES (:reporterId, :targetId, :reason, :details)`,
    {
      reporterId,
      targetId,
      reason: safeReason,
      details: safeDetails,
    },
  );
  return { id: result.insertId, ok: true };
}

module.exports = {
  ensureSessionSchema,
  getPlayerTokenVersion,
  bumpTokenVersion,
  deletePlayerAccount,
  createPlayerReport,
};
