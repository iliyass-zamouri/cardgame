import crypto from 'node:crypto';
import bcrypt from 'bcryptjs';
import { SignJWT, jwtVerify } from 'jose';
import { getPool } from '../infra/db.js';

const encoder = new TextEncoder();

function jwtSecret() {
  return encoder.encode(process.env.JWT_SECRET ?? 'dev-cardgame-secret-change-me');
}

export async function issueToken(player) {
  return new SignJWT({
    sub: player.public_id,
    displayName: player.display_name,
  })
    .setProtectedHeader({ alg: 'HS256' })
    .setIssuedAt()
    .setExpirationTime('30d')
    .sign(jwtSecret());
}

export async function verifyBearer(authHeader) {
  if (!authHeader?.startsWith('Bearer ')) return null;
  const token = authHeader.slice(7);
  try {
    const { payload } = await jwtVerify(token, jwtSecret());
    return payload.sub;
  } catch {
    return null;
  }
}

function publicId() {
  return `pl_${crypto.randomBytes(8).toString('hex')}`;
}

function referralCode() {
  return crypto.randomBytes(4).toString('hex').toUpperCase();
}

export async function findOrCreateGuest({ deviceId, displayName }) {
  const pool = getPool();
  const [existing] = await pool.query(
    'SELECT * FROM players WHERE guest_device_id = ? LIMIT 1',
    [deviceId],
  );
  if (existing.length) {
    return existing[0];
  }
  const id = publicId();
  const name = displayName?.trim() || `Guest-${id.slice(-4)}`;
  await pool.query(
    `INSERT INTO players
      (public_id, display_name, guest_device_id, referral_code, coins, gems, wins, losses)
     VALUES (?, ?, ?, ?, 1000, 0, 0, 0)`,
    [id, name, deviceId, referralCode()],
  );
  const [rows] = await pool.query('SELECT * FROM players WHERE public_id = ?', [id]);
  return rows[0];
}

export async function upsertOAuthPlayer({ provider, providerId, displayName, email }) {
  const pool = getPool();
  const [existing] = await pool.query(
    'SELECT * FROM players WHERE oauth_provider = ? AND oauth_subject = ? LIMIT 1',
    [provider, providerId],
  );
  if (existing.length) {
    if (displayName) {
      await pool.query('UPDATE players SET display_name = ? WHERE id = ?', [
        displayName,
        existing[0].id,
      ]);
    }
    const [rows] = await pool.query('SELECT * FROM players WHERE id = ?', [existing[0].id]);
    return rows[0];
  }
  const id = publicId();
  const name = displayName?.trim() || `${provider}-${id.slice(-4)}`;
  await pool.query(
    `INSERT INTO players
      (public_id, display_name, oauth_provider, oauth_subject, email, referral_code, coins, gems, wins, losses)
     VALUES (?, ?, ?, ?, ?, ?, 1000, 0, 0, 0)`,
    [id, name, provider, providerId, email ?? null, referralCode()],
  );
  const [rows] = await pool.query('SELECT * FROM players WHERE public_id = ?', [id]);
  return rows[0];
}

export async function getPlayer(publicIdValue) {
  const [rows] = await getPool().query(
    'SELECT * FROM players WHERE public_id = ? LIMIT 1',
    [publicIdValue],
  );
  return rows[0] ?? null;
}

export async function searchPlayers(q, limit = 20) {
  const like = `%${q}%`;
  const [rows] = await getPool().query(
    `SELECT public_id, display_name, coins, gems, wins, losses
     FROM players
     WHERE display_name LIKE ? OR public_id LIKE ?
     ORDER BY wins DESC LIMIT ?`,
    [like, like, limit],
  );
  return rows;
}

export async function listPlayerMatches(publicIdValue, limit = 20) {
  const player = await getPlayer(publicIdValue);
  if (!player) return [];
  const [rows] = await getPool().query(
    `SELECT m.public_id, m.status, m.stake, m.winner_id, m.started_at, m.ended_at,
            m.player1_id, m.player2_id, m.player1_score, m.player2_score
     FROM matches m
     WHERE m.player1_id = ? OR m.player2_id = ?
     ORDER BY m.started_at DESC LIMIT ?`,
    [player.id, player.id, limit],
  );
  return rows;
}

