// Streak rewards: a 7-day cycle that admins tune live from the Daily rewards tab.
// The server owns all time. A client sends only its UTC offset, and every
// decision here uses the server clock. These functions are pure so the rules
// can be tested without a database. server/db/daily_rewards.js applies them.

const DAY_MS = 86_400_000;
const HOUR_MS = 3_600_000;
const CYCLE_DAYS = 7;
const MIN_OFFSET_MINUTES = -720;
const MAX_OFFSET_MINUTES = 840;
// A timezone change larger than this is travel, not a DST shift.
const OFFSET_JUMP_MINUTES = 180;
const OFFSET_JUMP_LOCK_MS = 7 * DAY_MS;
const AT_RISK_STREAK = 3;
const CACHE_MS = 15_000;

const { TIERS, MAX_PRESETS, presetView } = require('./boosts');

const LANGUAGES = ['en', 'fr', 'es', 'pt', 'ar'];
const BOOSTER_IDS = ['coin_boost', 'streak_freeze'];
const CHOICES = ['rescue', 'restart'];
const CONFIG_KEYS = [
  'enabled',
  'graceDays',
  'minClaimGapHours',
  'rescue',
  'adBoost',
  'boosters',
  'comeback',
  'reminder',
  'calendar',
  'events',
  'chests',
];

/** Inclusive limits. The admin tab reads these too. */
const LIMITS = Object.freeze({
  maxMoney: 1_000_000,
  maxChips: 1_000,
  maxBoostMinutes: 7 * 24 * 60,
  maxBoostPercent: 100,
  maxBoostBonus: 100_000,
  maxBoostPresets: MAX_PRESETS,
  maxFreezeQuantity: 5,
  maxRewardsPerDay: 3,
  maxEvents: 12,
  maxChests: 10,
  maxChestEntries: 20,
  maxConfigBytes: 60 * 1024,
});

const DEFAULT_ROYAL_CHEST = {
  title: { en: 'Royal Chest', fr: 'Coffre royal', es: 'Cofre real', pt: 'Baú real', ar: 'الصندوق الملكي' },
  pool: [
    { weight: 60, reward: { type: 'money', amount: 2000 } },
    { weight: 25, reward: { type: 'chips', amount: 3 } },
    {
      weight: 10,
      reward: { type: 'avatar', itemId: 'queen-of-heart', fallback: { type: 'money', amount: 1500 } },
    },
    {
      weight: 4,
      reward: { type: 'deck', itemId: 'neon_nights', fallback: { type: 'money', amount: 2500 } },
    },
    {
      weight: 1,
      reward: { type: 'deck', itemId: 'gilded_gold', fallback: { type: 'money', amount: 8000 } },
    },
  ],
};

const DEFAULTS = deepFreeze({
  enabled: true,
  graceDays: 1,
  minClaimGapHours: 6,
  rescue: { enabled: true, chipCost: 3, windowDays: 3 },
  adBoost: { enabled: true, multiplier: 2 },
  boosters: {
    coin_boost: {
      presets: [
        {
          id: 'standard',
          name: { en: 'Coin Boost', fr: 'Boost de pièces', es: 'Impulso de monedas', pt: 'Turbo de moedas', ar: 'معزز العملات' },
          percent: 25,
          maxBonus: 2000,
          tier: 'silver',
        },
        {
          id: 'gold',
          name: { en: 'Gold Boost', fr: 'Boost doré', es: 'Impulso dorado', pt: 'Turbo dourado', ar: 'المعزز الذهبي' },
          percent: 50,
          maxBonus: 5000,
          tier: 'gold',
        },
      ],
    },
  },
  comeback: {
    enabled: true,
    absentDays: 7,
    cooldownDays: 30,
    rewards: [
      { type: 'money', amount: 500 },
      { type: 'chips', amount: 1 },
    ],
  },
  reminder: { enabled: true, localHour: 19, atRiskHour: 21 },
  calendar: {
    id: 'default',
    days: [
      { day: 1, rewards: [{ type: 'money', amount: 200 }] },
      { day: 2, rewards: [{ type: 'booster', boosterId: 'coin_boost', presetId: 'standard', minutes: 60 }] },
      { day: 3, rewards: [{ type: 'chips', amount: 1 }] },
      {
        day: 4,
        rewards: [
          { type: 'money', amount: 400 },
          { type: 'booster', boosterId: 'streak_freeze', quantity: 1 },
        ],
      },
      {
        day: 5,
        rewards: [
          { type: 'money', amount: 300 },
          { type: 'booster', boosterId: 'coin_boost', presetId: 'standard', minutes: 240 },
        ],
      },
      { day: 6, rewards: [{ type: 'chips', amount: 2 }] },
      {
        day: 7,
        rewards: [
          { type: 'money', amount: 1000 },
          { type: 'chest', chestId: 'royal' },
        ],
      },
    ],
  },
  events: [],
  chests: { royal: DEFAULT_ROYAL_CHEST },
});

