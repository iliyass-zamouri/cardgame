const { randomUUID } = require('crypto');
const { getPool } = require('./pool');
const {
  DEFAULTS,
  KNOWN_IDS,
  findItem,
  effectivePrice,
  bundledPrice,
  findPack,
  productType,
  activeBonus,
} = require('../marketplace_config');

// Column defaults for players created before the config existed. New players
// get the configured starting balances (see startingBalances).
const STARTING_MONEY = DEFAULTS.economy.startingMoney;
const STARTING_CHIPS = DEFAULTS.economy.startingChips;

/** Old store product ids that still redeem. They are not listed in the shop. */
const LEGACY_IAP_PRODUCTS = Object.freeze({
  gems_100: { type: 'chips', amount: 100 },
  gems_500: { type: 'chips', amount: 500 },
  gems_1200: { type: 'chips', amount: 1200 },
  coins_1000: { type: 'money', amount: 1000 },
  coins_5000: { type: 'money', amount: 5000 },
  pro_monthly: { type: 'pro', amount: 0 },
});

let configSource = () => DEFAULTS;

/** GameServer points this at its live store, so every caller sees admin edits. */
function useMarketplaceConfig(source) {
  configSource = source;
}

function currentConfig() {
  return configSource();
}

/** Money and chips a new player starts with. */
function startingBalances(config = currentConfig()) {
  return { money: config.economy.startingMoney, chips: config.economy.startingChips };
}

function withCode(code, message, details) {
  return Object.assign(new Error(message), { code }, details ? { details } : {});
}

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
  if (rows.length > 0) return false;
  await conn.query(`ALTER TABLE \`${table}\` ADD COLUMN ${definition}`);
  return true;
}

async function ensureMarketplaceSchema() {
  const pool = getPool();
  const conn = await pool.getConnection();
  try {
    await addColumnIfMissing(
      conn,
      'players',
      'money',
      `money INT NOT NULL DEFAULT ${STARTING_MONEY}`,
    );
    await addColumnIfMissing(
      conn,
      'players',
      'chips',
      `chips INT NOT NULL DEFAULT ${STARTING_CHIPS}`,
    );
    await addColumnIfMissing(
      conn,
      'matches',
      'stake_per_player',
      'stake_per_player INT NOT NULL DEFAULT 0',
    );
    await addColumnIfMissing(
      conn,
      'matches',
      'pot_amount',
      'pot_amount INT NOT NULL DEFAULT 0',
    );
    await addColumnIfMissing(
      conn,
      'matches',
      'stake_currency',
      `stake_currency VARCHAR(8) NOT NULL DEFAULT 'money'`,
    );
    await addColumnIfMissing(
      conn,
      'players',
      'avatar_id',
      `avatar_id VARCHAR(64) NOT NULL DEFAULT 'default'`,
    );
    await addColumnIfMissing(
      conn,
      'players',
      'deck_id',
      `deck_id VARCHAR(64) NOT NULL DEFAULT 'default'`,
    );
    const addedTutorialDone = await addColumnIfMissing(
      conn,
      'players',
      'tutorial_done',
      'tutorial_done TINYINT(1) NOT NULL DEFAULT 0',
    );
    if (addedTutorialDone) {
      // Players who already finished a match know the rules: don't prompt them.
      await conn.query(
        'UPDATE players SET tutorial_done = 1 WHERE wins + losses + draws > 0',
      );
    }

    await conn.query(`
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
    `);

    await conn.query(`
      CREATE TABLE IF NOT EXISTS iap_redemptions (
        transaction_id VARCHAR(191) NOT NULL PRIMARY KEY,
        player_id VARCHAR(64) NOT NULL,
        product_id VARCHAR(64) NOT NULL,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        KEY idx_iap_player (player_id),
        CONSTRAINT fk_iap_player FOREIGN KEY (player_id) REFERENCES players (id) ON DELETE CASCADE
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    `);

    await conn.query(`
      CREATE TABLE IF NOT EXISTS ad_reward_claims (
        id VARCHAR(64) NOT NULL PRIMARY KEY,
        player_id VARCHAR(64) NOT NULL,
        claimed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        KEY idx_ad_claims_player_time (player_id, claimed_at),
        CONSTRAINT fk_ad_claim_player FOREIGN KEY (player_id) REFERENCES players (id) ON DELETE CASCADE
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    `);

    // One row per shop sale, so the Shop tab can show what a promo sold.
    // Store packs log the amount granted; their real-money price is unknown here.
    await conn.query(`
      CREATE TABLE IF NOT EXISTS marketplace_purchases (
        id VARCHAR(64) NOT NULL PRIMARY KEY,
        player_id VARCHAR(64) NOT NULL,
        item_type VARCHAR(8) NOT NULL,
        item_id VARCHAR(64) NOT NULL,
        currency VARCHAR(8) NOT NULL,
        price_paid INT NOT NULL DEFAULT 0,
        base_price INT NOT NULL DEFAULT 0,
        amount INT NOT NULL DEFAULT 0,
        bonus INT NOT NULL DEFAULT 0,
        on_sale TINYINT(1) NOT NULL DEFAULT 0,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        KEY idx_mp_time (created_at),
        KEY idx_mp_item (item_type, item_id, created_at),
        CONSTRAINT fk_mkt_purchase_player FOREIGN KEY (player_id) REFERENCES players (id) ON DELETE CASCADE
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    `);
  } finally {
    conn.release();
  }
}

