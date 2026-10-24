import 'package:cardgame/app/auth_providers.dart';
import 'package:cardgame/app/game_session_controller.dart';
import 'package:cardgame/app/game_session_state.dart';
import 'package:cardgame/app/player_profile_repository.dart';
import 'package:cardgame/app/session_auth_repository.dart';
import 'package:cardgame/app/session_auth_status.dart';
import 'package:cardgame/data/avatars/avatar_catalog.dart';
import 'package:cardgame/domain/models/game_snapshot.dart';
import 'package:cardgame/l10n/app_localizations.dart';
import 'package:cardgame/ui/screens/home/stake_selector_modal.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/theme/city_theme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Connected extends GameSessionController {
  @override
  GameSessionState build() =>
      const GameSessionState(connection: ConnectionStatus.connected);
}

Future<void> _pumpSelector(
  WidgetTester tester,
  Size size, {
  String locale = 'en',
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        gameSessionProvider.overrideWith(_Connected.new),
        sessionAuthRepositoryProvider.overrideWithValue(
          SessionAuthRepository.memory(SessionAuthStatus.guest),
        ),
        playerProfileRepositoryProvider.overrideWithValue(
          PlayerProfileRepository.memory(
            const PlayerProfile(
              playerId: 'guest-1',
              name: 'Ace',
              username: 'ace',
              avatarId: 'golden-king',
              money: 800,
              chips: 2,
            ),
          ),
        ),
      ],
      child: MaterialApp(
        theme: buildCasinoTheme(locale: Locale(locale)),
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const StakeSelectorScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _font(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final file in files) {
    loader.addFont(rootBundle.load('assets/fonts/$file'));
  }
  await loader.load();
}

/// The pot the play panel would start a match at.
String _selectedPot(WidgetTester tester) {
  final panel = tester.widget(
    find.byWidgetPredicate((w) => w.runtimeType.toString() == '_ActionPanel'),
  );
  return ((panel as dynamic).option as PotOption).id;
}

void main() {
  group('StakeSelectorScreen Configuration', () {
    test('pot options match ordered city banners and pools', () {
      final options = StakeSelectorScreen.potOptions;
      expect(options.length, 8);

      expect(options[0].id, 'london');
      expect(options[0].assetPath, 'assets/pots/london.webp');
      expect(options[0].pool, 20);
      expect(options[0].entryStake, 10);

      expect(options[1].id, 'paris');
      expect(options[1].assetPath, 'assets/pots/paris.webp');
      expect(options[1].pool, 50);
      expect(options[1].entryStake, 25);

      expect(options[2].id, 'moscow');
      expect(options[2].assetPath, 'assets/pots/moscow.webp');
      expect(options[2].pool, 100);
      expect(options[2].entryStake, 50);

      expect(options[3].id, 'cairo');
      expect(options[3].assetPath, 'assets/pots/cairo.webp');
      expect(options[3].pool, 200);
      expect(options[3].entryStake, 100);

      expect(options[4].id, 'marrakech');
      expect(options[4].assetPath, 'assets/pots/marrakech.webp');
      expect(options[4].pool, 500);
      expect(options[4].entryStake, 250);

      expect(options[5].id, 'toronto');
      expect(options[5].assetPath, 'assets/pots/toronto.webp');
      expect(options[5].currency, CurrencyType.chips);
      expect(options[5].entryStake, 1);

      expect(options[6].id, 'new_york');
      expect(options[6].assetPath, 'assets/pots/new_york.webp');
      expect(options[6].currency, CurrencyType.chips);
      expect(options[6].entryStake, 5);

      expect(options[7].id, 'tokyo');
      expect(options[7].assetPath, 'assets/pots/tokyo.webp');
      expect(options[7].currency, CurrencyType.chips);
      expect(options[7].entryStake, 25);

      for (final option in options.take(5)) {
        expect(option.currency, CurrencyType.money);
      }
    });

    test('chip pots are afforded from chips, money pots from money', () {
      final london = StakeSelectorScreen.potOptions[0];
      final tokyo = StakeSelectorScreen.potOptions[7];
      expect(london.canAfford(money: 10, chips: 0), isTrue);
      expect(london.canAfford(money: 9, chips: 99), isFalse);
      expect(tokyo.canAfford(money: 999999, chips: 24), isFalse);
      expect(tokyo.canAfford(money: 0, chips: 25), isTrue);
    });

    test('city theme follows the stake currency', () {
      expect(CityTheme.forStake(50)?.id, 'paris');
      expect(CityTheme.forStake(50, chips: true)?.id, 'tokyo');
      expect(CityTheme.forStake(2, chips: true)?.id, 'toronto');
      expect(CityTheme.forStake(10, chips: true)?.id, 'new_york');
      final chipGame = GameSnapshot.fromJson({
        'roomId': 'R',
        'version': 1,
        'stakePool': 10,
        'stakeCurrency': 'chips',
        'you': <String, dynamic>{},
      });
      expect(chipGame.stakedInChips, isTrue);
      expect(CityTheme.forGame(chipGame)?.id, 'new_york');
    });

    test('stakePools backward compatibility list matches pools', () {
      expect(StakeSelectorScreen.stakePools, [20, 50, 100, 200, 500]);
    });

    testWidgets('pot options resolve localized city names', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              final names =
                  StakeSelectorScreen.potOptions
                      .map((o) => o.nameBuilder(l10n))
                      .toList();
              return Column(children: names.map(Text.new).toList());
            },
          ),
        ),
      );

      expect(find.text('London'), findsOneWidget);
      expect(find.text('Paris'), findsOneWidget);
      expect(find.text('Moscow'), findsOneWidget);
      expect(find.text('Cairo'), findsOneWidget);
      expect(find.text('Marrakech'), findsOneWidget);
      expect(find.text('Toronto'), findsOneWidget);
      expect(find.text('New York'), findsOneWidget);
      expect(find.text('Tokyo'), findsOneWidget);
    });
  });

  group('StakeSelectorScreen on a wide window', () {
    // Real fonts, so overflow checks measure what players see.
    setUpAll(() async {
      await _font('DM Sans', ['DMSans-Regular.ttf', 'DMSans-Bold.ttf']);
      await _font('Cinzel', ['Cinzel-Regular.ttf', 'Cinzel-Bold.ttf']);
    });

    testWidgets('fans the pots and steps through them with the keyboard', (
      tester,
    ) async {
      await _pumpSelector(tester, const Size(1280, 800));

      expect(tester.takeException(), isNull);
      expect(find.byType(PageView), findsNothing);
      expect(_selectedPot(tester), 'london');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(_selectedPot(tester), 'moscow');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(_selectedPot(tester), 'paris');
    });

    testWidgets('arrow keys follow the reading direction in RTL', (
      tester,
    ) async {
      await _pumpSelector(tester, const Size(1280, 800), locale: 'ar');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();

      expect(_selectedPot(tester), 'paris');
    });

    testWidgets('a wheel notch or a click on a side card selects it', (
      tester,
    ) async {
      await _pumpSelector(tester, const Size(1280, 800));
      final mouse = TestPointer(1, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(mouse.hover(const Offset(640, 380)));
      await tester.sendEventToBinding(mouse.scroll(const Offset(0, 100)));
      await tester.pumpAndSettle();
      expect(_selectedPot(tester), 'paris');

      final semantics = tester.ensureSemantics();
      await tester.tap(find.bySemanticsLabel(RegExp(r'^Moscow 100')));
      await tester.pumpAndSettle();
      semantics.dispose();
      expect(_selectedPot(tester), 'moscow');
    });

    for (final size in const [Size(900, 560), Size(1920, 1080)]) {
      testWidgets('fits a ${size.width}x${size.height} window', (tester) async {
        await _pumpSelector(tester, size);

        // Layout overflows surface as exceptions in widget tests.
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('StakeSelectorScreen on a phone', () {
    setUpAll(() async {
      await _font('DM Sans', ['DMSans-Regular.ttf', 'DMSans-Bold.ttf']);
      await _font('Cinzel', ['Cinzel-Regular.ttf', 'Cinzel-Bold.ttf']);
    });

    for (final size in const [Size(390, 844), Size(360, 640)]) {
      testWidgets('keeps the swipe carousel at ${size.width}', (tester) async {
        await _pumpSelector(tester, size);

        expect(tester.takeException(), isNull);
        expect(find.byType(PageView), findsOneWidget);
      });
    }
  });
}
