import 'package:cardgame/app/home_menu_providers.dart';
import 'package:cardgame/app/theme_providers.dart';
import 'package:cardgame/data/app/app_config_api.dart';
import 'package:cardgame/data/app/app_theme_config.dart';
import 'package:cardgame/ui/theme/app_theme.dart';
import 'package:cardgame/ui/theme/casino_palette.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/theme/felt_chrome.dart';
import 'package:cardgame/ui/theme/halloween_ambient.dart';
import 'package:cardgame/ui/theme/theme_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeConfigApi extends AppConfigApi {
  _FakeConfigApi(this.result) : super(baseUrl: '');

  final Future<AppConfig> Function() result;
  int calls = 0;

  @override
  Future<AppConfig> fetch() {
    calls++;
    return result();
  }
}

/// Paints a gold swatch from a const constructor: the case a parent rebuild
/// never refreshes on its own.
class _Swatch extends StatelessWidget {
  const _Swatch();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(color: CasinoColors.gold, child: const SizedBox.expand());
  }
}

void main() {
  setUp(() => AppTheme.activate(AppTheme.casino));
  tearDown(() => AppTheme.activate(AppTheme.casino));

  group('AppThemeConfig', () {
    test('parses a known id, with animated on by default', () {
      final config = AppThemeConfig.tryFromJson({'id': 'halloween'});
      expect(config, const AppThemeConfig(id: AppThemeId.halloween));
      expect(config!.animated, isTrue);
    });

    test('reads the motion kill switch', () {
      final config = AppThemeConfig.tryFromJson({
        'id': 'halloween',
        'animated': false,
      });
      expect(config!.animated, isFalse);
    });

    test('ignores an id this build does not know', () {
      expect(AppThemeConfig.tryFromJson({'id': 'christmas'}), isNull);
      expect(AppThemeConfig.tryFromJson({}), isNull);
    });

    test('round-trips through json', () {
      const config = AppThemeConfig(id: AppThemeId.halloween, animated: false);
      expect(AppThemeConfig.tryFromJson(config.toJson()), config);
    });
  });

  group('AppTheme', () {
    test('of() picks the palette for the id and keeps the animated flag', () {
      final theme = AppTheme.of(AppThemeId.halloween, animated: false);
      expect(theme.palette, CasinoPalette.halloween);
      expect(theme.animated, isFalse);
      expect(AppTheme.of(AppThemeId.casino).palette, CasinoPalette.casino);
    });

    test('equality compares the id and the animated flag', () {
      expect(AppTheme.of(AppThemeId.halloween), AppTheme.halloween);
      expect(
        AppTheme.halloween.copyWith(animated: false),
        isNot(AppTheme.halloween),
      );
    });

    test('CasinoColors follows the activated theme', () {
      expect(CasinoColors.gold, CasinoPalette.casino.gold);
      AppTheme.activate(AppTheme.halloween);
      expect(CasinoColors.gold, CasinoPalette.halloween.gold);
      expect(CasinoColors.feltHi, CasinoPalette.halloween.feltHi);
    });
  });

  group('palette contrast', () {
    for (final entry
        in {
          'casino': CasinoPalette.casino,
          'halloween': CasinoPalette.halloween,
        }.entries) {
      test('${entry.key} keeps text readable', () {
        final p = entry.value;
        for (final surface in [p.bg, p.surface, p.surfaceHi]) {
          expect(_contrast(p.text, surface), greaterThanOrEqualTo(4.5));
        }
        expect(_contrast(p.textMuted, p.surface), greaterThanOrEqualTo(3));
        expect(_contrast(p.bg, p.gold), greaterThanOrEqualTo(4.5));
      });

      test('${entry.key} keeps button labels readable', () {
        final p = entry.value;
        for (final fill in [p.fold, p.check, p.raise]) {
          expect(_contrast(p.text, fill), greaterThanOrEqualTo(3));
        }
      });
    }
  });

  group('ThemeRepository', () {
    test('memory round trip', () async {
      final repo = ThemeRepository.memory();
      expect(repo.read(), isNull);
      await repo.write(const AppThemeConfig(id: AppThemeId.halloween));
      expect(repo.read(), const AppThemeConfig(id: AppThemeId.halloween));
    });
  });

  group('themeProvider', () {
    ProviderContainer container(ThemeRepository repo, AppConfigApi api) {
      final c = ProviderContainer(
        overrides: [
          themeRepositoryProvider.overrideWithValue(repo),
          appConfigApiProvider.overrideWithValue(api),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('starts from the cached theme, then follows the server', () async {
      final repo = ThemeRepository.memory(
        const AppThemeConfig(id: AppThemeId.halloween),
      );
      final api = _FakeConfigApi(
        () async =>
            const AppConfig(theme: AppThemeConfig(id: AppThemeId.casino)),
      );
      final c = container(repo, api);
      final seen = <AppTheme>[];
      c.listen(themeProvider, (_, next) => seen.add(next));

      expect(c.read(themeProvider).id, AppThemeId.halloween);
      expect(AppTheme.active.id, AppThemeId.halloween);
      await pumpEventQueue();
      expect(c.read(themeProvider).id, AppThemeId.casino);
      expect(AppTheme.active.id, AppThemeId.casino);
      expect(seen.map((t) => t.id), [AppThemeId.casino]);
      expect(repo.read(), const AppThemeConfig(id: AppThemeId.casino));
    });

    test('does not notify when the server agrees with the cache', () async {
      final api = _FakeConfigApi(
        () async =>
            const AppConfig(theme: AppThemeConfig(id: AppThemeId.halloween)),
      );
      final c = container(
        ThemeRepository.memory(const AppThemeConfig(id: AppThemeId.halloween)),
        api,
      );
      final seen = <AppTheme>[];
      c.listen(themeProvider, (_, next) => seen.add(next));

      c.read(themeProvider);
      await pumpEventQueue();
      expect(api.calls, 1);
      expect(seen, isEmpty);
    });

    test('keeps the current theme when the server is down', () async {
      final c = container(
        ThemeRepository.memory(const AppThemeConfig(id: AppThemeId.halloween)),
        _FakeConfigApi(() async => throw Exception('offline')),
      );
      c.read(themeProvider);
      await pumpEventQueue();
      expect(c.read(themeProvider).id, AppThemeId.halloween);
    });

    test('keeps the current theme when the server predates themes', () async {
      final c = container(
        ThemeRepository.memory(const AppThemeConfig(id: AppThemeId.halloween)),
        _FakeConfigApi(() async => const AppConfig()),
      );
      c.read(themeProvider);
      await pumpEventQueue();
      expect(c.read(themeProvider).id, AppThemeId.halloween);
    });

    test('applies the server kill switch for the motion layer', () async {
      final c = container(
        ThemeRepository.memory(const AppThemeConfig(id: AppThemeId.halloween)),
        _FakeConfigApi(
          () async => const AppConfig(
            theme: AppThemeConfig(id: AppThemeId.halloween, animated: false),
          ),
        ),
      );
      c.read(themeProvider);
      await pumpEventQueue();
      expect(c.read(themeProvider).animated, isFalse);
      expect(AppTheme.active.animated, isFalse);
    });
  });

  testWidgets('refreshEntireUi repaints const widgets that read CasinoColors', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: _Swatch()));
    final swatch = find.byType(ColoredBox);
    expect(tester.widget<ColoredBox>(swatch).color, CasinoPalette.casino.gold);

    AppTheme.activate(AppTheme.halloween);
    refreshEntireUi(tester.element(find.byType(MaterialApp)));
    await tester.pump();

    expect(
      tester.widget<ColoredBox>(swatch).color,
      CasinoPalette.halloween.gold,
    );
  });

  testWidgets('HalloweenAmbient settles when motion is off', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: HalloweenAmbient(animated: false)),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('HalloweenAmbient settles under reduce-motion', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(body: HalloweenAmbient(animated: true)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('HalloweenAmbient drifts when motion is on', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HalloweenAmbient(animated: true))),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(tester.hasRunningAnimations, isTrue);
  });

  testWidgets(
    'the felt stage carries the Halloween scene only under halloween',
    (tester) async {
      AppTheme.activate(AppTheme.casino);
      await tester.pumpWidget(
        const MaterialApp(home: FeltTableBackground(child: SizedBox())),
      );
      expect(find.byType(HalloweenAmbient), findsNothing);

      // Unmount first so the next mount reads the newly activated theme.
      AppTheme.activate(AppTheme.halloween);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        const MaterialApp(home: FeltTableBackground(child: SizedBox())),
      );
      expect(find.byType(HalloweenAmbient), findsOneWidget);
    },
  );

  testWidgets('the root stage stays still under Halloween', (tester) async {
    AppTheme.activate(AppTheme.halloween);
    await tester.pumpWidget(
      const MaterialApp(
        home: FeltTableBackground(animated: false, child: SizedBox()),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
  });
}

/// WCAG 2.x contrast ratio between two opaque colours.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}
