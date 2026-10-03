const { SignJWT, jwtVerify } = require('jose');

const SESSION_TTL = '30d';
const DEV_SECRET = 'dev-session-secret';

class InvalidSessionError extends Error {
  /**
   * @param {'auth_required'|'invalid_token'} code
   * @param {string} [message]
   */
  constructor(code = 'invalid_token', message = 'Invalid session') {
    super(message);
    this.name = 'InvalidSessionError';
    this.code = code;
  }
}

/**
 * @returns {Uint8Array}
 */
function assertSessionSecret() {
  const fromEnv =
    typeof process.env.SESSION_SECRET === 'string'
      ? process.env.SESSION_SECRET.trim()
      : '';
  if (fromEnv) {
    return new TextEncoder().encode(fromEnv);
  }
  if (process.env.NODE_ENV === 'production') {
    throw new Error('SESSION_SECRET is required in production');
  }
  return new TextEncoder().encode(DEV_SECRET);
}

/**
 * @param {{ playerId: string, tokenVersion?: number }} input
 * @returns {Promise<string>}
 */
async function signSession({ playerId, tokenVersion = 0 }) {
  if (!playerId || typeof playerId !== 'string') {
    throw new Error('playerId is required to sign session');
  }
  const secret = assertSessionSecret();
  const tv = Number.isFinite(Number(tokenVersion))
    ? Math.max(0, Math.floor(Number(tokenVersion)))
    : 0;

  return new SignJWT({ tv })
    .setProtectedHeader({ alg: 'HS256' })
    .setSubject(playerId)
    .setIssuedAt()
    .setExpirationTime(SESSION_TTL)
    .sign(secret);
}

/**
 * @param {string} token
 * @returns {Promise<{ playerId: string, tokenVersion: number }>}
 */
async function verifySession(token) {
  if (typeof token !== 'string' || !token.trim()) {
    throw new InvalidSessionError('auth_required', 'Session token required');
  }
  try {
    const secret = assertSessionSecret();
    const { payload } = await jwtVerify(token.trim(), secret, {
      algorithms: ['HS256'],
    });
    const playerId =
      typeof payload.sub === 'string' && payload.sub.trim()
        ? payload.sub.trim()
        : null;
    if (!playerId) {
      throw new InvalidSessionError('invalid_token', 'Session missing subject');
    }
    const tv = Number(payload.tv);
    return {
      playerId,
      tokenVersion: Number.isFinite(tv) ? Math.max(0, Math.floor(tv)) : 0,
    };
  } catch (error) {
    if (error instanceof InvalidSessionError) throw error;
    throw new InvalidSessionError('invalid_token', 'Invalid or expired session');
  }
}

module.exports = {
  InvalidSessionError,
  assertSessionSecret,
  signSession,
  verifySession,
  SESSION_TTL,
  DEV_SECRET,
};
