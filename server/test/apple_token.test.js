const test = require('node:test');
const assert = require('node:assert/strict');
const { SignJWT, generateKeyPair, createLocalJWKSet, exportJWK } = require('jose');
const {
  verifyAppleIdentityToken,
  InvalidAppleTokenError,
  sha256Hex,
} = require('../auth/apple_token');

const AUD = 'com.hailsom.shadowhand';

async function setup() {
  const { publicKey, privateKey } = await generateKeyPair('RS256');
  const jwk = { ...(await exportJWK(publicKey)), kid: 'k1', alg: 'RS256' };
  const keySet = createLocalJWKSet({ keys: [jwk] });
  const sign = (claims, { aud = AUD, iss = 'https://appleid.apple.com' } = {}) =>
    new SignJWT(claims)
      .setProtectedHeader({ alg: 'RS256', kid: 'k1' })
      .setIssuer(iss)
      .setAudience(aud)
      .setSubject('001234.abcd.0001')
      .setIssuedAt()
      .setExpirationTime('5m')
      .sign(privateKey);
  return { keySet, sign };
}

function withAudience(fn) {
  return async () => {
    const prev = process.env.APPLE_CLIENT_IDS;
    process.env.APPLE_CLIENT_IDS = AUD;
    try {
      await fn();
    } finally {
      if (prev != null) process.env.APPLE_CLIENT_IDS = prev;
      else delete process.env.APPLE_CLIENT_IDS;
    }
  };
}

test('verifyAppleIdentityToken accepts a valid token + nonce', withAudience(async () => {
  const { keySet, sign } = await setup();
  const token = await sign({ nonce: sha256Hex('raw-nonce'), email: 'a@privaterelay.appleid.com' });
  const claims = await verifyAppleIdentityToken(token, { rawNonce: 'raw-nonce', keySet });
  assert.equal(claims.sub, '001234.abcd.0001');
  assert.equal(claims.email, 'a@privaterelay.appleid.com');
}));

test('verifyAppleIdentityToken rejects a nonce mismatch', withAudience(async () => {
  const { keySet, sign } = await setup();
  const token = await sign({ nonce: sha256Hex('raw-nonce') });
  await assert.rejects(
    verifyAppleIdentityToken(token, { rawNonce: 'other', keySet }),
    InvalidAppleTokenError,
  );
}));

test('verifyAppleIdentityToken requires a nonce', withAudience(async () => {
  const { keySet, sign } = await setup();
  const token = await sign({ nonce: sha256Hex('raw-nonce') });
  await assert.rejects(
    verifyAppleIdentityToken(token, { keySet }),
    InvalidAppleTokenError,
  );
}));

test('verifyAppleIdentityToken rejects wrong audience and issuer', withAudience(async () => {
  const { keySet, sign } = await setup();
  const nonce = sha256Hex('n');
  const wrongAud = await sign({ nonce }, { aud: 'com.other.app' });
  await assert.rejects(
    verifyAppleIdentityToken(wrongAud, { rawNonce: 'n', keySet }),
    InvalidAppleTokenError,
  );
  const wrongIss = await sign({ nonce }, { iss: 'https://accounts.google.com' });
  await assert.rejects(
    verifyAppleIdentityToken(wrongIss, { rawNonce: 'n', keySet }),
    InvalidAppleTokenError,
  );
}));
