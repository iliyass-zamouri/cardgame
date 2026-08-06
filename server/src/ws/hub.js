import crypto from 'node:crypto';
import { createMatchRecord, finishMatchRecord } from '../domain/store.js';
import { ProtocolEvents, decodeEnvelope, encodeEnvelope } from '../protocol.js';
import { PrivateLobby, normalizeRoomCode } from './lobby.js';
import { MatchRoom } from './match_room.js';
import { MatchQueue } from './queue.js';
import { RematchSession } from './rematch.js';

export class WsHub {
  constructor() {
    this._connections = new Map();
    this._rooms = new Map();
    this._roomByConnection = new Map();
    this._roomByPlayer = new Map();
    this._connectionSeq = 0;
    this._lobbies = new Map();
    this._lobbyByConnection = new Map();
    this._connectionsByPlayer = new Map();
    this._rematches = new Map();
    this._rematchByConnection = new Map();
    this._rematchByMatch = new Map();
    this._queue = new MatchQueue(({ stake, players }) => {
      void this._createRoom({ stake, mode: 'quick', players });
    });
  }

  get connectionCount() {
    return this._connections.size;
  }

  get roomCount() {
    return this._rooms.size;
  }

  _conn(connectionId) {
    return this._connections.get(connectionId);
  }

  _assertPlayer(connectionId, payloadPlayerId) {
    const conn = this._conn(connectionId);
    if (!conn) return { ok: false, code: 'no_connection' };
    if (!conn.authPlayerId) {
      return { ok: false, code: 'auth_required', message: 'WebSocket token required' };
    }
    if (payloadPlayerId && payloadPlayerId !== conn.authPlayerId) {
      return { ok: false, code: 'forbidden', message: 'playerId mismatch' };
    }
    return { ok: true, conn };
  }

  setAuth(connectionId, playerId) {
    const conn = this._conn(connectionId);
    if (!conn) return;
    const old = conn.playerId;
    conn.authPlayerId = playerId;
    conn.playerId = playerId;
    if (old && old !== playerId) {
      const set = this._connectionsByPlayer.get(old);
      set?.delete(connectionId);
    }
    this._indexPlayerConnection(playerId, connectionId);
  }

  attach(socket, { playerId = null } = {}) {
    this._connectionSeq += 1;
    const connectionId = `conn-${this._connectionSeq}`;
    const fallbackId = playerId ?? `tmp_${crypto.randomBytes(4).toString('hex')}`;
    this._connections.set(connectionId, {
      id: connectionId,
      playerId: fallbackId,
      authPlayerId: playerId,
      socket,
    });
    this._indexPlayerConnection(fallbackId, connectionId);

    socket.on('message', (data) => {
      const raw = typeof data === 'string' ? data : data.toString('utf8');
      this._onMessage(connectionId, raw);
    });
    socket.on('close', () => this._onDisconnect(connectionId));
    socket.on('error', () => this._onDisconnect(connectionId));
  }

  sendTo(connectionId, raw) {
    const conn = this._connections.get(connectionId);
    if (!conn || conn.socket.readyState !== 1) return;
    conn.socket.send(raw);
  }

  _indexPlayerConnection(playerId, connectionId) {
    const set = this._connectionsByPlayer.get(playerId) ?? new Set();
    set.add(connectionId);
    this._connectionsByPlayer.set(playerId, set);
  }

  _rebindPlayer(connectionId, playerId, displayName) {
    const conn = this._connections.get(connectionId);
    if (!conn) return;
    const old = conn.playerId;
    if (old && old !== playerId) {
      const set = this._connectionsByPlayer.get(old);
      set?.delete(connectionId);
    }
    conn.playerId = playerId;
    conn.displayName = displayName ?? conn.displayName;
    this._indexPlayerConnection(playerId, connectionId);

    const matchId = this._roomByPlayer.get(playerId);
    if (matchId) {
      const room = this._rooms.get(matchId);
      room?.rebind(playerId, connectionId);
      this._roomByConnection.set(connectionId, matchId);
    }
  }