/**
 * What buying `itemId` costs right now. The client's price is never charged:
 * - A build that sends `expectedPrice` gets `price_changed` when it is stale,
 *   so a player never pays a price they weren't shown.
 * - An older build shows its bundled price, so it pays the lower of that and
 *   the configured price, and can't buy an item whose currency changed.
 * @returns {{ currency: 'money'|'chips', price: number, basePrice: number, onSale: boolean }}
 */
function quotePurchase(config, { itemType, itemId, expectedPrice, expectedCurrency }, nowMs) {
  const item = findItem(config, itemType, itemId);
  if (!item) throw withCode('invalid_item_id', `Unknown ${itemType}`);
  if (!item.visible) throw withCode('item_unavailable', 'This item is not for sale right now');
  const quote = effectivePrice(itemType, item, nowMs);
  const current = { currency: quote.currency, price: quote.price, basePrice: quote.basePrice };

  if (expectedPrice != null) {
    const sameCurrency = (expectedCurrency ?? quote.currency) === quote.currency;
    if (!sameCurrency || Number(expectedPrice) !== quote.price) {
      throw withCode('price_changed', 'The price changed. Check it and try again.', current);
    }
    return quote;
  }

  const bundled = bundledPrice(itemType, itemId);
  if (!bundled || bundled.currency !== quote.currency) {
    throw withCode('price_changed', 'Update the app to buy this item.', current);
  }
  return { ...quote, price: Math.min(quote.price, bundled.price) };
}

/**
 * Persist equipped avatar/deck for a player (identity sync / equip).
 * Requires ownership (default or player_items row).
 */
async function updatePlayerCosmetics({ playerId, avatarId, deckId }) {
  if (!playerId) return null;
  const pool = getPool();
  const updates = [];
  const params = { playerId };

  if (typeof avatarId === 'string' && avatarId.trim()) {
    const id = avatarId.trim().slice(0, 64);
    const known = KNOWN_IDS.avatars.includes(id);
    if (known) {
      if (id !== 'default') {
        const [owned] = await pool.execute(
          `SELECT 1 AS ok FROM player_items
           WHERE player_id = :playerId AND item_type = 'avatar' AND item_id = :itemId
           LIMIT 1`,
          { playerId, itemId: id },
        );
        if (owned.length === 0) {
          const error = new Error('Avatar not owned');
          error.code = 'not_owned';
          throw error;
        }
      }
      updates.push('avatar_id = :avatarId');
      params.avatarId = id;
    }
  }
  if (typeof deckId === 'string' && deckId.trim()) {
    const id = deckId.trim().slice(0, 64);
    const known = KNOWN_IDS.decks.includes(id);
    if (known) {
      if (id !== 'default') {
        const [owned] = await pool.execute(
          `SELECT 1 AS ok FROM player_items
           WHERE player_id = :playerId AND item_type = 'deck' AND item_id = :itemId
           LIMIT 1`,
          { playerId, itemId: id },
        );
        if (owned.length === 0) {
          const error = new Error('Deck not owned');
          error.code = 'not_owned';
          throw error;
        }
      }
      updates.push('deck_id = :deckId');
      params.deckId = id;
    }
  }
  if (updates.length === 0) return null;

  await pool.execute(
    `UPDATE players SET ${updates.join(', ')}, last_seen_at = CURRENT_TIMESTAMP WHERE id = :playerId`,
    params,
  );
  return { playerId, avatarId: params.avatarId, deckId: params.deckId };
}

