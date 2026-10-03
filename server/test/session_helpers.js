const { signSession } = require('../auth/session');

/**
 * Mint a test JWT (no DB). Use in WS test payloads as `token`.
 * @param {string} playerId
 * @param {number} [tokenVersion]
 */
async function testToken(playerId, tokenVersion = 0) {
  return signSession({ playerId, tokenVersion });
}

module.exports = { testToken };
