const test = require('node:test');
const assert = require('node:assert/strict');
const { DEFAULTS, createMarketplaceStore } = require('../marketplace_config');
const { GameServer } = require('../game_server');

const SECRET = 'test-admin-secret';
const NOW = Date.UTC(2026, 9, 25, 12);
const HOUR = 3_600_000;

/** In-memory stand-in for the two app_settings rows. */
function memoryStore() {
  let current = null;
  let previous = null;
  return createMarketplaceStore({
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
  const server = new GameServer({ port: 0, marketplaceStore: store, clock: () => NOW });
  const address = await server.start();
  t.after(() => server.stop());
  return `http://127.0.0.1:${address.port}`;
}

const admin = { 'x-admin-push-secret': SECRET, 'content-type': 'application/json' };

function draft() {
  return JSON.parse(JSON.stringify(DEFAULTS));
}

test('shop admin endpoints refuse requests without the admin secret', async (t) => {
  const base = await startWith(memoryStore(), t);
  assert.equal((await fetch(`${base}/admin/marketplace`)).status, 401);
  assert.equal((await fetch(`${base}/admin/marketplace/stats`)).status, 401);
  for (const path of ['/admin/marketplace', '/admin/marketplace/revert']) {
    assert.equal((await fetch(`${base}${path}`, { method: 'POST', body: '{}' })).status, 401, path);
  }
});

test('the ops dashboard lists the Shop tab', async (t) => {
  const base = await startWith(memoryStore(), t);
  const page = await (await fetch(`${base}/admin`)).text();
  assert.match(page, /data-tab="shop"/);
  assert.match(page, /id="panel-shop"/);
});

test('admin saves a sale, the app catalog shows it, and revert undoes it', async (t) => {
  const base = await startWith(memoryStore(), t);

  const listed = await (await fetch(`${base}/admin/marketplace`, { headers: admin })).json();
  assert.equal(listed.source, 'default');
  assert.equal(listed.hasPrevious, false);
  assert.equal(listed.serverTimeMs, NOW);
  assert.equal(listed.known.avatars.length, DEFAULTS.avatars.length);

  const edited = draft();
  edited.decks.find((deck) => deck.id === 'gilded_gold').sale = {
    price: 25,
    startsAt: NOW - HOUR,
    endsAt: NOW + HOUR,
  };
  const saved = await fetch(`${base}/admin/marketplace`, {
    method: 'POST',
    headers: admin,
    body: JSON.stringify(edited),
  });
  assert.equal(saved.status, 200);
  assert.equal((await saved.json()).source, 'admin');

  const catalog = await (await fetch(`${base}/marketplace/catalog`)).json();
  const gilded = catalog.decks.find((deck) => deck.id === 'gilded_gold');
  assert.equal(gilded.price, 25);
  assert.deepEqual(gilded.sale, { price: 25, endsAtMs: NOW + HOUR });
  assert.equal(catalog.economy.moneyPerChip, 1000);

  const reverted = await fetch(`${base}/admin/marketplace/revert`, { method: 'POST', headers: admin });
  assert.equal(reverted.status, 409, 'the first save has no earlier version');

  const again = draft();
  again.economy.moneyPerChip = 900;
  await fetch(`${base}/admin/marketplace`, { method: 'POST', headers: admin, body: JSON.stringify(again) });
  const restored = await fetch(`${base}/admin/marketplace/revert`, { method: 'POST', headers: admin });
  assert.equal(restored.status, 200);
  assert.equal((await restored.json()).config.economy.moneyPerChip, 1000);
});

test('an invalid save is refused with a message for the admin', async (t) => {
  const base = await startWith(memoryStore(), t);
  const edited = draft();
  edited.avatars[1].price = 'free';
  const response = await fetch(`${base}/admin/marketplace`, {
    method: 'POST',
    headers: admin,
    body: JSON.stringify(edited),
  });
  assert.equal(response.status, 400);
  const body = await response.json();
  assert.equal(body.error, 'invalid_value');
  assert.match(body.message, /Avatar blue\.price/);
});

test('the public catalog needs no sign-in', async (t) => {
  const base = await startWith(memoryStore(), t);
  const response = await fetch(`${base}/marketplace/catalog`);
  assert.equal(response.status, 200);
  const body = await response.json();
  assert.equal(body.serverTimeMs, NOW);
  assert.equal(body.avatars[0].id, 'default');
  assert.equal(body.banner, null);
});
