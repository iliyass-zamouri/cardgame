import 'package:hive_flutter/hive_flutter.dart';

class PlayerProfile {
  const PlayerProfile({
    required this.playerId,
    required this.name,
    required this.username,
    this.authType = 'guest',
    this.avatarId = 'default',
    this.money = 500,
    this.chips = 1,
    this.ownedAvatars = const ['default'],
    this.ownedDecks = const ['default'],
  });

  final String playerId;
  final String name;
  final String username;
  final String authType;
  final String avatarId;
  final int money;
  final int chips;
  final List<String> ownedAvatars;
  final List<String> ownedDecks;

  static const empty = PlayerProfile(
    playerId: '',
    name: 'Player',
    username: 'player',
    authType: 'guest',
    avatarId: 'default',
    money: 500,
    chips: 1,
    ownedAvatars: ['default'],
    ownedDecks: ['default'],
  );

  bool get isEmpty => playerId.isEmpty;

  bool ownsAvatar(String avatarId) {
    if (avatarId == 'default') return true;
    return ownedAvatars.contains(avatarId);
  }

  bool ownsDeck(String deckId) {
    if (deckId == 'default') return true;
    return ownedDecks.contains(deckId);
  }

  PlayerProfile copyWith({
    String? playerId,
    String? name,
    String? username,
    String? authType,
    String? avatarId,
    int? money,
    int? chips,
    List<String>? ownedAvatars,
    List<String>? ownedDecks,
  }) {
    return PlayerProfile(
      playerId: playerId ?? this.playerId,
      name: name ?? this.name,
      username: username ?? this.username,
      authType: authType ?? this.authType,
      avatarId: avatarId ?? this.avatarId,
      money: money ?? this.money,
      chips: chips ?? this.chips,
      ownedAvatars: ownedAvatars ?? this.ownedAvatars,
      ownedDecks: ownedDecks ?? this.ownedDecks,
    );
  }
}

class PlayerProfileRepository {
  PlayerProfileRepository._(this._box, this._memory);

  static const boxName = 'player_profile';
  static const _keyPlayerId = 'playerId';
  static const _keyName = 'name';
  static const _keyUsername = 'username';
  static const _keyAuthType = 'authType';
  static const _keyAvatarId = 'avatarId';
  static const _keyMoney = 'money';
  static const _keyChips = 'chips';
  static const _keyOwnedAvatars = 'ownedAvatars';
  static const _keyOwnedDecks = 'ownedDecks';

  final Box<dynamic>? _box;
  PlayerProfile? _memory;

  static Future<PlayerProfileRepository> open() async {
    final box = await Hive.openBox<dynamic>(boxName);
    return PlayerProfileRepository._(box, null);
  }

  /// In-memory repo for tests (no Hive).
  factory PlayerProfileRepository.memory([
    PlayerProfile initial = PlayerProfile.empty,
  ]) {
    return PlayerProfileRepository._(null, initial);
  }

  PlayerProfile load() {
    if (_memory != null) return _memory!;
    final playerId = _box!.get(_keyPlayerId) as String? ?? '';
    if (playerId.isEmpty) return PlayerProfile.empty;
    final storedAvatars = (_box.get(_keyOwnedAvatars) as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const ['default'];
    final storedDecks = (_box.get(_keyOwnedDecks) as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const ['default'];

    return PlayerProfile(
      playerId: playerId,
      name: _box.get(_keyName) as String? ?? 'Player',
      username: _box.get(_keyUsername) as String? ?? 'player',
      authType: _box.get(_keyAuthType) as String? ?? 'guest',
      avatarId: _box.get(_keyAvatarId) as String? ?? 'default',
      money: (_box.get(_keyMoney) as num?)?.toInt() ?? 500,
      chips: (_box.get(_keyChips) as num?)?.toInt() ?? 1,
      ownedAvatars: storedAvatars.isEmpty ? const ['default'] : storedAvatars,
      ownedDecks: storedDecks.isEmpty ? const ['default'] : storedDecks,
    );
  }

  Future<void> save(PlayerProfile profile) async {
    if (_box == null) {
      _memory = profile;
      return;
    }
    await _box.put(_keyPlayerId, profile.playerId);
    await _box.put(_keyName, profile.name);
    await _box.put(_keyUsername, profile.username);
    await _box.put(_keyAuthType, profile.authType);
    await _box.put(_keyAvatarId, profile.avatarId);
    await _box.put(_keyMoney, profile.money);
    await _box.put(_keyChips, profile.chips);
    await _box.put(_keyOwnedAvatars, profile.ownedAvatars);
    await _box.put(_keyOwnedDecks, profile.ownedDecks);
  }

  Future<void> clear() async {
    if (_box == null) {
      _memory = PlayerProfile.empty;
      return;
    }
    await _box.clear();
  }
}
