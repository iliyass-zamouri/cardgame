import 'dart:async';
import 'dart:math';

import 'package:cardgame/domain/offline/card_utils.dart';
import 'package:cardgame/domain/offline/game_rule_error.dart';
import 'package:cardgame/domain/offline/room_player.dart';

typedef RoomRandom = double Function();
typedef RoomOnChange = void Function(OfflineGameRoom room);
typedef RoomScheduler =
    Timer Function(Duration duration, void Function() callback);

class _ActivePeek {
  final String viewerId;
  final String side;
  final int cardIndex;
  final String tag;
  Timer? timer;

  _ActivePeek({
    required this.viewerId,
    required this.side,
    required this.cardIndex,
    required this.tag,
  });
}

class _ActiveQueenAbility {
  final String viewerId;
  Timer? timer;

  _ActiveQueenAbility({required this.viewerId});
}

class _LastAction {
  final String playerId;
  final String type;
  final int? cardIndex;
  final String? cardTag;
  final String? drawnTag;
  final String? side;
  final int? youIndex;
  final int? opponentIndex;

  const _LastAction({
    required this.playerId,
    required this.type,
    this.cardIndex,
    this.cardTag,
    this.drawnTag,
    this.side,
    this.youIndex,
    this.opponentIndex,
  });
}

/// Dart port of `server/game_room.js` for offline vs-robot play.
class OfflineGameRoom {
  OfflineGameRoom(
    this.id, {
    RoomRandom? random,
    this.onChange,
    this.peekDurationMs = 3500,
    this.queenShuffleDurationMs = 1200,
    this.queenReplaceDurationMs = 1400,
    this.launchDurationMs = 5000,
    RoomScheduler? scheduler,
  }) : random = random ?? Random().nextDouble,
       scheduler =
           scheduler ?? ((duration, callback) => Timer(duration, callback));

  final String id;
  final RoomRandom random;
  final RoomOnChange? onChange;
  final int peekDurationMs;
  final int queenShuffleDurationMs;
  final int queenReplaceDurationMs;
  final int launchDurationMs;
  final RoomScheduler scheduler;

  int version = 0;
  String status = 'waiting';
  String matchType = 'private';
  List<int> seriesWins = [0, 0];
  List<bool> lobbyReady = [false, false];
  List<bool> rematchReady = [false, false];
  final List<RoomPlayer> players = [];
  List<String> deck = [];
  List<String> discard = [];
  int? turnIndex;
  Map<String, dynamic>? result;
  _LastAction? _lastAction;
  String? discardSource;

  final Map<String, Timer> _launchTimers = {};
  _ActivePeek? _activePeek;
  _ActiveQueenAbility? _activeQueenAbility;

  RoomPlayer addPlayer(
    String clientId, {
    String? playerId,
    String? displayName,
  }) {
    final existing = _player(clientId);
    if (existing != null) {
      existing.connected = true;
      if (playerId != null) existing.playerId = playerId;
      if (displayName != null) existing.displayName = displayName;
      _changed();
      return existing;
    }
    if (players.length >= 2) {
      throw GameRuleError('room_full', 'Room already has two players');
    }
    final player = RoomPlayer(
      id: clientId,
      playerId: playerId,
      displayName: displayName ?? 'Player',
    );
    players.add(player);
    _changed();
    return player;
  }

  void removePlayer(String clientId) {
    final index = players.indexWhere((player) => player.id == clientId);
    if (index < 0) return;
    _launchTimers.remove(clientId)?.cancel();
    _clearActivePeek();
    _clearActiveQueenAbility();
    players.removeAt(index);
    status = 'waiting';
    matchType = 'private';
    seriesWins = [0, 0];
    lobbyReady = [false, false];
    rematchReady = [false, false];
    deck = [];
    discard = [];
    turnIndex = null;
    result = null;
    _lastAction = null;
    discardSource = null;
    for (final player in players) {
      player.cards = [];
      player.handCard = null;
      player.launch = 'notLaunched';
      player.total = 0;
      player.jackPeekAvailable = false;
      player.queenAbilityAvailable = false;
    }
    _changed();
  }

  void ready(String clientId) {
    _requirePlayer(clientId);
    if (players.length != 2) {
      throw GameRuleError('waiting_for_player', 'Two players required');
    }
    if (status != 'waiting') {
      throw GameRuleError('already_started', 'Game already started');
    }
    final index = players.indexWhere((player) => player.id == clientId);
    lobbyReady[index] = true;
    if (lobbyReady[0] && lobbyReady[1]) {
      start(clientId);
      return;
    }
    _changed();
  }

