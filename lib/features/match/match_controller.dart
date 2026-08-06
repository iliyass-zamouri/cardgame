import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_protocol/game_protocol.dart';

import '../../core/config/dependency_injection.dart';
import '../../core/network/socket_client.dart';

enum AppPhase {
  boot,
  auth,
  lobby,
  matchmaking,
  waitingForOpponent,
  room,
  inGame,
  result,
}

class MatchViewState {
  const MatchViewState({
    this.phase = AppPhase.boot,
    this.roomCode,
    this.room,
    this.found,
    this.snapshot,
    this.rematch,
    this.queuing = false,
    this.error,
    this.stake = 100,
    this.connected = false,
  });

  final AppPhase phase;
  final String? roomCode;
  final RoomStateMessage? room;
  final MatchFoundMessage? found;
  final MatchSnapshotMessage? snapshot;
  final RematchStateMessage? rematch;
  final bool queuing;
  final String? error;
  final int stake;
  final bool connected;

  String? get localPlayerId =>
      snapshot?.localPlayerId ?? found?.localPlayerId;

  /// True while opponent hasn't joined / match snapshot isn't ready yet.
  bool get shouldShowMatchWaiting {
    if (phase == AppPhase.inGame) {
      final snap = snapshot;
      if (snap == null) return true;
      if (snap.phase == WireMatchPhase.lobby) return true;
      if (snap.players.length < 2) return true;
      return false;
    }
    if (phase == AppPhase.result && rematch != null && !rematch!.closed) {
      final r = rematch!;
      final id = localPlayerId;
      if (id == null) return false;
      final joined = r.members.any((m) => m.playerId == id);
      if (!joined) return false;
      if (r.members.length < r.expectedPlayers) return true;
      if (!r.members.every((m) => m.ready)) return true;
    }
    return false;
  }

  MatchViewState copyWith({
    AppPhase? phase,
    String? roomCode,
    RoomStateMessage? room,
    MatchFoundMessage? found,
    MatchSnapshotMessage? snapshot,
    RematchStateMessage? rematch,
    bool? queuing,
    String? error,
    int? stake,
    bool? connected,
    bool clearError = false,
    bool clearRoom = false,
    bool clearSnapshot = false,
    bool clearFound = false,
  }) {
    return MatchViewState(
      phase: phase ?? this.phase,
      roomCode: clearRoom ? null : roomCode ?? this.roomCode,
      room: clearRoom ? null : room ?? this.room,
      found: clearFound ? null : found ?? this.found,
      snapshot: clearSnapshot ? null : snapshot ?? this.snapshot,
      rematch: rematch ?? this.rematch,
      queuing: queuing ?? this.queuing,
      error: clearError ? null : error ?? this.error,
      stake: stake ?? this.stake,
      connected: connected ?? this.connected,
    );
  }
}

class MatchController extends StateNotifier<MatchViewState> {
  MatchController(this._socket, this._ref) : super(const MatchViewState()) {
    _sub = _socket.messages.listen(_onEnvelope);
    _connSub = _socket.connectionState.listen((up) {
      state = state.copyWith(connected: up);
      if (up) _rejoinIfNeeded();
    });
  }

  final SocketClient _socket;
  final Ref _ref;
  StreamSubscription<WireEnvelope>? _sub;
  StreamSubscription<bool>? _connSub;
  String? _joinedMatchId;

  Future<void> connect() async {
    final session = _ref.read(sessionProvider);
    await _socket.connect(
      token: session.token,
      activeMatchId: state.found?.matchId,
      playerId: session.playerId,
    );
    state = state.copyWith(
      phase: AppPhase.lobby,
      clearError: true,
      connected: _socket.isConnected,
    );
  }

  void _rejoinIfNeeded() {
    final matchId = state.found?.matchId ?? state.snapshot?.matchId;
    if (matchId == null) return;
    _joinedMatchId = null;
    _joinMatch(matchId);
  }

  void _joinMatch(String matchId) {
    if (_joinedMatchId == matchId) return;
    _joinedMatchId = matchId;
    final session = _ref.read(sessionProvider);
    _socket.send(
      ProtocolEvents.matchJoin,
      MatchJoinMessage(matchId: matchId, playerId: session.playerId).toJson(),
    );
  }

  void setStake(int stake) {
    state = state.copyWith(stake: stake);
  }

  void queue() {
    final session = _ref.read(sessionProvider);
    _joinedMatchId = null;
    _socket.send(
      ProtocolEvents.matchQueue,
      MatchQueueMessage(
        playerId: session.playerId,
        displayName: session.displayName,
        stake: state.stake,
      ).toJson(),
    );
    state = state.copyWith(phase: AppPhase.matchmaking, queuing: true);
  }

  void cancelQueue() {
    _socket.send(ProtocolEvents.matchCancel, {});
    state = state.copyWith(phase: AppPhase.lobby, queuing: false);
  }

