import 'package:cardgame/app/auth_providers.dart';
import 'package:cardgame/app/game_session_controller.dart';
import 'package:cardgame/app/locale_provider.dart';
import 'package:cardgame/app/locale_repository.dart';
import 'package:cardgame/app/player_profile_repository.dart';
import 'package:cardgame/app/push_providers.dart';
import 'package:cardgame/app/ranking_providers.dart';
import 'package:cardgame/app/session_auth_repository.dart';
import 'package:cardgame/app/session_auth_status.dart';
import 'package:cardgame/data/auth/guest_google_link.dart';
import 'package:cardgame/data/ranking/ranking_api.dart';
import 'package:cardgame/l10n/app_localizations.dart';
import 'package:cardgame/services/guest_link_prefs_repository.dart';
import 'package:cardgame/services/push_prefs_repository.dart';
import 'package:cardgame/ui/screens/home/game_starter.dart';
import 'package:cardgame/ui/screens/profile/player_profile_screen.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'fake_game_socket.dart';

void main() {
  testWidgets('TopBar renders @username and opens ProfileScreen on tap', (
    tester,
  ) async {
    final socket = FakeGameSocket();
    const profile = PlayerProfile(
      playerId: 'guest-test',
      name: 'Test Ace',
      username: 'test_ace',
      authType: 'guest',
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
          localeRepositoryProvider.overrideWithValue(
            LocaleRepository.memory('en'),
          ),
          pushPrefsRepositoryProvider.overrideWithValue(
            PushPrefsRepository.memory(pushSoftPromptDone: true),
          ),
          guestLinkPrefsRepositoryProvider.overrideWithValue(
            GuestLinkPrefsRepository.memory(dontAskAgain: true),
          ),
          rankingApiProvider.overrideWithValue(
            RankingApi(
              baseUrl: 'http://localhost',
              client: MockClient(
                (_) async => http.Response('{"matches":[]}', 200),
              ),
            ),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildCasinoTheme(),
          home: const StartGameWidget(),
        ),
      ),
    );

    // The home hero idles forever, so pump past animations instead of
    // waiting to settle.
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Test Ace'), findsOneWidget);
    expect(find.text('@test_ace'), findsOneWidget);

    // Tap topbar profile area
    await tester.tap(find.text('@test_ace'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(PlayerProfileScreen), findsOneWidget);
  });
}
