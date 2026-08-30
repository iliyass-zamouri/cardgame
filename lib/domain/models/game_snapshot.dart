enum GameStatus { waiting, playing, ended }

enum LaunchStatus { notLaunched, launched, ended }

enum LastActionActor { you, opponent }

enum LastActionType {
  discardMatch,
  doubleDiscard,
  swap,
  penaltyDraw,
  draw,
  throwHand,
  jackPeek,
  queenShuffle,
  queenReplace,
}

enum QueenMode { none, shufflePick, replacePick }

class CardSnapshot {
  final int index;
  final String? tag;
  final bool visible;

  const CardSnapshot({
    required this.index,
    required this.tag,
    required this.visible,
  });

  factory CardSnapshot.fromJson(Map<String, dynamic> json) {
    return CardSnapshot(
      index: json['index'] as int,
      tag: json['tag'] as String?,
      visible: json['visible'] as bool? ?? false,
    );
  }
}

class PlayerSnapshot {
  final bool connected;
  final String displayName;
  final String avatarId;
  final String? playerId;
  final int seriesWins;
  final bool lobbyReady;
  final bool rematchReady;
  final LaunchStatus launch;
  final int total;
  final List<CardSnapshot> cards;
  final String? handCardTag;
  final bool hasHandCard;
  final bool jackPeekAvailable;
  final bool queenAbilityAvailable;

  const PlayerSnapshot({
    required this.connected,
    this.displayName = 'Player',
    this.avatarId = 'default',
    this.playerId,
    this.seriesWins = 0,
    this.lobbyReady = false,
    this.rematchReady = false,
    required this.launch,
    required this.total,
    required this.cards,
    required this.handCardTag,
    required this.hasHandCard,
    this.jackPeekAvailable = false,
    this.queenAbilityAvailable = false,
  });

  factory PlayerSnapshot.fromJson(Map<String, dynamic> json) {
    return PlayerSnapshot(
      connected: json['connected'] as bool? ?? false,
      displayName: json['displayName'] as String? ?? 'Player',
      avatarId: json['avatarId'] as String? ?? 'default',
      playerId: json['playerId'] as String?,
      seriesWins: json['seriesWins'] as int? ?? 0,
      lobbyReady: json['lobbyReady'] as bool? ?? false,
      rematchReady: json['rematchReady'] as bool? ?? false,
      launch: switch (json['launch']) {
        'launched' => LaunchStatus.launched,
        'ended' => LaunchStatus.ended,
        _ => LaunchStatus.notLaunched,
      },
      total: json['total'] as int? ?? 0,
      cards: (json['cards'] as List<dynamic>? ?? const [])
          .map((card) => CardSnapshot.fromJson(card as Map<String, dynamic>))
          .toList(growable: false),
      handCardTag: json['handCard'] as String?,
      hasHandCard: json['hasHandCard'] as bool? ?? false,
      jackPeekAvailable: json['jackPeekAvailable'] as bool? ?? false,
      queenAbilityAvailable: json['queenAbilityAvailable'] as bool? ?? false,
    );
  }

  bool get handCardIsJack {
    final tag = handCardTag;
    if (tag == null || tag.length < 2) return false;
    return int.tryParse(tag.substring(1)) == 11;
  }

  bool get handCardIsQueen {
    final tag = handCardTag;
    if (tag == null || tag.length < 2) return false;
    return int.tryParse(tag.substring(1)) == 12;
  }
}

class PlayerResultRating {
  final String? playerId;
  final String result;
  final int pointsEarned;
  final int eloDelta;
  final int? eloBefore;
  final int? eloAfter;

  const PlayerResultRating({
    this.playerId,
    required this.result,
    required this.pointsEarned,
    required this.eloDelta,
    this.eloBefore,
    this.eloAfter,
  });

