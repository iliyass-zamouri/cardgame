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

test('snapshot includes displayName from addPlayer', () => {
  const room = new GameRoom('NAMES1');
  room.addPlayer('p1', { playerId: 'guest-1', displayName: 'Lucky Ace' });
  room.addPlayer('p2', { playerId: 'google-2', displayName: 'Sharp King' });
  const snap = room.snapshotFor('p1');
  assert.equal(snap.you.displayName, 'Lucky Ace');
  assert.equal(snap.you.playerId, 'guest-1');
  assert.equal(snap.opponent.displayName, 'Sharp King');
  assert.equal(snap.opponent.playerId, 'google-2');
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

test('drawing a Jack enables private peek for drawer only', () => {
  const room = startedRoom();
  room.players.forEach((player) => {
    player.launch = 'ended';
  });
  const player = room.players[room.turnIndex];
  const spectatorId = room.players[1 - room.turnIndex].id;
  room.deck.push('A11');

  room.draw(player.id);
  const snapshot = room.snapshotFor(player.id);
  const spectator = room.snapshotFor(spectatorId);

  assert.equal(snapshot.you.handCard, 'A11');
  assert.equal(snapshot.you.jackPeekAvailable, true);
  assert.equal(spectator.you.jackPeekAvailable, false);
  assert.equal(spectator.opponent.jackPeekAvailable, false);
});

test('jack peek reveals own card privately', () => {
  const room = startedRoom();
  room.players.forEach((player) => {
    player.launch = 'ended';
  });
  const player = room.players[room.turnIndex];
  const spectatorId = room.players[1 - room.turnIndex].id;
  player.cards = ['A5', 'B8'];
  player.handCard = 'C11';
  player.jackPeekAvailable = true;

  room.jackPeek(player.id, { side: 'you', cardIndex: 1 });
  const snapshot = room.snapshotFor(player.id);
  const spectator = room.snapshotFor(spectatorId);

  assert.equal(snapshot.you.cards[1].visible, true);
  assert.equal(snapshot.you.cards[1].tag, 'B8');
  assert.equal(snapshot.you.jackPeekAvailable, false);
  assert.deepEqual(snapshot.lastAction, {
    actor: 'you',
    type: 'jackPeek',
    cardIndex: 1,
    cardTag: null,
    drawnTag: null,
    side: 'you',
  });
  assert.equal(spectator.opponent.cards[1].visible, false);
  assert.equal(spectator.opponent.cards[1].tag, null);
  assert.deepEqual(spectator.lastAction, {
    actor: 'opponent',
    type: 'jackPeek',
    cardIndex: 1,
    cardTag: null,
    drawnTag: null,
    side: 'you',
  });
});

test('jack peek reveals opponent card privately', () => {
  const room = startedRoom();
  room.players.forEach((player) => {
    player.launch = 'ended';
  });
  const player = room.players[room.turnIndex];
  const opponent = room.players[1 - room.turnIndex];
  player.cards = ['A5', 'B8'];
  player.handCard = 'C11';
  player.jackPeekAvailable = true;
  opponent.cards = ['D3', 'A7'];

  room.jackPeek(player.id, { side: 'opponent', cardIndex: 0 });
  const snapshot = room.snapshotFor(player.id);
  const spectator = room.snapshotFor(opponent.id);

  assert.equal(snapshot.opponent.cards[0].visible, true);
  assert.equal(snapshot.opponent.cards[0].tag, 'D3');
  assert.equal(spectator.you.cards[0].visible, false);
  assert.equal(spectator.you.cards[0].tag, null);
  assert.equal(spectator.lastAction.side, 'opponent');
  assert.equal(spectator.lastAction.cardTag, null);
});

test('jack peek rejects without Jack, after use, and while peek in progress', () => {
  const room = startedRoom();
  room.players.forEach((player) => {
    player.launch = 'ended';
  });
  const player = room.players[room.turnIndex];
  player.cards = ['A5', 'B8'];
  player.handCard = 'D9';
  player.jackPeekAvailable = false;

  assert.throws(
    () => room.jackPeek(player.id, { side: 'you', cardIndex: 0 }),
    (error) => error instanceof GameRuleError && error.code === 'no_jack',
  );

  player.handCard = 'C11';
  player.jackPeekAvailable = true;
  room.jackPeek(player.id, { side: 'you', cardIndex: 0 });
  assert.throws(
    () => room.jackPeek(player.id, { side: 'you', cardIndex: 1 }),
    (error) =>
      error instanceof GameRuleError && error.code === 'peek_in_progress',
  );
  assert.throws(
    () => room.throwHand(player.id),
    (error) =>
      error instanceof GameRuleError && error.code === 'peek_in_progress',
  );
  assert.throws(
    () => room.tapCard(player.id, 1),
    (error) =>
      error instanceof GameRuleError && error.code === 'peek_in_progress',
  );
  room.dispose();
});

test('jack peek auto-throws Jack when peek ends', async () => {
  const room = new GameRoom('TEST01', { random: () => 0.25, peekDurationMs: 20 });
  room.addPlayer('p1');
  room.addPlayer('p2');
  room.start('p1');
  room.players.forEach((player) => {
    player.launch = 'ended';
  });
  const player = room.players[room.turnIndex];
  const spectatorId = room.players[1 - room.turnIndex].id;
  player.cards = ['A5', 'B8'];
  player.handCard = 'C11';
  player.jackPeekAvailable = true;

  room.jackPeek(player.id, { side: 'you', cardIndex: 0 });
  assert.equal(room.snapshotFor(player.id).you.hasHandCard, true);

  await new Promise((resolve) => setTimeout(resolve, 50));

  const snapshot = room.snapshotFor(player.id);
  const spectator = room.snapshotFor(spectatorId);
  assert.equal(snapshot.you.hasHandCard, false);
  assert.equal(snapshot.you.jackPeekAvailable, false);
  assert.equal(snapshot.discardTop, 'C11');
  assert.equal(snapshot.discardSource, 'drawn');
  assert.deepEqual(snapshot.lastAction, {
    actor: 'you',
    type: 'throw',
    cardIndex: null,
    cardTag: 'C11',
    drawnTag: null,
  });
  assert.equal(spectator.lastAction.type, 'throw');
  assert.equal(spectator.lastAction.cardTag, 'C11');
  assert.equal(snapshot.you.cards[0].visible, false);
  room.dispose();
});

test('drawing a Queen enables ability for drawer only', () => {
  const room = startedRoom();
  room.players.forEach((player) => {
    player.launch = 'ended';
  });
  const player = room.players[room.turnIndex];
  const spectatorId = room.players[1 - room.turnIndex].id;
  room.deck.push('A12');

  room.draw(player.id);
  const snapshot = room.snapshotFor(player.id);
  const spectator = room.snapshotFor(spectatorId);

  assert.equal(snapshot.you.handCard, 'A12');
  assert.equal(snapshot.you.queenAbilityAvailable, true);
  assert.equal(snapshot.you.jackPeekAvailable, false);
  assert.equal(spectator.you.queenAbilityAvailable, false);
  assert.equal(spectator.opponent.queenAbilityAvailable, false);
});

test('queen shuffle reorders target hand and auto-throws', async () => {
  const room = new GameRoom('TEST01', {
    random: () => 0.1,
    queenShuffleDurationMs: 20,
  });
  room.addPlayer('p1');
  room.addPlayer('p2');
  room.start('p1');
  room.players.forEach((player) => {
    player.launch = 'ended';
  });
  const player = room.players[room.turnIndex];
  player.cards = ['A1', 'B2', 'C3', 'D4'];
  player.handCard = 'A12';
  player.queenAbilityAvailable = true;
  const before = [...player.cards];

  room.queenShuffle(player.id, { side: 'you' });
  const mid = room.snapshotFor(player.id);
  assert.equal(mid.you.queenAbilityAvailable, false);
  assert.equal(mid.lastAction.type, 'queenShuffle');
  assert.equal(mid.lastAction.side, 'you');
  assert.equal(mid.you.hasHandCard, true);
  assert.notDeepEqual(
    mid.you.cards.map((card) => card.index),
    [],
  );
  // Order may change; tags stay hidden but underlying cards shuffled.
  assert.notDeepEqual(player.cards, before);

  await new Promise((resolve) => setTimeout(resolve, 50));
  const after = room.snapshotFor(player.id);
  assert.equal(after.you.hasHandCard, false);
  assert.equal(after.discardTop, 'A12');
  assert.equal(after.lastAction.type, 'throw');
  room.dispose();
});

test('queen replace swaps cross-player cards and auto-throws', async () => {
  const room = new GameRoom('TEST01', {
    random: () => 0.25,
    queenReplaceDurationMs: 20,
  });
  room.addPlayer('p1');
  room.addPlayer('p2');
  room.start('p1');
  room.players.forEach((player) => {
    player.launch = 'ended';
  });
  const player = room.players[room.turnIndex];
  const opponent = room.players[1 - room.turnIndex];
  player.cards = ['A5', 'B8'];
  opponent.cards = ['C3', 'D7'];
  player.handCard = 'B12';
  player.queenAbilityAvailable = true;

  room.queenReplace(player.id, { youIndex: 0, opponentIndex: 1 });
  assert.equal(player.cards[0], 'D7');
  assert.equal(opponent.cards[1], 'A5');
  const mid = room.snapshotFor(player.id);
  assert.equal(mid.lastAction.type, 'queenReplace');
  assert.equal(mid.lastAction.youIndex, 0);
  assert.equal(mid.lastAction.opponentIndex, 1);
  assert.equal(mid.lastAction.cardTag, null);
  assert.equal(mid.you.hasHandCard, true);

  await new Promise((resolve) => setTimeout(resolve, 50));
  const after = room.snapshotFor(player.id);
  assert.equal(after.you.hasHandCard, false);
  assert.equal(after.discardTop, 'B12');
  room.dispose();
});

test('queen ability rejects without Queen, after use, and during lock', () => {
  const room = startedRoom();
  room.players.forEach((player) => {
    player.launch = 'ended';
  });
  const player = room.players[room.turnIndex];
  player.cards = ['A5', 'B8', 'C3'];
  player.handCard = 'D9';
  player.queenAbilityAvailable = false;

  assert.throws(
    () => room.queenShuffle(player.id, { side: 'you' }),
    (error) => error instanceof GameRuleError && error.code === 'no_queen',
  );

  player.handCard = 'C12';
  player.queenAbilityAvailable = true;
  room.queenShuffle(player.id, { side: 'you' });
  assert.throws(
    () => room.queenReplace(player.id, { youIndex: 0, opponentIndex: 0 }),
    (error) =>
      error instanceof GameRuleError && error.code === 'queen_in_progress',
  );
  assert.throws(
    () => room.throwHand(player.id),
    (error) =>
      error instanceof GameRuleError && error.code === 'queen_in_progress',
  );
  room.dispose();
});
