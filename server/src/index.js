import 'dotenv/config';
import http from 'node:http';
import { WebSocketServer } from 'ws';
import { closeDb, initDb, pingDb } from './infra/db.js';
import {
  claimReferral,
  claimRewardedAd,
  findOrCreateGuest,
  getPlayer,
  getShopCatalog,
  issueToken,
  listFriends,
  listPlayerMatches,
  purchaseItem,
  removeFriend,
  requestFriend,
  respondFriend,
  searchPlayers,
  upsertOAuthPlayer,
  verifyBearer,
} from './domain/store.js';
import { WsHub } from './ws/hub.js';

const port = Number.parseInt(process.env.PORT ?? '8080', 10);

function readJsonBody(req) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    req.on('data', (chunk) => chunks.push(chunk));
    req.on('end', () => {
      const raw = Buffer.concat(chunks).toString('utf8');
      if (!raw) {
        resolve({});
        return;
      }
      try {
        resolve(JSON.parse(raw));
      } catch (error) {
        reject(error);
      }
    });
    req.on('error', reject);
  });
}

function sendJson(res, status, body) {
  const payload = JSON.stringify(body);
  res.writeHead(status, {
    'content-type': 'application/json',
    'access-control-allow-origin': '*',
    'access-control-allow-methods': 'GET, POST, DELETE, OPTIONS',
    'access-control-allow-headers': 'content-type, authorization, idempotency-key',
  });
  res.end(payload);
}

function parseUrl(req) {
  return new URL(req.url ?? '/', `http://${req.headers.host ?? 'localhost'}`);
}

function playerDto(p) {
  return {
    playerId: p.public_id,
    displayName: p.display_name,
    coins: p.coins,
    gems: p.gems,
    wins: p.wins,
    losses: p.losses,
    currentStreak: p.current_streak,
    bestStreak: p.best_streak,
    referralCode: p.referral_code,
  };
}

async function requireAuth(req, res) {
  const playerId = await verifyBearer(req.headers.authorization);
  if (!playerId) {
    sendJson(res, 401, { message: 'Access token required' });
    return null;
  }
  const player = await getPlayer(playerId);
  if (!player) {
    sendJson(res, 401, { message: 'Unknown player' });
    return null;
  }
  return player;
}

