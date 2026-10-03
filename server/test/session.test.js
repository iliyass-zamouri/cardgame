const test = require('node:test');
const assert = require('node:assert/strict');
const {
  signSession,
  verifySession,
  InvalidSessionError,
  assertSessionSecret,
  DEV_SECRET,
} = require('../auth/session');
const {
  resolveCatalogPrice,
  AD_DAILY_CAP,
  AD_COOLDOWN_MS,
  AD_REWARD_DAILY_CAP,
  AD_REWARD_COOLDOWN_MS,
  AVATAR_CATALOG,
} = require('../db/marketplace');

test('assertSessionSecret defaults in non-production', () => {
  const prev = process.env.SESSION_SECRET;
  const prevEnv = process.env.NODE_ENV;
  delete process.env.SESSION_SECRET;
  process.env.NODE_ENV = 'test';
  const secret = assertSessionSecret();
  assert.equal(Buffer.from(secret).toString('utf8'), DEV_SECRET);
  if (prev != null) process.env.SESSION_SECRET = prev;
  else delete process.env.SESSION_SECRET;
  if (prevEnv != null) process.env.NODE_ENV = prevEnv;
  else delete process.env.NODE_ENV;
});

test('signSession and verifySession round-trip', async () => {
  const token = await signSession({ playerId: 'guest-abc', tokenVersion: 3 });
  assert.equal(typeof token, 'string');
  assert.ok(token.length > 20);
  const session = await verifySession(token);
  assert.equal(session.playerId, 'guest-abc');
  assert.equal(session.tokenVersion, 3);
});

test('verifySession rejects empty token', async () => {
  await assert.rejects(
    () => verifySession(''),
    (err) => err instanceof InvalidSessionError && err.code === 'auth_required',
  );
});

test('verifySession rejects garbage token', async () => {
  await assert.rejects(
    () => verifySession('not.a.jwt'),
    (err) => err instanceof InvalidSessionError && err.code === 'invalid_token',
  );
});

test('resolveCatalogPrice uses avatar catalog ignoring client price', () => {
  const blue = resolveCatalogPrice('avatar', 'blue');
  assert.equal(blue.price, 200);
  assert.equal(blue.currency, 'money');
  const gold = resolveCatalogPrice('avatar', 'golden-king');
  assert.equal(gold.price, 5);
  assert.equal(gold.currency, 'chips');
  assert.throws(
    () => resolveCatalogPrice('avatar', 'nope'),
    (err) => err.code === 'invalid_item_id',
  );
});

test('ad reward cap constants', () => {
  assert.equal(AD_DAILY_CAP, 5);
  assert.equal(AD_COOLDOWN_MS, 60_000);
  assert.equal(AD_REWARD_DAILY_CAP, 5);
  assert.equal(AD_REWARD_COOLDOWN_MS, 60_000);
  assert.ok(AVATAR_CATALOG.length >= 10);
});
