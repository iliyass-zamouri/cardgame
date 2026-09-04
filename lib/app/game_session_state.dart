import 'package:cardgame/domain/models/game_snapshot.dart';

enum ConnectionStatus { disconnected, connecting, connected }

class TableInviteNotification {
  final String roomId;
  final String inviterName;
  final String inviterPlayerId;

  const TableInviteNotification({
    required this.roomId,
    required this.inviterName,
    required this.inviterPlayerId,
  });
}

class FriendAlertNotification {
  final String kind; // 'request' | 'accepted'
  final String playerId;
  final String playerName;
  final String? requestId;

  const FriendAlertNotification({
    required this.kind,
    required this.playerId,
    required this.playerName,
    this.requestId,
  });
}

class GameSessionState {
  static const _unset = Object();

  final ConnectionStatus connection;
  final GameSnapshot? game;
  final String? clientId;
  final String? message;
  final bool peekSelecting;
  final QueenMode queenMode;
  final bool searchingMatch;
  final TableInviteNotification? incomingInvite;
  final Set<String> sentInvitePlayerIds;
  final FriendAlertNotification? friendAlert;

  /// Replace pick: first selection side (`you` / `opponent`) and index.
  final String? replaceFirstSide;
  final int? replaceFirstIndex;

  const GameSessionState({
    this.connection = ConnectionStatus.disconnected,
    this.game,
    this.clientId,
    this.message,
    this.peekSelecting = false,
    this.queenMode = QueenMode.none,
    this.searchingMatch = false,
    this.incomingInvite,
    this.sentInvitePlayerIds = const {},
    this.friendAlert,
    this.replaceFirstSide,
    this.replaceFirstIndex,
  });

  GameSessionState copyWith({
    ConnectionStatus? connection,
    Object? game = _unset,
    Object? clientId = _unset,
    Object? message = _unset,
    bool? peekSelecting,
    QueenMode? queenMode,
    bool? searchingMatch,
    Object? incomingInvite = _unset,
    Set<String>? sentInvitePlayerIds,
    Object? friendAlert = _unset,
    Object? replaceFirstSide = _unset,
    Object? replaceFirstIndex = _unset,
  }) {
    return GameSessionState(
      connection: connection ?? this.connection,
      game: identical(game, _unset) ? this.game : game as GameSnapshot?,
      clientId:
          identical(clientId, _unset) ? this.clientId : clientId as String?,
      message: identical(message, _unset) ? this.message : message as String?,
      peekSelecting: peekSelecting ?? this.peekSelecting,
      queenMode: queenMode ?? this.queenMode,
      searchingMatch: searchingMatch ?? this.searchingMatch,
      incomingInvite:
          identical(incomingInvite, _unset)
              ? this.incomingInvite
              : incomingInvite as TableInviteNotification?,
      sentInvitePlayerIds: sentInvitePlayerIds ?? this.sentInvitePlayerIds,
      friendAlert:
          identical(friendAlert, _unset)
              ? this.friendAlert
              : friendAlert as FriendAlertNotification?,
      replaceFirstSide:
          identical(replaceFirstSide, _unset)
              ? this.replaceFirstSide
              : replaceFirstSide as String?,
      replaceFirstIndex:
          identical(replaceFirstIndex, _unset)
              ? this.replaceFirstIndex
              : replaceFirstIndex as int?,
    );
  }
}
