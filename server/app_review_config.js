// When and how the app asks players to rate it, tuned live from the admin
// Ratings tab. These functions are pure. server/app_review.js applies the
// rules and server/db/app_reviews.js stores the ratings.

const {
  ConfigError,
  invalid,
  requireObject,
  intIn,
  boolIn,
  localizedText,
} = require('./config_validation');

const CACHE_MS = 15_000;

/** Where a prompt came from. `settings` and `push` are opened on purpose and skip the rules. */
const TRIGGERS = ['win', 'daily', 'launch', 'settings', 'push'];
const AUTO_TRIGGERS = ['win', 'daily', 'launch'];
/** Reasons a player can tick after a low rating. The app localizes the labels. */
const FEEDBACK_TAGS = ['bugs', 'ads', 'difficulty', 'economy', 'bots', 'performance', 'other'];
/** gated: our stars first, store only at or above storeMinStars. native_only: the OS sheet straight away. */
const FLOWS = ['gated', 'native_only'];

/** Inclusive limits. The admin tab reads these too. */
const LIMITS = Object.freeze({
  storeMinStars: [1, 5],
  minMatchesPlayed: [0, 1000],
  minWins: [0, 1000],
  minAccountAgeDays: [0, 365],
  cooldownDays: [0, 365],
  lowRatingRepromptDays: [0, 730],
  highRatingRepromptDays: [0, 730],
  maxPrompts: [1, 50],
  pushMinMatchesPlayed: [0, 1000],
  pushMinDaysSinceInstall: [0, 365],
  pushIdleHours: [0, 168],
  pushHour: [0, 23],
  pushPerTickLimit: [1, 5000],
  pushTitleLength: 80,
  pushBodyLength: 200,
});

function deepFreeze(value) {
  if (value && typeof value === 'object') {
    Object.values(value).forEach(deepFreeze);
    Object.freeze(value);
  }
  return value;
}

const DEFAULTS = deepFreeze({
  enabled: true,
  flow: { android: 'gated', ios: 'gated' },
  storeMinStars: 4,
  iosAppStoreId: '',
  rules: {
    minMatchesPlayed: 5,
    minWins: 2,
    minAccountAgeDays: 2,
    cooldownDays: 14,
    lowRatingRepromptDays: 90,
    highRatingRepromptDays: 0,
    maxPrompts: 3,
  },
  triggers: { win: true, daily: true, launch: false, settings: true },
  feedback: { askReason: true, tags: ['bugs', 'ads', 'difficulty', 'economy', 'bots', 'other'] },
  push: {
    enabled: false,
    minMatchesPlayed: 10,
    minDaysSinceInstall: 3,
    idleHours: 6,
    sendWindowUtc: [16, 20],
    perTickLimit: 200,
    title: {
      en: 'Enjoying ShadowHand?',
      fr: 'Vous aimez ShadowHand ?',
      es: '¿Te gusta ShadowHand?',
      pt: 'Curtindo o ShadowHand?',
      ar: 'هل تستمتع بلعبة ShadowHand؟',
    },
    body: {
      en: 'Tell us how we are doing. It only takes a second.',
      fr: 'Dites-nous ce que vous en pensez. Ça ne prend qu’une seconde.',
      es: 'Cuéntanos qué te parece. Solo te llevará un segundo.',
      pt: 'Conte o que está achando. Leva só um segundo.',
      ar: 'أخبرنا برأيك. لن يستغرق الأمر سوى ثانية.',
    },
  },
});

function oneOf(value, allowed, label) {
  if (!allowed.includes(value)) invalid(`${label} must be one of ${allowed.join(', ')}`);
  return value;
}

function appStoreIdIn(value) {
  if (typeof value !== 'string' || !/^\d{0,12}$/.test(value.trim())) {
    invalid('iosAppStoreId must be the numeric App Store id (or empty)');
  }
  return value.trim();
}

function tagsIn(value) {
  if (!Array.isArray(value)) invalid('feedback.tags must be a list');
  const tags = [];
  for (const tag of value) {
    oneOf(tag, FEEDBACK_TAGS, 'feedback.tags');
    if (!tags.includes(tag)) tags.push(tag);
  }
  // Keep the canonical order so the app shows them the same way every time.
  return FEEDBACK_TAGS.filter((tag) => tags.includes(tag));
}

function hourWindowIn(value) {
  if (!Array.isArray(value) || value.length !== 2) {
    invalid('push.sendWindowUtc must be [startHour, endHour]');
  }
  return [
    intIn(value[0], LIMITS.pushHour, 'push.sendWindowUtc start'),
    intIn(value[1], LIMITS.pushHour, 'push.sendWindowUtc end'),
  ];
}

