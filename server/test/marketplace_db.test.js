// Runs the marketplace SQL against a real MySQL with an admin-edited config.
// Skipped unless MARKETPLACE_DB_TEST=1 and the MYSQL_* variables point at a
// scratch database. Example:
//   MARKETPLACE_DB_TEST=1 MYSQL_HOST=127.0.0.1 MYSQL_PORT=3306 \
//     MYSQL_USER=cardgame MYSQL_PASSWORD=cardgame MYSQL_DATABASE=cardgame \
//     node --test server/test/marketplace_db.test.js

const test = require('node:test');
const assert = require('node:assert/strict');
const crypto = require('crypto');
const { DEFAULTS, validateConfig } = require('../marketplace_config');

const skip =
  process.env.MARKETPLACE_DB_TEST === '1'
    ? false
    : 'set MARKETPLACE_DB_TEST=1 and MYSQL_* to run against MySQL';

const NOW = Date.now();
const HOUR = 3_600_000;

let ready = null;
function connect() {
  ready ??= (async () => {
    process.env.SKIP_IAP_VERIFY = '1';
    const pool = require('../db/pool');
    await pool.initDb();
    return pool;
  })();
  return ready;
}

async function db() {
  return (await connect()).getPool();
}

function marketplace() {
  return require('../db/marketplace');
}

/** The defaults with a few admin edits, validated as a save would be. */
function configWith(edit) {
  const draft = JSON.parse(JSON.stringify(DEFAULTS));
  edit(draft);
  const { config, message } = validateConfig(draft);
  assert.ok(config, message);
  return config;
}

const SALE_CONFIG = configWith((config) => {
  config.economy = { moneyPerChip: 800, startingMoney: 1200, startingChips: 3 };
  config.ads = { rewardMoney: 75, dailyCap: 1, cooldownSeconds: 0 };
  const blue = config.avatars.find((item) => item.id === 'blue');
  blue.sale = { price: 150, startsAt: NOW - HOUR, endsAt: NOW + HOUR };
  config.avatars.find((item) => item.id === 'red').price = 900;
  config.avatars.find((item) => item.id === 'bronze').visible = false;
  config.iapPacks.find((pack) => pack.productId === 'chips_5').bonus = {
    amount: 2,
    startsAt: NOW - HOUR,
    endsAt: NOW + HOUR,
  };
});

async function createPlayer({ money = 5000, chips = 10 } = {}) {
  const id = `t-${crypto.randomUUID()}`;
  await (await db()).execute(`INSERT INTO players (id, money, chips) VALUES (:id, :money, :chips)`, {
    id,
    money,
    chips,
  });
  return id;
}

async function balances(playerId) {
  const [rows] = await (await db()).execute(`SELECT money, chips FROM players WHERE id = :playerId`, {
    playerId,
  });
  return { money: Number(rows[0].money), chips: Number(rows[0].chips) };
}

async function purchases(playerId) {
  const [rows] = await (await db()).execute(
    `SELECT item_type, item_id, currency, price_paid, base_price, amount, bonus, on_sale
     FROM marketplace_purchases WHERE player_id = :playerId ORDER BY created_at, id`,
    { playerId },
  );
  return rows.map((row) => ({ ...row, on_sale: Number(row.on_sale) }));
}

test('a purchase during a sale charges the sale price and logs it', { skip }, async () => {
  await connect();
  const playerId = await createPlayer();
  const result = await marketplace().purchaseItem({
    playerId,
    itemType: 'avatar',
    itemId: 'blue',
    expectedPrice: 150,
    expectedCurrency: 'money',
    config: SALE_CONFIG,
    nowMs: NOW,
  });
  assert.equal(result.price, 150);
  assert.deepEqual(await balances(playerId), { money: 4850, chips: 10 });
  assert.deepEqual(await purchases(playerId), [
    {
      item_type: 'avatar',
      item_id: 'blue',
      currency: 'money',
      price_paid: 150,
      base_price: 200,
      amount: 0,
      bonus: 0,
      on_sale: 1,
    },
  ]);
});

