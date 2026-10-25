import 'dart:async';

import 'package:cardgame/app/boost_providers.dart';
import 'package:cardgame/data/boost/boost_models.dart';
import 'package:cardgame/l10n/l10n_ext.dart';
import 'package:cardgame/ui/screens/boost/boost_sheet.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/theme/felt_chrome.dart';
import 'package:cardgame/ui/widgets/boost_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Rebuilds once a second while a boost runs, counting down from what the
/// server said. Refetches the boosts once when the time is up.
class BoostTicker extends ConsumerStatefulWidget {
  const BoostTicker({super.key, required this.view, required this.builder});

  final BoostView view;
  final Widget Function(BuildContext context, int remainingSeconds) builder;

  @override
  ConsumerState<BoostTicker> createState() => _BoostTickerState();
}

class _BoostTickerState extends ConsumerState<BoostTicker> {
  Timer? _timer;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void didUpdateWidget(BoostTicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.view, widget.view)) _done = false;
  }

  void _tick() {
    if (!mounted) return;
    if (widget.view.remainingSeconds() <= 0 && !_done) {
      _done = true;
      unawaited(ref.read(boostProvider.notifier).refresh());
    }
    setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, widget.view.remainingSeconds());
}

/// Share of the run still left, for [BoostRing]. Null when the run's length
/// isn't known.
double? boostFraction(ActiveBoost active, int remainingSeconds) {
  final total = active.totalSeconds;
  if (total == null || total <= 0) return null;
  return remainingSeconds / total;
}

/// The tag on the home Play card: the running boost with its countdown, or
/// how many boosts wait to be activated. Opens the boosts sheet.
class BoostPlayTag extends ConsumerWidget {
  const BoostPlayTag({super.key});

  static const height = 30.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(boostProvider).value;
    if (view == null) return const SizedBox.shrink();
    final active = view.state.active;
    if (active != null && view.remainingSeconds() > 0) {
      return BoostTicker(
        view: view,
        builder: (context, left) {
          if (left <= 0) return const SizedBox.shrink();
          return _ActiveTag(active: active, remainingSeconds: left);
        },
      );
    }
    final ready = view.state.readyCount;
    if (ready == 0) return const SizedBox.shrink();
    return _ReadyTag(count: ready, tier: view.state.inventory.first.preset.tier);
  }
}

class _ActiveTag extends StatelessWidget {
  const _ActiveTag({required this.active, required this.remainingSeconds});

  final ActiveBoost active;
  final int remainingSeconds;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final preset = active.preset;
    final metal = BoostMetal.of(preset.tier);
    final clock = boostClock(remainingSeconds);
    const radius = BorderRadius.all(Radius.circular(BoostPlayTag.height / 2));
    return Semantics(
      button: true,
      label: l10n.boostActiveSemantics(preset.percent, clock),
      excludeSemantics: true,
      child: Pressable(
        onTap: () => showBoostSheet(context),
        child: BoostShimmer(
          borderRadius: radius,
          child: Container(
            height: BoostPlayTag.height,
            padding: const EdgeInsetsDirectional.fromSTEB(3, 2, 12, 2),
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF241A10), Color(0xFF0B0805)],
              ),
              border: Border.all(color: metal.base, width: 1.4),
              boxShadow: [
                BoxShadow(
                  color: metal.glow.withValues(alpha: 0.55),
                  blurRadius: 12,
                  spreadRadius: -1,
                ),
                const BoxShadow(
                  color: Color(0x99000000),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                BoostRing(
                  tier: preset.tier,
                  fraction: boostFraction(active, remainingSeconds),
                  stroke: 1.6,
                  child: BoostCoin(tier: preset.tier, size: 18),
                ),
                const SizedBox(width: 6),
                BoostPercentText(
                  percent: preset.percent,
                  tier: preset.tier,
                  fontSize: 14,
                ),
                Container(
                  width: 3,
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 7),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: metal.base.withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  clock,
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    color: CasinoColors.text.withValues(alpha: 0.92),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    fontFeatures: const [FontFeature.tabularFigures()],
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

/// Boosts wait to be activated: an ivory tag that breathes gently.
class _ReadyTag extends StatefulWidget {
  const _ReadyTag({required this.count, required this.tier});

  final int count;
  final BoostTier tier;

  @override
  State<_ReadyTag> createState() => _ReadyTagState();
}

class _ReadyTagState extends State<_ReadyTag>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
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
    final label = context.l10n.boostReady(widget.count);
    final metal = BoostMetal.of(widget.tier);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Pressable(
        onTap: () => showBoostSheet(context),
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) {
            final t = Curves.easeInOut.transform(_pulse.value);
            return DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(BoostPlayTag.height / 2),
                boxShadow: [
                  BoxShadow(
                    color: metal.glow.withValues(alpha: 0.2 + 0.3 * t),
                    blurRadius: 6 + 8 * t,
                  ),
                ],
              ),
              child: child,
            );
          },
          child: Container(
            height: BoostPlayTag.height,
            padding: const EdgeInsetsDirectional.fromSTEB(4, 2, 12, 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(BoostPlayTag.height / 2),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [CardInk.ivory, CardInk.ivoryShade],
              ),
              border: Border.all(color: CasinoColors.goldLo, width: 1.2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x80000000),
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                BoostCoin(tier: widget.tier, size: 22),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: CardInk.black,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    height: 1,
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
