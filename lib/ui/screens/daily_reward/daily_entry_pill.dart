import 'dart:math' as math;

import 'package:cardgame/app/daily_reward_providers.dart';
import 'package:cardgame/data/daily_reward/daily_reward_models.dart';
import 'package:cardgame/l10n/l10n_ext.dart';
import 'package:cardgame/ui/screens/daily_reward/daily_reward_modal.dart';
import 'package:cardgame/ui/screens/daily_reward/streak_card.dart';
import 'package:cardgame/ui/screens/daily_reward/streak_countdown.dart';
import 'package:cardgame/ui/theme/app_icons.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/theme/felt_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

/// Whether the home tab shows [DailyEntryPill], so its layout can make room.
final dailyEntryVisibleProvider = Provider<bool>((ref) {
  return ref.watch(
    dailyRewardProvider.select((view) => view.value?.status.enabled ?? false),
  );
});

/// Home banner for the streak: a gold pulse when a reward waits, the
/// countdown to the next one otherwise. Opens the streak.
class DailyEntryPill extends ConsumerWidget {
  const DailyEntryPill({super.key});

  static const height = 52.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(dailyRewardProvider).value;
    final status = view?.status;
    if (view == null || status == null || !status.enabled) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final broken = status.state == DailyRewardState.broken;
    final waiting = status.needsAttention;
    final day =
        status.state == DailyRewardState.claimed
            ? status.position
            : status.nextDay;

    final Widget subtitle;
    if (status.comebackAvailable) {
      subtitle = _line(l10n.dailyEntryComeback);
    } else if (broken) {
      subtitle = _line(l10n.dailyEntryBroken, color: CasinoColors.foldHi);
    } else if (status.state == DailyRewardState.claimed) {
      subtitle = StreakCountdown(
        view: view,
        onDone: () => ref.read(dailyRewardProvider.notifier).refresh(),
        builder:
            (context, time) => _line(l10n.dailyNextIn(time), tabular: time),
      );
    } else {
      subtitle = _line(l10n.dailyEntryReady(status.nextDay));
    }

    return Semantics(
      button: true,
      child: Pressable(
        onTap: () => openDailyRewards(context, ref, source: 'home'),
        child: Container(
          height: height,
          padding: const EdgeInsetsDirectional.fromSTEB(8, 6, 8, 6),
          decoration: leatherPanelDecoration(radius: 16, highlighted: waiting),
          child: Row(
            children: [
              _MiniCard(day: math.max(1, day), collected: !waiting),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      casinoButtonLabel(l10n.dailyStreakTitle, locale),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: CasinoFonts.displayFor(locale),
                        color: CasinoColors.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: locale.languageCode == 'ar' ? 0 : 1.2,
                        height: 1.2,
                      ),
                    ),
                    subtitle,
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (waiting)
                _PulsingTag(
                  label:
                      status.comebackAvailable
                          ? l10n.dailyCollect
                          : (broken ? l10n.dailyRestore : l10n.claim),
                  danger: broken && !status.comebackAvailable,
                )
              else
                _StreakBadge(count: status.streakCount),
            ],
          ),
        ),
      ),
    );
  }

  /// One line of subtitle. [tabular] is the part of it (the countdown) drawn
  /// with fixed-width digits so it doesn't jitter; the rest keeps normal
  /// spacing, which tabular figures would widen.
  static Widget _line(String text, {Color? color, String? tabular}) {
    final at = tabular == null ? -1 : text.indexOf(tabular);
    return Text.rich(
      at < 0
          ? TextSpan(text: text)
          : TextSpan(
            children: [
              TextSpan(text: text.substring(0, at)),
              TextSpan(
                text: tabular,
                style: const TextStyle(
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              TextSpan(text: text.substring(at + tabular!.length)),
            ],
          ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: color ?? CasinoColors.text,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        height: 1.25,
      ),
    );
  }
}

/// A tiny ivory card showing the day's rank and suit.
class _MiniCard extends StatelessWidget {
  const _MiniCard({required this.day, required this.collected});

  final int day;
  final bool collected;

  @override
  Widget build(BuildContext context) {
    final suit = daySuit(day);
    return Container(
      width: 30,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [CardInk.ivory, CardInk.ivoryShade],
        ),
        border: Border.all(
          color: CasinoColors.gold.withValues(alpha: collected ? 0.5 : 1),
          width: collected ? 1 : 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x80000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            day == 1 ? 'A' : '$day',
            textScaler: TextScaler.noScaling,
            style: TextStyle(
              fontFamily: CasinoFonts.display,
              color: suitColor(suit),
              fontSize: 14,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          SuitGlyph(suit: suit, size: 11),
        ],
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CasinoColors.gold.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const HugeIcon(
            icon: AppIcons.fire,
            size: 15,
            color: Color(0xFFFF9A2E),
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              fontFamily: CasinoFonts.display,
              color: CasinoColors.goldSoft,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

/// The call to action, breathing gently so a waiting reward is noticed.
class _PulsingTag extends StatefulWidget {
  const _PulsingTag({required this.label, required this.danger});

  final String label;
  final bool danger;

  @override
  State<_PulsingTag> createState() => _PulsingTagState();
}

class _PulsingTagState extends State<_PulsingTag>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final colors =
        widget.danger
            ? [CasinoColors.foldHi, CasinoColors.fold]
            : [CasinoColors.goldHi, CasinoColors.gold, CasinoColors.goldLo];
    final glow = widget.danger ? CasinoColors.foldHi : CasinoColors.gold;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_pulse.value);
        return Transform.scale(
          scale: 1 + 0.04 * t,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: glow.withValues(alpha: 0.25 + 0.35 * t),
                  blurRadius: 8 + 8 * t,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colors,
          ),
          border: Border.all(
            color: const Color(0xFF7A5A0E).withValues(alpha: 0.6),
          ),
        ),
        child: Text(
          casinoButtonLabel(widget.label, locale),
          style: TextStyle(
            fontFamily: CasinoFonts.uiFor(locale),
            color: widget.danger ? Colors.white : CardInk.black,
            fontSize: 12.5,
            fontWeight: FontWeight.w900,
            letterSpacing: locale.languageCode == 'ar' ? 0 : 0.8,
          ),
        ),
      ),
    );
  }
}
