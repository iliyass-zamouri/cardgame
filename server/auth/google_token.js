const { createRemoteJWKSet, jwtVerify } = require('jose');

const GOOGLE_ISSUERS = new Set([
  'https://accounts.google.com',
  'accounts.google.com',
]);

const googleJwks = createRemoteJWKSet(
  new URL('https://www.googleapis.com/oauth2/v3/certs'),
);

class InvalidGoogleTokenError extends Error {
  constructor(message = 'Invalid Google id token') {
    super(message);
    this.name = 'InvalidGoogleTokenError';
    this.code = 'invalid_google_token';
  }
}

function getGoogleClientIds() {
  const raw = process.env.GOOGLE_CLIENT_IDS ?? '';
  return raw
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean);
}

/**
 * Verify a Google ID token and return claims needed for account linking.
 * @param {string} idToken
 * @returns {Promise<{ sub: string, email?: string, name?: string }>}
 */
async function verifyGoogleIdToken(idToken) {
  if (typeof idToken !== 'string' || !idToken.trim()) {
    throw new InvalidGoogleTokenError('idToken is required');
  }

  const audiences = getGoogleClientIds();
  if (audiences.length === 0) {
    throw new InvalidGoogleTokenError(
      'GOOGLE_CLIENT_IDS is not configured on the server',
    );
  }

  let payload;
  try {
    const result = await jwtVerify(idToken.trim(), googleJwks, {
      audience: audiences,
    });
    payload = result.payload;
  } catch (error) {
    throw new InvalidGoogleTokenError(
      error instanceof Error ? error.message : 'Google token verification failed',
    );
  }

  const iss = typeof payload.iss === 'string' ? payload.iss : '';
  if (!GOOGLE_ISSUERS.has(iss)) {
    throw new InvalidGoogleTokenError(`Unexpected issuer: ${iss}`);
  }

  const sub = typeof payload.sub === 'string' ? payload.sub.trim() : '';
  if (!sub) {
    throw new InvalidGoogleTokenError('Missing sub claim');
  }

  return {
    sub,
    email: typeof payload.email === 'string' ? payload.email : undefined,
    name: typeof payload.name === 'string' ? payload.name : undefined,
  };
}

module.exports = {
  InvalidGoogleTokenError,
  getGoogleClientIds,
  verifyGoogleIdToken,
};
