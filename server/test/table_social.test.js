const test = require('node:test');
const assert = require('node:assert/strict');
const WebSocket = require('ws');
const { GameServer } = require('../game_server');
const { testToken } = require('./session_helpers');
const {
  sanitizeText,
  filterProfanity,
  validateChatCommand,
  validateVoiceSignal,
  ChatLimiter,
  MAX_TEXT_LENGTH,
} = require('../chat/room_chat');
const { turnCredential, buildIceServers } = require('../voice/turn_credentials');

test('sanitizeText trims, collapses whitespace and caps length', () => {
  assert.equal(sanitizeText('  hi \n\t there\u0000 '), 'hi there');
  assert.equal(sanitizeText(42), '');
  assert.equal(Array.from(sanitizeText('😀'.repeat(500))).length, MAX_TEXT_LENGTH);
});

test('filterProfanity masks whole words only, across languages', () => {
  assert.equal(filterProfanity('what the fuck'), 'what the ****');
  assert.equal(filterProfanity('Putain de carte'), '****** de carte');
  assert.equal(filterProfanity('ya qahba'), 'ya *****');
  assert.equal(filterProfanity('أنت قحبة'), 'أنت ****');
  assert.equal(filterProfanity('Scunthorpe classic shitake'), 'Scunthorpe classic shitake');
});

test('validateChatCommand accepts allowlisted ids and cleaned text', () => {
  assert.deepEqual(validateChatCommand({ kind: 'phrase', phraseId: 'wellPlayed' }), {
    kind: 'phrase',
    phraseId: 'wellPlayed',
  });
  assert.deepEqual(validateChatCommand({ kind: 'emoji', emojiId: 'laugh' }), {
    kind: 'emoji',
    emojiId: 'laugh',
  });
  assert.deepEqual(validateChatCommand({ kind: 'text', text: ' gg  shit ' }), {
    kind: 'text',
    text: 'gg ****',
  });
  assert.equal(validateChatCommand({ kind: 'phrase', phraseId: 'nope' }), null);
  assert.equal(validateChatCommand({ kind: 'emoji', emojiId: '<script>' }), null);
  assert.equal(validateChatCommand({ kind: 'text', text: '   ' }), null);
  assert.equal(validateChatCommand({ kind: 'other' }), null);
});

test('ChatLimiter allows a burst then refills over time', () => {
  let now = 0;
  const limiter = new ChatLimiter({ burst: 3, refillMs: 1500, now: () => now });
  assert.equal(limiter.tryConsume(), true);
  assert.equal(limiter.tryConsume(), true);
  assert.equal(limiter.tryConsume(), true);
  assert.equal(limiter.tryConsume(), false);
  now += 1500;
  assert.equal(limiter.tryConsume(), true);
  assert.equal(limiter.tryConsume(), false);
});

test('validateVoiceSignal keeps only known fields', () => {
  assert.deepEqual(validateVoiceSignal({ kind: 'offer', sdp: 'v=0', extra: 1 }), {
    kind: 'offer',
    sdp: 'v=0',
  });
  assert.deepEqual(
    validateVoiceSignal({ kind: 'ice', candidate: { candidate: 'candidate:1', sdpMid: '0', sdpMLineIndex: 0 } }),
    { kind: 'ice', candidate: { candidate: 'candidate:1', sdpMid: '0', sdpMLineIndex: 0 } },
  );
  assert.deepEqual(validateVoiceSignal({ kind: 'hangup' }), { kind: 'hangup' });
  assert.equal(validateVoiceSignal({ kind: 'offer', sdp: 'x'.repeat(20000) }), null);
  assert.equal(validateVoiceSignal({ kind: 'ice' }), null);
  assert.equal(validateVoiceSignal({ kind: 'bogus' }), null);
});

test('turnCredential follows the coturn REST scheme', () => {
  const { username, credential } = turnCredential({
    secret: 'secret',
    playerId: 'p1',
    ttlSeconds: 60,
    nowMs: 1_000_000,
  });
  assert.equal(username, '1060:p1');
  assert.equal(credential, require('crypto').createHmac('sha1', 'secret').update('1060:p1').digest('base64'));
});