function deepFreeze(value) {
  for (const child of Object.values(value)) {
    if (child && typeof child === 'object') deepFreeze(child);
  }
  return Object.freeze(value);
}

// ---------------------------------------------------------------- time

function localDateOf(nowMs, offsetMinutes) {
  return new Date(nowMs + offsetMinutes * 60_000).toISOString().slice(0, 10);
}

function localHourOf(nowMs, offsetMinutes) {
  return new Date(nowMs + offsetMinutes * 60_000).getUTCHours();
}

function dayNumber(dateString) {
  return Date.parse(`${dateString}T00:00:00Z`) / DAY_MS;
}

function addDays(dateString, days) {
  return new Date(Date.parse(`${dateString}T00:00:00Z`) + days * DAY_MS).toISOString().slice(0, 10);
}

function localMidnightMs(dateString, offsetMinutes) {
  return Date.parse(`${dateString}T00:00:00Z`) - offsetMinutes * 60_000;
}

function clampOffset(value) {
  if (typeof value !== 'number' || !Number.isFinite(value)) return null;
  return Math.min(MAX_OFFSET_MINUTES, Math.max(MIN_OFFSET_MINUTES, Math.round(value)));
}

/**
 * Picks the offset a claim uses. A small change (DST, a moved phone) is taken
 * at once. A jump larger than OFFSET_JUMP_MINUTES is taken only once per
 * OFFSET_JUMP_LOCK_MS, so a player cannot shift their day back and forth.
 */
function resolveOffset({ requested, stored, changedAtMs, nowMs }) {
  const asked = clampOffset(requested);
  if (stored == null) return { value: asked ?? 0, changedAtMs: nowMs };
  if (asked == null || asked === stored) return { value: stored, changedAtMs };
  if (Math.abs(asked - stored) <= OFFSET_JUMP_MINUTES) return { value: asked, changedAtMs };
  const locked = changedAtMs != null && nowMs - changedAtMs < OFFSET_JUMP_LOCK_MS;
  return locked ? { value: stored, changedAtMs } : { value: asked, changedAtMs: nowMs };
}

// ---------------------------------------------------------------- streak rules

function claimedAt(streak, nextClaimAtMs) {
  return { ...streak, state: 'claimed', nextClaimAtMs };
}

/**
 * Works out where the player stands in their streak at `nowMs`.
 *
 * `input` is { position, count, best, cycles, lastDate, lastAtMs, freezes,
 * lastComebackAtMs, createdAtMs }. `position` is the last claimed day (0 when
 * none), and `lastDate` is the local date of the last claim.
 *
 * States:
 *  - claimable: a claim is allowed now. `resets` says whether it starts over.
 *  - claimed:   already claimed for this local day, or inside the min gap.
 *  - broken:    too many missed days for grace or freezes. A claim needs a
 *               choice: 'rescue' (chips) or 'restart'.
 */
function computeStreakState(input, nowMs, offsetMinutes, config) {
  const localDate = localDateOf(nowMs, offsetMinutes);
  const lastDay = input.position ?? 0;
  const streak = {
    localDate,
    lastDay,
    count: input.count ?? 0,
    best: input.best ?? 0,
    cycles: input.cycles ?? 0,
    freezes: input.freezes ?? 0,
    state: 'claimable',
    nextDay: (lastDay % CYCLE_DAYS) + 1,
    resets: false,
    missedDays: 0,
    graceUsed: 0,
    freezesUsed: 0,
    nextClaimAtMs: null,
    rescue: { available: false, chipCost: config.rescue.chipCost, lastDate: null },
  };

  if (!input.lastDate || input.lastAtMs == null) return streak;

  const gap = dayNumber(localDate) - dayNumber(input.lastDate);
  const cooldownEndsAtMs = input.lastAtMs + config.minClaimGapHours * HOUR_MS;

  if (gap <= 0) {
    const nextMidnight = localMidnightMs(addDays(localDate, 1), offsetMinutes);
    return claimedAt(streak, Math.max(nextMidnight, cooldownEndsAtMs));
  }
  if (nowMs < cooldownEndsAtMs) return claimedAt(streak, cooldownEndsAtMs);

  const missed = gap - 1;
  const graceUsed = Math.min(missed, config.graceDays);
  const extra = missed - graceUsed;
  streak.missedDays = missed;
  streak.graceUsed = graceUsed;
  if (extra === 0) return streak;

  if (streak.freezes >= extra) {
    streak.freezesUsed = extra;
    return streak;
  }

  if (config.rescue.enabled && missed <= config.graceDays + config.rescue.windowDays) {
    streak.state = 'broken';
    streak.graceUsed = 0;
    streak.rescue.available = true;
    streak.rescue.lastDate = addDays(
      input.lastDate,
      config.graceDays + config.rescue.windowDays + 1,
    );
    return streak;
  }

  streak.resets = true;
  streak.nextDay = 1;
  streak.graceUsed = 0;
  return streak;
}

