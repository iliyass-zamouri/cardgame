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
      requiredLevel: 9,
      currency: CurrencyType.chips,
      price: 1,
    ),
    AvatarItem(
      id: 'joker_girl',
      assetPath: 'assets/avatars/joker-girl.png',
      nameKey: 'jokerGirlAvatar',
      requiredLevel: 12,
      currency: CurrencyType.chips,
      price: 2,
    ),
    AvatarItem(
      id: 'queen',
      assetPath: 'assets/avatars/queen.png',
      nameKey: 'queenAvatar',
      requiredLevel: 16,
      currency: CurrencyType.chips,
      price: 3,
    ),
    AvatarItem(
      id: 'king',
      assetPath: 'assets/avatars/king.png',
      nameKey: 'kingAvatar',
      requiredLevel: 20,
      currency: CurrencyType.chips,
      price: 5,
    ),
  ];

  static AvatarItem getById(String? id) {
    if (id == null || id.isEmpty) return defaultAvatar;
    return all.firstWhere(
      (avatar) => avatar.id == id,
      orElse: () => defaultAvatar,
    );
  }

  static String getAssetPath(String? id) {
    return getById(id).assetPath;
  }
}
