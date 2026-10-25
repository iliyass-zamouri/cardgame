const test = require('node:test');
const assert = require('node:assert/strict');

const { POTS, potFor } = require('../pots');
const { POT_LADDERS } = require('../bot_difficulty');
const {
  DEEPLINK_ROUTES,
  normalizeDeeplink,
  describeDeeplink,
  deeplinkCatalog,
} = require('../push/deeplinks');
const { summarizePots } = require('../admin/stats');
const { GameServer } = require('../game_server');

test('the pot list matches the bot pot ladders', () => {
  for (const currency of ['money', 'chips']) {
    assert.deepEqual(
      POTS.filter((pot) => pot.currency === currency).map((pot) => pot.pool),
      POT_LADDERS[currency],
    );
  }
  assert.equal(new Set(POTS.map((pot) => pot.id)).size, POTS.length);
  assert.equal(potFor('chips', 50).id, 'tokyo');
  assert.equal(potFor('money', 50).id, 'paris');
  assert.equal(potFor('money', 999), null);
});

test('normalizeDeeplink accepts every route in canonical form', () => {
  const cases = [
    [undefined, null],
    ['', null],
    ['  ', null],
    ['/', '/'],
    ['/play', '/play'],
    ['/play/', '/play'],
    ['/play?pot=cairo', '/play?pot=cairo'],
    ['/play?pot=new_york', '/play?pot=new_york'],
    ['/robot', '/robot'],
    ['/join?roomId=ab12cd', '/join?roomId=AB12CD'],
    ['/table?roomId=AB12CD', '/join?roomId=AB12CD'],
    ['/shop', '/shop'],
    ['/shop?tab=exchange', '/shop?tab=exchange'],
    ['/ranking?tab=history', '/ranking?tab=history'],
    ['/daily', '/daily'],
    ['/notifications', '/notifications'],
    ['/tutorial', '/tutorial'],
  ];
  for (const [input, expected] of cases) {
    assert.deepEqual(normalizeDeeplink(input), { route: expected }, String(input));
  }
  for (const entry of DEEPLINK_ROUTES) {
    if (entry.path === '/join') continue;
    assert.equal(normalizeDeeplink(entry.path).route, entry.path);
  }
});

