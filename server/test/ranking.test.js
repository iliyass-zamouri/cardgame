const test = require('node:test');
const assert = require('node:assert/strict');
const {
  expectedScore,
  applyElo,
  marginPoints,
  computeMatchRatings,
  ELO_K,
  ELO_FLOOR,
  POINTS_WIN_BASE,
  POINTS_DRAW_BASE,
  POINTS_LOSS_BASE,
} = require('../db/ranking');
const { GameRoom } = require('../game_room');

test('expectedScore is 0.5 when Elo equal', () => {
  assert.equal(expectedScore(1000, 1000), 0.5);
});

test('applyElo awards winner points vs equal opponent', () => {
  const { eloAfter, eloDelta } = applyElo(1000, 1000, 'win');
  assert.equal(eloDelta, Math.round(ELO_K * 0.5));
  assert.equal(eloAfter, 1000 + eloDelta);
});

test('applyElo clamps at floor', () => {
  const { eloAfter, eloDelta } = applyElo(ELO_FLOOR, 2000, 'loss');
  assert.equal(eloAfter, ELO_FLOOR);
  assert.equal(eloDelta, 0);
});

test('marginPoints win includes capped bonus', () => {
  assert.equal(marginPoints('win', 0, 10), POINTS_WIN_BASE + 5);
  assert.equal(marginPoints('win', 0, 100), POINTS_WIN_BASE + 15);
  assert.equal(marginPoints('draw', 5, 5), POINTS_DRAW_BASE);
  assert.equal(marginPoints('loss', 20, 0), POINTS_LOSS_BASE);
});

test('computeMatchRatings is zero-sum on Elo for equal players', () => {
  const rated = computeMatchRatings(
    { cardTotal: 3, elo: 1000 },
    { cardTotal: 8, elo: 1000 },
    0,
  );
  assert.equal(rated.a.result, 'win');
  assert.equal(rated.b.result, 'loss');
  assert.equal(rated.a.eloDelta + rated.b.eloDelta, 0);
  assert.equal(rated.a.pointsEarned, POINTS_WIN_BASE + 2);
  assert.equal(rated.b.pointsEarned, POINTS_LOSS_BASE);
});

test('random endGame invokes onRankedEnd once', async () => {
  const calls = [];
  const room = new GameRoom('RANK01', {
    random: () => 0.25,
    onRankedEnd: (payload) => {
      calls.push(payload);
      return Promise.resolve({ ok: true });
    },
  });
  room.matchType = 'random';
  room.addPlayer('c1', { playerId: 'guest-a', displayName: 'A' });
  room.addPlayer('c2', { playerId: 'guest-b', displayName: 'B' });
  room.start('c1');
  room.players[0].cards = [];
  room.players[1].cards = ['A5'];
  room.end('c1');

  assert.equal(room.status, 'ended');
  assert.equal(room.rankedSaved, true);
  await new Promise((resolve) => setImmediate(resolve));
  assert.equal(calls.length, 1);
  assert.equal(calls[0].roomId, 'RANK01');
  assert.equal(calls[0].players.length, 2);

  // Second end while already ended should not re-fire via finish path;
  // rematch start clears flag.
  room.rematch('c1');
  room.rematch('c2');
  assert.equal(room.rankedSaved, false);
  room.players[0].cards = [];
  room.players[1].cards = ['B3'];
  room.end('c1');
  await new Promise((resolve) => setImmediate(resolve));
  assert.equal(calls.length, 2);
});

test('private match does not invoke onRankedEnd', async () => {
  const calls = [];
  const room = new GameRoom('PRIV01', {
    onRankedEnd: (payload) => {
      calls.push(payload);
    },
  });
  room.matchType = 'private';
  room.addPlayer('c1', { playerId: 'guest-a', displayName: 'A' });
  room.addPlayer('c2', { playerId: 'guest-b', displayName: 'B' });
  room.start('c1');
  room.players[0].cards = [];
  room.players[1].cards = ['A5'];
  room.end('c1');
  await new Promise((resolve) => setImmediate(resolve));
  assert.equal(calls.length, 0);
  assert.equal(room.rankedSaved, false);
});

test('random without playerIds skips ranking', async () => {
  const calls = [];
  const room = new GameRoom('NOPID1', {
    onRankedEnd: (payload) => {
      calls.push(payload);
    },
  });
  room.matchType = 'random';
  room.addPlayer('c1');
  room.addPlayer('c2');
  room.start('c1');
  room.players[0].cards = [];
  room.players[1].cards = ['A5'];
  room.end('c1');
  await new Promise((resolve) => setImmediate(resolve));
  assert.equal(calls.length, 0);
});
