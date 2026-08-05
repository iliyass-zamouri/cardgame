import 'package:cardgame/domain/models/game_snapshot.dart';

enum ConnectionStatus { disconnected, connecting, connected }

class GameSessionState {
  static const _unset = Object();

  final ConnectionStatus connection;
  final GameSnapshot? game;
  final String? clientId;
  final String? message;

  const GameSessionState({
    this.connection = ConnectionStatus.disconnected,
    this.game,
    this.clientId,
    this.message,
  });

  GameSessionState copyWith({
    ConnectionStatus? connection,
    Object? game = _unset,
    Object? clientId = _unset,
    Object? message = _unset,
  }) {
    return GameSessionState(
      connection: connection ?? this.connection,
      game: identical(game, _unset) ? this.game : game as GameSnapshot?,
      clientId:
          identical(clientId, _unset) ? this.clientId : clientId as String?,
      message: identical(message, _unset) ? this.message : message as String?,
    );
  }
}