/**
 * Get balances and owned items for a player.
 */
async function getPlayerInventory(playerId, config = currentConfig()) {
  if (!playerId) {
    const error = new Error('playerId is required');
    error.code = 'invalid_player_id';
    throw error;
  }

  const pool = getPool();
  const [playerRows] = await pool.execute(
    `SELECT id, money, chips FROM players WHERE id = :playerId LIMIT 1`,
    { playerId },
  );

  if (playerRows.length === 0) {
    const error = new Error('Player not found');
    error.code = 'player_not_found';
    throw error;
  }

  const player = playerRows[0];
  const [itemRows] = await pool.execute(
    `SELECT item_type, item_id FROM player_items WHERE player_id = :playerId`,
    { playerId },
  );

  const ownedAvatars = new Set(['default']);
  const ownedDecks = new Set(['default']);

  for (const item of itemRows) {
    if (item.item_type === 'avatar') {
      ownedAvatars.add(item.item_id);
    } else if (item.item_type === 'deck') {
      ownedDecks.add(item.item_id);
    }
  }

  return {
    playerId: player.id,
    money: Number(player.money) || 0,
    chips: Number(player.chips) || 0,
    adRewardMoney: config.ads.rewardMoney,
    ownedAvatars: Array.from(ownedAvatars),
    ownedDecks: Array.from(ownedDecks),
  };
}

/**
 * Convert chips <-> money.
 * direction: 'chips_to_money' | 'money_to_chips'
 * amount: number of chips to sell (for chips_to_money) or number of chips to buy (for money_to_chips)
 * expectedRate: the money-per-chip rate the app showed. Older builds don't send it.
 */
async function exchangeCurrency({ playerId, direction, amount, expectedRate, config = currentConfig() }) {
  if (!playerId) {
    const error = new Error('playerId is required');
    error.code = 'invalid_player_id';
    throw error;
  }

  const parsedAmount = Number.parseInt(amount, 10);
  if (Number.isNaN(parsedAmount) || parsedAmount <= 0) {
    const error = new Error('Invalid exchange amount');
    error.code = 'invalid_amount';
    throw error;
  }

  const moneyPerChip = config.economy.moneyPerChip;
  if (expectedRate != null && Number(expectedRate) !== moneyPerChip) {
    throw withCode('rate_changed', 'The exchange rate changed. Check it and try again.', {
      moneyPerChip,
    });
  }

  const pool = getPool();
  const conn = await pool.getConnection();

  try {
    await conn.beginTransaction();

    const [rows] = await conn.execute(
      `SELECT id, money, chips FROM players WHERE id = :playerId FOR UPDATE`,
      { playerId },
    );

    if (rows.length === 0) {
      await conn.rollback();
      const error = new Error('Player not found');
      error.code = 'player_not_found';
      throw error;
    }

    const currentMoney = Number(rows[0].money) || 0;
    const currentChips = Number(rows[0].chips) || 0;

    let newMoney = currentMoney;
    let newChips = currentChips;

    if (direction === 'chips_to_money') {
      // Selling `amount` chips to receive `amount * moneyPerChip` money
      if (currentChips < parsedAmount) {
        await conn.rollback();
        const error = new Error('Insufficient chips');
        error.code = 'insufficient_funds';
        throw error;
      }
      newChips = currentChips - parsedAmount;
      newMoney = currentMoney + parsedAmount * moneyPerChip;
    } else if (direction === 'money_to_chips') {
      // Buying `amount` chips which costs `amount * moneyPerChip` money
      const costInMoney = parsedAmount * moneyPerChip;
      if (currentMoney < costInMoney) {
        await conn.rollback();
        const error = new Error('Insufficient money');
        error.code = 'insufficient_funds';
        throw error;
      }
      newMoney = currentMoney - costInMoney;
      newChips = currentChips + parsedAmount;
    } else {
      await conn.rollback();
      const error = new Error('Invalid exchange direction');
      error.code = 'invalid_direction';
      throw error;
    }

    await conn.execute(
      `UPDATE players SET money = :money, chips = :chips, last_seen_at = CURRENT_TIMESTAMP WHERE id = :playerId`,
      { money: newMoney, chips: newChips, playerId },
    );

    await conn.commit();

    return {
      playerId,
      money: newMoney,
      chips: newChips,
      exchangedAmount: parsedAmount,
      direction,
      moneyPerChip,
    };
  } catch (error) {
    await conn.rollback().catch(() => {});
    throw error;
  } finally {
    conn.release();
  }
}