/**
 * Turns a streak state and the player's choice into what a claim does.
 * Returns { plan } or { error, details }.
 */
function planClaim(streak, choice = null) {
  if (choice !== null && !CHOICES.includes(choice)) {
    return { error: 'invalid_choice' };
  }
  if (streak.state === 'claimed') return { error: 'already_claimed' };

  if (streak.state === 'claimable') {
    return {
      plan: {
        nextDay: streak.nextDay,
        continues: !streak.resets,
        chipCost: 0,
        freezesUsed: streak.freezesUsed,
        graceUsed: streak.graceUsed,
        rescued: false,
      },
    };
  }

  if (choice === 'rescue') {
    return {
      plan: {
        nextDay: streak.nextDay,
        continues: true,
        chipCost: streak.rescue.chipCost,
        freezesUsed: 0,
        graceUsed: 0,
        rescued: true,
      },
    };
  }
  if (choice === 'restart') {
    return {
      plan: { nextDay: 1, continues: false, chipCost: 0, freezesUsed: 0, graceUsed: 0, rescued: false },
    };
  }
  return {
    error: 'streak_broken',
    details: { rescue: streak.rescue, lastDay: streak.lastDay },
  };
}

/** The streak counters after a claim has been made. */
function applyClaim(streak, plan) {
  const count = plan.continues ? streak.count + 1 : 1;
  const wrapped = plan.continues && streak.lastDay === CYCLE_DAYS;
  return {
    position: plan.nextDay,
    count,
    best: Math.max(streak.best, count),
    cycles: wrapped ? streak.cycles + 1 : streak.cycles,
  };
}

// ---------------------------------------------------------------- calendars, chests, boosts

/** The event whose dates cover `localDate`, otherwise the default calendar. */
function pickCalendar(config, localDate) {
  const event = config.events.find((entry) => entry.startsAt <= localDate && localDate <= entry.endsAt);
  if (event) {
    return { id: event.id, title: event.title, endsAt: event.endsAt, days: event.days };
  }
  return { id: config.calendar.id, title: null, endsAt: null, days: config.calendar.days };
}

/** Weighted pick. `randomInt(n)` must return an integer from 0 to n - 1. */
function rollChest(chest, randomInt) {
  const total = chest.pool.reduce((sum, entry) => sum + entry.weight, 0);
  let roll = randomInt(total);
  for (let index = 0; index < chest.pool.length; index += 1) {
    const entry = chest.pool[index];
    if (roll < entry.weight) return { index, reward: entry.reward };
    roll -= entry.weight;
  }
  const last = chest.pool.length - 1;
  return { index: last, reward: chest.pool[last].reward };
}

/** Extra coins a Coin Boost adds to a won pot. The profit is the opponent's stake. */
function computeBoostBonus({ pot, ownStake, percent, maxBonus }) {
  const profit = Math.max(0, pot - ownStake);
  if (profit === 0) return 0;
  return Math.min(Math.floor((profit * percent) / 100), maxBonus);
}

/** Welcome-back bonus. Absence counts from the last claim, or account creation if never claimed. */
function comebackStatus(input, nowMs, config) {
  const settings = config.comeback;
  const referenceMs = input.lastAtMs ?? input.createdAtMs ?? null;
  const absentMs = referenceMs == null ? 0 : Math.max(0, nowMs - referenceMs);
  const absent = absentMs >= settings.absentDays * DAY_MS;
  const cooldownEndsAtMs =
    input.lastComebackAtMs == null ? null : input.lastComebackAtMs + settings.cooldownDays * DAY_MS;
  const cooling = cooldownEndsAtMs != null && nowMs < cooldownEndsAtMs;
  return {
    available: settings.enabled && absent && !cooling,
    rewards: settings.rewards,
    absentDays: Math.floor(absentMs / DAY_MS),
    cooldownEndsAtMs,
  };
}

// ---------------------------------------------------------------- client payload

function dayStatus(day, streak) {
  if (streak.state === 'claimable') {
    if (day < streak.nextDay) return 'claimed';
    return day === streak.nextDay ? 'today' : 'upcoming';
  }
  if (streak.state === 'claimed') {
    if (day === streak.nextDay) return 'next';
    return day <= streak.lastDay ? 'claimed' : 'upcoming';
  }
  if (day === streak.nextDay) return 'today';
  return day <= streak.lastDay ? 'claimed' : 'upcoming';
}

