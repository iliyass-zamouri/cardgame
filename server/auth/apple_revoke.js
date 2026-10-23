const { SignJWT, importPKCS8 } = require('jose');
const { getAppleClientIds } = require('./apple_token');

const APPLE_ISSUER = 'https://appleid.apple.com';
const APPLE_TOKEN_URL = 'https://appleid.apple.com/auth/token';
const APPLE_REVOKE_URL = 'https://appleid.apple.com/auth/revoke';

class AppleTokenRequestError extends Error {
  constructor(message, status = null) {
    super(message);
    this.name = 'AppleTokenRequestError';
    this.code = 'apple_token_request_failed';
    this.status = status;
  }
}

/**
 * Sign in with Apple key config from env. The .p8 key may be inline PEM with
 * literal `\n` escapes (single-line env var).
 * @returns {{ teamId: string, keyId: string, privateKey: string, clientId: string }|null}
 */
function getAppleRevocationConfig(env = process.env) {
  const teamId = (env.APPLE_TEAM_ID ?? '').trim();
  const keyId = (env.APPLE_KEY_ID ?? '').trim();
  const privateKey = (env.APPLE_PRIVATE_KEY ?? '').replace(/\\n/g, '\n').trim();
  const clientId = getAppleClientIds()[0] ?? '';
  if (!teamId || !keyId || !privateKey || !clientId) return null;
  return { teamId, keyId, privateKey, clientId };
}

/**
 * ES256 client_secret JWT for appleid.apple.com/auth/{token,revoke}.
 * Apple caps `exp` at 6 months; a short lifetime is enough per request.
 * @param {{ teamId: string, keyId: string, privateKey: string, clientId: string }} config
 * @param {{ now?: number, ttlSeconds?: number }} options `now` is unix seconds.
 */
async function buildAppleClientSecret(
  { teamId, keyId, privateKey, clientId },
  { now = Math.floor(Date.now() / 1000), ttlSeconds = 300 } = {},
) {
  const key = await importPKCS8(privateKey, 'ES256');
  return new SignJWT({})
    .setProtectedHeader({ alg: 'ES256', kid: keyId })
    .setIssuer(teamId)
    .setSubject(clientId)
    .setAudience(APPLE_ISSUER)
    .setIssuedAt(now)
    .setExpirationTime(now + ttlSeconds)
    .sign(key);
}

async function postAppleForm(url, params, fetchImpl) {
  const response = await fetchImpl(url, {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams(params).toString(),
  });
  if (!response.ok) {
    let detail = '';
    try {
      detail = await response.text();
    } catch {
      // ignore
    }
    throw new AppleTokenRequestError(
      `Apple ${url} responded ${response.status}${detail ? `: ${detail}` : ''}`,
      response.status,
    );
  }
  return response;
}

/**
 * Exchange a one-time authorizationCode for a refresh token.
 * @returns {Promise<string|null>} null when the key is not configured.
 */
async function exchangeAppleAuthorizationCode(
  authorizationCode,
  { config = getAppleRevocationConfig(), fetchImpl = fetch } = {},
) {
  if (!config) return null;
  if (typeof authorizationCode !== 'string' || !authorizationCode.trim()) {
    return null;
  }
  const clientSecret = await buildAppleClientSecret(config);
  const response = await postAppleForm(
    APPLE_TOKEN_URL,
    {
      client_id: config.clientId,
      client_secret: clientSecret,
      code: authorizationCode.trim(),
      grant_type: 'authorization_code',
    },
    fetchImpl,
  );
  const body = await response.json();
  const refreshToken =
    typeof body?.refresh_token === 'string' ? body.refresh_token : '';
  if (!refreshToken) {
    throw new AppleTokenRequestError('Apple token response had no refresh_token');
  }
  return refreshToken;
}

/**
 * Revoke a user's refresh token (account deletion, guideline 5.1.1(v)).
 * @returns {Promise<boolean>} false when the key is not configured.
 */
async function revokeAppleRefreshToken(
  refreshToken,
  { config = getAppleRevocationConfig(), fetchImpl = fetch } = {},
) {
  if (!config || !refreshToken) return false;
  const clientSecret = await buildAppleClientSecret(config);
  await postAppleForm(
    APPLE_REVOKE_URL,
    {
      client_id: config.clientId,
      client_secret: clientSecret,
      token: refreshToken,
      token_type_hint: 'refresh_token',
    },
    fetchImpl,
  );
  return true;
}

module.exports = {
  APPLE_TOKEN_URL,
  APPLE_REVOKE_URL,
  AppleTokenRequestError,
  getAppleRevocationConfig,
  buildAppleClientSecret,
  exchangeAppleAuthorizationCode,
  revokeAppleRefreshToken,
};