export async function createMatchRecord({ players, stake, mode, roomCode }) {
  const pool = getPool();
  const matchPublicId = `mt_${crypto.randomBytes(8).toString('hex')}`;
  const p1 = await getPlayer(players[0].playerId);
  const p2 = await getPlayer(players[1].playerId);
  await pool.query(
    `INSERT INTO matches
      (public_id, player1_id, player2_id, stake, mode, room_code, status, started_at)
     VALUES (?, ?, ?, ?, ?, ?, 'ongoing', NOW())`,
    [matchPublicId, p1?.id ?? null, p2?.id ?? null, stake, mode, roomCode ?? null],
  );
  return { publicId: matchPublicId };
}

export async function finishMatchRecord({
  publicId: matchPublicId,
  winnerPublicId,
  player1Score,
  player2Score,
  stake,
}) {
  const pool = getPool();
  const [matches] = await pool.query('SELECT * FROM matches WHERE public_id = ?', [
    matchPublicId,
  ]);
  const match = matches[0];
  if (!match || match.status !== 'ongoing') return;

  let winnerId = null;
  if (winnerPublicId) {
    const winner = await getPlayer(winnerPublicId);
    winnerId = winner?.id ?? null;
  }

  await pool.query(
    `UPDATE matches SET status = ?, winner_id = ?, player1_score = ?, player2_score = ?,
      ended_at = NOW() WHERE id = ?`,
    [winnerId ? 'completed' : 'draw', winnerId, player1Score, player2Score, match.id],
  );

  if (winnerId && match.player1_id && match.player2_id) {
    const loserId = winnerId === match.player1_id ? match.player2_id : match.player1_id;
    await pool.query(
      'UPDATE players SET wins = wins + 1, coins = coins + ?, current_streak = current_streak + 1, best_streak = GREATEST(best_streak, current_streak + 1) WHERE id = ?',
      [stake, winnerId],
    );
    await pool.query(
      'UPDATE players SET losses = losses + 1, coins = GREATEST(0, coins - ?), current_streak = 0 WHERE id = ?',
      [stake, loserId],
    );
  }
}

export async function listFriends(publicIdValue) {
  const player = await getPlayer(publicIdValue);
  if (!player) return [];
  const [rows] = await getPool().query(
    `SELECT p.public_id, p.display_name, f.status, f.requester_id = ? AS is_outgoing
     FROM friendships f
     JOIN players p ON p.id = IF(f.requester_id = ?, f.addressee_id, f.requester_id)
     WHERE (f.requester_id = ? OR f.addressee_id = ?) AND f.status IN ('pending','accepted')`,
    [player.id, player.id, player.id, player.id],
  );
  return rows;
}

export async function requestFriend(fromPublicId, toPublicId) {
  const from = await getPlayer(fromPublicId);
  const to = await getPlayer(toPublicId);
  if (!from || !to) return { error: 'not_found' };
  if (from.id === to.id) return { error: 'self' };
  try {
    await getPool().query(
      'INSERT INTO friendships (requester_id, addressee_id, status) VALUES (?, ?, ?)',
      [from.id, to.id, 'pending'],
    );
    return { ok: true };
  } catch {
    return { error: 'already_pending' };
  }
}

export async function respondFriend(publicIdValue, otherPublicId, accept) {
  const me = await getPlayer(publicIdValue);
  const other = await getPlayer(otherPublicId);
  if (!me || !other) return { error: 'not_found' };
  const status = accept ? 'accepted' : 'rejected';
  const [result] = await getPool().query(
    `UPDATE friendships SET status = ?
     WHERE requester_id = ? AND addressee_id = ? AND status = 'pending'`,
    [status, other.id, me.id],
  );
  if (result.affectedRows === 0) return { error: 'not_pending' };
  return { ok: true };
}