/**
 * Purchase an avatar or deck from the marketplace at its configured price.
 * See quotePurchase for how the client's expected price is checked.
 */
async function purchaseItem({
  playerId,
  itemType,
  itemId,
  expectedPrice,
  expectedCurrency,
  config = currentConfig(),
  nowMs = Date.now(),
}) {
  if (!playerId) {
    const error = new Error('playerId is required');
    error.code = 'invalid_player_id';
    throw error;
  }

  if (!['avatar', 'deck'].includes(itemType)) {
    const error = new Error('Invalid item type');
    error.code = 'invalid_item_type';
    throw error;
  }

  if (!itemId || typeof itemId !== 'string') {
    const error = new Error('Invalid item id');
    error.code = 'invalid_item_id';
    throw error;
  }

  const quote = quotePurchase(config, { itemType, itemId, expectedPrice, expectedCurrency }, nowMs);
  const resolvedCurrency = quote.currency;
  const parsedPrice = quote.price;

  const pool = getPool();
  const conn = await pool.getConnection();

  try {
    await conn.beginTransaction();

    const [itemRows] = await conn.execute(
      `SELECT 1 AS ok FROM player_items WHERE player_id = :playerId AND item_type = :itemType AND item_id = :itemId LIMIT 1`,
      { playerId, itemType, itemId },
    );

    if (itemRows.length > 0 || itemId === 'default') {
      await conn.rollback();
      const error = new Error('Item already owned');
      error.code = 'already_owned';
      throw error;
    }

    const [rows] = await conn.execute(
      `SELECT id, money, chips FROM players WHERE id = :playerId FOR UPDATE`,
      { playerId },
    );

    if (rows.length === 0) {
      await conn.rollback();
      const error = new Error('Player not found');
      error.code = 'player_not_found';
      throw error;
    }

    const currentMoney = Number(rows[0].money) || 0;
    const currentChips = Number(rows[0].chips) || 0;

    let newMoney = currentMoney;
    let newChips = currentChips;

    if (resolvedCurrency === 'money') {
      if (currentMoney < parsedPrice) {
        await conn.rollback();
        const error = new Error('Insufficient money');
        error.code = 'insufficient_funds';
        throw error;
      }
      newMoney = currentMoney - parsedPrice;
    } else {
      if (currentChips < parsedPrice) {
        await conn.rollback();
        const error = new Error('Insufficient chips');
        error.code = 'insufficient_funds';
        throw error;
      }
      newChips = currentChips - parsedPrice;
    }

    await conn.execute(
      `UPDATE players SET money = :money, chips = :chips, last_seen_at = CURRENT_TIMESTAMP WHERE id = :playerId`,
      { money: newMoney, chips: newChips, playerId },
    );

    const id = `item-${randomUUID()}`;
    await conn.execute(
      `INSERT INTO player_items (id, player_id, item_type, item_id)
       VALUES (:id, :playerId, :itemType, :itemId)`,
      { id, playerId, itemType, itemId },
    );
    await logPurchase(conn, {
      playerId,
      itemType,
      itemId,
      currency: resolvedCurrency,
      pricePaid: parsedPrice,
      basePrice: quote.basePrice,
      onSale: parsedPrice < quote.basePrice,
    });

    await conn.commit();

    return {
      playerId,
      itemType,
      itemId,
      currency: resolvedCurrency,
      price: parsedPrice,
      money: newMoney,
      chips: newChips,
    };
  } catch (error) {
    await conn.rollback().catch(() => {});
    throw error;
  } finally {
    conn.release();
  }
}