function ceilSeconds(untilMs, nowMs) {
  return Math.max(0, Math.ceil((untilMs - nowMs) / 1000));
}

/**
 * Title and pool of every chest in [rewardLists], so the app can name a chest
 * and show its odds before the player opens it.
 */
function chestsFor(config, rewardLists) {
  const chests = {};
  for (const rewards of rewardLists) {
    for (const reward of rewards) {
      const chest = reward.type === 'chest' ? config.chests[reward.chestId] : null;
      if (chest) chests[reward.chestId] = { title: chest.title, pool: chest.pool };
    }
  }
  return chests;
}

/** Every preset by id, so the app can name and colour a boost reward. */
function boostPresetsFor(config) {
  return Object.fromEntries(config.boosters.coin_boost.presets.map((preset) => [preset.id, presetView(preset)]));
}

/** The payload for GET /daily-reward. Times are seconds from now, never wall clocks. */
function buildDailyStatus({ streak, calendar, config, nowMs, offsetMinutes, activeBoost = null, comeback }) {
  const fallbackPreset = config.boosters.coin_boost.presets[0];
  return {
    enabled: true,
    state: streak.state,
    serverNow: nowMs,
    tzOffsetMinutes: offsetMinutes,
    calendar: { id: calendar.id, title: calendar.title, endsAt: calendar.endsAt },
    streak: {
      count: streak.count,
      best: streak.best,
      position: streak.lastDay,
      cycle: streak.cycles,
      nextDay: streak.nextDay,
      resets: streak.resets,
    },
    days: calendar.days.map(({ day, rewards }) => ({ day, rewards, status: dayStatus(day, streak) })),
    nextReward: {
      day: streak.nextDay,
      rewards: calendar.days[streak.nextDay - 1].rewards,
    },
    secondsUntilNextClaim:
      streak.state === 'claimed' ? ceilSeconds(streak.nextClaimAtMs, nowMs) : 0,
    grace: { days: config.graceDays, missedDays: streak.missedDays, graceUsed: streak.graceUsed },
    freezes: { count: streak.freezes, willUse: streak.freezesUsed },
    rescue: {
      available: streak.rescue.available,
      chipCost: streak.rescue.chipCost,
      lastDate: streak.rescue.lastDate,
    },
    adBoost: { enabled: config.adBoost.enabled, multiplier: config.adBoost.multiplier },
    // The running boost, in the shape app builds before boost presets read.
    coinBoost: {
      remainingSeconds: ceilSeconds(activeBoost?.untilMs ?? 0, nowMs),
      percent: activeBoost?.percent ?? fallbackPreset.percent,
      maxBonus: activeBoost?.maxBonus ?? fallbackPreset.maxBonus,
    },
    boostPresets: boostPresetsFor(config),
    comeback: {
      available: comeback.available,
      rewards: comeback.rewards,
      absentDays: comeback.absentDays,
    },
    chests: chestsFor(config, [...calendar.days.map((day) => day.rewards), comeback.rewards]),
  };
}

function disabledStatus(nowMs, offsetMinutes) {
  return { enabled: false, state: 'disabled', serverNow: nowMs, tzOffsetMinutes: offsetMinutes };
}

// ---------------------------------------------------------------- reminders

/**
 * Who gets a reminder push right now. Each row is { playerId, tzOffsetMinutes,
 * lastClaimLocalDate, lastReminderDate, streakCount }. The caller has already
 * filtered out players without a device token or with the pref off. Each
 * player gets at most one push per local day. Players on a streak of
 * AT_RISK_STREAK or more hear it at atRiskHour, and everyone else at localHour.
 */
function selectReminderRecipients(rows, nowMs, config) {
  if (!config.reminder.enabled) return [];
  const recipients = [];
  for (const row of rows) {
    const offset = clampOffset(row.tzOffsetMinutes) ?? 0;
    const localDate = localDateOf(nowMs, offset);
    if (row.lastClaimLocalDate === localDate || row.lastReminderDate === localDate) continue;
    const hour = localHourOf(nowMs, offset);
    const atRisk = (row.streakCount ?? 0) >= AT_RISK_STREAK && hour === config.reminder.atRiskHour;
    const regular = (row.streakCount ?? 0) < AT_RISK_STREAK && hour === config.reminder.localHour;
    if (atRisk || regular) {
      recipients.push({ playerId: row.playerId, kind: atRisk ? 'at_risk' : 'reminder', localDate });
    }
  }
  return recipients;
}

// ---------------------------------------------------------------- validation

