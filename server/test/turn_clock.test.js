const test = require('node:test');
const assert = require('node:assert/strict');
const { GameRoom, GameRuleError } = require('../game_room');

const TURN_MS = 1000;
const REVEAL_MS = 500;
const LAUNCH_MS = 100;
const JACK = 'A11';

/**
 * A room on mock timers with an injected clock. p1 starts (random 0.25).
 * With `reveal`, both seats reveal first so the first turn's clock is running.
 */
function timedRoom(t, { reveal = false, turnTimerConfig, matchType = 'private', ...options } = {}) {
  t.mock.timers.enable({ apis: ['setTimeout'] });
  const clock = { now: 0 };
  const room = new GameRoom('CLOCK1', {
    random: () => 0.25,
    turnTimerConfig: turnTimerConfig
      ?? (() => ({ turnMs: TURN_MS, revealMs: REVEAL_MS, maxMissedTurns: 2 })),
    turnGraceMs: 0,
    launchRevealMs: LAUNCH_MS,
    now: () => clock.now,
    ...options,
  });
  room.addPlayer('p1', { playerId: 'a1' });
  room.addPlayer('p2', { playerId: 'a2' });
  room.matchType = matchType;
  room.start('p1');
  if (reveal) {
    room.launch('p1');
    room.launch('p2');
    t.mock.timers.tick(LAUNCH_MS);
  }
  t.after(() => room.dispose());
  return { room, clock };
}

test('rooms without a turn-limit config never start a clock', (t) => {
  t.mock.timers.enable({ apis: ['setTimeout'] });
  const room = new GameRoom('CLOCK0', { random: () => 0.25 });
  room.addPlayer('p1');
  room.addPlayer('p2');
  room.start('p1');
  room.launch('p1');
  room.launch('p2');
  t.mock.timers.tick(10_000);
  assert.equal(room.turnClock, null);
  assert.equal(room.snapshotFor('p1').turnTimer, null);
  assert.equal(room.turnIndex, 0);
});

test('the turn clock starts once both players have revealed', (t) => {
  const { room, clock } = timedRoom(t);
  room.launch('p1');
  t.mock.timers.tick(LAUNCH_MS);
  assert.equal(room.turnClock, null);
  room.launch('p2');
  t.mock.timers.tick(LAUNCH_MS);
  clock.now = 250;
  const expected = { limitMs: TURN_MS, remainingMs: 750, maxMissedTurns: 2 };
  assert.deepEqual(room.snapshotFor('p1').turnTimer, expected);
  assert.deepEqual(room.snapshotFor('p2').turnTimer, expected);
});

test('an expired turn is played for the seat and counted as a miss', (t) => {
  const { room } = timedRoom(t, { reveal: true });
  t.mock.timers.tick(TURN_MS);
  assert.deepEqual(room.missedTurns, [1, 0]);
  assert.equal(room.turnIndex, 1);
  assert.equal(room.players[0].cards.length, 4);
  assert.equal(room.players[0].handCard, null);
  assert.equal(room.discard.length, 1);
  assert.equal(room.lastAction.type, 'throw');
  assert.equal(room.status, 'playing');
});

test('a real move clears the mover\'s miss streak', (t) => {
  const { room } = timedRoom(t, { reveal: true });
  t.mock.timers.tick(TURN_MS);
  t.mock.timers.tick(TURN_MS);
  assert.deepEqual(room.missedTurns, [1, 1]);
  assert.equal(room.turnIndex, 0);
  room.draw('p1');
  room.throwHand('p1');
  assert.deepEqual(room.missedTurns, [0, 1]);
});

test('consecutive timeouts forfeit the seat and settle as a timeout', async (t) => {
  const ranked = [];
  const { room } = timedRoom(t, {
    reveal: true,
    matchType: 'random',
    onRankedEnd: (payload) => {
      ranked.push(payload);
    },
  });
  t.mock.timers.tick(TURN_MS);
  t.mock.timers.tick(TURN_MS);
  t.mock.timers.tick(TURN_MS);
  assert.equal(room.status, 'ended');
  assert.equal(room.result.reason, 'timeout');
  assert.equal(room.result.quitterIndex, 0);
  assert.equal(room.result.winnerIndex, 1);
  assert.equal(room.snapshotFor('p2').result.quitter, 'opponent');
  assert.equal(room.turnClock, null);
  await room.rankedPromise;
  assert.equal(ranked.length, 1);
  assert.equal(ranked[0].quitterIndex, 0);
  assert.equal(ranked[0].winnerIndex, 1);
});

test('maxMissedTurns of 0 never forfeits but still counts the misses', (t) => {
  const { room } = timedRoom(t, {
    reveal: true,
    turnTimerConfig: () => ({ turnMs: TURN_MS, revealMs: REVEAL_MS, maxMissedTurns: 0 }),
  });
  for (let turn = 0; turn < 4; turn += 1) t.mock.timers.tick(TURN_MS);
  assert.equal(room.status, 'playing');
  assert.deepEqual(room.missedTurns, [2, 2]);
});

