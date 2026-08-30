import 'dart:async';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appTrackingServiceProvider = Provider<AppTrackingService>((ref) {
  return AppTrackingService();
});

class AppTrackingService {
  /// Requests App Tracking Transparency permission if on iOS 14+.
  /// Safe to call on any platform (no-op on Android / web / desktop).
  Future<TrackingStatus> requestTrackingAuthorization() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      return TrackingStatus.notSupported;
    }

    try {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        // Short delay helps ensure UI is rendered before system prompt displays.
        await Future.delayed(const Duration(milliseconds: 200));
        return await AppTrackingTransparency.requestTrackingAuthorization();
      }
      return status;
    } catch (e) {
      debugPrint('App tracking authorization request failed: $e');
      return TrackingStatus.notSupported;
    }
  }

  Future<TrackingStatus> getTrackingAuthorizationStatus() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      return TrackingStatus.notSupported;
    }
    try {
      return await AppTrackingTransparency.trackingAuthorizationStatus;
    } catch (_) {
      return TrackingStatus.notSupported;
    }
  }
}