class ConfigError extends Error {}

function invalid(message) {
  throw new ConfigError(message);
}

function isPlainObject(value) {
  return value !== null && typeof value === 'object' && !Array.isArray(value);
}

function requireObject(value, label, allowedKeys) {
  if (!isPlainObject(value)) invalid(`${label} must be an object`);
  const unknown = Object.keys(value).filter((key) => !allowedKeys.includes(key));
  if (unknown.length > 0) invalid(`${label} has unknown field: ${unknown.join(', ')}`);
  return value;
}

function intIn(value, [min, max], label) {
  if (!Number.isInteger(value) || value < min || value > max) {
    invalid(`${label} must be a whole number from ${min} to ${max}`);
  }
  return value;
}

function boolIn(value, label) {
  if (typeof value !== 'boolean') invalid(`${label} must be true or false`);
  return value;
}

function idIn(value, label, pattern) {
  if (typeof value !== 'string' || !pattern.test(value)) {
    invalid(`${label} must be lowercase letters, digits or dashes`);
  }
  return value;
}

function dateIn(value, label) {
  const valid =
    typeof value === 'string' &&
    /^\d{4}-\d{2}-\d{2}$/.test(value) &&
    Number.isFinite(Date.parse(`${value}T00:00:00Z`)) &&
    localDateOf(Date.parse(`${value}T00:00:00Z`), 0) === value;
  if (!valid) invalid(`${label} must be a date as YYYY-MM-DD`);
  return value;
}

function localizedText(value, label, maxLength) {
  requireObject(value, label, LANGUAGES);
  if (typeof value.en !== 'string' || value.en.trim() === '') invalid(`${label}.en is required`);
  const out = {};
  for (const language of LANGUAGES) {
    if (value[language] === undefined) continue;
    if (typeof value[language] !== 'string' || value[language].length > maxLength) {
      invalid(`${label}.${language} must be text up to ${maxLength} characters`);
    }
    out[language] = value[language].trim();
  }
  return out;
}

const CURRENCY_LIMITS = { money: LIMITS.maxMoney, chips: LIMITS.maxChips };

function parseCurrency(value, label) {
  requireObject(value, label, ['type', 'amount']);
  if (!Object.hasOwn(CURRENCY_LIMITS, value.type)) invalid(`${label}.type must be money or chips`);
  return {
    type: value.type,
    amount: intIn(value.amount, [1, CURRENCY_LIMITS[value.type]], `${label}.amount`),
  };
}

function parseItem(value, label, ctx) {
  requireObject(value, label, ['type', 'itemId', 'fallback']);
  if (typeof value.itemId !== 'string' || value.itemId === '') invalid(`${label}.itemId is required`);
  if (ctx.catalog) {
    const known = value.type === 'avatar' ? ctx.catalog.avatarIds : ctx.catalog.deckIds;
    if (!known.has(value.itemId)) invalid(`${label}.itemId "${value.itemId}" is not a known ${value.type}`);
  }
  return {
    type: value.type,
    itemId: value.itemId,
    fallback: parseCurrency(value.fallback, `${label}.fallback`),
  };
}

function parseBooster(value, label, ctx) {
  if (value.boosterId === 'coin_boost') {
    requireObject(value, label, ['type', 'boosterId', 'presetId', 'minutes']);
    // Rewards saved before presets existed run at the first preset.
    const presetId = value.presetId ?? ctx.boostPresetIds[0];
    if (!ctx.boostPresetIds.includes(presetId)) invalid(`${label}.presetId "${presetId}" is not a boost preset`);
    return {
      type: 'booster',
      boosterId: 'coin_boost',
      presetId,
      minutes: intIn(value.minutes, [1, LIMITS.maxBoostMinutes], `${label}.minutes`),
    };
  }
  if (value.boosterId === 'streak_freeze') {
    requireObject(value, label, ['type', 'boosterId', 'quantity']);
    return {
      type: 'booster',
      boosterId: 'streak_freeze',
      quantity: intIn(value.quantity, [1, LIMITS.maxFreezeQuantity], `${label}.quantity`),
    };
  }
  invalid(`${label}.boosterId must be one of ${BOOSTER_IDS.join(', ')}`);
}

/** One reward. `ctx` is { catalog, chestIds }. Chests are only allowed when `allowChest` is set. */
function parseReward(value, label, ctx, { allowChest }) {
  if (!isPlainObject(value)) invalid(`${label} must be an object`);
  switch (value.type) {
    case 'money':
    case 'chips':
      return parseCurrency(value, label);
    case 'avatar':
    case 'deck':
      return parseItem(value, label, ctx);
    case 'booster':
      return parseBooster(value, label, ctx);
    case 'chest':
      if (!allowChest) invalid(`${label}: a chest cannot hold another chest`);
      requireObject(value, label, ['type', 'chestId']);
      if (!ctx.chestIds.has(value.chestId)) invalid(`${label}.chestId "${value.chestId}" is not defined`);
      return { type: 'chest', chestId: value.chestId };
    default:
      invalid(`${label}.type must be money, chips, avatar, deck, booster or chest`);
  }
}

