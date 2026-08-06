const test = require('node:test');
const assert = require('node:assert/strict');
const { GameRoom, GameRuleError } = require('../game_room');

function startedRoom() {
  const room = new GameRoom('TEST01', { random: () => 0.25 });
  room.addPlayer('p1');
  room.addPlayer('p2');
  room.start('p1');
  return room;
}

test('server owns deal and hides private cards', () => {
  const room = startedRoom();
  const p1 = room.snapshotFor('p1');
  const p2 = room.snapshotFor('p2');

  assert.equal(p1.deckCount, 46);
  assert.equal(p1.you.cards.length, 4);
  assert.equal(p1.you.cards.every((card) => card.tag === null), true);
  assert.equal(p2.opponent.cards.every((card) => card.tag === null), true);
});

test('rejects command from player without turn', () => {
  const room = startedRoom();
  room.players.forEach((player) => {
    player.launch = 'ended';
  });
  const wrongPlayer = room.players[1 - room.turnIndex].id;

  assert.throws(
    () => room.draw(wrongPlayer),
    (error) =>
      error instanceof GameRuleError && error.code === 'not_your_turn',
  );
});

test('draw changes authoritative snapshot exactly once', () => {
  const room = startedRoom();
  room.players.forEach((player) => {
    player.launch = 'ended';
  });
  const playerId = room.players[room.turnIndex].id;
  const before = room.snapshotFor(playerId);

  room.draw(playerId);
  const after = room.snapshotFor(playerId);

  assert.equal(after.deckCount, before.deckCount - 1);
  assert.equal(after.you.hasHandCard, true);
  assert.equal(typeof after.you.handCard, 'string');
});

test('matching hand and drawn cards both land on the public discard pile', () => {
  const room = startedRoom();
  room.players.forEach((player) => {
    player.launch = 'ended';
  });
  const player = room.players[room.turnIndex];
  const spectatorId = room.players[1 - room.turnIndex].id;
  player.cards = ['A5', 'B8'];
  player.handCard = 'D5';

  room.tapCard(player.id, 0);
  const snapshot = room.snapshotFor(player.id);
  const spectator = room.snapshotFor(spectatorId);

  assert.deepEqual(snapshot.discardRecent, ['A5', 'D5']);
  assert.equal(snapshot.discardTop, 'D5');
  assert.equal(snapshot.you.cards.length, 1);
  assert.equal(snapshot.you.handCard, null);
  assert.deepEqual(snapshot.lastAction, {
    actor: 'you',
    type: 'doubleDiscard',
    cardIndex: 0,
    cardTag: 'A5',
    drawnTag: 'D5',
  });
  assert.deepEqual(spectator.lastAction, {
    actor: 'opponent',
    type: 'doubleDiscard',
    cardIndex: 0,
    cardTag: 'A5',
    drawnTag: 'D5',
  });
});

test('mismatched cards leave only the swapped card on the discard pile', () => {
  const room = startedRoom();
  room.players.forEach((player) => {
    player.launch = 'ended';
  });
  const player = room.players[room.turnIndex];
  const spectatorId = room.players[1 - room.turnIndex].id;
  player.cards = ['A5', 'B8'];
  player.handCard = 'D9';

  room.tapCard(player.id, 0);
  const snapshot = room.snapshotFor(player.id);
  const spectator = room.snapshotFor(spectatorId);

  assert.equal(snapshot.discardTop, 'A5');
  assert.equal(snapshot.discardRecent.at(-1), 'A5');
  assert.equal(snapshot.you.cards.length, 2);
  assert.equal(snapshot.you.hasHandCard, false);
  assert.equal(snapshot.discardSource, 'hand');
  assert.deepEqual(snapshot.lastAction, {
    actor: 'you',
    type: 'swap',
    cardIndex: 0,
    cardTag: 'A5',
    drawnTag: null,
  });
  assert.deepEqual(spectator.lastAction, {
    actor: 'opponent',
    type: 'swap',
    cardIndex: 0,
    cardTag: 'A5',
    drawnTag: null,
  });
});

