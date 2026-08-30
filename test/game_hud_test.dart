import 'package:cardgame/app/auth_providers.dart';
import 'package:cardgame/app/game_session_controller.dart';
import 'package:cardgame/app/player_profile_repository.dart';
import 'package:cardgame/app/session_auth_repository.dart';
import 'package:cardgame/app/session_auth_status.dart';
import 'package:cardgame/l10n/app_localizations.dart';
import 'package:cardgame/ui/screens/home/home_screen.dart';
import 'package:cardgame/ui/theme/casino_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_game_socket.dart';

void main() {
  testWidgets(
    'GameHud renders opponent above deck and current player below deck',
    (tester) async {
      final socket = FakeGameSocket();
      const profile = PlayerProfile(
        playerId: 'guest-1',
        name: 'Alice',
        username: 'alice_ace',
        avatarId: 'golden-king',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gameSocketFactoryProvider.overrideWithValue(() => socket),
            sessionAuthRepositoryProvider.overrideWithValue(
              SessionAuthRepository.memory(SessionAuthStatus.guest),
            ),
            playerProfileRepositoryProvider.overrideWithValue(
              PlayerProfileRepository.memory(profile),
            ),
          ],
          child: const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Scaffold(body: GameHud()),
          ),
        ),
      );

      socket.emit({
        'type': 'connected',
        'protocolVersion': 1,
        'clientId': 'guest-1',
      });

      socket.emit({
        'type': 'snapshot',
        'roomId': 'room-1',
        'version': 1,
        'status': 'playing',
        'ready': true,
        'deckCount': 30,
        'discardTop': 'A2',
        'turn': 'you',
        'potAmount': 100,
        'stakePool': 100,
        'stakePerPlayer': 50,
        'you': {
          'connected': true,
          'displayName': 'Alice',
          'playerId': 'guest-1',
          'launch': 'ended',
          'total': 0,
          'cards': [],
          'handCard': null,
          'hasHandCard': false,
        },
        'opponent': {
          'connected': true,
          'displayName': 'Bob',
          'playerId': 'guest-2',
          'launch': 'ended',
          'total': 0,
          'cards': [],
          'handCard': null,
          'hasHandCard': false,
        },
      });

      await tester.pumpAndSettle();

      // Verify pot is rendered
      expect(find.text('Pot: 100'), findsOneWidget);

      // Verify both player pills are rendered
      final playerPills = find.byType(CasinoPlayerPill);
      expect(playerPills, findsNWidgets(2));

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);

      // Verify Bob (opponent) is below his cards to the right
      // and Alice (current player) is above her cards to the left
      final bobPosition = tester.getTopLeft(find.text('Bob'));
      final alicePosition = tester.getTopLeft(find.text('Alice'));
      expect(bobPosition.dy < alicePosition.dy, isTrue);
      expect(bobPosition.dx > alicePosition.dx, isTrue);
    },
  );
}
