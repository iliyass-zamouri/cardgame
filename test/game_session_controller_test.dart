import 'dart:convert';

import 'package:cardgame/app/auth_providers.dart';
import 'package:cardgame/app/game_session_controller.dart';
import 'package:cardgame/app/game_session_state.dart';
import 'package:cardgame/app/player_profile_repository.dart';
import 'package:cardgame/app/session_auth_repository.dart';
import 'package:cardgame/app/session_auth_status.dart';
import 'package:cardgame/domain/models/game_snapshot.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
