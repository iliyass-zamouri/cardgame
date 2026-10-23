const test = require('node:test');
const assert = require('node:assert/strict');
const { generateKeyPair, exportPKCS8, jwtVerify, decodeProtectedHeader } = require('jose');
const {
  APPLE_TOKEN_URL,
  APPLE_REVOKE_URL,
  AppleTokenRequestError,
  getAppleRevocationConfig,
  buildAppleClientSecret,
  exchangeAppleAuthorizationCode,
  revokeAppleRefreshToken,
} = require('../auth/apple_revoke');

const CLIENT_ID = 'com.hailsom.shadowhand';

async function setup() {
  const { publicKey, privateKey } = await generateKeyPair('ES256', {
    extractable: true,
  });
  const config = {
    teamId: 'TEAM123456',
    keyId: 'KEY1234567',
    privateKey: await exportPKCS8(privateKey),
    clientId: CLIENT_ID,
  };
  return { publicKey, config };
}

function mockFetch(responder) {
  const calls = [];
  const fetchImpl = async (url, init) => {
    calls.push({ url, init, form: new URLSearchParams(init.body) });
    return responder(url, init);
  };
  return { calls, fetchImpl };
}

function jsonResponse(status, body) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json' },
  });
}

test('buildAppleClientSecret signs an ES256 JWT with Apple claims', async () => {
  const { publicKey, config } = await setup();
  const now = Math.floor(Date.now() / 1000);
  const jwt = await buildAppleClientSecret(config, { now, ttlSeconds: 600 });

  const header = decodeProtectedHeader(jwt);
  assert.equal(header.alg, 'ES256');
  assert.equal(header.kid, config.keyId);

  const { payload } = await jwtVerify(jwt, publicKey, {
    issuer: config.teamId,
    audience: 'https://appleid.apple.com',
    subject: CLIENT_ID,
  });
  assert.equal(payload.iat, now);
  assert.equal(payload.exp, now + 600);
});

test('getAppleRevocationConfig unescapes \\n and needs every value', () => {
  const prev = process.env.APPLE_CLIENT_IDS;
  process.env.APPLE_CLIENT_IDS = `${CLIENT_ID},other.service.id`;
  try {
    const config = getAppleRevocationConfig({
      APPLE_TEAM_ID: ' TEAM ',
      APPLE_KEY_ID: 'KEY',
      APPLE_PRIVATE_KEY: '-----BEGIN PRIVATE KEY-----\\nabc\\n-----END PRIVATE KEY-----',
    });
    assert.deepEqual(config, {
      teamId: 'TEAM',
      keyId: 'KEY',
      privateKey: '-----BEGIN PRIVATE KEY-----\nabc\n-----END PRIVATE KEY-----',
      clientId: CLIENT_ID,
    });
    assert.equal(
      getAppleRevocationConfig({ APPLE_TEAM_ID: 'TEAM', APPLE_KEY_ID: 'KEY' }),
      null,
    );
  } finally {
    if (prev != null) process.env.APPLE_CLIENT_IDS = prev;
    else delete process.env.APPLE_CLIENT_IDS;
  }
});

test('exchangeAppleAuthorizationCode posts the code and returns refresh_token', async () => {
  const { publicKey, config } = await setup();
  const { calls, fetchImpl } = mockFetch(() =>
    jsonResponse(200, { refresh_token: 'r.abc', access_token: 'a', id_token: 'i' }),
  );

  const token = await exchangeAppleAuthorizationCode(' code-1 ', { config, fetchImpl });

  assert.equal(token, 'r.abc');
  assert.equal(calls.length, 1);
  assert.equal(calls[0].url, APPLE_TOKEN_URL);
  assert.equal(calls[0].form.get('grant_type'), 'authorization_code');
  assert.equal(calls[0].form.get('code'), 'code-1');
  assert.equal(calls[0].form.get('client_id'), CLIENT_ID);
  await jwtVerify(calls[0].form.get('client_secret'), publicKey, {
    issuer: config.teamId,
  });
});

test('exchangeAppleAuthorizationCode throws on Apple error responses', async () => {
  const { config } = await setup();
  const { fetchImpl } = mockFetch(() => jsonResponse(400, { error: 'invalid_grant' }));
  await assert.rejects(
    exchangeAppleAuthorizationCode('code', { config, fetchImpl }),
    (error) => error instanceof AppleTokenRequestError && error.status === 400,
  );
});

test('exchange and revoke are no-ops without config or input', async () => {
  const { config } = await setup();
  const { calls, fetchImpl } = mockFetch(() => jsonResponse(200, {}));
  assert.equal(await exchangeAppleAuthorizationCode('code', { config: null, fetchImpl }), null);
  assert.equal(await exchangeAppleAuthorizationCode('', { config, fetchImpl }), null);
  assert.equal(await revokeAppleRefreshToken('r', { config: null, fetchImpl }), false);
  assert.equal(await revokeAppleRefreshToken(null, { config, fetchImpl }), false);
  assert.equal(calls.length, 0);
});

test('revokeAppleRefreshToken posts the refresh token to /auth/revoke', async () => {
  const { config } = await setup();
  const { calls, fetchImpl } = mockFetch(() => new Response('', { status: 200 }));

  assert.equal(await revokeAppleRefreshToken('r.abc', { config, fetchImpl }), true);
  assert.equal(calls[0].url, APPLE_REVOKE_URL);
  assert.equal(calls[0].form.get('token'), 'r.abc');
  assert.equal(calls[0].form.get('token_type_hint'), 'refresh_token');
  assert.equal(calls[0].form.get('client_id'), CLIENT_ID);
  assert.ok(calls[0].form.get('client_secret'));
});

test('revokeAppleRefreshToken throws on non-2xx', async () => {
  const { config } = await setup();
  const { fetchImpl } = mockFetch(() => new Response('bad', { status: 400 }));
  await assert.rejects(
    revokeAppleRefreshToken('r.abc', { config, fetchImpl }),
    AppleTokenRequestError,
  );
});