  async _createRoom({ stake, mode, players, roomCode = null, rematch = null }) {
    const { publicId } = await createMatchRecord({ players, stake, mode, roomCode });
    const session =
      rematch ??
      new RematchSession({
        mode,
        roomCode,
        stake,
        expectedPlayers: players.length,
        eligiblePlayerIds: players.map((p) => p.playerId),
        matchesPlayed: 0,
      });
    this._rematches.set(session.id, session);
    this._rematchByMatch.set(publicId, session.id);

    const room = new MatchRoom({
      matchId: publicId,
      players,
      stake,
      mode,
      roomCode: session.roomCode,
      rematchId: session.id,
      matchesPlayed: session.matchesPlayed,
      send: (connectionId, raw) => this.sendTo(connectionId, raw),
      onClosed: (id) => this._onRoomClosed(id),
      onFinished: (result) => {
        session.bumpMatchesPlayed();
        room.matchesPlayed = session.matchesPlayed;
        session.refreshEligible(
          result.participants.map((p) => p.playerId),
          result.participants.length,
        );
        session.scheduleIdle((idle) => this._dissolveRematch(idle));

        for (const connectionId of room.connectionIds) {
          this._roomByConnection.delete(connectionId);
        }
        for (const p of result.participants) {
          this._roomByPlayer.delete(p.playerId);
        }

        const offer = encodeEnvelope(ProtocolEvents.rematchState, session.toWireState());
        for (const connectionId of room.connectionIds) {
          this.sendTo(connectionId, offer);
        }

        const scores = result.participants;
        void finishMatchRecord({
          publicId: result.matchId,
          winnerPublicId: result.winnerId,
          player1Score: scores[0]?.score ?? 0,
          player2Score: scores[1]?.score ?? 0,
          stake: result.stake,
        }).catch((error) => console.error('[db] finishMatch failed', error));
      },
    });

    this._rooms.set(publicId, room);
    for (const p of players) {
      this._roomByConnection.set(p.connectionId, publicId);
      this._roomByPlayer.set(p.playerId, publicId);
      this.sendTo(
        p.connectionId,
        encodeEnvelope(ProtocolEvents.matchFound, {
          matchId: publicId,
          localPlayerId: p.playerId,
          players: players.map((x) => ({
            id: x.playerId,
            displayName: x.displayName,
          })),
          rematchId: session.id,
          matchesPlayed: session.matchesPlayed,
          mode,
          roomCode: session.roomCode,
          stake,
        }),
      );
    }
    room.broadcastSnapshot();
    return { room, matchId: publicId, rematch: session };
  }

  _onRoomClosed(matchId) {
    this._rooms.delete(matchId);
  }

  _dissolveRematch(session) {
    session.dissolve();
    this._rematches.delete(session.id);
    for (const [connId, rematchId] of [...this._rematchByConnection.entries()]) {
      if (rematchId === session.id) this._rematchByConnection.delete(connId);
    }
  }

  _onMessage(connectionId, raw) {
    const envelope = decodeEnvelope(raw);
    if (!envelope) {
      this.sendTo(
        connectionId,
        encodeEnvelope(ProtocolEvents.matchError, {
          code: 'bad_envelope',
          message: 'Invalid message format',
        }),
      );
      return;
    }

    const { event, payload } = envelope;
    try {
      switch (event) {
        case ProtocolEvents.matchQueue:
          this._handleQueue(connectionId, payload);
          break;
        case ProtocolEvents.matchCancel:
          this._queue.cancel(connectionId);
          break;
        case ProtocolEvents.matchJoin:
          this._handleMatchJoin(connectionId, payload);
          break;
        case ProtocolEvents.matchLeave:
          this._handleMatchLeave(connectionId);
          break;
        case ProtocolEvents.cardAction:
          this._handleCardAction(connectionId, payload);
          break;
        case ProtocolEvents.roomCreate:
          this._handleRoomCreate(connectionId, payload);
          break;
        case ProtocolEvents.roomJoin:
          this._handleRoomJoin(connectionId, payload);
          break;
        case ProtocolEvents.roomLeave:
          this._handleRoomLeave(connectionId);
          break;
        case ProtocolEvents.roomStart:
          this._handleRoomStart(connectionId);
          break;
        case ProtocolEvents.roomKick:
          this._handleRoomKick(connectionId, payload);
          break;
        case ProtocolEvents.roomInvite:
          this._handleRoomInvite(connectionId, payload);
          break;
        case ProtocolEvents.roomPresence:
          this._handlePresence(connectionId, payload);
          break;
        case ProtocolEvents.rematchJoin:
          this._handleRematchJoin(connectionId, payload);
          break;
        case ProtocolEvents.rematchReady:
          this._handleRematchReady(connectionId, payload);
          break;
        case ProtocolEvents.rematchLeave:
          this._handleRematchLeave(connectionId, payload);
          break;
        default:
          this.sendTo(
            connectionId,
            encodeEnvelope(ProtocolEvents.matchError, {
              code: 'unknown_event',
              message: `Unknown event ${event}`,
            }),
          );
      }
    } catch (error) {
      this.sendTo(
        connectionId,
        encodeEnvelope(ProtocolEvents.matchError, {
          code: 'handler_error',
          message: error.message ?? 'Handler error',
        }),
      );
    }
  }