test('normalizeDeeplink rejects what the app cannot open', () => {
  const cases = [
    ['friends', /single \//],
    ['//evil.example/x', /single \//],
    ['/casino', /unknown deeplink \/casino/],
    ['/play?pot=vegas', /unknown pot vegas/],
    ['/play?city=cairo', /does not take \?city/],
    ['/shop?tab=gems', /unknown \/shop tab gems/],
    ['/ranking?tab=weekly', /unknown \/ranking tab weekly/],
    ['/join', /roomId/],
    ['/join?roomId=x', /roomId/],
    ['/friends?id=1', /does not take/],
  ];
  for (const [input, pattern] of cases) {
    const result = normalizeDeeplink(input);
    assert.match(result.error || '', pattern, input);
    assert.equal(result.route, undefined);
  }
  assert.match(normalizeDeeplink(42).error, /string/);
});

test('describeDeeplink labels routes for push history', () => {
  assert.equal(describeDeeplink(null), 'None');
  assert.equal(describeDeeplink('/play?pot=cairo'), 'Cairo pot');
  assert.equal(describeDeeplink('/play'), 'Pot picker');
  assert.equal(describeDeeplink('/shop?tab=exchange'), 'Shop · Exchange');
  assert.equal(describeDeeplink('/ranking?tab=history'), 'Ranking · Match history');
  assert.equal(describeDeeplink('/join?roomId=AB12CD'), 'Join room AB12CD');
  assert.equal(describeDeeplink('/nowhere'), 'Unknown · /nowhere');
});

test('deeplinkCatalog lists pots with their entry fee', () => {
  const catalog = deeplinkCatalog();
  assert.equal(catalog.pots.length, POTS.length);
  assert.deepEqual(catalog.pots.find((pot) => pot.id === 'marrakech'), {
    id: 'marrakech', city: 'Marrakech', currency: 'money', pool: 500, entry: 250,
  });
  assert.ok(catalog.routes.every((entry) => Array.isArray(entry.params)));
  assert.deepEqual(catalog.shopTabs.map((tab) => tab.id), ['decks', 'avatars', 'exchange']);
});

test('the catalogue lists every deeplink, and each one validates', () => {
  const { links } = deeplinkCatalog();
  const routes = links.map((link) => link.route);
  assert.equal(new Set(routes).size, routes.length);
  for (const pot of POTS) assert.ok(routes.includes(`/play?pot=${pot.id}`), pot.id);
  for (const tab of ['decks', 'avatars', 'exchange']) assert.ok(routes.includes(`/shop?tab=${tab}`));
  for (const tab of ['leaderboard', 'history']) assert.ok(routes.includes(`/ranking?tab=${tab}`));
  for (const entry of DEEPLINK_ROUTES) {
    assert.ok(routes.some((route) => route.split('?')[0] === entry.path), entry.path);
  }
  for (const link of links) {
    const route = link.route === '/join' ? '/join?roomId=AB12CD' : link.route;
    assert.equal(normalizeDeeplink(route).route, route, link.route);
  }
  assert.equal(links.length, 12 + POTS.length + 3 + 2);
});

test('summarizePots splits matches by pot, day and week', () => {
  const day = (offset) => {
    const now = new Date();
    return new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() - offset))
      .toISOString().slice(0, 10);
  };
  const { pots, potsOther, potsByDay } = summarizePots([
    { day: day(0), currency: 'money', pot: 200, matches: 3, with_bot: 1 },
    { day: day(10), currency: 'money', pot: 200, matches: 1, with_bot: 0 },
    { day: day(0), currency: 'chips', pot: 10, matches: 4, with_bot: 4 },
    { day: day(2), currency: 'money', pot: 7, matches: 2, with_bot: 0 },
  ]);
  const cairo = pots.find((pot) => pot.id === 'cairo');
  assert.deepEqual(
    { matches: cairo.matches, volume: cairo.volume, withBot: cairo.withBot, last7d: cairo.last7d, prev7d: cairo.prev7d },
    { matches: 4, volume: 800, withBot: 1, last7d: 3, prev7d: 1 },
  );
  assert.equal(pots.find((pot) => pot.id === 'new_york').share, 40);
  assert.equal(potsOther, 2);
  assert.equal(potsByDay.length, 14);
  assert.equal(potsByDay.at(-1).day, day(0));
  assert.equal(potsByDay.at(-1).cairo, 3);
  assert.equal(potsByDay.at(-1).new_york, 4);
  assert.equal(potsByDay.at(-3).other, 2);
});

test('admin push routes need the secret and bad deeplinks are refused', async (t) => {
  const previousSecret = process.env.ADMIN_PUSH_SECRET;
  process.env.ADMIN_PUSH_SECRET = 'test-admin-secret';
  t.after(() => {
    if (previousSecret === undefined) delete process.env.ADMIN_PUSH_SECRET;
    else process.env.ADMIN_PUSH_SECRET = previousSecret;
  });

  const server = new GameServer({ port: 0 });
  const address = await server.start();
  t.after(() => server.stop());
  const base = `http://127.0.0.1:${address.port}`;
  const admin = { 'x-admin-push-secret': 'test-admin-secret', 'content-type': 'application/json' };

  assert.equal((await fetch(`${base}/admin/push/routes`)).status, 401);
  assert.equal((await fetch(`${base}/admin/push/history`)).status, 401);
  const catalog = await fetch(`${base}/admin/push/routes`, { headers: admin });
  assert.equal(catalog.status, 200);
  assert.equal((await catalog.json()).pots.length, POTS.length);

  const refused = await fetch(`${base}/admin/push`, {
    method: 'POST',
    headers: admin,
    body: JSON.stringify({ title: 'Hi', body: 'Play', route: '/play?pot=vegas' }),
  });
  assert.equal(refused.status, 400);
  assert.deepEqual(await refused.json(), { error: 'invalid_route', message: 'unknown pot vegas' });
});
