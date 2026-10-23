const test = require('node:test');
const assert = require('node:assert/strict');
const WebSocket = require('ws');
const {
  DEFAULTS,
  BOUNDS,
  normalizeConfig,
  parseTurnTimerPatch,
  createTurnTimerStore,
} = require('../turn_timer');
const { GameServer } = require('../game_server');
const { testToken } = require('./session_helpers');

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

test('normalizeConfig keeps valid stored fields and defaults the rest', () => {
  assert.deepEqual(normalizeConfig(null), DEFAULTS);
  assert.deepEqual(
    normalizeConfig({ enabled: false, turnSeconds: 45, maxMissedTurns: 'x', revealSeconds: 999 }),
    {
      enabled: false,
      turnSeconds: 45,
      maxMissedTurns: DEFAULTS.maxMissedTurns,
      revealSeconds: DEFAULTS.revealSeconds,
    },
  );
});

test('parseTurnTimerPatch accepts any non-empty subset of valid settings', () => {
  assert.deepEqual(parseTurnTimerPatch({ turnSeconds: 45 }), { patch: { turnSeconds: 45 } });
  assert.deepEqual(parseTurnTimerPatch({ enabled: false, maxMissedTurns: 0 }), {
    patch: { enabled: false, maxMissedTurns: 0 },
  });
  // Bounds are inclusive.
  assert.deepEqual(parseTurnTimerPatch({ turnSeconds: BOUNDS.turnSeconds[0] }), {
    patch: { turnSeconds: 10 },
  });
  assert.deepEqual(parseTurnTimerPatch({ revealSeconds: BOUNDS.revealSeconds[1] }), {
    patch: { revealSeconds: 60 },
  });
});

test('parseTurnTimerPatch rejects bad values and unknown keys', () => {
  assert.equal(parseTurnTimerPatch({ turnSeconds: 9 }).error, 'invalid_value');
  assert.equal(parseTurnTimerPatch({ turnSeconds: 121 }).error, 'invalid_value');
  assert.equal(parseTurnTimerPatch({ turnSeconds: 30.5 }).error, 'invalid_value');
  assert.equal(parseTurnTimerPatch({ turnSeconds: '30' }).error, 'invalid_value');
  assert.equal(parseTurnTimerPatch({ maxMissedTurns: -1 }).error, 'invalid_value');
  assert.equal(parseTurnTimerPatch({ enabled: 'yes' }).error, 'invalid_value');
  assert.equal(parseTurnTimerPatch({ turnSeconds: 30, tempo: 'fast' }).error, 'invalid_body');
  assert.equal(parseTurnTimerPatch({}).error, 'invalid_body');
  assert.equal(parseTurnTimerPatch([]).error, 'invalid_body');
  assert.equal(parseTurnTimerPatch(null).error, 'invalid_body');
});

test('current() serves code defaults until something is stored', async () => {
  const store = createTurnTimerStore({ ...memoryRow(), now: () => 0 });
  await store.refresh();
  assert.deepEqual(store.current(), { ...DEFAULTS, source: 'default' });
});

test('a stored record overrides the defaults field by field', async () => {
  const store = createTurnTimerStore({
    ...memoryRow({ turnSeconds: 45, enabled: false }),
    now: () => 0,
  });
  await store.refresh();
  assert.deepEqual(store.current(), {
    enabled: false,
    turnSeconds: 45,
    maxMissedTurns: DEFAULTS.maxMissedTurns,
    revealSeconds: DEFAULTS.revealSeconds,
    source: 'admin',
  });
});

test('current() is synchronous and refreshes in the background once stale', async () => {
  let reads = 0;
  let clock = 0;
  const store = createTurnTimerStore({
    read: async () => {
      reads += 1;
      return { turnSeconds: 40 };
    },
    write: async () => {},
    cacheMs: 1000,
    now: () => clock,
  });
  assert.equal(store.current().turnSeconds, DEFAULTS.turnSeconds);
  await store.refresh();
  assert.equal(store.current().turnSeconds, 40);
  assert.equal(reads, 1);
  clock = 1000;
  store.current();
  await store.refresh();
  assert.equal(reads, 2);
});

test('a failing read keeps the last good value and reports the error', async () => {
  const errors = [];
  let failing = false;
  const store = createTurnTimerStore({
    read: async () => {
      if (failing) throw new Error('db down');
      return { revealSeconds: 20 };
    },
    write: async () => {},
    now: () => 0,
    onReadError: (error) => errors.push(error),
  });
  await store.refresh();
  assert.equal(store.current().revealSeconds, 20);
  failing = true;
  await store.refresh();
  assert.equal(store.current().revealSeconds, 20);
  assert.equal(errors.length, 1);
});

test('set() merges into the stored settings, writes through and updates the cache', async () => {
  const row = memoryRow({ turnSeconds: 45, enabled: true });
  const store = createTurnTimerStore({ ...row, now: () => 0 });
  const saved = await store.set({ maxMissedTurns: 0 });
  assert.deepEqual(saved, {
    enabled: true,
    turnSeconds: 45,
    maxMissedTurns: 0,
    revealSeconds: DEFAULTS.revealSeconds,
    source: 'admin',
  });
  assert.deepEqual(row.peek(), {
    enabled: true,
    turnSeconds: 45,
    maxMissedTurns: 0,
    revealSeconds: DEFAULTS.revealSeconds,
  });
  assert.equal(store.current().maxMissedTurns, 0);
});

