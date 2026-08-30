const test = require('node:test');
const assert = require('node:assert/strict');
const {
  STARTING_MONEY,
  STARTING_CHIPS,
  MONEY_PER_CHIP,
  AD_REWARD_MONEY,
} = require('../db/marketplace');
const { GameRoom } = require('../game_room');

test('marketplace constants have expected economy values', () => {
  assert.equal(STARTING_MONEY, 500);
  assert.equal(STARTING_CHIPS, 1);
  assert.equal(MONEY_PER_CHIP, 1000);
  assert.equal(AD_REWARD_MONEY, 50);
});

test('GameRoom snapshot includes stakePool, stakePerPlayer, and potAmount', () => {
  const room = new GameRoom('STAKE1', { random: () => 0.5 });
  room.stakePool = 100;
  room.stakePerPlayer = 50;
  room.potAmount = 100;

  room.addPlayer('c1', { playerId: 'p1', displayName: 'Player 1' });
  const snapshot = room.snapshotFor('c1');

  assert.equal(snapshot.stakePool, 100);
  assert.equal(snapshot.stakePerPlayer, 50);
  assert.equal(snapshot.potAmount, 100);
});
