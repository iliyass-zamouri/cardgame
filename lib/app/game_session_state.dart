import 'package:cardgame/domain/models/game_snapshot.dart';

enum ConnectionStatus { disconnected, connecting, connected }

class GameSessionState {
  static const _unset = Object();

  final ConnectionStatus connection;
  final GameSnapshot? game;
  final String? clientId;
  final String? message;
  final bool peekSelecting;
  final QueenMode queenMode;

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
