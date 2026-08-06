/// Shared DTOs for Shadow Hand multiplayer wire protocol.

enum WireMatchPhase {
  lobby,
  dealing,
  reveal,
  playing,
  result;

  static WireMatchPhase fromName(String name) {
    return WireMatchPhase.values.firstWhere(
      (p) => p.name == name,
      orElse: () => WireMatchPhase.lobby,
    );
  }
}

enum WireCardActionType {
  draw,
  throwCard,
  swap,
  next,
  penalty,
  launch,
  end;

  static WireCardActionType fromName(String name) {
    switch (name) {
      case 'throw':
        return WireCardActionType.throwCard;
      default:
        return WireCardActionType.values.firstWhere(
          (a) => a.name == name,
          orElse: () => WireCardActionType.draw,
        );
    }
  }

  String get wireName => this == WireCardActionType.throwCard ? 'throw' : name;
}

class MatchQueueMessage {
  const MatchQueueMessage({
    this.mode = 'quick',
    this.stake = 100,
    this.displayName,
    this.playerId,
  });

  final String mode;
  final int stake;
  final String? displayName;
  final String? playerId;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'mode': mode,
        'stake': stake,
        if (displayName != null) 'displayName': displayName,
        if (playerId != null) 'playerId': playerId,
      };

  factory MatchQueueMessage.fromJson(Map<String, dynamic> json) {
    return MatchQueueMessage(
      mode: json['mode'] as String? ?? 'quick',
      stake: (json['stake'] as num?)?.toInt() ?? 100,
      displayName: json['displayName'] as String?,
      playerId: json['playerId'] as String?,
    );
  }
}

class MatchJoinMessage {
  const MatchJoinMessage({required this.matchId, this.playerId});

  final String matchId;
  final String? playerId;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'matchId': matchId,
        if (playerId != null) 'playerId': playerId,
      };

  factory MatchJoinMessage.fromJson(Map<String, dynamic> json) {
    return MatchJoinMessage(
      matchId: json['matchId'] as String? ?? '',
      playerId: json['playerId'] as String?,
    );
  }
}

class CardActionMessage {
  const CardActionMessage({
    required this.type,
    this.cardTag,
    this.hand = false,
    this.oldCardTag,
    this.newCardTag,
  });

  final WireCardActionType type;
  final String? cardTag;
  final bool hand;
  final String? oldCardTag;
  final String? newCardTag;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type.wireName,
        if (cardTag != null) 'card': cardTag,
        'hand': hand,
        if (oldCardTag != null) 'oldCard': oldCardTag,
        if (newCardTag != null) 'newCard': newCardTag,
      };

  factory CardActionMessage.fromJson(Map<String, dynamic> json) {
    return CardActionMessage(
      type: WireCardActionType.fromName(json['type'] as String? ?? 'draw'),
      cardTag: json['card'] as String?,
      hand: json['hand'] == true,
      oldCardTag: json['oldCard'] as String?,
      newCardTag: json['newCard'] as String?,
    );
  }
}

class WireCard {
  const WireCard({
    required this.tag,
    this.isThrown = false,
    this.cardSeen = false,
    this.isCardShown = false,
  });

  final String tag;
  final bool isThrown;
  final bool cardSeen;
  final bool isCardShown;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'tag': tag,
        'isThrown': isThrown,
        'cardSeen': cardSeen,
        'isCardShown': isCardShown,
      };

  factory WireCard.fromJson(Map<String, dynamic> json) {
    return WireCard(
      tag: json['tag'] as String? ?? '',
      isThrown: json['isThrown'] == true,
      cardSeen: json['cardSeen'] == true,
      isCardShown: json['isCardShown'] == true,
    );
  }
}

class WirePlayerState {
  const WirePlayerState({
    required this.id,
    required this.cards,
    this.handCard,
    this.total = 0,
    this.turn = false,
    this.launchReveal = 'NOT_LAUNCHED',
    this.displayName,
  });

