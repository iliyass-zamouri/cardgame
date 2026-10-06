import 'dart:async';
import 'dart:convert';

import 'package:cardgame/app/auth_providers.dart';
import 'package:cardgame/app/friends_providers.dart';
import 'package:cardgame/app/game_session_state.dart';
import 'package:cardgame/data/avatars/avatar_catalog.dart';
import 'package:cardgame/data/game_socket.dart';
import 'package:cardgame/data/offline/offline_game_socket.dart';
import 'package:cardgame/data/socket_client.dart';
import 'package:cardgame/domain/models/game_snapshot.dart';
import 'package:cardgame/services/analytics_service.dart';
import 'package:flutter/widgets.dart';
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
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;
  bool _offlineMode = false;

  /// Periodic connection check: pings while connected, reconnects while down.
  Timer? _healthTimer;
  AppLifecycleListener? _lifecycle;
  bool _backgrounded = false;
  DateTime _lastInboundAt = DateTime.now();
  DateTime? _connectStartedAt;

  /// Backoff between automatic reconnects; retries never stop (last value repeats).
  static const _reconnectDelaysSec = [1, 2, 4, 8, 15];
  static const _healthInterval = Duration(seconds: 10);

  /// No server message for this long while "connected" means a dead socket.
  static const _staleAfter = Duration(seconds: 30);
  static const _connectTimeout = Duration(seconds: 15);

  @override
  GameSessionState build() {
    ref.onDispose(() {
      _healthTimer?.cancel();
      _healthTimer = null;
      _lifecycle?.dispose();
      _lifecycle = null;
      _disposeSocket();
    });
    _healthTimer = Timer.periodic(_healthInterval, (_) => _checkHealth());
    _listenLifecycle();
    Future.microtask(connect);
    return const GameSessionState();
  }

  void _listenLifecycle() {
    try {
      _lifecycle = AppLifecycleListener(
        onHide: () => _backgrounded = true,
        onShow: () {
          _backgrounded = false;
          if (state.connection == ConnectionStatus.connected) {
            _probe();
          } else {
            _checkHealth(force: true);
          }
        },
      );
    } catch (_) {
      // No widgets binding (plain unit tests): periodic checks still run.
    }
  }

  void _checkHealth({bool force = false}) {
    if (_offlineMode || (_backgrounded && !force)) return;
    final now = DateTime.now();
    switch (state.connection) {
      case ConnectionStatus.connected:
        if (now.difference(_lastInboundAt) > _staleAfter) {
          _onConnectionLost();
          return;
        }
        _socket?.send(
          jsonEncode({'type': 'ping', 'at': now.millisecondsSinceEpoch}),
        );
      case ConnectionStatus.connecting:
        final startedAt = _connectStartedAt;
        if (startedAt != null && now.difference(startedAt) > _connectTimeout) {
          _onConnectionLost();
        }
      case ConnectionStatus.disconnected:
        // Returning to the app retries at once instead of waiting out backoff.
        if (force || _reconnectTimer == null) {
          connect(resetReconnect: force);
        }
    }
  }

  /// After resuming, a socket can look open but be dead: ping and give the
  /// server a few seconds to answer before reconnecting.
  void _probe() {
    final sentAt = DateTime.now();
    _socket?.send(
      jsonEncode({'type': 'ping', 'at': sentAt.millisecondsSinceEpoch}),
    );
    Timer(const Duration(seconds: 5), () {
      if (state.connection == ConnectionStatus.connected &&
          _lastInboundAt.isBefore(sentAt)) {
        _onConnectionLost();
      }
    });
  }

  void _onConnectionLost() {
    if (_offlineMode) return;
    _disposeSocket(cancelReconnect: false);
    state = state.copyWith(
      connection: ConnectionStatus.disconnected,
      searchingMatch: false,
    );
    _maybeScheduleReconnect();
  }

  Map<String, dynamic> get _identityPayload {
    final asyncProfile = ref.read(playerProfileProvider).asData?.value;
    final repoProfile = ref.read(playerProfileRepositoryProvider).load();
    final activeProfile =
        (asyncProfile != null && !asyncProfile.isEmpty)
            ? asyncProfile
            : repoProfile;
    if (activeProfile.isEmpty) return const {};
    final token = activeProfile.accessToken;
    return {
      'playerId': activeProfile.playerId,
      'displayName': activeProfile.name,
      'avatarId': activeProfile.avatarId,
      'deckId': activeProfile.deckId,
      if (token != null && token.isNotEmpty) 'token': token,
    };
  }

  void connect({bool resetReconnect = true}) {
    if (_offlineMode) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    if (resetReconnect) _reconnectAttempt = 0;
    _disposeSocket(cancelReconnect: false);
    _connectStartedAt = DateTime.now();
    state = state.copyWith(
      connection: ConnectionStatus.connecting,
      message: null,
      searchingMatch: false,
    );
    final socket = ref.read(gameSocketFactoryProvider)();
    _attachSocket(socket);
  }

  /// Start an offline match vs the heuristic robot. No network required.
  void playVsRobot({String robotName = 'Robot'}) {
    _cancelReconnect();
    _disposeSocket(cancelReconnect: false);
    _offlineMode = true;
    final asyncProfile = ref.read(playerProfileProvider).asData?.value;
    final repoProfile = ref.read(playerProfileRepositoryProvider).load();
    final profile =
        (asyncProfile != null && !asyncProfile.isEmpty)
            ? asyncProfile
            : repoProfile;
    final displayName =
        profile.isEmpty || profile.name.trim().isEmpty
            ? 'Player'
            : profile.name;
    state = state.copyWith(
      connection: ConnectionStatus.connected,
      message: null,
      searchingMatch: false,
      game: null,
      peekSelecting: false,
      queenMode: QueenMode.none,
      replaceFirstSide: null,
      replaceFirstIndex: null,
      clientId: kOfflineHumanId,
    );
    final socket = OfflineGameSocket(
      humanDisplayName: displayName,
      humanPlayerId: profile.isEmpty ? null : profile.playerId,
      humanDeckId: profile.deckId.isNotEmpty ? profile.deckId : 'default',
      robotDisplayName: robotName,
    );
    _attachSocket(socket);
  }

  void _attachSocket(GameSocket socket) {
    _socket = socket;
    _subscription = socket.stream.listen(
      _handleMessage,
      onError: (_) {
        if (_offlineMode) return;
        // Only announce losing a live connection, not each failed retry.
        final wasConnected = state.connection == ConnectionStatus.connected;
        state = state.copyWith(
          connection: ConnectionStatus.disconnected,
          message: wasConnected ? 'connection_lost' : state.message,
          searchingMatch: false,
        );
        _maybeScheduleReconnect();
      },
      onDone: () {
        if (_offlineMode) return;
        state = state.copyWith(
          connection: ConnectionStatus.disconnected,
          searchingMatch: false,
        );
        _maybeScheduleReconnect();
      },
    );
  }

  void _maybeScheduleReconnect() {
    if (_offlineMode) return;
    if (_reconnectTimer != null) return;

    final delaySec =
        _reconnectDelaysSec[_reconnectAttempt.clamp(
          0,
          _reconnectDelaysSec.length - 1,
        )];
    _reconnectAttempt++;
    _reconnectTimer = Timer(Duration(seconds: delaySec), () {
      _reconnectTimer = null;
      if (_offlineMode || _backgrounded) return;
      connect(resetReconnect: false);
    });
  }

  void _cancelReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempt = 0;
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

  void findMatch({
    int stakePool = 50,
    CurrencyType stakeCurrency = CurrencyType.money,
  }) {
    state = state.copyWith(searchingMatch: true, message: null, game: null);
    _send('findMatch', {
      'stakePool': stakePool,
      'stakeCurrency': stakeCurrency.name,
      ..._identityPayload,
    });
  }

  void cancelFindMatch() {
    state = state.copyWith(searchingMatch: false);
    _send('cancelFindMatch');
  }

  void leaveRoom() {
    _cancelReconnect();
    if (_offlineMode) {
      _offlineMode = false;
      _disposeSocket(cancelReconnect: false);
      state = state.copyWith(
        game: null,
        message: null,
        searchingMatch: false,
        peekSelecting: false,
        queenMode: QueenMode.none,
        replaceFirstSide: null,
        replaceFirstIndex: null,
        sentInvitePlayerIds: const {},
      );
      connect();
      ref.read(playerProfileProvider.notifier).refreshInventory().ignore();
      return;
    }
    _send('leaveRoom');
    ref.read(playerProfileProvider.notifier).refreshInventory().ignore();
  }

  void sendTableInvite({
    required String targetPlayerId,
    required String roomId,
  }) {
    final trimmedId = targetPlayerId.trim();
    if (trimmedId.isEmpty) return;
    state = state.copyWith(
      sentInvitePlayerIds: {...state.sentInvitePlayerIds, trimmedId},
    );
    _send('tableInvite', {
      'targetPlayerId': trimmedId,
      'roomId': roomId.trim().toUpperCase(),
    });
    unawaited(ref.read(analyticsServiceProvider).inviteAction(action: 'send'));
  }

  void dismissIncomingInvite() {
    state = state.copyWith(incomingInvite: null);
  }

  void clearFriendAlert() {
    if (state.friendAlert != null) {
      state = state.copyWith(friendAlert: null);
    }
  }

  void acceptIncomingInvite(String roomId) {
    state = state.copyWith(incomingInvite: null);
    joinRoom(roomId);
  }

  void readyUp() => _send('startGame');

  /// Staked rematches take the stake again; a short player gets the
  /// top-up sheet instead of the request.
  void rematch() {
    final game = state.game;
    final profile = ref.read(playerProfileProvider).value;
    final balance =
        game?.stakedInChips ?? false ? profile?.chips : profile?.money;
    if (!_offlineMode &&
        game != null &&
        game.matchType == 'random' &&
        game.stakePerPlayer > 0 &&
        balance != null &&
        balance < game.stakePerPlayer) {
      state = state.copyWith(fundsPrompt: game.stakePerPlayer);
      return;
    }
    _send('rematch');
  }

  void clearFundsPrompt() {
    if (state.fundsPrompt != null) state = state.copyWith(fundsPrompt: null);
  }

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
    _lastInboundAt = DateTime.now();
    final message = jsonDecode(raw) as Map<String, dynamic>;
    switch (message['type']) {
      case 'pong':
        break;
      case 'connected':
        _reconnectAttempt = 0;
        _connectStartedAt = null;
        state = state.copyWith(
          connection: ConnectionStatus.connected,
          clientId: message['clientId'] as String?,
          message: null,
        );
        if (_identityPayload.isNotEmpty) {
          _send('identity', _identityPayload);
        }
        break;
      case 'snapshot':
        final snapshot = GameSnapshot.fromJson(message);
        final currentVersion = state.game?.version ?? -1;
        final previousStatus = state.game?.status;
        final wasBlocked = state.game?.rematchBlocked?.youCantAfford ?? false;
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
          final blocked = snapshot.rematchBlocked;
          if (!wasBlocked && (blocked?.youCantAfford ?? false)) {
            state = state.copyWith(fundsPrompt: blocked!.required);
          }
          final stakedMoney = snapshot.you.money;
          final stakedChips = snapshot.you.chips;
          final profile = ref.read(playerProfileProvider).value;
          if ((stakedMoney != null && profile?.money != stakedMoney) ||
              (stakedChips != null && profile?.chips != stakedChips)) {
            ref
                .read(playerProfileProvider.notifier)
                .updateBalances(money: stakedMoney, chips: stakedChips)
                .ignore();
          }
          if (previousStatus != GameStatus.playing &&
              snapshot.status == GameStatus.playing) {
            unawaited(
              ref
                  .read(analyticsServiceProvider)
                  .matchStart(online: !_offlineMode, mode: snapshot.matchType),
            );
          }
          if (snapshot.status == GameStatus.ended) {
            _syncBalancesFromSnapshot(snapshot);
            final won = snapshot.result?.winnerIndex == 0;
            unawaited(
              ref
                  .read(analyticsServiceProvider)
                  .matchEnd(
                    online: !_offlineMode,
                    won: won,
                    mode: snapshot.matchType,
                  ),
            );
          }
        }
        break;
      case 'leftRoom':
        _cancelReconnect();
        state = state.copyWith(
          game: null,
          message: null,
          searchingMatch: false,
          peekSelecting: false,
          queenMode: QueenMode.none,
          replaceFirstSide: null,
          replaceFirstIndex: null,
          sentInvitePlayerIds: const {},
        );
        ref.read(playerProfileProvider.notifier).refreshInventory().ignore();
        break;
      case 'leftQueue':
        state = state.copyWith(searchingMatch: false, message: null);
        break;
      case 'tableInviteReceived':
        final roomId = message['roomId'] as String? ?? '';
        final inviterName = message['inviterName'] as String? ?? 'Friend';
        final inviterPlayerId = message['inviterPlayerId'] as String? ?? '';
        if (roomId.isNotEmpty &&
            (state.game == null || state.game!.status == GameStatus.ended)) {
          state = state.copyWith(
            incomingInvite: TableInviteNotification(
              roomId: roomId,
              inviterName: inviterName,
              inviterPlayerId: inviterPlayerId,
            ),
          );
        }
        break;
      case 'tableInviteSent':
        final targetPlayerId = message['targetPlayerId'] as String?;
        if (targetPlayerId != null && targetPlayerId.isNotEmpty) {
          state = state.copyWith(
            sentInvitePlayerIds: {...state.sentInvitePlayerIds, targetPlayerId},
          );
        }
        break;
      case 'friendRequestReceived':
        final fromPlayerId = message['fromPlayerId'] as String? ?? '';
        final fromName = message['fromName'] as String? ?? 'Player';
        if (fromPlayerId.isNotEmpty) {
          state = state.copyWith(
            friendAlert: FriendAlertNotification(
              kind: 'request',
              playerId: fromPlayerId,
              playerName: fromName,
              requestId: message['requestId'] as String?,
            ),
          );
          unawaited(
            ref.read(friendsDataProvider.notifier).refresh(silent: true),
          );
        }
        break;
      case 'friendRequestAccepted':
        final byPlayerId = message['byPlayerId'] as String? ?? '';
        final byName = message['byName'] as String? ?? 'Player';
        if (byPlayerId.isNotEmpty) {
          state = state.copyWith(
            friendAlert: FriendAlertNotification(
              kind: 'accepted',
              playerId: byPlayerId,
              playerName: byName,
            ),
          );
          unawaited(
            ref.read(friendsDataProvider.notifier).refresh(silent: true),
          );
        }
        break;
      case 'error':
        final code = message['code'] as String?;
        final required = (message['required'] as num?)?.toInt();
        if (code == 'insufficient_funds' && required != null) {
          state = state.copyWith(fundsPrompt: required);
          ref.read(playerProfileProvider.notifier).refreshInventory().ignore();
          break;
        }
        state = state.copyWith(
          message: (code != null && code.isNotEmpty) ? code : 'command_failed',
        );
        break;
    }
  }

  void _syncBalancesFromSnapshot(GameSnapshot snapshot) {
    final youId = snapshot.you.playerId;
    final ratings = snapshot.result?.ratings;
    if (youId != null && ratings != null) {
      for (final rating in ratings) {
        if (rating.playerId == youId && rating.moneyAfter != null) {
          ref
              .read(playerProfileProvider.notifier)
              .updateBalances(
                money: rating.moneyAfter!,
                chips: rating.chipsAfter,
              )
              .ignore();
          break;
        }
      }
    }
    ref.read(playerProfileProvider.notifier).refreshInventory().ignore();
  }

  void _send(String type, [Map<String, dynamic> payload = const {}]) {
    if (!_offlineMode && state.connection != ConnectionStatus.connected) {
      state = state.copyWith(message: 'server_not_connected');
      return;
    }
    if (_socket == null) {
      state = state.copyWith(message: 'server_not_connected');
      return;
    }
    _socket!.send(jsonEncode({'type': type, ...payload}));
  }

  void _disposeSocket({bool cancelReconnect = true}) {
    if (cancelReconnect) _cancelReconnect();
    _subscription?.cancel();
    _subscription = null;
    _socket?.close();
    _socket = null;
  }
}
