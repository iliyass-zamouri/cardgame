// Shop prices, economy knobs and promotions that admins tune live from the
// Shop tab. The set of avatars, decks and store products is fixed here because
// their art ships in the app; admins edit each one but can't add new ones.
// These functions are pure. server/db/marketplace.js applies them.

const crypto = require('crypto');
const { normalizeDeeplink } = require('./push/deeplinks');
const {
  ConfigError,
  invalid,
  isPlainObject,
  requireObject,
  intIn,
  boolIn,
  localizedText,
} = require('./config_validation');

const CACHE_MS = 15_000;
// A store purchase made just before a bonus ends is verified a moment later.
const IAP_BONUS_GRACE_MS = 10 * 60_000;

const CURRENCIES = ['money', 'chips'];
const RARITIES = ['standard', 'rare', 'epic', 'legendary'];
const BADGES = ['new', 'hot', 'popular', 'best_value', 'limited'];
const BANNER_STYLES = ['gold', 'ruby', 'emerald', 'sapphire'];
const FEATURED_TYPES = ['avatar', 'deck', 'iap'];

/**
 * The bundled catalogs. Prices here are what app builds from before this
 * config shows, so they are also the most an old build is ever charged.
 */
const AVATARS = Object.freeze([
  { id: 'default', name: 'Default', price: 0, currency: 'money', requiredLevel: 1 },
  { id: 'blue', name: 'Sapphire', price: 200, currency: 'money', requiredLevel: 2 },
  { id: 'red', name: 'Ruby', price: 400, currency: 'money', requiredLevel: 4 },
  { id: 'bronze', name: 'Bronze', price: 600, currency: 'money', requiredLevel: 6 },
  { id: 'silver', name: 'Silver', price: 1, currency: 'chips', requiredLevel: 8 },
  { id: 'joker-girl', name: 'Joker Girl', price: 2, currency: 'chips', requiredLevel: 10 },
  { id: 'violet-joker-girl', name: 'Violet Joker', price: 2, currency: 'chips', requiredLevel: 12 },
  { id: 'violet-queen', name: 'Violet Queen', price: 3, currency: 'chips', requiredLevel: 15 },
  { id: 'queen-of-heart', name: 'Queen of Hearts', price: 4, currency: 'chips', requiredLevel: 18 },
  { id: 'golden-king', name: 'Golden King', price: 5, currency: 'chips', requiredLevel: 20 },
].map(Object.freeze));

const DECKS = Object.freeze([
  { id: 'default', name: 'Classic Blue', price: 0, currency: 'chips', rarity: 'standard' },
  { id: 'sapphire_frost', name: 'Sapphire Dragon', price: 6, currency: 'chips', rarity: 'rare' },
  { id: 'imperial_jade', name: 'High Victorian', price: 8, currency: 'chips', rarity: 'rare' },
  { id: 'royal_crimson', name: 'Royal Crimson', price: 12, currency: 'chips', rarity: 'epic' },
  { id: 'neon_nights', name: 'Neon Nights', price: 15, currency: 'chips', rarity: 'epic' },
  { id: 'black_onyx', name: 'Onyx Black', price: 20, currency: 'chips', rarity: 'legendary' },
  { id: 'gilded_gold', name: '24K Gold', price: 35, currency: 'chips', rarity: 'legendary' },
].map(Object.freeze));

/** Store products the shop can list. Real-money prices live in the stores. */
const IAP_PRODUCTS = Object.freeze([
  { productId: 'chips_1', name: '1 Chip', type: 'chips', amount: 1, visible: true },
  { productId: 'chips_5', name: '5 Chips', type: 'chips', amount: 5, visible: true },
  { productId: 'chips_10', name: '10 Chips', type: 'chips', amount: 10, visible: true },
  { productId: 'chips_25', name: '25 Chips', type: 'chips', amount: 25, visible: true },
  { productId: 'chips_50', name: '50 Chips', type: 'chips', amount: 50, visible: true },
  { productId: 'cash_1000', name: '1,000 Cash', type: 'money', amount: 1000, visible: false },
  { productId: 'cash_5000', name: '5,000 Cash', type: 'money', amount: 5000, visible: false },
  { productId: 'cash_10000', name: '10,000 Cash', type: 'money', amount: 10000, visible: false },
  { productId: 'cash_25000', name: '25,000 Cash', type: 'money', amount: 25000, visible: false },
].map(Object.freeze));

