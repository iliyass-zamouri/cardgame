import 'package:flutter/foundation.dart';

/// AdMob IDs. Replace with real units before release.
/// Current values are Google's official test IDs.
abstract final class AdIds {
  static const androidAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const iosAppId = 'ca-app-pub-3940256099942544~1458002511';

  static const _androidInterstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const _iosInterstitial = 'ca-app-pub-3940256099942544/4411468910';

  /// AdMob only ships native plugins for Android/iOS.
  static bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static String get interstitialUnitId {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _iosInterstitial;
    }
    return _androidInterstitial;
  }
}
