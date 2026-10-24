import 'dart:async';
import 'dart:math' as math;

import 'package:cardgame/app/auth_providers.dart';
import 'package:cardgame/app/daily_reward_providers.dart';
import 'package:cardgame/data/avatars/avatar_catalog.dart';
import 'package:cardgame/data/daily_reward/daily_reward_models.dart';
import 'package:cardgame/l10n/l10n_ext.dart';
import 'package:cardgame/services/analytics_service.dart';
import 'package:cardgame/ui/screens/daily_reward/claim_celebration.dart';
import 'package:cardgame/ui/screens/daily_reward/reward_art.dart';
import 'package:cardgame/ui/screens/daily_reward/reward_shell.dart';
import 'package:cardgame/ui/theme/app_icons.dart';
import 'package:cardgame/ui/theme/casino_chrome.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/theme/felt_chrome.dart';
import 'package:cardgame/ui/theme/game_icon.dart';
import 'package:cardgame/ui/widgets/gold_burst.dart';
import 'package:cardgame/ui/widgets/reward_fly_overlay.dart';
import 'package:cardgame/ui/widgets/suit_card_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The welcome-back gift for a player returning after a long break.
Future<void> showComebackModal(BuildContext context) {
  return showRewardDialog<void>(context, builder: (_) => const ComebackModal());
}

class ComebackModal extends ConsumerStatefulWidget {
  const ComebackModal({super.key});

  @override
  ConsumerState<ComebackModal> createState() => _ComebackModalState();
}

class _ComebackModalState extends ConsumerState<ComebackModal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  );
  // Read in initState: still needed in dispose, when ref is gone.
  late final PlayerProfileNotifier _profile;
  late final AnalyticsService _analytics;

  /// The claim is on its way.
  bool _claiming = false;

  /// Paid: the panel only waits for the coins to land, then closes.
  bool _claimed = false;
  DailyClaimResult? _celebrating;
  DailyClaimResult? _unapplied;

  bool get _busy => _claiming || _claimed;

  @override
  void initState() {
    super.initState();
    _profile = ref.read(playerProfileProvider.notifier);
    _analytics = ref.read(analyticsServiceProvider);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _ambient.stop();
    } else if (!_ambient.isAnimating) {
      _ambient.repeat();
    }
  }

  @override
  void dispose() {
    _applyGrant();
    _ambient.dispose();
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

  Future<void> _claim() async {
    if (_busy) return;
    final l10n = context.l10n;
    setState(() => _claiming = true);
    try {
      final result =
          await ref.read(dailyRewardProvider.notifier).claimComeback();
      _unapplied = result;
      unawaited(_analytics.dailyReward(action: 'comeback'));
      if (!mounted) return;
      setState(() {
        _claiming = false;
        _claimed = true;
        _celebrating = result;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _claiming = false);
      CasinoToast.show(context, l10n.dailyClaimFailed, success: false);
      unawaited(ref.read(dailyRewardProvider.notifier).refresh());
    }
  }

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
          onLand: land,
        ),
      );
    }
    if (flights.isEmpty) land();
    setState(() => _celebrating = null);
    // Stay open until the coins land, so the counter ticks up with them.
    await Future.wait(flights);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final languageCode = Localizations.localeOf(context).languageCode;
    final status = ref.watch(dailyRewardProvider).value?.status;
    final rewards = status?.comebackRewards ?? const <RewardItem>[];
    final celebrating = _celebrating;
    return PopScope(
      canPop: !_busy,
      child: Stack(
        fit: StackFit.expand,
        children: [
          RewardPanel(
            title: l10n.dailyWelcomeBack,
            maxWidth: 380,
            onClose: _busy ? null : () => Navigator.of(context).maybePop(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 150,
                  child: AnimatedBuilder(
                    animation: _ambient,
                    builder: (context, _) {
                      final bob =
                          math.sin(_ambient.value * 2 * math.pi * 2) * 4;
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: GoldRaysPainter(
                                t: _ambient.value,
                                center: const Offset(0.5, 0.55),
                              ),
                            ),
                          ),
                          Transform.translate(
                            offset: Offset(0, bob),
                            child: const RewardArt(
                              reward: ChestReward(chestId: ''),
                              size: 116,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                Text(
                  l10n.dailyWelcomeBackBody,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: CasinoColors.text,
                    fontSize: 14,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                IvoryCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final (i, reward) in rewards.indexed) ...[
                        if (i > 0) const SizedBox(width: 18),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RewardArt(reward: reward, size: 44),
                            const SizedBox(height: 4),
                            Text(
                              rewardCaption(
                                l10n,
                                reward,
                                chests: status?.chests ?? const {},
                                languageCode: languageCode,
                              ),
                              style: const TextStyle(
                                fontFamily: CasinoFonts.display,
                                color: CardInk.black,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: GoldButton(
                    label: _claimed ? l10n.dailyCollected : l10n.dailyCollect,
                    height: 54,
                    leading:
                        _claiming
                            ? const SuitCardLoader(height: 18)
                            : GameIcon(
                              icon:
                                  _claimed
                                      ? AppIcons.checkCircle
                                      : AppIcons.gift,
                              size: 22,
                              color: CardInk.black,
                            ),
                    onPressed: _busy || rewards.isEmpty ? null : _claim,
                  ),
                ),
              ],
            ),
          ),
          if (celebrating != null)
            Positioned.fill(
              child: ClaimCelebration(
                title: l10n.dailyWelcomeBack,
                granted: celebrating.granted,
                chests: (celebrating.status ?? status)?.chests ?? const {},
                coinBoostPercent: status?.coinBoostPercent ?? 0,
                onCollect: _collect,
              ),
            ),
        ],
      ),
    );
  }
}