  void start(String clientId) {
    _requirePlayer(clientId);
    if (players.length != 2) {
      throw GameRuleError('waiting_for_player', 'Two players required');
    }
    if (status == 'playing') {
      throw GameRuleError('already_started', 'Game already started');
    }

    _clearTimers();
    deck = shuffle(createDeck(), random);
    discard = [];
    result = null;
    _lastAction = null;
    discardSource = null;
    status = 'playing';
    lobbyReady = [false, false];
    rematchReady = [false, false];
    for (final player in players) {
      player.cards = [];
      player.handCard = null;
      player.launch = 'notLaunched';
      player.total = 0;
      player.jackPeekAvailable = false;
      player.queenAbilityAvailable = false;
    }
    for (var round = 0; round < 4; round += 1) {
      for (final player in players) {
        player.cards.add(deck.removeLast());
      }
    }
    turnIndex = (random() * 2).floor();
    _changed();
  }

  void rematch(String clientId) {
    _requirePlayer(clientId);
    if (players.length != 2) {
      throw GameRuleError('waiting_for_player', 'Two players required');
    }
    if (status != 'ended') {
      throw GameRuleError('not_ended', 'Game is not over');
    }
    final index = players.indexWhere((player) => player.id == clientId);
    rematchReady[index] = true;
    if (rematchReady[0] && rematchReady[1]) {
      start(clientId);
      return;
    }
    _changed();
  }

  void launch(String clientId) {
    _requirePlaying();
    final player = _requirePlayer(clientId);
    if (player.launch != 'notLaunched') {
      throw GameRuleError('already_launched', 'Cards already revealed');
    }
    player.launch = 'launched';
    _changed();

    final timer = scheduler(Duration(milliseconds: launchDurationMs), () {
      player.launch = 'ended';
      _launchTimers.remove(clientId);
      _changed();
    });
    _launchTimers[clientId] = timer;
  }

  void draw(String clientId) {
    _requireAction(clientId);
    final player = _requirePlayer(clientId);
    if (player.handCard != null) {
      throw GameRuleError('already_drew', 'Throw or swap drawn card first');
    }
    _restock();
    if (deck.isEmpty) {
      throw GameRuleError('deck_empty', 'No cards available');
    }
    player.handCard = deck.removeLast();
    final value = cardValue(player.handCard!);
    player.jackPeekAvailable = value == 11;
    player.queenAbilityAvailable = value == 12;
    _lastAction = _LastAction(playerId: clientId, type: 'draw');
    discardSource = null;
    _changed();
  }

  void jackPeek(
    String clientId, {
    required String side,
    required int cardIndex,
  }) {
    _requireAction(clientId);
    _requireNoAbilityLock(clientId);
    final player = _requirePlayer(clientId);
    if (player.handCard == null || cardValue(player.handCard!) != 11) {
      throw GameRuleError('no_jack', 'Jack peek requires a drawn Jack');
    }
    if (!player.jackPeekAvailable) {
      throw GameRuleError('peek_used', 'Jack peek already used');
    }
    if (side != 'you' && side != 'opponent') {
      throw GameRuleError('invalid_side', 'Peek side must be you or opponent');
    }
    final viewerIndex = players.indexWhere((entry) => entry.id == clientId);
    final targetPlayer = side == 'you' ? player : players[1 - viewerIndex];
    if (cardIndex < 0 || cardIndex >= targetPlayer.cards.length) {
      throw GameRuleError('invalid_card', 'Card index is invalid');
    }

    player.jackPeekAvailable = false;
    _clearActivePeek();
    final peek = _ActivePeek(
      viewerId: clientId,
      side: side,
      cardIndex: cardIndex,
      tag: targetPlayer.cards[cardIndex],
    );
    _activePeek = peek;
    peek.timer = scheduler(
      Duration(milliseconds: peekDurationMs),
      _resolveJackPeek,
    );
    _lastAction = _LastAction(
      playerId: clientId,
      type: 'jackPeek',
      cardIndex: cardIndex,
      side: side,
    );
    discardSource = null;
    _changed();
  }

