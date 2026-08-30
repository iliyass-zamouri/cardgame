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

  static const List<DeckItem> all = [defaultDeck, onyxBlack];

  static DeckItem getById(String? id) {
    if (id == null || id.isEmpty) return defaultDeck;
    return all.firstWhere((deck) => deck.id == id, orElse: () => defaultDeck);
  }

  /// Flame back-skin id for a catalog deck. Unknown ids fall back to Classic Blue.
  static String skinIdFor(String? deckId) => getById(deckId).skinId;
}
