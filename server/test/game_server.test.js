const test = require('node:test');
const assert = require('node:assert/strict');
const WebSocket = require('ws');
const { GameServer } = require('../game_server');
const { GameRoom } = require('../game_room');

test('two clients create, join, and start an isolated room', async (t) => {
  const server = new GameServer({ port: 0 });
  const address = await server.start();
  t.after(() => server.stop());

  const first = await connect(address.port);
  const second = await connect(address.port);
  t.after(() => first.close());
  t.after(() => second.close());

  const created = waitFor(first, (message) => message.type === 'snapshot');
  first.send(JSON.stringify({ type: 'createRoom' }));
  const firstWaiting = await created;
  assert.match(firstWaiting.roomId, /^[A-F0-9]{6}$/);
  assert.equal(firstWaiting.ready, false);

  const firstReady = waitFor(
    first,
    (message) => message.type === 'snapshot' && message.ready,
  );
  const secondReady = waitFor(
    second,
    (message) => message.type === 'snapshot' && message.ready,
  );
  second.send(JSON.stringify({
    type: 'joinRoom',
    roomId: firstWaiting.roomId,
  }));
  await Promise.all([firstReady, secondReady]);

  const firstPlaying = waitFor(
    first,
    (message) => message.type === 'snapshot' && message.status === 'playing',
  );
  const secondPlaying = waitFor(
    second,
    (message) => message.type === 'snapshot' && message.status === 'playing',
  );
  first.send(JSON.stringify({ type: 'startGame' }));
  // One ready is not enough — still waiting.
  await new Promise((resolve) => setTimeout(resolve, 50));
  second.send(JSON.stringify({ type: 'startGame' }));
  const [firstGame, secondGame] = await Promise.all([
    firstPlaying,
    secondPlaying,
  ]);

  assert.equal(firstGame.roomId, secondGame.roomId);
  assert.equal(firstGame.deckCount, 46);
  assert.equal(secondGame.deckCount, 46);
  assert.equal(firstGame.you.cards.length, 4);
  assert.equal(secondGame.you.cards.length, 4);
});

test('findMatch queues two clients and auto-starts', async (t) => {
  const server = new GameServer({ port: 0 });
  const address = await server.start();
  t.after(() => server.stop());

  const first = await connect(address.port);
  const second = await connect(address.port);
  t.after(() => first.close());
  t.after(() => second.close());

  const firstPlaying = waitFor(
    first,
    (message) => message.type === 'snapshot' && message.status === 'playing',
  );
  const secondPlaying = waitFor(
    second,
    (message) => message.type === 'snapshot' && message.status === 'playing',
  );

  first.send(JSON.stringify({
    type: 'findMatch',
    playerId: 'guest-a',
    displayName: 'Ace',
  }));
  second.send(JSON.stringify({
    type: 'findMatch',
    playerId: 'guest-b',
    displayName: 'King',
  }));

  const [a, b] = await Promise.all([firstPlaying, secondPlaying]);
  assert.equal(a.roomId, b.roomId);
  assert.equal(a.matchType, 'random');
  assert.equal(b.matchType, 'random');
  assert.equal(a.you.cards.length, 4);
  assert.equal(a.you.seriesWins, 0);
});

test('cancelFindMatch leaves queue', async (t) => {
  const server = new GameServer({ port: 0 });
  const address = await server.start();
  t.after(() => server.stop());

  const first = await connect(address.port);
  t.after(() => first.close());

  const left = waitFor(first, (message) => message.type === 'leftQueue');
  first.send(JSON.stringify({ type: 'findMatch', displayName: 'Solo' }));
  first.send(JSON.stringify({ type: 'cancelFindMatch' }));
  await left;
  assert.equal(server.matchQueue.length, 0);
});

