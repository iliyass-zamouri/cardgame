const test = require('node:test');
const assert = require('node:assert/strict');
const WebSocket = require('ws');
const { GameServer } = require('../game_server');

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

  const firstStarted = waitFor(
    first,
    (message) => message.type === 'snapshot' && message.status === 'playing',
  );
  const secondStarted = waitFor(
    second,
    (message) => message.type === 'snapshot' && message.status === 'playing',
  );
  first.send(JSON.stringify({ type: 'startGame' }));
  const [firstGame, secondGame] = await Promise.all([
    firstStarted,
    secondStarted,
  ]);

  assert.equal(firstGame.roomId, secondGame.roomId);
  assert.equal(firstGame.deckCount, 46);
  assert.equal(secondGame.deckCount, 46);
  assert.equal(firstGame.you.cards.length, 4);
  assert.equal(secondGame.you.cards.length, 4);
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
      const message = JSON.parse(raw.toString());
      if (!predicate(message)) return;
      clearTimeout(timer);
      socket.off('message', onMessage);
      resolve(message);
    }
    socket.on('message', onMessage);
  });
}
