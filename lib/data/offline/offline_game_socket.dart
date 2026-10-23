import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cardgame/data/game_socket.dart';
import 'package:cardgame/domain/offline/game_room.dart';
import 'package:cardgame/domain/offline/game_rule_error.dart';
import 'package:cardgame/domain/offline/robot_player.dart';
import 'package:cardgame/trailer/trailer_mode.dart';

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
        case 'chatSend':
          _handleChat(command);
          return;
        case 'startGame':
        case 'identity':
        case 'ping':
        case 'voiceSignal':
        case 'voiceState':
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

  void _handleChat(Map<String, dynamic> command) {
    final kind = command['kind'];
    final payload = <String, dynamic>{'kind': kind};
    switch (kind) {
      case 'text':
        final text = (command['text'] as String? ?? '').trim();
        if (text.isEmpty) return;
        payload['text'] = text;
      case 'phrase':
        payload['phraseId'] = command['phraseId'];
      case 'emoji':
        payload['emojiId'] = command['emojiId'];
      default:
        return;
    }
    _emitChat(humanPlayerId ?? kOfflineHumanId, payload);

    // The robot always answers, like the online bots (server/bots/bot_brain.js).
    if (_replyTimer != null) return;
    _replyTimer = Timer(
      Duration(milliseconds: 1200 + _random.nextInt(2400)),
      () {
        _replyTimer = null;
        _emitChat(kOfflineRobotId, _robotReply(payload));
      },
    );
  }

  Timer? _replyTimer;

  Map<String, dynamic> _robotReply(Map<String, dynamic> message) {
    final key = switch (message['kind']) {
      'phrase' => message['phraseId'] as String?,
      'emoji' => 'emoji:${message['emojiId']}',
      _ => null,
    };
    final options =
        _robotReplies[key] ?? const ['emoji:laugh', 'hehe', 'emoji:cool'];
    final pick = options[_random.nextInt(options.length)];
    return pick.startsWith('emoji:')
        ? {'kind': 'emoji', 'emojiId': pick.substring(6)}
        : {'kind': 'phrase', 'phraseId': pick};
  }

  /// Message (phrase id or `emoji:<id>`) -> fitting answers.
  static const _robotReplies = <String, List<String>>{
    'hello': ['hello', 'goodLuck', 'emoji:fist'],
    'goodLuck': ['goodLuck', 'thanks'],
    'wellPlayed': ['thanks', 'emoji:love', 'hehe'],
    'niceSwap': ['thanks', 'emoji:cool', 'hehe'],
    'sharpMemory': ['thanks', 'knowMyCards', 'emoji:cool'],
    'playFast': ['oops', 'hehe'],
    'stopPeeking': ['hehe', 'emoji:laugh'],
    'giveCardBack': ['hehe', 'emoji:laugh', 'oops'],
    'blackKingPlease': ['hehe', 'goodLuck', 'foundJoker'],
    'foundJoker': ['hehe', 'emoji:laugh', 'blackKingPlease', 'lowTotal'],
    'knowMyCards': ['hehe', 'emoji:cool', 'foundJoker'],
    'lowTotal': ['hehe', 'emoji:laugh', 'foundJoker'],
    'endingNextTurn': ['emoji:shock', 'hehe', 'knowMyCards'],
    'unlucky': ['thanks', 'emoji:cry', 'oops'],
    'oops': ['hehe', 'emoji:laugh', 'unlucky'],
    'thanks': ['emoji:love', 'emoji:clap'],
    'hehe': ['hehe', 'emoji:laugh'],
    'gg': ['gg', 'wellPlayed', 'emoji:clap'],
    'emoji:laugh': ['hehe', 'emoji:laugh'],
    'emoji:love': ['thanks', 'emoji:love'],
    'emoji:cry': ['unlucky', 'emoji:cry'],
    'emoji:angry': ['emoji:cool', 'hehe', 'oops'],
    'emoji:cool': ['emoji:cool', 'hehe', 'foundJoker'],
    'emoji:shock': ['hehe', 'emoji:laugh'],
    'emoji:fist': ['emoji:fist', 'emoji:cool'],
    'emoji:clap': ['thanks', 'emoji:clap'],
  };

  void _emitChat(String fromPlayerId, Map<String, dynamic> payload) {
    _emit({
      'type': 'chatMessage',
      'id': '${DateTime.now().microsecondsSinceEpoch}-$fromPlayerId',
      'fromPlayerId': fromPlayerId,
      ...payload,
      'at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  final _random = Random();

  @override
  void close() {
    if (_closed) return;
    _closed = true;
    _replyTimer?.cancel();
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
    final snapshot = _room.snapshotFor(kOfflineHumanId);
    if (TrailerMode.enabled && TrailerMode.stakePool > 0) {
      snapshot['stakePool'] = TrailerMode.stakePool;
      snapshot['stakePerPlayer'] = TrailerMode.stakePool ~/ 2;
      snapshot['potAmount'] = TrailerMode.stakePool;
    }
    _emit(snapshot);
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
