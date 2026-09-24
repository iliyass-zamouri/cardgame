import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

class AnalyticsService {
  FirebaseAnalytics? _analytics;
  bool _initialized = false;

  void initialize() {
    if (_initialized) return;
    try {
      if (Firebase.apps.isNotEmpty) {
        _analytics = FirebaseAnalytics.instance;
      }
    } catch (e) {
      debugPrint('Firebase Analytics initialization skipped: $e');
    }
    _initialized = true;
  }

  FirebaseAnalytics? get analytics {
    if (!_initialized) initialize();
    return _analytics;
  }

  FirebaseAnalyticsObserver? get observer {
    final a = analytics;
    return a != null ? FirebaseAnalyticsObserver(analytics: a) : null;
  }

  Future<void> _run(Future<void> Function(FirebaseAnalytics fa) fn) async {
    final fa = analytics;
    if (fa == null) return;
    try {
      await fn(fa);
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    await _run(
      (fa) => fa.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      ),
    );
  }

  Future<void> logLogin({String? loginMethod}) async {
    await _run((fa) => fa.logLogin(loginMethod: loginMethod));
  }

  Future<void> logLoginFailed({
    required String method,
    String? reason,
  }) async {
    await logEvent(
      name: 'login_failed',
      parameters: {
        'method': method,
        if (reason != null) 'reason': reason,
      },
    );
  }

  Future<void> logSignUp({required String signUpMethod}) async {
    await _run((fa) => fa.logSignUp(signUpMethod: signUpMethod));
  }

  Future<void> logSignOut() async {
    await logEvent(name: 'sign_out');
  }

  Future<void> setUserId(String? userId) async {
    await _run((fa) => fa.setUserId(id: userId));
  }

  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    await _run((fa) => fa.setUserProperty(name: name, value: value));
  }

  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    await _run((fa) => fa.logEvent(name: name, parameters: parameters));
  }

  Future<void> matchStart({
    required bool online,
    String? mode,
  }) async {
    await logEvent(
      name: 'match_start',
      parameters: {
        'online': online ? 1 : 0,
        if (mode != null) 'mode': mode,
      },
    );
  }

  Future<void> matchEnd({
    required bool online,
    required bool won,
    String? mode,
  }) async {
    await logEvent(
      name: 'match_end',
      parameters: {
        'online': online ? 1 : 0,
        'won': won ? 1 : 0,
        if (mode != null) 'mode': mode,
      },
    );
  }

  Future<void> matchQuit({required bool online}) async {
    await logEvent(
      name: 'match_quit',
      parameters: {'online': online ? 1 : 0},
    );
  }

  Future<void> friendAction({required String action}) async {
    await logEvent(name: 'friend_action', parameters: {'action': action});
  }

  Future<void> inviteAction({required String action}) async {
    await logEvent(name: 'invite_action', parameters: {'action': action});
  }

  Future<void> pushPermission({required String result}) async {
    await logEvent(name: 'push_permission', parameters: {'result': result});
  }

  Future<void> shopBuy({required String itemId, String? currency}) async {
    await logEvent(
      name: 'shop_buy',
      parameters: {
        'item_id': itemId,
        if (currency != null) 'currency': currency,
      },
    );
  }

  Future<void> rewardedAd({required String result}) async {
    await logEvent(name: 'rewarded_ad', parameters: {'result': result});
  }

  Future<void> interstitialAd({required String result}) async {
    await logEvent(name: 'interstitial_ad', parameters: {'result': result});
  }
}
