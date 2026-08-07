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

class GameServer {
  constructor({ port = 8080, host = '127.0.0.1' } = {}) {
    this.port = port;
    this.host = host;
    this.rooms = new Map();
    this.clients = new Map();
    /** @type {Array<object>} FIFO matchmaking queue of client contexts */
    this.matchQueue = [];
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

    if (command.type === 'findMatch') {
      this.#leaveCurrentRoom(context);
      this.#dequeue(context);
      const identity = this.#identityFromCommand(command);
      context.playerId = identity.playerId;
      context.displayName = identity.displayName;
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
    this.matchQueue = this.matchQueue.filter((entry) => entry.id !== context.id);
  }

  #tryFormMatch() {
    while (this.matchQueue.length >= 2) {
      const first = this.matchQueue.shift();
      const second = this.matchQueue.shift();
      if (!first || !second) break;
      if (
        first.socket.readyState !== WebSocket.OPEN
        || second.socket.readyState !== WebSocket.OPEN
      ) {
        if (first.socket.readyState === WebSocket.OPEN) {
          this.matchQueue.unshift(first);
        }
        if (second.socket.readyState === WebSocket.OPEN) {
          this.matchQueue.unshift(second);
        }
        continue;
      }

      let roomId;
      do roomId = createRoomCode(); while (this.rooms.has(roomId));
      const room = this.#createRoom(roomId, 'random');
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

  #createRoom(roomId, matchType = 'private') {
    const room = new GameRoom(roomId, {
      onChange: (changedRoom) => this.#broadcastRoom(changedRoom),
      onRankedEnd: (payload) => recordRankedMatch(payload),
    });
    room.matchType = matchType;
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
    if (!room || room.players.some((player) => player.connected)) return;
    room.dispose();
    this.rooms.delete(room.id);
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