/** Ids other modules may reference (rewards, bots, cosmetics). */
const KNOWN_IDS = Object.freeze({
  avatars: Object.freeze(AVATARS.map((item) => item.id)),
  decks: Object.freeze(DECKS.map((item) => item.id)),
  iapProducts: Object.freeze(IAP_PRODUCTS.map((item) => item.productId)),
});

/** Inclusive limits. The admin tab reads these too. */
const LIMITS = Object.freeze({
  moneyPerChip: [1, 1_000_000],
  startingMoney: [0, 1_000_000],
  startingChips: [0, 1_000],
  rewardMoney: [0, 100_000],
  dailyCap: [0, 100],
  cooldownSeconds: [0, 86_400],
  price: Object.freeze({ money: [0, 10_000_000], chips: [0, 10_000] }),
  iapAmount: Object.freeze({ money: [1, 100_000_000], chips: [1, 100_000] }),
  requiredLevel: [1, 100],
  order: [0, 999],
  // 2020-01-01 to 2100-01-01, in ms.
  timeMs: [1_577_836_800_000, 4_102_444_800_000],
  bannerTitle: 40,
  bannerSubtitle: 80,
});

function envAdRewardMoney(env = process.env) {
  const value = Number.parseInt(env.AD_REWARD_MONEY, 10);
  return Number.isNaN(value) || value < 0 ? 50 : value;
}

function deepFreeze(value) {
  if (value && typeof value === 'object') {
    Object.values(value).forEach(deepFreeze);
    Object.freeze(value);
  }
  return value;
}

const DEFAULTS = deepFreeze({
  economy: { moneyPerChip: 1000, startingMoney: 500, startingChips: 1 },
  ads: { rewardMoney: envAdRewardMoney(), dailyCap: 5, cooldownSeconds: 60 },
  avatars: AVATARS.map(({ id, price, currency, requiredLevel }, index) => ({
    id,
    price,
    currency,
    requiredLevel,
    visible: true,
    order: index,
    badge: null,
    sale: null,
  })),
  decks: DECKS.map(({ id, price, rarity }, index) => ({
    id,
    price,
    rarity,
    visible: true,
    order: index,
    badge: null,
    sale: null,
  })),
  iapPacks: IAP_PRODUCTS.map(({ productId, amount, visible }, index) => ({
    productId,
    amount,
    visible,
    order: index,
    badge: null,
    bonus: null,
  })),
  promotions: { banner: null, featured: null },
});

// ---------------------------------------------------------------- validation

function oneOf(value, allowed, label) {
  if (!allowed.includes(value)) invalid(`${label} must be one of ${allowed.join(', ')}`);
  return value;
}

function badgeIn(value, label) {
  return value == null ? null : oneOf(value, BADGES, label);
}

function timeIn(value, label) {
  return intIn(value, LIMITS.timeMs, label);
}

/** { startsAt, endsAt } in UTC ms, with the end after the start. */
function windowIn(value, label) {
  const startsAt = timeIn(value.startsAt, `${label}.startsAt`);
  const endsAt = timeIn(value.endsAt, `${label}.endsAt`);
  if (endsAt <= startsAt) invalid(`${label} must end after it starts`);
  return { startsAt, endsAt };
}

function parseSale(value, label, basePrice, currency) {
  if (value == null) return null;
  requireObject(value, label, ['price', 'startsAt', 'endsAt']);
  const price = intIn(value.price, LIMITS.price[currency], `${label}.price`);
  if (price >= basePrice) invalid(`${label}.price must be below the normal price (${basePrice})`);
  return { price, ...windowIn(value, label) };
}

/**
 * One entry per known id. Ids the admin didn't send keep their defaults, so a
 * new item added in code shows up with its bundled values.
 */
