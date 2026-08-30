import 'dart:async';

import 'package:cardgame/ads/ad_ids.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

enum RewardedShowResult {
  rewarded,
  dismissed,
  loadFailed,
  showFailed,
  unsupported,
}

final rewardedAdProvider = Provider<RewardedAdService>((ref) {
  final service = RewardedAdService();
  ref.onDispose(service.dispose);
  return service;
});

class RewardedAdService {
  RewardedAd? _ad;
  bool _loading = false;
  bool _showing = false;

  void preload() {
    if (!AdIds.isSupported || _ad != null || _loading) return;
    _loading = true;
    RewardedAd.load(
      adUnitId: AdIds.rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _loading = false;
          _ad = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded ad failed to load: $error');
          _loading = false;
          _ad = null;
        },
      ),
    );
  }

  /// Shows the loaded rewarded ad. Completes with [RewardedShowResult].
  Future<RewardedShowResult> show() async {
    if (!AdIds.isSupported) return RewardedShowResult.unsupported;

    final ad = _ad;
    if (ad == null) {
      preload();
      return RewardedShowResult.loadFailed;
    }
    if (_showing) return RewardedShowResult.showFailed;

    _showing = true;
    _ad = null;
    var userEarnedReward = false;
    final completer = Completer<RewardedShowResult>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _showing = false;
        preload();
        if (!completer.isCompleted) {
          completer.complete(
            userEarnedReward
                ? RewardedShowResult.rewarded
                : RewardedShowResult.dismissed,
          );
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Rewarded ad failed to show: $error');
        ad.dispose();
        _showing = false;
        preload();
        if (!completer.isCompleted) {
          completer.complete(RewardedShowResult.showFailed);
        }
      },
    );

    await ad.show(
      onUserEarnedReward: (ad, reward) {
        userEarnedReward = true;
      },
    );

    return completer.future;
  }

  void dispose() {
    _ad?.dispose();
    _ad = null;
  }
}
