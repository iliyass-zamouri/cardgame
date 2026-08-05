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
