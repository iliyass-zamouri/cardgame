const test = require('node:test');
const assert = require('node:assert/strict');
const { DEFAULTS, createAppReviewStore } = require('../app_review_config');
const { GameServer } = require('../game_server');
const { testToken } = require('./session_helpers');

const SECRET = 'test-admin-secret';
const NOW = Date.UTC(2026, 9, 25, 12);

/** In-memory stand-in for the two app_settings rows. */
function memoryStore() {
  let current = null;
  let previous = null;
  return createAppReviewStore({
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
  const server = new GameServer({ port: 0, appReviewStore: store, clock: () => NOW });
  const address = await server.start();
  t.after(() => server.stop());
  return `http://127.0.0.1:${address.port}`;
}

const admin = { 'x-admin-push-secret': SECRET, 'content-type': 'application/json' };

async function player(id = 'p-review') {
  return { authorization: `Bearer ${await testToken(id)}`, 'content-type': 'application/json' };
}

function draft() {
  return JSON.parse(JSON.stringify(DEFAULTS));
}

test('rating admin endpoints refuse requests without the admin secret', async (t) => {
  const base = await startWith(memoryStore(), t);
  for (const path of ['/admin/app-review', '/admin/app-review/stats', '/admin/app-review/list', '/admin/app-review/export.csv']) {
    assert.equal((await fetch(`${base}${path}`)).status, 401, path);
  }
  for (const path of ['/admin/app-review', '/admin/app-review/revert', '/admin/app-review/7/handled']) {
    assert.equal((await fetch(`${base}${path}`, { method: 'POST', body: '{}' })).status, 401, path);
  }
});

test('the ops dashboard lists the Ratings tab', async (t) => {
  const base = await startWith(memoryStore(), t);
  const page = await (await fetch(`${base}/admin`)).text();
  assert.match(page, /data-tab="ratings"/);
  assert.match(page, /id="panel-ratings"/);
});

test('admin saves the rating config, the app sees it, and revert undoes it', async (t) => {
  const base = await startWith(memoryStore(), t);

  const listed = await (await fetch(`${base}/admin/app-review`, { headers: admin })).json();
  assert.equal(listed.source, 'default');
  assert.equal(listed.hasPrevious, false);
  assert.deepEqual(listed.config, draft());
  assert.ok(listed.limits.storeMinStars);
  assert.ok(listed.tags.includes('bugs'));

  const edited = draft();
  edited.storeMinStars = 5;
  edited.flow.ios = 'native_only';
  edited.iosAppStoreId = '6450000000';
  const saved = await fetch(`${base}/admin/app-review`, {
    method: 'POST',
    headers: admin,
    body: JSON.stringify(edited),
  });
  assert.equal(saved.status, 200);
  assert.equal((await saved.json()).config.storeMinStars, 5);

  const status = await fetch(`${base}/app-review/status?trigger=win&platform=ios&locale=fr`, {
    headers: await player(),
  });
  assert.equal(status.status, 200);
  const body = await status.json();
  // No database in this test: the app gets the config but no prompt.
  assert.equal(body.show, false);
  assert.equal(body.config.flow, 'native_only');
  assert.equal(body.config.storeMinStars, 5);
  assert.equal(body.config.iosAppStoreId, '6450000000');

  const next = draft();
  next.storeMinStars = 3;
  await fetch(`${base}/admin/app-review`, { method: 'POST', headers: admin, body: JSON.stringify(next) });

  const reverted = await fetch(`${base}/admin/app-review/revert`, { method: 'POST', headers: admin });
  assert.equal(reverted.status, 200);
  assert.equal((await reverted.json()).config.storeMinStars, 5);
});

test('admin save rejects an invalid config and keeps the old one', async (t) => {
  const base = await startWith(memoryStore(), t);
  const edited = draft();
  edited.storeMinStars = 9;
  const response = await fetch(`${base}/admin/app-review`, {
    method: 'POST',
    headers: admin,
    body: JSON.stringify(edited),
  });
  assert.equal(response.status, 400);
  const body = await response.json();
  assert.equal(body.error, 'invalid_value');
  assert.match(body.message, /storeMinStars/);
  const listed = await (await fetch(`${base}/admin/app-review`, { headers: admin })).json();
  assert.equal(listed.config.storeMinStars, DEFAULTS.storeMinStars);
});

test('revert with nothing saved before answers 409', async (t) => {
  const base = await startWith(memoryStore(), t);
  const response = await fetch(`${base}/admin/app-review/revert`, { method: 'POST', headers: admin });
  assert.equal(response.status, 409);
  assert.equal((await response.json()).error, 'no_previous');
});

test('player rating endpoints need a session', async (t) => {
  const base = await startWith(memoryStore(), t);
  assert.equal((await fetch(`${base}/app-review/status?trigger=win`)).status, 401);
  for (const path of ['/app-review/rate', '/app-review/shown', '/app-review/dismiss', '/app-review/3/feedback']) {
    const response = await fetch(`${base}${path}`, { method: 'POST', body: '{}' });
    assert.equal(response.status, 401, path);
  }
});

test('player rating endpoints validate input before touching the database', async (t) => {
  const base = await startWith(memoryStore(), t);
  const headers = await player();

  const noTrigger = await fetch(`${base}/app-review/status?trigger=nope`, { headers });
  assert.equal(noTrigger.status, 400);

  const badStars = await fetch(`${base}/app-review/rate`, {
    method: 'POST',
    headers,
    body: JSON.stringify({ stars: 9, trigger: 'win' }),
  });
  assert.equal(badStars.status, 400);
  assert.match((await badStars.json()).message, /stars/);

  const emptyFeedback = await fetch(`${base}/app-review/3/feedback`, {
    method: 'POST',
    headers,
    body: JSON.stringify({ tags: [], comment: ' ' }),
  });
  assert.equal(emptyFeedback.status, 400);

  const shownNoTrigger = await fetch(`${base}/app-review/shown`, {
    method: 'POST',
    headers,
    body: '{}',
  });
  assert.equal(shownNoTrigger.status, 400);

  // A valid rating with no database is refused rather than lost silently.
  const valid = await fetch(`${base}/app-review/rate`, {
    method: 'POST',
    headers,
    body: JSON.stringify({ stars: 4, trigger: 'win', platform: 'android' }),
  });
  assert.equal(valid.status, 503);
});
