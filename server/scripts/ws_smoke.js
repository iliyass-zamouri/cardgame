import WebSocket from 'ws';

const BASE = process.env.BASE_URL ?? 'http://127.0.0.1:8080';
const WS_BASE = BASE.replace(/^http/, 'ws');

async function guestAuth(label) {
  const res = await fetch(`${BASE}/auth/guest`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ deviceId: `smoke-${label}-${Date.now()}`, displayName: label }),
  });
  if (!res.ok) throw new Error(`auth failed ${res.status}`);
  const body = await res.json();
  return { token: body.token, playerId: body.player.playerId };
}

function connectWs(token) {
  return new Promise((resolve, reject) => {
    const ws = new WebSocket(`${WS_BASE}/ws?token=${encodeURIComponent(token)}`);
    const inbox = [];
    ws.on('open', () => resolve({ ws, inbox }));
    ws.on('message', (raw) => {
      inbox.push(JSON.parse(raw.toString()));
    });
    ws.on('error', reject);
  });
}

function waitFor(inbox, event, timeoutMs = 8000) {
  return new Promise((resolve, reject) => {
    const start = Date.now();
    const tick = () => {
      const hit = inbox.find((m) => m.event === event);
      if (hit) return resolve(hit);
      if (Date.now() - start > timeoutMs) {
        return reject(new Error(`timeout waiting for ${event}`));
      }
      setTimeout(tick, 50);
    };
    tick();
  });
}

function send(ws, event, payload) {
  ws.send(JSON.stringify({ event, payload }));
}

async function main() {
  const a = await guestAuth('A');
  const b = await guestAuth('B');
  const clientA = await connectWs(a.token);
  const clientB = await connectWs(b.token);

  send(clientA.ws, 'match.queue', { playerId: a.playerId, stake: 100, displayName: 'A' });
  send(clientB.ws, 'match.queue', { playerId: b.playerId, stake: 100, displayName: 'B' });

  const foundA = await waitFor(clientA.inbox, 'match.found');
  const foundB = await waitFor(clientB.inbox, 'match.found');
  if (!foundA.payload.matchId || foundA.payload.matchId !== foundB.payload.matchId) {
    throw new Error('match ids mismatch');
  }

  const snapA = await waitFor(clientA.inbox, 'match.snapshot');
  if (snapA.payload.phase !== 'reveal') {
    throw new Error(`expected reveal phase, got ${snapA.payload.phase}`);
  }

  send(clientA.ws, 'card.action', { type: 'launch' });
  send(clientB.ws, 'card.action', { type: 'launch' });

  let playing = false;
  for (let i = 0; i < 20; i += 1) {
    await new Promise((r) => setTimeout(r, 500));
    const snap = [...clientA.inbox].reverse().find((m) => m.event === 'match.snapshot');
    if (snap?.payload.phase === 'playing') {
      playing = true;
      break;
    }
  }
  if (!playing) throw new Error('never entered playing phase');

  clientA.ws.close();
  clientB.ws.close();
  console.log('WS smoke OK');
}

main().catch((err) => {
  console.error('WS smoke FAILED', err);
  process.exit(1);
});
