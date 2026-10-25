import 'dart:async';
import 'dart:math' as math;

import 'package:cardgame/ads/rewarded_ad_service.dart';
import 'package:cardgame/app/app_review_providers.dart';
import 'package:cardgame/app/auth_providers.dart';
import 'package:cardgame/app/boost_providers.dart';
import 'package:cardgame/app/daily_reward_providers.dart';
import 'package:cardgame/data/app_review/app_review_models.dart';
import 'package:cardgame/data/avatars/avatar_catalog.dart';
import 'package:cardgame/data/daily_reward/daily_reward_api.dart';
import 'package:cardgame/data/daily_reward/daily_reward_models.dart';
import 'package:cardgame/data/decks/deck_catalog.dart';
import 'package:cardgame/l10n/l10n_ext.dart';
import 'package:cardgame/services/analytics_service.dart';
import 'package:cardgame/services/sfx_service.dart';
import 'package:cardgame/ui/screens/daily_reward/claim_celebration.dart';
import 'package:cardgame/ui/screens/daily_reward/comeback_modal.dart';
import 'package:cardgame/ui/screens/daily_reward/reward_art.dart';
import 'package:cardgame/ui/screens/daily_reward/reward_shell.dart';
import 'package:cardgame/ui/screens/daily_reward/streak_card.dart';
import 'package:cardgame/ui/screens/daily_reward/streak_countdown.dart';
import 'package:cardgame/ui/theme/app_icons.dart';
import 'package:cardgame/ui/theme/casino_chrome.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/theme/felt_chrome.dart';
import 'package:cardgame/ui/theme/game_icon.dart';
import 'package:cardgame/ui/widgets/currency_icon.dart';
import 'package:cardgame/ui/widgets/insufficient_funds_sheet.dart';
import 'package:cardgame/ui/widgets/reward_fly_overlay.dart';
import 'package:cardgame/ui/widgets/suit_card_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the 7-day streak. [source] is logged: 'launch' or 'home'.
Future<void> showDailyRewardModal(
  BuildContext context, {
  required String source,
}) {
  return showRewardDialog<void>(
    context,
    builder: (_) => DailyRewardModal(source: source),
  );
}

/// Navigator [openDailyRewards] is showing in, so the launch prompt and a
/// notification tap can't stack two streaks. A navigator torn down mid-show
/// no longer counts.
NavigatorState? _dailyRewardsShownIn;

/// The welcome-back gift first when there is one, then the streak if a claim
/// is waiting.
Future<void> openDailyRewards(
  BuildContext context,
  WidgetRef ref, {
  required String source,
}) async {
  if (_dailyRewardsShownIn?.mounted ?? false) return;
  final navigator = Navigator.of(context, rootNavigator: true);
  _dailyRewardsShownIn = navigator;
  final stateBefore = ref.read(dailyRewardProvider).value?.status.state;
  try {
    await _openDailyRewards(context, ref, source: source);
  } finally {
    if (identical(_dailyRewardsShownIn, navigator)) _dailyRewardsShownIn = null;
  }
  // Just claimed: a good moment to ask for a rating.
  final stateAfter = ref.read(dailyRewardProvider).value?.status.state;
  if (stateBefore != DailyRewardState.claimed &&
      stateAfter == DailyRewardState.claimed &&
      context.mounted) {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!context.mounted) return;
    await ref
        .read(appReviewControllerProvider)
        .maybePrompt(context, AppReviewTrigger.daily);
  }
}

Future<void> _openDailyRewards(
  BuildContext context,
  WidgetRef ref, {
  required String source,
}) async {
  final status = ref.read(dailyRewardProvider).value?.status;
  if (status == null || !status.enabled) return;
  if (status.comebackAvailable) {
    await showComebackModal(context);
    if (!context.mounted) return;
    final latest = ref.read(dailyRewardProvider).value?.status;
    final waiting =
        latest != null &&
        (latest.state == DailyRewardState.claimable ||
            latest.state == DailyRewardState.broken);
    // Opened from home, the streak follows either way; at launch only if a claim waits.
    if (!waiting && source == 'launch') return;
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!context.mounted) return;
  }
  await showDailyRewardModal(context, source: source);
}

/// The streak: seven playing cards dealt onto a felt table, today's lifted
/// and glowing, the jackpot spread wide at the bottom. Claiming plays the
/// reveal, flies the coins into the top bar, then turns today's card over
/// and seals it.
class DailyRewardModal extends ConsumerStatefulWidget {
  const DailyRewardModal({super.key, required this.source});

