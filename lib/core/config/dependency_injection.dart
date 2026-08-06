import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../config/server_config.dart';
import '../network/api_client.dart';
import '../network/socket_client.dart';

final serverConfigProvider = Provider<ServerConfig>((ref) {
  return ServerConfig.fromEnvironment();
});

final sharedPrefsProvider = FutureProvider<SharedPreferences>((ref) {
  return SharedPreferences.getInstance();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(serverConfigProvider));
});

final socketClientProvider = Provider<SocketClient>((ref) {
  final config = ref.watch(serverConfigProvider);
  if (!config.onlineMp) return NoopSocketClient();
  return WsSocketClient(config);
});

class SessionState {
  const SessionState({
    this.token,
    this.playerId,
    this.displayName,
    this.coins = 0,
    this.gems = 0,
    this.loading = false,
    this.error,
  });

  final String? token;
  final String? playerId;
  final String? displayName;
  final int coins;
  final int gems;
  final bool loading;
  final String? error;

  bool get isAuthenticated => token != null && playerId != null;

  SessionState copyWith({
    String? token,
    String? playerId,
    String? displayName,
    int? coins,
    int? gems,
    bool? loading,
    String? error,
  }) {
    return SessionState(
      token: token ?? this.token,
      playerId: playerId ?? this.playerId,
      displayName: displayName ?? this.displayName,
      coins: coins ?? this.coins,
      gems: gems ?? this.gems,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class SessionController extends StateNotifier<SessionState> {
  SessionController(this._api, this._prefs) : super(const SessionState());

  final ApiClient _api;
  final SharedPreferences _prefs;

  Future<void> restore() async {
    final token = _prefs.getString('token');
    final playerId = _prefs.getString('playerId');
    final name = _prefs.getString('displayName');
    if (token == null || playerId == null) return;
    _api.setToken(token);
    state = state.copyWith(
      token: token,
      playerId: playerId,
      displayName: name,
    );
  }

  Future<void> signInGuest() async {
    state = state.copyWith(loading: true, error: null);
    try {
      var deviceId = _prefs.getString('deviceId');
      deviceId ??= const Uuid().v4();
      await _prefs.setString('deviceId', deviceId);
      final res = await _api.post('/auth/guest', body: {
        'deviceId': deviceId,
        'displayName': 'Operative',
      });
      await _applyAuth(res);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> signInGoogle() async {
    await _signInOAuth('google', 'google-dev-${const Uuid().v4()}');
  }

  Future<void> signInApple() async {
    await _signInOAuth('apple', 'apple-dev-${const Uuid().v4()}');
  }

  Future<void> _signInOAuth(String provider, String subject) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final res = await _api.post('/auth/$provider', body: {
        'providerSubject': subject,
        'displayName': provider == 'google' ? 'Google Player' : 'Apple Player',
      });
      await _applyAuth(res);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> _applyAuth(Map<String, dynamic> res) async {
    final token = res['token'] as String;
    final player = Map<String, dynamic>.from(res['player'] as Map);
    _api.setToken(token);
    await _prefs.setString('token', token);
    await _prefs.setString('playerId', player['playerId'] as String);
    await _prefs.setString('displayName', player['displayName'] as String? ?? '');
    state = SessionState(
      token: token,
      playerId: player['playerId'] as String,
      displayName: player['displayName'] as String?,
      coins: (player['coins'] as num?)?.toInt() ?? 0,
      gems: (player['gems'] as num?)?.toInt() ?? 0,
    );
  }

  Future<void> signOut() async {
    await _prefs.remove('token');
    await _prefs.remove('playerId');
    _api.setToken(null);
    state = const SessionState();
  }
}

final sessionProvider =
    StateNotifierProvider<SessionController, SessionState>((ref) {
  throw UnimplementedError('Override in dependency_injection');
});