  _handle(connectionId) {
    return this._conn(connectionId);
  }

  _handleQueue(connectionId, payload) {
    const auth = this._assertPlayer(connectionId, payload.playerId);
    if (!auth.ok) {
      this.sendTo(
        connectionId,
        encodeEnvelope(ProtocolEvents.matchError, {
          code: auth.code,
          message: auth.message ?? auth.code,
        }),
      );
      return;
    }
    const conn = auth.conn;
    if (payload.playerId) {
      this._rebindPlayer(connectionId, payload.playerId, payload.displayName);
    }
    this._leaveLobby(connectionId);
    this._queue.enqueue({
      connectionId,
      playerId: conn.playerId,
      displayName: payload.displayName ?? conn.displayName,
      stake: payload.stake ?? 100,
    });
  }

  _handleMatchJoin(connectionId, payload) {
    const conn = this._conn(connectionId);
    if (!conn) return;
    if (payload.playerId) this._rebindPlayer(connectionId, payload.playerId);
    const room = this._rooms.get(payload.matchId);
    if (!room) {
      this.sendTo(
        connectionId,
        encodeEnvelope(ProtocolEvents.matchError, {
          code: 'match_not_found',
          message: 'Match not found',
        }),
      );
      return;
    }
    room.rebind(conn.playerId, connectionId);
    this._roomByConnection.set(connectionId, room.matchId);
  }

  _handleMatchLeave(connectionId) {
    const matchId = this._roomByConnection.get(connectionId);
    if (!matchId) return;
    const room = this._rooms.get(matchId);
    room?.close();
    this._roomByConnection.delete(connectionId);
  }

  _handleCardAction(connectionId, payload) {
    const matchId = this._roomByConnection.get(connectionId);
    const room = matchId ? this._rooms.get(matchId) : null;
    if (!room) {
      this.sendTo(
        connectionId,
        encodeEnvelope(ProtocolEvents.matchError, {
          code: 'not_in_match',
          message: 'Not in a match',
        }),
      );
      return;
    }
    room.handleAction(connectionId, payload);
  }

  _broadcastLobby(lobby, reason) {
    const wire = encodeEnvelope(ProtocolEvents.roomState, lobby.toWireState(reason));
    for (const m of lobby.members) {
      this.sendTo(m.connectionId, wire);
    }
  }

  _handleRoomCreate(connectionId, payload) {
    const auth = this._assertPlayer(connectionId, payload.playerId);
    if (!auth.ok) {
      this.sendTo(
        connectionId,
        encodeEnvelope(ProtocolEvents.matchError, {
          code: auth.code,
          message: auth.message ?? auth.code,
        }),
      );
      return;
    }
    if (payload.playerId) {
      this._rebindPlayer(connectionId, payload.playerId, payload.displayName);
    }
    this._leaveLobby(connectionId);
    const lobby = new PrivateLobby({
      host: {
        playerId: this._conn(connectionId).playerId,
        connectionId,
        displayName: payload.displayName,
      },
      stake: payload.stake ?? 100,
    });
    this._lobbies.set(lobby.code, lobby);
    this._lobbyByConnection.set(connectionId, lobby.code);
    this._broadcastLobby(lobby);
  }