  final String source;

  @override
  ConsumerState<DailyRewardModal> createState() => _DailyRewardModalState();
}

class _DailyRewardModalState extends ConsumerState<DailyRewardModal>
    with TickerProviderStateMixin {
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );
  late final AnimationController _deal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  late final AnimationController _lift = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  late final AnimationController _settle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );

  // Read in initState: they are still needed in dispose, when ref is gone.
  late final PlayerProfileNotifier _profile;
  late final AnalyticsService _analytics;

  bool _busy = false;
  bool _logged = false;
  bool _closing = false;

  /// The card lifted while its claim is on the way.
  int? _claimingDay;

  /// The card turning over and taking its seal after the reveal.
  int? _settlingDay;

  /// A claim being revealed.
  DailyClaimResult? _celebrating;

  /// A claim whose balances have not reached the profile yet.
  DailyClaimResult? _unapplied;

  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  @override
  void initState() {
    super.initState();
    _profile = ref.read(playerProfileProvider.notifier);
    _analytics = ref.read(analyticsServiceProvider);
    ref.read(rewardedAdProvider).preload();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reduceMotion) {
      _ambient.stop();
      _deal.value = 1;
    } else {
      if (!_ambient.isAnimating) _ambient.repeat();
      if (_deal.value == 0 && !_deal.isAnimating) _deal.forward();
    }
  }

  @override
  void dispose() {
    // Never lose a payout because the modal closed mid-reveal.
    _applyGrant();
    _ambient.dispose();
    _deal.dispose();
    _lift.dispose();
    _settle.dispose();
    super.dispose();
  }

  void _applyGrant() {
    final result = _unapplied;
    if (result == null) return;
    _unapplied = null;
    unawaited(
      _profile.applyServerGrant(
        money: result.money,
        chips: result.chips,
        ownedAvatars: result.ownedAvatars,
        ownedDecks: result.ownedDecks,
      ),
    );
  }

  void _logView(DailyRewardStatus status) {
    if (_logged) return;
    _logged = true;
    unawaited(
      _analytics.dailyReward(
        action: 'view',
        parameters: {
          'source': widget.source,
          'state': status.state.name,
          'day': status.nextDay,
        },
      ),
    );
  }

  void _close() {
    if (_busy || _closing) return;
    _closing = true;
    Navigator.of(context).maybePop();
  }

  void _endClaim() {
    if (!mounted) return;
    if (!_reduceMotion) unawaited(_lift.reverse());
    setState(() {
      _busy = false;
      _claimingDay = null;
    });
  }

  Future<void> _claim({bool boosted = false, StreakChoice? choice}) async {
    final status = ref.read(dailyRewardProvider).value?.status;
    if (_busy || status == null) return;
    final l10n = context.l10n;
    setState(() {
      _busy = true;
      _claimingDay = choice == StreakChoice.restart ? 1 : status.nextDay;
    });
    unawaited(HapticFeedback.mediumImpact());
    if (!_reduceMotion) unawaited(_lift.forward());
    try {
      final result = await ref
          .read(dailyRewardProvider.notifier)
          .claim(boosted: boosted, choice: choice);
      _unapplied = result;
      unawaited(
        _analytics.dailyReward(
          action: choice?.name ?? 'claim',
          parameters: {
            'day': result.day ?? 0,
            'boosted': result.boosted ? 1 : 0,
            'streak': result.streakCount ?? 0,
            if (result.chipsSpent > 0) 'chips': result.chipsSpent,
          },
        ),
      );
      if (!mounted) return;
      if (result.alreadyClaimed || result.granted.isEmpty) {
        _applyGrant();
        _endClaim();
        return;
      }
      _lift.value = 0;
      _settle.value = 0;
      setState(() {
        _celebrating = result;
        _settlingDay = result.day;
        _claimingDay = null;
      });
    } on DailyRewardApiException catch (error) {
      _endClaim();
      if (!mounted) return;
      switch (error.code) {
        case 'streak_broken':
          unawaited(ref.read(dailyRewardProvider.notifier).refresh());
        case 'insufficient_funds':
          await _topUpThenRescue(status.rescueChipCost);
        case 'daily_disabled':
          _close();
        default:
          CasinoToast.show(context, l10n.dailyClaimFailed, success: false);
      }
    } catch (_) {
      _endClaim();
      if (mounted) {
        CasinoToast.show(context, l10n.dailyClaimFailed, success: false);
      }
    }
  }

  Future<void> _rescue(DailyRewardStatus status) async {
    final chips = ref.read(playerProfileProvider).value?.chips ?? 0;
    if (chips < status.rescueChipCost) {
      await _topUpThenRescue(status.rescueChipCost);
      return;
    }
    await _claim(choice: StreakChoice.rescue);
  }

  Future<void> _topUpThenRescue(int cost) async {
    final covered = await InsufficientFundsSheet.show(
      context,
      required: cost,
      currency: CurrencyType.chips,
    );
    if (covered && mounted) await _claim(choice: StreakChoice.rescue);
  }

  Future<void> _claimDoubled() async {
    if (_busy) return;
    final l10n = context.l10n;
    unawaited(
      _analytics.dailyReward(action: 'ad', parameters: {'result': 'start'}),
    );
    final shown = await ref.read(rewardedAdProvider).show();
    unawaited(
      _analytics.dailyReward(action: 'ad', parameters: {'result': shown.name}),
    );
    if (!mounted) return;
    if (shown == RewardedShowResult.rewarded) {
      await _claim(boosted: true);
    } else if (shown != RewardedShowResult.dismissed) {
      CasinoToast.show(context, l10n.adNotAvailable, success: false);
    }
  }

  /// The reveal's "Collect": fly each currency into the top bar (its counter
  /// starts counting as the first coin lands), then turn the card over.
  Future<void> _collect(Map<CurrencyType, Offset> origins) async {
    final result = _celebrating;
    if (result == null) return;
    var landed = false;
    void land() {
      if (landed) return;
      landed = true;
      _applyGrant();
    }

    final flights = <Future<void>>[];
    for (final currency in CurrencyType.values) {
      final amount = result.granted.fold<int>(
        0,
        (sum, grant) => sum + grant.amountOf(currency),
      );
      final from = origins[currency];
      if (amount <= 0 || from == null) continue;
      flights.add(
        flyRewardToHud(
          context,
          currency: currency,
          from: from,
          amount: amount,
          count: currency == CurrencyType.chips ? 5 : 9,
          onLand: land,
        ),
      );
    }
    if (flights.isEmpty) land();

    setState(() => _celebrating = null);
    if (_reduceMotion) {
      _settle.value = 1;
    } else {
      SfxService.instance.flip();
      Timer(const Duration(milliseconds: 560), () {
        if (mounted) HapticFeedback.lightImpact();
      });
      await _settle.forward(from: 0);
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _settlingDay = null;
    });
  }

  void _equip(RewardItem item) {
    switch (item) {
      case AvatarReward(:final itemId):
        unawaited(_profile.updateAvatar(itemId));
      case DeckReward(:final itemId):
        unawaited(_profile.updateDeck(itemId));
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final languageCode = Localizations.localeOf(context).languageCode;
    final async = ref.watch(dailyRewardProvider);
    final view = async.value;
    final status = view?.status;
    if (status != null) {
      if (status.enabled) {
        _logView(status);
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) => _close());
      }
    }
    final title =
        status != null && status.isEvent
            ? localizedTitle(status.calendarTitles, languageCode) ??
                l10n.dailyStreakTitle
            : l10n.dailyStreakTitle;
    final celebrating = _celebrating;

    return PopScope(
      canPop: !_busy,
      child: Stack(
        fit: StackFit.expand,
        children: [
          RewardPanel(
            title: title,
            onClose: _busy ? null : _close,
            child:
                view == null || status == null || !status.enabled
                    ? _LoadingOrError(
                      failed: async.hasError,
                      onRetry:
                          () =>
                              ref.read(dailyRewardProvider.notifier).refresh(),
                    )
                    : _body(view),
          ),
          if (celebrating != null)
            Positioned.fill(
              child: ClaimCelebration(
                title:
                    (celebrating.day ?? 0) == 7
                        ? l10n.dailyJackpotWon
                        : l10n.dailyDayReward(
                          celebrating.day ?? status?.nextDay ?? 1,
                        ),
                granted: celebrating.granted,
                jackpot: celebrating.day == 7,
                chests: (celebrating.status ?? status)?.chests ?? const {},
                boostMultiplier:
                    celebrating.boosted ? status?.adBoostMultiplier : null,
                boostPresets:
                    (celebrating.status ?? status)?.boostPresets ?? const {},
                onCollect: _collect,
                onEquip: _equip,
              ),
            ),
        ],
      ),
    );
  }

  Widget _body(DailyRewardView view) {
    final status = view.status;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: _StreakHeader(
            view: view,
            ambient: _ambient,
            onCountdownDone:
                () => ref.read(dailyRewardProvider.notifier).refresh(),
          ),
        ),
        _Notices(status: status),
        const SizedBox(height: 10),
        Flexible(
          child: FeltInset(
            child: AnimatedBuilder(
              animation: Listenable.merge([_deal, _lift, _settle]),
              builder: (context, _) => _table(status),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _actions(view),
      ],
    );
  }

  Widget _table(DailyRewardStatus status) {
    final skinId = DeckCatalog.skinIdFor(
      ref.watch(playerProfileProvider.select((p) => p.value?.deckId)),
    );
    final flip = Curves.easeInOutCubic.transform(
      (_settle.value / 0.55).clamp(0.0, 1.0),
    );
    final seal = ((_settle.value - 0.55) / 0.45).clamp(0.0, 1.0);
    Widget card(DailyDay day, {bool wide = false}) {
      final settling = day.day == _settlingDay;
      return _Dealt(
        index: day.day - 1,
        deal: _deal.value,
        child: StreakDayCard(
          key: ValueKey('day-${day.day}'),
          day: day,
          look:
              status.weekComplete
                  ? DayCardLook.claimed
                  : dayCardLook(day.status),
          faceLook: settling ? DayCardLook.today : null,
          flip: settling && !wide ? flip : null,
          seal: settling ? seal : null,
          lift:
              day.day == _claimingDay
                  ? Curves.easeOut.transform(_lift.value)
                  : 0,
          deckSkinId: skinId,
          ambient: _ambient,
          chests: status.chests,
          wide: wide,
        ),
      );
    }

    final days = {for (final day in status.days) day.day: day};
    DailyDay dayOf(int n) =>
        days[n] ??
        DailyDay(day: n, status: DailyDayStatus.upcoming, rewards: const []);
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        var cardWidth = (constraints.maxWidth - gap * 2) / 3;
        var cardHeight = cardWidth * 1.28;
        var wideHeight = cardWidth * 0.9;
        // Short screens shrink the cards; the gaps between them stay.
        final cards = cardHeight * 2 + wideHeight;
        final room = constraints.maxHeight - gap * 2;
        if (constraints.hasBoundedHeight && cards > room) {
          final k = math.max(0.0, room) / cards;
          cardWidth *= k;
          cardHeight *= k;
          wideHeight *= k;
        }
        final rowWidth = cardWidth * 3 + gap * 2;
        // heightFactor 1: the felt hugs the cards, so the whole panel can.
        Widget row(List<int> numbers) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (i, n) in numbers.indexed) ...[
              if (i > 0) const SizedBox(width: gap),
              SizedBox(
                width: cardWidth,
                height: cardHeight,
                child: card(dayOf(n)),
              ),
            ],
          ],
        );
        return Center(
          heightFactor: 1,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              row(const [1, 2, 3]),
              const SizedBox(height: gap),
              row(const [4, 5, 6]),
              const SizedBox(height: gap),
              SizedBox(
                width: rowWidth,
                height: wideHeight,
                child: card(dayOf(7), wide: true),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _actions(DailyRewardView view) {
    final l10n = context.l10n;
    final status = view.status;
    switch (status.state) {
      case DailyRewardState.broken:
        return _BrokenActions(
          status: status,
          busy: _busy,
          onRescue: () => _rescue(status),
          onRestart: () => _claim(choice: StreakChoice.restart),
        );
      case DailyRewardState.claimed:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TomorrowPreview(status: status),
            const SizedBox(height: 10),
            LeatherButton(
              label: l10n.dailyComeBackTomorrow,
              onPressed: _busy ? null : _close,
            ),
          ],
        );
      case DailyRewardState.claimable:
      case DailyRewardState.disabled:
        // The ad can only double money and chips (a chest may roll them).
        final doublable =
            status.adBoostEnabled &&
            status.nextRewards.any(
              (reward) => reward is CurrencyReward || reward is ChestReward,
            );
        final ads = ref.read(rewardedAdProvider);
        return LayoutBuilder(
          builder: (context, constraints) {
            // Small phones: a slimmer ad button leaves Claim its full word.
            final narrow = constraints.maxWidth < 300;
            return Row(
              children: [
                Expanded(
                  child: GoldButton(
                    label: l10n.claim,
                    height: 54,
                    leading:
                        _busy
                            ? const SuitCardLoader(height: 18)
                            : const GameIcon(
                              icon: AppIcons.gift,
                              size: 22,
                              color: CardInk.black,
                            ),
                    onPressed: _busy ? null : () => _claim(),
                  ),
                ),
                if (doublable)
                  ValueListenableBuilder<bool>(
                    valueListenable: ads.ready,
                    builder: (context, ready, _) {
                      if (!ready) return const SizedBox.shrink();
                      return Padding(
                        padding: EdgeInsetsDirectional.only(
                          start: narrow ? 8 : 10,
                        ),
                        child: _AdBoostButton(
                          multiplier: status.adBoostMultiplier,
                          width: narrow ? 76 : 94,
                          onPressed: _busy ? null : _claimDoubled,
                        ),
                      );
                    },
                  ),
              ],
            );
          },
        );
    }
  }
}