async function main() {
  await initDb();
  console.log(
    `MySQL connected (${process.env.MYSQL_HOST ?? '127.0.0.1'}:${process.env.MYSQL_PORT ?? '3306'}/${process.env.MYSQL_DATABASE ?? 'cardgame'})`,
  );

  const hub = new WsHub();
  const server = http.createServer(async (req, res) => {
    if (req.method === 'OPTIONS') {
      res.writeHead(204, {
        'access-control-allow-origin': '*',
        'access-control-allow-methods': 'GET, POST, DELETE, OPTIONS',
        'access-control-allow-headers': 'content-type, authorization, idempotency-key',
      });
      res.end();
      return;
    }

    const url = parseUrl(req);

    try {
      if (url.pathname === '/healthz' || url.pathname === '/health') {
        let dbOk = false;
        try {
          dbOk = await pingDb();
        } catch {
          dbOk = false;
        }
        sendJson(res, dbOk ? 200 : 503, {
          ok: dbOk,
          db: dbOk ? 'up' : 'down',
          connections: hub.connectionCount,
          rooms: hub.roomCount,
        });
        return;
      }

      if (req.method === 'POST' && url.pathname === '/auth/guest') {
        const body = await readJsonBody(req);
        const deviceId = String(body.deviceId ?? '').trim();
        if (!deviceId || deviceId.length < 8) {
          sendJson(res, 400, { message: 'deviceId required' });
          return;
        }
        const player = await findOrCreateGuest({
          deviceId,
          displayName: body.displayName,
        });
        const token = await issueToken(player);
        sendJson(res, 200, { token, player: playerDto(player) });
        return;
      }

      if (req.method === 'POST' && url.pathname === '/auth/google') {
        const body = await readJsonBody(req);
        // Dev-friendly: accept providerSubject; production should verify idToken.
        const subject = body.providerSubject ?? body.sub ?? body.idToken;
        if (!subject) {
          sendJson(res, 400, { message: 'providerSubject required' });
          return;
        }
        const player = await upsertOAuthPlayer({
          provider: 'google',
          providerId: String(subject).slice(0, 255),
          displayName: body.displayName,
          email: body.email,
        });
        const token = await issueToken(player);
        sendJson(res, 200, { token, player: playerDto(player) });
        return;
      }

      if (req.method === 'POST' && url.pathname === '/auth/apple') {
        const body = await readJsonBody(req);
        const subject = body.providerSubject ?? body.sub ?? body.idToken;
        if (!subject) {
          sendJson(res, 400, { message: 'providerSubject required' });
          return;
        }
        const player = await upsertOAuthPlayer({
          provider: 'apple',
          providerId: String(subject).slice(0, 255),
          displayName: body.displayName,
          email: body.email,
        });
        const token = await issueToken(player);
        sendJson(res, 200, { token, player: playerDto(player) });
        return;
      }

      if (req.method === 'GET' && url.pathname === '/players/search') {
        const player = await requireAuth(req, res);
        if (!player) return;
        const q = url.searchParams.get('q') ?? '';
        const rows = await searchPlayers(q);
        sendJson(res, 200, { players: rows.map(playerDto) });
        return;
      }

      const playerMatch = url.pathname.match(/^\/players\/([^/]+)$/);
      if (req.method === 'GET' && playerMatch) {
        const player = await getPlayer(playerMatch[1]);
        if (!player) {
          sendJson(res, 404, { message: 'Not found' });
          return;
        }
        sendJson(res, 200, { player: playerDto(player) });
        return;
      }

      const historyMatch = url.pathname.match(/^\/players\/([^/]+)\/matches$/);
      if (req.method === 'GET' && historyMatch) {
        const authed = await requireAuth(req, res);
        if (!authed) return;
        const rows = await listPlayerMatches(historyMatch[1]);
        sendJson(res, 200, { matches: rows });
        return;
      }

      if (req.method === 'GET' && url.pathname === '/friends') {
        const player = await requireAuth(req, res);
        if (!player) return;
        const friends = await listFriends(player.public_id);
        sendJson(res, 200, { friends });
        return;
      }

      if (req.method === 'POST' && url.pathname === '/friends/request') {
        const player = await requireAuth(req, res);
        if (!player) return;
        const body = await readJsonBody(req);
        const result = await requestFriend(player.public_id, body.playerId);
        if (result.error) {
          sendJson(res, 400, result);
          return;
        }
        sendJson(res, 200, result);
        return;
      }

      if (req.method === 'POST' && url.pathname === '/friends/respond') {
        const player = await requireAuth(req, res);
        if (!player) return;
        const body = await readJsonBody(req);
        const result = await respondFriend(
          player.public_id,
          body.playerId,
          body.accept === true,
        );
        if (result.error) {
          sendJson(res, 400, result);
          return;
        }
        sendJson(res, 200, result);
        return;
      }

      if (req.method === 'DELETE' && url.pathname.startsWith('/friends/')) {
        const player = await requireAuth(req, res);
        if (!player) return;
        const otherId = url.pathname.slice('/friends/'.length);
        const result = await removeFriend(player.public_id, otherId);
        sendJson(res, result.error ? 400 : 200, result);
        return;
      }

      if (req.method === 'POST' && url.pathname === '/referrals/claim') {
        const player = await requireAuth(req, res);
        if (!player) return;
        const body = await readJsonBody(req);
        const result = await claimReferral(player.public_id, body.code);
        sendJson(res, result.error ? 400 : 200, result);
        return;
      }

      if (req.method === 'GET' && url.pathname === '/shop/catalog') {
        sendJson(res, 200, { items: await getShopCatalog() });
        return;
      }

      if (req.method === 'POST' && url.pathname === '/shop/purchase') {
        const player = await requireAuth(req, res);
        if (!player) return;
        const body = await readJsonBody(req);
        const result = await purchaseItem({
          playerPublicId: player.public_id,
          itemId: body.itemId,
          idempotencyKey: req.headers['idempotency-key'] ?? body.idempotencyKey,
        });
        sendJson(res, result.error ? 400 : 200, result);
        return;
      }

      if (req.method === 'POST' && url.pathname === '/shop/rewarded-ad') {
        const player = await requireAuth(req, res);
        if (!player) return;
        const result = await claimRewardedAd(player.public_id);
        sendJson(res, result.error ? 400 : 200, result);
        return;
      }

      sendJson(res, 404, { message: 'Not found' });
    } catch (error) {
      console.error('[http]', error);
      sendJson(res, 500, { message: 'Server error' });
    }
  });

  const wss = new WebSocketServer({ server, path: '/ws' });
  wss.on('connection', async (socket, req) => {
    const url = new URL(req.url ?? '/ws', `http://${req.headers.host ?? 'localhost'}`);
    const token = url.searchParams.get('token');
    let playerId = null;
    if (token) {
      playerId = await verifyBearer(`Bearer ${token}`);
    }
    hub.attach(socket, { playerId });
  });

  server.listen(port, () => {
    console.log(`cardgame listening on :${port} (REST + /ws)`);
  });

  const shutdown = async () => {
    console.log('Shutting down...');
    wss.close();
    server.close();
    await closeDb();
    process.exit(0);
  };
  process.on('SIGINT', shutdown);
  process.on('SIGTERM', shutdown);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
