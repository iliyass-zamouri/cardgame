import 'dart:convert';
import 'dart:io';

import 'package:cardgame/app/auth_providers.dart';
import 'package:cardgame/app/marketplace_providers.dart';
import 'package:cardgame/app/player_profile_repository.dart';
import 'package:cardgame/data/marketplace/marketplace_catalog.dart';
import 'package:cardgame/l10n/app_localizations.dart';
import 'package:cardgame/services/sfx_service.dart';
import 'package:cardgame/ui/screens/marketplace_screen.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A fixed catalog: no network.
class _FixedCatalog extends MarketplaceCatalogController {
  _FixedCatalog(this.catalog);

  final MarketplaceCatalog catalog;

  @override
  MarketplaceCatalog build() => catalog;

  @override
  Future<void> refresh() async {}
}

Future<void> _font(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final file in files) {
    loader.addFont(rootBundle.load('assets/fonts/$file'));
  }
  await loader.load();
}

/// The captured promo catalog with every promo at once: sales on avatars
/// and decks (long and short countdowns), long badges, a featured deck, and
/// bonuses on store packs.
MarketplaceCatalog _busyCatalog() {
  final json =
      jsonDecode(
            File(
              'test/fixtures/marketplace/catalog_promo.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  final t = json['serverTimeMs'] as int;
  Map<String, dynamic> sale(Map d, int price, String badge, int hours) => {
    ...d.cast<String, dynamic>(),
    'price': price,
    'badge': badge,
    'sale': {'price': price, 'endsAtMs': t + hours * 3600000},
  };
  List<Object> edit(String key, Map Function(Map) change) => [
    for (final item in json[key] as List) change(item as Map),
  ];
  return MarketplaceCatalog.fromJson({
    ...json,
    'avatars': edit(
      'avatars',
      (a) => switch (a['id']) {
        'golden-king' => sale(a, 3, 'limited', 30),
        'red' => sale(a, 280, 'best_value', 2),
        _ => a,
      },
    ),
    'decks': edit(
      'decks',
      (d) => switch (d['id']) {
        'royal_crimson' => sale(d, 8, 'new', 5),
        'gilded_gold' => sale(d, 25, 'best_value', 60),
        'sapphire_frost' => {...d, 'badge': 'popular'},
        _ => d,
      },
    ),
    'iapPacks': edit(
      'iapPacks',
      (p) => switch (p['productId']) {
        'chips_25' => {
          ...p,
          'badge': 'best_value',
          'bonus': {'amount': 5, 'endsAtMs': t + 86400000},
        },
        'chips_50' => {
          ...p,
          'badge': 'popular',
          'bonus': {'amount': 15, 'endsAtMs': t + 3 * 86400000},
        },
        _ => p,
      },
    ),
  }, receivedAt: DateTime.now());
}

void main() {
  setUpAll(() async {
    await _font('DM Sans', ['DMSans-Regular.ttf', 'DMSans-Bold.ttf']);
    await _font('Cinzel', ['Cinzel-Regular.ttf', 'Cinzel-Bold.ttf']);
    await _font('Cairo', ['Cairo-Regular.ttf', 'Cairo-Bold.ttf']);
  });
  setUp(() => SfxService.instance.enabled = false);

  final catalog = _busyCatalog();

  // The narrowest phone, a common phone and a desktop window, in the
  // longest languages, at normal and large text.
  for (final width in [320.0, 390.0, 1280.0]) {
    for (final language in ['en', 'fr', 'es', 'ar']) {
      for (final textScale in [1.0, 1.3]) {
        testWidgets(
          'shop promos fit at ${width.toInt()}px, $language, text x$textScale',
          (tester) async {
            tester.view.physicalSize = Size(width, 844) * 2;
            tester.view.devicePixelRatio = 2;
            addTearDown(tester.view.reset);
            for (final tab in MarketplaceTab.values) {
              await tester.pumpWidget(
                ProviderScope(
                  overrides: [
                    playerProfileRepositoryProvider.overrideWithValue(
                      PlayerProfileRepository.memory(
                        const PlayerProfile(
                          playerId: '',
                          name: 'Ace',
                          username: 'ace',
                          money: 123456,
                          chips: 1234,
                        ),
                      ),
                    ),
                    marketplaceCatalogProvider.overrideWith(
                      () => _FixedCatalog(catalog),
                    ),
                  ],
                  child: MaterialApp(
                    theme: buildCasinoTheme(),
                    locale: Locale(language),
                    builder:
                        (context, child) => MediaQuery(
                          data: MediaQuery.of(
                            context,
                          ).copyWith(textScaler: TextScaler.linear(textScale)),
                          child: child!,
                        ),
                    supportedLocales: AppLocalizations.supportedLocales,
                    localizationsDelegates: const [
                      AppLocalizations.delegate,
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                    ],
                    home: MarketplaceScreen(initialTab: tab),
                  ),
                ),
              );
              await tester.pump(const Duration(milliseconds: 500));
              // Scroll the whole tab so every card lays out.
              final list = find.byType(Scrollable).last;
              for (var i = 0; i < 6; i++) {
                await tester.drag(
                  list,
                  const Offset(0, -400),
                  warnIfMissed: false,
                );
                await tester.pump(const Duration(milliseconds: 50));
              }
              expect(tester.takeException(), isNull, reason: tab.name);
            }
            // Unmount so the countdowns' timers stop.
            await tester.pumpWidget(const SizedBox());
          },
        );
      }
    }
  }
}
