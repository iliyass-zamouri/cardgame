CREATE TABLE IF NOT EXISTS players (
  id VARCHAR(64) NOT NULL PRIMARY KEY,
  display_name VARCHAR(64) NULL,
  username VARCHAR(64) NULL,
  device_id VARCHAR(191) NULL,
  created_ip VARCHAR(45) NULL,
  last_ip VARCHAR(45) NULL,
  auth_type ENUM('guest', 'google') NOT NULL DEFAULT 'guest',
  google_sub VARCHAR(255) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  last_seen_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_players_device (device_id),
  UNIQUE KEY uq_players_username (username),
  UNIQUE KEY uq_players_google_sub (google_sub),
  KEY idx_players_device_ip (device_id, last_ip)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
