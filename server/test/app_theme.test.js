const test = require('node:test');
const assert = require('node:assert/strict');

const {
  THEMES,
  normalizeTheme,
  themeFromEnv,
  parseThemePatch,
  createThemeStore,
} = require('../app_theme');
const { GameServer } = require('../game_server');

/** In-memory stand-in for the app_settings row. */
function memoryRow(initial = null) {
  let row = initial;
  return {
    read: async () => row,
    write: async (next) => {
      row = next;
    },
    peek: () => row,
  };
}

function unreachableRow() {
  const down = async () => {
    throw new Error('db down');
  };
  return { read: down, write: down };
}

test('normalizeTheme trims, lowercases and rejects unknown ids', () => {
  assert.equal(normalizeTheme('  Halloween '), 'halloween');
  assert.equal(normalizeTheme('casino'), 'casino');
  assert.equal(normalizeTheme('pumpkin'), null);
  assert.equal(normalizeTheme(undefined), null);
  assert.equal(normalizeTheme(null), null);
});

test('themeFromEnv defaults to casino', () => {
  assert.equal(themeFromEnv({}), 'casino');
  assert.equal(themeFromEnv({ APP_THEME: 'halloween' }), 'halloween');
  assert.equal(themeFromEnv({ APP_THEME: 'nope' }), 'casino');
});

test('parseThemePatch validates the admin body', () => {
  assert.deepEqual(parseThemePatch({ theme: 'halloween' }), {
    patch: { theme: 'halloween' },
  });
  assert.deepEqual(parseThemePatch({ theme: null }), { patch: { theme: null } });
  assert.deepEqual(parseThemePatch({ animated: false }), {
    patch: { animated: false },
  });
  assert.equal(parseThemePatch({ theme: 'pumpkin' }).error, 'invalid_theme');
  assert.equal(parseThemePatch({ animated: 'no' }).error, 'invalid_body');
  assert.equal(parseThemePatch({}).error, 'invalid_body');
  assert.equal(parseThemePatch([]).error, 'invalid_body');
  assert.equal(parseThemePatch(null).error, 'invalid_body');
});

test('current() serves the env default when nothing is stored', async () => {
  const store = createThemeStore({
    ...memoryRow(),
    env: { APP_THEME: 'halloween' },
  });
  assert.deepEqual(await store.current(), {
    id: 'halloween',
    animated: true,
    source: 'env',
    envDefault: 'halloween',
  });
});

test('a stored override beats the env default', async () => {
  const store = createThemeStore({
    ...memoryRow({ id: 'halloween', animated: true }),
    env: {},
  });
  assert.deepEqual(await store.current(), {
    id: 'halloween',
    animated: true,
    source: 'admin',
    envDefault: 'casino',
  });
});

test('a failing read serves the env default instead of throwing', async () => {
  const errors = [];
  const store = createThemeStore({
    ...unreachableRow(),
    env: { APP_THEME: 'halloween' },
    onReadError: (error) => errors.push(error),
  });
  const state = await store.current();
  assert.equal(state.id, 'halloween');
  assert.equal(state.source, 'env');
  assert.equal(errors.length, 1);
});

test('reads are cached until the TTL passes', async () => {
  let reads = 0;
  let clock = 0;
  const store = createThemeStore({
    read: async () => {
      reads += 1;
      return { id: 'halloween', animated: true };
    },
    write: async () => {},
    env: {},
    cacheMs: 1000,
    now: () => clock,
  });
  await store.current();
  await store.current();
  assert.equal(reads, 1);
  clock = 1000;
  await store.current();
  assert.equal(reads, 2);
});

test('set() merges into the stored record and writes through', async () => {
  const row = memoryRow({ id: 'halloween', animated: true });
  const store = createThemeStore({ ...row, env: {}, cacheMs: 60_000 });
  assert.equal((await store.current()).id, 'halloween');

  assert.deepEqual(await store.set({ animated: false }), {
    id: 'halloween',
    animated: false,
    source: 'admin',
    envDefault: 'casino',
  });
  assert.deepEqual(row.peek(), { id: 'halloween', animated: false });

  // Clearing the override keeps the motion kill switch as it was.
  assert.deepEqual(await store.set({ theme: null }), {
    id: 'casino',
    animated: false,
    source: 'env',
    envDefault: 'casino',
  });
  assert.deepEqual(row.peek(), { id: null, animated: false });
});

test('set() refuses to write when the stored record cannot be read', async () => {
  const store = createThemeStore({ ...unreachableRow(), env: {} });
  await assert.rejects(store.set({ theme: 'halloween' }), /db down/);
});

test('app config and admin routes share one live theme', async (t) => {
  const previousSecret = process.env.ADMIN_PUSH_SECRET;
  process.env.ADMIN_PUSH_SECRET = 'test-admin-secret';
  t.after(() => {
    if (previousSecret === undefined) delete process.env.ADMIN_PUSH_SECRET;
    else process.env.ADMIN_PUSH_SECRET = previousSecret;
  });

  const themeStore = createThemeStore({
    ...memoryRow(),
    env: { APP_THEME: 'casino' },
    cacheMs: 0,
  });
  const server = new GameServer({ port: 0, themeStore });
  const address = await server.start();
  t.after(() => server.stop());

  const base = `http://127.0.0.1:${address.port}`;
  const admin = {
    'x-admin-push-secret': 'test-admin-secret',
    'content-type': 'application/json',
  };
  const post = (body) =>
    fetch(`${base}/admin/theme`, {
      method: 'POST',
      headers: admin,
      body: typeof body === 'string' ? body : JSON.stringify(body),
    });
  const configTheme = async () =>
    (await (await fetch(`${base}/app/config`)).json()).theme;

  assert.deepEqual(await configTheme(), { id: 'casino', animated: true });

  assert.equal((await fetch(`${base}/admin/theme`)).status, 401);
  const listed = await (
    await fetch(`${base}/admin/theme`, { headers: admin })
  ).json();
  assert.deepEqual(listed.available, THEMES);
  assert.equal(listed.source, 'env');

  const switched = await post({ theme: 'halloween' });
  assert.equal(switched.status, 200);
  assert.equal((await switched.json()).theme, 'halloween');
  assert.deepEqual(await configTheme(), { id: 'halloween', animated: true });

  assert.equal((await post({ animated: false })).status, 200);
  assert.deepEqual(await configTheme(), { id: 'halloween', animated: false });

  const unknown = await post({ theme: 'pumpkin' });
  assert.equal(unknown.status, 400);
  assert.equal((await unknown.json()).error, 'invalid_theme');

  const broken = await post('{nope');
  assert.equal(broken.status, 400);
  assert.equal((await broken.json()).error, 'invalid_json');

  const reset = await post({ theme: null });
  assert.equal((await reset.json()).source, 'env');
  assert.deepEqual(await configTheme(), { id: 'casino', animated: false });
});
