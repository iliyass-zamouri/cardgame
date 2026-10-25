import 'package:cardgame/data/avatars/avatar_catalog.dart';
import 'package:cardgame/data/decks/deck_catalog.dart';

/// Marketing badge an admin can put on a shop item.
enum ShopBadge {
  isNew('new'),
  hot('hot'),
  popular('popular'),
  bestValue('best_value'),
  limited('limited');

  const ShopBadge(this.wire);

  final String wire;

  static ShopBadge? parse(Object? raw) {
    for (final badge in values) {
      if (badge.wire == raw) return badge;
    }
    return null;
  }
}

/// Look of the promo banner. The app draws each in its own art.
enum ShopBannerStyle { gold, ruby, emerald, sapphire }

CurrencyType _currency(Object? raw, CurrencyType fallback) => switch (raw) {
  'money' => CurrencyType.money,
  'chips' => CurrencyType.chips,
  _ => fallback,
};

int _int(Object? raw, int fallback) => (raw as num?)?.toInt() ?? fallback;

/// Server time in ms → this device's clock, corrected by the offset seen when
/// the catalog arrived, so a wrong device clock can't end a sale early.
DateTime? _localTime(Object? serverMs, int skewMs) {
  final ms = (serverMs as num?)?.toInt();
  return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms - skewMs);
}

/// What an item costs, and the sale that lowers it, if one runs.
class ShopPrice {
  const ShopPrice({
    required this.basePrice,
    required this.currency,
    this.salePrice,
    this.saleEndsAt,
    this.badge,
  });

  final int basePrice;
  final CurrencyType currency;
  final int? salePrice;
  final DateTime? saleEndsAt;
  final ShopBadge? badge;

  bool onSaleAt(DateTime now) =>
      salePrice != null && saleEndsAt != null && now.isBefore(saleEndsAt!);

  int priceAt(DateTime now) => onSaleAt(now) ? salePrice! : basePrice;

  /// Whole percent off, e.g. 30 for 35 → 25.
  int get percentOff =>
      salePrice == null || basePrice <= 0
          ? 0
          : ((1 - salePrice! / basePrice) * 100).round();
}

class ShopAvatar {
  const ShopAvatar({required this.item, required this.price});

  /// The bundled avatar, with the server's price, currency and level.
  final AvatarItem item;
  final ShopPrice price;
}

class ShopDeck {
  const ShopDeck({required this.item, required this.price});

  /// The bundled deck, with the server's rarity.
  final DeckItem item;
  final ShopPrice price;
}

/// A store product as the shop lists it. The real-money price comes from
/// the store; [amount] and [bonusAmount] are what the server grants.
class IapPackOffer {
  const IapPackOffer({
    required this.productId,
    required this.currency,
    required this.amount,
    this.bonusAmount,
    this.bonusEndsAt,
    this.badge,
  });

  final String productId;
  final CurrencyType currency;
  final int amount;
  final int? bonusAmount;
  final DateTime? bonusEndsAt;
  final ShopBadge? badge;

  int bonusAt(DateTime now) =>
      bonusAmount != null && bonusEndsAt != null && now.isBefore(bonusEndsAt!)
          ? bonusAmount!
          : 0;
}

class ShopBanner {
  const ShopBanner({
    required this.style,
    required this.title,
    this.subtitle,
    this.deeplink,
    this.endsAt,
  });

  final ShopBannerStyle style;
  final Map<String, String> title;
  final Map<String, String>? subtitle;
  final String? deeplink;
  final DateTime? endsAt;

  /// The text in [languageCode], or English when it has no translation.
  static String? pick(Map<String, String>? text, String languageCode) {
    if (text == null) return null;
    final value = text[languageCode];
    return value != null && value.isNotEmpty ? value : text['en'];
  }

  bool liveAt(DateTime now) => endsAt == null || now.isBefore(endsAt!);
}

/// Featured item: 'avatar', 'deck' or 'iap', and its id.
class ShopFeatured {
  const ShopFeatured({required this.type, required this.id});

  final String type;
  final String id;

  bool matches(String itemType, String itemId) =>
      type == itemType && id == itemId;
}

/// The bundled store packs, shown until the server catalog arrives.
const bundledIapPacks = [
  IapPackOffer(productId: 'chips_1', currency: CurrencyType.chips, amount: 1),
  IapPackOffer(productId: 'chips_5', currency: CurrencyType.chips, amount: 5),
  IapPackOffer(productId: 'chips_10', currency: CurrencyType.chips, amount: 10),
  IapPackOffer(productId: 'chips_25', currency: CurrencyType.chips, amount: 25),
  IapPackOffer(productId: 'chips_50', currency: CurrencyType.chips, amount: 50),
];

/// GET /marketplace/catalog: what the shop sells and for how much, set by
/// admins. Items keep their bundled art and names; ids this build doesn't
/// know are dropped.
class MarketplaceCatalog {
  const MarketplaceCatalog({
    required this.moneyPerChip,
    required this.adRewardMoney,
    required this.adDailyCap,
    required this.avatars,
    required this.decks,
    required this.packs,
    this.banner,
    this.featured,
    this.nextChangeAt,
    this.version = 'bundled',
  });

  final int moneyPerChip;
  final int adRewardMoney;
  final int adDailyCap;
  final List<ShopAvatar> avatars;
  final List<ShopDeck> decks;
  final List<IapPackOffer> packs;
  final ShopBanner? banner;
  final ShopFeatured? featured;

  /// When a sale, bonus or banner next starts or ends.
  final DateTime? nextChangeAt;
  final String version;

