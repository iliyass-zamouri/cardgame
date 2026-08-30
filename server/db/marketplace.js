const { randomUUID } = require('crypto');
const { getPool } = require('./pool');

const STARTING_MONEY = 500;
const STARTING_CHIPS = 1;
const MONEY_PER_CHIP = 1000;
const AD_REWARD_MONEY = 50;

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
  if (rows.length > 0) return;
  await conn.query(`ALTER TABLE \`${table}\` ADD COLUMN ${definition}`);
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
  } finally {
    conn.release();
  }
}

/**
 * Get balances and owned items for a player.
 */
async function getPlayerInventory(playerId) {
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
    ownedAvatars: Array.from(ownedAvatars),
    ownedDecks: Array.from(ownedDecks),
  };
}

/**
 * Convert chips <-> money.
 * direction: 'chips_to_money' | 'money_to_chips'
 * amount: number of chips to sell (for chips_to_money) or number of chips to buy (for money_to_chips)
 */
async function exchangeCurrency({ playerId, direction, amount }) {
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
      // Selling `amount` chips to receive `amount * MONEY_PER_CHIP` money
      if (currentChips < parsedAmount) {
        await conn.rollback();
        const error = new Error('Insufficient chips');
        error.code = 'insufficient_funds';
        throw error;
      }
      newChips = currentChips - parsedAmount;
      newMoney = currentMoney + parsedAmount * MONEY_PER_CHIP;
    } else if (direction === 'money_to_chips') {
      // Buying `amount` chips which costs `amount * MONEY_PER_CHIP` money
      const costInMoney = parsedAmount * MONEY_PER_CHIP;
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
    };
  } catch (error) {
    await conn.rollback().catch(() => {});
    throw error;
  } finally {
    conn.release();
  }
}

/**
 * Purchase an avatar or deck from the marketplace.
 */
async function purchaseItem({ playerId, itemType, itemId, currency, price }) {
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

  if (!['money', 'chips'].includes(currency)) {
    const error = new Error('Invalid currency');
    error.code = 'invalid_currency';
    throw error;
  }

  const parsedPrice = Number.parseInt(price, 10);
  if (Number.isNaN(parsedPrice) || parsedPrice < 0) {
    const error = new Error('Invalid price');
    error.code = 'invalid_price';
    throw error;
  }

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

    if (currency === 'money') {
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

    await conn.commit();

    return {
      playerId,
      itemType,
      itemId,
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
 * Claim rewarded ad bonus (+50 Money).
 */
async function claimRewardedAdBonus(playerId) {
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

    const currentMoney = Number(rows[0].money) || 0;
    const currentChips = Number(rows[0].chips) || 0;
    const newMoney = currentMoney + AD_REWARD_MONEY;

    await conn.execute(
      `UPDATE players SET money = :money, last_seen_at = CURRENT_TIMESTAMP WHERE id = :playerId`,
      { money: newMoney, playerId },
    );

    await conn.commit();

    return {
      playerId,
      money: newMoney,
      chips: currentChips,
      reward: AD_REWARD_MONEY,
    };
  } catch (error) {
    await conn.rollback().catch(() => {});
    throw error;
  } finally {
    conn.release();
  }
}

module.exports = {
  STARTING_MONEY,
  STARTING_CHIPS,
  MONEY_PER_CHIP,
  AD_REWARD_MONEY,
  ensureMarketplaceSchema,
  getPlayerInventory,
  exchangeCurrency,
  purchaseItem,
  claimRewardedAdBonus,
};