function parseRewardList(value, label, ctx, options) {
  if (!Array.isArray(value) || value.length < 1 || value.length > LIMITS.maxRewardsPerDay) {
    invalid(`${label} needs 1 to ${LIMITS.maxRewardsPerDay} rewards`);
  }
  return value.map((reward, index) => parseReward(reward, `${label} reward ${index + 1}`, ctx, options));
}

function parseDays(value, label, ctx) {
  if (!Array.isArray(value) || value.length !== CYCLE_DAYS) invalid(`${label} must list exactly 7 days`);
  return value.map((entry, index) => {
    const dayLabel = `${label} day ${index + 1}`;
    requireObject(entry, dayLabel, ['day', 'rewards']);
    if (entry.day !== index + 1) invalid(`${dayLabel} must be numbered ${index + 1}`);
    return {
      day: entry.day,
      rewards: parseRewardList(entry.rewards, dayLabel, ctx, { allowChest: true }),
    };
  });
}

function parseEvents(value, ctx) {
  if (!Array.isArray(value) || value.length > LIMITS.maxEvents) {
    invalid(`events must be a list of up to ${LIMITS.maxEvents} events`);
  }
  const events = value.map((entry, index) => {
    const label = `events[${index}]`;
    requireObject(entry, label, ['id', 'title', 'startsAt', 'endsAt', 'days']);
    const event = {
      id: idIn(entry.id, `${label}.id`, /^[a-z0-9-]{1,40}$/),
      title: localizedText(entry.title, `${label}.title`, 40),
      startsAt: dateIn(entry.startsAt, `${label}.startsAt`),
      endsAt: dateIn(entry.endsAt, `${label}.endsAt`),
      days: parseDays(entry.days, label, ctx),
    };
    if (event.endsAt < event.startsAt) invalid(`${label}.endsAt is before startsAt`);
    return event;
  });

  const ids = new Set(events.map((event) => event.id));
  if (ids.size !== events.length) invalid('Event ids must be unique');
  const byStart = [...events].sort((a, b) => a.startsAt.localeCompare(b.startsAt));
  for (let index = 1; index < byStart.length; index += 1) {
    if (byStart[index].startsAt <= byStart[index - 1].endsAt) {
      invalid(`Events "${byStart[index - 1].id}" and "${byStart[index].id}" overlap`);
    }
  }
  return events;
}

function parseChests(value, ctx) {
  if (!isPlainObject(value)) invalid('chests must be an object');
  const entries = Object.entries(value);
  if (entries.length > LIMITS.maxChests) invalid(`At most ${LIMITS.maxChests} chests`);
  const chests = {};
  for (const [chestId, chest] of entries) {
    const label = `chests.${chestId}`;
    idIn(chestId, label, /^[a-z][a-z0-9_]{1,31}$/);
    requireObject(chest, label, ['title', 'pool']);
    if (!Array.isArray(chest.pool) || chest.pool.length < 1 || chest.pool.length > LIMITS.maxChestEntries) {
      invalid(`${label} needs 1 to ${LIMITS.maxChestEntries} entries`);
    }
    chests[chestId] = {
      title: localizedText(chest.title, `${label}.title`, 40),
      pool: chest.pool.map((entry, index) => {
        requireObject(entry, `${label} entry ${index + 1}`, ['weight', 'reward']);
        return {
          weight: intIn(entry.weight, [1, 1000], `${label} entry ${index + 1}.weight`),
          reward: parseReward(entry.reward, `${label} entry ${index + 1}`, ctx, { allowChest: false }),
        };
      }),
    };
  }
  return chests;
}

/**
 * Coin Boost presets. The config saved before presets existed held one
 * { percent, maxBonus }. That becomes a single "standard" preset.
 */
