import 'dart:async';
import 'dart:math' as math;

import 'package:cardgame/app/auth_providers.dart';
import 'package:cardgame/app/daily_reward_providers.dart';
import 'package:cardgame/data/auth/auth_config.dart';
import 'package:cardgame/data/boost/boost_api.dart';
import 'package:cardgame/data/boost/boost_models.dart';
import 'package:cardgame/trailer/trailer_mode.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final boostApiProvider = Provider<BoostApi>((ref) {
  return BoostApi(baseUrl: httpBaseUrl);
});

/// The boosts as last fetched, with when they arrived on [dailyRewardClock].
class BoostView {
  const BoostView(this.state, this.receivedAt);

  final BoostState state;
  final Duration receivedAt;

  /// Seconds the running boost has left, counted down from the answer, never
  /// from the device clock. 0 when none runs or it has ended.
  int remainingSeconds() {
    final active = state.active;
    if (active == null) return 0;
    final elapsed = (dailyRewardClock() - receivedAt).inSeconds;
    return math.max(0, active.remainingSeconds - elapsed);
  }

  /// The running boost, or null once its time is up.
  ActiveBoost? get running => remainingSeconds() > 0 ? state.active : null;
}

/// The signed-in player's Coin Boosts: fetched at sign-in, after claims and
/// matches, and when the app comes back. Null while signed out.
class BoostController extends AsyncNotifier<BoostView?> {
  static const _resumeGap = Duration(seconds: 60);

  AppLifecycleListener? _lifecycle;
  Duration? _lastFetch;

  @override
  Future<BoostView?> build() async {
    final auth = ref.watch(playerAuthProvider);
    _listenForResume();
    ref.onDispose(() {
      _lifecycle?.dispose();
      _lifecycle = null;
    });
    if (auth.playerId.isEmpty || TrailerMode.enabled) return null;
    return _fetch(auth);
  }

  Future<BoostView> _fetch(PlayerAuth auth) async {
    _lastFetch = dailyRewardClock();
    final state = await ref
        .read(boostApiProvider)
        .fetch(accessToken: auth.accessToken);
    return BoostView(state, dailyRewardClock());
  }

  /// Refetches; a failure keeps what is already shown.
  Future<void> refresh() async {
    final auth = ref.read(playerAuthProvider);
    if (auth.playerId.isEmpty || TrailerMode.enabled) return;
    try {
      final view = await _fetch(auth);
      if (ref.mounted) state = AsyncData(view);
    } catch (error, stack) {
      if (ref.mounted && state.value == null) state = AsyncError(error, stack);
    }
  }

  /// Activates one waiting boost. A refusal still shows the boosts as the
  /// server has them, so the sheet can say which boost is in the way.
  Future<BoostActivation> activate(String itemId) async {
    final auth = ref.read(playerAuthProvider);
    try {
      final result = await ref
          .read(boostApiProvider)
          .activate(itemId: itemId, accessToken: auth.accessToken);
      _adopt(result.state);
      return result;
    } on BoostApiException catch (error) {
      if (error.state != null) _adopt(error.state!);
      rethrow;
    }
  }

  void _adopt(BoostState boosts) {
    if (!ref.mounted) return;
    _lastFetch = dailyRewardClock();
    state = AsyncData(BoostView(boosts, dailyRewardClock()));
  }

  void _listenForResume() {
    if (_lifecycle != null) return;
    try {
      _lifecycle = AppLifecycleListener(
        onResume: () {
          final last = _lastFetch;
          if (last == null || dailyRewardClock() - last > _resumeGap) {
            unawaited(refresh());
          }
        },
      );
    } catch (_) {
      // No widgets binding (plain unit tests): fetches still run on demand.
    }
  }
}

final boostProvider = AsyncNotifierProvider<BoostController, BoostView?>(
  BoostController.new,
);