  _handleRoomJoin(connectionId, payload) {
    const auth = this._assertPlayer(connectionId, payload.playerId);
    if (!auth.ok) {
      this.sendTo(
        connectionId,
        encodeEnvelope(ProtocolEvents.matchError, {
          code: auth.code,
          message: auth.message ?? auth.code,
        }),
      );
      return;
    }
    if (payload.playerId) {
      this._rebindPlayer(connectionId, payload.playerId, payload.displayName);
    }
    const code = normalizeRoomCode(payload.code);
    const lobby = this._lobbies.get(code);
    if (!lobby || lobby.closed) {
      this.sendTo(
        connectionId,
        encodeEnvelope(ProtocolEvents.matchError, {
          code: 'room_not_found',
          message: 'Room not found',
        }),
      );
      return;
    }
    this._leaveLobby(connectionId);
    try {
      lobby.add({
        playerId: this._conn(connectionId).playerId,
        connectionId,
        displayName: payload.displayName,
      });
    } catch {
      this.sendTo(
        connectionId,
        encodeEnvelope(ProtocolEvents.matchError, {
          code: 'room_full',
          message: 'Room is full',
        }),
      );
      return;
    }
    this._lobbyByConnection.set(connectionId, lobby.code);
    this._broadcastLobby(lobby);
  }

  _leaveLobby(connectionId) {
    const code = this._lobbyByConnection.get(connectionId);
    if (!code) return;
    const lobby = this._lobbies.get(code);
    this._lobbyByConnection.delete(connectionId);
    if (!lobby) return;
    const conn = this._conn(connectionId);
    lobby.remove(conn?.playerId);
    if (lobby.closed || !lobby.members.length) {
      this._lobbies.delete(code);
    } else {
      this._broadcastLobby(lobby);
    }
  }

  _handleRoomLeave(connectionId) {
    this._leaveLobby(connectionId);
  }

  async _handleRoomStart(connectionId) {
    const code = this._lobbyByConnection.get(connectionId);
    const lobby = code ? this._lobbies.get(code) : null;
    if (!lobby) return;
    const conn = this._conn(connectionId);
    if (conn?.playerId !== lobby.hostPlayerId) {
      this.sendTo(
        connectionId,
        encodeEnvelope(ProtocolEvents.matchError, {
          code: 'forbidden',
          message: 'Only host can start',
        }),
      );
      return;
    }
    if (lobby.members.length < 2) {
      this.sendTo(
        connectionId,
        encodeEnvelope(ProtocolEvents.matchError, {
          code: 'not_ready',
          message: 'Need 2 players',
        }),
      );
      return;
    }
    const players = lobby.members.map((m) => ({
      playerId: m.playerId,
      connectionId: m.connectionId,
      displayName: m.name,
    }));
    for (const m of lobby.members) {
      this._lobbyByConnection.delete(m.connectionId);
    }
    lobby.closed = true;
    this._lobbies.delete(lobby.code);
    this._broadcastLobby(lobby, 'started');
    await this._createRoom({
      stake: lobby.stake,
      mode: 'private',
      players,
      roomCode: lobby.code,
    });
  }

  _handleRoomKick(connectionId, payload) {
    const code = this._lobbyByConnection.get(connectionId);
    const lobby = code ? this._lobbies.get(code) : null;
    if (!lobby) return;
    const conn = this._conn(connectionId);
    try {
      lobby.kick(conn.playerId, payload.targetPlayerId);
    } catch {
      this.sendTo(
        connectionId,
        encodeEnvelope(ProtocolEvents.matchError, {
          code: 'forbidden',
          message: 'Cannot kick',
        }),
      );
      return;
    }
    for (const [cid, c] of this._connections.entries()) {
      if (c.playerId === payload.targetPlayerId) {
        this._lobbyByConnection.delete(cid);
        this.sendTo(
          cid,
          encodeEnvelope(ProtocolEvents.roomState, {
            ...lobby.toWireState('kicked'),
            closed: true,
          }),
        );
      }
    }
    this._broadcastLobby(lobby);
  }

