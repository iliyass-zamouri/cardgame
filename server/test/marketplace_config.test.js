const test = require('node:test');
const assert = require('node:assert/strict');
const {
  DEFAULTS,
  validateConfig,
  normalizeConfig,
  windowState,
  activeBonus,
  catalogView,
  createMarketplaceStore,
  IAP_BONUS_GRACE_MS,
} = require('../marketplace_config');
const { quotePurchase, iapGrant } = require('../db/marketplace');

const NOW = Date.UTC(2026, 9, 25, 12);
const HOUR = 3_600_000;

/** A mutable deep copy of the defaults, as the admin tab would send it. */
function draft() {
  return JSON.parse(JSON.stringify(DEFAULTS));
}

function withAvatar(config, id, patch) {
  config.avatars = config.avatars.map((item) => (item.id === id ? { ...item, ...patch } : item));
  return config;
}

function valid(config) {
  const result = validateConfig(config);
  assert.equal(result.error, undefined, result.message);
  return result.config;
}

function rejects(config, pattern) {
  const result = validateConfig(config);
  assert.equal(result.error, 'invalid_value');
  assert.match(result.message, pattern);
}

test('the defaults validate and round-trip unchanged', () => {
  assert.deepEqual(valid(draft()), draft());
});

test('ids the admin leaves out keep their defaults', () => {
  const config = draft();
  config.avatars = [{ ...config.avatars[1], price: 250 }];
  const saved = valid(config);
  assert.equal(saved.avatars.length, DEFAULTS.avatars.length);
  assert.equal(saved.avatars[1].price, 250);
  assert.deepEqual(saved.avatars[2], DEFAULTS.avatars[2]);
});

test('unknown and duplicate ids are rejected', () => {
  const unknown = draft();
  unknown.decks.push({ ...unknown.decks[1], id: 'rainbow' });
  rejects(unknown, /unknown id rainbow/);

  const twice = draft();
  twice.decks.push(twice.decks[1]);
  rejects(twice, /sapphire_frost twice/);
});

test('bounds, badges and rarities are checked', () => {
  rejects(withAvatar(draft(), 'blue', { price: -1 }), /Avatar blue\.price/);
  rejects(withAvatar(draft(), 'blue', { badge: 'mega' }), /badge must be one of/);
  rejects(withAvatar(draft(), 'blue', { currency: 'gems' }), /currency must be one of/);
  const deck = draft();
  deck.decks[1].rarity = 'mythic';
  rejects(deck, /rarity must be one of/);
  const economy = draft();
  economy.economy.moneyPerChip = 0;
  rejects(economy, /economy\.moneyPerChip/);
});

test('the starter items stay free and listed', () => {
  rejects(withAvatar(draft(), 'default', { price: 10 }), /starter item/);
  rejects(withAvatar(draft(), 'default', { visible: false }), /starter item/);
});

test('a sale must be cheaper than the normal price and end after it starts', () => {
  const sale = { price: 150, startsAt: NOW, endsAt: NOW + HOUR };
  assert.deepEqual(valid(withAvatar(draft(), 'blue', { sale })).avatars[1].sale, sale);
  rejects(withAvatar(draft(), 'blue', { sale: { ...sale, price: 200 } }), /below the normal price/);
  rejects(withAvatar(draft(), 'blue', { sale: { ...sale, endsAt: NOW } }), /end after it starts/);
});

test('the banner deeplink is checked against the app routes', () => {
  const config = draft();
  config.promotions.banner = {
    enabled: true,
    style: 'gold',
    title: { en: 'Weekend sale' },
    subtitle: null,
    deeplink: '/shop?tab=decks',
    startsAt: null,
    endsAt: null,
  };
  assert.equal(valid(config).promotions.banner.deeplink, '/shop?tab=decks');
  config.promotions.banner.deeplink = '/nowhere';
  rejects(config, /deeplink/);
});

test('the featured item must exist and be visible', () => {
  const config = draft();
  config.promotions.featured = { type: 'deck', id: 'gilded_gold' };
  valid(config);
  config.decks = config.decks.map((deck) => (deck.id === 'gilded_gold' ? { ...deck, visible: false } : deck));
  rejects(config, /hidden deck/);
  config.promotions.featured = { type: 'iap', id: 'chips_999' };
  rejects(config, /unknown iap/);
});

test('a broken stored config falls back to the defaults', () => {
  const quiet = console.error;
  console.error = () => {};
  try {
    assert.equal(normalizeConfig({ economy: 'nope' }), DEFAULTS);
  } finally {
    console.error = quiet;
  }
});

test('windows start inclusive and end exclusive', () => {
  const window = { startsAt: NOW, endsAt: NOW + HOUR };
  assert.equal(windowState(window, NOW - 1), 'scheduled');
  assert.equal(windowState(window, NOW), 'active');
  assert.equal(windowState(window, NOW + HOUR), 'ended');
  assert.equal(windowState(null, NOW), 'none');
});

test('quotePurchase charges the sale price while it runs', () => {
  const config = valid(withAvatar(draft(), 'blue', { sale: { price: 120, startsAt: NOW, endsAt: NOW + HOUR } }));
  const quote = (nowMs, extra = {}) =>
    quotePurchase(config, { itemType: 'avatar', itemId: 'blue', ...extra }, nowMs);
  assert.equal(quote(NOW).price, 120);
  assert.equal(quote(NOW).onSale, true);
  assert.equal(quote(NOW + HOUR).price, 200);
});

