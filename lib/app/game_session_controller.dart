import 'dart:async';
import 'dart:convert';

import 'package:cardgame/app/game_session_state.dart';
import 'package:cardgame/data/game_socket.dart';
import 'package:cardgame/data/socket_client.dart';
import 'package:cardgame/domain/models/game_snapshot.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef GameSocketFactory = GameSocket Function();

final gameSocketFactoryProvider = Provider<GameSocketFactory>(
  (ref) => SocketClient.new,
);

final gameSessionProvider =
    NotifierProvider<GameSessionController, GameSessionState>(
  GameSessionController.new,
);

class GameSessionController extends Notifier<GameSessionState> {
  GameSocket? _socket;
  StreamSubscription<String>? _subscription;

  @override
  GameSessionState build() {
    ref.onDispose(_disposeSocket);
    Future.microtask(connect);
    return const GameSessionState();
  }

  void connect() {
    _disposeSocket();
    state = state.copyWith(
      connection: ConnectionStatus.connecting,
      message: null,
    );
    final socket = ref.read(gameSocketFactoryProvider)();
    _socket = socket;
    _subscription = socket.stream.listen(
      _handleMessage,
      onError: (_) {
        state = state.copyWith(
          connection: ConnectionStatus.disconnected,
          message: 'Connection lost',
        );
      },
      onDone: () {
        state = state.copyWith(connection: ConnectionStatus.disconnected);
      },
    );
  }

  void createRoom() => _send('createRoom');

  void joinRoom(String roomId) {
    final normalized = roomId.trim().toUpperCase();
    if (normalized.isEmpty) {
      state = state.copyWith(message: 'Enter a room code');
      return;
    }
    _send('joinRoom', {'roomId': normalized});
  }

  void leaveRoom() => _send('leaveRoom');

  void startGame() => _send('startGame');

  void launch() => _send('launch');

  void drawCard() => _send('draw');

  void tapCard(int cardIndex) => _send('tapCard', {'cardIndex': cardIndex});

  void throwHandCard() => _send('throwHand');

  void endGame() => _send('endGame');

  void clearMessage() {
    if (state.message != null) state = state.copyWith(message: null);
  }

  void _handleMessage(String raw) {
    final message = jsonDecode(raw) as Map<String, dynamic>;
    switch (message['type']) {
      case 'connected':
        state = state.copyWith(
          connection: ConnectionStatus.connected,
          clientId: message['clientId'] as String?,
          message: null,
        );
        break;
      case 'snapshot':
        final snapshot = GameSnapshot.fromJson(message);
        final currentVersion = state.game?.version ?? -1;
        if (snapshot.version >= currentVersion ||
            snapshot.roomId != state.game?.roomId) {
          state = state.copyWith(game: snapshot, message: null);
        }
        break;
      case 'leftRoom':
        state = state.copyWith(game: null, message: null);
        break;
      case 'error':
        state = state.copyWith(
          message: message['message'] as String? ?? 'Command failed',
        );
        break;
    }
  }

  void _send(String type, [Map<String, dynamic> payload = const {}]) {
    if (state.connection != ConnectionStatus.connected) {
      state = state.copyWith(message: 'Server is not connected');
      return;
    }
    _socket?.send(jsonEncode({'type': type, ...payload}));
  }

  void _disposeSocket() {
    _subscription?.cancel();
    _subscription = null;
    _socket?.close();
    _socket = null;
  }
}
