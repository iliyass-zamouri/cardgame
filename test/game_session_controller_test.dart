import 'dart:convert';

import 'package:cardgame/app/auth_providers.dart';
import 'package:cardgame/app/game_session_controller.dart';
import 'package:cardgame/app/game_session_state.dart';
import 'package:cardgame/app/player_profile_repository.dart';
import 'package:cardgame/app/ranking_providers.dart';
import 'package:cardgame/app/session_auth_repository.dart';
import 'package:cardgame/app/session_auth_status.dart';
import 'package:cardgame/data/ranking/ranking_api.dart';
import 'package:cardgame/domain/models/game_snapshot.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'fake_game_socket.dart';

List<dynamic> _authOverrides() => [
  sessionAuthRepositoryProvider.overrideWithValue(
    SessionAuthRepository.memory(SessionAuthStatus.guest),
  ),
  playerProfileRepositoryProvider.overrideWithValue(
    PlayerProfileRepository.memory(
      const PlayerProfile(
        playerId: 'guest-test',
        name: 'Test Ace',
        username: 'test_ace',
      ),
    ),
  ),
];

void main() {
  test(
    'reconnects automatically when the socket drops outside a game',
    () async {
      final sockets = <FakeGameSocket>[];
      final container = ProviderContainer(
        overrides: [
          gameSocketFactoryProvider.overrideWithValue(() {
            final socket = FakeGameSocket();
            sockets.add(socket);
            return socket;
          }),
          ..._authOverrides(),
        ],
      );
      addTearDown(container.dispose);
      container.read(gameSessionProvider);
      await Future<void>.delayed(Duration.zero);
      sockets.single.emit({'type': 'connected', 'clientId': 'client-1'});
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(gameSessionProvider).connection,
        ConnectionStatus.connected,
      );

      sockets.single.close();
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(gameSessionProvider).connection,
        ConnectionStatus.disconnected,
      );

      // First backoff step is 1s; no user action needed.
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      expect(sockets.length, 2);
      expect(
        container.read(gameSessionProvider).connection,
        ConnectionStatus.connecting,
      );
    },
  );

  test('parses authoritative snapshot into immutable state', () async {
    final socket = FakeGameSocket();
    final container = ProviderContainer(
      overrides: [
        gameSocketFactoryProvider.overrideWithValue(() => socket),
        ..._authOverrides(),
      ],
    );
    addTearDown(container.dispose);
    container.read(gameSessionProvider);
    await Future<void>.delayed(Duration.zero);

    socket.emit({
      'type': 'connected',
      'protocolVersion': 1,
      'clientId': 'client-1',
    });
    socket.emit(_snapshot());
    await Future<void>.delayed(Duration.zero);

    final state = container.read(gameSessionProvider);
    expect(state.connection, ConnectionStatus.connected);
    expect(state.game?.roomId, 'ABC123');
    expect(state.game?.status, GameStatus.playing);
    expect(state.game?.you.cards.single.visible, isTrue);
    expect(state.game?.opponent?.cards.single.visible, isFalse);
    expect(state.game?.you.displayName, 'Lucky Ace');
  });

  test('sends commands without mutating game state locally', () async {
    final socket = FakeGameSocket();
    final container = ProviderContainer(
      overrides: [
        gameSocketFactoryProvider.overrideWithValue(() => socket),
        ..._authOverrides(),
      ],
    );
    addTearDown(container.dispose);
    container.read(gameSessionProvider);
    await Future<void>.delayed(Duration.zero);
    socket.emit({
      'type': 'connected',
      'protocolVersion': 1,
      'clientId': 'client-1',
    });
    socket.emit(_snapshot());
    await Future<void>.delayed(Duration.zero);

    final before = container.read(gameSessionProvider).game;
    container.read(gameSessionProvider.notifier).tapCard(0);

    expect(container.read(gameSessionProvider).game, same(before));
    expect(jsonDecode(socket.sent.last), {'type': 'tapCard', 'cardIndex': 0});
  });

  test('createRoom includes player identity', () async {
    final socket = FakeGameSocket();
    final container = ProviderContainer(
      overrides: [
        gameSocketFactoryProvider.overrideWithValue(() => socket),
        ..._authOverrides(),
      ],
    );
    addTearDown(container.dispose);
    container.read(gameSessionProvider);
    await Future<void>.delayed(Duration.zero);
    socket.emit({
      'type': 'connected',
      'protocolVersion': 1,
      'clientId': 'client-1',
    });
    await Future<void>.delayed(Duration.zero);

    container.read(gameSessionProvider.notifier).createRoom();
    expect(jsonDecode(socket.sent.last), {
      'type': 'createRoom',
      'playerId': 'guest-test',
      'displayName': 'Test Ace',
      'avatarId': 'default',
      'deckId': 'default',
    });
  });

  test(
    'syncs player balances when ended snapshot includes rating with balances',
    () async {
      final socket = FakeGameSocket();
      final profileRepo = PlayerProfileRepository.memory(
        const PlayerProfile(
          playerId: 'guest-1',
          name: 'Lucky Ace',
          username: 'lucky_ace',
          money: 100,
          chips: 5,
        ),
      );
      final container = ProviderContainer(
        overrides: [
          gameSocketFactoryProvider.overrideWithValue(() => socket),
          sessionAuthRepositoryProvider.overrideWithValue(
            SessionAuthRepository.memory(SessionAuthStatus.guest),
          ),
          playerProfileRepositoryProvider.overrideWithValue(profileRepo),
        ],
      );
      addTearDown(container.dispose);
      container.read(gameSessionProvider);
      await Future<void>.delayed(Duration.zero);
      await container.read(playerProfileProvider.future);

      socket.emit({
        'type': 'connected',
        'protocolVersion': 1,
        'clientId': 'client-1',
      });
      socket.emit({
        ..._snapshot(),
        'status': 'ended',
        'result': {
          'scores': [5, 8],
          'winnerIndex': 0,
          'ratings': [
            {
              'playerId': 'guest-1',
              'result': 'win',
              'pointsEarned': 30,
              'eloDelta': 16,
              'moneyAfter': 150,
              'chipsAfter': 5,
            },
            {
              'playerId': 'guest-2',
              'result': 'loss',
              'pointsEarned': 2,
              'eloDelta': -16,
              'moneyAfter': 50,
              'chipsAfter': 1,
            },
          ],
        },
      });
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final updatedProfile = container.read(playerProfileProvider).value;
      expect(updatedProfile?.money, 150);
      expect(updatedProfile?.chips, 5);
    },
  );

  test('handles tableInvite sending and receiving', () async {
    final socket = FakeGameSocket();
    final container = ProviderContainer(
      overrides: [
        gameSocketFactoryProvider.overrideWithValue(() => socket),
        ..._authOverrides(),
      ],
    );
    addTearDown(container.dispose);
    final notifier = container.read(gameSessionProvider.notifier);
    await Future<void>.delayed(Duration.zero);
    socket.emit({
      'type': 'connected',
      'protocolVersion': 1,
      'clientId': 'client-1',
    });
    await Future<void>.delayed(Duration.zero);

    notifier.sendTableInvite(targetPlayerId: 'p2-friend', roomId: 'XYZ789');
    expect(
      container.read(gameSessionProvider).sentInvitePlayerIds,
      contains('p2-friend'),
    );
    expect(jsonDecode(socket.sent.last), {
      'type': 'tableInvite',
      'targetPlayerId': 'p2-friend',
      'roomId': 'XYZ789',
    });

    socket.emit({
      'type': 'tableInviteReceived',
      'roomId': 'TBL999',
      'inviterName': 'QueenPlayer',
      'inviterPlayerId': 'host-001',
    });
    await Future<void>.delayed(Duration.zero);

    final incoming = container.read(gameSessionProvider).incomingInvite;
    expect(incoming?.roomId, 'TBL999');
    expect(incoming?.inviterName, 'QueenPlayer');
    expect(incoming?.inviterPlayerId, 'host-001');

    notifier.dismissIncomingInvite();
    expect(container.read(gameSessionProvider).incomingInvite, isNull);
  });

  test(
    'handles friendRequestReceived and friendRequestAccepted alerts',
    () async {
      final socket = FakeGameSocket();
      final container = ProviderContainer(
        overrides: [
          gameSocketFactoryProvider.overrideWithValue(() => socket),
          ..._authOverrides(),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(gameSessionProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      socket.emit({
        'type': 'connected',
        'protocolVersion': 1,
        'clientId': 'client-1',
      });
      await Future<void>.delayed(Duration.zero);

      socket.emit({
        'type': 'friendRequestReceived',
        'requestId': 'friendship-1',
        'fromPlayerId': 'sender-9',
        'fromName': 'ShadowAce',
        'fromUsername': 'shadow_ace',
      });
      await Future<void>.delayed(Duration.zero);

      final requestAlert = container.read(gameSessionProvider).friendAlert;
      expect(requestAlert?.kind, 'request');
      expect(requestAlert?.playerId, 'sender-9');
      expect(requestAlert?.playerName, 'ShadowAce');
      expect(requestAlert?.requestId, 'friendship-1');

      notifier.clearFriendAlert();
      expect(container.read(gameSessionProvider).friendAlert, isNull);

      socket.emit({
        'type': 'friendRequestAccepted',
        'friendshipId': 'friendship-2',
        'byPlayerId': 'accepter-3',
        'byName': 'QueenBee',
      });
      await Future<void>.delayed(Duration.zero);

      final acceptedAlert = container.read(gameSessionProvider).friendAlert;
      expect(acceptedAlert?.kind, 'accepted');
      expect(acceptedAlert?.playerId, 'accepter-3');
      expect(acceptedAlert?.playerName, 'QueenBee');
    },
  );

  test('balance updates do not refetch ranks', () async {
    final ranking = _CountingRankingApi();
    final container = ProviderContainer(
      overrides: [
        ..._authOverrides(),
        rankingApiProvider.overrideWithValue(ranking.api),
      ],
    );
    addTearDown(container.dispose);
    container.listen(myRankProvider, (_, _) {});
    await container.read(playerProfileProvider.future);
    await container.read(myRankProvider.future);
    expect(ranking.rankFetches, 1);

    // A stake or payout changes the profile but not who is asking.
    await container
        .read(playerProfileProvider.notifier)
        .updateBalances(money: 999, chips: 7);
    await container.read(myRankProvider.future);
    expect(ranking.rankFetches, 1);
  });

  test('a finished online match refreshes ranks once', () async {
    final socket = FakeGameSocket();
    final ranking = _CountingRankingApi();
    final container = ProviderContainer(
      overrides: [
        gameSocketFactoryProvider.overrideWithValue(() => socket),
        ..._authOverrides(),
        rankingApiProvider.overrideWithValue(ranking.api),
      ],
    );
    addTearDown(container.dispose);
    container.listen(myRankProvider, (_, _) {});
    container.read(gameSessionProvider);
    await container.read(playerProfileProvider.future);
    await container.read(myRankProvider.future);
    expect(ranking.rankFetches, 1);

    socket.emit({
      'type': 'connected',
      'protocolVersion': 1,
      'clientId': 'client-1',
    });
    socket.emit(_snapshot());
    const result = {
      'scores': [5, 8],
      'winnerIndex': 0,
    };
    // Later snapshots of the same finished match must not refetch again.
    socket.emit({
      ..._snapshot(),
      'version': 3,
      'status': 'ended',
      'result': result,
    });
    socket.emit({
      ..._snapshot(),
      'version': 4,
      'status': 'ended',
      'result': result,
    });
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await container.read(myRankProvider.future);
    expect(ranking.rankFetches, 2);
  });
}

Map<String, dynamic> _snapshot() {
  return {
    'type': 'snapshot',
    'roomId': 'ABC123',
    'version': 2,
    'status': 'playing',
    'ready': true,
    'deckCount': 45,
    'discardTop': 'A2',
    'turn': 'you',
    'you': {
      'connected': true,
      'displayName': 'Lucky Ace',
      'playerId': 'guest-1',
      'launch': 'ended',
      'total': 5,
      'cards': [
        {'index': 0, 'tag': 'A1', 'visible': true},
      ],
      'handCard': null,
      'hasHandCard': false,
    },
    'opponent': {
      'connected': true,
      'displayName': 'Sharp King',
      'playerId': 'guest-2',
      'launch': 'ended',
      'total': 8,
      'cards': [
        {'index': 0, 'tag': null, 'visible': false},
      ],
      'handCard': null,
      'hasHandCard': false,
    },
    'result': null,
    'lastAction': null,
  };
}

/// Ranking API that answers every call and counts player-rank fetches.
class _CountingRankingApi {
  int rankFetches = 0;

  late final RankingApi api = RankingApi(
    baseUrl: 'http://localhost',
    client: MockClient((request) async {
      if (request.url.path == '/ranking/player') rankFetches++;
      return http.Response(
        jsonEncode({'playerId': 'guest-test', 'rank': 3, 'elo': 1200}),
        200,
      );
    }),
  );
}