  /// The catalog this build shipped with, for the first run and offline.
  static final MarketplaceCatalog bundled = MarketplaceCatalog(
    moneyPerChip: 1000,
    adRewardMoney: 50,
    adDailyCap: 5,
    avatars: [
      for (final avatar in AvatarCatalog.all)
        ShopAvatar(
          item: avatar,
          price: ShopPrice(basePrice: avatar.price, currency: avatar.currency),
        ),
    ],
    decks: [
      for (final deck in DeckCatalog.all)
        ShopDeck(
          item: deck,
          price: ShopPrice(
            basePrice: deck.chipPrice,
            currency: CurrencyType.chips,
          ),
        ),
    ],
    packs: bundledIapPacks,
  );

  /// [receivedAt] is when this device got [json], to correct for its clock.
  factory MarketplaceCatalog.fromJson(
    Map<String, dynamic> json, {
    required DateTime receivedAt,
  }) {
    final serverMs = _int(
      json['serverTimeMs'],
      receivedAt.millisecondsSinceEpoch,
    );
    final skew = serverMs - receivedAt.millisecondsSinceEpoch;
    final economy = json['economy'] as Map? ?? const {};
    final ads = json['ads'] as Map? ?? const {};

    ShopPrice price(Map raw, CurrencyType fallbackCurrency) {
      final sale = raw['sale'] as Map?;
      return ShopPrice(
        basePrice: _int(raw['basePrice'] ?? raw['price'], 0),
        currency: _currency(raw['currency'], fallbackCurrency),
        salePrice: sale == null ? null : _int(sale['price'], 0),
        saleEndsAt: sale == null ? null : _localTime(sale['endsAtMs'], skew),
        badge: ShopBadge.parse(raw['badge']),
      );
    }

    final avatars = <ShopAvatar>[];
    for (final raw in (json['avatars'] as List? ?? const []).whereType<Map>()) {
      final bundled = AvatarCatalog.all.where((a) => a.id == raw['id']);
      if (bundled.isEmpty) continue;
      final shopPrice = price(raw, bundled.first.currency);
      avatars.add(
        ShopAvatar(
          item: bundled.first.copyWith(
            price: shopPrice.basePrice,
            currency: shopPrice.currency,
            requiredLevel: _int(
              raw['requiredLevel'],
              bundled.first.requiredLevel,
            ),
          ),
          price: shopPrice,
        ),
      );
    }

    final decks = <ShopDeck>[];
    for (final raw in (json['decks'] as List? ?? const []).whereType<Map>()) {
      final bundled = DeckCatalog.all.where((d) => d.id == raw['id']);
      if (bundled.isEmpty) continue;
      final shopPrice = price(raw, CurrencyType.chips);
      final rarity = DeckRarity.values.asNameMap()[raw['rarity']];
      decks.add(
        ShopDeck(
          item: bundled.first.copyWith(
            chipPrice: shopPrice.basePrice,
            rarity: rarity,
          ),
          price: shopPrice,
        ),
      );
    }

    final packs = <IapPackOffer>[];
    for (final raw
        in (json['iapPacks'] as List? ?? const []).whereType<Map>()) {
      final productId = raw['productId'];
      if (productId is! String) continue;
      final bonus = raw['bonus'] as Map?;
      packs.add(
        IapPackOffer(
          productId: productId,
          currency: _currency(raw['type'], CurrencyType.chips),
          amount: _int(raw['amount'], 0),
          bonusAmount: bonus == null ? null : _int(bonus['amount'], 0),
          bonusEndsAt:
              bonus == null ? null : _localTime(bonus['endsAtMs'], skew),
          badge: ShopBadge.parse(raw['badge']),
        ),
      );
    }

    final bannerRaw = json['banner'] as Map?;
    final featuredRaw = json['featured'] as Map?;
    Map<String, String>? text(Object? raw) =>
        raw is Map ? raw.map((k, v) => MapEntry('$k', '$v')) : null;

    return MarketplaceCatalog(
      moneyPerChip: _int(economy['moneyPerChip'], 1000),
      adRewardMoney: _int(ads['rewardMoney'], 50),
      adDailyCap: _int(ads['dailyCap'], 5),
      avatars: avatars,
      decks: decks,
      packs: packs,
      banner:
          bannerRaw == null || text(bannerRaw['title']) == null
              ? null
              : ShopBanner(
                style:
                    ShopBannerStyle.values.asNameMap()[bannerRaw['style']] ??
                    ShopBannerStyle.gold,
                title: text(bannerRaw['title'])!,
                subtitle: text(bannerRaw['subtitle']),
                deeplink: bannerRaw['deeplink'] as String?,
                endsAt: _localTime(bannerRaw['endsAtMs'], skew),
              ),
      featured:
          featuredRaw == null
              ? null
              : ShopFeatured(
                type: '${featuredRaw['type']}',
                id: '${featuredRaw['id']}',
              ),
      nextChangeAt: _localTime(json['nextChangeAtMs'], skew),
      version: '${json['version'] ?? ''}',
    );
  }

  ShopAvatar? avatar(String id) {
    for (final entry in avatars) {
      if (entry.item.id == id) return entry;
    }
    return null;
  }

  ShopDeck? deck(String id) {
    for (final entry in decks) {
      if (entry.item.id == id) return entry;
    }
    return null;
  }

  /// [items] with the featured one moved to the front.
  List<T> featuredFirst<T>(
    List<T> items,
    String itemType,
    String Function(T) idOf,
  ) {
    final pick = featured;
    if (pick == null || pick.type != itemType) return items;
    final index = items.indexWhere((item) => idOf(item) == pick.id);
    if (index <= 0) return items;
    return [items[index], ...items.take(index), ...items.skip(index + 1)];
  }
}
