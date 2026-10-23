// Per-turn time limit for online matches. Admins set it live from the
// Gameplay tab. GameRoom reads it when each turn starts, so a change reaches
// matches already in progress from their next turn.
const DEFAULTS = Object.freeze({
  enabled: true,
  turnSeconds: 30,
  maxMissedTurns: 3,
  revealSeconds: 15,
});

/** Inclusive limits for the numeric settings. */
const BOUNDS = Object.freeze({
  turnSeconds: Object.freeze([10, 120]),
  maxMissedTurns: Object.freeze([0, 10]),
  revealSeconds: Object.freeze([5, 60]),
});

const CACHE_MS = 15_000;
const DEFAULT_STATE = Object.freeze({ ...DEFAULTS, source: 'default' });

function inBounds(value, [min, max]) {
  return Number.isInteger(value) && value >= min && value <= max;
}

/** Each field takes its stored value when valid, otherwise its default. */
function normalizeConfig(raw) {
  const stored = raw && typeof raw === 'object' ? raw : {};
  return {
    enabled: typeof stored.enabled === 'boolean' ? stored.enabled : DEFAULTS.enabled,
    turnSeconds: inBounds(stored.turnSeconds, BOUNDS.turnSeconds)
      ? stored.turnSeconds
      : DEFAULTS.turnSeconds,
    maxMissedTurns: inBounds(stored.maxMissedTurns, BOUNDS.maxMissedTurns)
      ? stored.maxMissedTurns
      : DEFAULTS.maxMissedTurns,
    revealSeconds: inBounds(stored.revealSeconds, BOUNDS.revealSeconds)
      ? stored.revealSeconds
      : DEFAULTS.revealSeconds,
  };
}

/**
 * Validates an admin POST body. Any non-empty subset of the settings is
 * accepted. Returns `{ patch }` or `{ error, message }`.
 */
function parseTurnTimerPatch(body) {
  if (!body || typeof body !== 'object' || Array.isArray(body)) {
    return { error: 'invalid_body', message: 'Expected a JSON object' };
  }
  const known = Object.keys(DEFAULTS);
  const unknown = Object.keys(body).filter((key) => !known.includes(key));
  if (unknown.length > 0) {
    return { error: 'invalid_body', message: `Unknown setting: ${unknown.join(', ')}` };
  }
  const patch = {};
  for (const key of known) {
    if (body[key] === undefined) continue;
    if (key === 'enabled') {
      if (typeof body.enabled !== 'boolean') {
        return { error: 'invalid_value', message: 'enabled must be true or false' };
      }
    } else if (!inBounds(body[key], BOUNDS[key])) {
      const [min, max] = BOUNDS[key];
      return {
        error: 'invalid_value',
        message: `${key} must be a whole number from ${min} to ${max}`,
      };
    }
    patch[key] = body[key];
  }
  if (Object.keys(patch).length === 0) {
    return { error: 'invalid_body', message: `Send at least one of: ${known.join(', ')}` };
  }
  return { patch };
}

/**
 * Live turn-limit settings. `read()` resolves the stored record or null, and
 * `write(record)` persists it. `current()` never waits on the database. A
 * failing read keeps the last good value, or the code defaults if none.
 */
function createTurnTimerStore({
  read,
  write,
  cacheMs = CACHE_MS,
  now = Date.now,
  onReadError = (error) =>
    console.error('[turn-timer] read failed, keeping last-known settings', error),
} = {}) {
  let state = DEFAULT_STATE;
  let loadedAt = -Infinity;
  /** @type {Promise<void> | null} */
  let pending = null;
  // Bumped by set(): a read that started before a write must not overwrite it.
  let epoch = 0;

  async function load() {
    const startedAt = epoch;
    try {
      const record = await read();
      if (startedAt === epoch) {
        state = record
          ? Object.freeze({ ...normalizeConfig(record), source: 'admin' })
          : DEFAULT_STATE;
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

  return {
    /** Synchronous. Starts a background refresh when the cache is stale. */
    current() {
      if (now() - loadedAt >= cacheMs) void refresh();
      return state;
    },
    /** Reloads from the store now. Never rejects. */
    refresh,
    /** Merges a validated patch into the stored settings. Throws if the store is down. */
    async set(patch) {
      // Read the store directly: a cached value must not decide which fields survive.
      const base = normalizeConfig(await read());
      const config = normalizeConfig({ ...base, ...patch });
      await write(config);
      epoch += 1;
      state = Object.freeze({ ...config, source: 'admin' });
      loadedAt = now();
      return state;
    },
  };
}

module.exports = {
  DEFAULTS,
  BOUNDS,
  normalizeConfig,
  parseTurnTimerPatch,
  createTurnTimerStore,
};
