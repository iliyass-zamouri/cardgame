'use strict';
const test = require('node:test');
const assert = require('node:assert');
const { getClientCountry, normalizeCountry } = require('../auth/geo');

test('normalizeCountry validates codes', () => {
  assert.strictEqual(normalizeCountry('ma'), 'MA');
  assert.strictEqual(normalizeCountry('XX'), null);
  assert.strictEqual(normalizeCountry('T1'), null);
  assert.strictEqual(normalizeCountry('USA'), null);
});

test('CF-IPCountry only trusted behind proxy', () => {
  const req = { headers: { 'cf-ipcountry': 'MA' } };
  process.env.TRUST_PROXY = '1';
  assert.strictEqual(getClientCountry(req, '127.0.0.1'), 'MA');
  process.env.TRUST_PROXY = '0';
  assert.strictEqual(getClientCountry(req, '127.0.0.1'), null);
});

test('geoip lookup for a public IP, null for private', () => {
  process.env.TRUST_PROXY = '0';
  assert.strictEqual(getClientCountry({ headers: {} }, '8.8.8.8'), 'US');
  assert.strictEqual(getClientCountry({ headers: {} }, '192.168.1.5'), null);
});
