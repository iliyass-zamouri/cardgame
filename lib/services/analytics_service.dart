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

  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      await analytics?.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );
    } catch (e) {
      debugPrint('Analytics logScreenView error: $e');
    }
  }

  Future<void> logLogin({String? loginMethod}) async {
    try {
      await analytics?.logLogin(loginMethod: loginMethod);
    } catch (e) {
      debugPrint('Analytics logLogin error: $e');
    }
  }

  Future<void> logSignUp({required String signUpMethod}) async {
    try {
      await analytics?.logSignUp(signUpMethod: signUpMethod);
    } catch (e) {
      debugPrint('Analytics logSignUp error: $e');
    }
  }

  Future<void> setUserId(String? userId) async {
    try {
      await analytics?.setUserId(id: userId);
    } catch (e) {
      debugPrint('Analytics setUserId error: $e');
    }
  }

  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    try {
      await analytics?.setUserProperty(name: name, value: value);
    } catch (e) {
      debugPrint('Analytics setUserProperty error: $e');
    }
  }

  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    try {
      await analytics?.logEvent(name: name, parameters: parameters);
    } catch (e) {
      debugPrint('Analytics logEvent ($name) error: $e');
    }
  }
}
