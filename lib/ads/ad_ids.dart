import 'package:flutter/foundation.dart';

/// AdMob IDs and test/prod resolution.
abstract final class AdIds {
  // Test IDs (Google official sample IDs)
  static const testAndroidAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const testIosAppId = 'ca-app-pub-3940256099942544~1458002511';
  static const testAndroidInterstitial =
      'ca-app-pub-3940256099942544/1033173712';
  static const testIosInterstitial = 'ca-app-pub-3940256099942544/4411468910';
  static const testAndroidRewarded = 'ca-app-pub-3940256099942544/5224354917';
  static const testIosRewarded = 'ca-app-pub-3940256099942544/1712484513';

  // Production IDs
  static const prodAndroidAppId = 'ca-app-pub-9698112281637218~1212411796';
  static const prodIosAppId = 'ca-app-pub-9698112281637218~1212411796';
  static const prodAndroidInterstitial =
      'ca-app-pub-9698112281637218/1397183976';
  static const prodIosInterstitial = 'ca-app-pub-9698112281637218/1397183976';
  // Marketplace "Watch Video Ad" (AdMob daily-reward)
  static const prodAndroidRewarded = 'ca-app-pub-9698112281637218/6328096978';
  static const prodIosRewarded = 'ca-app-pub-9698112281637218/6328096978';

  static bool _forceTestIds = false;

  static void setForceTestIds(bool value) {
    _forceTestIds = value;
  }

  /// True when loading Google test units rather than production inventory.
  static bool get useTestIds {
    if (_forceTestIds) return true;
    const forceTestDefine = bool.fromEnvironment(
      'ADMOB_TEST',
      defaultValue: false,
    );
    if (forceTestDefine) return true;
    const forceProdDefine = bool.fromEnvironment(
      'ADMOB_PROD',
      defaultValue: false,
    );
    if (forceProdDefine) return false;
    return !kReleaseMode;
  }

  /// AdMob only ships native plugins for Android/iOS.
  static bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static String get interstitialUnitId {
    final isIos = defaultTargetPlatform == TargetPlatform.iOS;
    if (useTestIds) {
      return isIos ? testIosInterstitial : testAndroidInterstitial;
    }
    return isIos ? prodIosInterstitial : prodAndroidInterstitial;
  }

  static String get rewardedUnitId {
    final isIos = defaultTargetPlatform == TargetPlatform.iOS;
    if (useTestIds) {
      return isIos ? testIosRewarded : testAndroidRewarded;
    }
    return isIos ? prodIosRewarded : prodAndroidRewarded;
  }
}
