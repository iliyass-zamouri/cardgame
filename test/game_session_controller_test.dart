import 'dart:convert';

import 'package:cardgame/app/game_session_controller.dart';
import 'package:cardgame/app/game_session_state.dart';
import 'package:cardgame/domain/models/game_snapshot.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_game_socket.dart';

void main() {
  test('parses authoritative snapshot into immutable state', () async {
    final socket = FakeGameSocket();
    final container = ProviderContainer(
      overrides: [
        gameSocketFactoryProvider.overrideWithValue(() => socket),
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
  });

  test('sends commands without mutating game state locally', () async {
    final socket = FakeGameSocket();
    final container = ProviderContainer(
      overrides: [
        gameSocketFactoryProvider.overrideWithValue(() => socket),
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
    expect(jsonDecode(socket.sent.last), {
      'type': 'tapCard',
      'cardIndex': 0,
    });
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
      'launch': 'ended',
      'total': 0,
      'cards': [
        {'index': 0, 'tag': 'B3', 'visible': true},
      ],
      'handCard': null,
      'hasHandCard': false,
    },
    'opponent': {
      'connected': true,
      'launch': 'ended',
      'total': 0,
      'cards': [
        {'index': 0, 'tag': null, 'visible': false},
      ],
      'handCard': null,
      'hasHandCard': false,
    },
    'result': null,
  };
}
