const test = require('node:test');
const assert = require('node:assert/strict');
const {
  isValidUsernameFormat,
  normalizeUsername,
} = require('../db/friends');

test('isValidUsernameFormat validates username format correctly', () => {
  // Valid usernames
  assert.equal(isValidUsernameFormat('alice'), true);
  assert.equal(isValidUsernameFormat('bob_123'), true);
  assert.equal(isValidUsernameFormat('lucky_ace_9999'), true);
  assert.equal(isValidUsernameFormat('abc'), true); // 3 chars
  assert.equal(isValidUsernameFormat('a1234567890123456789'), true); // 20 chars

  // Invalid usernames
  assert.equal(isValidUsernameFormat('ab'), false); // too short
  assert.equal(isValidUsernameFormat('a123456789012345678901'), false); // too long (21 chars)
  assert.equal(isValidUsernameFormat('alice!'), false); // invalid character
  assert.equal(isValidUsernameFormat('alice space'), false); // spaces
  assert.equal(isValidUsernameFormat(''), false); // empty
  assert.equal(isValidUsernameFormat(null), false); // null
  assert.equal(isValidUsernameFormat(123), false); // non-string
});

test('normalizeUsername trims and converts to lowercase', () => {
  assert.equal(normalizeUsername('  Alice_123  '), 'alice_123');
  assert.equal(normalizeUsername('LUCKY_ACE'), 'lucky_ace');
  assert.equal(normalizeUsername(null), '');
});
