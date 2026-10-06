const test = require('node:test');
const assert = require('node:assert/strict');
const WebSocket = require('ws');
const { GameServer } = require('../game_server');
const { testToken } = require('./session_helpers');
const { signSession } = require('../auth/session');
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
  first.send(JSON.stringify({ type: 'createRoom', token: await authToken('host-room') }));
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
    token: await authToken('guest-join'),
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
    displayName: 'Ace',
    token: await authToken('guest-a'),
  }));
  second.send(JSON.stringify({
    type: 'findMatch',
    displayName: 'King',
    token: await authToken('guest-b'),
  }));

  const [a, b] = await Promise.all([firstPlaying, secondPlaying]);
  assert.equal(a.roomId, b.roomId);
  assert.equal(a.matchType, 'random');
  assert.equal(b.matchType, 'random');
  assert.equal(a.you.cards.length, 4);
  assert.equal(a.you.seriesWins, 0);
});

test('findMatch pairs chip pots and tags the room with the currency', async (t) => {
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
  for (const [socket, name] of [[first, 'chip-a'], [second, 'chip-b']]) {
    socket.send(JSON.stringify({
      type: 'findMatch',
      stakePool: 10,
      stakeCurrency: 'chips',
      token: await authToken(name),
    }));
  }

  const [a, b] = await Promise.all([firstPlaying, secondPlaying]);
  assert.equal(a.roomId, b.roomId);
  assert.equal(a.stakePool, 10);
  assert.equal(a.stakePerPlayer, 5);
  assert.equal(a.stakeCurrency, 'chips');
});

test('findMatch keeps money and chip pots of the same size apart', async (t) => {
  const server = new GameServer({ port: 0 });
  const address = await server.start();
  t.after(() => server.stop());

  const first = await connect(address.port);
  const second = await connect(address.port);
  t.after(() => first.close());
  t.after(() => second.close());

  first.send(JSON.stringify({
    type: 'findMatch',
    stakePool: 50,
    token: await authToken('money-50'),
  }));
  second.send(JSON.stringify({
    type: 'findMatch',
    stakePool: 50,
    stakeCurrency: 'chips',
    token: await authToken('chips-50'),
  }));
  await new Promise((resolve) => setTimeout(resolve, 100));

  assert.equal(server.matchQueue.length, 2);
  assert.deepEqual(
    server.matchQueue.map((ctx) => ctx.stakeCurrency).sort(),
    ['chips', 'money'],
  );
});

test('cancelFindMatch leaves queue', async (t) => {
  const server = new GameServer({ port: 0 });
  const address = await server.start();
  t.after(() => server.stop());

  const first = await connect(address.port);
  t.after(() => first.close());

  const left = waitFor(first, (message) => message.type === 'leftQueue');
  first.send(JSON.stringify({ type: 'findMatch', displayName: 'Solo', token: await authToken('solo') }));
  first.send(JSON.stringify({ type: 'cancelFindMatch' }));
  await left;
  assert.equal(server.matchQueue.length, 0);
});

