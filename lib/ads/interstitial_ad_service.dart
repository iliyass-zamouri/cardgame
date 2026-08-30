import 'dart:async';

import 'package:cardgame/ads/ad_ids.dart';
import 'package:cardgame/core/monetization/purchases_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

final interstitialAdProvider = Provider<InterstitialAdService>((ref) {
  final service = InterstitialAdService(isPro: () => ref.read(isProProvider));
  ref.onDispose(service.dispose);
  return service;
});

class InterstitialAdService {
  InterstitialAdService({bool Function()? isPro}) : _isPro = isPro;

  final bool Function()? _isPro;
  InterstitialAd? _ad;
  bool _loading = false;
  bool _showing = false;

  void preload() {
    if (_isPro?.call() == true) return;
    if (!AdIds.isSupported || _ad != null || _loading) return;
    _loading = true;
    InterstitialAd.load(
      adUnitId: AdIds.interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loading = false;
          _ad = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial failed to load: $error');
          _loading = false;
          _ad = null;
        },
      ),
    );
  }

  /// Shows interstitial if ready. Completes on dismiss/fail/nothing loaded.
  Future<void> show() async {
    if (_isPro?.call() == true) return;
    if (!AdIds.isSupported) return;
    final ad = _ad;
    if (ad == null || _showing) return;

    _showing = true;
    _ad = null;
    final completer = Completer<void>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _showing = false;
        if (!completer.isCompleted) completer.complete();
        preload();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Interstitial failed to show: $error');
        ad.dispose();
        _showing = false;
        if (!completer.isCompleted) completer.complete();
        preload();
      },
    );

    await ad.show();
    return completer.future;
  }

  void dispose() {
    _ad?.dispose();
    _ad = null;
  }
}
