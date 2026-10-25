const test = require('node:test');
const assert = require('node:assert/strict');
const { STARTING_MONEY, STARTING_CHIPS, LEGACY_IAP_PRODUCTS, iapGrant } = require('../db/marketplace');
const { DEFAULTS, AVATARS, DECKS } = require('../marketplace_config');
const { GameRoom } = require('../game_room');

test('marketplace defaults keep the economy values from before the config', () => {
  assert.equal(STARTING_MONEY, 500);
  assert.equal(STARTING_CHIPS, 1);
  assert.deepEqual(DEFAULTS.economy, { moneyPerChip: 1000, startingMoney: 500, startingChips: 1 });
  assert.deepEqual(DEFAULTS.ads, { rewardMoney: 50, dailyCap: 5, cooldownSeconds: 60 });
});

test('marketplace avatar catalog contains all 10 app avatars', () => {
  assert.equal(AVATARS.length, 10);
  const ids = AVATARS.map((a) => a.id);
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

test('marketplace IAP products grant their default amounts, legacy ids included', () => {
  const grant = (productId) => iapGrant(DEFAULTS, productId, Date.now());
  assert.deepEqual(grant('chips_1'), { type: 'chips', amount: 1, bonus: 0 });
  assert.deepEqual(grant('chips_5'), { type: 'chips', amount: 5, bonus: 0 });
  assert.deepEqual(grant('chips_10'), { type: 'chips', amount: 10, bonus: 0 });
  assert.deepEqual(grant('chips_25'), { type: 'chips', amount: 25, bonus: 0 });
  assert.deepEqual(grant('chips_50'), { type: 'chips', amount: 50, bonus: 0 });
  assert.deepEqual(grant('cash_1000'), { type: 'money', amount: 1000, bonus: 0 });
  assert.deepEqual(grant('cash_5000'), { type: 'money', amount: 5000, bonus: 0 });
  assert.deepEqual(grant('cash_10000'), { type: 'money', amount: 10000, bonus: 0 });
  assert.deepEqual(grant('cash_25000'), { type: 'money', amount: 25000, bonus: 0 });
  assert.equal(grant('gems_100').amount, 100);
  assert.equal(LEGACY_IAP_PRODUCTS.pro_monthly.type, 'pro');
  assert.equal(grant('nope'), null);
});

test('marketplace deck catalog lists every deck the app sells, priced in chips', () => {
  const ids = DECKS.map((d) => d.id);
  assert.deepEqual(ids, [
    'default',
    'sapphire_frost',
    'imperial_jade',
    'royal_crimson',
    'neon_nights',
    'black_onyx',
    'gilded_gold',
  ]);
  const prices = Object.fromEntries(DECKS.map((d) => [d.id, d.price]));
  assert.deepEqual(prices, {
    default: 0,
    sapphire_frost: 6,
    imperial_jade: 8,
    royal_crimson: 12,
    neon_nights: 15,
    black_onyx: 20,
    gilded_gold: 35,
  });
  assert.ok(DECKS.every((d) => d.currency === 'chips'));
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