test('lobby ready requires both players then auto-starts', () => {
  const room = new GameRoom('READY1', { random: () => 0.2 });
  room.addPlayer('p1', { displayName: 'A' });
  room.addPlayer('p2', { displayName: 'B' });

  room.ready('p1');
  assert.equal(room.status, 'waiting');
  assert.equal(room.lobbyReady[0], true);
  assert.equal(room.lobbyReady[1], false);
  assert.equal(room.snapshotFor('p1').you.lobbyReady, true);
  assert.equal(room.snapshotFor('p1').opponent.lobbyReady, false);

  room.ready('p2');
  assert.equal(room.status, 'playing');
  assert.equal(room.lobbyReady[0], false);
  assert.equal(room.lobbyReady[1], false);
});

test('rematch requires both players and preserves series wins', () => {
  const room = new GameRoom('RMATCH', { random: () => 0.1 });
  room.addPlayer('p1', { displayName: 'A' });
  room.addPlayer('p2', { displayName: 'B' });
  room.start('p1');
  room.players[0].cards = ['A1'];
  room.players[1].cards = ['A5', 'A6'];
  room.end('p1');

  assert.equal(room.status, 'ended');
  assert.equal(room.seriesWins[0], 1);
  assert.equal(room.seriesWins[1], 0);

  room.rematch('p1');
  assert.equal(room.status, 'ended');
  assert.equal(room.rematchReady[0], true);
  assert.equal(room.rematchReady[1], false);

  const snap = room.snapshotFor('p1');
  assert.equal(snap.you.rematchReady, true);
  assert.equal(snap.opponent.rematchReady, false);
  assert.equal(snap.you.seriesWins, 1);
  assert.equal(snap.opponent.seriesWins, 0);

  room.rematch('p2');
  assert.equal(room.status, 'playing');
  assert.equal(room.seriesWins[0], 1);
  assert.equal(room.seriesWins[1], 0);
  assert.equal(room.rematchReady[0], false);
  assert.equal(room.rematchReady[1], false);
});

test('tableInvite relays invitation to online target player and acknowledges sender', async (t) => {
  const server = new GameServer({ port: 0 });
  const address = await server.start();
  t.after(() => server.stop());

  const host = await connect(address.port);
  const friend = await connect(address.port);
  t.after(() => host.close());
  t.after(() => friend.close());

  // Establish friend identity
  const friendAck = waitFor(friend, (m) => m.type === 'identityAck');
  friend.send(JSON.stringify({
    type: 'identity',
    playerId: 'friend-123',
    displayName: 'Bob',
  }));
  await friendAck;

  // Host creates private room
  const created = waitFor(host, (message) => message.type === 'snapshot');
  host.send(JSON.stringify({
    type: 'createRoom',
    playerId: 'host-456',
    displayName: 'Alice',
  }));
  const hostWaiting = await created;

  const inviteReceivedPromise = waitFor(
    friend,
    (message) => message.type === 'tableInviteReceived',
  );
  const inviteSentPromise = waitFor(
    host,
    (message) => message.type === 'tableInviteSent',
  );

  host.send(JSON.stringify({
    type: 'tableInvite',
    targetPlayerId: 'friend-123',
    roomId: hostWaiting.roomId,
  }));

  const received = await inviteReceivedPromise;
  const sent = await inviteSentPromise;

  assert.equal(received.type, 'tableInviteReceived');
  assert.equal(received.roomId, hostWaiting.roomId);
  assert.equal(received.inviterName, 'Alice');
  assert.equal(received.inviterPlayerId, 'host-456');

  assert.equal(sent.type, 'tableInviteSent');
  assert.equal(sent.targetPlayerId, 'friend-123');
  assert.equal(sent.delivered, true);
});

async function connect(port) {
  const socket = new WebSocket(`ws://127.0.0.1:${port}`);
  await new Promise((resolve, reject) => {
    socket.once('open', resolve);
    socket.once('error', reject);
  });
  return socket;
}

function waitFor(socket, predicate, timeout = 2000) {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => {
      socket.off('message', onMessage);
      reject(new Error('Timed out waiting for server message'));
    }, timeout);
    function onMessage(raw) {
      try {
        const message = JSON.parse(raw.toString());
        if (!predicate(message)) return;
        clearTimeout(timer);
        socket.off('message', onMessage);
        resolve(message);
      } catch (err) {
        // ignore JSON parse error in test harness
      }
    }
    socket.on('message', onMessage);
  });
}
