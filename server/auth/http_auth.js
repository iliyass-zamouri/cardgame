const { verifySession, InvalidSessionError } = require('./session');
const { getPlayerTokenVersion } = require('../db/store');

function isDbReady() {
  try {
    require('../db/pool').getPool();
    return true;
  } catch {
    return false;
  }
}

/**
 * @param {import('http').IncomingMessage} request
 * @returns {string|null}
 */
function getBearerToken(request) {
  const header = request.headers?.authorization;
  if (typeof header !== 'string') return null;
  const match = /^Bearer\s+(.+)$/i.exec(header.trim());
  if (!match) return null;
  const token = match[1].trim();
  return token || null;
}

/**
 * Verify JWT + token_version. Sends 401 via sendJson on failure.
 * @returns {Promise<{ playerId: string }|null>}
 */
async function requireAuth(request, response, sendJson) {
  const token = getBearerToken(request);
  if (!token) {
    sendJson(response, 401, {
      error: 'auth_required',
      message: 'Authorization Bearer token required',
    });
    return null;
  }

  let session;
  try {
    session = await verifySession(token);
  } catch (error) {
    const code =
      error instanceof InvalidSessionError ? error.code : 'invalid_token';
    sendJson(response, 401, {
      error: code,
      message: error.message || 'Invalid session',
    });
    return null;
  }

  if (!isDbReady()) {
    return { playerId: session.playerId };
  }

  let dbVersion;
  try {
    dbVersion = await getPlayerTokenVersion(session.playerId);
  } catch (error) {
    if (error?.message?.includes('MySQL pool not initialized')) {
      return { playerId: session.playerId };
    }
    throw error;
  }

  if (dbVersion == null) {
    sendJson(response, 401, {
      error: 'invalid_token',
      message: 'Player not found',
    });
    return null;
  }

  if (Number(dbVersion) !== Number(session.tokenVersion)) {
    sendJson(response, 401, {
      error: 'invalid_token',
      message: 'Session revoked',
    });
    return null;
  }

  return { playerId: session.playerId };
}

module.exports = {
  getBearerToken,
  requireAuth,
  isDbReady,
};