test('quotePurchase rejects a stale expected price and hidden items', () => {
  const config = valid(withAvatar(draft(), 'red', { price: 450 }));
  const buy = (extra) => () => quotePurchase(config, { itemType: 'avatar', itemId: 'red', ...extra }, NOW);
  assert.throws(buy({ expectedPrice: 400, expectedCurrency: 'money' }), (err) => {
    assert.equal(err.code, 'price_changed');
    assert.deepEqual(err.details, { currency: 'money', price: 450, basePrice: 450 });
    return true;
  });
  assert.equal(buy({ expectedPrice: 450, expectedCurrency: 'money' })().price, 450);
  assert.throws(buy({ expectedPrice: 450, expectedCurrency: 'chips' }), { code: 'price_changed' });

  const hidden = valid(withAvatar(draft(), 'red', { visible: false }));
  assert.throws(() => quotePurchase(hidden, { itemType: 'avatar', itemId: 'red' }, NOW), {
    code: 'item_unavailable',
  });
});

test('an older build never pays more than its bundled price', () => {
  const raised = valid(withAvatar(draft(), 'red', { price: 900 }));
  assert.equal(quotePurchase(raised, { itemType: 'avatar', itemId: 'red' }, NOW).price, 400);
  const lowered = valid(withAvatar(draft(), 'red', { price: 300 }));
  assert.equal(quotePurchase(lowered, { itemType: 'avatar', itemId: 'red' }, NOW).price, 300);
  const recurrency = valid(withAvatar(draft(), 'red', { currency: 'chips', price: 2 }));
  assert.throws(() => quotePurchase(recurrency, { itemType: 'avatar', itemId: 'red' }, NOW), {
    code: 'price_changed',
  });
});

test('an IAP bonus applies in its window plus a short grace', () => {
  const config = draft();
  config.iapPacks[1].bonus = { amount: 2, startsAt: NOW, endsAt: NOW + HOUR };
  const saved = valid(config);
  const pack = saved.iapPacks[1];
  assert.equal(activeBonus(pack, NOW - 1), 0);
  assert.equal(activeBonus(pack, NOW), 2);
  assert.equal(activeBonus(pack, NOW + HOUR + IAP_BONUS_GRACE_MS - 1), 2);
  assert.equal(activeBonus(pack, NOW + HOUR + IAP_BONUS_GRACE_MS), 0);
  assert.deepEqual(iapGrant(saved, 'chips_5', NOW), { type: 'chips', amount: 7, bonus: 2 });
});

test('catalogView lists visible items in shop order with live promotions', () => {
  const config = draft();
  config.decks = config.decks.map((deck) =>
    deck.id === 'gilded_gold'
      ? { ...deck, order: 0, badge: 'hot', sale: { price: 25, startsAt: NOW - HOUR, endsAt: NOW + HOUR } }
      : deck.id === 'neon_nights'
        ? { ...deck, visible: false }
        : { ...deck, order: deck.order + 1 },
  );
  config.iapPacks[0].bonus = { amount: 1, startsAt: NOW + HOUR, endsAt: NOW + 2 * HOUR };
  config.promotions.banner = {
    enabled: true,
    style: 'ruby',
    title: { en: 'Gold rush' },
    subtitle: null,
    deeplink: null,
    startsAt: NOW - HOUR,
    endsAt: NOW + 3 * HOUR,
  };
  const view = catalogView(valid(config), NOW);

  assert.deepEqual(
    view.decks.map((deck) => deck.id),
    ['gilded_gold', 'default', 'sapphire_frost', 'imperial_jade', 'royal_crimson', 'black_onyx'],
  );
  assert.deepEqual(view.decks[0], {
    id: 'gilded_gold',
    price: 25,
    basePrice: 35,
    currency: 'chips',
    badge: 'hot',
    sale: { price: 25, endsAtMs: NOW + HOUR },
    rarity: 'legendary',
  });
  assert.equal(view.iapPacks[0].bonus, null);
  assert.equal(view.iapPacks.length, 5);
  assert.equal(view.banner.title.en, 'Gold rush');
  assert.equal(view.nextChangeAtMs, NOW + HOUR);
  assert.equal(view.serverTimeMs, NOW);
  assert.match(view.version, /^[0-9a-f]{12}$/);
});

test('the store saves, keeps the previous version and reverts', async () => {
  const rows = new Map();
  const store = createMarketplaceStore({
    read: async () => rows.get('current') ?? null,
    write: async (config) => rows.set('current', config),
    readPrevious: async () => rows.get('previous') ?? null,
    writePrevious: async (config) => rows.set('previous', config),
  });
  await store.refresh();
  assert.equal(store.current().source, 'default');

  const first = valid(withAvatar(draft(), 'blue', { price: 210 }));
  const second = valid(withAvatar(draft(), 'blue', { price: 220 }));
  await store.set(first);
  await store.set(second);
  assert.equal(store.current().avatars[1].price, 220);
  assert.equal(await store.hasPrevious(), true);

  await store.revert();
  assert.equal(store.current().avatars[1].price, 210);
  await store.revert();
  assert.equal(store.current().avatars[1].price, 220);
});
