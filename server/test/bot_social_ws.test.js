const test = require('node:test');
const assert = require('node:assert/strict');
const WebSocket = require('ws');
const { GameServer } = require('../game_server');
const { testToken } = require('./session_helpers');

test('bot always answers chat in a bot match', async (t) => {
  const server = new GameServer({ port: 0, botMatchMinDelayMs: 20, botMatchMaxDelayMs: 40 });
  const address = await server.start();
  t.after(() => server.stop());
  const client = await connect(address.port);
  t.after(() => client.close());

  const playing = waitFor(client, (m) => m.type === 'snapshot' && m.status === 'playing', 3000);
  client.send(JSON.stringify({ type: 'findMatch', token: await testToken('human-chat') }));
  const game = await playing;
  const botPlayerId = game.opponent.playerId;
  assert.ok(botPlayerId);

  const reply = waitFor(
    client,
    (m) => m.type === 'chatMessage' && m.fromPlayerId === botPlayerId,
    6000,
  );
  client.send(JSON.stringify({ type: 'chatSend', kind: 'phrase', phraseId: 'hello' }));
  const message = await reply;
  assert.ok(['phrase', 'emoji'].includes(message.kind));
});

test('a bot hosts a private table, invites a player and plays', async (t) => {
  const server = new GameServer({ port: 0 });
  const address = await server.start();
  t.after(() => server.stop());
  const client = await connect(address.port);
  t.after(() => client.close());

  const ack = waitFor(client, (m) => m.type === 'identityAck' || m.type === 'error');
  client.send(JSON.stringify({ type: 'identity', token: await testToken('human-host') }));
  await ack;

  const invited = waitFor(client, (m) => m.type === 'tableInviteReceived');
  assert.equal(
    await server.hostBotInviteForTest({ botId: 'bot-host', humanId: 'human-host', ttlMs: 60_000 }),
    true,
  );
  const invite = await invited;
  assert.equal(invite.inviterPlayerId, 'bot-host');
  assert.ok(server.activeBotPlayerIds.has('bot-host'));

  const lobby = waitFor(client, (m) => m.type === 'snapshot' && m.opponent);
  client.send(JSON.stringify({ type: 'joinRoom', roomId: invite.roomId, token: await testToken('human-host') }));
  const joined = await lobby;
  assert.equal(joined.matchType, 'private');

  const playing = waitFor(client, (m) => m.type === 'snapshot' && m.status === 'playing', 5000);
  client.send(JSON.stringify({ type: 'ready' }));
  await playing;
});

test('an unanswered bot invite closes and frees the bot', async (t) => {
  const server = new GameServer({ port: 0 });
  await server.start();
  t.after(() => server.stop());

  await server.hostBotInviteForTest({ botId: 'bot-lonely', humanId: 'nobody', ttlMs: 50 });
  assert.equal(server.rooms.size, 1);
  await new Promise((resolve) => setTimeout(resolve, 120));
  assert.equal(server.rooms.size, 0);
  assert.equal(server.activeBotPlayerIds.has('bot-lonely'), false);
});

test('a bot friend joins the player table and readies up', async (t) => {
  const server = new GameServer({ port: 0 });
  const address = await server.start();
  t.after(() => server.stop());
  const client = await connect(address.port);
  t.after(() => client.close());

  const created = waitFor(client, (m) => m.type === 'snapshot');
  client.send(JSON.stringify({ type: 'createRoom', token: await testToken('human-guest') }));
  const { roomId } = await created;

  const seated = waitFor(client, (m) => m.type === 'snapshot' && m.opponent?.playerId === 'bot-friend');
  await server.botJoinHumanRoomForTest({ botId: 'bot-friend', humanId: 'human-guest', roomId });
  await seated;

  const playing = waitFor(client, (m) => m.type === 'snapshot' && m.status === 'playing', 5000);
  client.send(JSON.stringify({ type: 'ready' }));
  await playing;
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