  final String id;
  final List<WireCard> cards;
  final WireCard? handCard;
  final int total;
  final bool turn;
  final String launchReveal;
  final String? displayName;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'cards': cards.map((c) => c.toJson()).toList(growable: false),
        if (handCard != null) 'handCard': handCard!.toJson(),
        'total': total,
        'turn': turn,
        'launchReveal': launchReveal,
        if (displayName != null) 'displayName': displayName,
      };

  factory WirePlayerState.fromJson(Map<String, dynamic> json) {
    final rawCards = json['cards'];
    final cards = <WireCard>[];
    if (rawCards is List) {
      for (final item in rawCards) {
        if (item is Map) {
          cards.add(WireCard.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    final hand = json['handCard'];
    return WirePlayerState(
      id: json['id'] as String? ?? '',
      cards: cards,
      handCard: hand is Map
          ? WireCard.fromJson(Map<String, dynamic>.from(hand))
          : null,
      total: (json['total'] as num?)?.toInt() ?? 0,
      turn: json['turn'] == true,
      launchReveal: json['launchReveal'] as String? ?? 'NOT_LAUNCHED',
      displayName: json['displayName'] as String?,
    );
  }
}

class MatchFoundPlayer {
  const MatchFoundPlayer({
    required this.id,
    this.displayName,
  });

  final String id;
  final String? displayName;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        if (displayName != null) 'displayName': displayName,
      };

  factory MatchFoundPlayer.fromJson(Map<String, dynamic> json) {
    return MatchFoundPlayer(
      id: json['id'] as String? ?? '',
      displayName: json['displayName'] as String?,
    );
  }
}

class MatchFoundMessage {
  const MatchFoundMessage({
    required this.matchId,
    required this.localPlayerId,
    required this.players,
    this.rematchId,
    this.matchesPlayed = 0,
    this.mode,
    this.roomCode,
    this.stake = 100,
  });

  final String matchId;
  final String localPlayerId;
  final List<MatchFoundPlayer> players;
  final String? rematchId;
  final int matchesPlayed;
  final String? mode;
  final String? roomCode;
  final int stake;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'matchId': matchId,
        'localPlayerId': localPlayerId,
        'players': players.map((p) => p.toJson()).toList(growable: false),
        if (rematchId != null) 'rematchId': rematchId,
        'matchesPlayed': matchesPlayed,
        if (mode != null) 'mode': mode,
        if (roomCode != null) 'roomCode': roomCode,
        'stake': stake,
      };

  factory MatchFoundMessage.fromJson(Map<String, dynamic> json) {
    final rawPlayers = json['players'];
    final players = <MatchFoundPlayer>[];
    if (rawPlayers is List) {
      for (final item in rawPlayers) {
        if (item is Map) {
          players.add(
            MatchFoundPlayer.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    return MatchFoundMessage(
      matchId: json['matchId'] as String? ?? '',
      localPlayerId: json['localPlayerId'] as String? ?? '',
      players: players,
      rematchId: json['rematchId'] as String?,
      matchesPlayed: (json['matchesPlayed'] as num?)?.toInt() ?? 0,
      mode: json['mode'] as String?,
      roomCode: json['roomCode'] as String?,
      stake: (json['stake'] as num?)?.toInt() ?? 100,
    );
  }
}

class MatchSnapshotMessage {
  const MatchSnapshotMessage({
    required this.matchId,
    required this.phase,
    required this.localPlayerId,
    required this.players,
    required this.deck,
    required this.throwedCards,
    required this.currentPlayerId,
    this.outcome,
    this.winnerId,
    this.rematchId,
    this.matchesPlayed,
    this.stake = 100,
    this.topDiscardValue,
    this.canAct = false,
    this.revealSecondsLeft = 0,
  });

  final String matchId;
  final WireMatchPhase phase;
  final String localPlayerId;
  final List<WirePlayerState> players;
  final List<String> deck;
  final List<String> throwedCards;
  final String currentPlayerId;
  final String? outcome;
  final String? winnerId;
  final String? rematchId;
  final int? matchesPlayed;
  final int stake;
  final int? topDiscardValue;
  final bool canAct;
  final int revealSecondsLeft;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'matchId': matchId,
        'phase': phase.name,
        'localPlayerId': localPlayerId,
        'players': players.map((p) => p.toJson()).toList(growable: false),
        'deck': deck,
        'throwedCards': throwedCards,
        'currentPlayerId': currentPlayerId,
        if (outcome != null) 'outcome': outcome,
        if (winnerId != null) 'winnerId': winnerId,
        if (rematchId != null) 'rematchId': rematchId,
        if (matchesPlayed != null) 'matchesPlayed': matchesPlayed,
        'stake': stake,
        if (topDiscardValue != null) 'topDiscardValue': topDiscardValue,
        'canAct': canAct,
        'revealSecondsLeft': revealSecondsLeft,
      };

  factory MatchSnapshotMessage.fromJson(Map<String, dynamic> json) {
    final rawPlayers = json['players'];
    final players = <WirePlayerState>[];
    if (rawPlayers is List) {
      for (final item in rawPlayers) {
        if (item is Map) {
          players.add(
            WirePlayerState.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    return MatchSnapshotMessage(
      matchId: json['matchId'] as String? ?? '',
      phase: WireMatchPhase.fromName(json['phase'] as String? ?? 'lobby'),
      localPlayerId: json['localPlayerId'] as String? ?? '',
      players: players,
      deck: (json['deck'] as List?)?.whereType<String>().toList() ?? const [],
      throwedCards: (json['throwedCards'] as List?)?.whereType<String>().toList() ??
          const [],
      currentPlayerId: json['currentPlayerId'] as String? ?? '',
      outcome: json['outcome'] as String?,
      winnerId: json['winnerId'] as String?,
      rematchId: json['rematchId'] as String?,
      matchesPlayed: (json['matchesPlayed'] as num?)?.toInt(),
      stake: (json['stake'] as num?)?.toInt() ?? 100,
      topDiscardValue: (json['topDiscardValue'] as num?)?.toInt(),
      canAct: json['canAct'] == true,
      revealSecondsLeft: (json['revealSecondsLeft'] as num?)?.toInt() ?? 0,
    );
  }
}

class RoomCreateMessage {
  const RoomCreateMessage({
    required this.playerId,
    this.displayName,
    this.stake = 100,
  });

  final String playerId;
  final String? displayName;
  final int stake;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'playerId': playerId,
        if (displayName != null) 'displayName': displayName,
        'stake': stake,
      };

  factory RoomCreateMessage.fromJson(Map<String, dynamic> json) {
    return RoomCreateMessage(
      playerId: json['playerId'] as String? ?? '',
      displayName: json['displayName'] as String?,
      stake: (json['stake'] as num?)?.toInt() ?? 100,
    );
  }
}

class RoomJoinMessage {
  const RoomJoinMessage({
    required this.playerId,
    required this.code,
    this.displayName,
  });

  final String playerId;
  final String code;
  final String? displayName;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'playerId': playerId,
        'code': code,
        if (displayName != null) 'displayName': displayName,
      };

  factory RoomJoinMessage.fromJson(Map<String, dynamic> json) {
    return RoomJoinMessage(
      playerId: json['playerId'] as String? ?? '',
      code: json['code'] as String? ?? '',
      displayName: json['displayName'] as String?,
    );
  }
}

class RoomKickMessage {
  const RoomKickMessage({required this.targetPlayerId});

  final String targetPlayerId;

  Map<String, dynamic> toJson() =>
      <String, dynamic>{'targetPlayerId': targetPlayerId};

  factory RoomKickMessage.fromJson(Map<String, dynamic> json) {
    return RoomKickMessage(
      targetPlayerId: json['targetPlayerId'] as String? ?? '',
    );
  }
}

class RoomInviteMessage {
  const RoomInviteMessage({required this.targetPlayerIds});

  final List<String> targetPlayerIds;

  Map<String, dynamic> toJson() =>
      <String, dynamic>{'targetPlayerIds': targetPlayerIds};

  factory RoomInviteMessage.fromJson(Map<String, dynamic> json) {
    final raw = json['targetPlayerIds'];
    return RoomInviteMessage(
      targetPlayerIds: raw is List
          ? raw.whereType<String>().toList(growable: false)
          : const [],
    );
  }
}

class RoomMember {
  const RoomMember({
    required this.playerId,
    required this.name,
    this.isHost = false,
  });

  final String playerId;
  final String name;
  final bool isHost;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'playerId': playerId,
        'name': name,
        'isHost': isHost,
      };

  factory RoomMember.fromJson(Map<String, dynamic> json) {
    return RoomMember(
      playerId: json['playerId'] as String? ?? '',
      name: json['name'] as String? ?? 'Player',
      isHost: json['isHost'] == true,
    );
  }
}

class RoomStateMessage {
  const RoomStateMessage({
    required this.code,
    required this.hostPlayerId,
    required this.members,
    this.stake = 100,
    this.closed = false,
    this.reason,
  });

  final String code;
  final String hostPlayerId;
  final List<RoomMember> members;
  final int stake;
  final bool closed;
  final String? reason;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'code': code,
        'hostPlayerId': hostPlayerId,
        'members': members.map((m) => m.toJson()).toList(growable: false),
        'stake': stake,
        'closed': closed,
        if (reason != null) 'reason': reason,
      };

  factory RoomStateMessage.fromJson(Map<String, dynamic> json) {
    final rawMembers = json['members'];
    final members = <RoomMember>[];
    if (rawMembers is List) {
      for (final item in rawMembers) {
        if (item is Map) {
          members.add(RoomMember.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    return RoomStateMessage(
      code: json['code'] as String? ?? '',
      hostPlayerId: json['hostPlayerId'] as String? ?? '',
      members: members,
      stake: (json['stake'] as num?)?.toInt() ?? 100,
      closed: json['closed'] == true,
      reason: json['reason'] as String?,
    );
  }
}

class RoomPresenceMessage {
  const RoomPresenceMessage({
    this.playerId,
    this.playerIds = const [],
    this.onlinePlayerIds = const [],
  });

  final String? playerId;
  final List<String> playerIds;
  final List<String> onlinePlayerIds;

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (playerId != null) 'playerId': playerId,
        if (playerIds.isNotEmpty) 'playerIds': playerIds,
        if (onlinePlayerIds.isNotEmpty) 'onlinePlayerIds': onlinePlayerIds,
      };

  factory RoomPresenceMessage.fromJson(Map<String, dynamic> json) {
    final ids = json['playerIds'];
    final online = json['onlinePlayerIds'];
    return RoomPresenceMessage(
      playerId: json['playerId'] as String?,
      playerIds:
          ids is List ? ids.whereType<String>().toList(growable: false) : const [],
      onlinePlayerIds: online is List
          ? online.whereType<String>().toList(growable: false)
          : const [],
    );
  }
}

class MatchErrorMessage {
  const MatchErrorMessage({required this.code, required this.message});

  final String code;
  final String message;

  Map<String, dynamic> toJson() =>
      <String, dynamic>{'code': code, 'message': message};

  factory MatchErrorMessage.fromJson(Map<String, dynamic> json) {
    return MatchErrorMessage(
      code: json['code'] as String? ?? 'unknown',
      message: json['message'] as String? ?? 'Unknown error',
    );
  }
}

class RematchJoinMessage {
  const RematchJoinMessage({
    required this.rematchId,
    this.matchId,
    this.playerId,
    this.displayName,
  });

  final String rematchId;
  final String? matchId;
  final String? playerId;
  final String? displayName;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'rematchId': rematchId,
        if (matchId != null) 'matchId': matchId,
        if (playerId != null) 'playerId': playerId,
        if (displayName != null) 'displayName': displayName,
      };

  factory RematchJoinMessage.fromJson(Map<String, dynamic> json) {
    return RematchJoinMessage(
      rematchId: json['rematchId'] as String? ?? '',
      matchId: json['matchId'] as String?,
      playerId: json['playerId'] as String?,
      displayName: json['displayName'] as String?,
    );
  }
}

class RematchReadyMessage {
  const RematchReadyMessage({required this.rematchId, required this.ready});

  final String rematchId;
  final bool ready;

  Map<String, dynamic> toJson() =>
      <String, dynamic>{'rematchId': rematchId, 'ready': ready};

  factory RematchReadyMessage.fromJson(Map<String, dynamic> json) {
    return RematchReadyMessage(
      rematchId: json['rematchId'] as String? ?? '',
      ready: json['ready'] == true,
    );
  }
}

class RematchLeaveMessage {
  const RematchLeaveMessage({required this.rematchId});

  final String rematchId;

  Map<String, dynamic> toJson() => <String, dynamic>{'rematchId': rematchId};

  factory RematchLeaveMessage.fromJson(Map<String, dynamic> json) {
    return RematchLeaveMessage(rematchId: json['rematchId'] as String? ?? '');
  }
}

class RematchMember {
  const RematchMember({
    required this.playerId,
    required this.name,
    required this.ready,
  });

  final String playerId;
  final String name;
  final bool ready;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'playerId': playerId,
        'name': name,
        'ready': ready,
      };

  factory RematchMember.fromJson(Map<String, dynamic> json) {
    return RematchMember(
      playerId: json['playerId'] as String? ?? '',
      name: json['name'] as String? ?? 'Player',
      ready: json['ready'] == true,
    );
  }
}

class RematchStateMessage {
  const RematchStateMessage({
    required this.rematchId,
    required this.mode,
    required this.matchesPlayed,
    required this.expectedPlayers,
    required this.members,
    this.roomCode,
    this.stake = 100,
    this.closed = false,
  });

  final String rematchId;
  final String mode;
  final String? roomCode;
  final int matchesPlayed;
  final int expectedPlayers;
  final List<RematchMember> members;
  final int stake;
  final bool closed;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'rematchId': rematchId,
        'mode': mode,
        if (roomCode != null) 'roomCode': roomCode,
        'matchesPlayed': matchesPlayed,
        'expectedPlayers': expectedPlayers,
        'members': members.map((m) => m.toJson()).toList(growable: false),
        'stake': stake,
        'closed': closed,
      };

  factory RematchStateMessage.fromJson(Map<String, dynamic> json) {
    final rawMembers = json['members'];
    final members = <RematchMember>[];
    if (rawMembers is List) {
      for (final item in rawMembers) {
        if (item is Map) {
          members.add(RematchMember.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    return RematchStateMessage(
      rematchId: json['rematchId'] as String? ?? '',
      mode: json['mode'] as String? ?? 'quick',
      roomCode: json['roomCode'] as String?,
      matchesPlayed: (json['matchesPlayed'] as num?)?.toInt() ?? 0,
      expectedPlayers: (json['expectedPlayers'] as num?)?.toInt() ?? 0,
      members: members,
      stake: (json['stake'] as num?)?.toInt() ?? 100,
      closed: json['closed'] == true,
    );
  }
}
