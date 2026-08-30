const test = require('node:test');
const assert = require('node:assert/strict');
const {
  STARTING_MONEY,
  STARTING_CHIPS,
  MONEY_PER_CHIP,
  AD_REWARD_MONEY,
  AVATAR_CATALOG,
  DECK_CATALOG,
  IAP_CATALOG,
  getAdRewardMoney,
} = require('../db/marketplace');
const { GameRoom } = require('../game_room');

test('marketplace constants have expected economy values', () => {
  assert.equal(STARTING_MONEY, 500);
  assert.equal(STARTING_CHIPS, 1);
  assert.equal(MONEY_PER_CHIP, 1000);
  assert.equal(AD_REWARD_MONEY, 50);
  assert.equal(getAdRewardMoney(), 50);
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

test('marketplace IAP catalog contains expected consumable and subscription SKUs', () => {
  assert.equal(IAP_CATALOG.chips_1.type, 'chips');
  assert.equal(IAP_CATALOG.chips_1.amount, 1);
  assert.equal(IAP_CATALOG.chips_5.type, 'chips');
  assert.equal(IAP_CATALOG.chips_5.amount, 5);
  assert.equal(IAP_CATALOG.chips_10.type, 'chips');
  assert.equal(IAP_CATALOG.chips_10.amount, 10);
  assert.equal(IAP_CATALOG.chips_25.type, 'chips');
  assert.equal(IAP_CATALOG.chips_25.amount, 25);
  assert.equal(IAP_CATALOG.cash_1000.type, 'money');
  assert.equal(IAP_CATALOG.cash_1000.amount, 1000);
  assert.equal(IAP_CATALOG.cash_5000.type, 'money');
  assert.equal(IAP_CATALOG.cash_5000.amount, 5000);
  assert.equal(IAP_CATALOG.cash_10000.type, 'money');
  assert.equal(IAP_CATALOG.cash_10000.amount, 10000);
  assert.equal(IAP_CATALOG.pro_monthly.type, 'pro');
});

test('marketplace deck catalog contains classic and onyx black at 20 chips', () => {
  assert.equal(DECK_CATALOG.length, 2);
  const ids = DECK_CATALOG.map((d) => d.id);
  assert.deepEqual(ids, ['default', 'black_onyx']);
  const onyx = DECK_CATALOG.find((d) => d.id === 'black_onyx');
  assert.equal(onyx.price, 20);
  assert.equal(onyx.currency, 'chips');
});

test('GameRoom snapshot includes stakePool, stakePerPlayer, potAmount, avatarId, and deckId', () => {
  const room = new GameRoom('STAKE1', { random: () => 0.5 });
  room.stakePool = 100;
  room.stakePerPlayer = 50;
  room.potAmount = 100;

  room.addPlayer('c1', {
    playerId: 'p1',
    displayName: 'Player 1',
    avatarId: 'golden-king',
    deckId: 'black_onyx',
  });
  const snapshot = room.snapshotFor('c1');

  assert.equal(snapshot.stakePool, 100);
  assert.equal(snapshot.stakePerPlayer, 50);
  assert.equal(snapshot.potAmount, 100);
  assert.equal(snapshot.you.avatarId, 'golden-king');
  assert.equal(snapshot.you.deckId, 'black_onyx');
});

test('GameRoom snapshot tracks discardDeckId when card is thrown', () => {
  const room = new GameRoom('ROOM_DISCARD', { random: () => 0.1 });
  room.addPlayer('c1', { playerId: 'p1', displayName: 'P1', deckId: 'black_onyx' });
  room.addPlayer('c2', { playerId: 'p2', displayName: 'P2', deckId: 'default' });
  room.start('c1');
  room.players[0].launch = 'ended';
  room.players[1].launch = 'ended';
  room.turnIndex = 0;

  room.draw('c1');
  room.throwHand('c1');

  const snap = room.snapshotFor('c1');
  assert.equal(snap.discardDeckId, 'black_onyx');
});