function parseList(value, label, { idKey, defaults, parseEntry }) {
  if (!Array.isArray(value)) invalid(`${label} must be a list`);
  const byId = new Map();
  for (const entry of value) {
    if (!isPlainObject(entry)) invalid(`${label} entries must be objects`);
    const id = entry[idKey];
    if (!defaults.some((item) => item[idKey] === id)) invalid(`${label} has unknown id ${id}`);
    if (byId.has(id)) invalid(`${label} lists ${id} twice`);
    byId.set(id, entry);
  }
  return defaults.map((fallback) =>
    byId.has(fallback[idKey]) ? parseEntry(byId.get(fallback[idKey]), `${label} ${fallback[idKey]}`) : fallback,
  );
}

const AVATAR_KEYS = ['id', 'price', 'currency', 'requiredLevel', 'visible', 'order', 'badge', 'sale'];
const DECK_KEYS = ['id', 'price', 'rarity', 'visible', 'order', 'badge', 'sale'];
const PACK_KEYS = ['productId', 'amount', 'visible', 'order', 'badge', 'bonus'];

function parseAvatar(entry, label) {
  requireObject(entry, label, AVATAR_KEYS);
  const currency = oneOf(entry.currency, CURRENCIES, `${label}.currency`);
  const price = intIn(entry.price, LIMITS.price[currency], `${label}.price`);
  const avatar = {
    id: entry.id,
    price,
    currency,
    requiredLevel: intIn(entry.requiredLevel, LIMITS.requiredLevel, `${label}.requiredLevel`),
    visible: boolIn(entry.visible, `${label}.visible`),
    order: intIn(entry.order, LIMITS.order, `${label}.order`),
    badge: badgeIn(entry.badge, `${label}.badge`),
    sale: parseSale(entry.sale, `${label}.sale`, price, currency),
  };
  return entry.id === 'default' ? starterItem(avatar, label) : avatar;
}

function parseDeck(entry, label) {
  requireObject(entry, label, DECK_KEYS);
  const price = intIn(entry.price, LIMITS.price.chips, `${label}.price`);
  const deck = {
    id: entry.id,
    price,
    rarity: oneOf(entry.rarity, RARITIES, `${label}.rarity`),
    visible: boolIn(entry.visible, `${label}.visible`),
    order: intIn(entry.order, LIMITS.order, `${label}.order`),
    badge: badgeIn(entry.badge, `${label}.badge`),
    sale: parseSale(entry.sale, `${label}.sale`, price, 'chips'),
  };
  return entry.id === 'default' ? starterItem(deck, label) : deck;
}

/** Every player owns the starter avatar and deck, so they stay free and listed. */
function starterItem(item, label) {
  if (item.price !== 0 || item.sale) invalid(`${label} is the starter item and stays free`);
  if (!item.visible) invalid(`${label} is the starter item and can't be hidden`);
  return item;
}

function parsePack(entry, label) {
  requireObject(entry, label, PACK_KEYS);
  const { type } = IAP_PRODUCTS.find((product) => product.productId === entry.productId);
  const range = LIMITS.iapAmount[type];
  let bonus = null;
  if (entry.bonus != null) {
    requireObject(entry.bonus, `${label}.bonus`, ['amount', 'startsAt', 'endsAt']);
    bonus = {
      amount: intIn(entry.bonus.amount, range, `${label}.bonus.amount`),
      ...windowIn(entry.bonus, `${label}.bonus`),
    };
  }
  return {
    productId: entry.productId,
    amount: intIn(entry.amount, range, `${label}.amount`),
    visible: boolIn(entry.visible, `${label}.visible`),
    order: intIn(entry.order, LIMITS.order, `${label}.order`),
    badge: badgeIn(entry.badge, `${label}.badge`),
    bonus,
  };
}