/**
 * Claim rewarded ad bonus with the configured daily cap + cooldown.
 */
async function claimRewardedAdBonus(playerId, config = currentConfig()) {
  const { rewardMoney, dailyCap, cooldownSeconds } = config.ads;
  if (!playerId) {
    const error = new Error('playerId is required');
    error.code = 'invalid_player_id';
    throw error;
  }

  const pool = getPool();
  const conn = await pool.getConnection();

  try {
    await conn.beginTransaction();

    const [rows] = await conn.execute(
      `SELECT id, money, chips FROM players WHERE id = :playerId FOR UPDATE`,
      { playerId },
    );

    if (rows.length === 0) {
      await conn.rollback();
      const error = new Error('Player not found');
      error.code = 'player_not_found';
      throw error;
    }

    const [recent] = await conn.execute(
      `SELECT claimed_at FROM ad_reward_claims
       WHERE player_id = :playerId
       ORDER BY claimed_at DESC
       LIMIT 1`,
      { playerId },
    );
    if (recent.length > 0) {
      const last = new Date(recent[0].claimed_at).getTime();
      if (Date.now() - last < cooldownSeconds * 1000) {
        await conn.rollback();
        const error = new Error('Ad reward cooldown active');
        error.code = 'ad_cooldown';
        throw error;
      }
    }

    const [dayCountRows] = await conn.execute(
      `SELECT COUNT(*) AS cnt FROM ad_reward_claims
       WHERE player_id = :playerId
         AND claimed_at >= UTC_DATE()`,
      { playerId },
    );
    const dayCount = Number(dayCountRows[0]?.cnt) || 0;
    if (dayCount >= dailyCap) {
      await conn.rollback();
      const error = new Error('Daily ad reward cap reached');
      error.code = 'ad_daily_cap';
      throw error;
    }

    const rewardAmount = rewardMoney;
    const currentMoney = Number(rows[0].money) || 0;
    const currentChips = Number(rows[0].chips) || 0;
    const newMoney = currentMoney + rewardAmount;

    await conn.execute(
      `UPDATE players SET money = :money, last_seen_at = CURRENT_TIMESTAMP WHERE id = :playerId`,
      { money: newMoney, playerId },
    );
    await conn.execute(
      `INSERT INTO ad_reward_claims (id, player_id) VALUES (:id, :playerId)`,
      { id: `ad-${randomUUID()}`, playerId },
    );

    await conn.commit();

    return {
      playerId,
      money: newMoney,
      chips: currentChips,
      reward: rewardAmount,
      claimsToday: dayCount + 1,
      dailyCap,
    };
  } catch (error) {
    await conn.rollback().catch(() => {});
    throw error;
  } finally {
    conn.release();
  }
}

/** What a store product grants now: its configured amount plus any live bonus. */
function iapGrant(config, productId, nowMs) {
  const pack = findPack(config, productId);
  if (pack) {
    const bonus = activeBonus(pack, nowMs);
    return { type: productType(productId), amount: pack.amount + bonus, bonus };
  }
  const legacy = LEGACY_IAP_PRODUCTS[productId];
  return legacy ? { ...legacy, bonus: 0 } : null;
}

