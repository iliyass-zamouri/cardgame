const http = require('http');
const crypto = require('crypto');
const WebSocket = require('ws');
const { GameRoom, GameRuleError, createRoomCode } = require('./game_room');

class GameServer {
  constructor({ port = 8080, host = '127.0.0.1' } = {}) {
    this.port = port;
    this.host = host;
    this.rooms = new Map();
    this.clients = new Map();
    this.httpServer = null;
    this.webSocketServer = null;
  }

  async start() {
    if (this.httpServer) return this.address;

    this.httpServer = http.createServer((request, response) => {
      if (request.url === '/health') {
        response.writeHead(200, { 'content-type': 'application/json' });
        response.end(JSON.stringify({
          status: 'ok',
          rooms: this.rooms.size,
          clients: this.clients.size,
        }));
        return;
      }
      response.writeHead(404);
      response.end();
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
    await new Promise((resolve) => this.webSocketServer?.close(resolve));
    await new Promise((resolve) => this.httpServer?.close(resolve));
    this.webSocketServer = null;
    this.httpServer = null;
  }

  #connect(socket) {
    const context = {
      id: crypto.randomUUID(),
      socket,
      roomId: null,
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
      const room = this.rooms.get(context.roomId);
      room?.removePlayer(context.id);
      this.clients.delete(context.id);
      this.#deleteAbandonedRoom(room);
    });
  }

  #handle(context, command) {
    if (!command || typeof command.type !== 'string') {
      throw new GameRuleError('invalid_command', 'Command type is required');
    }

    if (command.type === 'createRoom') {
      this.#leaveCurrentRoom(context);
      let roomId;
      do roomId = createRoomCode(); while (this.rooms.has(roomId));
      const room = this.#createRoom(roomId);
      context.roomId = roomId;
      room.addPlayer(context.id);
      return;
    }

    if (command.type === 'joinRoom') {
      const roomId = String(command.roomId ?? '').trim().toUpperCase();
      const room = this.rooms.get(roomId);
      if (!room) throw new GameRuleError('room_not_found', 'Room not found');
      this.#leaveCurrentRoom(context);
      context.roomId = roomId;
      room.addPlayer(context.id);
      return;
    }

    if (command.type === 'leaveRoom') {
      this.#leaveCurrentRoom(context);
      this.#send(context.socket, { type: 'leftRoom' });
      return;
    }

    const room = this.rooms.get(context.roomId);
    if (!room) throw new GameRuleError('not_in_room', 'Create or join a room');

    switch (command.type) {
      case 'startGame':
        room.start(context.id);
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
      case 'endGame':
        room.end(context.id);
        break;
      default:
        throw new GameRuleError('unknown_command', 'Unknown command');
    }
  }

  #createRoom(roomId) {
    const room = new GameRoom(roomId, {
      onChange: (changedRoom) => this.#broadcastRoom(changedRoom),
    });
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
