import 'dart:async';
import 'dart:convert';

import 'package:cardgame/data/game_socket.dart';
import 'package:cardgame/domain/offline/game_room.dart';
import 'package:cardgame/domain/offline/game_rule_error.dart';
import 'package:cardgame/domain/offline/robot_player.dart';

const kOfflineHumanId = 'local';
const kOfflineRobotId = 'robot';

/// Local [GameSocket] that runs [OfflineGameRoom] + [RobotPlayer] in-process.
class OfflineGameSocket implements GameSocket {
  OfflineGameSocket({
    required this.humanDisplayName,
    this.humanPlayerId,
    this.humanDeckId = 'default',
    this.robotDisplayName = 'Robot',
    OfflineGameRoom Function(void Function(OfflineGameRoom) onChange)?
    roomFactory,
    RobotPlayer Function(OfflineGameRoom room)? robotFactory,
  }) {
    _controller = StreamController<String>();
    _room = (roomFactory ?? _defaultRoom)(_handleRoomChanged);
    _robot = (robotFactory ?? _defaultRobot)(_room);
    _room.matchType = 'offline';
    _room.addPlayer(
      kOfflineHumanId,
      playerId: humanPlayerId,
      displayName: humanDisplayName,
      deckId: humanDeckId,
    );
    _room.addPlayer(
      kOfflineRobotId,
      playerId: 'robot',
      displayName: robotDisplayName,
    );
    _room.start(kOfflineHumanId);
    // Defer so [GameSessionController] can attach its listener first.
    scheduleMicrotask(() {
      if (_closed) return;
      _emitConnected();
      _ready = true;
      _pushSnapshot();
      _robot.onRoomChanged();
    });
  }

  final String humanDisplayName;
  final String? humanPlayerId;
  final String humanDeckId;
  final String robotDisplayName;

  late final StreamController<String> _controller;
  late final OfflineGameRoom _room;
  late final RobotPlayer _robot;
  bool _closed = false;
  bool _ready = false;

  OfflineGameRoom get room => _room;

  @override
  Stream<String> get stream => _controller.stream;

  @override
  void send(String message) {
    if (_closed) return;
    final command = jsonDecode(message) as Map<String, dynamic>;
    final type = command['type'] as String?;
    if (type == null) return;

    try {
      switch (type) {
        case 'leaveRoom':
          _emit({'type': 'leftRoom'});
          close();
          return;
        case 'launch':
          _room.launch(kOfflineHumanId);
          break;
        case 'draw':
          _room.draw(kOfflineHumanId);
          break;
        case 'tapCard':
          _room.tapCard(kOfflineHumanId, (command['cardIndex'] as num).toInt());
          break;
        case 'throwHand':
          _room.throwHand(kOfflineHumanId);
          break;
        case 'jackPeek':
          _room.jackPeek(
            kOfflineHumanId,
            side: command['side'] as String,
            cardIndex: (command['cardIndex'] as num).toInt(),
          );
          break;
        case 'queenShuffle':
          _room.queenShuffle(kOfflineHumanId, side: command['side'] as String);
          break;
        case 'queenReplace':
          _room.queenReplace(
            kOfflineHumanId,
            youIndex: (command['youIndex'] as num).toInt(),
            opponentIndex: (command['opponentIndex'] as num).toInt(),
          );
          break;
        case 'endGame':
          _room.end(kOfflineHumanId);
          break;
        case 'rematch':
          _room.rematch(kOfflineHumanId);
          _robot.rematchReady();
          break;
        case 'startGame':
          break;
        default:
          _emit({
            'type': 'error',
            'code': 'unknown_command',
            'message': 'Unknown command',
          });
      }
    } on GameRuleError catch (error) {
      _emit({'type': 'error', 'code': error.code, 'message': error.message});
    }
  }

  @override
  void close() {
    if (_closed) return;
    _closed = true;
    _robot.dispose();
    _room.dispose();
    unawaited(_controller.close());
  }

  void _handleRoomChanged(OfflineGameRoom room) {
    if (_closed || !_ready) return;
    _pushSnapshot();
    _robot.onRoomChanged();
  }

  void _pushSnapshot() {
    _emit(_room.snapshotFor(kOfflineHumanId));
  }

  void _emitConnected() {
    _emit({'type': 'connected', 'clientId': kOfflineHumanId});
  }

  void _emit(Map<String, dynamic> payload) {
    if (_closed || _controller.isClosed) return;
    _controller.add(jsonEncode(payload));
  }

  static OfflineGameRoom _defaultRoom(void Function(OfflineGameRoom) onChange) {
    return OfflineGameRoom('OFFLINE', onChange: onChange);
  }

  static RobotPlayer _defaultRobot(OfflineGameRoom room) {
    return RobotPlayer(room: room, clientId: kOfflineRobotId);
  }
}
