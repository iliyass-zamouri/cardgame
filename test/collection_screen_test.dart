import 'package:cardgame/app/auth_providers.dart';
import 'package:cardgame/app/player_profile_repository.dart';
import 'package:cardgame/data/avatars/avatar_catalog.dart';
import 'package:cardgame/data/decks/deck_catalog.dart';
import 'package:cardgame/l10n/app_localizations.dart';
import 'package:cardgame/ui/screens/collection_screen.dart';
import 'package:cardgame/ui/screens/marketplace_screen.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/theme/felt_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Local-only profile (no player id) so equip never hits the network.
  const profile = PlayerProfile(
    playerId: '',
    name: 'Ace',
    username: 'ace',
    chips: 3,
    ownedAvatars: ['default', 'blue'],
    ownedDecks: ['default', 'sapphire_frost'],
  );

  Future<ProviderContainer> pumpCollection(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(
      overrides: [
        playerProfileRepositoryProvider.overrideWithValue(
          PlayerProfileRepository.memory(profile),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildCasinoTheme(),
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const CollectionScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    return container;
  }

  testWidgets('shows owned counts and equips an owned deck', (tester) async {
    final container = await pumpCollection(tester);

    expect(find.text('2/${DeckCatalog.all.length} owned'), findsOneWidget);
    expect(find.text('2/${AvatarCatalog.all.length} owned'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final sapphire = find.byKey(const ValueKey('deck-sapphire_frost'));
    await tester.tap(
      find.descendant(of: sapphire, matching: find.byType(LeatherButton)),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));

    expect(
      container.read(playerProfileProvider).value?.deckId,
      'sapphire_frost',
    );
  });

  testWidgets('locked deck opens the shop on the decks tab', (tester) async {
    await pumpCollection(tester);

    final buy = find.descendant(
      of: find.byKey(const ValueKey('deck-black_onyx')),
      matching: find.byType(GoldButton),
    );
    // Built lazily below the fold: scroll the grid until it is on screen.
    for (
      var i = 0;
      i < 15 && (buy.evaluate().isEmpty || tester.getCenter(buy).dy > 760);
      i++
    ) {
      await tester.drag(
        find.byType(CustomScrollView).first,
        const Offset(0, -150),
      );
      await tester.pump();
    }
    await tester.tap(buy);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final shop = tester.widget<MarketplaceScreen>(
      find.byType(MarketplaceScreen),
    );
    expect(shop.initialTabIndex, 2);
  });
}
