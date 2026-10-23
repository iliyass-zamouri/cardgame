// App colour themes served through GET /app/config. The app bundles every
// palette; the server only picks which id is live and whether its motion
// layer may run. Unknown ids fall back to the default, so a typo or an old
// client can never leave the app without a look.
const THEMES = ['casino', 'halloween'];
const DEFAULT_THEME = 'casino';
const CACHE_MS = 15_000;
const EMPTY_RECORD = Object.freeze({ id: null, animated: true });

function normalizeTheme(raw) {
  if (typeof raw !== 'string') return null;
  const id = raw.trim().toLowerCase();
  return THEMES.includes(id) ? id : null;
}

function themeFromEnv(env = process.env) {
  return normalizeTheme(env.APP_THEME) ?? DEFAULT_THEME;
}

/**
 * Validates an admin POST body. `theme` is a known id or null (clears the
 * override); `animated` is the motion kill switch. Returns `{ patch }` or
 * `{ error, message }`.
 */
function parseThemePatch(body) {
  if (!body || typeof body !== 'object' || Array.isArray(body)) {
    return { error: 'invalid_body', message: 'Expected a JSON object' };
  }
  const patch = {};
  if (body.theme !== undefined) {
    if (body.theme === null) {
      patch.theme = null;
    } else {
      patch.theme = normalizeTheme(body.theme);
      if (patch.theme === null) {
        return {
          error: 'invalid_theme',
          message: `theme must be one of ${THEMES.join(', ')}, or null`,
        };
      }
    }
  }
  if (body.animated !== undefined) {
    if (typeof body.animated !== 'boolean') {
      return { error: 'invalid_body', message: 'animated must be true or false' };
    }
    patch.animated = body.animated;
  }
  if (Object.keys(patch).length === 0) {
    return { error: 'invalid_body', message: 'Send theme and/or animated' };
  }
  return { patch };
}

/**
 * Live theme state over the env default. `read()` resolves the stored record
 * `{ id, animated }` or null, and `write(record)` persists it. Reads are
 * cached briefly. A failing read serves the env default instead of erroring,
 * so /app/config never fails because of the theme.
 */
function createThemeStore({
  read,
  write,
  env = process.env,
  cacheMs = CACHE_MS,
  now = Date.now,
  onReadError = (error) =>
    console.error('[app-theme] read failed, serving env default', error),
} = {}) {
  const envDefault = themeFromEnv(env);
  /** @type {{ at: number, record: object } | null} */
  let cached = null;

  function resolve(record) {
    const override = normalizeTheme(record.id);
    return {
      id: override ?? envDefault,
      animated: record.animated !== false,
      source: override ? 'admin' : 'env',
      envDefault,
    };
  }

  async function stored() {
    if (cached && now() - cached.at < cacheMs) return cached.record;
    const record = (await read()) ?? EMPTY_RECORD;
    cached = { at: now(), record };
    return record;
  }

  return {
    /** Never throws: a failing read serves the env default, uncached. */
    async current() {
      try {
        return resolve(await stored());
      } catch (error) {
        onReadError(error);
        return resolve(EMPTY_RECORD);
      }
    },
    /** Merges a validated patch into the stored record. Throws if the store is down. */
    async set(patch) {
      // Read the store directly: merging into a fallback would erase the other field.
      const base = (await read()) ?? EMPTY_RECORD;
      const record = {
        id: 'theme' in patch ? patch.theme : base.id,
        animated: 'animated' in patch ? patch.animated : base.animated !== false,
      };
      await write(record);
      cached = { at: now(), record };
      return resolve(record);
    },
  };
}

module.exports = {
  THEMES,
  DEFAULT_THEME,
  normalizeTheme,
  themeFromEnv,
  parseThemePatch,
  createThemeStore,
};
