const crypto = require('crypto');
const { AVATAR_CATALOG, DECK_CATALOG } = require('./marketplace');
const { rollChest } = require('../daily_rewards');

const MAX_CHEST_DEPTH = 1;

function scale(amount, multiplier) {
  return Math.floor(amount * multiplier);
}

function grantCurrency(currency, ctx) {
  const amount = scale(currency.amount, ctx.multiplier);
  ctx.totals[currency.type] += amount;
  return { type: currency.type, amount };
}

async function ownsItem(conn, playerId, itemType, itemId) {
  const [rows] = await conn.execute(
    `SELECT 1 AS owned FROM player_items
     WHERE player_id = :playerId AND item_type = :itemType AND item_id = :itemId
     LIMIT 1`,
    { playerId, itemType, itemId },
  );
  return rows.length > 0;
}

/** Avatars and decks. A duplicate or unknown id converts to its currency fallback. */
async function grantItem(conn, playerId, reward, ctx) {
  const catalog = reward.type === 'avatar' ? AVATAR_CATALOG : DECK_CATALOG;
  const entry = { type: reward.type, itemId: reward.itemId };

  if (!catalog.some((item) => item.id === reward.itemId)) {
    return { ...entry, unknown: true, converted: grantCurrency(reward.fallback, ctx) };
  }
  // Starter items are always owned, so they convert too.
  if (reward.itemId === 'default' || (await ownsItem(conn, playerId, reward.type, reward.itemId))) {
    return { ...entry, duplicate: true, converted: grantCurrency(reward.fallback, ctx) };
  }

  await conn.execute(
    `INSERT INTO player_items (id, player_id, item_type, item_id)
     VALUES (:id, :playerId, :itemType, :itemId)`,
    { id: `daily-${crypto.randomUUID()}`, playerId, itemType: reward.type, itemId: reward.itemId },
  );
  return { ...entry, granted: true };
}

/** Coin Boost extends from whichever is later, the current end or now. Streak Freeze stacks. */
async function grantBooster(conn, playerId, reward, ctx) {
  if (reward.boosterId === 'coin_boost') {
    const [rows] = await conn.execute(
      `SELECT active_until_ms FROM player_boosters
       WHERE player_id = :playerId AND booster_id = 'coin_boost'
       FOR UPDATE`,
      { playerId },
    );
    const current = Number(rows[0]?.active_until_ms) || 0;
    const activeUntilMs = Math.max(current, ctx.nowMs) + reward.minutes * 60_000;
    await conn.execute(
      `INSERT INTO player_boosters (player_id, booster_id, quantity, active_until_ms)
       VALUES (:playerId, 'coin_boost', 0, :activeUntilMs) AS new
       ON DUPLICATE KEY UPDATE active_until_ms = new.active_until_ms`,
      { playerId, activeUntilMs },
    );
    return { type: 'booster', boosterId: 'coin_boost', minutes: reward.minutes, activeUntilMs };
  }

  await conn.execute(
    `INSERT INTO player_boosters (player_id, booster_id, quantity, active_until_ms)
     VALUES (:playerId, 'streak_freeze', :quantity, 0) AS new
     ON DUPLICATE KEY UPDATE quantity = player_boosters.quantity + new.quantity`,
    { playerId, quantity: reward.quantity },
  );
  return { type: 'booster', boosterId: 'streak_freeze', quantity: reward.quantity };
}

async function grantChest(conn, playerId, reward, ctx, depth) {
  const chest = ctx.chests[reward.chestId];
  if (!chest || depth > MAX_CHEST_DEPTH) {
    return { type: 'chest', chestId: reward.chestId, skipped: true };
  }
  const { index, reward: picked } = rollChest(chest, ctx.randomInt);
  const loot = await grantOne(conn, playerId, picked, ctx, depth + 1);
  return { type: 'chest', chestId: reward.chestId, pick: index, loot };
}

async function grantOne(conn, playerId, reward, ctx, depth) {
  switch (reward.type) {
    case 'money':
    case 'chips':
      return grantCurrency(reward, ctx);
    case 'avatar':
    case 'deck':
      return grantItem(conn, playerId, reward, ctx);
    case 'booster':
      return grantBooster(conn, playerId, reward, ctx);
    case 'chest':
      return grantChest(conn, playerId, reward, ctx, depth);
    default:
      return { type: reward.type, skipped: true };
  }
}

/**
 * Applies reward entries inside the caller's transaction. The caller must hold
 * the player's row lock. The currency is returned, not written, so the caller
 * can combine it with other changes in one UPDATE (see applyBalances).
 *
 * `multiplier` scales currency only (an ad boost). Booster durations and
 * quantities are never scaled.
 */
async function grantRewards(conn, playerId, rewards, options) {
  const ctx = {
    multiplier: options.multiplier ?? 1,
    nowMs: options.nowMs,
    chests: options.chests ?? {},
    randomInt: options.randomInt ?? crypto.randomInt,
    totals: { money: 0, chips: 0 },
  };
  const granted = [];
  for (const reward of rewards) {
    granted.push(await grantOne(conn, playerId, reward, ctx, 0));
  }
  return { granted, money: ctx.totals.money, chips: ctx.totals.chips };
}

/** One UPDATE for both balances. Chips may be negative (a rescue charge). */
async function applyBalances(conn, playerId, { money = 0, chips = 0 }) {
  if (money === 0 && chips === 0) return;
  await conn.execute(
    `UPDATE players SET money = money + :money, chips = chips + :chips WHERE id = :playerId`,
    { playerId, money, chips },
  );
}

module.exports = {
  grantRewards,
  applyBalances,
};
