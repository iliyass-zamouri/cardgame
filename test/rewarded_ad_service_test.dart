import 'dart:async';

import 'package:cardgame/ads/rewarded_ad_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Stands in for a loaded ad. The methods the service awaits are overridden
/// with no-ops; anything else returns null instead of reaching the platform.
class _FakeRewardedAd implements RewardedAd {
  @override
  Future<void> dispose() async {}

  @override
  Future<void> show({
    required OnUserEarnedRewardCallback onUserEarnedReward,
  }) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _ThrowingAd extends _FakeRewardedAd {
  @override
  Future<void> show({
    required OnUserEarnedRewardCallback onUserEarnedReward,
  }) async => throw StateError('no ad to show');
}

void main() {
  late List<RewardedAdLoadCallback> requests;
  late RewardedAdService service;

  setUp(() {
    // Ads only load on Android and iOS, so pin the platform for the host.
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    requests = [];
    service = RewardedAdService(
      load: ({
        required String adUnitId,
        required AdRequest request,
        required RewardedAdLoadCallback rewardedAdLoadCallback,
      }) async {
        requests.add(rewardedAdLoadCallback);
      },
    );
    addTearDown(() {
      service.dispose();
      debugDefaultTargetPlatformOverride = null;
    });
  });

  test('is not ready until an ad loads, and asks for one ad at a time', () {
    expect(service.ready.value, isFalse);
    service.preload();
    service.preload();
    expect(requests, hasLength(1));
    expect(service.ready.value, isFalse);
  });

  test('becomes ready when the ad loads', () {
    service.preload();
    requests.single.onAdLoaded(_FakeRewardedAd());
    expect(service.ready.value, isTrue);
  });

  test('stays not ready when the load fails', () {
    service.preload();
    requests.single.onAdFailedToLoad(LoadAdError(3, 'test', 'No fill', null));
    expect(service.ready.value, isFalse);
  });

  test('is not ready while its ad is playing', () {
    service.preload();
    requests.single.onAdLoaded(_FakeRewardedAd());
    unawaited(service.show());
    expect(service.ready.value, isFalse);
  });

  test('a throwing show frees the slot and asks for the next ad', () async {
    service.preload();
    requests.single.onAdLoaded(_ThrowingAd());
    expect(await service.show(), RewardedShowResult.showFailed);
    expect(service.ready.value, isFalse);
    expect(requests, hasLength(2));
  });
}