  void queenShuffle(String clientId, {required String side}) {
    _requireAction(clientId);
    _requireNoAbilityLock(clientId);
    final player = _requireQueenAbility(clientId);
    if (side != 'you' && side != 'opponent') {
      throw GameRuleError(
        'invalid_side',
        'Shuffle side must be you or opponent',
      );
    }
    final viewerIndex = players.indexWhere((entry) => entry.id == clientId);
    final targetPlayer = side == 'you' ? player : players[1 - viewerIndex];
    if (targetPlayer.cards.length < 2) {
      throw GameRuleError('cannot_shuffle', 'Not enough cards to shuffle');
    }

    player.queenAbilityAvailable = false;
    player.jackPeekAvailable = false;
    targetPlayer.cards = shuffle(targetPlayer.cards, random);
    _lastAction = _LastAction(
      playerId: clientId,
      type: 'queenShuffle',
      side: side,
    );
    discardSource = null;
    _startQueenAbilityLock(clientId, queenShuffleDurationMs);
    _changed();
  }

  void queenReplace(
    String clientId, {
    required int youIndex,
    required int opponentIndex,
  }) {
    _requireAction(clientId);
    _requireNoAbilityLock(clientId);
    final player = _requireQueenAbility(clientId);
    final viewerIndex = players.indexWhere((entry) => entry.id == clientId);
    final opponent = players[1 - viewerIndex];
    if (youIndex < 0 || youIndex >= player.cards.length) {
      throw GameRuleError('invalid_card', 'Your card index is invalid');
    }
    if (opponentIndex < 0 || opponentIndex >= opponent.cards.length) {
      throw GameRuleError('invalid_card', 'Opponent card index is invalid');
    }

    player.queenAbilityAvailable = false;
    player.jackPeekAvailable = false;
    final ownTag = player.cards[youIndex];
    player.cards[youIndex] = opponent.cards[opponentIndex];
    opponent.cards[opponentIndex] = ownTag;
    _lastAction = _LastAction(
      playerId: clientId,
      type: 'queenReplace',
      cardIndex: youIndex,
      youIndex: youIndex,
      opponentIndex: opponentIndex,
    );
    discardSource = null;
    _startQueenAbilityLock(clientId, queenReplaceDurationMs);
    _changed();
  }

  void tapCard(String clientId, int cardIndex) {
    _requireAction(clientId);
    _requireNoAbilityLock(clientId);
    final player = _requirePlayer(clientId);
    if (cardIndex < 0 || cardIndex >= player.cards.length) {
      throw GameRuleError('invalid_card', 'Card index is invalid');
    }
    final selected = player.cards[cardIndex];

    if (player.handCard == null) {
      if (discard.isEmpty) {
        throw GameRuleError('draw_first', 'Draw a card first');
      }
      if (cardValue(selected) == cardValue(discard.last)) {
        player.cards.removeAt(cardIndex);
        discard.add(selected);
        discardSource = 'hand';
        _lastAction = _LastAction(
          playerId: clientId,
          type: 'discardMatch',
          cardIndex: cardIndex,
          cardTag: selected,
        );
      } else {
        _restock();
        if (deck.isNotEmpty) player.cards.add(deck.removeLast());
        discardSource = null;
        _lastAction = _LastAction(
          playerId: clientId,
          type: 'penaltyDraw',
          cardIndex: cardIndex,
        );
      }
      _finishIfNeeded();
      _changed();
      return;
    }

    if (cardValue(player.handCard!) == cardValue(selected)) {
      final drawnTag = player.handCard!;
      player.cards.removeAt(cardIndex);
      discard.addAll([selected, drawnTag]);
      discardSource = 'hand';
      _lastAction = _LastAction(
        playerId: clientId,
        type: 'doubleDiscard',
        cardIndex: cardIndex,
        cardTag: selected,
        drawnTag: drawnTag,
      );
    } else {
      final drawnTag = player.handCard!;
      player.cards[cardIndex] = drawnTag;
      discard.add(selected);
      discardSource = 'hand';
      _lastAction = _LastAction(
        playerId: clientId,
        type: 'swap',
        cardIndex: cardIndex,
        cardTag: selected,
      );
    }
    player.handCard = null;
    player.jackPeekAvailable = false;
    player.queenAbilityAvailable = false;
    _advanceTurn();
  }