function parseBoostPresets(value) {
  requireObject(value, 'boosters.coin_boost', ['presets', 'percent', 'maxBonus']);
  if (value.presets === undefined && value.percent !== undefined) {
    const [standard] = DEFAULTS.boosters.coin_boost.presets;
    return parseBoostPresets({
      presets: [{ ...standard, percent: value.percent, maxBonus: value.maxBonus }],
    });
  }
  if (value.percent !== undefined || value.maxBonus !== undefined) {
    invalid('boosters.coin_boost sets its value on each preset');
  }
  const list = value.presets;
  if (!Array.isArray(list) || list.length < 1 || list.length > MAX_PRESETS) {
    invalid(`Coin Boost needs 1 to ${MAX_PRESETS} presets`);
  }
  const presets = list.map((entry, index) => {
    const label = `Boost preset ${index + 1}`;
    requireObject(entry, label, ['id', 'name', 'percent', 'maxBonus', 'tier']);
    if (!TIERS.includes(entry.tier)) invalid(`${label}.tier must be one of ${TIERS.join(', ')}`);
    return {
      id: idIn(entry.id, `${label}.id`, /^[a-z0-9-]{1,32}$/),
      name: localizedText(entry.name, `${label}.name`, 30),
      percent: intIn(entry.percent, [1, LIMITS.maxBoostPercent], `${label}.percent`),
      maxBonus: intIn(entry.maxBonus, [0, LIMITS.maxBoostBonus], `${label}.maxBonus`),
      tier: entry.tier,
    };
  });
  if (new Set(presets.map((preset) => preset.id)).size !== presets.length) {
    invalid('Boost preset ids must be unique');
  }
  // One value runs at a time, and the value is what tells two boosts apart.
  if (new Set(presets.map((preset) => preset.percent)).size !== presets.length) {
    invalid('Two boost presets give the same percent. Each preset needs its own percent.');
  }
  return presets;
}

function buildConfig(input, catalog) {
  requireObject(input, 'config', CONFIG_KEYS);
  requireObject(input.boosters, 'boosters', ['coin_boost']);
  const presets = parseBoostPresets(input.boosters.coin_boost);
  const boostPresetIds = presets.map((preset) => preset.id);
  const chests = parseChests(input.chests, { catalog, chestIds: new Set(), boostPresetIds });
  const ctx = { catalog, chestIds: new Set(Object.keys(chests)), boostPresetIds };

  requireObject(input.rescue, 'rescue', ['enabled', 'chipCost', 'windowDays']);
  requireObject(input.adBoost, 'adBoost', ['enabled', 'multiplier']);
  requireObject(input.comeback, 'comeback', ['enabled', 'absentDays', 'cooldownDays', 'rewards']);
  requireObject(input.reminder, 'reminder', ['enabled', 'localHour', 'atRiskHour']);
  requireObject(input.calendar, 'calendar', ['id', 'days']);

  const config = {
    enabled: boolIn(input.enabled, 'enabled'),
    graceDays: intIn(input.graceDays, [0, 3], 'graceDays'),
    minClaimGapHours: intIn(input.minClaimGapHours, [0, 24], 'minClaimGapHours'),
    rescue: {
      enabled: boolIn(input.rescue.enabled, 'rescue.enabled'),
      chipCost: intIn(input.rescue.chipCost, [1, 50], 'rescue.chipCost'),
      windowDays: intIn(input.rescue.windowDays, [0, 7], 'rescue.windowDays'),
    },
    adBoost: {
      enabled: boolIn(input.adBoost.enabled, 'adBoost.enabled'),
      multiplier: intIn(input.adBoost.multiplier, [2, 5], 'adBoost.multiplier'),
    },
    boosters: { coin_boost: { presets } },
    comeback: {
      enabled: boolIn(input.comeback.enabled, 'comeback.enabled'),
      absentDays: intIn(input.comeback.absentDays, [1, 90], 'comeback.absentDays'),
      cooldownDays: intIn(input.comeback.cooldownDays, [1, 365], 'comeback.cooldownDays'),
      rewards: parseRewardList(input.comeback.rewards, 'comeback', ctx, { allowChest: true }),
    },
    reminder: {
      enabled: boolIn(input.reminder.enabled, 'reminder.enabled'),
      localHour: intIn(input.reminder.localHour, [0, 23], 'reminder.localHour'),
      atRiskHour: intIn(input.reminder.atRiskHour, [0, 23], 'reminder.atRiskHour'),
    },
    calendar: {
      id: idIn(input.calendar.id, 'calendar.id', /^[a-z0-9-]{1,40}$/),
      days: parseDays(input.calendar.days, 'calendar', ctx),
    },
    events: parseEvents(input.events, ctx),
    chests,
  };

  if (Buffer.byteLength(JSON.stringify(config)) > LIMITS.maxConfigBytes) {
    invalid('The reward table is too large');
  }
  return config;
}

/**
 * Checks a complete daily-rewards config. `catalog` is { avatarIds, deckIds }
 * (Sets). Pass null to skip the catalog check, as on reads.
 * Returns { config } or { error, message }.
 */
function validateConfig(input, { catalog = null } = {}) {
  try {
    return { config: buildConfig(input, catalog) };
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
    console.error('[daily-rewards] stored config is invalid, using defaults', message);
    return DEFAULTS;
  }
  return config;
}

