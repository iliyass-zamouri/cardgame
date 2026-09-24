import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final crashlyticsServiceProvider = Provider<CrashlyticsService>((ref) {
  return CrashlyticsService();
});

class CrashlyticsService {
  bool get isAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> enableCollection() async {
    if (!isAvailable) return;
    try {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
        !kDebugMode,
      );
    } catch (e) {
      debugPrint('Crashlytics enable failed: $e');
    }
  }

  Future<void> setUserId(String? userId) async {
    if (!isAvailable) return;
    try {
      await FirebaseCrashlytics.instance.setUserIdentifier(userId ?? '');
    } catch (e) {
      debugPrint('Crashlytics setUserId failed: $e');
    }
  }

  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
  }) async {
    if (!isAvailable) return;
    try {
      await FirebaseCrashlytics.instance.recordError(
        error,
        stack,
        fatal: fatal,
      );
    } catch (e) {
      debugPrint('Crashlytics recordError failed: $e');
    }
  }

  void installFlutterErrorHandlers() {
    if (!isAvailable) return;
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }
}
