CREATE TABLE IF NOT EXISTS players (
  id VARCHAR(64) NOT NULL PRIMARY KEY,
  display_name VARCHAR(64) NULL,
  username VARCHAR(64) NULL,
  device_id VARCHAR(191) NULL,
  created_ip VARCHAR(45) NULL,
  last_ip VARCHAR(45) NULL,
  auth_type ENUM('guest', 'google') NOT NULL DEFAULT 'guest',
  google_sub VARCHAR(255) NULL,
  elo INT NOT NULL DEFAULT 1000,
  total_points INT NOT NULL DEFAULT 0,
  wins INT NOT NULL DEFAULT 0,
  losses INT NOT NULL DEFAULT 0,
  draws INT NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  last_seen_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_players_device (device_id),
  UNIQUE KEY uq_players_username (username),
  UNIQUE KEY uq_players_google_sub (google_sub),
  KEY idx_players_device_ip (device_id, last_ip),
  KEY idx_players_elo (elo, total_points)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS matches (
  id VARCHAR(64) NOT NULL PRIMARY KEY,
  room_id VARCHAR(64) NOT NULL,
  match_type ENUM('random') NOT NULL,
  winner_player_id VARCHAR(64) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_matches_created (created_at),
  KEY idx_matches_winner (winner_player_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS match_players (
  match_id VARCHAR(64) NOT NULL,
  player_id VARCHAR(64) NOT NULL,
  seat TINYINT NOT NULL,
  card_total INT NOT NULL,
  result ENUM('win', 'loss', 'draw') NOT NULL,
  points_earned INT NOT NULL,
  elo_before INT NOT NULL,
  elo_after INT NOT NULL,
  elo_delta INT NOT NULL,
  PRIMARY KEY (match_id, player_id),
  KEY idx_mp_player (player_id),
  CONSTRAINT fk_mp_match FOREIGN KEY (match_id) REFERENCES matches (id),
  CONSTRAINT fk_mp_player FOREIGN KEY (player_id) REFERENCES players (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Existing DBs: ranking columns added by ensureRankingSchema() in server/db/ranking.js
