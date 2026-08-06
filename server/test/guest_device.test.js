const test = require('node:test');
const assert = require('node:assert/strict');
const {
  assertValidGuestDeviceId,
  isValidGuestDeviceId,
  normalizeClientIp,
  InvalidGuestDeviceIdError,
} = require('../auth/guest_device');
const { generateGuestIdentity } = require('../auth/guest_name');

test('accepts local uuid guest device ids', () => {
  const id = 'local:550e8400-e29b-41d4-a716-446655440000';
  assert.equal(isValidGuestDeviceId(id), true);
  assert.equal(assertValidGuestDeviceId(id), id);
});

test('rejects colliding and legacy guest device ids', () => {
  assert.equal(isValidGuestDeviceId('android:TQ3A.230805.001'), false);
  assert.equal(isValidGuestDeviceId('web-unknown'), false);
  assert.throws(
    () => assertValidGuestDeviceId('android:foo'),
    (error) => error instanceof InvalidGuestDeviceIdError,
  );
});

test('normalizes loopback and ipv4-mapped addresses', () => {
  assert.equal(normalizeClientIp('::1'), '127.0.0.1');
  assert.equal(normalizeClientIp('::ffff:127.0.0.1'), '127.0.0.1');
});

test('generateGuestIdentity returns name and short username', () => {
  const identity = generateGuestIdentity();
  assert.ok(identity.name.length > 0);
  assert.ok(identity.username.length > 0);
  assert.ok(identity.username.length <= 16);
});
