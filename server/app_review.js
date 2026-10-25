// The rules behind the rate-the-app prompt. Everything here is pure apart
// from runPushTick, which takes its database and FCM calls as arguments.
// The config comes from server/app_review_config.js.

const { LANGUAGES } = require('./config_validation');
const { TRIGGERS, AUTO_TRIGGERS, FEEDBACK_TAGS, storeFor } = require('./app_review_config');

const DAY_MS = 24 * 60 * 60 * 1000;
const COMMENT_MAX = 1000;
const PLATFORMS = ['android', 'ios', 'macos', 'other'];
/** Stops a double tap or a replayed request from saving two ratings. */
const RATE_MIN_GAP_MS = 30_000;
const AUTO_PUSH_CAMPAIGN = 'app_review_auto';

/**
 * Whether to show the prompt now.
 * @param {{
 *   config: object,
 *   trigger: string,
 *   player: { matchesPlayed: number, wins: number, createdAtMs: number | null },
 *   state: null | {
 *     promptsShown: number,
 *     lastPromptAtMs: number | null,
 *     lastStars: number | null,
 *     lastRatedAtMs: number | null,
 *   },
 *   nowMs: number,
 * }} args
 * @returns {{ show: boolean, reason: string }}
 */
function evaluateEligibility({ config, trigger, player, state, nowMs }) {
  if (!config.enabled) return { show: false, reason: 'disabled' };
  if (!TRIGGERS.includes(trigger)) return { show: false, reason: 'unknown_trigger' };
  // Opened on purpose: the rules are for prompts the player didn't ask for.
  if (trigger === 'push') return { show: true, reason: 'push' };
  if (trigger === 'settings') {
    return config.triggers.settings
      ? { show: true, reason: 'settings' }
      : { show: false, reason: 'trigger_off' };
  }
  if (!config.triggers[trigger]) return { show: false, reason: 'trigger_off' };

  const { rules } = config;
  if (player.matchesPlayed < rules.minMatchesPlayed) return { show: false, reason: 'too_few_matches' };
  if (player.wins < rules.minWins) return { show: false, reason: 'too_few_wins' };
  if (player.createdAtMs != null && nowMs - player.createdAtMs < rules.minAccountAgeDays * DAY_MS) {
    return { show: false, reason: 'account_too_new' };
  }

  if (state) {
    if (state.promptsShown >= rules.maxPrompts) return { show: false, reason: 'max_prompts' };
    if (state.lastPromptAtMs != null && nowMs - state.lastPromptAtMs < rules.cooldownDays * DAY_MS) {
      return { show: false, reason: 'cooldown' };
    }
    if (state.lastRatedAtMs != null) {
      const happy = (state.lastStars ?? 0) >= config.storeMinStars;
      const days = happy ? rules.highRatingRepromptDays : rules.lowRatingRepromptDays;
      if (days === 0) return { show: false, reason: 'already_rated' };
      if (nowMs - state.lastRatedAtMs < days * DAY_MS) return { show: false, reason: 'already_rated' };
    }
  }
  return { show: true, reason: 'eligible' };
}

/** 'store' sends the player on to rate publicly, 'feedback' asks what went wrong. */
function decideAction(config, platform, stars) {
  const store = storeFor(platform);
  if (!store) return 'feedback';
  if (config.flow[store] === 'native_only') return 'store';
  return stars >= config.storeMinStars ? 'store' : 'feedback';
}

/** Counts towards maxPrompts. Prompts the player opened don't. */
function countsAsPrompt(trigger) {
  return AUTO_TRIGGERS.includes(trigger);
}

function cleanText(value, maxLength) {
  if (typeof value !== 'string') return '';
  return value
    .replace(/[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]/g, '')
    .trim()
    .slice(0, maxLength);
}

/** Device facts the app sends with every call. Unknown values are coerced, not rejected. */
function parseClientInfo(input) {
  const source = input && typeof input === 'object' ? input : {};
  const platform = typeof source.platform === 'string' ? source.platform.toLowerCase() : '';
  const locale = typeof source.locale === 'string' ? source.locale.slice(0, 2).toLowerCase() : '';
  return {
    platform: PLATFORMS.includes(platform) ? platform : 'other',
    appVersion: cleanText(source.appVersion, 32) || null,
    locale: LANGUAGES.includes(locale) ? locale : 'en',
  };
}

