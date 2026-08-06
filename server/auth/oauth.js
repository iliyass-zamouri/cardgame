const {
  findOrLinkOAuth,
  InvalidOAuthProviderError,
} = require('../db/store');

/**
 * @param {{ provider: 'google', sub: string, displayNameHint?: string|null, deviceId?: string|null, clientIp?: string|null }} args
 */
async function authenticateOAuth({
  provider,
  sub,
  displayNameHint,
  deviceId,
  clientIp,
}) {
  if (provider !== 'google') {
    throw new InvalidOAuthProviderError(provider);
  }
  return findOrLinkOAuth({
    provider,
    sub,
    displayNameHint: displayNameHint ?? null,
    deviceId: deviceId ?? null,
    clientIp: clientIp ?? null,
  });
}

module.exports = {
  authenticateOAuth,
  InvalidOAuthProviderError,
};
