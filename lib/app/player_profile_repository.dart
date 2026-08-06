import 'package:hive_flutter/hive_flutter.dart';

class PlayerProfile {
  const PlayerProfile({
    required this.playerId,
    required this.name,
    required this.username,
    this.authType = 'guest',
  });

  final String playerId;
  final String name;
  final String username;
  final String authType;

  static const empty = PlayerProfile(
    playerId: '',
    name: 'Player',
    username: 'player',
  );

  bool get isEmpty => playerId.isEmpty;

  PlayerProfile copyWith({
    String? playerId,
    String? name,
    String? username,
    String? authType,
  }) {
    return PlayerProfile(
      playerId: playerId ?? this.playerId,
      name: name ?? this.name,
      username: username ?? this.username,
      authType: authType ?? this.authType,
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
    return PlayerProfile(
      playerId: playerId,
      name: _box.get(_keyName) as String? ?? 'Player',
      username: _box.get(_keyUsername) as String? ?? 'player',
      authType: _box.get(_keyAuthType) as String? ?? 'guest',
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
  }

  Future<void> clear() async {
    if (_box == null) {
      _memory = PlayerProfile.empty;
      return;
    }
    await _box.clear();
  }
}