export async function removeFriend(publicIdValue, otherPublicId) {
  const me = await getPlayer(publicIdValue);
  const other = await getPlayer(otherPublicId);
  if (!me || !other) return { error: 'not_found' };
  await getPool().query(
    `DELETE FROM friendships
     WHERE (requester_id = ? AND addressee_id = ?) OR (requester_id = ? AND addressee_id = ?)`,
    [me.id, other.id, other.id, me.id],
  );
  return { ok: true };
}

export async function getShopCatalog() {
  return [
    { id: 'coins_500', type: 'currency', coins: 500, priceGems: 50 },
    { id: 'coins_2000', type: 'currency', coins: 2000, priceGems: 150 },
    { id: 'card_back_gold', type: 'cosmetic', priceCoins: 300 },
    { id: 'table_felt_emerald', type: 'cosmetic', priceCoins: 500 },
  ];
}

export async function purchaseItem({ playerPublicId, itemId, idempotencyKey }) {
  const pool = getPool();
  if (idempotencyKey) {
    const [existing] = await pool.query(
      'SELECT * FROM purchases WHERE idempotency_key = ? LIMIT 1',
      [idempotencyKey],
    );
    if (existing.length) {
      return { ok: true, replay: true, purchaseId: existing[0].id };
    }
  }
  const player = await getPlayer(playerPublicId);
  if (!player) return { error: 'not_found' };
  const catalog = await getShopCatalog();
  const item = catalog.find((i) => i.id === itemId);
  if (!item) return { error: 'invalid' };

  if (item.type === 'currency') {
    if (player.gems < item.priceGems) return { error: 'insufficient_funds' };
    await pool.query('UPDATE players SET gems = gems - ?, coins = coins + ? WHERE id = ?', [
      item.priceGems,
      item.coins,
      player.id,
    ]);
  } else {
    if (player.coins < item.priceCoins) return { error: 'insufficient_funds' };
    await pool.query('UPDATE players SET coins = coins - ? WHERE id = ?', [
      item.priceCoins,
      player.id,
    ]);
    await pool.query(
      'INSERT INTO inventory (player_id, item_id) VALUES (?, ?) ON DUPLICATE KEY UPDATE item_id = item_id',
      [player.id, item.id],
    );
  }

  const [result] = await pool.query(
    'INSERT INTO purchases (player_id, item_id, idempotency_key) VALUES (?, ?, ?)',
    [player.id, itemId, idempotencyKey ?? null],
  );
  return { ok: true, purchaseId: result.insertId };
}

export async function claimRewardedAd(playerPublicId) {
  const pool = getPool();
  const player = await getPlayer(playerPublicId);
  if (!player) return { error: 'not_found' };
  const [rows] = await pool.query(
    `SELECT COUNT(*) AS c FROM rewarded_claims
     WHERE player_id = ? AND claimed_at >= CURDATE()`,
    [player.id],
  );
  if (rows[0].c >= 5) return { error: 'daily_cap' };
  await pool.query('INSERT INTO rewarded_claims (player_id, reward_coins) VALUES (?, ?)', [
    player.id,
    50,
  ]);
  await pool.query('UPDATE players SET coins = coins + 50 WHERE id = ?', [player.id]);
  return { ok: true, coins: 50 };
}

export async function claimReferral(claimerPublicId, code) {
  const pool = getPool();
  const claimer = await getPlayer(claimerPublicId);
  if (!claimer) return { error: 'not_found' };
  const [owners] = await pool.query('SELECT * FROM players WHERE referral_code = ?', [code]);
  const owner = owners[0];
  if (!owner) return { error: 'invalid' };
  if (owner.id === claimer.id) return { error: 'own_code' };
  try {
    await pool.query(
      'INSERT INTO referrals (referrer_id, referred_id) VALUES (?, ?)',
      [owner.id, claimer.id],
    );
  } catch {
    return { error: 'already_claimed' };
  }
  await pool.query('UPDATE players SET coins = coins + 100 WHERE id IN (?, ?)', [
    owner.id,
    claimer.id,
  ]);
  return { ok: true };
}

export async function hashPassword(password) {
  return bcrypt.hash(password, 10);
}

export async function verifyPassword(password, hash) {
  return bcrypt.compare(password, hash);
}
