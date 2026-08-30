import 'package:cardgame/l10n/app_localizations.dart';
import 'package:cardgame/ui/screens/home/stake_selector_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StakeSelectorModal Configuration', () {
    test('pot options match ordered city banners and pools', () {
      final options = StakeSelectorModal.potOptions;
      expect(options.length, 5);

      expect(options[0].id, 'london');
      expect(options[0].assetPath, 'assets/pots/london.png');
      expect(options[0].pool, 20);
      expect(options[0].entryStake, 10);

      expect(options[1].id, 'paris');
      expect(options[1].assetPath, 'assets/pots/paris.png');
      expect(options[1].pool, 50);
      expect(options[1].entryStake, 25);

      expect(options[2].id, 'moscow');
      expect(options[2].assetPath, 'assets/pots/moscow.png');
      expect(options[2].pool, 100);
      expect(options[2].entryStake, 50);

      expect(options[3].id, 'cairo');
      expect(options[3].assetPath, 'assets/pots/cairo.png');
      expect(options[3].pool, 200);
      expect(options[3].entryStake, 100);

      expect(options[4].id, 'marrakech');
      expect(options[4].assetPath, 'assets/pots/marrakech.png');
      expect(options[4].pool, 500);
      expect(options[4].entryStake, 250);
    });

    test('stakePools backward compatibility list matches pools', () {
      expect(StakeSelectorModal.stakePools, [20, 50, 100, 200, 500]);
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
                  StakeSelectorModal.potOptions
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
    });
  });
}
