const { createHash } = require('crypto');
const { createRemoteJWKSet, jwtVerify } = require('jose');

const APPLE_ISSUER = 'https://appleid.apple.com';

const appleJwks = createRemoteJWKSet(
  new URL('https://appleid.apple.com/auth/keys'),
);

class InvalidAppleTokenError extends Error {
  constructor(message = 'Invalid Apple identity token') {
    super(message);
    this.name = 'InvalidAppleTokenError';
    this.code = 'invalid_apple_token';
  }
}

/** Bundle ids (native) and Service ids (web/Android) accepted as `aud`. */
function getAppleClientIds() {
  const raw = process.env.APPLE_CLIENT_IDS ?? '';
  return raw
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean);
}

function sha256Hex(value) {
  return createHash('sha256').update(value, 'utf8').digest('hex');
}

/**
 * Verify a Sign in with Apple identity token.
 * The client sends Apple sha256(rawNonce) and the server the raw nonce, so a
 * stolen token cannot be replayed without the nonce.
 * @param {string} identityToken
 * @param {{ rawNonce: string, keySet?: Function }} options `keySet` is for tests.
 * @returns {Promise<{ sub: string, email?: string }>}
 */
async function verifyAppleIdentityToken(
  identityToken,
  { rawNonce = null, keySet = appleJwks } = {},
) {
  if (typeof identityToken !== 'string' || !identityToken.trim()) {
    throw new InvalidAppleTokenError('identityToken is required');
  }

  const audiences = getAppleClientIds();
  if (audiences.length === 0) {
    throw new InvalidAppleTokenError(
      'APPLE_CLIENT_IDS is not configured on the server',
    );
  }

  let payload;
  try {
    const result = await jwtVerify(identityToken.trim(), keySet, {
      issuer: APPLE_ISSUER,
      audience: audiences,
    });
    payload = result.payload;
  } catch (error) {
    throw new InvalidAppleTokenError(
      error instanceof Error ? error.message : 'Apple token verification failed',
    );
  }

  if (typeof rawNonce !== 'string' || !rawNonce) {
    throw new InvalidAppleTokenError('nonce is required');
  }
  if (payload.nonce !== sha256Hex(rawNonce)) {
    throw new InvalidAppleTokenError('Nonce mismatch');
  }

  const sub = typeof payload.sub === 'string' ? payload.sub.trim() : '';
  if (!sub) {
    throw new InvalidAppleTokenError('Missing sub claim');
  }

  return {
    sub,
    email: typeof payload.email === 'string' ? payload.email : undefined,
  };
}

module.exports = {
  InvalidAppleTokenError,
  getAppleClientIds,
  sha256Hex,
  verifyAppleIdentityToken,
};