/// Deals card [index] onto the table: dropped in from above with a little
/// spin, one after another.
class _Dealt extends StatelessWidget {
  const _Dealt({required this.index, required this.deal, required this.child});

  final int index;
  final double deal;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final start = index * 0.07;
    final local = ((deal - start) / 0.5).clamp(0.0, 1.0);
    if (local >= 1) return child;
    final t = Curves.easeOutBack.transform(local);
    return Opacity(
      opacity: Curves.easeOut.transform(local),
      child: Transform.translate(
        offset: Offset(0, -46 * (1 - t)),
        child: Transform.rotate(
          angle: (index.isEven ? -0.14 : 0.14) * (1 - t),
          child: child,
        ),
      ),
    );
  }
}

class _LoadingOrError extends StatelessWidget {
  const _LoadingOrError({required this.failed, required this.onRetry});

  final bool failed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SizedBox(
      height: 320,
      child: Center(
        child:
            failed
                ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.dailyLoadFailed,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: CasinoColors.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    LeatherButton(
                      label: l10n.dailyRetry,
                      compact: true,
                      onPressed: onRetry,
                    ),
                  ],
                )
                : const SuitCardLoader(height: 28),
      ),
    );
  }
}

/// Flame, streak length and best, with the day or the countdown at the end
/// and the week's progress underneath.
class _StreakHeader extends StatelessWidget {
  const _StreakHeader({
    required this.view,
    required this.ambient,
    required this.onCountdownDone,
  });

