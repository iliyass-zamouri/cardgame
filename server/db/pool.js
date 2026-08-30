const mysql = require('mysql2/promise');
const fs = require('fs');
const path = require('path');

let pool = null;

function getPool() {
  if (!pool) {
    throw new Error('MySQL pool not initialized. Call initDb() first.');
  }
  return pool;
}

async function initDb() {
  if (pool) {
    return pool;
  }

  pool = mysql.createPool({
    host: process.env.MYSQL_HOST ?? '127.0.0.1',
    port: Number.parseInt(process.env.MYSQL_PORT ?? '3306', 10),
    user: process.env.MYSQL_USER ?? 'cardgame',
    password: process.env.MYSQL_PASSWORD ?? 'cardgame',
    database: process.env.MYSQL_DATABASE ?? 'cardgame',
    waitForConnections: true,
    connectionLimit: 10,
    namedPlaceholders: true,
    multipleStatements: true,
  });

  const conn = await pool.getConnection();
  try {
    await conn.query('SELECT 1');
    const schemaPath = path.join(__dirname, '..', 'sql', 'schema.sql');
    const schema = fs.readFileSync(schemaPath, 'utf8');
    await conn.query(schema);
  } finally {
    conn.release();
  }

  // Lazy require avoids circular dependency with ranking.js → pool.js
  const { ensureRankingSchema } = require('./ranking');
  await ensureRankingSchema();

  const { ensureFriendsSchema } = require('./friends');
  await ensureFriendsSchema();

  const { ensureBotSchema } = require('./bots');
  await ensureBotSchema();

  const { ensureMarketplaceSchema } = require('./marketplace');
  await ensureMarketplaceSchema();

  return pool;
}

async function pingDb() {
  const [rows] = await getPool().query('SELECT 1 AS ok');
  return rows[0]?.ok === 1;
}

async function closeDb() {
  if (!pool) {
    return;
  }
  await pool.end();
  pool = null;
}

module.exports = {
  getPool,
  initDb,
  pingDb,
  closeDb,
};
