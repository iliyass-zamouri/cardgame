import 'package:cardgame/app/auth_providers.dart';
import 'package:cardgame/app/game_session_controller.dart';
import 'package:cardgame/app/game_session_state.dart';
import 'package:cardgame/app/player_profile_repository.dart';
import 'package:cardgame/app/push_providers.dart';
import 'package:cardgame/app/session_auth_repository.dart';
import 'package:cardgame/app/session_auth_status.dart';
import 'package:cardgame/l10n/app_localizations.dart';
import 'package:cardgame/services/push_prefs_repository.dart';
import 'package:cardgame/ui/screens/home/game_starter.dart';
import 'package:cardgame/ui/screens/home/home_menu_widgets.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Fixed extends GameSessionController {
  _Fixed(this._s);
  final GameSessionState _s;
  @override
  GameSessionState build() => _s;
}

Future<void> _font(String family, List<String> files) async {
  final l = FontLoader(family);
  for (final f in files) {
    l.addFont(rootBundle.load('assets/fonts/$f'));
  }
  await l.load();
}

void main() {
  setUpAll(() async {
    await _font('DM Sans', ['DMSans-Regular.ttf', 'DMSans-Bold.ttf']);
    await _font('Cinzel', ['Cinzel-Regular.ttf', 'Cinzel-Bold.ttf']);
    await _font('Cairo', ['Cairo-Regular.ttf', 'Cairo-Bold.ttf']);
  });

  for (final (name, locale, conn, size) in [
    ('en', 'en', ConnectionStatus.connected, const Size(390, 844)),
    ('ar', 'ar', ConnectionStatus.connected, const Size(390, 844)),
    (
      'small_offline',
      'fr',
      ConnectionStatus.disconnected,
      const Size(360, 640),
    ),
  ]) {
    testWidgets('home layout fits: $name', (tester) async {
      tester.view.physicalSize = size * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      const profile = PlayerProfile(
        playerId: 'guest-1',
        name: 'Iliyass',
        username: 'iliyass_ace',
        avatarId: 'golden-king',
        money: 12500,
        chips: 340,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gameSessionProvider.overrideWith(
              () => _Fixed(GameSessionState(connection: conn)),
            ),
            sessionAuthRepositoryProvider.overrideWithValue(
              SessionAuthRepository.memory(SessionAuthStatus.google),
            ),
            playerProfileRepositoryProvider.overrideWithValue(
              PlayerProfileRepository.memory(profile),
            ),
            notificationsUnreadCountProvider.overrideWithValue(3),
            pushPrefsRepositoryProvider.overrideWithValue(
              PushPrefsRepository.memory(),
            ),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildCasinoTheme(locale: Locale(locale)),
            locale: Locale(locale),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const StartGameWidget(),
          ),
        ),
      );
      await tester.runAsync(() async {
        for (final e in find.byType(Image).evaluate()) {
          await precacheImage((e.widget as Image).image, e);
        }
      });
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 1));

      // Layout overflows surface as exceptions in widget tests.
      expect(tester.takeException(), isNull);
      expect(find.byType(PrimaryPlayCard), findsOneWidget);
      expect(find.byType(ModePlayingCard), findsNWidgets(3));
      expect(find.byType(TableRailDock), findsOneWidget);
    });
  }
}
