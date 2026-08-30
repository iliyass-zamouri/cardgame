const http = require('http');
const crypto = require('crypto');
const { URL } = require('url');
const WebSocket = require('ws');
const { GameRoom, GameRuleError, createRoomCode } = require('./game_room');
const { sendJson, readJsonBody, corsHeaders } = require('./http_util');
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
const { authenticateOAuth } = require('./auth/oauth');
const { findOrCreateGuest } = require('./db/store');
const {
  recordRankedMatch,
  getLeaderboard,
  getPlayerRank,
  getMatchHistory,
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
} = require('./db/friends');
const {
  getPlayerInventory,
  exchangeCurrency,
  purchaseItem,
  claimRewardedAdBonus,
} = require('./db/marketplace');
const { acquireBotUser } = require('./db/bots');
const { ServerRobotPlayer } = require('./bot_player');

class GameServer {
  constructor({
    port = 8080,
    host = '127.0.0.1',
    botMatchMinDelayMs = 10000,
    botMatchMaxDelayMs = 30000,
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

    await new Promise((resolve, reject) => {
      this.httpServer.once('error', reject);
      this.httpServer.listen(this.port, this.host, resolve);
    });
    return this.address;
  }

  get address() {
    const address = this.httpServer?.address();
    return typeof address === 'object' && address
      ? { host: this.host, port: address.port }
      : null;
  }

  async stop() {
    for (const timer of this.matchTimers.values()) clearTimeout(timer);
    this.matchTimers.clear();
    for (const roomBot of this.roomBots.values()) roomBot.bot.dispose();
    this.roomBots.clear();
    this.activeBotPlayerIds.clear();
    for (const room of this.rooms.values()) room.dispose();
    for (const context of this.clients.values()) context.socket.terminate();
    this.rooms.clear();
    this.clients.clear();
    this.matchQueue = [];
    await new Promise((resolve) => this.webSocketServer?.close(resolve));
    await new Promise((resolve) => this.httpServer?.close(resolve));
    this.webSocketServer = null;
    this.httpServer = null;
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

  async #handlePlayerRank(_request, response, url) {
    const playerId = url.searchParams.get('playerId');
    if (!playerId) {
      sendJson(response, 400, {
        error: 'missing_player_id',
        message: 'playerId is required',
      });
      return;
    }
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

  async #handleMatchHistory(_request, response, url) {
    const playerId = url.searchParams.get('playerId');
    if (!playerId) {
      sendJson(response, 400, {
        error: 'missing_player_id',
        message: 'playerId is required',
      });
      return;
    }
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

  async #handleCheckUsername(_request, response, url) {
    const username = url.searchParams.get('username');
    const playerId = url.searchParams.get('playerId');
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
    let body;
    try {
      body = await readJsonBody(request);
    } catch {
      sendJson(response, 400, { error: 'invalid_json', message: 'Invalid JSON body' });
      return;
    }

    const { playerId, name, username } = body || {};
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
      sendJson(response, 200, {
        playerId: updated.id,
        name: updated.display_name,
        username: updated.username,
        authType: updated.auth_type,
        elo: updated.elo,
        totalPoints: updated.total_points,
      });
    } catch (error) {
      if (error.code === 'invalid_format' || error.code === 'username_taken') {
        sendJson(response, error.code === 'username_taken' ? 409 : 400, {
          error: error.code,
          message: error.message,
        });
        return;
      }
      console.error('[player/profile]', error);
      sendJson(response, 500, { error: 'server_error', message: 'Failed to update profile' });
    }
  }

  async #handleSearchPlayers(_request, response, url) {
    const query = url.searchParams.get('query') || '';
    const playerId = url.searchParams.get('playerId') || null;
    const limit = url.searchParams.get('limit') || 20;