test('set() refuses to write when the stored settings cannot be read', async () => {
  const store = createTurnTimerStore({ ...unreachableRow(), now: () => 0 });
  await assert.rejects(store.set({ enabled: false }), /db down/);
});

test('admin routes read and change the live turn limit', async (t) => {
  const previousSecret = process.env.ADMIN_PUSH_SECRET;
  process.env.ADMIN_PUSH_SECRET = 'test-admin-secret';
  t.after(() => {
    if (previousSecret === undefined) delete process.env.ADMIN_PUSH_SECRET;
    else process.env.ADMIN_PUSH_SECRET = previousSecret;
  });

  const row = memoryRow();
  const turnTimerStore = createTurnTimerStore({ ...row, cacheMs: 0 });
  const server = new GameServer({ port: 0, turnTimerStore });
  const address = await server.start();
  t.after(() => server.stop());

  const base = `http://127.0.0.1:${address.port}`;
  const admin = {
    'x-admin-push-secret': 'test-admin-secret',
    'content-type': 'application/json',
  };
  const post = (body) =>
    fetch(`${base}/admin/turn-timer`, {
      method: 'POST',
      headers: admin,
      body: typeof body === 'string' ? body : JSON.stringify(body),
    });

  assert.equal((await fetch(`${base}/admin/turn-timer`)).status, 401);

  const listed = await (await fetch(`${base}/admin/turn-timer`, { headers: admin })).json();
  assert.equal(listed.turnSeconds, DEFAULTS.turnSeconds);
  assert.equal(listed.source, 'default');
  assert.deepEqual(listed.defaults, DEFAULTS);
  assert.deepEqual(listed.bounds, BOUNDS);

  const saved = await post({ turnSeconds: 45, maxMissedTurns: 0 });
  assert.equal(saved.status, 200);
  assert.equal((await saved.json()).turnSeconds, 45);

  const reread = await (await fetch(`${base}/admin/turn-timer`, { headers: admin })).json();
  assert.equal(reread.turnSeconds, 45);
  assert.equal(reread.maxMissedTurns, 0);
  assert.equal(reread.source, 'admin');

  const tooFast = await post({ turnSeconds: 5 });
  assert.equal(tooFast.status, 400);
  assert.equal((await tooFast.json()).error, 'invalid_value');

  const broken = await post('{nope');
  assert.equal(broken.status, 400);
  assert.equal((await broken.json()).error, 'invalid_json');
});

test('a failed save answers 500 and reports the failure', async (t) => {
  const previousSecret = process.env.ADMIN_PUSH_SECRET;
  process.env.ADMIN_PUSH_SECRET = 'test-admin-secret';
  t.after(() => {
    if (previousSecret === undefined) delete process.env.ADMIN_PUSH_SECRET;
    else process.env.ADMIN_PUSH_SECRET = previousSecret;
  });

  const turnTimerStore = createTurnTimerStore({
    read: async () => null,
    write: async () => {
      throw new Error('disk full');
    },
    cacheMs: 0,
    onReadError: () => {},
  });
  const server = new GameServer({ port: 0, turnTimerStore });
  const address = await server.start();
  t.after(() => server.stop());

  const failed = await fetch(`http://127.0.0.1:${address.port}/admin/turn-timer`, {
    method: 'POST',
    headers: {
      'x-admin-push-secret': 'test-admin-secret',
      'content-type': 'application/json',
    },
    body: JSON.stringify({ enabled: false }),
  });
  assert.equal(failed.status, 500);
  assert.equal((await failed.json()).error, 'server_error');
});

test('a room created over the socket reads the live turn limit', async (t) => {
  const row = memoryRow();
  const turnTimerStore = createTurnTimerStore({ ...row, now: Date.now, cacheMs: 60_000 });
  const server = new GameServer({ port: 0, turnTimerStore });
  const address = await server.start();
  t.after(() => server.stop());

  const socket = await connect(address.port);
  t.after(() => socket.close());
  const created = waitFor(socket, (message) => message.type === 'snapshot');
  socket.send(JSON.stringify({ type: 'createRoom', token: await testToken('host-live') }));
  const { roomId } = await created;
  const room = server.rooms.get(roomId);

  assert.deepEqual(room.turnTimerConfig(), {
    turnMs: DEFAULTS.turnSeconds * 1000,
    revealMs: DEFAULTS.revealSeconds * 1000,
    maxMissedTurns: DEFAULTS.maxMissedTurns,
  });

  // A change made after the room exists reaches it without a restart.
  await turnTimerStore.set({ turnSeconds: 45 });
  assert.equal(room.turnTimerConfig().turnMs, 45_000);

  await turnTimerStore.set({ enabled: false });
  assert.equal(room.turnTimerConfig(), null);
});

function connect(port) {
  return new Promise((resolve, reject) => {
    const socket = new WebSocket(`ws://127.0.0.1:${port}`);
    socket.once('open', () => resolve(socket));
    socket.once('error', reject);
  });
}

function waitFor(socket, predicate, timeout = 2000) {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => {
      socket.off('message', onMessage);
      reject(new Error('Timed out waiting for server message'));
    }, timeout);
    function onMessage(raw) {
      const message = JSON.parse(raw.toString());
      if (!predicate(message)) return;
      clearTimeout(timer);
      socket.off('message', onMessage);
      resolve(message);
    }
    socket.on('message', onMessage);
  });
}