test('leaveRoom mid random match ends it as a quit for the opponent', async (t) => {
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
  first.send(JSON.stringify({ type: 'findMatch', displayName: 'Ace', token: await authToken('quit-a') }));
  second.send(JSON.stringify({ type: 'findMatch', displayName: 'King', token: await authToken('quit-b') }));
  const [a] = await Promise.all([firstPlaying, secondPlaying]);

  const left = waitFor(first, (message) => message.type === 'leftRoom');
  const ended = waitFor(
    second,
    (message) => message.type === 'snapshot' && message.status === 'ended',
  );
  first.send(JSON.stringify({ type: 'leaveRoom' }));
  const [, opponentView] = await Promise.all([left, ended]);

  assert.equal(opponentView.roomId, a.roomId);
  assert.equal(opponentView.result.reason, 'quit');
  assert.equal(opponentView.result.quitter, 'opponent');
  const room = server.rooms.get(a.roomId);
  assert.equal(room.status, 'ended');
  assert.equal(room.players.length, 2);
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
    displayName: 'Bob',
    token: await authToken('friend-123'),
  }));
  await friendAck;

  // Host creates private room
  const created = waitFor(host, (message) => message.type === 'snapshot');
  host.send(JSON.stringify({
    type: 'createRoom',
    displayName: 'Alice',
    token: await authToken('host-456'),
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

test('friend request notify reaches online target via websocket', async (t) => {
  const server = new GameServer({ port: 0 });
  const address = await server.start();
  t.after(() => server.stop());

  const target = await connect(address.port);
  t.after(() => target.close());

  const ack = waitFor(target, (m) => m.type === 'identityAck');
  target.send(JSON.stringify({
    type: 'identity',
    displayName: 'Target',
    token: await authToken('target-player'),
  }));
  await ack;

  const receivedPromise = waitFor(
    target,
    (message) => message.type === 'friendRequestReceived',
  );

  // Invoke private notify helper through the same path HTTP handlers use.
  server.notifyPlayerForTest('target-player', {
    type: 'friendRequestReceived',
    requestId: 'friendship-test',
    fromPlayerId: 'sender-player',
    fromName: 'Sender',
    fromUsername: 'sender',
  });

  const received = await receivedPromise;
  assert.equal(received.type, 'friendRequestReceived');
  assert.equal(received.requestId, 'friendship-test');
  assert.equal(received.fromPlayerId, 'sender-player');
  assert.equal(received.fromName, 'Sender');
});


async function authToken(playerId, tokenVersion = 0) {
  return signSession({ playerId, tokenVersion });
}

async function sendAuthed(socket, payload) {
  const playerId = payload.playerId || 'guest-test';
  const token = await authToken(playerId);
  socket.send(JSON.stringify({ ...payload, token, playerId: undefined }));
}

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

function endedRandomRoom(id, beforeRematch) {
  const room = new GameRoom(id, {
    random: () => 0.1,
    onRankedEnd: () => Promise.resolve(null),
    beforeRematch,
  });
  room.matchType = 'random';
  room.stakePool = 100;
  room.stakePerPlayer = 50;
  room.potAmount = 100;
  room.escrowed = true;
  room.addPlayer('p1', { playerId: 'pa', displayName: 'A' });
  room.addPlayer('p2', { playerId: 'pb', displayName: 'B' });
  room.start('p1');
  room.players[0].cards = ['A1'];
  room.players[1].cards = ['A5'];
  room.end('p1');
  return room;
}

test('staked rematch escrows both stakes before starting', async () => {
  const calls = [];
  let release;
  const room = endedRandomRoom('STAKE1', (payload) => {
    calls.push(payload);
    return new Promise((resolve) => {
      release = () => resolve({ escrowed: true, balances: { pa: 150, pb: 30 } });
    });
  });

  room.rematch('p1');
  room.rematch('p2');
  assert.equal(room.status, 'ended');
  assert.equal(room.snapshotFor('p1').rematchPending, true);
  // A third press while pending is ignored.
  room.rematch('p2');

  await new Promise((resolve) => setImmediate(resolve));
  assert.equal(calls.length, 1);
  assert.deepEqual(calls[0].playerIds, ['pa', 'pb']);
  assert.equal(calls[0].stake, 50);

  release();
  await new Promise((resolve) => setImmediate(resolve));
  assert.equal(room.status, 'playing');
  assert.equal(room.escrowed, true);
  const snap = room.snapshotFor('p2');
  assert.equal(snap.rematchPending, false);
  assert.equal(snap.you.money, 30);
  assert.equal(snap.opponent.money, undefined);
});

test('staked rematch blocked when a player cannot cover the stake', async () => {
  const room = endedRandomRoom('STAKE2', () => {
    const error = new Error('Insufficient funds for stake');
    error.code = 'insufficient_funds';
    error.playerId = 'pb';
    error.required = 50;
    return Promise.reject(error);
  });

  room.rematch('p1');
  room.rematch('p2');
  await new Promise((resolve) => setImmediate(resolve));
  await new Promise((resolve) => setImmediate(resolve));

  assert.equal(room.status, 'ended');
  assert.deepEqual(room.rematchReady, [true, false]);
  const short = room.snapshotFor('p2');
  assert.equal(short.rematchPending, false);
  assert.deepEqual(short.rematchBlocked, {
    reason: 'insufficient_funds',
    required: 50,
    who: 'you',
  });
  assert.equal(room.snapshotFor('p1').rematchBlocked.who, 'opponent');

  // Pressing again clears the block and retries.
  room.rematch('p2');
  assert.equal(room.snapshotFor('p2').rematchBlocked, null);
});

test('ping is answered with pong', async (t) => {
  const server = new GameServer({ port: 0 });
  const address = await server.start();
  t.after(() => server.stop());

  const client = await connect(address.port);
  t.after(() => client.close());

  const pong = waitFor(client, (message) => message.type === 'pong');
  client.send(JSON.stringify({ type: 'ping', at: 42 }));
  assert.equal((await pong).at, 42);
});
