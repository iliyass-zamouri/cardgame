import 'package:cardgame/app/player_profile_repository.dart';
import 'package:cardgame/app/session_auth_repository.dart';
import 'package:cardgame/app/session_auth_status.dart';
import 'package:cardgame/data/auth/auth_config.dart';
import 'package:cardgame/data/auth/device_identity_service.dart';
import 'package:cardgame/data/auth/google_sign_in_service.dart';
import 'package:cardgame/data/auth/guest_auth_service.dart';
import 'package:cardgame/data/auth/oauth_auth_service.dart';
import 'package:cardgame/data/auth/server_identity.dart';
import 'package:cardgame/data/marketplace/marketplace_api.dart';
import 'package:cardgame/data/profile/profile_api.dart';
import 'package:cardgame/services/analytics_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sessionAuthRepositoryProvider = Provider<SessionAuthRepository>((ref) {
  throw UnimplementedError(
    'sessionAuthRepositoryProvider must be overridden in main()',
  );
});

final playerProfileRepositoryProvider = Provider<PlayerProfileRepository>((
  ref,
) {
  throw UnimplementedError(
    'playerProfileRepositoryProvider must be overridden in main()',
  );
});

final deviceIdentityServiceProvider = Provider<DeviceIdentityService>((ref) {
  return DeviceIdentityService();
});

final profileApiServiceProvider = Provider<ProfileApi>((ref) {
  return ProfileApi(baseUrl: httpBaseUrl);
});

final marketplaceApiServiceProvider = Provider<MarketplaceApi>((ref) {
  return MarketplaceApi(baseUrl: httpBaseUrl);
});

final guestAuthServiceProvider = Provider<GuestAuthService>((ref) {
  return GuestAuthService(baseUrl: httpBaseUrl);
});

final oauthAuthServiceProvider = Provider<OAuthAuthService>((ref) {
  return OAuthAuthService(baseUrl: httpBaseUrl);
});

final googleSignInServiceProvider = Provider<GoogleSignInService>((ref) {
  return GoogleSignInService();
});

class SessionAuthNotifier extends AsyncNotifier<SessionAuthStatus> {
  SessionAuthRepository get _repo => ref.read(sessionAuthRepositoryProvider);

  @override
  Future<SessionAuthStatus> build() async {
    return _repo.load();
  }

  Future<void> signOut() async {
    try {
      await ref.read(googleSignInServiceProvider).signOut();
    } on Object {
      // Best-effort.
    }
    await ref.read(playerProfileProvider.notifier).clear();
    const next = SessionAuthStatus.signedOut;
    state = const AsyncData(next);
    await _repo.save(next);
  }

  Future<void> enterAsGuest() async {
    const next = SessionAuthStatus.guest;
    state = const AsyncData(next);
    await _repo.save(next);
  }

  Future<void> enterWithGoogle() async {
    const next = SessionAuthStatus.google;
    state = const AsyncData(next);
    await _repo.save(next);
  }
}

final sessionAuthProvider =
    AsyncNotifierProvider<SessionAuthNotifier, SessionAuthStatus>(
      SessionAuthNotifier.new,
    );

class PlayerProfileNotifier extends AsyncNotifier<PlayerProfile> {
  PlayerProfileRepository get _repo =>
      ref.read(playerProfileRepositoryProvider);

  @override
  Future<PlayerProfile> build() async {
    return _repo.load();
  }

  Future<void> applyIdentity(ServerIdentity identity) async {
    // Wait for initial build() so its empty Hive load cannot overwrite us.
    final current = await future;
    final next = PlayerProfile(
      playerId: identity.playerId,
      name: identity.name,
      username: identity.username,
      authType: identity.authType,
      avatarId: current.avatarId.isNotEmpty ? current.avatarId : 'default',
      money: identity.money,
      chips: identity.chips,
      ownedAvatars: current.ownedAvatars.isNotEmpty ? current.ownedAvatars : const ['default'],
      ownedDecks: current.ownedDecks.isNotEmpty ? current.ownedDecks : const ['default'],
    );
    await _repo.save(next);
    state = AsyncData(next);

    final analytics = ref.read(analyticsServiceProvider);
    await analytics.setUserId(identity.playerId);
    await analytics.setUserProperty(
      name: 'auth_type',
      value: identity.authType,
    );

    // Refresh inventory in background
    refreshInventory().ignore();
  }

