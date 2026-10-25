import 'dart:async';
import 'dart:math' as math;

import 'package:cardgame/app/auth_providers.dart';
import 'package:cardgame/app/boost_providers.dart';
import 'package:cardgame/data/auth/auth_config.dart';
import 'package:cardgame/data/daily_reward/daily_reward_api.dart';
import 'package:cardgame/data/daily_reward/daily_reward_models.dart';
import 'package:cardgame/trailer/trailer_mode.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dailyRewardApiProvider = Provider<DailyRewardApi>((ref) {
  return DailyRewardApi(baseUrl: httpBaseUrl);
});

/// Monotonic time for streak countdowns. They run from what the server said
/// when it answered, never from the device clock, which players can change.
final Stopwatch _monotonic = Stopwatch()..start();

Duration dailyRewardClock() => _monotonic.elapsed;

/// The streak as last fetched, with when it arrived on [dailyRewardClock].
class DailyRewardView {
  const DailyRewardView(this.status, this.receivedAt);

  final DailyRewardStatus status;
  final Duration receivedAt;

  /// Seconds until the next claim opens, counted down from the answer.
  int secondsUntilNextClaim() {
    final elapsed = (dailyRewardClock() - receivedAt).inSeconds;
    return math.max(0, status.secondsUntilNextClaim - elapsed);
  }
}

int _tzOffsetMinutes() => DateTime.now().timeZoneOffset.inMinutes;

/// The 7-day streak for the signed-in player: fetched at sign-in, again when
/// the app comes back after a while (the day may have turned), and when a
/// countdown runs out. Null while signed out.
class DailyRewardController extends AsyncNotifier<DailyRewardView?> {
  static const _resumeGap = Duration(seconds: 60);

  AppLifecycleListener? _lifecycle;
  Duration? _lastFetch;

  @override
  Future<DailyRewardView?> build() async {
    final auth = ref.watch(playerAuthProvider);
    _listenForResume();
    ref.onDispose(() {
      _lifecycle?.dispose();
      _lifecycle = null;
    });
    if (auth.playerId.isEmpty || TrailerMode.enabled) return null;
    return _fetch(auth);
  }

  Future<DailyRewardView> _fetch(PlayerAuth auth) async {
    _lastFetch = dailyRewardClock();
    final status = await ref
        .read(dailyRewardApiProvider)
        .fetchStatus(
          tzOffsetMinutes: _tzOffsetMinutes(),
          accessToken: auth.accessToken,
        );
    return DailyRewardView(status, dailyRewardClock());
  }

  /// Refetches; a failure keeps what is already shown.
  Future<void> refresh() async {
    final auth = ref.read(playerAuthProvider);
    if (auth.playerId.isEmpty) return;
    try {
      final view = await _fetch(auth);
      if (ref.mounted) state = AsyncData(view);
    } catch (error, stack) {
      if (ref.mounted && state.value == null) state = AsyncError(error, stack);
    }
  }

  /// Claims the day's reward. Balances are left to the caller: the modal
  /// applies them when its coins land in the top bar.
  Future<DailyClaimResult> claim({
    bool boosted = false,
    StreakChoice? choice,
  }) async {
    final auth = ref.read(playerAuthProvider);
    final result = await ref
        .read(dailyRewardApiProvider)
        .claim(
          tzOffsetMinutes: _tzOffsetMinutes(),
          boosted: boosted,
          choice: choice,
          accessToken: auth.accessToken,
        );
    _adopt(result.status);
    return result;
  }

  Future<DailyClaimResult> claimComeback() async {
    final auth = ref.read(playerAuthProvider);
    final result = await ref
        .read(dailyRewardApiProvider)
        .claimComeback(
          tzOffsetMinutes: _tzOffsetMinutes(),
          accessToken: auth.accessToken,
        );
    _adopt(result.status);
    return result;
  }

  void _adopt(DailyRewardStatus? status) {
    // A claim may have added a boost to the player's boosts.
    unawaited(ref.read(boostProvider.notifier).refresh());
    if (status == null || !ref.mounted) return;
    _lastFetch = dailyRewardClock();
    state = AsyncData(DailyRewardView(status, dailyRewardClock()));
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

final dailyRewardProvider =
    AsyncNotifierProvider<DailyRewardController, DailyRewardView?>(
      DailyRewardController.new,
    );