    try {
      const onlinePlayerIds = this.#getOnlinePlayerIds();
      const results = await searchPlayers({
        query,
        playerId,
        limit,
        onlinePlayerIds,
      });
      sendJson(response, 200, results);
    } catch (error) {
      console.error('[friends/search]', error);
      sendJson(response, 500, { error: 'server_error', message: 'Failed to search players' });
    }
  }

  async #handleGetFriends(_request, response, url) {
    const playerId = url.searchParams.get('playerId');
    if (!playerId) {
      sendJson(response, 400, { error: 'missing_player_id', message: 'playerId is required' });
      return;
    }

    try {
      const onlinePlayerIds = this.#getOnlinePlayerIds();
      const payload = await getPlayerFriends({ playerId, onlinePlayerIds });
      sendJson(response, 200, payload);
    } catch (error) {
      console.error('[friends]', error);
      sendJson(response, 500, { error: 'server_error', message: 'Failed to get friends' });
    }
  }

  async #handleSendFriendRequest(request, response) {
    let body;
    try {
      body = await readJsonBody(request);
    } catch {
      sendJson(response, 400, { error: 'invalid_json', message: 'Invalid JSON body' });
      return;
    }

    const { playerId, targetPlayerId, targetUsername } = body || {};
    if (!playerId) {
      sendJson(response, 400, { error: 'missing_player_id', message: 'playerId is required' });
      return;
    }

    try {
      const result = await sendFriendRequest({ playerId, targetPlayerId, targetUsername });
      sendJson(response, 200, result);
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
    let body;
    try {
      body = await readJsonBody(request);
    } catch {
      sendJson(response, 400, { error: 'invalid_json', message: 'Invalid JSON body' });
      return;
    }

    const { playerId, requesterId, requestId } = body || {};
    if (!playerId) {
      sendJson(response, 400, { error: 'missing_player_id', message: 'playerId is required' });
      return;
    }

    try {
      const result = await acceptFriendRequest({ playerId, requesterId, requestId });
      sendJson(response, 200, result);
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
    let body;
    try {
      body = await readJsonBody(request);
    } catch {
      sendJson(response, 400, { error: 'invalid_json', message: 'Invalid JSON body' });
      return;
    }

    const { playerId, requesterId, requestId } = body || {};
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
    let body;
    try {
      body = await readJsonBody(request);
    } catch {
      sendJson(response, 400, { error: 'invalid_json', message: 'Invalid JSON body' });
      return;
    }

    const { playerId, targetPlayerId, requestId } = body || {};
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
    let body;
    try {
      body = await readJsonBody(request);
    } catch {
      sendJson(response, 400, { error: 'invalid_json', message: 'Invalid JSON body' });
      return;
    }

    const { playerId, friendId, friendshipId } = body || {};
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

  async #handleGetInventory(_request, response, url) {
    const playerId = url.searchParams.get('playerId');
    if (!playerId) {
      sendJson(response, 400, { error: 'missing_player_id', message: 'playerId is required' });
      return;
    }

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
    let body;
    try {
      body = await readJsonBody(request);
    } catch {
      sendJson(response, 400, { error: 'invalid_json', message: 'Invalid JSON body' });
      return;
    }

    const { playerId, direction, amount } = body || {};
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
    let body;
    try {
      body = await readJsonBody(request);
    } catch {
      sendJson(response, 400, { error: 'invalid_json', message: 'Invalid JSON body' });
      return;
    }

    const { playerId, itemType, itemId, currency, price } = body || {};
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
    let body;
    try {
      body = await readJsonBody(request);
    } catch {
      sendJson(response, 400, { error: 'invalid_json', message: 'Invalid JSON body' });
      return;
    }

    const { playerId } = body || {};
    if (!playerId) {
      sendJson(response, 400, { error: 'missing_player_id', message: 'playerId is required' });
      return;
    }

    try {
      const result = await claimRewardedAdBonus(playerId);
      sendJson(response, 200, result);
    } catch (error) {
      if (error.code === 'player_not_found') {
        sendJson(response, 404, { error: error.code, message: error.message });
        return;
      }
      console.error('[marketplace/claim-ad-reward]', error);
      sendJson(response, 500, { error: 'server_error', message: 'Failed to claim ad reward' });
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
      sendJson(response, 200, identity);
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

    try {
      const claims = await verifyGoogleIdToken(idToken);
      const identity = await authenticateOAuth({
        provider: 'google',
        sub: claims.sub,
        displayNameHint: claims.name ?? null,
        deviceId,
        clientIp,
      });
      sendJson(response, 200, identity);
    } catch (error) {
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
      try {
        const command = JSON.parse(raw.toString());
        this.#handle(context, command);
      } catch (error) {
        if (error instanceof GameRuleError) {
          this.#error(socket, error.code, error.message);
        } else if (error instanceof SyntaxError) {
          this.#error(socket, 'invalid_json', 'Message must be valid JSON');
        } else {
          console.error(error);
          this.#error(socket, 'server_error', 'Command failed');
        }
      }
    });

    socket.on('close', () => {
      this.#dequeue(context);
      const room = this.rooms.get(context.roomId);
      room?.removePlayer(context.id);
      this.clients.delete(context.id);
      this.#deleteAbandonedRoom(room);
    });
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
    return { playerId, displayName };
  }

  #handle(context, command) {
    if (!command || typeof command.type !== 'string') {
      throw new GameRuleError('invalid_command', 'Command type is required');
    }

    if (command.type === 'identity') {
      const identity = this.#identityFromCommand(command);
      context.playerId = identity.playerId;
      context.displayName = identity.displayName;
      this.#send(context.socket, { type: 'identityAck', playerId: context.playerId });
      return;
    }

    if (command.type === 'findMatch') {
      this.#leaveCurrentRoom(context);
      this.#dequeue(context);
      const identity = this.#identityFromCommand(command);
      context.playerId = identity.playerId;
      context.displayName = identity.displayName;
      const allowedStakes = [20, 50, 100, 200, 500];
      const reqStake = Number(command.stakePool ?? command.stake ?? 50);
      context.stakePool = allowedStakes.includes(reqStake) ? reqStake : 50;
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
      const identity = this.#identityFromCommand(command);
      context.playerId = identity.playerId;
      context.displayName = identity.displayName;
      let roomId;
      do roomId = createRoomCode(); while (this.rooms.has(roomId));
      const room = this.#createRoom(roomId, 'private');
      context.roomId = roomId;
      room.addPlayer(context.id, {
        playerId: context.playerId,
        displayName: context.displayName,
      });
      return;
    }

    if (command.type === 'joinRoom') {
      this.#dequeue(context);
      const roomId = String(command.roomId ?? '').trim().toUpperCase();
      const room = this.rooms.get(roomId);
      if (!room) throw new GameRuleError('room_not_found', 'Room not found');
      this.#leaveCurrentRoom(context);
      const identity = this.#identityFromCommand(command);
      context.playerId = identity.playerId;
      context.displayName = identity.displayName;
      context.roomId = roomId;
      room.addPlayer(context.id, {
        playerId: context.playerId,
        displayName: context.displayName,
      });
      return;
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
    const room = this.#createRoom(roomId, 'random', stakePool);
    context.roomId = roomId;

    const botClientId = `bot-client-${crypto.randomUUID()}`;
    room.addPlayer(context.id, {
      playerId: context.playerId,
      displayName: context.displayName,
    });
    room.addPlayer(botClientId, {
      playerId: botUser.playerId,
      displayName: botUser.displayName,
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
    this.matchQueue = this.matchQueue.filter(
      (ctx) => ctx.socket && ctx.socket.readyState === WebSocket.OPEN
    );

    const byStake = new Map();
    for (const ctx of this.matchQueue) {
      const stake = ctx.stakePool || 50;
      if (!byStake.has(stake)) byStake.set(stake, []);
      byStake.get(stake).push(ctx);
    }

    for (const [stake, queue] of byStake.entries()) {
      while (queue.length >= 2) {
        const first = queue.shift();
        const second = queue.shift();
        if (!first || !second) break;

        this.#clearMatchTimer(first.id);
        this.#clearMatchTimer(second.id);
        this.matchQueue = this.matchQueue.filter(
          (c) => c.id !== first.id && c.id !== second.id
        );

        let roomId;
        do roomId = createRoomCode(); while (this.rooms.has(roomId));
        const room = this.#createRoom(roomId, 'random', stake);
        first.roomId = roomId;
        second.roomId = roomId;
        room.addPlayer(first.id, {
          playerId: first.playerId,
          displayName: first.displayName,
        });
        room.addPlayer(second.id, {
          playerId: second.playerId,
          displayName: second.displayName,
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

  #createRoom(roomId, matchType = 'private', stakePool = 0) {
    const room = new GameRoom(roomId, {
      onChange: (changedRoom) => {
        this.#broadcastRoom(changedRoom);
        const roomBot = this.roomBots.get(changedRoom.id);
        if (roomBot) {
          roomBot.bot.onRoomChanged();
        }
      },
      onRankedEnd: (payload) => recordRankedMatch(payload),
    });
    room.matchType = matchType;
    room.stakePool = Number(stakePool) || 0;
    room.stakePerPlayer = Math.floor(room.stakePool / 2);
    room.potAmount = room.stakePool;
    this.rooms.set(roomId, room);
    return room;
  }

  #broadcastRoom(room) {
    for (const player of room.players) {
      const client = this.clients.get(player.id);
      if (client?.socket.readyState === WebSocket.OPEN) {
        this.#send(client.socket, room.snapshotFor(player.id));
      }
    }
  }

  #leaveCurrentRoom(context) {
    if (!context.roomId) return;
    const room = this.rooms.get(context.roomId);
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
