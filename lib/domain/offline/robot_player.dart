import 'dart:async';
import 'dart:math';

import 'package:cardgame/domain/offline/card_utils.dart';
import 'package:cardgame/domain/offline/game_room.dart';
import 'package:cardgame/domain/offline/game_rule_error.dart';
import 'package:cardgame/domain/offline/room_player.dart';

/// Heuristic bot that plays legal moves against [OfflineGameRoom].
class RobotPlayer {
  RobotPlayer({
    required this.room,
    required this.clientId,
    this.thinkMinMs = 600,
    this.thinkMaxMs = 1200,
    this.launchDelayMs = 400,

    /// Pause after draw so UI can animate before throw/swap.
    this.actionDelayMs = 900,
    Random? random,
    void Function(Duration delay, void Function() callback)? schedule,
  }) : _random = random ?? Random(),
       _schedule =
           schedule ??
           ((delay, callback) {
             Timer(delay, callback);
           });

  final OfflineGameRoom room;
  final String clientId;
  final int thinkMinMs;
  final int thinkMaxMs;
  final int launchDelayMs;
  final int actionDelayMs;
  final Random _random;
  final void Function(Duration delay, void Function() callback) _schedule;

  /// Known own card tags by layout index.
  final Map<int, String?> _memory = {};
  bool _disposed = false;
  bool _turnScheduled = false;

  void dispose() {
    _disposed = true;
  }

  void onRoomChanged() {
    if (_disposed) return;
    final player = _self;
    if (player == null) return;

    if (room.status == 'playing' && player.launch == 'notLaunched') {
      _schedule(Duration(milliseconds: launchDelayMs), () {
        if (_disposed) return;
        try {
          room.launch(clientId);
        } on GameRuleError {
          // Already launched.
        }
      });
      return;
    }

    if (room.status != 'playing') return;
    if (!_bothLaunched) return;
    if (!_isMyTurn) return;
    if (_abilityLocked) return;
    // Draw already done; actionDelay callback will finish the turn.
    if (_self?.handCard != null) return;
    if (_turnScheduled) return;

    _turnScheduled = true;
    _schedule(_thinkDelay(), () {
      _turnScheduled = false;
      if (_disposed) return;
      _takeTurn();
    });
  }

  void rematchReady() {
    if (_disposed) return;
    try {
      room.rematch(clientId);
    } on GameRuleError {
      // Ignore.
    }
  }

  Duration _thinkDelay() {
    final span = thinkMaxMs - thinkMinMs;
    final ms = thinkMinMs + (span <= 0 ? 0 : _random.nextInt(span + 1));
    return Duration(milliseconds: ms);
  }

  void _takeTurn() {
    final player = _self;
    if (player == null) return;
    if (room.status != 'playing' || !_isMyTurn || !_bothLaunched) return;
    if (_abilityLocked) return;

    _syncMemoryFromLaunch(player);

    try {
      if (player.handCard == null) {
        final matchIndex = _findDiscardMatch(player);
        if (matchIndex != null) {
          room.tapCard(clientId, matchIndex);
          _forgetIndex(matchIndex);
          return;
        }
        room.draw(clientId);
        // Yield so draw snapshot reaches Flame before throw/swap.
        _schedule(Duration(milliseconds: actionDelayMs), () {
          if (_disposed) return;
          final afterDraw = _self;
          if (afterDraw?.handCard == null) return;
          if (!_isMyTurn || _abilityLocked) return;
          try {
            _playWithHand(afterDraw!);
          } on GameRuleError {
            _fallback();
          }
        });
        return;
      }

      _playWithHand(player);
    } on GameRuleError {
      _fallback();
    }
  }