function parseBanner(value) {
  if (value == null) return null;
  const label = 'promotions.banner';
  requireObject(value, label, ['enabled', 'style', 'title', 'subtitle', 'deeplink', 'startsAt', 'endsAt']);
  const { route, error } = normalizeDeeplink(value.deeplink);
  if (error) invalid(`${label}.deeplink: ${error}`);
  const hasWindow = value.startsAt != null || value.endsAt != null;
  return {
    enabled: boolIn(value.enabled, `${label}.enabled`),
    style: oneOf(value.style, BANNER_STYLES, `${label}.style`),
    title: localizedText(value.title, `${label}.title`, LIMITS.bannerTitle),
    subtitle: value.subtitle == null ? null : localizedText(value.subtitle, `${label}.subtitle`, LIMITS.bannerSubtitle),
    deeplink: route,
    ...(hasWindow ? windowIn(value, label) : { startsAt: null, endsAt: null }),
  };
}

function parseFeatured(value, config) {
  if (value == null) return null;
  const label = 'promotions.featured';
  requireObject(value, label, ['type', 'id']);
  const type = oneOf(value.type, FEATURED_TYPES, `${label}.type`);
  const item = listFor(config, type).find((entry) => idOf(entry) === value.id);
  if (!item) invalid(`${label} points at unknown ${type} ${value.id}`);
  if (!item.visible) invalid(`${label} points at a hidden ${type}`);
  return { type, id: value.id };
}

function buildConfig(input) {
  requireObject(input, 'config', ['economy', 'ads', 'avatars', 'decks', 'iapPacks', 'promotions']);
  requireObject(input.economy, 'economy', ['moneyPerChip', 'startingMoney', 'startingChips']);
  requireObject(input.ads, 'ads', ['rewardMoney', 'dailyCap', 'cooldownSeconds']);
  requireObject(input.promotions, 'promotions', ['banner', 'featured']);

  const config = {
    economy: {
      moneyPerChip: intIn(input.economy.moneyPerChip, LIMITS.moneyPerChip, 'economy.moneyPerChip'),
      startingMoney: intIn(input.economy.startingMoney, LIMITS.startingMoney, 'economy.startingMoney'),
      startingChips: intIn(input.economy.startingChips, LIMITS.startingChips, 'economy.startingChips'),
    },
    ads: {
      rewardMoney: intIn(input.ads.rewardMoney, LIMITS.rewardMoney, 'ads.rewardMoney'),
      dailyCap: intIn(input.ads.dailyCap, LIMITS.dailyCap, 'ads.dailyCap'),
      cooldownSeconds: intIn(input.ads.cooldownSeconds, LIMITS.cooldownSeconds, 'ads.cooldownSeconds'),
    },
    avatars: parseList(input.avatars, 'Avatar', {
      idKey: 'id',
      defaults: DEFAULTS.avatars,
      parseEntry: parseAvatar,
    }),
    decks: parseList(input.decks, 'Deck', { idKey: 'id', defaults: DEFAULTS.decks, parseEntry: parseDeck }),
    iapPacks: parseList(input.iapPacks, 'Pack', {
      idKey: 'productId',
      defaults: DEFAULTS.iapPacks,
      parseEntry: parsePack,
    }),
  };
  config.promotions = {
    banner: parseBanner(input.promotions.banner),
    featured: parseFeatured(input.promotions.featured, config),
  };
  return config;
}

/** Checks a complete marketplace config. Returns { config } or { error, message }. */
function validateConfig(input) {
  try {
    return { config: buildConfig(input) };
  } catch (error) {
    if (error instanceof ConfigError) return { error: 'invalid_value', message: error.message };
    throw error;
  }
}

/** For stored values. A bad stored config falls back to the defaults and is logged. */
function normalizeConfig(raw) {
  if (raw === null || raw === undefined) return DEFAULTS;
  const { config, message } = validateConfig(raw);
  if (!config) {
    console.error('[marketplace] stored config is invalid, using defaults', message);
    return DEFAULTS;
  }
  return config;
}

// ---------------------------------------------------------------- pricing

function listFor(config, type) {
  if (type === 'avatar') return config.avatars;
  if (type === 'deck') return config.decks;
  return config.iapPacks;
}

function idOf(entry) {
  return entry.productId ?? entry.id;
}

/** True while `startsAt <= nowMs < endsAt`. */
function isLive(window, nowMs) {
  return Boolean(window) && window.startsAt <= nowMs && nowMs < window.endsAt;
}

