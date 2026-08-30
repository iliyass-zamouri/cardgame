const test = require('node:test');
const assert = require('node:assert/strict');
const WebSocket = require('ws');
const { GameServer } = require('../game_server');
const { acquireBotUser } = require('../db/bots');
const { ServerRobotPlayer } = require('../bot_player');
const { GameRoom } = require('../game_room');

test('acquireBotUser returns valid bot identity without database', async () => {
  const active = new Set(['bot-1']);
  const bot = await acquireBotUser(active);
  assert.ok(bot.playerId);
  assert.ok(bot.displayName);
  assert.ok(bot.username);
  assert.equal(bot.elo, 1000);
  assert.notEqual(bot.playerId, 'bot-1');
});

test('findMatch triggers bot match after queue timeout', async (t) => {
  const server = new GameServer({
    port: 0,
    botMatchMinDelayMs: 30,
    botMatchMaxDelayMs: 60,
  });
  const address = await server.start();
  t.after(() => server.stop());

  const client = await connect(address.port);
  t.after(() => client.close());

  const playingPromise = waitFor(
    client,
    (msg) => msg.type === 'snapshot' && msg.status === 'playing',
    3000,
  );

  client.send(JSON.stringify({
    type: 'findMatch',
    playerId: 'p-human-1',
    displayName: 'Alice',
  }));

  const game = await playingPromise;
  assert.equal(game.status, 'playing');
  assert.equal(game.matchType, 'random');
  assert.equal(game.you.displayName, 'Alice');
  assert.ok(game.opponent.displayName);
  assert.equal(server.activeBotPlayerIds.size, 1);
});

test('cancelFindMatch clears timer and stops bot match', async (t) => {
  const server = new GameServer({
    port: 0,
    botMatchMinDelayMs: 60,
    botMatchMaxDelayMs: 100,
  });
  const address = await server.start();
  t.after(() => server.stop());

  const client = await connect(address.port);
  t.after(() => client.close());

  const leftQueuePromise = waitFor(
    client,
    (msg) => msg.type === 'leftQueue',
    2000,
  );

  client.send(JSON.stringify({
    type: 'findMatch',
    playerId: 'p-human-cancel',
    displayName: 'Bob',
  }));

  await new Promise((resolve) => setTimeout(resolve, 20));
  client.send(JSON.stringify({ type: 'cancelFindMatch' }));
  await leftQueuePromise;

  assert.equal(server.matchQueue.length, 0);
  assert.equal(server.matchTimers.size, 0);

  // Wait beyond timeout to verify bot is not spawned
  await new Promise((resolve) => setTimeout(resolve, 120));
  assert.equal(server.rooms.size, 0);
  assert.equal(server.activeBotPlayerIds.size, 0);
});

test('two human players join before timer and pair without bot', async (t) => {
  const server = new GameServer({
    port: 0,
    botMatchMinDelayMs: 300,
    botMatchMaxDelayMs: 500,
  });
  const address = await server.start();
  t.after(() => server.stop());

  const first = await connect(address.port);
  const second = await connect(address.port);
  t.after(() => first.close());
  t.after(() => second.close());

  const firstPlaying = waitFor(
    first,
    (msg) => msg.type === 'snapshot' && msg.status === 'playing',
    2000,
  );
  const secondPlaying = waitFor(
    second,
    (msg) => msg.type === 'snapshot' && msg.status === 'playing',
    2000,
  );

  first.send(JSON.stringify({
    type: 'findMatch',
    playerId: 'h1',
    displayName: 'Human1',
  }));
  second.send(JSON.stringify({
    type: 'findMatch',
    playerId: 'h2',
    displayName: 'Human2',
  }));

  const [firstGame, secondGame] = await Promise.all([firstPlaying, secondPlaying]);
  assert.equal(firstGame.roomId, secondGame.roomId);
  assert.equal(firstGame.opponent.displayName, 'Human2');
  assert.equal(secondGame.opponent.displayName, 'Human1');
  assert.equal(server.activeBotPlayerIds.size, 0);
  assert.equal(server.roomBots.size, 0);
});

test('ServerRobotPlayer auto-launches and responds to room changes', async () => {
  let bot;
  const room = new GameRoom('ROOM1', {
    onChange: (r) => bot?.onRoomChanged(),
  });

  room.addPlayer('human', { playerId: 'p1', displayName: 'Human' });
  room.addPlayer('bot-client', { playerId: 'bot-1', displayName: 'Bot' });

  bot = new ServerRobotPlayer({
    room,
    clientId: 'bot-client',
    launchDelayMs: 10,
    actionDelayMs: 20,
    thinkMinMs: 10,
    thinkMaxMs: 20,
  });

  room.start('human');
  assert.equal(room.status, 'playing');

  // Human launches
  room.launch('human');

  // Wait for bot to launch
  await new Promise((resolve) => setTimeout(resolve, 50));
  assert.equal(room.players.find((p) => p.id === 'bot-client').launch, 'launched');

  bot.dispose();
});

test('ServerRobotPlayer takes turn when it is bot turn', async () => {
  let bot;
  const room = new GameRoom('ROOM2', {
    onChange: (r) => bot?.onRoomChanged(),
  });

  room.addPlayer('human', { playerId: 'p1', displayName: 'Human' });
  room.addPlayer('bot-client', { playerId: 'bot-1', displayName: 'Bot' });

  bot = new ServerRobotPlayer({
    room,
    clientId: 'bot-client',
    launchDelayMs: 5,
    actionDelayMs: 15,
    thinkMinMs: 5,
    thinkMaxMs: 10,
  });

  room.start('human');
  // Set both launch ended
  room.players[0].launch = 'ended';
  room.players[1].launch = 'ended';
  // Force turn to bot
  room.turnIndex = 1;
  const initialDeck = room.deck.length;

  bot.onRoomChanged();

  // Wait for bot think & action
  await new Promise((resolve) => setTimeout(resolve, 60));

  // Bot should have taken an action (either drew or played card)
  assert.ok(room.deck.length < initialDeck || room.discard.length > 0 || room.turnIndex !== 1);

  bot.dispose();
});

test('abandoned bot room cleans up bot runner and activeBotPlayerIds', async (t) => {
  const server = new GameServer({
    port: 0,
    botMatchMinDelayMs: 20,
    botMatchMaxDelayMs: 30,
  });
  const address = await server.start();
  t.after(() => server.stop());

  const client = await connect(address.port);

  const playingPromise = waitFor(
    client,
    (msg) => msg.type === 'snapshot' && msg.status === 'playing',
    2000,
  );

  client.send(JSON.stringify({
    type: 'findMatch',
    playerId: 'p-disconnect',
    displayName: 'DisconnectingUser',
  }));

  await playingPromise;
  assert.equal(server.rooms.size, 1);
  assert.equal(server.activeBotPlayerIds.size, 1);
  assert.equal(server.roomBots.size, 1);

  // Client disconnects
  client.close();
  await new Promise((resolve) => setTimeout(resolve, 50));

  assert.equal(server.rooms.size, 0);
  assert.equal(server.activeBotPlayerIds.size, 0);
  assert.equal(server.roomBots.size, 0);
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
