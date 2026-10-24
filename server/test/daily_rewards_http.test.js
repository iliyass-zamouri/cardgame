const test = require('node:test');
const assert = require('node:assert/strict');
const { DEFAULTS, createDailyRewardsStore } = require('../daily_rewards');
const { GameServer } = require('../game_server');

const SECRET = 'test-admin-secret';

/** In-memory stand-in for the two app_settings rows. */
function memoryStore() {
  let current = null;
  let previous = null;
  return createDailyRewardsStore({
    read: async () => current,
    write: async (config) => {
      current = config;
    },
    readPrevious: async () => previous,
    writePrevious: async (config) => {
      previous = config;
    },
  });
}

async function startWith(store, t) {
  const previousSecret = process.env.ADMIN_PUSH_SECRET;
  process.env.ADMIN_PUSH_SECRET = SECRET;
  t.after(() => {
    if (previousSecret === undefined) delete process.env.ADMIN_PUSH_SECRET;
    else process.env.ADMIN_PUSH_SECRET = previousSecret;
  });
  const server = new GameServer({ port: 0, dailyRewardsStore: store });
  const address = await server.start();
  t.after(() => server.stop());
  return `http://127.0.0.1:${address.port}`;
}

const admin = { 'x-admin-push-secret': SECRET, 'content-type': 'application/json' };

test('admin endpoints refuse requests without the admin secret', async (t) => {
  const base = await startWith(memoryStore(), t);
  assert.equal((await fetch(`${base}/admin/daily-rewards`)).status, 401);
  assert.equal((await fetch(`${base}/admin/reward-catalog`)).status, 401);
  assert.equal((await fetch(`${base}/admin/daily-rewards/stats`)).status, 401);
  assert.equal((await fetch(`${base}/admin/daily-rewards/player?id=p1`)).status, 401);
  for (const path of ['/admin/daily-rewards', '/admin/daily-rewards/player/action']) {
    assert.equal((await fetch(`${base}${path}`, { method: 'POST', body: '{}' })).status, 401, path);
  }
});

test('support actions are checked before the database is touched', async (t) => {
  const previousDebug = process.env.DAILY_REWARDS_DEBUG;
  delete process.env.DAILY_REWARDS_DEBUG;
  t.after(() => {
    if (previousDebug !== undefined) process.env.DAILY_REWARDS_DEBUG = previousDebug;
  });
  const base = await startWith(memoryStore(), t);
  const act = (body) =>
    fetch(`${base}/admin/daily-rewards/player/action`, {
      method: 'POST',
      headers: admin,
      body: JSON.stringify(body),
    });

  const unknown = await act({ playerId: 'p1', action: 'nuke' });
  assert.equal(unknown.status, 400);
  assert.equal((await unknown.json()).error, 'invalid_action');

  const qaOnly = await act({ playerId: 'p1', action: 'shift_days', days: 1 });
  assert.equal(qaOnly.status, 403, 'time travel stays off unless DAILY_REWARDS_DEBUG=1');
  assert.equal((await qaOnly.json()).error, 'debug_only');

  const noId = await fetch(`${base}/admin/daily-rewards/player`, { headers: admin });
  assert.equal(noId.status, 400);
});

test('the ops dashboard lists the Daily rewards tab', async (t) => {
  const base = await startWith(memoryStore(), t);
  const page = await (await fetch(`${base}/admin`)).text();
  assert.match(page, /data-tab="daily"/);
  assert.match(page, /id="panel-daily"/);
});

test('admin reads the live table and saves a whole edited copy', async (t) => {
  const base = await startWith(memoryStore(), t);

  const listed = await (await fetch(`${base}/admin/daily-rewards`, { headers: admin })).json();
  assert.equal(listed.source, 'default');
  assert.equal(listed.hasPrevious, false);
  assert.equal(listed.config.graceDays, DEFAULTS.graceDays);
  assert.equal(listed.config.calendar.days.length, 7);
  assert.deepEqual(listed.defaults, structuredClone(DEFAULTS), 'the tab can load defaults into the editor');

  const edited = { ...structuredClone(listed.config), graceDays: 2 };
  const saved = await fetch(`${base}/admin/daily-rewards`, {
    method: 'POST',
    headers: admin,
    body: JSON.stringify(edited),
  });
  assert.equal(saved.status, 200);
  const savedBody = await saved.json();
  assert.equal(savedBody.config.graceDays, 2);
  assert.equal(savedBody.source, 'admin');
  assert.equal(savedBody.hasPrevious, false, 'the first save has nothing before it');

  const second = await fetch(`${base}/admin/daily-rewards`, {
    method: 'POST',
    headers: admin,
    body: JSON.stringify({ ...edited, graceDays: 3 }),
  });
  assert.equal((await second.json()).hasPrevious, true);

  const reverted = await fetch(`${base}/admin/daily-rewards/revert`, {
    method: 'POST',
    headers: admin,
  });
  assert.equal(reverted.status, 200);
  assert.equal((await reverted.json()).config.graceDays, 2);
});

test('admin save refuses bad input with a clear message and keeps the old table', async (t) => {
  const base = await startWith(memoryStore(), t);
  const bad = structuredClone(DEFAULTS);
  bad.calendar.days[0].rewards = [{ type: 'avatar', itemId: 'ghost', fallback: { type: 'money', amount: 1 } }];

  const response = await fetch(`${base}/admin/daily-rewards`, {
    method: 'POST',
    headers: admin,
    body: JSON.stringify(bad),
  });
  assert.equal(response.status, 400);
  const body = await response.json();
  assert.equal(body.error, 'invalid_value');
  assert.match(body.message, /"ghost" is not a known avatar/);

  const listed = await (await fetch(`${base}/admin/daily-rewards`, { headers: admin })).json();
  assert.equal(listed.source, 'default', 'a refused save changes nothing');
});

test('revert with nothing to restore answers 409', async (t) => {
  const base = await startWith(memoryStore(), t);
  const response = await fetch(`${base}/admin/daily-rewards/revert`, { method: 'POST', headers: admin });
  assert.equal(response.status, 409);
  assert.equal((await response.json()).error, 'no_previous');
});

test('the reward catalog lists what the admin can pick', async (t) => {
  const base = await startWith(memoryStore(), t);
  const catalog = await (await fetch(`${base}/admin/reward-catalog`, { headers: admin })).json();
  assert.deepEqual(catalog.currencies, ['money', 'chips']);
  assert.ok(catalog.avatars.some((avatar) => avatar.id === 'blue'));
  assert.ok(catalog.decks.some((deck) => deck.id === 'neon_nights'));
  assert.deepEqual(catalog.boosters, ['coin_boost', 'streak_freeze']);
  // The economy estimate's yardsticks.
  assert.equal(catalog.moneyPerChip, 1000);
  assert.equal(catalog.startingMoney, 500);
  assert.equal(catalog.adDailyCap, 5);
  assert.equal(typeof catalog.adRewardMoney, 'number');
});

test('player endpoints require a bearer token before touching the database', async (t) => {
  const base = await startWith(memoryStore(), t);
  const status = await fetch(`${base}/daily-reward?tzOffset=60`);
  assert.equal(status.status, 401);
  assert.equal((await status.json()).error, 'auth_required');

  const claim = await fetch(`${base}/daily-reward/claim`, { method: 'POST', body: '{}' });
  assert.equal(claim.status, 401);

  const comeback = await fetch(`${base}/daily-reward/comeback/claim`, { method: 'POST', body: '{}' });
  assert.equal(comeback.status, 401);
});