function buildConfig(input) {
  requireObject(input, 'config', [
    'enabled',
    'flow',
    'storeMinStars',
    'iosAppStoreId',
    'rules',
    'triggers',
    'feedback',
    'push',
  ]);
  const flow = requireObject(input.flow, 'flow', ['android', 'ios']);
  const rules = requireObject(input.rules, 'rules', Object.keys(DEFAULTS.rules));
  const triggers = requireObject(input.triggers, 'triggers', Object.keys(DEFAULTS.triggers));
  const feedback = requireObject(input.feedback, 'feedback', ['askReason', 'tags']);
  const push = requireObject(input.push, 'push', Object.keys(DEFAULTS.push));

  return {
    enabled: boolIn(input.enabled, 'enabled'),
    flow: {
      android: oneOf(flow.android, FLOWS, 'flow.android'),
      ios: oneOf(flow.ios, FLOWS, 'flow.ios'),
    },
    storeMinStars: intIn(input.storeMinStars, LIMITS.storeMinStars, 'storeMinStars'),
    iosAppStoreId: appStoreIdIn(input.iosAppStoreId),
    rules: {
      minMatchesPlayed: intIn(rules.minMatchesPlayed, LIMITS.minMatchesPlayed, 'rules.minMatchesPlayed'),
      minWins: intIn(rules.minWins, LIMITS.minWins, 'rules.minWins'),
      minAccountAgeDays: intIn(rules.minAccountAgeDays, LIMITS.minAccountAgeDays, 'rules.minAccountAgeDays'),
      cooldownDays: intIn(rules.cooldownDays, LIMITS.cooldownDays, 'rules.cooldownDays'),
      lowRatingRepromptDays: intIn(
        rules.lowRatingRepromptDays,
        LIMITS.lowRatingRepromptDays,
        'rules.lowRatingRepromptDays',
      ),
      highRatingRepromptDays: intIn(
        rules.highRatingRepromptDays,
        LIMITS.highRatingRepromptDays,
        'rules.highRatingRepromptDays',
      ),
      maxPrompts: intIn(rules.maxPrompts, LIMITS.maxPrompts, 'rules.maxPrompts'),
    },
    triggers: {
      win: boolIn(triggers.win, 'triggers.win'),
      daily: boolIn(triggers.daily, 'triggers.daily'),
      launch: boolIn(triggers.launch, 'triggers.launch'),
      settings: boolIn(triggers.settings, 'triggers.settings'),
    },
    feedback: {
      askReason: boolIn(feedback.askReason, 'feedback.askReason'),
      tags: tagsIn(feedback.tags),
    },
    push: {
      enabled: boolIn(push.enabled, 'push.enabled'),
      minMatchesPlayed: intIn(push.minMatchesPlayed, LIMITS.pushMinMatchesPlayed, 'push.minMatchesPlayed'),
      minDaysSinceInstall: intIn(
        push.minDaysSinceInstall,
        LIMITS.pushMinDaysSinceInstall,
        'push.minDaysSinceInstall',
      ),
      idleHours: intIn(push.idleHours, LIMITS.pushIdleHours, 'push.idleHours'),
      sendWindowUtc: hourWindowIn(push.sendWindowUtc),
      perTickLimit: intIn(push.perTickLimit, LIMITS.pushPerTickLimit, 'push.perTickLimit'),
      title: localizedText(push.title, 'push.title', LIMITS.pushTitleLength),
      body: localizedText(push.body, 'push.body', LIMITS.pushBodyLength),
    },
  };
}

/** Checks a complete config. Returns { config } or { error, message }. */
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
    console.error('[app-review] stored config is invalid, using defaults', message);
    return DEFAULTS;
  }
  return config;
}

/** iOS and macOS share the App Store; anything else has no store to send to. */
function storeFor(platform) {
  if (platform === 'android') return 'android';
  if (platform === 'ios' || platform === 'macos') return 'ios';
  return null;
}

/** What the app needs to run the prompt on this platform. */
function clientView(config, platform) {
  const store = storeFor(platform);
  return {
    enabled: config.enabled,
    flow: store ? config.flow[store] : 'gated',
    hasStore: store !== null,
    storeMinStars: config.storeMinStars,
    iosAppStoreId: config.iosAppStoreId,
    askReason: config.feedback.askReason,
    tags: [...config.feedback.tags],
    triggers: { ...config.triggers },
  };
}

// ---------------------------------------------------------------- live store

function codedError(code, message) {
  return Object.assign(new Error(message), { code });
}

function frozenState(config, source) {
  return Object.freeze({ ...config, source });
}

/**
 * The live config, cached like marketplace_config.js. `read()` and
 * `write(config)` handle the current value. `readPrevious()` and
 * `writePrevious(config)` keep the version before the last save, for revert.
 */
function createAppReviewStore({
  read,
  write,
  readPrevious,
  writePrevious,
  cacheMs = CACHE_MS,
  now = Date.now,
  onReadError = (error) =>
    console.error('[app-review] read failed, keeping last-known settings', error),
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

/** For runs without a database: the defaults, read-only. */
function staticAppReviewStore(config = DEFAULTS) {
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
  TRIGGERS,
  AUTO_TRIGGERS,
  FEEDBACK_TAGS,
  FLOWS,
  LIMITS,
  DEFAULTS,
  validateConfig,
  normalizeConfig,
  storeFor,
  clientView,
  createAppReviewStore,
  staticAppReviewStore,
};
