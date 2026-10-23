import 'dart:async';

import 'package:cardgame/ads/ad_ids.dart';
import 'package:cardgame/trailer/trailer_mode.dart';
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

/// Matches [RewardedAd.load]. Injectable so tests can drive the callbacks.
typedef RewardedAdLoader =
    Future<void> Function({
      required String adUnitId,
      required AdRequest request,
      required RewardedAdLoadCallback rewardedAdLoadCallback,
    });

final rewardedAdProvider = Provider<RewardedAdService>((ref) {
  final service = RewardedAdService();
  ref.onDispose(service.dispose);
  return service;
});

class RewardedAdService {
  RewardedAdService({RewardedAdLoader load = RewardedAd.load}) : _load = load;

  final RewardedAdLoader _load;
  final _ready = ValueNotifier<bool>(false);
  RewardedAd? _ad;
  bool _loading = false;
  bool _showing = false;
  bool _disposed = false;
  int _retries = 0;
  Timer? _retryTimer;
  DateTime? _lastFailureAt;

  /// True while an ad is loaded and [show] can play it. The watch button is
  /// greyed out while this is false.
  ValueListenable<bool> get ready => _ready;

  /// AdMob throttles ad units that fail repeatedly ("Too many recently failed
  /// requests"), so never re-request right after a failure.
  static const _failureCooldown = Duration(seconds: 20);

  void preload() {
    if (TrailerMode.enabled) return;
    if (!AdIds.isSupported || _ad != null || _loading) return;
    final failedAt = _lastFailureAt;
    if (failedAt != null &&
        DateTime.now().difference(failedAt) < _failureCooldown) {
      return;
    }
    _loading = true;
    _load(
      adUnitId: AdIds.rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _loading = false;
          _retries = 0;
          _lastFailureAt = null;
          _setAd(ad);
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded ad failed to load: $error');
          _loadFailed();
        },
      ),
    ).catchError((Object error) {
      debugPrint('Rewarded ad request failed: $error');
      _loadFailed();
    });
  }

  void _loadFailed() {
    _loading = false;
    _lastFailureAt = DateTime.now();
    _setAd(null);
    if (_retries < 3) {
      final delay = Duration(seconds: 30 * (1 << _retries++));
      _retryTimer?.cancel();
      _retryTimer = Timer(delay, preload);
    }
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
    _setAd(null);
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

    try {
      await ad.show(
        onUserEarnedReward: (ad, reward) {
          userEarnedReward = true;
        },
      );
    } catch (error) {
      // Free the slot here too, or the button would stay greyed out for good.
      debugPrint('Rewarded ad failed to show: $error');
      ad.dispose();
      _showing = false;
      preload();
      return RewardedShowResult.showFailed;
    }

    return completer.future;
  }

  void dispose() {
    _disposed = true;
    _retryTimer?.cancel();
    _ad?.dispose();
    _ad = null;
    _ready.dispose();
  }

  void _setAd(RewardedAd? ad) {
    _ad = ad;
    if (!_disposed) _ready.value = ad != null;
  }
}
