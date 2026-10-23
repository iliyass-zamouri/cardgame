const { getPool } = require('./pool');

/** Key/value rows for server switches that admins flip at runtime. */
async function ensureAppSettingsSchema() {
  await getPool().query(`
    CREATE TABLE IF NOT EXISTS app_settings (
      setting_key VARCHAR(64) NOT NULL PRIMARY KEY,
      setting_value TEXT NOT NULL,
      updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  `);
}

/** @returns {Promise<string | null>} */
async function getSetting(key) {
  const [rows] = await getPool().execute(
    'SELECT setting_value FROM app_settings WHERE setting_key = :key',
    { key },
  );
  return rows[0]?.setting_value ?? null;
}

async function setSetting(key, value) {
  await getPool().execute(
    `INSERT INTO app_settings (setting_key, setting_value)
     VALUES (:key, :value) AS new
     ON DUPLICATE KEY UPDATE setting_value = new.setting_value`,
    { key, value },
  );
}

module.exports = {
  ensureAppSettingsSchema,
  getSetting,
  setSetting,
};
