CREATE TABLE IF NOT EXISTS players (
  id VARCHAR(64) NOT NULL PRIMARY KEY,
  display_name VARCHAR(64) NULL,
  username VARCHAR(64) NULL,
  device_id VARCHAR(191) NULL,
  created_ip VARCHAR(45) NULL,
  last_ip VARCHAR(45) NULL,
  auth_type ENUM('guest', 'google') NOT NULL DEFAULT 'guest',
  google_sub VARCHAR(255) NULL,
  is_bot TINYINT(1) NOT NULL DEFAULT 0,
  money INT NOT NULL DEFAULT 500,
  chips INT NOT NULL DEFAULT 1,
  avatar_id VARCHAR(64) NOT NULL DEFAULT 'default',
  deck_id VARCHAR(64) NOT NULL DEFAULT 'default',
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
  KEY idx_players_is_bot (is_bot),
  KEY idx_players_elo (elo, total_points)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS matches (
  id VARCHAR(64) NOT NULL PRIMARY KEY,
  room_id VARCHAR(64) NOT NULL,
  match_type ENUM('random') NOT NULL,
  stake_per_player INT NOT NULL DEFAULT 0,
  pot_amount INT NOT NULL DEFAULT 0,
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

CREATE TABLE IF NOT EXISTS player_items (
  id VARCHAR(64) NOT NULL PRIMARY KEY,
  player_id VARCHAR(64) NOT NULL,
  item_type ENUM('avatar', 'deck') NOT NULL,
  item_id VARCHAR(64) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_player_item (player_id, item_type, item_id),
  KEY idx_player_items_player (player_id),
  CONSTRAINT fk_pi_player FOREIGN KEY (player_id) REFERENCES players (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS iap_redemptions (
  transaction_id VARCHAR(191) NOT NULL PRIMARY KEY,
  player_id VARCHAR(64) NOT NULL,
  product_id VARCHAR(64) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_iap_player (player_id),
  CONSTRAINT fk_iap_player FOREIGN KEY (player_id) REFERENCES players (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS friendships (
  id VARCHAR(64) NOT NULL PRIMARY KEY,
  player_id VARCHAR(64) NOT NULL,
  friend_id VARCHAR(64) NOT NULL,
  status ENUM('pending', 'accepted', 'declined', 'blocked') NOT NULL DEFAULT 'pending',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_friendship_pair (player_id, friend_id),
  KEY idx_friendships_player_status (player_id, status),
  KEY idx_friendships_friend_status (friend_id, status),
  CONSTRAINT fk_fs_player FOREIGN KEY (player_id) REFERENCES players (id) ON DELETE CASCADE,
  CONSTRAINT fk_fs_friend FOREIGN KEY (friend_id) REFERENCES players (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Existing DBs: ranking columns added by ensureRankingSchema() in server/db/ranking.js
-- Existing DBs: friendships table added by ensureFriendsSchema() in server/db/friends.js
-- Existing DBs: is_bot column added by ensureBotSchema() in server/db/bots.js
