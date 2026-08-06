-- 001_init.sql
CREATE TABLE IF NOT EXISTS players (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  public_id VARCHAR(64) NOT NULL UNIQUE,
  display_name VARCHAR(64) NOT NULL,
  email VARCHAR(255) NULL,
  password_hash VARCHAR(255) NULL,
  guest_device_id VARCHAR(128) NULL UNIQUE,
  oauth_provider VARCHAR(32) NULL,
  oauth_subject VARCHAR(255) NULL,
  referral_code VARCHAR(16) NOT NULL UNIQUE,
  coins INT NOT NULL DEFAULT 1000,
  gems INT NOT NULL DEFAULT 0,
  wins INT NOT NULL DEFAULT 0,
  losses INT NOT NULL DEFAULT 0,
  current_streak INT NOT NULL DEFAULT 0,
  best_streak INT NOT NULL DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_oauth (oauth_provider, oauth_subject)
);

CREATE TABLE IF NOT EXISTS matches (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  public_id VARCHAR(64) NOT NULL UNIQUE,
  player1_id BIGINT NULL,
  player2_id BIGINT NULL,
  winner_id BIGINT NULL,
  player1_score INT NULL,
  player2_score INT NULL,
  stake INT NOT NULL DEFAULT 100,
  mode VARCHAR(32) NOT NULL DEFAULT 'quick',
  room_code VARCHAR(16) NULL,
  status ENUM('ongoing','completed','draw','aborted') NOT NULL DEFAULT 'ongoing',
  started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  ended_at TIMESTAMP NULL,
  INDEX idx_matches_players (player1_id, player2_id),
  CONSTRAINT fk_m_p1 FOREIGN KEY (player1_id) REFERENCES players(id),
  CONSTRAINT fk_m_p2 FOREIGN KEY (player2_id) REFERENCES players(id),
  CONSTRAINT fk_m_w FOREIGN KEY (winner_id) REFERENCES players(id)
);

CREATE TABLE IF NOT EXISTS friendships (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  requester_id BIGINT NOT NULL,
  addressee_id BIGINT NOT NULL,
  status ENUM('pending','accepted','rejected') NOT NULL DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_friend (requester_id, addressee_id),
  CONSTRAINT fk_f_req FOREIGN KEY (requester_id) REFERENCES players(id),
  CONSTRAINT fk_f_add FOREIGN KEY (addressee_id) REFERENCES players(id)
);

CREATE TABLE IF NOT EXISTS inventory (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  player_id BIGINT NOT NULL,
  item_id VARCHAR(64) NOT NULL,
  acquired_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_inv (player_id, item_id),
  CONSTRAINT fk_inv_p FOREIGN KEY (player_id) REFERENCES players(id)
);

CREATE TABLE IF NOT EXISTS purchases (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  player_id BIGINT NOT NULL,
  item_id VARCHAR(64) NOT NULL,
  idempotency_key VARCHAR(128) NULL UNIQUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_pur_p FOREIGN KEY (player_id) REFERENCES players(id)
);

CREATE TABLE IF NOT EXISTS rewarded_claims (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  player_id BIGINT NOT NULL,
  reward_coins INT NOT NULL,
  claimed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_reward_day (player_id, claimed_at),
  CONSTRAINT fk_rw_p FOREIGN KEY (player_id) REFERENCES players(id)
);

CREATE TABLE IF NOT EXISTS referrals (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  referrer_id BIGINT NOT NULL,
  referred_id BIGINT NOT NULL UNIQUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_ref_a FOREIGN KEY (referrer_id) REFERENCES players(id),
  CONSTRAINT fk_ref_b FOREIGN KEY (referred_id) REFERENCES players(id)
);

CREATE TABLE IF NOT EXISTS room_audit (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  room_code VARCHAR(16) NOT NULL,
  event_name VARCHAR(64) NOT NULL,
  actor_public_id VARCHAR(64) NULL,
  payload_json JSON NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
