const http = require('http');
const crypto = require('crypto');
const { URL } = require('url');
const WebSocket = require('ws');
const { GameRoom, GameRuleError, createRoomCode } = require('./game_room');
const fs = require('fs');
const path = require('path');
const { sendJson, sendHtml, sendCsv, readJsonBody, corsHeaders } = require('./http_util');
const {
  assertValidGuestDeviceId,
  InvalidGuestDeviceIdError,
  InvalidGuestIpError,
  GuestIpMismatchError,
  getClientIp,
} = require('./auth/guest_device');
const {
  verifyGoogleIdToken,
  InvalidGoogleTokenError,
} = require('./auth/google_token');
const { signSession, verifySession, InvalidSessionError } = require('./auth/session');
const { requireAuth, isDbReady } = require('./auth/http_auth');
const {
  getPlayerTokenVersion,
  bumpTokenVersion,
  deletePlayerAccount,
  createPlayerReport,
} = require('./db/store');
const {
  authenticateOAuth,
  GoogleAccountInUseError,
} = require('./auth/oauth');
const { findOrCreateGuest } = require('./db/store');
const {
  recordRankedMatch,
  getLeaderboard,
  getPlayerRank,
  getMatchHistory,
  escrowStake,
  assertCanAfford,
  refundEscrow,
} = require('./db/ranking');
const {
  isUsernameAvailable,
  updatePlayerProfile,
  searchPlayers,
  getPlayerFriends,
  sendFriendRequest,
  acceptFriendRequest,
  declineFriendRequest,
  cancelFriendRequest,
  removeFriend,
  blockFriend,
} = require('./db/friends');
const {
  getPlayerInventory,
  exchangeCurrency,
  purchaseItem,
  claimRewardedAdBonus,
  redeemIapPurchase,
  updatePlayerCosmetics,
} = require('./db/marketplace');
const { acquireBotUser } = require('./db/bots');
const { ServerRobotPlayer } = require('./bot_player');
const {
  playerExists,
  upsertDeviceToken,
  removeDeviceToken,
  getNotifyPrefs,
  updateNotifyPrefs,
  listPlayerNotifications,
  markPlayerNotificationsRead,
  listPlayerIdsWithNotifyPref,
  listMarketingBlastAudience,
  countMarketingBlastAudience,
} = require('./db/push');
const { sendToPlayers, sendMarketingBlast, isFcmReady } = require('./push/fcm');
const {
  getAdminDashboardStats,
  getPlayersByIds,
  searchAdminPlayers,
  listAdminGooglePlayers,
  exportAdminGooglePlayersCsv,
} = require('./admin/stats');

/**
 * Pot sizes matchmaking accepts, per stake currency (each player pays half).
 * Must match `StakeSelectorScreen.potOptions` in the app.
 */
const ALLOWED_STAKE_POOLS = {
  money: [20, 50, 100, 200, 500],
  chips: [2, 10, 50],
};

const ADMIN_HTML_PATH = path.join(__dirname, 'public', 'admin.html');
let _adminHtmlCache = null;

function loadAdminHtml() {
  if (_adminHtmlCache) return _adminHtmlCache;
  _adminHtmlCache = fs.readFileSync(ADMIN_HTML_PATH, 'utf8');
  return _adminHtmlCache;
}

function assertAdminPushSecret(request, response) {
  const secret = process.env.ADMIN_PUSH_SECRET || '';
  const provided = request.headers['x-admin-push-secret'];
  if (!secret || provided !== secret) {
    sendJson(response, 401, {
      error: 'unauthorized',
      message: 'Invalid admin secret',
    });
    return false;
  }
  return true;
}

class GameServer {
  constructor({
    port = 8080,
    host = '127.0.0.1',
    botMatchMinDelayMs = 2000,
    botMatchMaxDelayMs = 6000,
  } = {}) {
    this.port = port;
    this.host = host;
    this.botMatchMinDelayMs = botMatchMinDelayMs;
    this.botMatchMaxDelayMs = botMatchMaxDelayMs;
    this.rooms = new Map();
    this.clients = new Map();
    /** @type {Array<object>} FIFO matchmaking queue of client contexts */
    this.matchQueue = [];
    /** @type {Map<string, NodeJS.Timeout>} */
    this.matchTimers = new Map();
    /** @type {Map<string, { bot: ServerRobotPlayer, botPlayerId: string, botClientId: string }>} */
    this.roomBots = new Map();
    /** @type {Set<string>} Active bot player IDs */
    this.activeBotPlayerIds = new Set();
    this.httpServer = null;
    this.webSocketServer = null;
    /** @type {{ t: number, connections: number, uniquePlayers: number, rooms: number, queue: number }[]} */
    this.presenceSamples = [];
    this.presenceTimer = null;
    /** @type {Map<string, NodeJS.Timeout>} key = `${roomId}:${playerId}` */
    this.disconnectGraceTimers = new Map();
  }

