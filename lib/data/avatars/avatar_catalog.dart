enum CurrencyType {
  money,
  chips;

  String get symbol => this == CurrencyType.money ? '💵' : '🪙';
}

class AvatarItem {
  const AvatarItem({
    required this.id,
    required this.assetPath,
    required this.nameKey,
    this.requiredLevel = 1,
    this.isDefault = false,
    this.currency = CurrencyType.money,
    this.price = 0,
  });

  final String id;
  final String assetPath;
  final String nameKey;
  final int requiredLevel;
  final bool isDefault;
  final CurrencyType currency;
  final int price;

  bool get isPremium => currency == CurrencyType.chips;

  bool isUnlocked(int playerLevel) {
    if (isDefault || requiredLevel <= 1) return true;
    return playerLevel >= requiredLevel;
  }
}

class AvatarCatalog {
  static const String defaultAvatarId = 'default';
  static const String defaultAssetPath = 'assets/avatars/default.png';

  static const defaultAvatar = AvatarItem(
    id: defaultAvatarId,
    assetPath: defaultAssetPath,
    nameKey: 'defaultAvatar',
    requiredLevel: 1,
    isDefault: true,
    currency: CurrencyType.money,
    price: 0,
  );

  static const List<AvatarItem> all = [
    defaultAvatar,
    AvatarItem(
      id: 'blue',
      assetPath: 'assets/avatars/blue.png',
      nameKey: 'blueAvatar',
      requiredLevel: 2,
      currency: CurrencyType.money,
      price: 200,
    ),
    AvatarItem(
      id: 'red',
      assetPath: 'assets/avatars/red.png',
      nameKey: 'redAvatar',
      requiredLevel: 4,
      currency: CurrencyType.money,
      price: 400,
    ),
    AvatarItem(
      id: 'bronze',
      assetPath: 'assets/avatars/bronze.png',
      nameKey: 'bronzeAvatar',
      requiredLevel: 6,
      currency: CurrencyType.money,
      price: 600,
    ),
    AvatarItem(
      id: 'silver',
      assetPath: 'assets/avatars/silver.png',
      nameKey: 'silverAvatar',
      requiredLevel: 8,
      currency: CurrencyType.chips,
      price: 1,
    ),
    AvatarItem(
      id: 'joker-girl',
      assetPath: 'assets/avatars/joker-girl.png',
      nameKey: 'jokerGirlAvatar',
      requiredLevel: 10,
      currency: CurrencyType.chips,
      price: 2,
    ),
    AvatarItem(
      id: 'violet-joker-girl',
      assetPath: 'assets/avatars/violet-joker-girl.png',
      nameKey: 'violetJokerGirlAvatar',
      requiredLevel: 12,
      currency: CurrencyType.chips,
      price: 2,
    ),
    AvatarItem(
      id: 'violet-queen',
      assetPath: 'assets/avatars/violet-queen.png',
      nameKey: 'violetQueenAvatar',
      requiredLevel: 15,
      currency: CurrencyType.chips,
      price: 3,
    ),
    AvatarItem(
      id: 'queen-of-heart',
      assetPath: 'assets/avatars/queen-of-heart.png',
      nameKey: 'queenOfHeartAvatar',
      requiredLevel: 18,
      currency: CurrencyType.chips,
      price: 4,
    ),
    AvatarItem(
      id: 'golden-king',
      assetPath: 'assets/avatars/golden-king.png',
      nameKey: 'goldenKingAvatar',
      requiredLevel: 20,
      currency: CurrencyType.chips,
      price: 5,
    ),
  ];

  static AvatarItem getById(String? id) {
    if (id == null || id.isEmpty) return defaultAvatar;
    final normalized = switch (id) {
      'joker_girl' => 'joker-girl',
      'violet_joker_girl' => 'violet-joker-girl',
      'violet_queen' || 'queen' => 'violet-queen',
      'queen_of_heart' || 'queen-of-hearts' => 'queen-of-heart',
      'golden_king' || 'king' => 'golden-king',
      _ => id,
    };
    return all.firstWhere(
      (avatar) => avatar.id == normalized || avatar.id == id,
      orElse: () => defaultAvatar,
    );
  }

  static String getAssetPath(String? id) {
    return getById(id).assetPath;
  }
}