/** 'none' | 'scheduled' | 'active' | 'ended', for the admin tab. */
function windowState(window, nowMs) {
  if (!window) return 'none';
  if (nowMs < window.startsAt) return 'scheduled';
  return nowMs < window.endsAt ? 'active' : 'ended';
}

/** The configured avatar or deck, or null for an unknown id. */
function findItem(config, itemType, itemId) {
  const list = itemType === 'deck' ? config.decks : itemType === 'avatar' ? config.avatars : null;
  return list?.find((item) => item.id === itemId) ?? null;
}

/** Currency and price a player pays right now, with the sale applied. */
function effectivePrice(itemType, item, nowMs) {
  const currency = itemType === 'deck' ? 'chips' : item.currency;
  const onSale = isLive(item.sale, nowMs);
  return { currency, price: onSale ? item.sale.price : item.price, basePrice: item.price, onSale };
}

/** The price an app build from before this config shows for an item. */
function bundledPrice(itemType, itemId) {
  const list = itemType === 'deck' ? DECKS : AVATARS;
  const item = list.find((entry) => entry.id === itemId);
  return item ? { currency: item.currency, price: item.price } : null;
}

function findPack(config, productId) {
  return config.iapPacks.find((pack) => pack.productId === productId) ?? null;
}

function productType(productId) {
  return IAP_PRODUCTS.find((product) => product.productId === productId)?.type ?? null;
}

/** The bonus amount a pack grants now. The end gets a short grace for store verify. */
function activeBonus(pack, nowMs, graceMs = IAP_BONUS_GRACE_MS) {
  const bonus = pack?.bonus;
  if (!bonus || nowMs < bonus.startsAt || nowMs >= bonus.endsAt + graceMs) return 0;
  return bonus.amount;
}

// ---------------------------------------------------------------- app payload

function byOrder(a, b) {
  return a.order - b.order;
}

function saleView(sale, nowMs) {
  return isLive(sale, nowMs) ? { price: sale.price, endsAtMs: sale.endsAt } : null;
}

function bannerView(banner, nowMs) {
  if (!banner?.enabled) return null;
  if (banner.startsAt != null && !isLive(banner, nowMs)) return null;
  return {
    style: banner.style,
    title: banner.title,
    subtitle: banner.subtitle,
    deeplink: banner.deeplink,
    endsAtMs: banner.endsAt,
  };
}

/** The next time a sale, bonus or banner starts or ends, so the app refetches then. */
function nextChangeAt(config, nowMs) {
  const windows = [
    ...config.avatars.map((item) => item.sale),
    ...config.decks.map((item) => item.sale),
    ...config.iapPacks.map((pack) => pack.bonus),
    config.promotions.banner?.startsAt != null ? config.promotions.banner : null,
  ].filter(Boolean);
  const times = windows.flatMap((window) => [window.startsAt, window.endsAt]).filter((t) => t > nowMs);
  return times.length > 0 ? Math.min(...times) : null;
}

/** GET /marketplace/catalog: visible items only, in shop order, prices as of now. */
function catalogView(config, nowMs) {
  const items = (list, view) => list.filter((item) => item.visible).sort(byOrder).map(view);
  const priced = (item, currency) => {
    const sale = saleView(item.sale, nowMs);
    return {
      id: item.id,
      price: sale ? sale.price : item.price,
      basePrice: item.price,
      currency,
      badge: item.badge,
      sale,
    };
  };
  const body = {
    economy: { moneyPerChip: config.economy.moneyPerChip },
    ads: { ...config.ads },
    avatars: items(config.avatars, (item) => ({
      ...priced(item, item.currency),
      requiredLevel: item.requiredLevel,
    })),
    decks: items(config.decks, (item) => ({ ...priced(item, 'chips'), rarity: item.rarity })),
    iapPacks: items(config.iapPacks, (pack) => {
      const bonus = isLive(pack.bonus, nowMs) ? { amount: pack.bonus.amount, endsAtMs: pack.bonus.endsAt } : null;
      return {
        productId: pack.productId,
        type: productType(pack.productId),
        amount: pack.amount,
        badge: pack.badge,
        bonus,
      };
    }),
    banner: bannerView(config.promotions.banner, nowMs),
    featured: config.promotions.featured,
    nextChangeAtMs: nextChangeAt(config, nowMs),
  };
  const version = crypto.createHash('sha1').update(JSON.stringify(body)).digest('hex').slice(0, 12);
  return { version, serverTimeMs: nowMs, ...body };
}

