import 'dart:convert';
import 'dart:io';

import 'package:cardgame/app/auth_providers.dart';
import 'package:cardgame/app/daily_reward_providers.dart';
import 'package:cardgame/app/game_session_controller.dart';
import 'package:cardgame/app/game_session_state.dart';
import 'package:cardgame/app/home_menu_providers.dart';
import 'package:cardgame/app/player_profile_repository.dart';
import 'package:cardgame/app/push_providers.dart';
import 'package:cardgame/app/session_auth_repository.dart';
import 'package:cardgame/app/session_auth_status.dart';
import 'package:cardgame/data/app/app_config_api.dart';
import 'package:cardgame/data/app/home_menu_config.dart';
import 'package:cardgame/data/daily_reward/daily_reward_models.dart';
import 'package:cardgame/l10n/app_localizations.dart';
import 'package:cardgame/services/push_prefs_repository.dart';
import 'package:cardgame/ui/screens/daily_reward/daily_entry_pill.dart';
import 'package:cardgame/ui/screens/home/game_starter.dart';
import 'package:cardgame/ui/screens/home/home_menu_widgets.dart';
import 'package:cardgame/ui/screens/how_to_play_screen.dart';
import 'package:cardgame/ui/screens/marketplace_screen.dart';
import 'package:cardgame/ui/screens/tutorial/tutorial_progress_repository.dart';
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

class _OfflineConfigApi extends AppConfigApi {
  _OfflineConfigApi() : super(baseUrl: '');

  @override
  Future<AppConfig> fetch() async => const AppConfig();
}

/// The streak as the server sent it in [fixture], or switched off.
class _FixedDailyRewards extends DailyRewardController {
  _FixedDailyRewards(this.fixture);

  final String? fixture;

  @override
  Future<DailyRewardView?> build() async {
    final name = fixture;
    if (name == null) return null;
    final json = jsonDecode(
      File('test/fixtures/daily_reward/$name.json').readAsStringSync(),
    );
    return DailyRewardView(
      DailyRewardStatus.fromJson(json as Map<String, dynamic>),
      dailyRewardClock(),
    );
  }
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

  const reduced = HomeMenuConfig(
    modes: [HomeMode.playVsRobot],
    nav: [HomeNavTab.friends, HomeNavTab.home, HomeNavTab.rules],
  );
  const empty = HomeMenuConfig(modes: [], nav: [HomeNavTab.home]);

  for (final (name, locale, conn, size, menu) in [
    (
      'en',
      'en',
      ConnectionStatus.connected,
      const Size(390, 844),
      HomeMenuConfig.fallback,
    ),
    (
      'ar',
      'ar',
      ConnectionStatus.connected,
      const Size(390, 844),
      HomeMenuConfig.fallback,
    ),
    (
      'small_offline',
      'fr',
      ConnectionStatus.disconnected,
      const Size(360, 640),
      HomeMenuConfig.fallback,
    ),
    (
      'reduced',
      'en',
      ConnectionStatus.connected,
      const Size(390, 844),
      reduced,
    ),
    (
      'empty_small',
      'en',
      ConnectionStatus.connected,
      const Size(360, 640),
      empty,
    ),
    // Desktop windows: side rail and the two-pane home.
    (
      'wide',
      'en',
      ConnectionStatus.connected,
      const Size(1280, 800),
      HomeMenuConfig.fallback,
    ),
    (
      'wide_ar',
      'ar',
      ConnectionStatus.connected,
      const Size(1280, 800),
      HomeMenuConfig.fallback,
    ),
    (
      'wide_smallest_offline',
      'fr',
      ConnectionStatus.disconnected,
      const Size(900, 560),
      HomeMenuConfig.fallback,
    ),
    (
      'wide_reduced',
      'en',
      ConnectionStatus.connected,
      const Size(1920, 1080),
      reduced,
    ),
  ]) {
    // With and without the streak banner above the play card.
    for (final daily in [null, 'status_midweek', 'status_claimed']) {
      testWidgets('home layout fits: $name${daily == null ? '' : ' $daily'}', (
        tester,
      ) async {
        await _pumpHome(
          tester,
          locale: locale,
          conn: conn,
          size: size,
          menu: menu,
          daily: daily,
        );

        // Layout overflows surface as exceptions in widget tests.
        expect(tester.takeException(), isNull);
        expect(find.byType(PrimaryPlayCard), findsOneWidget);
        expect(find.byType(ModePlayingCard), findsNWidgets(menu.modes.length));
        final wide = size.width >= 900 && size.height >= 560;
        expect(find.byType(HomeNavBar), wide ? findsNothing : findsOneWidget);
        expect(find.byType(HomeNavRail), wide ? findsOneWidget : findsNothing);
        expect(_navItems(tester), hasLength(menu.nav.length));
        expect(
          find.byType(DailyEntryPill),
          daily == null ? findsNothing : findsOneWidget,
        );
      });
    }
  }