/** Writes one marketplace_purchases row inside the caller's transaction. */
async function logPurchase(conn, { playerId, itemType, itemId, currency, pricePaid = 0, basePrice = 0, amount = 0, bonus = 0, onSale }) {
  await conn.execute(
    `INSERT INTO marketplace_purchases
       (id, player_id, item_type, item_id, currency, price_paid, base_price, amount, bonus, on_sale)
     VALUES (:id, :playerId, :itemType, :itemId, :currency, :pricePaid, :basePrice, :amount, :bonus, :onSale)`,
    {
      id: `buy-${randomUUID()}`,
      playerId,
      itemType,
      itemId,
      currency,
      pricePaid,
      basePrice,
      amount,
      bonus,
      onSale: onSale ? 1 : 0,
    },
  );
}

/**
 * Verify purchase appears on RevenueCat subscriber when secret configured.
 * SKIP_IAP_VERIFY=1 skips (tests). Missing key: allow non-prod, reject production.
 */
async function verifyRevenueCatPurchase({ playerId, productId, transactionId }) {
  if (process.env.SKIP_IAP_VERIFY === '1') {
    return true;
  }

  const secret =
    typeof process.env.REVENUECAT_SECRET_API_KEY === 'string'
      ? process.env.REVENUECAT_SECRET_API_KEY.trim()
      : '';

  if (!secret) {
    if (process.env.NODE_ENV === 'production') {
      const error = new Error('IAP verification unavailable');
      error.code = 'iap_verify_unavailable';
      throw error;
    }
    return true;
  }

  const url = `https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(playerId)}`;
  const response = await fetch(url, {
    method: 'GET',
    headers: {
      Authorization: `Bearer ${secret}`,
      Accept: 'application/json',
    },
  });

  if (!response.ok) {
    const error = new Error(`RevenueCat verify failed (${response.status})`);
    error.code = 'iap_verify_failed';
    throw error;
  }

  const body = await response.json();
  const subscriber = body?.subscriber || body;
  const nonSubs = subscriber?.non_subscriptions || {};
  const purchases = nonSubs[productId];
  if (Array.isArray(purchases)) {
    const hit = purchases.some(
      (p) =>
        p &&
        (String(p.id) === String(transactionId) ||
          String(p.store_transaction_id || '') === String(transactionId)),
    );
    if (hit) return true;
  }

  const subs = subscriber?.subscriptions || {};
  const sub = subs[productId];
  if (sub) {
    const storeId = String(
      sub.store_transaction_id || sub.original_transaction_id || '',
    );
    if (storeId && storeId === String(transactionId)) return true;
    if (sub.purchase_date || sub.original_purchase_date) return true;
  }

  const error = new Error('Purchase not found on RevenueCat subscriber');
  error.code = 'iap_not_found';
  throw error;
}

/**
 * Redeem an IAP purchase idempotently based on store transactionId.
 */