test('a disconnected seat is played for but never counted', (t) => {
  const { room } = timedRoom(t, { reveal: true });
  room.markDisconnected('p1');
  t.mock.timers.tick(TURN_MS);
  assert.equal(room.turnIndex, 1);
  assert.deepEqual(room.missedTurns, [0, 0]);
  assert.equal(room.status, 'playing');
});

test('bot seats get a display-only clock that is never enforced', (t) => {
  t.mock.timers.enable({ apis: ['setTimeout'] });
  const room = new GameRoom('CLOCK2', {
    random: () => 0.75,
    turnTimerConfig: () => ({ turnMs: TURN_MS, revealMs: REVEAL_MS, maxMissedTurns: 1 }),
    turnGraceMs: 0,
    launchRevealMs: LAUNCH_MS,
  });
  room.addPlayer('p1');
  room.addPlayer('bot', { isBot: true });
  room.start('p1');
  t.after(() => room.dispose());
  room.launch('p1');
  room.launch('bot');
  t.mock.timers.tick(LAUNCH_MS);
  assert.equal(room.turnIndex, 1);
  assert.ok(room.snapshotFor('p1').turnTimer);
  t.mock.timers.tick(TURN_MS);
  assert.equal(room.turnIndex, 1);
  assert.deepEqual(room.missedTurns, [0, 0]);
  assert.equal(room.status, 'playing');
});

test('a changed limit applies from the next turn', (t) => {
  let turnMs = TURN_MS;
  const { room } = timedRoom(t, {
    reveal: true,
    turnTimerConfig: () => ({ turnMs, revealMs: REVEAL_MS, maxMissedTurns: 2 }),
  });
  turnMs = 300;
  t.mock.timers.tick(TURN_MS);
  assert.equal(room.snapshotFor('p1').turnTimer.limitMs, 300);
  t.mock.timers.tick(300);
  assert.deepEqual(room.missedTurns, [1, 1]);
});

test('turning the limit off mid-turn stops the clock without any move', (t) => {
  let enabled = true;
  const { room } = timedRoom(t, {
    reveal: true,
    turnTimerConfig: () =>
      enabled ? { turnMs: TURN_MS, revealMs: REVEAL_MS, maxMissedTurns: 2 } : null,
  });
  enabled = false;
  t.mock.timers.tick(TURN_MS);
  assert.equal(room.turnClock, null);
  assert.deepEqual(room.missedTurns, [0, 0]);
  assert.equal(room.turnIndex, 0);
  assert.equal(room.snapshotFor('p1').turnTimer, null);
});

test('an ability lock at expiry defers the timeout, and the lock ends the turn', (t) => {
  const { room } = timedRoom(t, { reveal: true, peekDurationMs: 1500 });
  room.players[0].handCard = JACK;
  room.players[0].jackPeekAvailable = true;
  room.jackPeek('p1', { side: 'opponent', cardIndex: 0 });
  t.mock.timers.tick(TURN_MS);
  assert.deepEqual(room.missedTurns, [0, 0]);
  assert.equal(room.turnIndex, 0);
  t.mock.timers.tick(500);
  assert.equal(room.turnIndex, 1);
  assert.deepEqual(room.missedTurns, [0, 0]);
});

test('a reconnect keeps an ability lock on its seat', (t) => {
  const { room } = timedRoom(t, { reveal: true, peekDurationMs: 200 });
  room.players[0].handCard = JACK;
  room.players[0].jackPeekAvailable = true;
  room.jackPeek('p1', { side: 'opponent', cardIndex: 0 });
  room.reconnectPlayer('p1', 'p1-new');
  assert.equal(room.activePeek.viewerId, 'p1-new');
  t.mock.timers.tick(200);
  assert.equal(room.turnIndex, 1);
});

test('a seat that never reveals is revealed automatically', (t) => {
  const { room } = timedRoom(t);
  t.mock.timers.tick(REVEAL_MS);
  assert.ok(room.players.every((player) => player.launch === 'launched'));
  t.mock.timers.tick(LAUNCH_MS);
  assert.ok(room.players.every((player) => player.launch === 'ended'));
  assert.ok(room.turnClock);
});

test('a rematch starts with clean miss counts and a fresh reveal', (t) => {
  const { room } = timedRoom(t, { reveal: true });
  t.mock.timers.tick(TURN_MS);
  assert.deepEqual(room.missedTurns, [1, 0]);
  room.end('p2');
  room.rematch('p1');
  room.rematch('p2');
  assert.equal(room.status, 'playing');
  assert.deepEqual(room.missedTurns, [0, 0]);
  assert.equal(room.turnClock, null);
  assert.ok(room.revealTimer);
});

test('end() is rejected once the match is no longer running', (t) => {
  const { room } = timedRoom(t, { reveal: true });
  room.end('p1');
  assert.throws(
    () => room.end('p2'),
    (error) => error instanceof GameRuleError && error.code === 'not_playing',
  );
});

test('disposing a room stops every clock', (t) => {
  const { room } = timedRoom(t, { reveal: true });
  const version = room.version;
  room.dispose();
  t.mock.timers.tick(TURN_MS * 3);
  assert.equal(room.version, version);
  assert.equal(room.turnClock, null);
});