  void throwHand(String clientId) {
    _requireAction(clientId);
    _requireNoAbilityLock(clientId);
    final player = _requirePlayer(clientId);
    if (player.handCard == null) {
      throw GameRuleError('no_hand_card', 'Draw a card first');
    }
    _throwDrawnCard(player);
  }

  void end(String clientId) {
    _requirePlayer(clientId);
    _lastAction = null;
    discardSource = null;
    _endGame();
    _changed();
  }

  Map<String, dynamic> snapshotFor(String clientId) {
    final viewerIndex = players.indexWhere((player) => player.id == clientId);
    final viewer = viewerIndex >= 0 ? players[viewerIndex] : null;
    final opponent = viewerIndex >= 0 ? players[1 - viewerIndex] : null;
    final showAll = status == 'ended';

    final last = _lastAction;
    Map<String, dynamic>? lastActionJson;
    if (last != null) {
      lastActionJson = {
        'actor': last.playerId == clientId ? 'you' : 'opponent',
        'type': last.type,
        'cardIndex': last.cardIndex,
        'cardTag': last.cardTag,
        'drawnTag': last.drawnTag,
        if (last.side != null) 'side': last.side,
        if (last.youIndex != null) 'youIndex': last.youIndex,
        if (last.opponentIndex != null) 'opponentIndex': last.opponentIndex,
      };
    }

    return {
      'type': 'snapshot',
      'roomId': id,
      'version': version,
      'status': status,
      'ready': players.length == 2,
      'matchType': matchType,
      'deckCount': deck.length,
      'discardTop': discard.isEmpty ? null : discard.last,
      'discardRecent':
          discard.length <= 2
              ? List<String>.from(discard)
              : discard.sublist(discard.length - 2),
      'turn':
          turnIndex == null
              ? null
              : (turnIndex == viewerIndex ? 'you' : 'opponent'),
      'you':
          viewer == null
              ? null
              : _playerView(viewer, true, showAll, clientId, viewerIndex),
      'opponent':
          opponent == null
              ? null
              : _playerView(
                opponent,
                false,
                showAll,
                clientId,
                1 - viewerIndex,
              ),
      'result': result,
      'discardSource': discardSource,
      'lastAction': lastActionJson,
    };
  }

  void dispose() => _clearTimers();

  Map<String, dynamic> _playerView(
    RoomPlayer player,
    bool isSelf,
    bool showAll,
    String? viewerId,
    int seatIndex,
  ) {
    final peek = _activePeek;
    final peekForViewer = peek != null && peek.viewerId == viewerId;
    return {
      'connected': player.connected,
      'displayName': player.displayName,
      'playerId': player.playerId,
      'seriesWins': seriesWins[seatIndex],
      'lobbyReady': lobbyReady[seatIndex],
      'rematchReady': rematchReady[seatIndex],
      'launch': player.launch,
      'total': player.total,
      'cards': [
        for (var index = 0; index < player.cards.length; index += 1)
          _cardView(
            player,
            index,
            isSelf: isSelf,
            showAll: showAll,
            peekForViewer: peekForViewer,
            peek: peek,
          ),
      ],
      'handCard': isSelf ? player.handCard : null,
      'hasHandCard': player.handCard != null,
      'jackPeekAvailable': isSelf ? player.jackPeekAvailable : false,
      'queenAbilityAvailable': isSelf ? player.queenAbilityAvailable : false,
    };
  }

  Map<String, dynamic> _cardView(
    RoomPlayer player,
    int index, {
    required bool isSelf,
    required bool showAll,
    required bool peekForViewer,
    required _ActivePeek? peek,
  }) {
    final initialReveal = isSelf && player.launch == 'launched' && index < 2;
    final jackPeekReveal =
        peekForViewer &&
        peek != null &&
        peek.cardIndex == index &&
        ((peek.side == 'you' && isSelf) ||
            (peek.side == 'opponent' && !isSelf));
    final visible = showAll || initialReveal || jackPeekReveal;
    return {
      'index': index,
      'tag': visible ? player.cards[index] : null,
      'visible': visible,
    };
  }

  void _advanceTurn() {
    if (_finishIfNeeded()) {
      _changed();
      return;
    }
    turnIndex = 1 - turnIndex!;
    _restock();
    _changed();
  }

  bool _finishIfNeeded() {
    if (players.any((player) => player.cards.isEmpty)) {
      _endGame();
      return true;
    }
    return false;
  }