  void createRoom() {
    final session = _ref.read(sessionProvider);
    _socket.send(
      ProtocolEvents.roomCreate,
      RoomCreateMessage(
        playerId: session.playerId!,
        displayName: session.displayName,
        stake: state.stake,
      ).toJson(),
    );
    state = state.copyWith(phase: AppPhase.room);
  }

  void joinRoom(String code) {
    final session = _ref.read(sessionProvider);
    _socket.send(
      ProtocolEvents.roomJoin,
      RoomJoinMessage(
        playerId: session.playerId!,
        code: code,
        displayName: session.displayName,
      ).toJson(),
    );
    state = state.copyWith(phase: AppPhase.room, roomCode: code);
  }

  void startRoom() {
    _socket.send(ProtocolEvents.roomStart, {});
  }

  void leaveRoom() {
    _socket.send(ProtocolEvents.roomLeave, {});
    state = state.copyWith(phase: AppPhase.lobby, clearRoom: true);
  }

  void sendCardAction(CardActionMessage action) {
    _socket.send(ProtocolEvents.cardAction, action.toJson());
  }

  void rematchJoin() {
    final rematchId = state.rematch?.rematchId ?? state.found?.rematchId;
    if (rematchId == null) return;
    final session = _ref.read(sessionProvider);
    _socket.send(
      ProtocolEvents.rematchJoin,
      RematchJoinMessage(
        rematchId: rematchId,
        matchId: state.found?.matchId,
        playerId: session.playerId,
        displayName: session.displayName,
      ).toJson(),
    );
  }

  void rematchReady(bool ready) {
    final rematchId = state.rematch?.rematchId;
    if (rematchId == null) return;
    _socket.send(
      ProtocolEvents.rematchReady,
      RematchReadyMessage(rematchId: rematchId, ready: ready).toJson(),
    );
  }

  void leaveMatch() {
    _socket.send(ProtocolEvents.matchLeave, {});
    _joinedMatchId = null;
    state = state.copyWith(
      phase: AppPhase.lobby,
      clearRoom: true,
      clearSnapshot: true,
      clearFound: true,
      queuing: false,
    );
  }

  void backToLobby() {
    // Always notify server — otherwise seat stays mapped and blocks re-queue.
    if (state.found != null || state.snapshot != null) {
      _socket.send(ProtocolEvents.matchLeave, {});
    }
    _joinedMatchId = null;
    state = state.copyWith(
      phase: AppPhase.lobby,
      clearRoom: true,
      clearSnapshot: true,
      clearFound: true,
      queuing: false,
    );
  }

  void _onEnvelope(WireEnvelope envelope) {
    switch (envelope.event) {
      case ProtocolEvents.matchFound:
        final found = MatchFoundMessage.fromJson(envelope.payload);
        // Duplicate found (server rebind ack) — join once, don't flip phase.
        if (state.found?.matchId == found.matchId) {
          _joinMatch(found.matchId);
          break;
        }
        _joinedMatchId = null;
        _joinMatch(found.matchId);
        state = state.copyWith(
          found: found,
          phase: AppPhase.waitingForOpponent,
          queuing: false,
          clearSnapshot: true,
        );
      case ProtocolEvents.matchSnapshot:
        final snap = MatchSnapshotMessage.fromJson(envelope.payload);
        final activeId = state.found?.matchId ?? state.snapshot?.matchId;
        // Stale room still broadcasting after rematch / double-queue.
        if (activeId != null && snap.matchId != activeId) break;
        final phase = switch (snap.phase) {
          WireMatchPhase.result => AppPhase.result,
          WireMatchPhase.lobby => AppPhase.waitingForOpponent,
          _ => AppPhase.inGame,
        };
        state = state.copyWith(snapshot: snap, phase: phase, clearError: true);
      case ProtocolEvents.roomState:
        final room = RoomStateMessage.fromJson(envelope.payload);
        if (room.closed && room.reason == 'kicked') {
          state = state.copyWith(
            phase: AppPhase.lobby,
            clearRoom: true,
            error: 'Kicked from room',
          );
        } else {
          state = state.copyWith(
            room: room,
            roomCode: room.code,
            phase: AppPhase.room,
          );
        }
      case ProtocolEvents.rematchState:
        state = state.copyWith(
          rematch: RematchStateMessage.fromJson(envelope.payload),
        );
      case ProtocolEvents.matchError:
        final err = MatchErrorMessage.fromJson(envelope.payload);
        if (err.code == 'match_closed') {
          // Self-leave / re-queue already cleared local state — skip toast noise.
          if (state.phase == AppPhase.lobby ||
              state.phase == AppPhase.matchmaking) {
            break;
          }
          _joinedMatchId = null;
          state = state.copyWith(
            phase: AppPhase.lobby,
            clearRoom: true,
            clearSnapshot: true,
            clearFound: true,
            error: err.message,
            queuing: false,
          );
          break;
        }
        state = state.copyWith(error: err.message, queuing: false);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _connSub?.cancel();
    super.dispose();
  }
}

final matchControllerProvider =
    StateNotifierProvider<MatchController, MatchViewState>((ref) {
  final socket = ref.watch(socketClientProvider);
  return MatchController(socket, ref);
});
