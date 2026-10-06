import 'package:cardgame/data/avatars/avatar_catalog.dart';
import 'package:cardgame/domain/models/game_snapshot.dart';
import 'package:cardgame/l10n/app_localizations.dart';
import 'package:cardgame/ui/screens/home/stake_selector_modal.dart';
import 'package:cardgame/ui/theme/city_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