// ---------------------------------------------------------------- support tools

const SUPPORT_ACTIONS = ['restore', 'gift_freeze', 'gift_boost', 'shift_days', 'reset'];
// These rewrite a player's history, so they only run with DAILY_REWARDS_DEBUG=1.
const DEBUG_ACTIONS = ['gift_boost', 'shift_days', 'reset'];
const MAX_SHIFT_DAYS = 30;

/**
 * Support fix for a broken streak: move the last claim to yesterday in the
 * player's local time, long enough ago to clear the minimum gap. The next
 * claim then continues the streak at the next day and keeps the count.
 * Returns { lastDate, lastAtMs }, or { error } when there is nothing to fix.
 */
function planRestore(streak, nowMs, offsetMinutes, config) {
  if (streak.state !== 'broken' && !streak.resets) return { error: 'streak_not_broken' };
  return {
    lastDate: addDays(streak.localDate, -1),
    lastAtMs: Math.min(
      localMidnightMs(streak.localDate, offsetMinutes) - 1,
      nowMs - config.minClaimGapHours * HOUR_MS,
    ),
  };
}

/**
 * Validates POST /admin/daily-rewards/player/action.
 * Returns { action, playerId, quantity?, days?, presetId?, minutes? } or { error, message }.
 */
function parseSupportAction(body, { debug = false } = {}) {
  if (!isPlainObject(body)) return { error: 'invalid_action', message: 'Expected a JSON object' };
  const playerId = typeof body.playerId === 'string' ? body.playerId.trim() : '';
  if (playerId === '') return { error: 'invalid_value', message: 'playerId is required' };
  const { action } = body;
  if (!SUPPORT_ACTIONS.includes(action)) {
    return { error: 'invalid_action', message: `action must be one of ${SUPPORT_ACTIONS.join(', ')}` };
  }
  if (DEBUG_ACTIONS.includes(action) && !debug) {
    return { error: 'debug_only', message: `${action} only runs when DAILY_REWARDS_DEBUG=1` };
  }
  if (action === 'gift_freeze') {
    const quantity = body.quantity ?? 1;
    if (!Number.isInteger(quantity) || quantity < 1 || quantity > LIMITS.maxFreezeQuantity) {
      return {
        error: 'invalid_value',
        message: `quantity must be a whole number from 1 to ${LIMITS.maxFreezeQuantity}`,
      };
    }
    return { action, playerId, quantity };
  }
  if (action === 'shift_days') {
    const { days } = body;
    if (!Number.isInteger(days) || days < 1 || days > MAX_SHIFT_DAYS) {
      return { error: 'invalid_value', message: `days must be a whole number from 1 to ${MAX_SHIFT_DAYS}` };
    }
    return { action, playerId, days };
  }
  if (action === 'gift_boost') {
    const { presetId, minutes } = body;
    if (typeof presetId !== 'string' || presetId === '') {
      return { error: 'invalid_value', message: 'presetId is required' };
    }
    if (!Number.isInteger(minutes) || minutes < 1 || minutes > LIMITS.maxBoostMinutes) {
      return {
        error: 'invalid_value',
        message: `minutes must be a whole number from 1 to ${LIMITS.maxBoostMinutes}`,
      };
    }
    return { action, playerId, presetId, minutes };
  }
  return { action, playerId };
}

// ---------------------------------------------------------------- store

function frozenState(config, source) {
  return Object.freeze({ ...config, source });
}

function codedError(code, message) {
  const error = new Error(message);
  error.code = code;
  return error;
}

/**
 * The live config, cached like turn_timer.js. `read()` and `write(config)`
 * handle the current value. `readPrevious()` and `writePrevious(config)` handle
 * the copy kept for one-click revert. `current()` never waits on the database.
 */
function createDailyRewardsStore({
  read,
  write,
  readPrevious,
  writePrevious,
  cacheMs = CACHE_MS,
  now = Date.now,
  onReadError = (error) =>
    console.error('[daily-rewards] read failed, keeping last-known settings', error),
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

module.exports = {
  DEFAULTS,
  LIMITS,
  BOOSTER_IDS,
  CYCLE_DAYS,
  OFFSET_JUMP_MINUTES,
  localDateOf,
  addDays,
  resolveOffset,
  clampOffset,
  computeStreakState,
  planClaim,
  applyClaim,
  pickCalendar,
  rollChest,
  computeBoostBonus,
  comebackStatus,
  buildDailyStatus,
  disabledStatus,
  selectReminderRecipients,
  planRestore,
  parseSupportAction,
  validateConfig,
  normalizeConfig,
  createDailyRewardsStore,
};
