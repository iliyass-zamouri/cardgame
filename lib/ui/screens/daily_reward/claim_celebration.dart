import 'dart:async';
import 'dart:math' as math;

import 'package:cardgame/data/avatars/avatar_catalog.dart';
import 'package:cardgame/data/daily_reward/daily_reward_models.dart';
import 'package:cardgame/l10n/l10n_ext.dart';
import 'package:cardgame/services/sfx_service.dart';
import 'package:cardgame/ui/screens/daily_reward/reward_art.dart';
import 'package:cardgame/ui/theme/app_icons.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/theme/felt_chrome.dart';
import 'package:cardgame/ui/theme/game_icon.dart';
import 'package:cardgame/ui/widgets/amount_format.dart';
import 'package:cardgame/ui/widgets/currency_icon.dart';
import 'package:cardgame/ui/widgets/gold_burst.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Full-screen reveal after a claim: the rewards land in a gold burst under
/// turning rays, amounts count up, a chest throws its lid open to show what
/// it rolled. "Collect" (or a tap anywhere once it has landed) reports where
/// each currency sits on screen, so its coins can fly from there.
class ClaimCelebration extends StatefulWidget {
  const ClaimCelebration({
    super.key,
    required this.title,
    required this.granted,
    required this.onCollect,
    this.chests = const {},
    this.jackpot = false,
    this.boostMultiplier,
    this.coinBoostPercent = 0,
    this.onEquip,
  });

  final String title;
  final List<GrantedReward> granted;
  final void Function(Map<CurrencyType, Offset> origins) onCollect;
  final Map<String, DailyChest> chests;
  final bool jackpot;

  /// Shown as an "×2 ad boost" badge when the claim was boosted.
  final int? boostMultiplier;
  final int coinBoostPercent;

  /// Equips a newly won avatar or deck.
  final void Function(RewardItem item)? onEquip;

  @override
  State<ClaimCelebration> createState() => _ClaimCelebrationState();
}