/** Names and bundled values for the admin tab's tables and pickers. */
function knownItems() {
  return {
    avatars: AVATARS.map(({ id, name }) => ({ id, name })),
    decks: DECKS.map(({ id, name }) => ({ id, name })),
    iapProducts: IAP_PRODUCTS.map(({ productId, name, type }) => ({ productId, name, type })),
    currencies: CURRENCIES,
    rarities: RARITIES,
    badges: BADGES,
    bannerStyles: BANNER_STYLES,
  };
}

// ---------------------------------------------------------------- store

function codedError(code, message) {
  return Object.assign(new Error(message), { code });
}

function frozenState(config, source) {
  return Object.freeze({ ...config, source });
}

/**
 * The live config, cached like daily_rewards.js. `read()` and `write(config)`
 * handle the current value. `readPrevious()` and `writePrevious(config)` keep
 * the version before the last save, for revert. `current()` never waits on
 * the database; a failing read keeps the last good value.
 */
function createMarketplaceStore({
  read,
  write,
  readPrevious,
  writePrevious,
  cacheMs = CACHE_MS,
  now = Date.now,
  onReadError = (error) =>
    console.error('[marketplace] read failed, keeping last-known settings', error),
} = {}) {
  let state = frozenState(DEFAULTS, 'default');
  let loadedAt = -Infinity;
  /** @type {Promise<void> | null} */
  let pending = null;
  // Bumped by a write: a read that started before it must not overwrite it.
  let epoch = 0;

  async function load() {
    const startedAt = epoch;
    try {
      const record = await read();
      if (startedAt === epoch) {
        state = frozenState(normalizeConfig(record), record ? 'admin' : 'default');
      }
    } catch (error) {
      onReadError(error);
    }
    loadedAt = now();
  }

  function refresh() {
    pending ??= load().finally(() => {
      pending = null;
    });
    return pending;
  }

  function adopt(config) {
    epoch += 1;
    state = frozenState(config, 'admin');
    loadedAt = now();
    return state;
  }

  return {
    /** Synchronous. Starts a background refresh when the cache is stale. */
    current() {
      if (now() - loadedAt >= cacheMs) void refresh();
      return state;
    },
    refresh,
    /** Saves a validated config and keeps the previous one for revert. */
    async set(config) {
      const previous = await read();
      if (previous) await writePrevious(previous);
      await write(config);
      return adopt(config);
    },
    async hasPrevious() {
      return Boolean(await readPrevious());
    },
    /** Swaps the saved config with the previous one. A second revert undoes the first. */
    async revert() {
      const previous = await readPrevious();
      if (!previous || validateConfig(previous).error) {
        throw codedError('no_previous', 'No earlier version to restore');
      }
      const current = await read();
      if (current) await writePrevious(current);
      await write(previous);
      return adopt(normalizeConfig(previous));
    },
  };
}

/** A store that only ever holds the defaults: tests and runs without a database. */
function staticMarketplaceStore(config = DEFAULTS) {
  const state = frozenState(config, 'default');
  return {
    current: () => state,
    refresh: async () => {},
    set: async () => {
      throw codedError('read_only', 'This store is read-only');
    },
    hasPrevious: async () => false,
    revert: async () => {
      throw codedError('no_previous', 'No earlier version to restore');
    },
  };
}

module.exports = {
  AVATARS,
  DECKS,
  IAP_PRODUCTS,
  KNOWN_IDS,
  LIMITS,
  DEFAULTS,
  IAP_BONUS_GRACE_MS,
  validateConfig,
  normalizeConfig,
  isLive,
  windowState,
  findItem,
  effectivePrice,
  bundledPrice,
  findPack,
  productType,
  activeBonus,
  catalogView,
  knownItems,
  createMarketplaceStore,
  staticMarketplaceStore,
};