function parseTrigger(value) {
  return TRIGGERS.includes(value) ? value : null;
}

/** POST /app-review/rate. Returns { stars, trigger, ...clientInfo } or { error, message }. */
function parseRateInput(input) {
  const source = input && typeof input === 'object' ? input : {};
  if (!Number.isInteger(source.stars) || source.stars < 1 || source.stars > 5) {
    return { error: 'invalid_value', message: 'stars must be a whole number from 1 to 5' };
  }
  const trigger = parseTrigger(source.trigger);
  if (!trigger) return { error: 'invalid_value', message: `trigger must be one of ${TRIGGERS.join(', ')}` };
  return { stars: source.stars, trigger, ...parseClientInfo(source) };
}

/** POST /app-review/:id/feedback. Unknown tags are dropped; the comment is optional. */
function parseFeedbackInput(input) {
  const source = input && typeof input === 'object' ? input : {};
  const tags = Array.isArray(source.tags)
    ? FEEDBACK_TAGS.filter((tag) => source.tags.includes(tag))
    : [];
  const comment = cleanText(source.comment, COMMENT_MAX);
  if (tags.length === 0 && !comment) {
    return { error: 'invalid_value', message: 'Pick a reason or write a comment' };
  }
  return { tags, comment: comment || null };
}

/** True when `nowMs` falls in [start, end) UTC hours. A window like [22, 2] wraps midnight. */
function inSendWindow([start, end], nowMs) {
  const hour = new Date(nowMs).getUTCHours();
  if (start === end) return true;
  return start < end ? hour >= start && hour < end : hour >= start || hour < end;
}

/** The push copy in the player's language, falling back to English. */
function pushCopyFor(push, locale) {
  return {
    title: push.title[locale] || push.title.en,
    body: push.body[locale] || push.body.en,
  };
}

/**
 * One pass of the automatic rating push. Players are marked before the send,
 * so a crash mid-send never pushes anyone twice.
 * @param {{
 *   config: object,
 *   nowMs: number,
 *   selectCandidates: (config: object, nowMs: number, limit: number) => Promise<{playerId: string, locale: string | null}[]>,
 *   markPushSent: (playerIds: string[], nowMs: number) => Promise<void>,
 *   sendToPlayers: (playerIds: string[], opts: object) => Promise<object>,
 * }} deps
 * @returns {Promise<{ sent: number, skipped?: string }>}
 */
async function runPushTick({ config, nowMs, selectCandidates, markPushSent, sendToPlayers }) {
  if (!config.enabled || !config.push.enabled) return { sent: 0, skipped: 'disabled' };
  if (!inSendWindow(config.push.sendWindowUtc, nowMs)) return { sent: 0, skipped: 'outside_window' };

  const candidates = await selectCandidates(config, nowMs, config.push.perTickLimit);
  if (candidates.length === 0) return { sent: 0 };
  await markPushSent(candidates.map((row) => row.playerId), nowMs);

  /** @type {Map<string, string[]>} */
  const byLocale = new Map();
  for (const { playerId, locale } of candidates) {
    const key = LANGUAGES.includes(locale) ? locale : 'en';
    if (!byLocale.has(key)) byLocale.set(key, []);
    byLocale.get(key).push(playerId);
  }
  for (const [locale, playerIds] of byLocale) {
    const copy = pushCopyFor(config.push, locale);
    await sendToPlayers(playerIds, {
      category: 'marketing',
      ...copy,
      data: { type: 'app_review', route: '/rate', campaignId: AUTO_PUSH_CAMPAIGN },
    });
  }
  return { sent: candidates.length };
}

module.exports = {
  DAY_MS,
  COMMENT_MAX,
  PLATFORMS,
  RATE_MIN_GAP_MS,
  AUTO_PUSH_CAMPAIGN,
  evaluateEligibility,
  decideAction,
  countsAsPrompt,
  parseClientInfo,
  parseTrigger,
  parseRateInput,
  parseFeedbackInput,
  inSendWindow,
  pushCopyFor,
  runPushTick,
};