test('buildIceServers falls back to STUN when TURN is not configured', () => {
  const stunOnly = buildIceServers({ playerId: 'p1', env: {} });
  assert.equal(stunOnly.iceServers.length, 1);
  assert.ok(stunOnly.iceServers[0].urls[0].startsWith('stun:'));

  const withTurn = buildIceServers({
    playerId: 'p1',
    env: { TURN_URLS: 'turn:1.2.3.4:3478?transport=udp,turn:1.2.3.4:3478?transport=tcp', TURN_SHARED_SECRET: 's' },
  });
  assert.deepEqual(withTurn.iceServers[0].urls, ['stun:1.2.3.4:3478']);
  assert.equal(withTurn.iceServers[1].urls.length, 2);
  assert.ok(withTurn.iceServers[1].username.endsWith(':p1'));
});

test('chat messages reach both seats; voice signals reach only the peer', async (t) => {
  const server = new GameServer({ port: 0 });
  const address = await server.start();
  t.after(() => server.stop());
  const { host, guest } = await joinedPair(address.port, t);

  const hostGot = waitFor(host, (m) => m.type === 'chatMessage');
  const guestGot = waitFor(guest, (m) => m.type === 'chatMessage');
  host.send(JSON.stringify({ type: 'chatSend', kind: 'phrase', phraseId: 'goodLuck' }));
  const [a, b] = await Promise.all([hostGot, guestGot]);
  assert.equal(a.id, b.id);
  assert.equal(b.fromPlayerId, 'chat-host');
  assert.equal(b.phraseId, 'goodLuck');

  const masked = waitFor(guest, (m) => m.type === 'chatMessage' && m.kind === 'text');
  host.send(JSON.stringify({ type: 'chatSend', kind: 'text', text: 'fuck this hand' }));
  assert.equal((await masked).text, '**** this hand');

  let hostEcho = false;
  host.on('message', (raw) => {
    if (JSON.parse(raw.toString()).type === 'voiceSignal') hostEcho = true;
  });
  const signal = waitFor(guest, (m) => m.type === 'voiceSignal');
  host.send(JSON.stringify({ type: 'voiceSignal', signal: { kind: 'offer', sdp: 'v=0' } }));
  const relayed = await signal;
  assert.equal(relayed.fromPlayerId, 'chat-host');
  assert.deepEqual(relayed.signal, { kind: 'offer', sdp: 'v=0' });

  const micState = waitFor(host, (m) => m.type === 'voiceState');
  guest.send(JSON.stringify({ type: 'voiceState', micOn: true }));
  assert.equal((await micState).micOn, true);
  assert.equal(hostEcho, false);
});

test('invalid and flooding chat commands are rejected', async (t) => {
  const server = new GameServer({ port: 0 });
  const address = await server.start();
  t.after(() => server.stop());
  const { host } = await joinedPair(address.port, t);

  const invalid = waitFor(host, (m) => m.type === 'error');
  host.send(JSON.stringify({ type: 'chatSend', kind: 'phrase', phraseId: 'notAPhrase' }));
  assert.equal((await invalid).code, 'chat_invalid');

  const limited = waitFor(host, (m) => m.type === 'error' && m.code === 'chat_rate_limited');
  for (let i = 0; i < 5; i += 1) {
    host.send(JSON.stringify({ type: 'chatSend', kind: 'emoji', emojiId: 'clap' }));
  }
  await limited;
});

test('chat outside a room is rejected', async (t) => {
  const server = new GameServer({ port: 0 });
  const address = await server.start();
  t.after(() => server.stop());
  const client = await connect(address.port);
  t.after(() => client.close());

  const error = waitFor(client, (m) => m.type === 'error');
  client.send(JSON.stringify({ type: 'chatSend', kind: 'emoji', emojiId: 'clap' }));
  assert.equal((await error).code, 'not_in_room');
});

async function joinedPair(port, t) {
  const host = await connect(port);
  const guest = await connect(port);
  t.after(() => host.close());
  t.after(() => guest.close());

  const created = waitFor(host, (m) => m.type === 'snapshot');
  host.send(JSON.stringify({ type: 'createRoom', token: await testToken('chat-host') }));
  const { roomId } = await created;

  const joined = waitFor(guest, (m) => m.type === 'snapshot');
  guest.send(JSON.stringify({ type: 'joinRoom', roomId, token: await testToken('chat-guest') }));
  await joined;
  return { host, guest };
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
      const message = JSON.parse(raw.toString());
      if (!predicate(message)) return;
      clearTimeout(timer);
      socket.off('message', onMessage);
      resolve(message);
    }
    socket.on('message', onMessage);
  });
}
