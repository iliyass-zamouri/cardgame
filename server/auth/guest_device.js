/**
 * Guest device + client-IP identity rules.
 *
 * Guests are keyed by an install-scoped id from the client:
 *   local:<uuid-v4>
 * plus the server-observed client IP (not client-supplied).
 */

const LOCAL_DEVICE_ID_RE =
  /^local:[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

const COLLIDING_GUEST_DEVICE_IDS = new Set([
  'web-unknown',
  'android-unknown',
  'ios-unknown',
  'macos-unknown',
]);

class InvalidGuestDeviceIdError extends Error {
  constructor(message = 'deviceId must be local:<uuid>') {
    super(message);
    this.name = 'InvalidGuestDeviceIdError';
    this.code = 'invalid_device_id';
  }
}

class InvalidGuestIpError extends Error {
  constructor(message = 'client IP is required') {
    super(message);
    this.name = 'InvalidGuestIpError';
    this.code = 'invalid_client_ip';
  }
}

class GuestIpMismatchError extends Error {
  constructor(
    message = 'deviceId is bound to a different IP — cannot resume guest',
  ) {
    super(message);
    this.name = 'GuestIpMismatchError';
    this.code = 'device_ip_mismatch';
  }
}

function normalizeGuestDeviceId(raw) {
  if (typeof raw !== 'string') {
    return '';
  }
  return raw.trim();
}

function normalizeClientIp(raw) {
  if (typeof raw !== 'string') {
    return '';
  }
  let ip = raw.trim().toLowerCase();
  if (!ip) {
    return '';
  }
  const zone = ip.indexOf('%');
  if (zone !== -1) {
    ip = ip.slice(0, zone);
  }
  if (ip.startsWith('::ffff:')) {
    ip = ip.slice('::ffff:'.length);
  }
  if (ip === '::1') {
    ip = '127.0.0.1';
  }
  if (ip.length > 45) {
    return '';
  }
  return ip;
}

function getClientIp(req) {
  const trustProxy =
    process.env.TRUST_PROXY === '1' || process.env.TRUST_PROXY === 'true';
  if (trustProxy) {
    const xff = req.headers['x-forwarded-for'];
    if (typeof xff === 'string' && xff.trim()) {
      const first = xff.split(',')[0];
      const normalized = normalizeClientIp(first);
      if (normalized) {
        return normalized;
      }
    }
    const realIp = req.headers['x-real-ip'];
    if (typeof realIp === 'string') {
      const normalized = normalizeClientIp(realIp);
      if (normalized) {
        return normalized;
      }
    }
  }
  const addr = req.socket?.remoteAddress ?? '';
  return normalizeClientIp(addr);
}

function assertClientIp(raw) {
  const ip = normalizeClientIp(raw);
  if (!ip) {
    throw new InvalidGuestIpError('Could not determine client IP');
  }
  return ip;
}

function guestIpRebindEnabled() {
  return (
    process.env.GUEST_IP_REBIND === '1' ||
    process.env.GUEST_IP_REBIND === 'true'
  );
}

function isCollidingGuestDeviceId(deviceId) {
  if (!deviceId) {
    return true;
  }
  if (COLLIDING_GUEST_DEVICE_IDS.has(deviceId)) {
    return true;
  }
  if (deviceId.startsWith('unknown:')) {
    return true;
  }
  if (deviceId.startsWith('android:')) {
    return true;
  }
  return false;
}

function isValidGuestDeviceId(deviceId) {
  if (!deviceId || deviceId.length > 191) {
    return false;
  }
  if (isCollidingGuestDeviceId(deviceId)) {
    return false;
  }
  return LOCAL_DEVICE_ID_RE.test(deviceId);
}

function assertValidGuestDeviceId(raw) {
  const deviceId = normalizeGuestDeviceId(raw);
  if (!deviceId) {
    throw new InvalidGuestDeviceIdError('deviceId is required');
  }
  if (deviceId.length > 191) {
    throw new InvalidGuestDeviceIdError('deviceId too long');
  }
  if (!isValidGuestDeviceId(deviceId)) {
    throw new InvalidGuestDeviceIdError(
      'deviceId must be a unique install id (local:<uuid>)',
    );
  }
  return deviceId;
}

module.exports = {
  InvalidGuestDeviceIdError,
  InvalidGuestIpError,
  GuestIpMismatchError,
  normalizeGuestDeviceId,
  normalizeClientIp,
  getClientIp,
  assertClientIp,
  guestIpRebindEnabled,
  isCollidingGuestDeviceId,
  isValidGuestDeviceId,
  assertValidGuestDeviceId,
};
