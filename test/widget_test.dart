import 'package:cardgame/app/auth_providers.dart';
import 'package:cardgame/app/game_session_controller.dart';
import 'package:cardgame/app/player_profile_repository.dart';
import 'package:cardgame/app/session_auth_repository.dart';
import 'package:cardgame/app/session_auth_status.dart';
import 'package:cardgame/ui/screens/home/game_starter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_game_socket.dart';

void main() {
  testWidgets('shows start screen', (WidgetTester tester) async {
    final socket = FakeGameSocket();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gameSocketFactoryProvider.overrideWithValue(() => socket),
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
        ],
        child: const MaterialApp(home: StartGameWidget()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ShadowHand'), findsOneWidget);
    expect(find.text('FIND MATCH'), findsOneWidget);
    expect(find.text('CREATE ROOM'), findsOneWidget);
    expect(find.text('JOIN ROOM'), findsOneWidget);
    expect(find.textContaining('Test Ace'), findsOneWidget);
  });
}
