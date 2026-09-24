const {
  findOrLinkOAuth,
  InvalidOAuthProviderError,
  GoogleAccountInUseError,
} = require('../db/store');

/**
 * @param {{
 *   provider: 'google',
 *   sub: string,
 *   displayNameHint?: string|null,
 *   email?: string|null,
 *   deviceId?: string|null,
 *   clientIp?: string|null,
 *   confirmSwitch?: boolean,
 * }} args
 */
async function authenticateOAuth({
  provider,
  sub,
  displayNameHint,
  email,
  deviceId,
  clientIp,
  confirmSwitch = false,
}) {
  if (provider !== 'google') {
    throw new InvalidOAuthProviderError(provider);
  }
  return findOrLinkOAuth({
    provider,
    sub,
    displayNameHint: displayNameHint ?? null,
    email: email ?? null,
    deviceId: deviceId ?? null,
    clientIp: clientIp ?? null,
    confirmSwitch: confirmSwitch === true,
  });
}

module.exports = {
  authenticateOAuth,
  InvalidOAuthProviderError,
  GoogleAccountInUseError,
};
