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
  }) {
    return MatchViewState(
      phase: phase ?? this.phase,
      roomCode: clearRoom ? null : roomCode ?? this.roomCode,
      room: clearRoom ? null : room ?? this.room,
      found: found ?? this.found,
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
    final session = _ref.read(sessionProvider);
    if (matchId == null || session.playerId == null) return;
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

  void backToLobby() {
    state = state.copyWith(
      phase: AppPhase.lobby,
      clearRoom: true,
      clearSnapshot: true,
      queuing: false,
    );
  }

  void _onEnvelope(WireEnvelope envelope) {
    switch (envelope.event) {
      case ProtocolEvents.matchFound:
        final found = MatchFoundMessage.fromJson(envelope.payload);
        state = state.copyWith(
          found: found,
          phase: AppPhase.inGame,
          queuing: false,
        );
      case ProtocolEvents.matchSnapshot:
        final snap = MatchSnapshotMessage.fromJson(envelope.payload);
        final phase = snap.phase == WireMatchPhase.result
            ? AppPhase.result
            : AppPhase.inGame;
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