  final DailyRewardView view;
  final Animation<double> ambient;
  final VoidCallback onCountdownDone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final status = view.status;
    final broken = status.state == DailyRewardState.broken;
    final collected =
        status.weekComplete
            ? 7
            : status.days
                .where((day) => day.status == DailyDayStatus.claimed)
                .length;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Narrow phones (360 wide and under) get "4/7" for "Day 4 of 7".
        final compact = constraints.maxWidth < 300;
        final Widget? pill = switch (status.state) {
          DailyRewardState.claimed => StreakCountdown(
            view: view,
            onDone: onCountdownDone,
            builder:
                (context, time) =>
                    _Pill(icon: AppIcons.timer, text: time, mono: true),
          ),
          // Said under the count instead, where it has room.
          DailyRewardState.broken => null,
          _ => _Pill(
            icon: AppIcons.gift,
            text:
                compact
                    ? '${status.nextDay}/7'
                    : l10n.dailyDayOfWeek(status.nextDay),
          ),
        };
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                SizedBox.square(
                  dimension: 38,
                  child: AnimatedBuilder(
                    animation: ambient,
                    builder:
                        (context, _) => CustomPaint(
                          painter: _FlamePainter(
                            t: ambient.value,
                            streak: broken ? 0 : status.liveStreak,
                          ),
                        ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          l10n.dailyStreakCount(status.liveStreak),
                          maxLines: 1,
                          style: TextStyle(
                            fontFamily: CasinoFonts.displayOf(context),
                            color: CasinoColors.goldSoft,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                          ),
                        ),
                      ),
                      Text(
                        broken
                            ? l10n.dailyStreakBrokenTitle
                            : l10n.dailyBest(
                              math.max(status.bestStreak, status.streakCount),
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color:
                              broken
                                  ? CasinoColors.foldHi
                                  : CasinoColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                // Short by now ("4/7", the countdown): the title gives way.
                if (pill != null) ...[const SizedBox(width: 8), pill],
              ],
            ),
            const SizedBox(height: 8),
            GoldProgressBar(value: collected / 7, height: 7),
          ],
        );
      },
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.text, this.mono = false});

  final GameIconData icon;
  final String text;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final color = CasinoColors.goldSoft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GameIcon(icon: icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            maxLines: 1,
            style: TextStyle(
              color: color,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              fontFeatures: mono ? const [FontFeature.tabularFigures()] : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// A living flame that grows with the streak: an ember before the first
/// claim, then bigger, and white-hot from a full week.
class _FlamePainter extends CustomPainter {
  const _FlamePainter({required this.t, required this.streak});

  final double t;
  final int streak;

  @override
  void paint(Canvas canvas, Size size) {
    final tier = streak <= 0 ? 0 : (streak < 3 ? 1 : (streak < 7 ? 2 : 3));
    final scale = const [0.62, 0.78, 0.9, 1.0][tier];
    final flicker =
        1 +
        0.06 * math.sin(t * 2 * math.pi * 9) +
        0.03 * math.sin(t * 2 * math.pi * 23);
    final sway = 0.05 * math.sin(t * 2 * math.pi * 5);
    final w = size.width * 0.72 * scale;
    final h = size.height * 0.9 * scale * flicker;
    final base = Offset(size.width / 2, size.height * 0.95);

    Path flame(double width, double height) {
      final tip = base + Offset(width * sway * 2, -height);
      return Path()
        ..moveTo(base.dx, base.dy)
        ..cubicTo(
          base.dx - width * 0.62,
          base.dy - height * 0.08,
          base.dx - width * 0.55,
          base.dy - height * 0.62,
          tip.dx,
          tip.dy,
        )
        ..cubicTo(
          base.dx + width * 0.12,
          base.dy - height * 0.55,
          base.dx + width * 0.62,
          base.dy - height * 0.42,
          base.dx + width * 0.5,
          base.dy - height * 0.16,
        )
        ..cubicTo(
          base.dx + width * 0.42,
          base.dy - height * 0.02,
          base.dx + width * 0.2,
          base.dy,
          base.dx,
          base.dy,
        )
        ..close();
    }

    if (tier >= 2) {
      canvas.drawCircle(
        base - Offset(0, h * 0.4),
        w * 0.9,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFFF9A2E).withValues(alpha: 0.45),
              const Color(0x00FF9A2E),
            ],
          ).createShader(
            Rect.fromCircle(center: base - Offset(0, h * 0.4), radius: w * 0.9),
          ),
      );
    }
    final outer = flame(w, h);
    final bounds = outer.getBounds();
    final colors =
        tier == 0
            ? const [Color(0xFF8A7A6A), Color(0xFF5A4A3A)]
            : const [Color(0xFFFFD35C), Color(0xFFFF8A1F), Color(0xFFD9381E)];
    canvas.drawPath(
      outer,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ).createShader(bounds),
    );
    if (tier == 0) return;
    final inner = flame(w * 0.55, h * 0.58);
    canvas.drawPath(
      inner,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors:
              tier == 3
                  ? const [Color(0xFFFFFFFF), Color(0xFFBDE7FF)]
                  : const [Color(0xFFFFF7C2), Color(0xFFFFC23D)],
        ).createShader(inner.getBounds()),
    );
  }

  @override
  bool shouldRepaint(covariant _FlamePainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.streak != streak;
}