  void _endGame() {
    status = 'ended';
    turnIndex = null;
    rematchReady = [false, false];
    for (final player in players) {
      player.total = player.cards.fold<int>(
        0,
        (sum, tag) => sum + gameValue(tag),
      );
    }
    final winnerIndex =
        players[0].total == players[1].total
            ? null
            : (players[0].total < players[1].total ? 0 : 1);
    result = {
      'scores': players.map((player) => player.total).toList(growable: false),
      'winnerIndex': winnerIndex,
    };
    if (winnerIndex == 0 || winnerIndex == 1) {
      seriesWins[winnerIndex!] += 1;
    }
    _clearTimers();
  }

  void _restock() {
    if (deck.isNotEmpty || discard.length <= 1) return;
    final top = discard.removeLast();
    deck = shuffle(discard, random);
    discard = [top];
  }

  void _requireAction(String clientId) {
    _requirePlaying();
    final index = players.indexWhere((player) => player.id == clientId);
    if (index < 0) throw GameRuleError('not_in_room', 'Join room first');
    if (index != turnIndex) {
      throw GameRuleError('not_your_turn', 'It is not your turn');
    }
    if (!players.every((player) => player.launch == 'ended')) {
      throw GameRuleError('reveal_first', 'Both players must reveal first');
    }
  }

  void _requirePlaying() {
    if (status != 'playing') {
      throw GameRuleError('not_playing', 'Game is not running');
    }
  }

  RoomPlayer _requirePlayer(String clientId) {
    final player = _player(clientId);
    if (player == null) throw GameRuleError('not_in_room', 'Join room first');
    return player;
  }

  RoomPlayer? _player(String clientId) {
    for (final player in players) {
      if (player.id == clientId) return player;
    }
    return null;
  }

  void _changed() {
    version += 1;
    onChange?.call(this);
  }

  void _requireNoAbilityLock(String clientId) {
    if (_activePeek?.viewerId == clientId) {
      throw GameRuleError('peek_in_progress', 'Wait for peek to finish');
    }
    if (_activeQueenAbility?.viewerId == clientId) {
      throw GameRuleError(
        'queen_in_progress',
        'Wait for Queen ability to finish',
      );
    }
  }

  RoomPlayer _requireQueenAbility(String clientId) {
    final player = _requirePlayer(clientId);
    if (player.handCard == null || cardValue(player.handCard!) != 12) {
      throw GameRuleError('no_queen', 'Queen ability requires a drawn Queen');
    }
    if (!player.queenAbilityAvailable) {
      throw GameRuleError('queen_used', 'Queen ability already used');
    }
    return player;
  }

  void _startQueenAbilityLock(String clientId, int durationMs) {
    _clearActiveQueenAbility();
    final ability = _ActiveQueenAbility(viewerId: clientId);
    _activeQueenAbility = ability;
    ability.timer = scheduler(
      Duration(milliseconds: durationMs),
      _resolveQueenAbility,
    );
  }

  void _throwDrawnCard(RoomPlayer player) {
    final cardTag = player.handCard!;
    _lastAction = _LastAction(
      playerId: player.id,
      type: 'throw',
      cardTag: cardTag,
    );
    discardSource = 'drawn';
    discard.add(cardTag);
    player.handCard = null;
    player.jackPeekAvailable = false;
    player.queenAbilityAvailable = false;
    _advanceTurn();
  }

  void _resolveJackPeek() {
    final peek = _activePeek;
    _clearActivePeek();
    if (peek == null) return;
    final player = _player(peek.viewerId);
    if (player?.handCard == null) {
      _changed();
      return;
    }
    _throwDrawnCard(player!);
  }

  void _resolveQueenAbility() {
    final ability = _activeQueenAbility;
    _clearActiveQueenAbility();
    if (ability == null) return;
    final player = _player(ability.viewerId);
    if (player?.handCard == null) {
      _changed();
      return;
    }
    _throwDrawnCard(player!);
  }

  void _clearActivePeek() {
    _activePeek?.timer?.cancel();
    _activePeek = null;
  }

  void _clearActiveQueenAbility() {
    _activeQueenAbility?.timer?.cancel();
    _activeQueenAbility = null;
  }

  void _clearTimers() {
    for (final timer in _launchTimers.values) {
      timer.cancel();
    }
    _launchTimers.clear();
    _clearActivePeek();
    _clearActiveQueenAbility();
  }
}