  factory PlayerResultRating.fromJson(Map<String, dynamic> json) {
    return PlayerResultRating(
      playerId: json['playerId'] as String?,
      result: json['result'] as String? ?? 'draw',
      pointsEarned: (json['pointsEarned'] as num?)?.toInt() ?? 0,
      eloDelta: (json['eloDelta'] as num?)?.toInt() ?? 0,
      eloBefore: (json['eloBefore'] as num?)?.toInt(),
      eloAfter: (json['eloAfter'] as num?)?.toInt(),
    );
  }
}

class GameResult {
  final List<int> scores;
  final int? winnerIndex;
  final List<PlayerResultRating>? ratings;

  const GameResult({
    required this.scores,
    required this.winnerIndex,
    this.ratings,
  });

  factory GameResult.fromJson(Map<String, dynamic> json) {
    final ratingsJson = json['ratings'] as List<dynamic>?;
    return GameResult(
      scores: (json['scores'] as List<dynamic>).cast<int>(),
      winnerIndex: json['winnerIndex'] as int?,
      ratings: ratingsJson
          ?.map((r) => PlayerResultRating.fromJson(r as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}

class LastAction {
  final LastActionActor actor;
  final LastActionType type;
  final int? cardIndex;

  /// Public face of the card that left the hand (discarded / swapped out).
  final String? cardTag;

  /// Second public face (double-discard drawn card), when applicable.
  final String? drawnTag;

  /// Jack peek / queen shuffle target side from the actor's perspective.
  final String? side;

  /// Queen replace: actor's own card index.
  final int? youIndex;

  /// Queen replace: opponent card index (from actor's view).
  final int? opponentIndex;

  const LastAction({
    required this.actor,
    required this.type,
    required this.cardIndex,
    this.cardTag,
    this.drawnTag,
    this.side,
    this.youIndex,
    this.opponentIndex,
  });

  bool sameAs(LastAction? other) {
    if (other == null) return false;
    return actor == other.actor &&
        type == other.type &&
        cardIndex == other.cardIndex &&
        cardTag == other.cardTag &&
        drawnTag == other.drawnTag &&
        side == other.side &&
        youIndex == other.youIndex &&
        opponentIndex == other.opponentIndex;
  }

  static int? _parseIndex(dynamic raw) {
    return switch (raw) {
      null => null,
      int value => value,
      num value => value.toInt(),
      String value => int.tryParse(value),
      _ => null,
    };
  }

  static LastAction? tryParse(Map<String, dynamic>? json) {
    if (json == null) return null;
    final actor = switch (json['actor']) {
      'you' => LastActionActor.you,
      'opponent' => LastActionActor.opponent,
      _ => null,
    };
    final type = switch (json['type']) {
      'discardMatch' => LastActionType.discardMatch,
      'doubleDiscard' => LastActionType.doubleDiscard,
      'swap' => LastActionType.swap,
      'penaltyDraw' => LastActionType.penaltyDraw,
      'draw' => LastActionType.draw,
      'throw' => LastActionType.throwHand,
      'jackPeek' => LastActionType.jackPeek,
      'queenShuffle' => LastActionType.queenShuffle,
      'queenReplace' => LastActionType.queenReplace,
      _ => null,
    };
    if (actor == null || type == null) return null;
    final cardIndex = _parseIndex(json['cardIndex']);
    final youIndex = _parseIndex(json['youIndex']);
    final opponentIndex = _parseIndex(json['opponentIndex']);
    final needsIndex =
        type != LastActionType.draw &&
        type != LastActionType.throwHand &&
        type != LastActionType.queenShuffle;
    if (needsIndex &&
        cardIndex == null &&
        type != LastActionType.queenReplace) {
      return null;
    }
    if (type == LastActionType.queenReplace &&
        (youIndex == null || opponentIndex == null)) {
      return null;
    }
    final side = json['side'] as String?;
    return LastAction(
      actor: actor,
      type: type,
      cardIndex: cardIndex ?? youIndex,
      cardTag: json['cardTag'] as String?,
      drawnTag: json['drawnTag'] as String?,
      side: side == 'you' || side == 'opponent' ? side : null,
      youIndex: youIndex,
      opponentIndex: opponentIndex,
    );
  }
}

class GameSnapshot {
  final String roomId;
  final int version;
  final GameStatus status;
  final bool ready;
  final String matchType;
  final int stakePool;
  final int stakePerPlayer;
  final int potAmount;
  final int deckCount;
  final String? discardTopTag;

  /// Public discard pile, oldest first, capped to the two most recent cards.
  final List<String> discardRecentTags;
  final bool isYourTurn;
  final PlayerSnapshot you;
  final PlayerSnapshot? opponent;
  final GameResult? result;
  final LastAction? lastAction;

  /// Where the newest discard came from: `hand`, `drawn`, or null.
  final String? discardSource;

  const GameSnapshot({
    required this.roomId,
    required this.version,
    required this.status,
    required this.ready,
    this.matchType = 'private',
    this.stakePool = 0,
    this.stakePerPlayer = 0,
    this.potAmount = 0,
    required this.deckCount,
    required this.discardTopTag,
    required this.discardRecentTags,
    required this.isYourTurn,
    required this.you,
    required this.opponent,
    required this.result,
    required this.lastAction,
    this.discardSource,
  });

  factory GameSnapshot.fromJson(Map<String, dynamic> json) {
    final opponentJson = json['opponent'] as Map<String, dynamic>?;
    final resultJson = json['result'] as Map<String, dynamic>?;
    final lastActionJson = json['lastAction'] as Map<String, dynamic>?;
    return GameSnapshot(
      roomId: json['roomId'] as String,
      version: json['version'] as int,
      status: switch (json['status']) {
        'playing' => GameStatus.playing,
        'ended' => GameStatus.ended,
        _ => GameStatus.waiting,
      },
      ready: json['ready'] as bool? ?? false,
      matchType: json['matchType'] as String? ?? 'private',
      stakePool: (json['stakePool'] as num?)?.toInt() ?? 0,
      stakePerPlayer: (json['stakePerPlayer'] as num?)?.toInt() ?? 0,
      potAmount: (json['potAmount'] as num?)?.toInt() ?? 0,
      deckCount: json['deckCount'] as int? ?? 0,
      discardTopTag: json['discardTop'] as String?,
      discardRecentTags:
          (json['discardRecent'] as List<dynamic>? ?? const []).cast<String>(),
      isYourTurn: json['turn'] == 'you',
      you: PlayerSnapshot.fromJson(json['you'] as Map<String, dynamic>),
      opponent:
          opponentJson == null ? null : PlayerSnapshot.fromJson(opponentJson),
      result: resultJson == null ? null : GameResult.fromJson(resultJson),
      lastAction: LastAction.tryParse(lastActionJson),
      discardSource: json['discardSource'] as String?,
    );
  }

  bool get bothRevealed =>
      you.launch == LaunchStatus.ended &&
      opponent?.launch == LaunchStatus.ended;

  bool get canJackPeek =>
      status == GameStatus.playing &&
      you.jackPeekAvailable &&
      you.handCardIsJack;

  /// Peek reveal still running; Jack throws when it ends.
  bool get jackPeekInProgress =>
      status == GameStatus.playing &&
      lastAction?.type == LastActionType.jackPeek &&
      you.hasHandCard &&
      !you.jackPeekAvailable;

  bool get canQueenAbility =>
      status == GameStatus.playing &&
      you.queenAbilityAvailable &&
      you.handCardIsQueen;

  bool get queenAbilityInProgress =>
      status == GameStatus.playing &&
      you.hasHandCard &&
      !you.queenAbilityAvailable &&
      (lastAction?.type == LastActionType.queenShuffle ||
          lastAction?.type == LastActionType.queenReplace);

  bool get abilityLockActive => jackPeekInProgress || queenAbilityInProgress;
}