test('an older build pays its bundled price after a price rise', { skip }, async () => {
  await connect();
  const playerId = await createPlayer();
  const result = await marketplace().purchaseItem({
    playerId,
    itemType: 'avatar',
    itemId: 'red',
    config: SALE_CONFIG,
    nowMs: NOW,
  });
  assert.equal(result.price, 400);
  assert.deepEqual(await balances(playerId), { money: 4600, chips: 10 });
});

test('a stale price and a hidden item charge nothing', { skip }, async () => {
  await connect();
  const playerId = await createPlayer();
  const buy = (itemId, extra = {}) =>
    marketplace().purchaseItem({ playerId, itemType: 'avatar', itemId, config: SALE_CONFIG, nowMs: NOW, ...extra });
  await assert.rejects(buy('red', { expectedPrice: 400, expectedCurrency: 'money' }), { code: 'price_changed' });
  await assert.rejects(buy('bronze'), { code: 'item_unavailable' });
  assert.deepEqual(await balances(playerId), { money: 5000, chips: 10 });
  assert.deepEqual(await purchases(playerId), []);
});

test('exchange uses the configured rate and rejects a stale one', { skip }, async () => {
  await connect();
  const playerId = await createPlayer({ money: 0, chips: 2 });
  const result = await marketplace().exchangeCurrency({
    playerId,
    direction: 'chips_to_money',
    amount: 2,
    expectedRate: 800,
    config: SALE_CONFIG,
  });
  assert.equal(result.moneyPerChip, 800);
  assert.deepEqual(await balances(playerId), { money: 1600, chips: 0 });
  await assert.rejects(
    marketplace().exchangeCurrency({
      playerId,
      direction: 'money_to_chips',
      amount: 1,
      expectedRate: 1000,
      config: SALE_CONFIG,
    }),
    { code: 'rate_changed' },
  );
});

test('the ad reward pays the configured amount up to the daily cap', { skip }, async () => {
  await connect();
  const playerId = await createPlayer({ money: 0 });
  const first = await marketplace().claimRewardedAdBonus(playerId, SALE_CONFIG);
  assert.equal(first.reward, 75);
  assert.equal(first.dailyCap, 1);
  await assert.rejects(marketplace().claimRewardedAdBonus(playerId, SALE_CONFIG), { code: 'ad_daily_cap' });
  assert.equal((await marketplace().getPlayerInventory(playerId, SALE_CONFIG)).adRewardMoney, 75);
});

test('an IAP during a bonus grants the extra amount once and logs it', { skip }, async () => {
  await connect();
  const playerId = await createPlayer({ chips: 0 });
  const transactionId = `tx-${crypto.randomUUID()}`;
  const redeem = () =>
    marketplace().redeemIapPurchase({ playerId, productId: 'chips_5', transactionId, config: SALE_CONFIG, nowMs: NOW });
  assert.equal((await redeem()).chips, 7);
  assert.equal((await redeem()).alreadyRedeemed, true);
  assert.equal((await balances(playerId)).chips, 7);
  const [row] = await purchases(playerId);
  assert.equal(row.item_type, 'iap');
  assert.equal(row.amount, 7);
  assert.equal(row.bonus, 2);
  assert.equal(row.on_sale, 1);
});

test('shop stats group sales by item and sale state', { skip }, async () => {
  await connect();
  const stats = await marketplace().getMarketplaceStats({ days: 1 });
  const blue = stats.items.find((item) => item.itemId === 'blue' && item.onSale);
  assert.ok(blue.units >= 1);
  assert.equal(blue.currency, 'money');
  assert.ok(blue.revenue >= 150);
});

test('new players start with the configured balances', { skip }, async () => {
  await connect();
  const { useMarketplaceConfig } = marketplace();
  const { findOrCreateGuest } = require('../db/store');
  useMarketplaceConfig(() => SALE_CONFIG);
  try {
    const player = await findOrCreateGuest({
      deviceId: `local:${crypto.randomUUID()}`,
      clientIp: '203.0.113.7',
    });
    assert.equal(player.money, 1200);
    assert.deepEqual(await balances(player.playerId), { money: 1200, chips: 3 });
  } finally {
    useMarketplaceConfig(() => DEFAULTS);
  }
});

test.after(async () => {
  if (ready) await require('../db/pool').closeDb();
});
