enum DeckRarity { standard, rare, epic, legendary }

class DeckItem {
  const DeckItem({
    required this.id,
    required this.nameKey,
    required this.descriptionKey,
    required this.chipPrice,
    required this.rarity,
    required this.skinId,
    this.isDefault = false,
  });

  final String id;
  final String nameKey;
  final String descriptionKey;
  final int chipPrice;
  final DeckRarity rarity;
  final String skinId;
  final bool isDefault;
}

class DeckCatalog {
  static const String defaultDeckId = 'default';
  static const String onyxBlackDeckId = 'black_onyx';

  static const defaultDeck = DeckItem(
    id: defaultDeckId,
    nameKey: 'classicDeck',
    descriptionKey: 'classicDeckDesc',
    chipPrice: 0,
    rarity: DeckRarity.standard,
    skinId: 'ornate_blue',
    isDefault: true,
  );

  static const onyxBlack = DeckItem(
    id: onyxBlackDeckId,
    nameKey: 'onyxBlackDeck',
    descriptionKey: 'onyxBlackDeckDesc',
    chipPrice: 20,
    rarity: DeckRarity.legendary,
    skinId: 'black_onyx',
  );

  static const sapphireFrost = DeckItem(
    id: 'sapphire_frost',
    nameKey: 'sapphireFrostDeck',
    descriptionKey: 'sapphireFrostDeckDesc',
    chipPrice: 6,
    rarity: DeckRarity.rare,
    skinId: 'sapphire_frost',
  );

  static const imperialJade = DeckItem(
    id: 'imperial_jade',
    nameKey: 'imperialJadeDeck',
    descriptionKey: 'imperialJadeDeckDesc',
    chipPrice: 8,
    rarity: DeckRarity.rare,
    skinId: 'imperial_jade',
  );

  static const royalCrimson = DeckItem(
    id: 'royal_crimson',
    nameKey: 'royalCrimsonDeck',
    descriptionKey: 'royalCrimsonDeckDesc',
    chipPrice: 12,
    rarity: DeckRarity.epic,
    skinId: 'royal_crimson',
  );

  static const neonNights = DeckItem(
    id: 'neon_nights',
    nameKey: 'neonNightsDeck',
    descriptionKey: 'neonNightsDeckDesc',
    chipPrice: 15,
    rarity: DeckRarity.epic,
    skinId: 'neon_nights',
  );

  static const gilded = DeckItem(
    id: 'gilded_gold',
    nameKey: 'gildedDeck',
    descriptionKey: 'gildedDeckDesc',
    chipPrice: 35,
    rarity: DeckRarity.legendary,
    skinId: 'gilded_gold',
  );

  /// Market order: cheapest first, ending with the legendaries.
  static const List<DeckItem> all = [
    defaultDeck,
    sapphireFrost,
    imperialJade,
    royalCrimson,
    neonNights,
    onyxBlack,
    gilded,
  ];

  static DeckItem getById(String? id) {
    if (id == null || id.isEmpty) return defaultDeck;
    return all.firstWhere((deck) => deck.id == id, orElse: () => defaultDeck);
  }

  /// Flame back-skin id for a catalog deck. Unknown ids fall back to Classic Blue.
  static String skinIdFor(String? deckId) => getById(deckId).skinId;
}
