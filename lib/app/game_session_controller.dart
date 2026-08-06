import 'dart:async';
import 'dart:convert';

import 'package:cardgame/app/auth_providers.dart';
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

  Map<String, dynamic> get _identityPayload {
    final profile = ref.read(playerProfileRepositoryProvider).load();
    if (profile.isEmpty) return const {};
    return {'playerId': profile.playerId, 'displayName': profile.name};
  }

  void connect() {
    _disposeSocket();
    state = state.copyWith(
      connection: ConnectionStatus.connecting,
      message: null,
      searchingMatch: false,
    );
    final socket = ref.read(gameSocketFactoryProvider)();
    _socket = socket;
    _subscription = socket.stream.listen(
      _handleMessage,
      onError: (_) {
        state = state.copyWith(
          connection: ConnectionStatus.disconnected,
          message: 'connection_lost',
          searchingMatch: false,
        );
      },
      onDone: () {
        state = state.copyWith(
          connection: ConnectionStatus.disconnected,
          searchingMatch: false,
        );
      },
    );
  }

  void createRoom() => _send('createRoom', _identityPayload);

  void joinRoom(String roomId) {
    final normalized = roomId.trim().toUpperCase();
    if (normalized.isEmpty) {
      state = state.copyWith(message: 'enter_room_code');
      return;
    }
    _send('joinRoom', {'roomId': normalized, ..._identityPayload});
  }

  void findMatch() {
    state = state.copyWith(searchingMatch: true, message: null, game: null);
    _send('findMatch', _identityPayload);
  }

  void cancelFindMatch() {
    state = state.copyWith(searchingMatch: false);
    _send('cancelFindMatch');
  }

  void leaveRoom() => _send('leaveRoom');

  void readyUp() => _send('startGame');

  void rematch() => _send('rematch');

  void launch() => _send('launch');

  void drawCard() => _send('draw');

  void tapCard(int cardIndex) => _send('tapCard', {'cardIndex': cardIndex});

  void throwHandCard() => _send('throwHand');

  void endGame() => _send('endGame');

  void togglePeekSelecting() {
    final game = state.game;
    if (game == null || !game.canJackPeek) {
      if (state.peekSelecting) {
        state = state.copyWith(peekSelecting: false);
      }
      return;
    }
    state = state.copyWith(
      peekSelecting: !state.peekSelecting,
      queenMode: QueenMode.none,
      replaceFirstSide: null,
      replaceFirstIndex: null,
    );
  }

  void cancelPeekSelecting() {
    if (state.peekSelecting) {
      state = state.copyWith(peekSelecting: false);
    }
  }

  void jackPeek({required String side, required int cardIndex}) {
    cancelPeekSelecting();
    _send('jackPeek', {'side': side, 'cardIndex': cardIndex});
  }

  void enterQueenShufflePick() {
    final game = state.game;
    if (game == null || !game.canQueenAbility) return;
    state = state.copyWith(
      queenMode: QueenMode.shufflePick,
      peekSelecting: false,
      replaceFirstSide: null,
      replaceFirstIndex: null,
    );
  }

  void enterQueenReplacePick() {
    final game = state.game;
    if (game == null || !game.canQueenAbility) return;
    state = state.copyWith(
      queenMode: QueenMode.replacePick,
      peekSelecting: false,
      replaceFirstSide: null,
      replaceFirstIndex: null,
    );
  }

  void cancelQueenMode() {
    if (state.queenMode == QueenMode.none && state.replaceFirstSide == null) {
      return;
    }
    state = state.copyWith(
      queenMode: QueenMode.none,
      replaceFirstSide: null,
      replaceFirstIndex: null,
    );
  }

  void queenShuffle({required String side}) {
    cancelQueenMode();
    _send('queenShuffle', {'side': side});
  }

  void selectReplaceCard({required String side, required int cardIndex}) {
    if (state.queenMode != QueenMode.replacePick) return;
    final firstSide = state.replaceFirstSide;
    final firstIndex = state.replaceFirstIndex;
    if (firstSide == null || firstIndex == null) {
      state = state.copyWith(
        replaceFirstSide: side,
        replaceFirstIndex: cardIndex,
      );
      return;
    }
    if (firstSide == side) {
      state = state.copyWith(
        replaceFirstSide: side,
        replaceFirstIndex: cardIndex,
      );
      return;
    }
    final youIndex = firstSide == 'you' ? firstIndex : cardIndex;
    final opponentIndex = firstSide == 'opponent' ? firstIndex : cardIndex;
    cancelQueenMode();
    _send('queenReplace', {
      'youIndex': youIndex,
      'opponentIndex': opponentIndex,
    });
  }

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
          final keepPeek = state.peekSelecting && snapshot.canJackPeek;
          final keepQueen =
              state.queenMode != QueenMode.none && snapshot.canQueenAbility;
          state = state.copyWith(
            game: snapshot,
            message: null,
            searchingMatch: false,
            peekSelecting: keepPeek,
            queenMode: keepQueen ? state.queenMode : QueenMode.none,
            replaceFirstSide: keepQueen ? state.replaceFirstSide : null,
            replaceFirstIndex: keepQueen ? state.replaceFirstIndex : null,
          );
        }
        break;
      case 'leftRoom':
        state = state.copyWith(
          game: null,
          message: null,
          searchingMatch: false,
          peekSelecting: false,
          queenMode: QueenMode.none,
          replaceFirstSide: null,
          replaceFirstIndex: null,
        );
        break;
      case 'leftQueue':
        state = state.copyWith(searchingMatch: false, message: null);
        break;
      case 'error':
        final code = message['code'] as String?;
        state = state.copyWith(
          message: (code != null && code.isNotEmpty) ? code : 'command_failed',
        );
        break;
    }
  }

  void _send(String type, [Map<String, dynamic> payload = const {}]) {
    if (state.connection != ConnectionStatus.connected) {
      state = state.copyWith(message: 'server_not_connected');
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