  for (final (locale, size) in [
    ('en', const Size(390, 844)),
    ('ar', const Size(390, 844)),
    ('en', const Size(1280, 800)),
  ]) {
    testWidgets('nav tabs switch in place: $locale ${size.width}', (
      tester,
    ) async {
      await _pumpHome(
        tester,
        locale: locale,
        conn: ConnectionStatus.connected,
        size: size,
        menu: HomeMenuConfig.fallback,
      );
      final fanState = tester.state(find.byType(HeroCardFan));
      String? selectedLabel() =>
          _navItems(tester).singleWhere((item) => item.selected).label;
      final homeLabel = selectedLabel();

      final rules = _navItems(tester).last;
      await tester.tap(find.text(rules.label).last);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(HowToPlayScreen), findsOneWidget);
      expect(_navItems(tester), hasLength(HomeMenuConfig.fallback.nav.length));
      expect(selectedLabel(), rules.label);
      expect(find.byType(BackButton), findsNothing);
      // Home stays mounted but hidden; untouched tabs are never built.
      expect(find.byType(PrimaryPlayCard), findsNothing);
      expect(find.byType(MarketplaceScreen, skipOffstage: false), findsNothing);

      // System back returns to the home tab instead of leaving the app.
      await tester.binding.handlePopRoute();
      // Home's idle fan float resumes, so the tree never settles.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(selectedLabel(), homeLabel);
      expect(find.byType(PrimaryPlayCard), findsOneWidget);
      expect(tester.state(find.byType(HeroCardFan)), same(fanState));
      expect(find.byType(HowToPlayScreen, skipOffstage: false), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('resizing across the wide breakpoint keeps tabs and pages', (
    tester,
  ) async {
    await _pumpHome(
      tester,
      locale: 'en',
      conn: ConnectionStatus.connected,
      size: const Size(390, 844),
      menu: HomeMenuConfig.fallback,
    );
    final rules = _navItems(tester).last;
    await tester.tap(find.text(rules.label).last);
    await tester.pumpAndSettle();
    final page = tester.element(find.byType(HowToPlayScreen));

    tester.view.physicalSize = const Size(1280, 800) * 3;
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(HomeNavRail), findsOneWidget);
    expect(
      _navItems(tester).singleWhere((item) => item.selected).label,
      rules.label,
    );
    // The open page moved into the new layout instead of rebuilding.
    expect(tester.element(find.byType(HowToPlayScreen)), same(page));
  });
}

/// The home tabs, from the bottom bar on a phone or the rail when wide.
List<RailDockItem> _navItems(WidgetTester tester) {
  final rail = find.byType(HomeNavRail);
  if (rail.evaluate().isNotEmpty) {
    return tester.widget<HomeNavRail>(rail).items;
  }
  return tester.widget<HomeNavBar>(find.byType(HomeNavBar)).items;
}

Future<void> _pumpHome(
  WidgetTester tester, {
  required String locale,
  required ConnectionStatus conn,
  required Size size,
  required HomeMenuConfig menu,
  String? daily,
}) async {
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
        homeMenuRepositoryProvider.overrideWithValue(
          HomeMenuRepository.memory(menu),
        ),
        appConfigApiProvider.overrideWithValue(_OfflineConfigApi()),
        tutorialProgressRepositoryProvider.overrideWithValue(
          TutorialProgressRepository.memory(),
        ),
        dailyRewardProvider.overrideWith(() => _FixedDailyRewards(daily)),
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
}
