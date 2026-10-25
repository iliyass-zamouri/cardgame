const test = require('node:test');
const assert = require('node:assert/strict');
const {
  signSession,
  verifySession,
  InvalidSessionError,
  assertSessionSecret,
  DEV_SECRET,
} = require('../auth/session');
const { quotePurchase } = require('../db/marketplace');
const { DEFAULTS } = require('../marketplace_config');

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

test('quotePurchase uses the avatar catalog, ignoring the client price', () => {
  const quote = (itemId) => quotePurchase(DEFAULTS, { itemType: 'avatar', itemId }, Date.now());
  const blue = quote('blue');
  assert.equal(blue.price, 200);
  assert.equal(blue.currency, 'money');
  const gold = quote('golden-king');
  assert.equal(gold.price, 5);
  assert.equal(gold.currency, 'chips');
  assert.throws(
    () => quote('nope'),
    (err) => err.code === 'invalid_item_id',
  );
});

test('ad reward cap defaults', () => {
  assert.equal(DEFAULTS.ads.dailyCap, 5);
  assert.equal(DEFAULTS.ads.cooldownSeconds, 60);
});