  _handleRoomInvite(connectionId, payload) {
    const code = this._lobbyByConnection.get(connectionId);
    const lobby = code ? this._lobbies.get(code) : null;
    if (!lobby) return;
    const targets = payload.targetPlayerIds ?? [];
    for (const targetId of targets) {
      const set = this._connectionsByPlayer.get(targetId);
      if (!set) continue;
      for (const cid of set) {
        this.sendTo(
          cid,
          encodeEnvelope(ProtocolEvents.roomState, {
            code: lobby.code,
            hostPlayerId: lobby.hostPlayerId,
            members: lobby.toWireState().members,
            stake: lobby.stake,
            closed: false,
            reason: 'invite',
          }),
        );
      }
    }
  }

  _handlePresence(connectionId, payload) {
    const conn = this._conn(connectionId);
    if (payload.playerId) {
      this._rebindPlayer(connectionId, payload.playerId);
    }
    const ids = payload.playerIds ?? [];
    const online = ids.filter((id) => (this._connectionsByPlayer.get(id)?.size ?? 0) > 0);
    this.sendTo(
      connectionId,
      encodeEnvelope(ProtocolEvents.roomPresence, {
        playerId: conn?.playerId,
        playerIds: ids,
        onlinePlayerIds: online,
      }),
    );
  }

  _handleRematchJoin(connectionId, payload) {
    const conn = this._conn(connectionId);
    if (!conn) return;
    if (payload.playerId) {
      this._rebindPlayer(connectionId, payload.playerId, payload.displayName);
    }
    let session = this._rematches.get(payload.rematchId);
    if (!session && payload.matchId) {
      const rematchId = this._rematchByMatch.get(payload.matchId);
      session = rematchId ? this._rematches.get(rematchId) : null;
    }
    if (!session || session.closed) {
      this.sendTo(
        connectionId,
        encodeEnvelope(ProtocolEvents.matchError, {
          code: 'rematch_gone',
          message: 'Rematch unavailable',
        }),
      );
      return;
    }
    session.join({
      playerId: this._conn(connectionId).playerId,
      connectionId,
      displayName: payload.displayName,
    });
    this._rematchByConnection.set(connectionId, session.id);
    this._broadcastRematch(session);
  }

  async _handleRematchReady(connectionId, payload) {
    const session = this._rematches.get(payload.rematchId);
    if (!session) return;
    const conn = this._conn(connectionId);
    session.setReady(conn.playerId, payload.ready === true);
    this._broadcastRematch(session);
    if (session.allReady()) {
      const players = [...session.members.values()].map((m) => ({
        playerId: m.playerId,
        connectionId: m.connectionId,
        displayName: m.name,
      }));
      for (const m of session.members.values()) {
        this._rematchByConnection.delete(m.connectionId);
        m.ready = false;
      }
      await this._createRoom({
        stake: session.stake,
        mode: session.mode,
        players,
        roomCode: session.roomCode,
        rematch: session,
      });
    }
  }

  _handleRematchLeave(connectionId, payload) {
    const session = this._rematches.get(payload.rematchId);
    if (!session) return;
    const conn = this._conn(connectionId);
    session.leave(conn.playerId);
    this._rematchByConnection.delete(connectionId);
    this._broadcastRematch(session);
  }

  _broadcastRematch(session) {
    const wire = encodeEnvelope(ProtocolEvents.rematchState, session.toWireState());
    for (const m of session.members.values()) {
      this.sendTo(m.connectionId, wire);
    }
  }

  _onDisconnect(connectionId) {
    this._queue.cancel(connectionId);
    this._leaveLobby(connectionId);
    const rematchId = this._rematchByConnection.get(connectionId);
    if (rematchId) {
      const session = this._rematches.get(rematchId);
      const conn = this._conn(connectionId);
      if (session && conn) {
        session.leave(conn.playerId);
        this._broadcastRematch(session);
      }
      this._rematchByConnection.delete(connectionId);
    }
    this._roomByConnection.delete(connectionId);
    const conn = this._connections.get(connectionId);
    if (conn) {
      const set = this._connectionsByPlayer.get(conn.playerId);
      set?.delete(connectionId);
      if (set && set.size === 0) this._connectionsByPlayer.delete(conn.playerId);
    }
    this._connections.delete(connectionId);
  }
}
