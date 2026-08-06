import 'package:cardgame/app/player_profile_repository.dart';
import 'package:cardgame/app/session_auth_repository.dart';
import 'package:cardgame/app/session_auth_status.dart';
import 'package:cardgame/data/auth/auth_config.dart';
import 'package:cardgame/data/auth/device_identity_service.dart';
import 'package:cardgame/data/auth/google_sign_in_service.dart';
import 'package:cardgame/data/auth/guest_auth_service.dart';
import 'package:cardgame/data/auth/oauth_auth_service.dart';
import 'package:cardgame/data/auth/server_identity.dart';
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
    final next = PlayerProfile(
      playerId: identity.playerId,
      name: identity.name,
      username: identity.username,
      authType: identity.authType,
    );
    state = AsyncData(next);
    await _repo.save(next);
  }

  Future<void> clear() async {
    state = const AsyncData(PlayerProfile.empty);
    await _repo.clear();
  }
}

final playerProfileProvider =
    AsyncNotifierProvider<PlayerProfileNotifier, PlayerProfile>(
      PlayerProfileNotifier.new,
    );