  async start() {
    if (this.httpServer) return this.address;

    this.httpServer = http.createServer((request, response) => {
      this.#handleHttp(request, response).catch((error) => {
        console.error('[http] unhandled', error);
        if (!response.headersSent) {
          sendJson(response, 500, {
            error: 'server_error',
            message: 'Internal server error',
          });
        }
      });
    });

    this.webSocketServer = new WebSocket.Server({
      server: this.httpServer,
      maxPayload: 16 * 1024,
    });
    this.webSocketServer.on('connection', (socket) => this.#connect(socket));

    this.presenceTimer = setInterval(() => this.#samplePresence(), 15_000);
    if (this.presenceTimer.unref) this.presenceTimer.unref();
    this.#samplePresence();

    await new Promise((resolve, reject) => {
      this.httpServer.once('error', reject);
      this.httpServer.listen(this.port, this.host, resolve);
    });
    const addr = this.address;
    if (addr) {
      const hostLabel = this.host === '0.0.0.0' ? '127.0.0.1' : this.host;
      console.log(`Ops dashboard: http://${hostLabel}:${addr.port}/admin`);
    }
    return addr;
  }

  get address() {
    const address = this.httpServer?.address();
    return typeof address === 'object' && address
      ? { host: this.host, port: address.port }
      : null;
  }

  async stop() {
    if (this.presenceTimer) {
      clearInterval(this.presenceTimer);
      this.presenceTimer = null;
    }
    for (const timer of this.matchTimers.values()) clearTimeout(timer);
    this.matchTimers.clear();
    for (const timer of this.disconnectGraceTimers.values()) clearTimeout(timer);
    this.disconnectGraceTimers.clear();
    for (const roomBot of this.roomBots.values()) roomBot.bot.dispose();
    this.roomBots.clear();
    this.activeBotPlayerIds.clear();
    for (const room of this.rooms.values()) room.dispose();
    for (const context of this.clients.values()) context.socket.terminate();
    this.rooms.clear();
    this.clients.clear();
    this.matchQueue = [];
    this.presenceSamples = [];
    await new Promise((resolve) => this.webSocketServer?.close(resolve));
    await new Promise((resolve) => this.httpServer?.close(resolve));
    this.webSocketServer = null;
    this.httpServer = null;
  }

  #samplePresence() {
    const uniquePlayers = new Set();
    for (const ctx of this.clients.values()) {
      if (ctx.playerId) uniquePlayers.add(ctx.playerId);
    }
    this.presenceSamples.push({
      t: Date.now(),
      connections: this.clients.size,
      uniquePlayers: uniquePlayers.size,
      rooms: this.rooms.size,
      queue: this.matchQueue.length,
    });
    if (this.presenceSamples.length > 240) {
      this.presenceSamples.shift();
    }
  }

  async #adminLiveSnapshot() {
    const now = Date.now();
    const inQueueIds = new Set(
      this.matchQueue.map((c) => c.id).filter(Boolean),
    );
    const connections = [...this.clients.values()].map((ctx) => {
      let location = 'idle';
      if (ctx.roomId) {
        const room = this.rooms.get(ctx.roomId);
        if (room?.status === 'playing' || room?.status === 'ended') {
          location = 'match';
        } else if (room?.status === 'waiting') {
          const anyRematch = Array.isArray(room.rematchReady)
            ? room.rematchReady.some(Boolean)
            : false;
          location = anyRematch ? 'rematch' : 'lobby';
        } else {
          location = 'lobby';
        }
      } else if (inQueueIds.has(ctx.id)) {
        location = 'queue';
      }
      return {
        connectionId: ctx.id,
        playerId: ctx.playerId || null,
        displayName: ctx.displayName || null,
        location,
        roomId: ctx.roomId || null,
        connectedMs: Math.max(0, now - (ctx.connectedAt || now)),
        remoteAddress: ctx.socket?._socket?.remoteAddress || null,
      };
    });

    const uniquePlayers = new Set(
      connections.map((c) => c.playerId).filter(Boolean),
    );
    const rooms = [...this.rooms.values()].map((room) => ({
      matchId: room.id,
      roomCode: room.id,
      mode: room.matchType || 'private',
      phase: room.status,
      mapId: null,
      stakePerPlayer: room.stakePerPlayer || 0,
      potAmount: room.potAmount || 0,
      stakeCurrency: room.stakeCurrency || 'money',
      players: room.players.map((p) => ({
        playerId: p.playerId,
        displayName: p.displayName,
        isBot: Boolean(p.id?.startsWith('bot-client-')),
        connected: Boolean(p.connected),
        role: 'player',
      })),
    }));

    const profilesList = await getPlayersByIds(
      connections.map((c) => c.playerId).filter(Boolean),
    );
    /** @type {Record<string, unknown>} */
    const profiles = {};
    for (const player of profilesList) {
      if (player?.playerId) profiles[player.playerId] = player;
    }

    return {
      counts: {
        connections: connections.length,
        uniquePlayers: uniquePlayers.size,
        rooms: rooms.length,
        inMatch: connections.filter((c) => c.location === 'match').length,
        inQueue: connections.filter((c) => c.location === 'queue').length,
        inLobby: connections.filter((c) => c.location === 'lobby').length,
        rematches: connections.filter((c) => c.location === 'rematch').length,
        idle: connections.filter((c) => c.location === 'idle').length,
        queueQuick: this.matchQueue.length,
        queueRanked: 0,
        lobbies: rooms.filter((r) => r.phase === 'waiting').length,
      },
      connections,
      rooms,
      queues: {
        quick: this.matchQueue.map((c) => ({
          playerId: c.playerId,
          displayName: c.displayName,
          waitMs: Math.max(0, now - (c.queueJoinedAt || c.connectedAt || now)),
        })),
        ranked: [],
      },
      lobbies: [],
      rematches: [],
      profiles,
      presence: this.presenceSamples,
    };
  }

  async #handleHttp(request, response) {
    const url = new URL(request.url ?? '/', `http://${request.headers.host || 'localhost'}`);

    if (request.method === 'GET' && url.pathname === '/health') {
      sendJson(response, 200, {
        status: 'ok',
        rooms: this.rooms.size,
        clients: this.clients.size,
      });
      return;
    }

    if (
      request.method === 'GET' &&
      (url.pathname === '/admin' || url.pathname === '/admin/')
    ) {
      try {
        sendHtml(response, 200, loadAdminHtml());
      } catch (error) {
        console.error('[admin] failed to load admin.html', error);
        sendJson(response, 500, {
          error: 'server_error',
          message: 'Admin UI missing',
        });
      }
      return;
    }

    if (request.method === 'GET' && url.pathname === '/admin/live') {
      if (!assertAdminPushSecret(request, response)) return;
      try {
        sendJson(response, 200, await this.#adminLiveSnapshot());
      } catch (error) {
        console.error('[admin/live] failed', error);
        sendJson(response, 500, {
          error: 'server_error',
          message: 'Live snapshot failed',
        });
      }
      return;
    }

    if (request.method === 'GET' && url.pathname === '/admin/stats') {
      if (!assertAdminPushSecret(request, response)) return;
      try {
        sendJson(response, 200, await getAdminDashboardStats());
      } catch (error) {
        console.error('[admin/stats] failed', error);
        sendJson(response, 500, {
          error: 'server_error',
          message: 'Stats failed',
        });
      }
      return;
    }

    if (request.method === 'GET' && url.pathname === '/admin/players') {
      if (!assertAdminPushSecret(request, response)) return;
      try {
        const players = await searchAdminPlayers({
          query: url.searchParams.get('q') ?? '',
          limit: url.searchParams.get('limit'),
        });
        sendJson(response, 200, { players });
      } catch (error) {
        console.error('[admin/players] failed', error);
        sendJson(response, 500, {
          error: 'server_error',
          message: 'Search failed',
        });
      }
      return;
    }

    if (request.method === 'GET' && url.pathname === '/admin/data/players') {
      if (!assertAdminPushSecret(request, response)) return;
      try {
        const players = await listAdminGooglePlayers({
          limit: url.searchParams.get('limit'),
        });
        sendJson(response, 200, { players, count: players.length });
      } catch (error) {
        console.error('[admin/data/players] failed', error);
        sendJson(response, 500, {
          error: 'server_error',
          message: 'Player list failed',
        });
      }
      return;
    }

    if (request.method === 'GET' && url.pathname === '/admin/data/players.csv') {
      if (!assertAdminPushSecret(request, response)) return;
      try {
        const { csv, count } = await exportAdminGooglePlayersCsv();
        const stamp = new Date().toISOString().slice(0, 10);
        sendCsv(response, 200, csv, `shadowhand-google-players-${stamp}.csv`);
        console.log(`[admin/data/players.csv] exported ${count} rows`);
      } catch (error) {
        console.error('[admin/data/players.csv] failed', error);
        sendJson(response, 500, {
          error: 'server_error',
          message: 'CSV export failed',
        });
      }
      return;
    }

    if (request.method === 'OPTIONS') {
      sendJson(response, 204, {});
      return;
    }

    if (request.method === 'GET' && url.pathname === '/app/config') {
      sendJson(response, 200, {
        minAndroidVersionCode: Number.parseInt(process.env.MIN_ANDROID_VERSION_CODE || '1', 10) || 1,
        softMinVersion: process.env.SOFT_MIN_VERSION || null,
      });
      return;
    }

    if (request.method === 'DELETE' && url.pathname === '/account') {
      await this.#handleDeleteAccount(request, response);
      return;
    }

    if (request.method === 'POST' && url.pathname === '/friends/block') {
      await this.#handleBlockFriend(request, response);
      return;
    }

    if (request.method === 'POST' && url.pathname === '/players/report') {
      await this.#handleReportPlayer(request, response);
      return;
    }

    if (request.method === 'POST' && url.pathname === '/auth/guest') {
      await this.#handleGuestAuth(request, response);
      return;
    }

    if (request.method === 'POST' && url.pathname === '/auth/google') {
      await this.#handleGoogleAuth(request, response);
      return;
    }

    if (request.method === 'GET' && url.pathname === '/ranking') {
      await this.#handleLeaderboard(request, response, url);
      return;
    }

    if (request.method === 'GET' && url.pathname === '/ranking/player') {
      await this.#handlePlayerRank(request, response, url);
      return;
    }

    if (request.method === 'GET' && url.pathname === '/matches') {
      await this.#handleMatchHistory(request, response, url);
      return;
    }

    if (request.method === 'GET' && url.pathname === '/player/check-username') {
      await this.#handleCheckUsername(request, response, url);
      return;
    }

    if (request.method === 'POST' && url.pathname === '/player/profile') {
      await this.#handleUpdateProfile(request, response);
      return;
    }

    if (request.method === 'GET' && url.pathname === '/friends/search') {
      await this.#handleSearchPlayers(request, response, url);
      return;
    }

    if (request.method === 'GET' && url.pathname === '/friends') {
      await this.#handleGetFriends(request, response, url);
      return;
    }

    if (request.method === 'POST' && url.pathname === '/friends/request') {
      await this.#handleSendFriendRequest(request, response);
      return;
    }

    if (request.method === 'POST' && url.pathname === '/friends/accept') {
      await this.#handleAcceptFriendRequest(request, response);
      return;
    }

    if (request.method === 'POST' && url.pathname === '/friends/decline') {
      await this.#handleDeclineFriendRequest(request, response);
      return;
    }

    if (request.method === 'POST' && url.pathname === '/friends/cancel') {
      await this.#handleCancelFriendRequest(request, response);
      return;
    }

    if (request.method === 'POST' && url.pathname === '/friends/remove') {
      await this.#handleRemoveFriend(request, response);
      return;
    }

    if (request.method === 'GET' && url.pathname === '/marketplace/inventory') {
      await this.#handleGetInventory(request, response, url);
      return;
    }

    if (request.method === 'POST' && url.pathname === '/marketplace/exchange') {
      await this.#handleExchangeCurrency(request, response);
      return;
    }

    if (request.method === 'POST' && url.pathname === '/marketplace/buy') {
      await this.#handlePurchaseItem(request, response);
      return;
    }

    if (request.method === 'POST' && url.pathname === '/marketplace/claim-ad-reward') {
      await this.#handleClaimAdReward(request, response);
      return;
    }

    if (
      request.method === 'POST' &&
      (url.pathname === '/economy/iap/verify' || url.pathname === '/marketplace/iap/verify')
    ) {
      await this.#handleVerifyIap(request, response);
      return;
    }

    if (request.method === 'POST' && url.pathname === '/devices/register') {
      await this.#handleDeviceRegister(request, response);
      return;
    }

    if (request.method === 'POST' && url.pathname === '/devices/unregister') {
      await this.#handleDeviceUnregister(request, response);
      return;
    }

    if (request.method === 'GET' && url.pathname.startsWith('/players/') && url.pathname.endsWith('/notify-prefs')) {
      await this.#handleGetNotifyPrefs(request, response, url);
      return;
    }

    if (request.method === 'POST' && url.pathname.startsWith('/players/') && url.pathname.endsWith('/notify-prefs')) {
      await this.#handleUpdateNotifyPrefs(request, response, url);
      return;
    }

    if (request.method === 'GET' && url.pathname.startsWith('/players/') && url.pathname.endsWith('/notifications')) {
      await this.#handleListNotifications(request, response, url);
      return;
    }

    if (request.method === 'POST' && url.pathname.startsWith('/players/') && url.pathname.endsWith('/notifications/read')) {
      await this.#handleMarkNotificationsRead(request, response, url);
      return;
    }

    if (request.method === 'POST' && url.pathname === '/admin/push') {
      await this.#handleAdminPush(request, response);
      return;
    }

    if (request.method === 'OPTIONS') {
      response.writeHead(204, corsHeaders());
      response.end();
      return;
    }

    response.writeHead(404);
    response.end();
  }

  async #handleLeaderboard(_request, response, url) {
    const limit = url.searchParams.get('limit');
    const offset = url.searchParams.get('offset');
    try {
      const payload = await getLeaderboard({ limit, offset });
      sendJson(response, 200, payload);
    } catch (error) {
      console.error('[ranking] leaderboard', error);
      sendJson(response, 500, {
        error: 'server_error',
        message: 'Failed to load ranking',
      });
    }
  }

  async #handlePlayerRank(request, response, url) {
    const auth = await this.#requireAuth(request, response);
    if (!auth) return;
    // Read-only lookup: any signed-in player may view another player's rank.
    const playerId = url.searchParams.get('playerId')?.trim() || auth.playerId;
    try {
      const entry = await getPlayerRank(playerId);
      if (!entry) {
        sendJson(response, 404, {
          error: 'not_found',
          message: 'Player not found',
        });
        return;
      }
      sendJson(response, 200, entry);
    } catch (error) {
      console.error('[ranking] player', error);
      sendJson(response, 500, {
        error: 'server_error',
        message: 'Failed to load player rank',
      });
    }
  }

  async #handleMatchHistory(request, response, url) {
    const auth = await this.#requireAuth(request, response);
    if (!auth) return;
    // Read-only lookup: any signed-in player may view another player's history.
    const playerId = url.searchParams.get('playerId')?.trim() || auth.playerId;
    const limit = url.searchParams.get('limit');
    const offset = url.searchParams.get('offset');
    try {
      const payload = await getMatchHistory({ playerId, limit, offset });
      sendJson(response, 200, payload);
    } catch (error) {
      console.error('[ranking] matches', error);
      sendJson(response, 500, {
        error: 'server_error',
        message: 'Failed to load match history',
      });
    }
  }

  #getOnlinePlayerIds() {
    const ids = new Set();
    for (const ctx of this.clients.values()) {
      if (ctx.playerId && ctx.socket?.readyState === WebSocket.OPEN) {
        ids.add(ctx.playerId);
      }
    }
    return ids;
  }

  async #handleCheckUsername(request, response, url) {
    const auth = await this.#requireAuth(request, response);
    if (!auth) return;
    const username = url.searchParams.get('username');
    const playerId = auth.playerId;
    if (!username) {
      sendJson(response, 400, {
        error: 'missing_username',
        message: 'username query parameter is required',
      });
      return;
    }
    try {
      const result = await isUsernameAvailable(username, playerId);
      sendJson(response, 200, result);
    } catch (error) {
      console.error('[player/check-username]', error);
      sendJson(response, 500, { error: 'server_error', message: 'Failed to check username' });
    }
  }

  async #handleUpdateProfile(request, response) {
    const auth = await this.#requireAuth(request, response);
    if (!auth) return;

    let body;
    try {
      body = await readJsonBody(request);
    } catch {
      sendJson(response, 400, { error: 'invalid_json', message: 'Invalid JSON body' });
      return;
    }

    const playerId = auth.playerId;
    const { name, username, avatarId, deckId } = body || {};
    if (!playerId) {
      sendJson(response, 400, { error: 'missing_player_id', message: 'playerId is required' });
      return;
    }

    try {
      const updated = await updatePlayerProfile({ playerId, name, username });
      if (!updated) {
        sendJson(response, 404, { error: 'not_found', message: 'Player not found' });
        return;
      }
      if (avatarId || deckId) {
        await updatePlayerCosmetics({ playerId, avatarId, deckId });
      }
      sendJson(response, 200, {
        playerId: updated.id,
        name: updated.display_name,
        username: updated.username,
        authType: updated.auth_type,
        elo: updated.elo,
        totalPoints: updated.total_points,
        avatarId: avatarId || updated.avatar_id || 'default',
        deckId: deckId || updated.deck_id || 'default',
      });
    } catch (error) {
      if (error.code === 'invalid_format' || error.code === 'username_taken') {
        sendJson(response, error.code === 'username_taken' ? 409 : 400, {
          error: error.code,
          message: error.message,
        });
        return;
      }
      if (error.code === 'not_owned') {
        sendJson(response, 400, { error: error.code, message: error.message });
        return;
      }
      console.error('[player/profile]', error);
      sendJson(response, 500, { error: 'server_error', message: 'Failed to update profile' });
    }
  }

  async #handleSearchPlayers(request, response, url) {
    const auth = await this.#requireAuth(request, response);
    if (!auth) return;
    const query = url.searchParams.get('query') || '';
    const playerId = auth.playerId;
    const limit = url.searchParams.get('limit') || 20;

    try {
      const onlinePlayerIds = this.#getOnlinePlayerIds();
      const results = await searchPlayers({
        query,
        playerId,
        limit,
        onlinePlayerIds,
      });
      this.#enrichAvatarsFromLiveClients(results.players);
      sendJson(response, 200, results);
    } catch (error) {
      console.error('[friends/search]', error);
      sendJson(response, 500, { error: 'server_error', message: 'Failed to search players' });
    }
  }

  async #handleGetFriends(request, response, url) {
    const auth = await this.#requireAuth(request, response);
    if (!auth) return;
    const playerId = auth.playerId;
    void url;

    try {
      const onlinePlayerIds = this.#getOnlinePlayerIds();
      const payload = await getPlayerFriends({ playerId, onlinePlayerIds });
      this.#enrichAvatarsFromLiveClients(payload.friends);
      this.#enrichAvatarsFromLiveClients(payload.incomingRequests);
      this.#enrichAvatarsFromLiveClients(payload.outgoingRequests);
      sendJson(response, 200, payload);
    } catch (error) {
      console.error('[friends]', error);
      sendJson(response, 500, { error: 'server_error', message: 'Failed to get friends' });
    }
  }

  async #handleSendFriendRequest(request, response) {
    const auth = await this.#requireAuth(request, response);
    if (!auth) return;

    let body;
    try {
      body = await readJsonBody(request);
    } catch {
      sendJson(response, 400, { error: 'invalid_json', message: 'Invalid JSON body' });
      return;
    }

    const playerId = auth.playerId;
    const { targetPlayerId, targetUsername } = body || {};
    if (!playerId) {
      sendJson(response, 400, { error: 'missing_player_id', message: 'playerId is required' });
      return;
    }

    try {
      const result = await sendFriendRequest({ playerId, targetPlayerId, targetUsername });
      sendJson(response, 200, result);

      if (result.status === 'pending' && !result.alreadyPending && result.targetPlayerId) {
        this.#notifyPlayer(result.targetPlayerId, {
          type: 'friendRequestReceived',
          requestId: result.requestId || null,
          fromPlayerId: result.fromPlayerId || playerId,
          fromName: result.fromName || 'Player',
          fromUsername: result.fromUsername || '',
        });
        void sendToPlayers([result.targetPlayerId], {
          category: 'social',
          title: 'Friend request',
          body: `${result.fromName || 'Player'} sent a friend request`,
          data: {
            type: 'friend_request',
            route: '/friends',
            fromPlayerId: result.fromPlayerId || playerId,
          },
        }).catch((error) => console.error('[fcm] friend request', error));
      } else if (result.autoAccepted && result.notifyPlayerId) {
        this.#notifyPlayer(result.notifyPlayerId, {
          type: 'friendRequestAccepted',
          friendshipId: result.friendshipId || null,
          byPlayerId: result.fromPlayerId || playerId,
          byName: result.fromName || 'Player',
          byUsername: result.fromUsername || '',
        });
        void sendToPlayers([result.notifyPlayerId], {
          category: 'social',
          title: 'Friend accepted',
          body: `${result.fromName || 'Player'} accepted your friend request`,
          data: {
            type: 'friend_accepted',
            route: '/friends',
            byPlayerId: result.fromPlayerId || playerId,
          },
        }).catch((error) => console.error('[fcm] friend auto-accept', error));
      }
    } catch (error) {
      if (
        error.code === 'player_not_found' ||
        error.code === 'invalid_target' ||
        error.code === 'cannot_friend_self'
      ) {
        sendJson(response, 400, { error: error.code, message: error.message });
        return;
      }
      console.error('[friends/request]', error);
      sendJson(response, 500, { error: 'server_error', message: 'Failed to send friend request' });
    }
  }

  async #handleAcceptFriendRequest(request, response) {
    const auth = await this.#requireAuth(request, response);
    if (!auth) return;

    let body;
    try {
      body = await readJsonBody(request);
    } catch {
      sendJson(response, 400, { error: 'invalid_json', message: 'Invalid JSON body' });
      return;
    }

    const playerId = auth.playerId;
    const { requesterId, requestId } = body || {};
    if (!playerId) {
      sendJson(response, 400, { error: 'missing_player_id', message: 'playerId is required' });
      return;
    }

    try {
      const result = await acceptFriendRequest({ playerId, requesterId, requestId });
      sendJson(response, 200, result);

      if (result.requesterId) {
        this.#notifyPlayer(result.requesterId, {
          type: 'friendRequestAccepted',
          friendshipId: result.friendshipId || null,
          byPlayerId: result.byPlayerId || playerId,
          byName: result.byName || 'Player',
          byUsername: result.byUsername || '',
        });
        void sendToPlayers([result.requesterId], {
          category: 'social',
          title: 'Friend accepted',
          body: `${result.byName || 'Player'} accepted your friend request`,
          data: {
            type: 'friend_accepted',
            route: '/friends',
            byPlayerId: result.byPlayerId || playerId,
          },
        }).catch((error) => console.error('[fcm] friend accept', error));
      }
    } catch (error) {
      if (error.code === 'request_not_found') {
        sendJson(response, 404, { error: error.code, message: error.message });
        return;
      }
      console.error('[friends/accept]', error);
      sendJson(response, 500, { error: 'server_error', message: 'Failed to accept friend request' });
    }
  }

  async #handleDeclineFriendRequest(request, response) {
    const auth = await this.#requireAuth(request, response);
    if (!auth) return;

    let body;
    try {
      body = await readJsonBody(request);
    } catch {
      sendJson(response, 400, { error: 'invalid_json', message: 'Invalid JSON body' });
      return;
    }

    const playerId = auth.playerId;
    const { requesterId, requestId } = body || {};
    if (!playerId) {
      sendJson(response, 400, { error: 'missing_player_id', message: 'playerId is required' });
      return;
    }

    try {
      const result = await declineFriendRequest({ playerId, requesterId, requestId });
      sendJson(response, 200, result);
    } catch (error) {
      console.error('[friends/decline]', error);
      sendJson(response, 500, { error: 'server_error', message: 'Failed to decline friend request' });
    }
  }

  async #handleCancelFriendRequest(request, response) {
    const auth = await this.#requireAuth(request, response);
    if (!auth) return;

    let body;
    try {
      body = await readJsonBody(request);
    } catch {
      sendJson(response, 400, { error: 'invalid_json', message: 'Invalid JSON body' });
      return;
    }

    const playerId = auth.playerId;
    const { targetPlayerId, requestId } = body || {};
    if (!playerId) {
      sendJson(response, 400, { error: 'missing_player_id', message: 'playerId is required' });
      return;
    }

    try {
      const result = await cancelFriendRequest({ playerId, targetPlayerId, requestId });
      sendJson(response, 200, result);
    } catch (error) {
      console.error('[friends/cancel]', error);
      sendJson(response, 500, { error: 'server_error', message: 'Failed to cancel friend request' });
    }
  }

  async #handleRemoveFriend(request, response) {
    const auth = await this.#requireAuth(request, response);
    if (!auth) return;

    let body;
    try {
      body = await readJsonBody(request);
    } catch {
      sendJson(response, 400, { error: 'invalid_json', message: 'Invalid JSON body' });
      return;
    }

    const playerId = auth.playerId;
    const { friendId, friendshipId } = body || {};
    if (!playerId) {
      sendJson(response, 400, { error: 'missing_player_id', message: 'playerId is required' });
      return;
    }

    try {
      const result = await removeFriend({ playerId, friendId, friendshipId });
      sendJson(response, 200, result);
    } catch (error) {
      console.error('[friends/remove]', error);
      sendJson(response, 500, { error: 'server_error', message: 'Failed to remove friend' });
    }
  }

  async #handleGetInventory(request, response, url) {
    const auth = await this.#requireAuth(request, response);
    if (!auth) return;
    const playerId = auth.playerId;
    void url;

    try {
      const inventory = await getPlayerInventory(playerId);
      sendJson(response, 200, inventory);
    } catch (error) {
      if (error.code === 'player_not_found') {
        sendJson(response, 404, { error: error.code, message: error.message });
        return;
      }
      console.error('[marketplace/inventory]', error);
      sendJson(response, 500, { error: 'server_error', message: 'Failed to load inventory' });
    }
  }

  async #handleExchangeCurrency(request, response) {
    const auth = await this.#requireAuth(request, response);
    if (!auth) return;

    let body;
    try {
      body = await readJsonBody(request);
    } catch {
      sendJson(response, 400, { error: 'invalid_json', message: 'Invalid JSON body' });
      return;
    }

    const playerId = auth.playerId;
    const { direction, amount } = body || {};
    if (!playerId) {
      sendJson(response, 400, { error: 'missing_player_id', message: 'playerId is required' });
      return;
    }

    try {
      const result = await exchangeCurrency({ playerId, direction, amount });
      sendJson(response, 200, result);
    } catch (error) {
      if (
        error.code === 'player_not_found' ||
        error.code === 'insufficient_funds' ||
        error.code === 'invalid_amount' ||
        error.code === 'invalid_direction'
      ) {
        sendJson(response, 400, { error: error.code, message: error.message });
        return;
      }
      console.error('[marketplace/exchange]', error);
      sendJson(response, 500, { error: 'server_error', message: 'Failed to exchange currency' });
    }
  }

  async #handlePurchaseItem(request, response) {
    const auth = await this.#requireAuth(request, response);
    if (!auth) return;

    let body;
    try {
      body = await readJsonBody(request);
    } catch {
      sendJson(response, 400, { error: 'invalid_json', message: 'Invalid JSON body' });
      return;
    }

    const playerId = auth.playerId;
    const { itemType, itemId, currency, price } = body || {};
    if (!playerId) {
      sendJson(response, 400, { error: 'missing_player_id', message: 'playerId is required' });
      return;
    }

    try {
      const result = await purchaseItem({ playerId, itemType, itemId, currency, price });
      sendJson(response, 200, result);
    } catch (error) {
      if (
        error.code === 'player_not_found' ||
        error.code === 'already_owned' ||
        error.code === 'insufficient_funds' ||
        error.code === 'invalid_item_type' ||
        error.code === 'invalid_item_id' ||
        error.code === 'invalid_currency' ||
        error.code === 'invalid_price'
      ) {
        sendJson(response, 400, { error: error.code, message: error.message });
        return;
      }
      console.error('[marketplace/buy]', error);
      sendJson(response, 500, { error: 'server_error', message: 'Failed to purchase item' });
    }
  }

  async #handleClaimAdReward(request, response) {
    const auth = await this.#requireAuth(request, response);
    if (!auth) return;

    let body;
    try {
      body = await readJsonBody(request);
    } catch {
      sendJson(response, 400, { error: 'invalid_json', message: 'Invalid JSON body' });
      return;
    }

    const playerId = auth.playerId;
    void body;

    try {
      const result = await claimRewardedAdBonus(playerId);
      sendJson(response, 200, result);
    } catch (error) {
      if (error.code === 'player_not_found') {
        sendJson(response, 404, { error: error.code, message: error.message });
        return;
      }
      if (error.code === 'ad_cooldown' || error.code === 'ad_daily_cap') {
        sendJson(response, 429, { error: error.code, message: error.message });
        return;
      }
      console.error('[marketplace/claim-ad-reward]', error);
      sendJson(response, 500, { error: 'server_error', message: 'Failed to claim ad reward' });
    }
  }

  async #handleVerifyIap(request, response) {
    const auth = await this.#requireAuth(request, response);
    if (!auth) return;

    let body;
    try {
      body = await readJsonBody(request);
    } catch {
      sendJson(response, 400, { error: 'invalid_json', message: 'Invalid JSON body' });
      return;
    }

    const playerId = auth.playerId;
    const { productId, transactionId } = body || {};
    if (!playerId || !productId || !transactionId) {
      sendJson(response, 400, {
        error: 'missing_parameters',
        message: 'playerId, productId, and transactionId are required',
      });
      return;
    }

    try {
      const result = await redeemIapPurchase({ playerId, productId, transactionId });
      sendJson(response, 200, result);
    } catch (error) {
      if (error.code === 'player_not_found') {
        sendJson(response, 404, { error: error.code, message: error.message });
        return;
      }
      if (error.code === 'invalid_product_id' || error.code === 'invalid_player_id' || error.code === 'invalid_transaction_id') {
        sendJson(response, 400, { error: error.code, message: error.message });
        return;
      }
      console.error('[economy/iap/verify]', error);
      sendJson(response, 500, { error: 'server_error', message: 'Failed to verify IAP purchase' });
    }
  }

  async #requireAuth(request, response) {
    return requireAuth(request, response, sendJson);
  }

  async #handleDeleteAccount(request, response) {
    const auth = await this.#requireAuth(request, response);
    if (!auth) return;
    try {
      await bumpTokenVersion(auth.playerId);
      const deleted = await deletePlayerAccount(auth.playerId);
      if (!deleted) {
        sendJson(response, 404, { error: 'player_not_found', message: 'Player not found' });
        return;
      }
      sendJson(response, 200, { ok: true, deleted: true });
    } catch (error) {
      console.error('[account/delete]', error);
      sendJson(response, 500, { error: 'server_error', message: 'Failed to delete account' });
    }
  }

  async #handleBlockFriend(request, response) {
    const auth = await this.#requireAuth(request, response);
    if (!auth) return;
    let body;
    try {
      body = await readJsonBody(request);
    } catch {
      sendJson(response, 400, { error: 'invalid_json', message: 'Invalid JSON body' });
      return;
    }
    const targetPlayerId = body?.targetPlayerId || body?.friendId;
    if (!targetPlayerId) {
      sendJson(response, 400, { error: 'missing_target', message: 'targetPlayerId required' });
      return;
    }
    try {
      const result = await blockFriend({ playerId: auth.playerId, targetPlayerId });
      sendJson(response, 200, result);
    } catch (error) {
      sendJson(response, 400, { error: error.code || 'block_failed', message: error.message });
    }
  }

  async #handleReportPlayer(request, response) {
    const auth = await this.#requireAuth(request, response);
    if (!auth) return;
    let body;
    try {
      body = await readJsonBody(request);
    } catch {
      sendJson(response, 400, { error: 'invalid_json', message: 'Invalid JSON body' });
      return;
    }
    const targetId = body?.targetPlayerId || body?.targetId;
    if (!targetId) {
      sendJson(response, 400, { error: 'missing_target', message: 'targetPlayerId required' });
      return;
    }
    try {
      const result = await createPlayerReport({
        reporterId: auth.playerId,
        targetId,
        reason: body?.reason,
        details: body?.details,
      });
      sendJson(response, 200, result);
    } catch (error) {
      sendJson(response, 400, { error: error.code || 'report_failed', message: error.message });
    }
  }

  async #handleGuestAuth(request, response) {
    let body;
    try {
      body = await readJsonBody(request);
    } catch {
      sendJson(response, 400, { error: 'invalid_json', message: 'Invalid JSON body' });
      return;
    }

    let deviceId;
    try {
      deviceId = assertValidGuestDeviceId(body.deviceId);
    } catch (error) {
      const message =
        error instanceof InvalidGuestDeviceIdError
          ? error.message
          : 'deviceId is required';
      sendJson(response, 400, {
        error: 'invalid_device_id',
        message,
      });
      return;
    }

    const clientIp = getClientIp(request);

    try {
      const identity = await findOrCreateGuest({ deviceId, clientIp });
      const tokenVersion = identity.tokenVersion ?? (await getPlayerTokenVersion(identity.playerId)) ?? 0;
      const accessToken = await signSession({
        playerId: identity.playerId,
        tokenVersion,
      });
      sendJson(response, 200, { ...identity, accessToken });
    } catch (error) {
      if (
        error instanceof InvalidGuestDeviceIdError ||
        error instanceof InvalidGuestIpError
      ) {
        sendJson(response, 400, {
          error: error.code,
          message: error.message,
        });
        return;
      }
      if (error instanceof GuestIpMismatchError) {
        sendJson(response, 403, {
          error: error.code,
          message: error.message,
        });
        return;
      }
      if (error?.message?.includes('MySQL pool not initialized')) {
        sendJson(response, 503, {
          error: 'db_unavailable',
          message: 'Database not ready',
        });
        return;
      }
      console.error('[auth/guest] failed', error);
      sendJson(response, 500, {
        error: 'server_error',
        message: 'Could not create or load guest',
      });
    }
  }

  async #handleGoogleAuth(request, response) {
    let body;
    try {
      body = await readJsonBody(request);
    } catch {
      sendJson(response, 400, { error: 'invalid_json', message: 'Invalid JSON body' });
      return;
    }

    const idToken =
      typeof body.idToken === 'string' ? body.idToken.trim() : '';
    if (!idToken) {
      sendJson(response, 400, {
        error: 'invalid_id_token',
        message: 'idToken is required',
      });
      return;
    }

    let deviceId = null;
    if (body.deviceId != null && String(body.deviceId).trim()) {
      try {
        deviceId = assertValidGuestDeviceId(body.deviceId);
      } catch (error) {
        const message =
          error instanceof InvalidGuestDeviceIdError
            ? error.message
            : 'Invalid deviceId';
        sendJson(response, 400, {
          error: 'invalid_device_id',
          message,
        });
        return;
      }
    }

    const clientIp = getClientIp(request);
    const confirmSwitch = body.confirmSwitch === true;

    try {
      const claims = await verifyGoogleIdToken(idToken);
      const identity = await authenticateOAuth({
        provider: 'google',
        sub: claims.sub,
        displayNameHint: claims.name ?? null,
        email: claims.email ?? null,
        deviceId,
        clientIp,
        confirmSwitch,
      });
      const tokenVersion = identity.tokenVersion ?? (await getPlayerTokenVersion(identity.playerId)) ?? 0;
      const accessToken = await signSession({
        playerId: identity.playerId,
        tokenVersion,
      });
      sendJson(response, 200, { ...identity, accessToken });
    } catch (error) {
      if (error instanceof GoogleAccountInUseError) {
        sendJson(response, 409, {
          error: error.code,
          message: error.message,
          existingName: error.existingName,
          existingUsername: error.existingUsername,
          guestPlayerId: error.guestPlayerId,
        });
        return;
      }
      if (error instanceof InvalidGoogleTokenError) {
        sendJson(response, 401, {
          error: error.code,
          message: error.message,
        });
        return;
      }
      if (error instanceof InvalidGuestDeviceIdError) {
        sendJson(response, 400, {
          error: error.code,
          message: error.message,
        });
        return;
      }
      if (error?.message?.includes('MySQL pool not initialized')) {
        sendJson(response, 503, {
          error: 'db_unavailable',
          message: 'Database not ready',
        });
        return;
      }
      console.error('[auth/google] failed', error);
      sendJson(response, 500, {
        error: 'server_error',
        message: 'Could not authenticate with Google',
      });
    }
  }

  #connect(socket) {
    const context = {
      id: crypto.randomUUID(),
      socket,
      roomId: null,
      playerId: null,
      displayName: null,
      messages: [],
      connectedAt: Date.now(),
    };
    this.clients.set(context.id, context);
    this.#send(socket, {
      type: 'connected',
      protocolVersion: 1,
      clientId: context.id,
    });

    socket.on('message', (raw) => {
      if (!this.#withinRateLimit(context)) {
        this.#error(socket, 'rate_limited', 'Too many commands');
        return;
      }
      Promise.resolve()
        .then(async () => {
          const command = JSON.parse(raw.toString());
          // Client heartbeat: proves the socket is alive end to end.
          if (command.type === 'ping') {
            this.#send(socket, { type: 'pong', at: command.at ?? null });
            return;
          }
          await this.#handle(context, command);
        })
        .catch((error) => {
          if (error instanceof GameRuleError) {
            this.#error(socket, error.code, error.message);
          } else if (error instanceof SyntaxError) {
            this.#error(socket, 'invalid_json', 'Message must be valid JSON');
          } else if (error instanceof InvalidSessionError) {
            this.#error(socket, error.code || 'auth_required', error.message);
          } else {
            console.error(error);
            this.#error(socket, 'server_error', 'Command failed');
          }
        });
    });

    socket.on('close', () => {
      this.#onSocketClose(context);
    });
  }

  #graceKey(roomId, playerId) {
    return `${roomId}:${playerId}`;
  }

  #clearDisconnectGrace(roomId, playerId) {
    const key = this.#graceKey(roomId, playerId);
    const timer = this.disconnectGraceTimers.get(key);
    if (timer) {
      clearTimeout(timer);
      this.disconnectGraceTimers.delete(key);
    }
  }

  #onSocketClose(context) {
    this.#dequeue(context);
    const room = this.rooms.get(context.roomId);
    if (room && room.status === 'playing' && context.playerId) {
      const hasBot = this.roomBots.has(room.id);
      // Vs bot: forfeit immediately (no human to wait for).
      if (hasBot) {
        room.markDisconnected(context.id);
        try {
          room.forfeit(context.id, { reason: 'quit' });
        } catch (error) {
          console.error('[disconnect bot forfeit]', error);
        }
        this.clients.delete(context.id);
        this.#deleteAbandonedRoom(room);
        return;
      }
      room.markDisconnected(context.id);
      this.clients.delete(context.id);
      const roomId = room.id;
      const playerId = context.playerId;
      const oldClientId = context.id;
      this.#clearDisconnectGrace(roomId, playerId);
      const timer = setTimeout(() => {
        this.disconnectGraceTimers.delete(this.#graceKey(roomId, playerId));
        const live = this.rooms.get(roomId);
        if (!live || live.status !== 'playing') return;
        const seat = live.players.find((p) => p.id === oldClientId || p.playerId === playerId);
        if (!seat || seat.connected) return;
        try {
          live.forfeit(seat.id, { reason: 'quit' });
        } catch (error) {
          console.error('[disconnect forfeit]', error);
        }
        this.#deleteAbandonedRoom(live);
      }, 60_000);
      this.disconnectGraceTimers.set(this.#graceKey(roomId, playerId), timer);
      return;
    }
    room?.removePlayer(context.id);
    this.clients.delete(context.id);
    this.#deleteAbandonedRoom(room);
  }

  async #bindIdentityFromToken(context, command, { allowResume = false } = {}) {
    const token =
      typeof command.token === 'string' && command.token.trim()
        ? command.token.trim()
        : null;
    if (!token) {
      throw new InvalidSessionError('auth_required', 'Session token required');
    }
    const session = await verifySession(token);
    try {
      const dbVersion = await getPlayerTokenVersion(session.playerId);
      if (dbVersion == null || Number(dbVersion) !== Number(session.tokenVersion)) {
        throw new InvalidSessionError('invalid_token', 'Session revoked');
      }
    } catch (error) {
      if (error instanceof InvalidSessionError) throw error;
      if (!error?.message?.includes('MySQL pool not initialized')) {
        throw error;
      }
      // Unit tests / offline: trust JWT when DB unavailable
    }
    const displayName =
      typeof command.displayName === 'string' && command.displayName.trim()
        ? command.displayName.trim().slice(0, 64)
        : null;
    const avatarId =
      typeof command.avatarId === 'string' && command.avatarId.trim()
        ? command.avatarId.trim().slice(0, 64)
        : 'default';
    const deckId =
      typeof command.deckId === 'string' && command.deckId.trim()
        ? command.deckId.trim().slice(0, 64)
        : 'default';

    // Resume disconnected seat in a playing room
    if (allowResume) {
      for (const room of this.rooms.values()) {
        if (room.status !== 'playing') continue;
        const seat = room.findPlayerByPlayerId(session.playerId);
        if (seat && !seat.connected) {
          this.#clearDisconnectGrace(room.id, session.playerId);
          room.reconnectPlayer(seat.id, context.id, {
            displayName,
            avatarId,
            deckId,
          });
          context.roomId = room.id;
          context.playerId = session.playerId;
          context.displayName = displayName;
          context.avatarId = avatarId;
          context.deckId = deckId;
          this.#send(context.socket, {
            type: 'identityAck',
            playerId: context.playerId,
            resumed: true,
            roomId: room.id,
          });
          this.#send(context.socket, room.snapshotFor(context.id));
          return { resumed: true, playerId: session.playerId, displayName, avatarId, deckId };
        }
      }
    }

    context.playerId = session.playerId;
    context.displayName = displayName;
    context.avatarId = avatarId;
    context.deckId = deckId;
    return { resumed: false, playerId: session.playerId, displayName, avatarId, deckId };
  }

  #identityFromCommand(command) {
    const playerId =
      typeof command.playerId === 'string' && command.playerId.trim()
        ? command.playerId.trim().slice(0, 64)
        : null;
    const displayName =
      typeof command.displayName === 'string' && command.displayName.trim()
        ? command.displayName.trim().slice(0, 64)
        : null;
    const avatarId =
      typeof command.avatarId === 'string' && command.avatarId.trim()
        ? command.avatarId.trim().slice(0, 64)
        : 'default';
    const deckId =
      typeof command.deckId === 'string' && command.deckId.trim()
        ? command.deckId.trim().slice(0, 64)
        : 'default';
    return { playerId, displayName, avatarId, deckId };
  }

  async #handle(context, command) {
    if (!command || typeof command.type !== 'string') {
      throw new GameRuleError('invalid_command', 'Command type is required');
    }

    if (command.type === 'identity') {
      const bound = await this.#bindIdentityFromToken(context, command, {
        allowResume: true,
      });
      if (bound.resumed) return;
      this.#send(context.socket, { type: 'identityAck', playerId: context.playerId });
      if (context.playerId) {
        updatePlayerCosmetics({
          playerId: context.playerId,
          avatarId: context.avatarId,
          deckId: context.deckId,
        }).catch((err) => console.error('[identity cosmetics]', err));
      }
      return;
    }

    if (command.type === 'findMatch') {
      this.#leaveCurrentRoom(context);
      this.#dequeue(context);
      await this.#bindIdentityFromToken(context, command);
      if (context.playerId) {
        updatePlayerCosmetics({
          playerId: context.playerId,
          avatarId: context.avatarId,
          deckId: context.deckId,
        }).catch((err) => console.error('[findMatch cosmetics]', err));
      }
      const reqStake = Number(command.stakePool ?? command.stake ?? 50);
      const reqCurrency = command.stakeCurrency === 'chips' ? 'chips' : 'money';
      const allowed = ALLOWED_STAKE_POOLS[reqCurrency].includes(reqStake);
      context.stakePool = allowed ? reqStake : 50;
      context.stakeCurrency = allowed ? reqCurrency : 'money';
      const entryStake = Math.floor(context.stakePool / 2) || context.stakePool;
      try {
        await assertCanAfford(context.playerId, entryStake, context.stakeCurrency);
      } catch (error) {
        if (!error?.message?.includes('MySQL pool not initialized')) {
          this.#error(context.socket, error.code || 'insufficient_funds', error.message);
          return;
        }
      }
      context.queueJoinedAt = Date.now();
      this.matchQueue.push(context);
      this.#tryFormMatch();
      return;
    }

    if (command.type === 'cancelFindMatch') {
      this.#dequeue(context);
      this.#send(context.socket, { type: 'leftQueue' });
      return;
    }

    if (command.type === 'createRoom') {
      this.#dequeue(context);
      this.#leaveCurrentRoom(context);
      await this.#bindIdentityFromToken(context, command);
      if (context.playerId) {
        updatePlayerCosmetics({
          playerId: context.playerId,
          avatarId: context.avatarId,
          deckId: context.deckId,
        }).catch((err) => console.error('[createRoom cosmetics]', err));
      }
      let roomId;
      do roomId = createRoomCode(); while (this.rooms.has(roomId));
      const room = this.#createRoom(roomId, 'private');
      context.roomId = roomId;
      room.addPlayer(context.id, {
        playerId: context.playerId,
        displayName: context.displayName,
        avatarId: context.avatarId,
        deckId: context.deckId,
      });
      return;
    }

    if (command.type === 'joinRoom') {
      this.#dequeue(context);
      const roomId = String(command.roomId ?? '').trim().toUpperCase();
      const room = this.rooms.get(roomId);
      if (!room) throw new GameRuleError('room_not_found', 'Room not found');
      this.#leaveCurrentRoom(context);
      await this.#bindIdentityFromToken(context, command);
      if (context.playerId) {
        updatePlayerCosmetics({
          playerId: context.playerId,
          avatarId: context.avatarId,
          deckId: context.deckId,
        }).catch((err) => console.error('[joinRoom cosmetics]', err));
      }
      context.roomId = roomId;
      room.addPlayer(context.id, {
        playerId: context.playerId,
        displayName: context.displayName,
        avatarId: context.avatarId,
        deckId: context.deckId,
      });
      return;
    }

    if (command.type === 'rematch' && context.roomId) {
      // Staked rematch: tell a short player right away so they can top up,
      // instead of waiting for the opponent to accept.
      const room = this.rooms.get(context.roomId);
      if (room?.matchType === 'random' && room.stakePerPlayer > 0) {
        try {
          await assertCanAfford(context.playerId, room.stakePerPlayer, room.stakeCurrency);
        } catch (error) {
          if (!error?.message?.includes('MySQL pool not initialized')) {
            this.#send(context.socket, {
              type: 'error',
              code: error.code || 'insufficient_funds',
              message: error.message,
              required: room.stakePerPlayer,
              currency: room.stakeCurrency,
            });
            return;
          }
        }
      }
    }

    if (command.type === 'leaveRoom') {
      this.#dequeue(context);
      this.#leaveCurrentRoom(context);
      this.#send(context.socket, { type: 'leftRoom' });
      return;
    }

    if (command.type === 'tableInvite') {
      const targetPlayerId = String(command.targetPlayerId || '').trim();
      const roomId = String(command.roomId || context.roomId || '').trim().toUpperCase();
      if (!targetPlayerId || !roomId) {
        throw new GameRuleError('invalid_invite', 'Target player and room required');
      }

      let delivered = false;
      for (const ctx of this.clients.values()) {
        if (ctx.playerId === targetPlayerId && ctx.socket && ctx.socket.readyState === WebSocket.OPEN) {
          this.#send(ctx.socket, {
            type: 'tableInviteReceived',
            roomId,
            inviterName: context.displayName || 'Friend',
            inviterPlayerId: context.playerId || '',
          });
          delivered = true;
        }
      }

      this.#send(context.socket, {
        type: 'tableInviteSent',
        targetPlayerId,
        roomId,
        delivered,
      });

      void sendToPlayers([targetPlayerId], {
        category: 'invites',
        title: 'Table invite',
        body: `${context.displayName || 'Friend'} invited you to a table`,
        data: {
          type: 'table_invite',
          route: `/join?roomId=${encodeURIComponent(roomId)}`,
          roomId,
          inviterPlayerId: context.playerId || '',
        },
      }).catch((error) => console.error('[fcm] table invite', error));
      return;
    }

    const room = this.rooms.get(context.roomId);
    if (!room) throw new GameRuleError('not_in_room', 'Create or join a room');

    switch (command.type) {
      case 'startGame':
      case 'ready':
        room.ready(context.id);
        break;
      case 'rematch':
        room.rematch(context.id);
        break;
      case 'launch':
        room.launch(context.id);
        break;
      case 'draw':
        room.draw(context.id);
        break;
      case 'tapCard':
        room.tapCard(context.id, command.cardIndex);
        break;
      case 'throwHand':
        room.throwHand(context.id);
        break;
      case 'jackPeek':
        room.jackPeek(context.id, {
          side: command.side,
          cardIndex: command.cardIndex,
        });
        break;
      case 'queenShuffle':
        room.queenShuffle(context.id, { side: command.side });
        break;
      case 'queenReplace':
        room.queenReplace(context.id, {
          youIndex: command.youIndex,
          opponentIndex: command.opponentIndex,
        });
        break;
      case 'endGame':
        room.end(context.id);
        break;
      default:
        throw new GameRuleError('unknown_command', 'Unknown command');
    }
  }

  #dequeue(context) {
    this.#clearMatchTimer(context.id);
    this.matchQueue = this.matchQueue.filter((entry) => entry.id !== context.id);
  }

  #scheduleBotMatch(context) {
    if (this.matchTimers.has(context.id)) return;
    const minDelay = this.botMatchMinDelayMs;
    const maxDelay = this.botMatchMaxDelayMs;
    const delay = minDelay + Math.floor(Math.random() * (Math.max(0, maxDelay - minDelay) + 1));
    const timer = setTimeout(() => {
      this.#matchWithBot(context);
    }, delay);
    this.matchTimers.set(context.id, timer);
  }

  #clearMatchTimer(clientId) {
    const timer = this.matchTimers.get(clientId);
    if (timer) {
      clearTimeout(timer);
      this.matchTimers.delete(clientId);
    }
  }

  async #matchWithBot(context) {
    this.#clearMatchTimer(context.id);
    const queueIndex = this.matchQueue.findIndex((entry) => entry.id === context.id);
    if (queueIndex < 0) return;
    this.matchQueue.splice(queueIndex, 1);

    if (context.socket.readyState !== WebSocket.OPEN) return;

    let botUser;
    try {
      botUser = await acquireBotUser(this.activeBotPlayerIds);
    } catch (error) {
      console.error('[bot] failed to acquire bot user', error);
      return;
    }

    if (context.socket.readyState !== WebSocket.OPEN) return;

    this.activeBotPlayerIds.add(botUser.playerId);

    let roomId;
    do roomId = createRoomCode(); while (this.rooms.has(roomId));
    const stakePool = context.stakePool || 50;
    const stakeCurrency = context.stakeCurrency || 'money';
    const stakePerPlayer = Math.floor(stakePool / 2) || stakePool;
    let escrowed = false;
    try {
      const result = await escrowStake({
        playerIds: [context.playerId, botUser.playerId],
        stake: stakePerPlayer,
        currency: stakeCurrency,
      });
      escrowed = Boolean(result?.escrowed);
    } catch (error) {
      if (!error?.message?.includes('MySQL pool not initialized')) {
        console.error('[bot] escrow failed', error);
        this.activeBotPlayerIds.delete(botUser.playerId);
        this.#error(context.socket, error.code || 'insufficient_funds', error.message);
        // Requeue human for another attempt
        context.queueJoinedAt = Date.now();
        this.matchQueue.push(context);
        this.#scheduleBotMatch(context);
        return;
      }
    }
    const room = this.#createRoom(roomId, 'random', stakePool, stakeCurrency);
    room.escrowed = escrowed;
    context.roomId = roomId;

    const botClientId = `bot-client-${crypto.randomUUID()}`;
    room.addPlayer(context.id, {
      playerId: context.playerId,
      displayName: context.displayName,
      avatarId: context.avatarId || 'default',
      deckId: context.deckId || 'default',
    });
    room.addPlayer(botClientId, {
      playerId: botUser.playerId,
      displayName: botUser.displayName,
      avatarId: botUser.avatarId || 'default',
      deckId: 'default',
    });

    const bot = new ServerRobotPlayer({
      room,
      clientId: botClientId,
    });
    this.roomBots.set(roomId, {
      bot,
      botPlayerId: botUser.playerId,
      botClientId,
    });

    room.start(context.id);
  }

  #tryFormMatch() {
    void this.#tryFormMatchAsync();
  }

  async #tryFormMatchAsync() {
    this.matchQueue = this.matchQueue.filter(
      (ctx) => ctx.socket && ctx.socket.readyState === WebSocket.OPEN
    );

    // Pair only players queued for the same pot (amount and currency).
    const byStake = new Map();
    for (const ctx of this.matchQueue) {
      const key = `${ctx.stakeCurrency || 'money'}:${ctx.stakePool || 50}`;
      if (!byStake.has(key)) byStake.set(key, []);
      byStake.get(key).push(ctx);
    }

    for (const queue of byStake.values()) {
      const stake = queue[0].stakePool || 50;
      const stakeCurrency = queue[0].stakeCurrency || 'money';
      while (queue.length >= 2) {
        const first = queue.shift();
        const second = queue.shift();
        if (!first || !second) break;

        this.#clearMatchTimer(first.id);
        this.#clearMatchTimer(second.id);
        this.matchQueue = this.matchQueue.filter(
          (c) => c.id !== first.id && c.id !== second.id
        );

        const stakePerPlayer = Math.floor(stake / 2) || stake;
        let escrowed = false;
        try {
          const result = await escrowStake({
            playerIds: [first.playerId, second.playerId],
            stake: stakePerPlayer,
            currency: stakeCurrency,
          });
          escrowed = Boolean(result?.escrowed);
        } catch (error) {
          if (!error?.message?.includes('MySQL pool not initialized')) {
            console.error('[matchmaking] escrow failed', error);
            this.#error(first.socket, error.code || 'insufficient_funds', error.message);
            this.#error(second.socket, error.code || 'insufficient_funds', error.message);
            first.queueJoinedAt = Date.now();
            second.queueJoinedAt = Date.now();
            this.matchQueue.push(first, second);
            continue;
          }
        }

        let roomId;
        do roomId = createRoomCode(); while (this.rooms.has(roomId));
        const room = this.#createRoom(roomId, 'random', stake, stakeCurrency);
        room.escrowed = escrowed;
        first.roomId = roomId;
        second.roomId = roomId;
        room.addPlayer(first.id, {
          playerId: first.playerId,
          displayName: first.displayName,
          avatarId: first.avatarId || 'default',
          deckId: first.deckId || 'default',
        });
        room.addPlayer(second.id, {
          playerId: second.playerId,
          displayName: second.displayName,
          avatarId: second.avatarId || 'default',
          deckId: second.deckId || 'default',
        });
        room.start(first.id);
      }
    }

    for (const context of this.matchQueue) {
      if (context.socket && context.socket.readyState === WebSocket.OPEN) {
        this.#scheduleBotMatch(context);
      }
    }
  }

  #createRoom(roomId, matchType = 'private', stakePool = 0, stakeCurrency = 'money') {
    const room = new GameRoom(roomId, {
      onChange: (changedRoom) => {
        this.#broadcastRoom(changedRoom);
        const roomBot = this.roomBots.get(changedRoom.id);
        if (roomBot) {
          roomBot.bot.onRoomChanged();
        }
      },
      onRankedEnd: (payload) => recordRankedMatch(payload),
      beforeRematch: ({ playerIds, stake, currency }) => escrowStake({ playerIds, stake, currency })
        .catch((error) => {
          // Without a DB (tests/local), rematch unstaked as matchmaking does.
          if (error?.message?.includes('MySQL pool not initialized')) {
            return { escrowed: false };
          }
          throw error;
        }),
    });
    room.matchType = matchType;
    room.stakePool = Number(stakePool) || 0;
    room.stakePerPlayer = Math.floor(room.stakePool / 2);
    room.potAmount = room.stakePool;
    room.stakeCurrency = stakeCurrency === 'chips' ? 'chips' : 'money';
    room.escrowed = false;
    this.rooms.set(roomId, room);
    return room;
  }

  #broadcastRoom(room) {
    for (const player of room.players) {
      // A seat left via quit stays in the room but its socket has moved on.
      if (!player.connected) continue;
      const client = this.clients.get(player.id);
      if (client?.socket.readyState === WebSocket.OPEN) {
        this.#send(client.socket, room.snapshotFor(player.id));
      }
    }
  }

  #playerIdFromPath(pathname, suffix) {
    // /players/:id/suffix
    const parts = pathname.split('/').filter(Boolean);
    if (parts.length < 3 || parts[0] !== 'players') return '';
    if (!pathname.endsWith(suffix)) return '';
    return decodeURIComponent(parts[1] || '').trim();
  }

  async #handleDeviceRegister(request, response) {
    const auth = await this.#requireAuth(request, response);
    if (!auth) return;

    let body;
    try {
      body = await readJsonBody(request);
    } catch {
      sendJson(response, 400, { error: 'invalid_json', message: 'Invalid JSON body' });
      return;
    }
    const playerId = auth.playerId;
    const token = typeof body.token === 'string' ? body.token.trim() : '';
    const platformRaw =
      typeof body.platform === 'string' ? body.platform.trim().toLowerCase() : '';
    const platform =
      platformRaw === 'ios' || platformRaw === 'android' ? platformRaw : '';
    if (!playerId || !token || !platform) {
      sendJson(response, 400, {
        error: 'invalid_body',
        message: 'token and platform (android|ios) required',
      });
      return;
    }
    if (token.length > 512) {
      sendJson(response, 400, { error: 'invalid_body', message: 'token too long' });
      return;
    }
    try {
      if (!(await playerExists(playerId))) {
        sendJson(response, 404, { error: 'not_found', message: 'Player not found' });
        return;
      }
      const result = await upsertDeviceToken({ playerId, token, platform });
      sendJson(response, 200, result);
    } catch (error) {
      console.error('[devices/register] failed', error);
      sendJson(response, 500, { error: 'server_error', message: 'Register failed' });
    }
  }

  async #handleDeviceUnregister(request, response) {
    const auth = await this.#requireAuth(request, response);
    if (!auth) return;

    let body;
    try {
      body = await readJsonBody(request);
    } catch {
      sendJson(response, 400, { error: 'invalid_json', message: 'Invalid JSON body' });
      return;
    }
    const playerId = typeof body.playerId === 'string' ? body.playerId.trim() : '';
    const token = typeof body.token === 'string' ? body.token.trim() : '';
    if (!token) {
      sendJson(response, 400, { error: 'invalid_body', message: 'token required' });
      return;
    }
    try {
      const result = await removeDeviceToken({
        playerId: playerId || undefined,
        token,
      });
      sendJson(response, 200, result);
    } catch (error) {
      console.error('[devices/unregister] failed', error);
      sendJson(response, 500, { error: 'server_error', message: 'Unregister failed' });
    }
  }

  async #handleGetNotifyPrefs(request, response, url) {
    const auth = await this.#requireAuth(request, response);
    if (!auth) return;
    const pathPlayerId = this.#playerIdFromPath(url.pathname, '/notify-prefs');
    if (!pathPlayerId || pathPlayerId !== auth.playerId) {
      sendJson(response, 403, { error: 'forbidden', message: 'Cannot access another player' });
      return;
    }
    const playerId = auth.playerId;
    try {
      const prefs = await getNotifyPrefs(playerId);
      if (!prefs) {
        sendJson(response, 404, { error: 'not_found', message: 'Player not found' });
        return;
      }
      sendJson(response, 200, prefs);
    } catch (error) {
      console.error('[notify-prefs] get failed', error);
      sendJson(response, 500, { error: 'server_error', message: 'Prefs fetch failed' });
    }
  }

  async #handleUpdateNotifyPrefs(request, response, url) {
    const auth = await this.#requireAuth(request, response);
    if (!auth) return;
    const pathPlayerId = this.#playerIdFromPath(url.pathname, '/notify-prefs');
    if (!pathPlayerId || pathPlayerId !== auth.playerId) {
      sendJson(response, 403, { error: 'forbidden', message: 'Cannot access another player' });
      return;
    }
    const playerId = auth.playerId;
    let body;
    try {
      body = await readJsonBody(request);
    } catch {
      sendJson(response, 400, { error: 'invalid_json', message: 'Invalid JSON body' });
      return;
    }
    try {
      const prefs = await updateNotifyPrefs({
        playerId,
        invites: typeof body.invites === 'boolean' ? body.invites : undefined,
        social: typeof body.social === 'boolean' ? body.social : undefined,
        ranking: typeof body.ranking === 'boolean' ? body.ranking : undefined,
        marketing: typeof body.marketing === 'boolean' ? body.marketing : undefined,
      });
      sendJson(response, 200, prefs);
    } catch (error) {
      if (error.code === 'not_found') {
        sendJson(response, 404, { error: 'not_found', message: 'Player not found' });
        return;
      }
      console.error('[notify-prefs] update failed', error);
      sendJson(response, 500, { error: 'server_error', message: 'Prefs update failed' });
    }
  }

  async #handleListNotifications(request, response, url) {
    const auth = await this.#requireAuth(request, response);
    if (!auth) return;
    const pathPlayerId = this.#playerIdFromPath(url.pathname, '/notifications');
    if (!pathPlayerId || pathPlayerId !== auth.playerId) {
      sendJson(response, 403, { error: 'forbidden', message: 'Cannot access another player' });
      return;
    }
    const playerId = auth.playerId;
    try {
      if (!(await playerExists(playerId))) {
        sendJson(response, 404, { error: 'not_found', message: 'Player not found' });
        return;
      }
      const limit = Number.parseInt(url.searchParams.get('limit') || '50', 10);
      const offset = Number.parseInt(url.searchParams.get('offset') || '0', 10);
      const inbox = await listPlayerNotifications({ playerId, limit, offset });
      sendJson(response, 200, inbox);
    } catch (error) {
      console.error('[notifications] list failed', error);
      sendJson(response, 500, { error: 'server_error', message: 'Notifications fetch failed' });
    }
  }

  async #handleMarkNotificationsRead(request, response, url) {
    const auth = await this.#requireAuth(request, response);
    if (!auth) return;
    const pathPlayerId = this.#playerIdFromPath(url.pathname, '/notifications/read');
    if (!pathPlayerId || pathPlayerId !== auth.playerId) {
      sendJson(response, 403, { error: 'forbidden', message: 'Cannot access another player' });
      return;
    }
    const playerId = auth.playerId;
    let body;
    try {
      body = await readJsonBody(request);
    } catch {
      sendJson(response, 400, { error: 'invalid_json', message: 'Invalid JSON body' });
      return;
    }
    try {
      const result = await markPlayerNotificationsRead({
        playerId,
        ids: Array.isArray(body.ids) ? body.ids : undefined,
        all: body.all === true,
      });
      sendJson(response, 200, result);
    } catch (error) {
      console.error('[notifications] mark read failed', error);
      sendJson(response, 500, { error: 'server_error', message: 'Mark read failed' });
    }
  }

  async #handleAdminPush(request, response) {
    if (!assertAdminPushSecret(request, response)) return;
    let body;
    try {
      body = await readJsonBody(request);
    } catch {
      sendJson(response, 400, { error: 'invalid_json', message: 'Invalid JSON body' });
      return;
    }

    const dryRun = body.dryRun === true;
    const title = typeof body.title === 'string' ? body.title.trim() : '';
    const pushBody = typeof body.body === 'string' ? body.body.trim() : '';
    if (!dryRun && (!title || !pushBody)) {
      sendJson(response, 400, {
        error: 'invalid_body',
        message: 'title and body required',
      });
      return;
    }

    const routeRaw = typeof body.route === 'string' ? body.route.trim() : '';
    if (routeRaw && !routeRaw.startsWith('/')) {
      sendJson(response, 400, {
        error: 'invalid_route',
        message: 'route must start with /',
      });
      return;
    }

    const explicitIds = Array.isArray(body.playerIds)
      ? [
          ...new Set(
            body.playerIds
              .filter((id) => typeof id === 'string' && id.trim())
              .map((id) => id.trim()),
          ),
        ]
      : [];

    const hasAudienceFilters =
      body.maxLastSeenDays != null ||
      body.requirePushToken != null ||
      body.platforms != null ||
      body.minMatchesPlayed != null ||
      body.maxMatchesPlayed != null ||
      body.minWins != null ||
      body.maxWins != null;

    /** @type {string[] | undefined} */
    let platforms;
    if (Array.isArray(body.platforms)) {
      platforms = body.platforms;
    } else if (typeof body.platforms === 'string' && body.platforms.trim()) {
      const p = body.platforms.trim().toLowerCase();
      if (p === 'android' || p === 'ios') platforms = [p];
      else if (p !== 'all') {
        sendJson(response, 400, {
          error: 'invalid_platforms',
          message: 'platforms must be all|android|ios or array',
        });
        return;
      }
    }

    const audienceFilters = {
      maxLastSeenDays:
        body.maxLastSeenDays != null ? Number(body.maxLastSeenDays) : 30,
      requirePushToken: body.requirePushToken !== false,
      minMatchesPlayed:
        body.minMatchesPlayed != null
          ? Number(body.minMatchesPlayed)
          : undefined,
      maxMatchesPlayed:
        body.maxMatchesPlayed != null
          ? Number(body.maxMatchesPlayed)
          : undefined,
      minWins: body.minWins != null ? Number(body.minWins) : undefined,
      maxWins: body.maxWins != null ? Number(body.maxWins) : undefined,
      platforms,
    };

    try {
      if (dryRun) {
        if (explicitIds.length) {
          sendJson(response, 200, {
            dryRun: true,
            audienceCount: explicitIds.length,
            sampleIds: explicitIds.slice(0, 10),
          });
          return;
        }
        if (hasAudienceFilters) {
          const audienceCount =
            await countMarketingBlastAudience(audienceFilters);
          const sampleIds = (
            await listMarketingBlastAudience({
              ...audienceFilters,
              limit: 10,
            })
          ).slice(0, 10);
          sendJson(response, 200, {
            dryRun: true,
            audienceCount,
            sampleIds,
          });
          return;
        }
        const allIds = await listPlayerIdsWithNotifyPref('marketing');
        sendJson(response, 200, {
          dryRun: true,
          audienceCount: allIds.length,
          sampleIds: allIds.slice(0, 10),
        });
        return;
      }

      /** @type {Record<string, unknown>} */
      const data = {
        ...(body.data && typeof body.data === 'object' ? body.data : {}),
      };
      if (routeRaw) data.route = routeRaw;

      const result = await sendMarketingBlast({
        title,
        body: pushBody,
        data,
        playerIds: explicitIds.length ? explicitIds : undefined,
        audienceFilters:
          !explicitIds.length && hasAudienceFilters
            ? audienceFilters
            : undefined,
      });
      sendJson(response, 200, { ...result, fcmReady: isFcmReady() });
    } catch (error) {
      console.error('[admin/push] failed', error);
      sendJson(response, 500, { error: 'server_error', message: 'Push failed' });
    }
  }

  #notifyPlayer(playerId, payload) {
    if (!playerId) return;
    for (const ctx of this.clients.values()) {
      if (ctx.playerId === playerId && ctx.socket?.readyState === WebSocket.OPEN) {
        this.#send(ctx.socket, payload);
      }
    }
  }

  /** Prefer live WS cosmetics over stale DB default for online players. */
  #enrichAvatarsFromLiveClients(entries) {
    if (!Array.isArray(entries) || entries.length === 0) return;
    const live = new Map();
    for (const ctx of this.clients.values()) {
      if (!ctx.playerId) continue;
      if (ctx.avatarId && ctx.avatarId !== 'default') {
        live.set(ctx.playerId, ctx.avatarId);
      }
    }
    for (const entry of entries) {
      const liveAvatar = live.get(entry.playerId);
      if (liveAvatar) entry.avatarId = liveAvatar;
    }
  }

  /** @internal Test-only alias for #notifyPlayer. */
  notifyPlayerForTest(playerId, payload) {
    this.#notifyPlayer(playerId, payload);
  }

  #leaveCurrentRoom(context) {
    if (!context.roomId) return;
    const room = this.rooms.get(context.roomId);
    // Leaving a live match counts as quitting: settle as a loss, keep the seat
    // (disconnected) so the opponent still sees the result.
    if (room && room.status === 'playing' && room.players.length === 2) {
      room.markDisconnected(context.id);
      try {
        room.forfeit(context.id, { reason: 'quit' });
      } catch (error) {
        console.error('[leave forfeit]', error);
      }
      if (context.playerId) this.#clearDisconnectGrace(room.id, context.playerId);
      context.roomId = null;
      this.#deleteAbandonedRoom(room);
      return;
    }
    room?.removePlayer(context.id);
    context.roomId = null;
    this.#deleteAbandonedRoom(room);
  }

  #deleteAbandonedRoom(room) {
    if (!room) return;
    const humanConnected = room.players.some(
      (player) => player.connected && !player.id.startsWith('bot-client-')
    );
    if (!humanConnected) {
      const roomBot = this.roomBots.get(room.id);
      if (roomBot) {
        roomBot.bot.dispose();
        this.activeBotPlayerIds.delete(roomBot.botPlayerId);
        this.roomBots.delete(room.id);
      }
      room.dispose();
      this.rooms.delete(room.id);
    }
  }

  #withinRateLimit(context) {
    const now = Date.now();
    context.messages = context.messages.filter((time) => now - time < 1000);
    context.messages.push(now);
    return context.messages.length <= 20;
  }

  #error(socket, code, message) {
    this.#send(socket, { type: 'error', code, message });
  }

  #send(socket, payload) {
    if (socket.readyState === WebSocket.OPEN) {
      socket.send(JSON.stringify(payload));
    }
  }
}

module.exports = { GameServer };