test('discard match records lastAction for both viewers', () => {
  const room = startedRoom();
  room.players.forEach((player) => {
    player.launch = 'ended';
  });
  const player = room.players[room.turnIndex];
  const spectatorId = room.players[1 - room.turnIndex].id;
  room.discard = ['C5'];
  player.cards = ['A5', 'B8'];
  player.handCard = null;

  room.tapCard(player.id, 0);
  const snapshot = room.snapshotFor(player.id);
  const spectator = room.snapshotFor(spectatorId);

  assert.equal(snapshot.discardTop, 'A5');
  assert.equal(snapshot.you.cards.length, 1);
  assert.deepEqual(snapshot.lastAction, {
    actor: 'you',
    type: 'discardMatch',
    cardIndex: 0,
    cardTag: 'A5',
    drawnTag: null,
  });
  assert.deepEqual(spectator.lastAction, {
    actor: 'opponent',
    type: 'discardMatch',
    cardIndex: 0,
    cardTag: 'A5',
    drawnTag: null,
  });
});

test('penalty miss records lastAction for both viewers', () => {
  const room = startedRoom();
  room.players.forEach((player) => {
    player.launch = 'ended';
  });
  const player = room.players[room.turnIndex];
  const spectatorId = room.players[1 - room.turnIndex].id;
  room.discard = ['C9'];
  player.cards = ['A5', 'B8'];
  player.handCard = null;
  const beforeCount = player.cards.length;

  room.tapCard(player.id, 1);
  const snapshot = room.snapshotFor(player.id);
  const spectator = room.snapshotFor(spectatorId);

  assert.equal(snapshot.you.cards.length, beforeCount + 1);
  assert.deepEqual(snapshot.lastAction, {
    actor: 'you',
    type: 'penaltyDraw',
    cardIndex: 1,
    cardTag: null,
    drawnTag: null,
  });
  assert.deepEqual(spectator.lastAction, {
    actor: 'opponent',
    type: 'penaltyDraw',
    cardIndex: 1,
    cardTag: null,
    drawnTag: null,
  });
});

test('draw records lastAction for both viewers', () => {
  const room = startedRoom();
  room.players.forEach((player) => {
    player.launch = 'ended';
  });
  const playerId = room.players[room.turnIndex].id;
  const spectatorId = room.players[1 - room.turnIndex].id;
  const before = room.snapshotFor(playerId);

  room.draw(playerId);
  const after = room.snapshotFor(playerId);
  const spectator = room.snapshotFor(spectatorId);

  assert.equal(after.deckCount, before.deckCount - 1);
  assert.equal(after.you.hasHandCard, true);
  assert.deepEqual(after.lastAction, {
    actor: 'you',
    type: 'draw',
    cardIndex: null,
    cardTag: null,
    drawnTag: null,
  });
  assert.deepEqual(spectator.lastAction, {
    actor: 'opponent',
    type: 'draw',
    cardIndex: null,
    cardTag: null,
    drawnTag: null,
  });
});

test('throw records lastAction for both viewers', () => {
  const room = startedRoom();
  room.players.forEach((player) => {
    player.launch = 'ended';
  });
  const player = room.players[room.turnIndex];
  const spectatorId = room.players[1 - room.turnIndex].id;
  player.handCard = 'D7';

  room.throwHand(player.id);
  const snapshot = room.snapshotFor(player.id);
  const spectator = room.snapshotFor(spectatorId);

  assert.equal(snapshot.discardTop, 'D7');
  assert.equal(snapshot.you.hasHandCard, false);
  assert.equal(snapshot.discardSource, 'drawn');
  assert.deepEqual(snapshot.lastAction, {
    actor: 'you',
    type: 'throw',
    cardIndex: null,
    cardTag: 'D7',
    drawnTag: null,
  });
  assert.deepEqual(spectator.lastAction, {
    actor: 'opponent',
    type: 'throw',
    cardIndex: null,
    cardTag: 'D7',
    drawnTag: null,
  });
});

test('end computes scores on server and reveals cards', () => {
  const room = startedRoom();
  room.players[0].cards = ['A5'];
  room.players[1].cards = ['B6'];

  room.end('p1');
  const snapshot = room.snapshotFor('p1');

  assert.equal(snapshot.status, 'ended');
  assert.deepEqual(snapshot.result.scores, [5, 6]);
  assert.equal(snapshot.result.winnerIndex, 0);
  assert.equal(snapshot.you.cards[0].tag, 'A5');
  assert.equal(snapshot.opponent.cards[0].tag, 'B6');
});
