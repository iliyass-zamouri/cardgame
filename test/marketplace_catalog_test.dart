import 'dart:convert';
import 'dart:io';

import 'package:cardgame/app/marketplace_providers.dart';
import 'package:cardgame/data/avatars/avatar_catalog.dart';
import 'package:cardgame/data/decks/deck_catalog.dart';
import 'package:cardgame/data/marketplace/marketplace_api.dart';
import 'package:cardgame/data/marketplace/marketplace_catalog.dart';
import 'package:cardgame/l10n/app_localizations.dart';
import 'package:cardgame/ui/widgets/shop_promo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Captured from GET /marketplace/catalog on a local server with an admin
/// sale on Sapphire, a ruby banner, 24K Gold featured and Neon Nights hidden.
Map<String, dynamic> _promo() =>
    jsonDecode(
          File(
            'test/fixtures/marketplace/catalog_promo.json',
          ).readAsStringSync(),
        )
        as Map<String, dynamic>;

void main() {
  final json = _promo();
  final serverNow = DateTime.fromMillisecondsSinceEpoch(
    json['serverTimeMs'] as int,
  );
  final catalog = MarketplaceCatalog.fromJson(json, receivedAt: serverNow);

  group('MarketplaceCatalog.fromJson', () {
    test('keeps bundled art and applies the server price, sale and badge', () {
      final blue = catalog.avatar('blue')!;
      expect(blue.item.assetPath, AvatarCatalog.getById('blue').assetPath);
      expect(blue.item.price, 250);
      expect(blue.price.basePrice, 250);
      expect(blue.price.salePrice, 175);
      expect(blue.price.badge, ShopBadge.hot);
      expect(blue.price.onSaleAt(serverNow), isTrue);
      expect(blue.price.priceAt(serverNow), 175);
      expect(blue.price.percentOff, 30);
    });

    test('a sale ends at its end time, then the normal price applies', () {
      final blue = catalog.avatar('blue')!.price;
      final end = blue.saleEndsAt!;
      expect(blue.priceAt(end.subtract(const Duration(seconds: 1))), 175);
      expect(blue.priceAt(end), 250);
    });

    test('hidden items are left out and the order is the server order', () {
      expect(catalog.deck('neon_nights'), isNull);
      expect(catalog.decks.map((d) => d.item.id), [
        'default',
        'sapphire_frost',
        'imperial_jade',
        'royal_crimson',
        'black_onyx',
        'gilded_gold',
      ]);
    });

    test('the featured item moves to the front of its list', () {
      final ordered = catalog.featuredFirst(
        catalog.decks,
        'deck',
        (d) => d.item.id,
      );
      expect(ordered.first.item.id, 'gilded_gold');
      expect(ordered.length, catalog.decks.length);
      // Featuring a deck leaves the avatar order alone.
      expect(
        catalog.featuredFirst(catalog.avatars, 'avatar', (a) => a.item.id),
        same(catalog.avatars),
      );
    });

    test('the banner keeps its text per language, falling back to English', () {
      final banner = catalog.banner!;
      expect(banner.style, ShopBannerStyle.ruby);
      expect(ShopBanner.pick(banner.title, 'fr'), 'Weekend deck sale');
      expect(banner.deeplink, '/shop?tab=decks');
      expect(banner.liveAt(serverNow), isTrue);
    });

    test('times are corrected for a device clock that runs fast', () {
      final fastDevice = serverNow.add(const Duration(hours: 2));
      final skewed = MarketplaceCatalog.fromJson(json, receivedAt: fastDevice);
      final serverEnd = catalog.avatar('blue')!.price.saleEndsAt!;
      expect(
        skewed.avatar('blue')!.price.saleEndsAt,
        serverEnd.add(const Duration(hours: 2)),
      );
    });

    test('ids this build does not know are dropped', () {
      final withUnknown = {
        ...json,
        'decks': [
          ...(json['decks'] as List),
          {'id': 'rainbow', 'price': 9, 'basePrice': 9, 'currency': 'chips'},
        ],
      };
      final parsed = MarketplaceCatalog.fromJson(
        withUnknown,
        receivedAt: serverNow,
      );
      expect(parsed.deck('rainbow'), isNull);
    });
  });

  test('the bundled catalog matches the prices this build shipped with', () {
    final bundled = MarketplaceCatalog.bundled;
    expect(bundled.moneyPerChip, 1000);
    expect(bundled.avatars.length, AvatarCatalog.all.length);
    expect(bundled.deck('gilded_gold')!.price.priceAt(DateTime.now()), 35);
    expect(bundled.packs.map((p) => p.productId), [
      'chips_1',
      'chips_5',
      'chips_10',
      'chips_25',
      'chips_50',
    ]);
  });

  test('the repository round-trips the served catalog', () async {
    final repo = MarketplaceCatalogRepository.memory();
    expect(repo.read(), isNull);
    await repo.write(json, serverNow);
    final cached = repo.read()!;
    expect(cached.version, catalog.version);
    expect(
      cached.avatar('blue')!.price.saleEndsAt,
      catalog.avatar('blue')!.price.saleEndsAt,
    );
  });

  test('shop-changed errors are told apart from other refusals', () {
    expect(
      isShopChangedError(MarketplaceApiException('x', code: 'price_changed')),
      isTrue,
    );
    expect(
      isShopChangedError(
        MarketplaceApiException('x', code: 'item_unavailable'),
      ),
      isTrue,
    );
    expect(
      isShopChangedError(
        MarketplaceApiException('x', code: 'insufficient_funds'),
      ),
      isFalse,
    );
  });

  test('deck copyWith keeps the skin and takes the server rarity', () {
    final deck = DeckCatalog.getById('sapphire_frost');
    final edited = deck.copyWith(chipPrice: 4, rarity: DeckRarity.epic);
    expect(edited.skinId, deck.skinId);
    expect(edited.chipPrice, 4);
    expect(edited.rarity, DeckRarity.epic);
  });

  // About a phone card's width.
  Widget app(Widget child, {double width = 220}) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: SizedBox(width: width, child: child)),
  );

  testWidgets('promo tags show the featured crown and the badge', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        const ShopPromoTags(badge: ShopBadge.bestValue, featured: true),
        width: 400,
      ),
    );
    expect(find.text('FEATURED'), findsOneWidget);
    expect(find.text('BEST VALUE'), findsOneWidget);

    // Too narrow for the words: the pills keep just their icons, no overflow.
    await tester.pumpWidget(
      app(
        const ShopPromoTags(badge: ShopBadge.bestValue, featured: true),
        width: 60,
      ),
    );
    expect(find.text('BEST VALUE'), findsNothing);
    expect(find.byType(ShopPill), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the sale bar shows the discount, old price and time left', (
    tester,
  ) async {
    final price = ShopPrice(
      basePrice: 35,
      currency: CurrencyType.chips,
      salePrice: 25,
      saleEndsAt: DateTime.now().add(
        const Duration(days: 2, hours: 3, minutes: 30),
      ),
    );
    await tester.pumpWidget(
      app(ShopSaleBar(price: price, currencyIcon: const SizedBox())),
    );
    expect(find.text('−29%'), findsOneWidget);
    expect(find.text('35'), findsOneWidget);
    expect(find.text('2d 3h'), findsOneWidget);
    expect(tester.takeException(), isNull);
    // Unmount so the countdown's timer stops.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the sale bar is gone once the sale has ended', (tester) async {
    final price = ShopPrice(
      basePrice: 35,
      currency: CurrencyType.chips,
      salePrice: 25,
      saleEndsAt: DateTime.now().subtract(const Duration(minutes: 1)),
    );
    await tester.pumpWidget(
      app(ShopSaleBar(price: price, currencyIcon: const SizedBox())),
    );
    expect(find.text('35'), findsNothing);
    expect(find.textContaining('%'), findsNothing);
  });

  testWidgets('the bonus bar shows the extra amount on a store pack', (
    tester,
  ) async {
    final pack = IapPackOffer(
      productId: 'chips_25',
      currency: CurrencyType.chips,
      amount: 25,
      bonusAmount: 5,
      bonusEndsAt: DateTime.now().add(const Duration(hours: 2)),
    );
    await tester.pumpWidget(app(ShopBonusBar(pack: pack), width: 340));
    expect(find.text('+5 BONUS'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  test('shopTimeLeft uses a clock under a day and days above', () {
    final l10n = lookupAppLocalizations(const Locale('en'));
    expect(shopTimeLeft(l10n, const Duration(minutes: 5, seconds: 3)), '05:03');
    expect(shopTimeLeft(l10n, const Duration(days: 1, hours: 4)), '1d 4h');
  });
}