class _ClaimCelebrationState extends State<ClaimCelebration>
    with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  );
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 9),
  );
  late final AnimationController _chest = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 950),
  );
  final _currencyKeys = {
    CurrencyType.money: GlobalKey(debugLabel: 'celebration-money'),
    CurrencyType.chips: GlobalKey(debugLabel: 'celebration-chips'),
  };
  final _equipped = <String>{};
  Timer? _chestTimer;
  bool _collecting = false;

  bool get _hasChest =>
      widget.granted.any((grant) => grant.reward is ChestReward);

  @override
  void initState() {
    super.initState();
    unawaited(
      widget.jackpot
          ? HapticFeedback.heavyImpact()
          : HapticFeedback.mediumImpact(),
    );
    if (widget.jackpot) {
      SfxService.instance.win();
    } else {
      SfxService.instance.buy();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _intro.value = 1;
      _chest.value = 1;
      _ambient.stop();
      return;
    }
    if (!_intro.isAnimating && _intro.value == 0) _intro.forward();
    if (!_ambient.isAnimating) _ambient.repeat();
    if (_hasChest && _chestTimer == null && _chest.value == 0) {
      _chestTimer = Timer(const Duration(milliseconds: 750), () {
        if (!mounted) return;
        SfxService.instance.reveal();
        HapticFeedback.mediumImpact();
        _chest.forward();
      });
    }
  }

  @override
  void dispose() {
    _chestTimer?.cancel();
    _intro.dispose();
    _ambient.dispose();
    _chest.dispose();
    super.dispose();
  }

  Animation<double> _slice(
    double begin,
    double end, [
    Curve curve = Curves.easeOutCubic,
  ]) => CurvedAnimation(
    parent: _intro,
    curve: Interval(begin, end, curve: curve),
  );

  void _collect() {
    if (_collecting) return;
    _collecting = true;
    final origins = <CurrencyType, Offset>{};
    for (final MapEntry(key: currency, value: key) in _currencyKeys.entries) {
      final box = key.currentContext?.findRenderObject();
      if (box is RenderBox && box.attached && box.hasSize) {
        origins[currency] = box.localToGlobal(box.size.center(Offset.zero));
      }
    }
    widget.onCollect(origins);
  }

  void _equip(RewardItem item) {
    final id = switch (item) {
      AvatarReward(:final itemId) => 'avatar:$itemId',
      DeckReward(:final itemId) => 'deck:$itemId',
      _ => null,
    };
    if (id == null || _equipped.contains(id)) return;
    setState(() => _equipped.add(id));
    widget.onEquip?.call(item);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    // The first tile paying each currency is where its coins fly from.
    final keyed = <CurrencyType>{};
    GlobalKey? keyFor(GrantedReward grant) {
      for (final currency in CurrencyType.values) {
        if (!keyed.contains(currency) && grant.amountOf(currency) > 0) {
          keyed.add(currency);
          return _currencyKeys[currency];
        }
      }
      return null;
    }

    final headline = _slice(0.12, 0.55, Curves.elasticOut);
    final buttonIn = _slice(0.62, 1);
    // Dialog routes carry no Material: without one, text falls back to the
    // framework's error style.
    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (_intro.value > 0.6) _collect();
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            FadeTransition(
              opacity: _slice(0, 0.22),
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.15),
                    radius: 0.95,
                    colors: [Color(0xEB3A2416), Color(0xF5060403)],
                  ),
                ),
              ),
            ),
            IgnorePointer(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_intro, _ambient]),
                  builder:
                      (_, _) => CustomPaint(
                        painter: GoldRaysPainter(
                          t: _ambient.value,
                          center: const Offset(0.5, 0.4),
                          intensity: _slice(0.04, 0.4).value,
                        ),
                      ),
                ),
              ),
            ),
            if (widget.jackpot)
              IgnorePointer(
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _ambient,
                    builder:
                        (_, _) => CustomPaint(
                          painter: ConfettiPainter(
                            t: _ambient.value,
                            win: true,
                          ),
                        ),
                  ),
                ),
              ),
            IgnorePointer(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _intro,
                  builder:
                      (_, _) => CustomPaint(
                        painter: GoldBurstPainter(
                          t: _slice(0.06, 0.8, Curves.linear).value,
                          origin: const Offset(0.5, 0.4),
                          big: widget.jackpot,
                        ),
                      ),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 24,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ScaleTransition(
                        scale: headline,
                        child: Text(
                          casinoButtonLabel(widget.title, locale),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: CasinoFonts.displayFor(locale),
                            color: CasinoColors.goldSoft,
                            fontSize: widget.jackpot ? 34 : 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: locale.languageCode == 'ar' ? 0 : 2,
                            shadows: [
                              Shadow(
                                color: CasinoColors.gold.withValues(alpha: 0.7),
                                blurRadius: 18,
                              ),
                              const Shadow(
                                color: Color(0xCC000000),
                                offset: Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (widget.boostMultiplier != null) ...[
                        const SizedBox(height: 10),
                        FadeTransition(
                          opacity: _slice(0.3, 0.6),
                          child: _BoostBadge(
                            label: l10n.dailyBoostedBadge(
                              widget.boostMultiplier!,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 14,
                        runSpacing: 18,
                        children: [
                          for (final (i, grant) in widget.granted.indexed)
                            _PopIn(
                              animation: _slice(
                                math.min(0.7, 0.18 + i * 0.1),
                                math.min(1, 0.55 + i * 0.1),
                                Curves.easeOutBack,
                              ),
                              child: _GrantTile(
                                grant: grant,
                                artKey: keyFor(grant),
                                count: _slice(0.35, 0.95),
                                chest: CurvedAnimation(
                                  parent: _chest,
                                  curve: Curves.easeOutBack,
                                ),
                                chests: widget.chests,
                                coinBoostPercent: widget.coinBoostPercent,
                                equipped: _equipped,
                                onEquip: widget.onEquip == null ? null : _equip,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      FadeTransition(
                        opacity: buttonIn,
                        child: SlideTransition(
                          position: Tween(
                            begin: const Offset(0, 0.4),
                            end: Offset.zero,
                          ).animate(buttonIn),
                          child: SizedBox(
                            width: 230,
                            child: GoldButton(
                              label: l10n.dailyCollect,
                              height: 52,
                              leading: const GameIcon(
                                icon: AppIcons.gift,
                                size: 20,
                                color: CardInk.black,
                              ),
                              onPressed: _collect,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PopIn extends StatelessWidget {
  const _PopIn({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final t = animation.value;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.scale(scale: 0.4 + 0.6 * t, child: child),
        );
      },
    );
  }
}

class _BoostBadge extends StatelessWidget {
  const _BoostBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.black.withValues(alpha: 0.4),
        border: Border.all(color: CasinoColors.gold.withValues(alpha: 0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GameIcon(
            icon: AppIcons.watchAd,
            size: 16,
            color: CasinoColors.goldSoft,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: CasinoColors.goldSoft,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// One won reward: art on a soft glow, its name, and what it means.
class _GrantTile extends StatelessWidget {
  const _GrantTile({
    required this.grant,
    required this.artKey,
    required this.count,
    required this.chest,
    required this.chests,
    required this.coinBoostPercent,
    required this.equipped,
    required this.onEquip,
  });

  final GrantedReward grant;

  /// Marks the art whose coins fly to the top bar.
  final GlobalKey? artKey;
  final Animation<double> count;
  final Animation<double> chest;
  final Map<String, DailyChest> chests;
  final int coinBoostPercent;
  final Set<String> equipped;
  final void Function(RewardItem item)? onEquip;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final languageCode = Localizations.localeOf(context).languageCode;
    final reward = grant.reward;
    final name = rewardCaption(
      l10n,
      reward,
      chests: chests,
      languageCode: languageCode,
    );

    if (reward is ChestReward) {
      return SizedBox(
        width: 200,
        child: AnimatedBuilder(
          animation: chest,
          builder: (context, _) {
            final open = chest.value.clamp(0.0, 1.0);
            // A little rattle before the lid gives way.
            final shake =
                open == 0
                    ? 0.0
                    : math.sin(open * math.pi * 8) * (1 - open) * 0.08;
            final loot = grant.loot;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Glow(
                  child: Transform.rotate(
                    angle: shake,
                    child: RewardArt(
                      reward: reward,
                      size: 100,
                      chestOpen: open,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                _Name(name),
                if (loot != null && open > 0.55) ...[
                  const SizedBox(height: 10),
                  Transform.scale(
                    scale: Curves.easeOutBack.transform(
                      ((open - 0.55) / 0.45).clamp(0.0, 1.0),
                    ),
                    child: _GrantTile(
                      grant: loot,
                      artKey: artKey,
                      count: kAlwaysCompleteAnimation,
                      chest: chest,
                      chests: chests,
                      coinBoostPercent: coinBoostPercent,
                      equipped: equipped,
                      onEquip: onEquip,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      );
    }

    final itemKey = switch (reward) {
      AvatarReward(:final itemId) => 'avatar:$itemId',
      DeckReward(:final itemId) => 'deck:$itemId',
      _ => null,
    };
    final converted = grant.converted;
    final children = <Widget>[];
    if (reward is CurrencyReward) {
      children.addAll([
        _Glow(
          child: KeyedSubtree(
            key: artKey,
            child: RewardArt(reward: reward, size: 78),
          ),
        ),
        const SizedBox(height: 6),
        AnimatedBuilder(
          animation: count,
          builder:
              (context, _) => _Amount(
                '+${groupedAmount((reward.amount * count.value.clamp(0.0, 1.0)).round())}',
              ),
        ),
        _Caption(
          reward.currency == CurrencyType.chips ? l10n.chips : l10n.money,
        ),
      ]);
    } else if (itemKey != null && grant.duplicate && converted != null) {
      children.addAll([
        Opacity(opacity: 0.55, child: RewardArt(reward: reward, size: 72)),
        const SizedBox(height: 6),
        _Name(name),
        _Caption(l10n.dailyAlreadyOwned),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            KeyedSubtree(
              key: artKey,
              child: CurrencyIcon(currency: converted.currency, size: 26),
            ),
            const SizedBox(width: 6),
            _Amount('+${groupedAmount(converted.amount)}', size: 22),
          ],
        ),
      ]);
    } else if (itemKey != null) {
      final isEquipped = equipped.contains(itemKey);
      children.addAll([
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            _Glow(child: RewardArt(reward: reward, size: 84)),
            Positioned(top: -10, child: _NewBadge(label: l10n.dailyNew)),
          ],
        ),
        const SizedBox(height: 8),
        _Name(name),
        if (onEquip != null) ...[
          const SizedBox(height: 8),
          LeatherButton(
            label: isEquipped ? l10n.equipped : l10n.equip,
            compact: true,
            onPressed: isEquipped ? null : () => onEquip!(reward),
          ),
        ],
      ]);
    } else {
      final body = switch (reward) {
        CoinBoostReward() => l10n.dailyCoinBoostBody(coinBoostPercent),
        StreakFreezeReward() => l10n.dailyStreakFreezeBody,
        _ => null,
      };
      children.addAll([
        _Glow(child: RewardArt(reward: reward, size: 78)),
        const SizedBox(height: 8),
        _Name(
          rewardTitle(l10n, reward, chests: chests, languageCode: languageCode),
        ),
        if (body != null) _Caption(body),
      ]);
    }
    return SizedBox(
      width: 150,
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            CasinoColors.gold.withValues(alpha: 0.38),
            CasinoColors.gold.withValues(alpha: 0),
          ],
        ),
      ),
      child: Padding(padding: const EdgeInsets.all(14), child: child),
    );
  }
}

class _Amount extends StatelessWidget {
  const _Amount(this.text, {this.size = 30});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: CasinoFonts.display,
        color: CasinoColors.goldSoft,
        fontSize: size,
        fontWeight: FontWeight.w900,
        height: 1.1,
        shadows: const [
          Shadow(color: Color(0xCC000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
    );
  }
}

class _Name extends StatelessWidget {
  const _Name(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: CasinoFonts.displayOf(context),
        color: CasinoColors.text,
        fontSize: 15,
        fontWeight: FontWeight.w800,
        height: 1.2,
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: CasinoColors.textMuted,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
      ),
    );
  }
}

class _NewBadge extends StatelessWidget {
  const _NewBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          colors: [CasinoColors.foldHi, CasinoColors.fold],
        ),
        border: Border.all(color: CasinoColors.goldSoft, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x80000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        casinoButtonLabel(label, locale),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