  Future<void> refreshInventory() async {
    final current = await future;
    if (current.isEmpty || current.playerId.isEmpty) return;

    try {
      final marketplaceApi = ref.read(marketplaceApiServiceProvider);
      final inv = await marketplaceApi.getInventory(current.playerId);
      final next = current.copyWith(
        money: inv.money,
        chips: inv.chips,
        ownedAvatars: inv.ownedAvatars,
        ownedDecks: inv.ownedDecks,
      );
      await _repo.save(next);
      state = AsyncData(next);
    } catch (_) {
      // Best effort when offline / unavailable
    }
  }

  Future<void> exchangeCurrency({
    required String direction,
    required int amount,
  }) async {
    final current = await future;
    if (current.isEmpty || current.playerId.isEmpty) return;

    final marketplaceApi = ref.read(marketplaceApiServiceProvider);
    final res = await marketplaceApi.exchange(
      playerId: current.playerId,
      direction: direction,
      amount: amount,
    );

    final next = current.copyWith(
      money: (res['money'] as num?)?.toInt() ?? current.money,
      chips: (res['chips'] as num?)?.toInt() ?? current.chips,
    );
    await _repo.save(next);
    state = AsyncData(next);
  }

  Future<void> buyItem({
    required String itemType,
    required String itemId,
    required String currency,
    required int price,
  }) async {
    final current = await future;
    if (current.isEmpty || current.playerId.isEmpty) return;

    final marketplaceApi = ref.read(marketplaceApiServiceProvider);
    final res = await marketplaceApi.buyItem(
      playerId: current.playerId,
      itemType: itemType,
      itemId: itemId,
      currency: currency,
      price: price,
    );

    final updatedAvatars = itemType == 'avatar'
        ? {...current.ownedAvatars, itemId}.toList()
        : current.ownedAvatars;
    final updatedDecks = itemType == 'deck'
        ? {...current.ownedDecks, itemId}.toList()
        : current.ownedDecks;

    final next = current.copyWith(
      money: (res['money'] as num?)?.toInt() ?? current.money,
      chips: (res['chips'] as num?)?.toInt() ?? current.chips,
      ownedAvatars: updatedAvatars,
      ownedDecks: updatedDecks,
    );
    await _repo.save(next);
    state = AsyncData(next);
  }

  Future<void> claimAdReward() async {
    final current = await future;
    if (current.isEmpty || current.playerId.isEmpty) return;

    final marketplaceApi = ref.read(marketplaceApiServiceProvider);
    final res = await marketplaceApi.claimAdReward(current.playerId);

    final next = current.copyWith(
      money: (res['money'] as num?)?.toInt() ?? (current.money + 50),
    );
    await _repo.save(next);
    state = AsyncData(next);
  }

  Future<void> updateAvatar(String avatarId) async {
    final current = await future;
    if (current.isEmpty && current.playerId.isEmpty) {
      final next = current.copyWith(avatarId: avatarId);
      await _repo.save(next);
      state = AsyncData(next);
      return;
    }

    final next = current.copyWith(avatarId: avatarId);
    await _repo.save(next);
    state = AsyncData(next);
  }

  Future<void> updateProfile({String? name, String? username}) async {
    final current = await future;
    if (current.isEmpty) return;

    final profileApi = ref.read(profileApiServiceProvider);
    final res = await profileApi.updateProfile(
      playerId: current.playerId,
      name: name,
      username: username,
    );

    final next = current.copyWith(
      name: res['name'] as String? ?? (name ?? current.name),
      username: res['username'] as String? ?? (username ?? current.username),
    );
    await _repo.save(next);
    state = AsyncData(next);
  }

  Future<void> clear() async {
    await future;
    await _repo.clear();
    state = const AsyncData(PlayerProfile.empty);

    final analytics = ref.read(analyticsServiceProvider);
    await analytics.setUserId(null);
  }
}

final playerProfileProvider =
    AsyncNotifierProvider<PlayerProfileNotifier, PlayerProfile>(
      PlayerProfileNotifier.new,
    );
