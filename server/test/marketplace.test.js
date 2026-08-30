const test = require('node:test');
const assert = require('node:assert/strict');
const {
  STARTING_MONEY,
  STARTING_CHIPS,
  MONEY_PER_CHIP,
  AD_REWARD_MONEY,
  AVATAR_CATALOG,
} = require('../db/marketplace');
const { GameRoom } = require('../game_room');

test('marketplace constants have expected economy values', () => {
  assert.equal(STARTING_MONEY, 500);
  assert.equal(STARTING_CHIPS, 1);
  assert.equal(MONEY_PER_CHIP, 1000);
  assert.equal(AD_REWARD_MONEY, 50);
});

test('marketplace avatar catalog contains all 10 app avatars', () => {
  assert.equal(AVATAR_CATALOG.length, 10);
  const ids = AVATAR_CATALOG.map((a) => a.id);
  assert.deepEqual(ids, [
    'default',
    'blue',
    'red',
    'bronze',
    'silver',
    'joker-girl',
    'violet-joker-girl',
    'violet-queen',
    'queen-of-heart',
    'golden-king',
  ]);
});

test('GameRoom snapshot includes stakePool, stakePerPlayer, potAmount, and avatarId', () => {
  const room = new GameRoom('STAKE1', { random: () => 0.5 });
  room.stakePool = 100;
  room.stakePerPlayer = 50;
  room.potAmount = 100;

  room.addPlayer('c1', { playerId: 'p1', displayName: 'Player 1', avatarId: 'golden-king' });
  const snapshot = room.snapshotFor('c1');

  assert.equal(snapshot.stakePool, 100);
  assert.equal(snapshot.stakePerPlayer, 50);
  assert.equal(snapshot.potAmount, 100);
  assert.equal(snapshot.you.avatarId, 'golden-king');
});