/// One-line notes above the table: a running event, a forgiven day, a
/// freeze about to be spent, a fresh start, a Coin Boost still burning.
class _Notices extends ConsumerWidget {
  const _Notices({required this.status});

  final DailyRewardStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final claimable = status.state == DailyRewardState.claimable;
    final boost = ref.watch(boostProvider).value;
    final boostLeft = boost?.remainingSeconds() ?? 0;
    final notes = <(GameIconData, String)>[
      if (status.isEvent && status.calendarEndsAt != null)
        (AppIcons.crown, l10n.dailyEventEnds(_daysLeft(status))),
      if (claimable && status.freezesWillUse > 0)
        (AppIcons.freeze, l10n.dailyFreezeSaves),
      if (claimable && status.graceUsed > 0 && status.freezesWillUse == 0)
        (AppIcons.checkCircle, l10n.dailyGraceForgiven),
      if (claimable && status.resets) (AppIcons.refresh, l10n.dailyNewStreak),
      if (boost?.state.active case final active? when boostLeft > 0)
        (
          AppIcons.bolt,
          '${l10n.dailyCoinBoost} +${active.preset.percent}% · ${boostDuration(math.max(1, boostLeft ~/ 60))}',
        ),
    ];
    if (notes.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final (icon, text) in notes.take(2))
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: CasinoColors.gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: CasinoColors.gold.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GameIcon(icon: icon, size: 14, color: CasinoColors.goldSoft),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      text,
                      style: TextStyle(
                        color: CasinoColors.goldSoft,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Whole days from the player's day (as the server counts it) to the
  /// event's last day.
  static int _daysLeft(DailyRewardStatus status) {
    final end = DateTime.tryParse('${status.calendarEndsAt}T00:00:00Z');
    final today = status.localDate;
    if (end == null || today == null) return 0;
    return math.max(0, end.difference(today).inDays);
  }
}

/// ×2 with a short ad.
class _AdBoostButton extends StatelessWidget {
  const _AdBoostButton({
    required this.multiplier,
    required this.width,
    required this.onPressed,
  });