async function redeemIapPurchase({
  playerId,
  productId,
  transactionId,
  config = currentConfig(),
  nowMs = Date.now(),
}) {
  if (!playerId) {
    const error = new Error('playerId is required');
    error.code = 'invalid_player_id';
    throw error;
  }
  if (!productId) {
    const error = new Error('productId is required');
    error.code = 'invalid_product_id';
    throw error;
  }
  if (!transactionId) {
    const error = new Error('transactionId is required');
    error.code = 'invalid_transaction_id';
    throw error;
  }

  const catalogEntry = iapGrant(config, productId, nowMs);
  if (!catalogEntry) {
    const error = new Error(`Unknown product: ${productId}`);
    error.code = 'invalid_product_id';
    throw error;
  }

  await verifyRevenueCatPurchase({ playerId, productId, transactionId });

  const pool = getPool();
  const conn = await pool.getConnection();

  try {
    await conn.beginTransaction();

    // Check if already redeemed
    const [existing] = await conn.execute(
      `SELECT transaction_id, player_id, product_id, created_at
       FROM iap_redemptions
       WHERE transaction_id = :transactionId
       LIMIT 1`,
      { transactionId },
    );

    const [playerRows] = await conn.execute(
      `SELECT id, money, chips FROM players WHERE id = :playerId FOR UPDATE`,
      { playerId },
    );

    if (playerRows.length === 0) {
      await conn.rollback();
      const error = new Error('Player not found');
      error.code = 'player_not_found';
      throw error;
    }

    const currentMoney = Number(playerRows[0].money) || 0;
    const currentChips = Number(playerRows[0].chips) || 0;

    if (existing.length > 0) {
      await conn.commit();
      return {
        playerId,
        productId,
        transactionId,
        money: currentMoney,
        chips: currentChips,
        alreadyRedeemed: true,
      };
    }

    let newMoney = currentMoney;
    let newChips = currentChips;

    if (catalogEntry.type === 'chips') {
      newChips = currentChips + catalogEntry.amount;
    } else if (catalogEntry.type === 'money') {
      newMoney = currentMoney + catalogEntry.amount;
    }

    await conn.execute(
      `UPDATE players
       SET money = :money, chips = :chips, last_seen_at = CURRENT_TIMESTAMP
       WHERE id = :playerId`,
      { money: newMoney, chips: newChips, playerId },
    );

    await conn.execute(
      `INSERT INTO iap_redemptions (transaction_id, player_id, product_id)
       VALUES (:transactionId, :playerId, :productId)`,
      { transactionId, playerId, productId },
    );
    if (catalogEntry.type === 'chips' || catalogEntry.type === 'money') {
      await logPurchase(conn, {
        playerId,
        itemType: 'iap',
        itemId: productId,
        currency: catalogEntry.type,
        amount: catalogEntry.amount,
        bonus: catalogEntry.bonus,
        onSale: catalogEntry.bonus > 0,
      });
    }

    await conn.commit();

    return {
      playerId,
      productId,
      transactionId,
      money: newMoney,
      chips: newChips,
      alreadyRedeemed: false,
      granted: catalogEntry,
    };
  } catch (error) {
    await conn.rollback().catch(() => {});
    throw error;
  } finally {
    conn.release();
  }
}

/**
 * Shop sales over the last `days` days, one row per item, split into sale and
 * full price. Revenue is in the currency the item was priced in.
 */
async function getMarketplaceStats({ days = 30 } = {}) {
  const window = Math.min(Math.max(Number.parseInt(days, 10) || 30, 1), 365);
  const [rows] = await getPool().execute(
    `SELECT item_type, item_id, currency, on_sale,
            COUNT(*) AS units, SUM(price_paid) AS revenue, SUM(amount) AS amount, SUM(bonus) AS bonus,
            COUNT(DISTINCT player_id) AS buyers
     FROM marketplace_purchases
     WHERE created_at >= UTC_TIMESTAMP() - INTERVAL ${window} DAY
     GROUP BY item_type, item_id, currency, on_sale
     ORDER BY item_type, item_id, on_sale`,
  );
  return {
    days: window,
    items: rows.map((row) => ({
      itemType: row.item_type,
      itemId: row.item_id,
      currency: row.currency,
      onSale: Boolean(row.on_sale),
      units: Number(row.units) || 0,
      buyers: Number(row.buyers) || 0,
      revenue: Number(row.revenue) || 0,
      amount: Number(row.amount) || 0,
      bonus: Number(row.bonus) || 0,
    })),
  };
}

module.exports = {
  STARTING_MONEY,
  STARTING_CHIPS,
  LEGACY_IAP_PRODUCTS,
  useMarketplaceConfig,
  currentConfig,
  startingBalances,
  quotePurchase,
  iapGrant,
  ensureMarketplaceSchema,
  getPlayerInventory,
  exchangeCurrency,
  purchaseItem,
  claimRewardedAdBonus,
  redeemIapPurchase,
  updatePlayerCosmetics,
  verifyRevenueCatPurchase,
  getMarketplaceStats,
};
