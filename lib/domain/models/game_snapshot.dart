enum GameStatus { waiting, playing, ended }

enum LaunchStatus { notLaunched, launched, ended }

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
  final LaunchStatus launch;
  final int total;
  final List<CardSnapshot> cards;
  final String? handCardTag;
  final bool hasHandCard;

  const PlayerSnapshot({
    required this.connected,
    required this.launch,
    required this.total,
    required this.cards,
    required this.handCardTag,
    required this.hasHandCard,
  });

  factory PlayerSnapshot.fromJson(Map<String, dynamic> json) {
    return PlayerSnapshot(
      connected: json['connected'] as bool? ?? false,
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
    );
  }
}

class GameResult {
  final List<int> scores;
  final int? winnerIndex;

  const GameResult({required this.scores, required this.winnerIndex});

  factory GameResult.fromJson(Map<String, dynamic> json) {
    return GameResult(
      scores: (json['scores'] as List<dynamic>).cast<int>(),
      winnerIndex: json['winnerIndex'] as int?,
    );
  }
}

class GameSnapshot {
  final String roomId;
  final int version;
  final GameStatus status;
  final bool ready;
  final int deckCount;
  final String? discardTopTag;

  /// Public discard pile, oldest first, capped to the two most recent cards.
  final List<String> discardRecentTags;
  final bool isYourTurn;
  final PlayerSnapshot you;
  final PlayerSnapshot? opponent;
  final GameResult? result;

  const GameSnapshot({
    required this.roomId,
    required this.version,
    required this.status,
    required this.ready,
    required this.deckCount,
    required this.discardTopTag,
    required this.discardRecentTags,
    required this.isYourTurn,
    required this.you,
    required this.opponent,
    required this.result,
  });

  factory GameSnapshot.fromJson(Map<String, dynamic> json) {
    final opponentJson = json['opponent'] as Map<String, dynamic>?;
    final resultJson = json['result'] as Map<String, dynamic>?;
    return GameSnapshot(
      roomId: json['roomId'] as String,
      version: json['version'] as int,
      status: switch (json['status']) {
        'playing' => GameStatus.playing,
        'ended' => GameStatus.ended,
        _ => GameStatus.waiting,
      },
      ready: json['ready'] as bool? ?? false,
      deckCount: json['deckCount'] as int? ?? 0,
      discardTopTag: json['discardTop'] as String?,
      discardRecentTags:
          (json['discardRecent'] as List<dynamic>? ?? const []).cast<String>(),
      isYourTurn: json['turn'] == 'you',
      you: PlayerSnapshot.fromJson(json['you'] as Map<String, dynamic>),
      opponent:
          opponentJson == null ? null : PlayerSnapshot.fromJson(opponentJson),
      result: resultJson == null ? null : GameResult.fromJson(resultJson),
    );
  }

  bool get bothRevealed =>
      you.launch == LaunchStatus.ended &&
      opponent?.launch == LaunchStatus.ended;
}