  final int multiplier;
  final double width;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Semantics(
      label: '×$multiplier, ${l10n.dailyShortAd}',
      button: true,
      child: Pressable(
        onTap: onPressed,
        child: Container(
          width: width,
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [CasinoColors.raiseHi, CasinoColors.raise],
            ),
            border: Border.all(
              color: CasinoColors.goldSoft.withValues(alpha: 0.8),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: CasinoColors.raise.withValues(alpha: 0.45),
                blurRadius: 14,
              ),
              const BoxShadow(
                color: Color(0x66000000),
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: ExcludeSemantics(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const GameIcon(
                      icon: AppIcons.watchAd,
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '×$multiplier',
                      style: const TextStyle(
                        fontFamily: CasinoFonts.display,
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    l10n.dailyShortAd,
                    maxLines: 1,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// What tomorrow pays, on a slim strip under a collected day.
class _TomorrowPreview extends StatelessWidget {
  const _TomorrowPreview({required this.status});

  final DailyRewardStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final languageCode = Localizations.localeOf(context).languageCode;
    if (status.nextRewards.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CasinoColors.gold.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Text(
            '${l10n.dailyTomorrow} · ${l10n.dailyDay(status.nextDay)}',
            style: TextStyle(
              color: CasinoColors.textMuted,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          for (final reward in status.nextRewards.take(3)) ...[
            RewardArt(reward: reward, size: 24),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 90),
              child: Text(
                rewardCaption(
                  l10n,
                  reward,
                  chests: status.chests,
                  languageCode: languageCode,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: CasinoColors.goldSoft,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

/// A broken streak: restore it with chips, or start again from day 1.
class _BrokenActions extends StatelessWidget {
  const _BrokenActions({
    required this.status,
    required this.busy,
    required this.onRescue,
    required this.onRestart,
  });

  final DailyRewardStatus status;
  final bool busy;
  final VoidCallback onRescue;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.dailyStreakBrokenBody(status.nextDay),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: CasinoColors.text,
            fontSize: 13,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final restore = GoldButton(
              label: l10n.dailyRestore,
              height: 52,
              leading:
                  busy
                      ? const SuitCardLoader(height: 18)
                      : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const ChipIcon(size: 20),
                          const SizedBox(width: 3),
                          Text(
                            '${status.rescueChipCost}',
                            style: const TextStyle(
                              fontFamily: CasinoFonts.display,
                              color: CardInk.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
              onPressed: busy ? null : onRescue,
            );
            // Side by side only where both labels fit whole.
            if (constraints.maxWidth < 330) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  restore,
                  const SizedBox(height: 8),
                  LeatherButton(
                    label: l10n.dailyStartOver,
                    height: 44,
                    onPressed: busy ? null : onRestart,
                  ),
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: restore),
                const SizedBox(width: 10),
                Expanded(
                  child: LeatherButton(
                    label: l10n.dailyStartOver,
                    height: 52,
                    onPressed: busy ? null : onRestart,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
