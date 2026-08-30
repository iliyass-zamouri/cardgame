enum DeckRarity {
  standard,
  rare,
  epic,
  legendary,
}

class DeckItem {
  const DeckItem({
    required this.id,
    required this.nameKey,
    required this.descriptionKey,
    required this.chipPrice,
    required this.rarity,
    this.isDefault = false,
    this.previewCardTags = const ['A1', 'B5', 'CK'],
  });

  final String id;
  final String nameKey;
  final String descriptionKey;
  final int chipPrice;
  final DeckRarity rarity;
  final bool isDefault;
  final List<String> previewCardTags;
}

class DeckCatalog {
  static const String defaultDeckId = 'default';

  static const defaultDeck = DeckItem(
    id: defaultDeckId,
    nameKey: 'classicDeck',
    descriptionKey: 'classicDeckDesc',
    chipPrice: 0,
    rarity: DeckRarity.standard,
    isDefault: true,
    previewCardTags: ['A1', 'B5', 'CK'],
  );

  static const List<DeckItem> all = [
    defaultDeck,
    DeckItem(
      id: 'gold_luxury',
      nameKey: 'goldLuxuryDeck',
      descriptionKey: 'goldLuxuryDeckDesc',
      chipPrice: 2,
      rarity: DeckRarity.rare,
      previewCardTags: ['A10', 'B10', 'DK'],
    ),
    DeckItem(
      id: 'shadow_neon',
      nameKey: 'shadowNeonDeck',
      descriptionKey: 'shadowNeonDeckDesc',
      chipPrice: 5,
      rarity: DeckRarity.legendary,
      previewCardTags: ['AJ', 'CQ', 'DK'],
    ),
  ];

  static DeckItem getById(String? id) {
    if (id == null || id.isEmpty) return defaultDeck;
    return all.firstWhere(
      (deck) => deck.id == id,
      orElse: () => defaultDeck,
    );
  }
}