  void _playWithHand(RoomPlayer player) {
    final hand = player.handCard!;
    final handVal = cardValue(hand);

    for (var i = 0; i < player.cards.length; i += 1) {
      if (cardValue(player.cards[i]) == handVal) {
        room.tapCard(clientId, i);
        _forgetIndex(i);
        return;
      }
    }

    if (player.jackPeekAvailable && handVal == 11) {
      final peekIndex = _bestPeekIndex(player);
      if (peekIndex != null) {
        room.jackPeek(clientId, side: 'you', cardIndex: peekIndex);
        _memory[peekIndex] = player.cards[peekIndex];
        return;
      }
    }

    if (player.queenAbilityAvailable && handVal == 12) {
      final ownWorst = _worstKnownIndex(player);
      final opponent = _opponent;
      if (ownWorst != null &&
          opponent != null &&
          opponent.cards.isNotEmpty &&
          gameValue(player.cards[ownWorst]) >= 8) {
        final incoming = opponent.cards[0];
        room.queenReplace(clientId, youIndex: ownWorst, opponentIndex: 0);
        _memory[ownWorst] = incoming;
        return;
      }
      if (player.cards.length >= 2) {
        room.queenShuffle(clientId, side: 'opponent');
        return;
      }
    }

    final drawnScore = gameValue(hand);
    if (drawnScore <= 3) {
      room.throwHand(clientId);
      return;
    }

    final swapIndex = _bestSwapTarget(player, drawnScore);
    if (swapIndex != null) {
      room.tapCard(clientId, swapIndex);
      _memory[swapIndex] = hand;
      return;
    }

    room.throwHand(clientId);
  }

  void _fallback() {
    final player = _self;
    if (player == null) return;
    try {
      if (player.handCard != null) {
        room.throwHand(clientId);
      } else {
        room.draw(clientId);
        if (_self?.handCard != null) {
          room.throwHand(clientId);
        }
      }
    } on GameRuleError {
      // Give up this tick.
    }
  }

  int? _findDiscardMatch(RoomPlayer player) {
    if (room.discard.isEmpty) return null;
    final top = cardValue(room.discard.last);
    for (var i = 0; i < player.cards.length; i += 1) {
      if (cardValue(player.cards[i]) == top) return i;
    }
    return null;
  }

  int? _bestPeekIndex(RoomPlayer player) {
    for (var i = player.cards.length - 1; i >= 0; i -= 1) {
      if (!_memory.containsKey(i)) return i;
    }
    return player.cards.isEmpty ? null : 0;
  }

  int? _worstKnownIndex(RoomPlayer player) {
    int? bestIndex;
    var bestScore = -999;
    for (var i = 0; i < player.cards.length; i += 1) {
      final known = _memory[i] ?? (i < 2 ? player.cards[i] : null);
      if (known == null) continue;
      final score = gameValue(known);
      if (score > bestScore) {
        bestScore = score;
        bestIndex = i;
      }
    }
    return bestIndex ?? (player.cards.isEmpty ? null : player.cards.length - 1);
  }

  int? _bestSwapTarget(RoomPlayer player, int drawnScore) {
    int? bestIndex;
    var bestOutgoing = -999;
    for (var i = 0; i < player.cards.length; i += 1) {
      final known = _memory[i] ?? player.cards[i];
      final outgoing = gameValue(known);
      if (outgoing > drawnScore && outgoing > bestOutgoing) {
        bestOutgoing = outgoing;
        bestIndex = i;
      }
    }
    return bestIndex;
  }

  void _syncMemoryFromLaunch(RoomPlayer player) {
    if (player.cards.length >= 2) {
      _memory.putIfAbsent(0, () => player.cards[0]);
      _memory.putIfAbsent(1, () => player.cards[1]);
    }
  }

  void _forgetIndex(int removedIndex) {
    final next = <int, String?>{};
    for (final entry in _memory.entries) {
      if (entry.key < removedIndex) {
        next[entry.key] = entry.value;
      } else if (entry.key > removedIndex) {
        next[entry.key - 1] = entry.value;
      }
    }
    _memory
      ..clear()
      ..addAll(next);
  }

  RoomPlayer? get _self {
    for (final player in room.players) {
      if (player.id == clientId) return player;
    }
    return null;
  }

  RoomPlayer? get _opponent {
    for (final player in room.players) {
      if (player.id != clientId) return player;
    }
    return null;
  }

  bool get _bothLaunched =>
      room.players.every((player) => player.launch == 'ended');

  bool get _isMyTurn {
    final index = room.players.indexWhere((p) => p.id == clientId);
    return room.turnIndex != null && index == room.turnIndex;
  }

  bool get _abilityLocked {
    final player = _self;
    if (player == null || player.handCard == null) return false;
    final last = room.snapshotFor(clientId)['lastAction'] as Map?;
    if (last == null) return false;
    final type = last['type'];
    if (type == 'jackPeek' ||
        type == 'queenShuffle' ||
        type == 'queenReplace') {
      return !player.jackPeekAvailable && !player.queenAbilityAvailable;
    }
    return false;
  }
}
