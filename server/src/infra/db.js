import 'dotenv/config';
import mysql from 'mysql2/promise';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

let pool;

export function getPool() {
  if (!pool) {
    pool = mysql.createPool({
      host: process.env.MYSQL_HOST ?? '127.0.0.1',
      port: Number.parseInt(process.env.MYSQL_PORT ?? '3306', 10),
      user: process.env.MYSQL_USER ?? 'cardgame',
      password: process.env.MYSQL_PASSWORD ?? 'cardgame',
      database: process.env.MYSQL_DATABASE ?? 'cardgame',
      waitForConnections: true,
      connectionLimit: 10,
    });
  }
  return pool;
}

export async function initDb() {
  const p = getPool();
  await p.query('SELECT 1');
  await runMigrations();
}

export async function pingDb() {
  const [rows] = await getPool().query('SELECT 1 AS ok');
  return rows?.[0]?.ok === 1;
}

export async function closeDb() {
  if (pool) {
    await pool.end();
    pool = null;
  }
}

async function runMigrations() {
  const p = getPool();
  await p.query(`
    CREATE TABLE IF NOT EXISTS schema_migrations (
      id INT AUTO_INCREMENT PRIMARY KEY,
      name VARCHAR(255) NOT NULL UNIQUE,
      applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  `);
  const dir = path.join(__dirname, '..', 'migrations', 'sql');
  if (!fs.existsSync(dir)) return;
  const files = fs.readdirSync(dir).filter((f) => f.endsWith('.sql')).sort();
  const [applied] = await p.query('SELECT name FROM schema_migrations');
  const done = new Set(applied.map((r) => r.name));
  for (const file of files) {
    if (done.has(file)) continue;
    const sql = fs.readFileSync(path.join(dir, file), 'utf8');
    const conn = await p.getConnection();
    try {
      await conn.beginTransaction();
      for (const stmt of sql.split(';').map((s) => s.trim()).filter(Boolean)) {
        await conn.query(stmt);
      }
      await conn.query('INSERT INTO schema_migrations (name) VALUES (?)', [file]);
      await conn.commit();
      console.log(`[migrate] applied ${file}`);
    } catch (err) {
      await conn.rollback();
      throw err;
    } finally {
      conn.release();
    }
  }
}
