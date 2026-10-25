import 'package:cardgame/app/boost_providers.dart';
import 'package:cardgame/data/boost/boost_api.dart';
import 'package:cardgame/data/boost/boost_models.dart';
import 'package:cardgame/l10n/l10n_ext.dart';
import 'package:cardgame/ui/screens/boost/boost_play_tag.dart';
import 'package:cardgame/ui/screens/daily_reward/reward_art.dart';
import 'package:cardgame/ui/theme/app_icons.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/theme/felt_chrome.dart';
import 'package:cardgame/ui/theme/game_icon.dart';
import 'package:cardgame/ui/widgets/amount_format.dart';
import 'package:cardgame/ui/widgets/boost_badge.dart';
import 'package:cardgame/ui/widgets/gold_burst.dart';
import 'package:cardgame/ui/widgets/greyed_out.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The player's boosts: the one running, and the ones waiting with an
/// Activate button each.
Future<void> showBoostSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const BoostSheet(),
  );
}

class BoostSheet extends ConsumerStatefulWidget {
  const BoostSheet({super.key});

  @override
  ConsumerState<BoostSheet> createState() => _BoostSheetState();
}

class _BoostSheetState extends ConsumerState<BoostSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  /// The item being activated, so only its button waits.
  String? _busyItem;
  String? _message;
  bool _messageIsError = false;

  @override
  void initState() {
    super.initState();
    // Opening the sheet is a good moment to catch up with the server.
    Future.microtask(() => ref.read(boostProvider.notifier).refresh());
  }

  @override
  void dispose() {
    _burst.dispose();
    super.dispose();
  }

  Future<void> _activate(BoostGroup group) async {
    final item = group.items.first;
    final l10n = context.l10n;
    setState(() {
      _busyItem = item.id;
      _message = null;
    });
    try {
      final result = await ref
          .read(boostProvider.notifier)
          .activate(item.id);
      if (!mounted) return;
      setState(() {
        _messageIsError = false;
        _message =
            result.kind == BoostActivationKind.extend
                ? l10n.boostExtended(boostDuration(result.minutes))
                : l10n.boostStarted(group.preset.percent);
      });
      if (!MediaQuery.disableAnimationsOf(context)) _burst.forward(from: 0);
    } on BoostApiException catch (error) {
      if (!mounted) return;
      final blocking = error.state?.active?.preset.percent;
      setState(() {
        _messageIsError = true;
        _message =
            error.isConflict && blocking != null
                ? l10n.boostWaitsFor(blocking)
                : l10n.boostActivateFailed;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messageIsError = true;
        _message = l10n.boostActivateFailed;
      });
    } finally {
      if (mounted) setState(() => _busyItem = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final view = ref.watch(boostProvider).value;
    final state = view?.state ?? BoostState.empty;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.86;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [CasinoColors.leather, CasinoColors.leatherDeep],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: CasinoColors.gold, width: 1.5)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const GameIcon(icon: AppIcons.bolt, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.boostsTitle,
                      style: TextStyle(
                        color: CasinoColors.gold,
                        fontWeight: FontWeight.w800,
                        fontFamily: CasinoFonts.displayOf(context),
                        fontSize: 19,
                      ),
                    ),
                  ),
                  FeltIconButton(
                    icon: AppIcons.close,
                    size: 36,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Stack(
                children: [
                  view != null && view.running != null
                      ? BoostTicker(
                        view: view,
                        builder:
                            (context, left) =>
                                left > 0
                                    ? _ActiveHero(
                                      active: view.state.active!,
                                      remainingSeconds: left,
                                    )
                                    : const _IdleHero(),
                      )
                      : const _IdleHero(),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _burst,
                        builder:
                            (context, _) =>
                                _burst.isAnimating
                                    ? CustomPaint(
                                      painter: GoldBurstPainter(
                                        t: _burst.value,
                                        origin: const Offset(0.16, 0.5),
                                      ),
                                    )
                                    : const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child:
                    _message == null
                        ? const SizedBox(width: double.infinity)
                        : Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            _message!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color:
                                  _messageIsError
                                      ? CasinoColors.foldHi
                                      : CasinoColors.goldSoft,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
              ),
              const SizedBox(height: 16),
              if (state.readyCount > 0)
                FeltSectionHeader(label: l10n.boostReady(state.readyCount)),
              Flexible(
                child:
                    state.inventory.isEmpty
                        ? _EmptyInventory(text: l10n.boostInventoryEmpty)
                        : ListView.separated(
                          shrinkWrap: true,
                          itemCount: state.inventory.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final group = state.inventory[index];
                            final running = view?.running;
                            return _GroupCard(
                              group: group,
                              running: running,
                              busy: group.items.any(
                                (item) => item.id == _busyItem,
                              ),
                              locked: _busyItem != null,
                              onActivate: () => _activate(group),
                            );
                          },
                        ),
              ),
              const SizedBox(height: 14),
              Text(
                '${l10n.boostOneAtATime} ${l10n.boostMoneyOnly}.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: CasinoColors.textMuted,
                  fontSize: 11.5,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The running boost: a big coin in its draining ring, its value and clock.
class _ActiveHero extends StatelessWidget {
  const _ActiveHero({required this.active, required this.remainingSeconds});

  final ActiveBoost active;
  final int remainingSeconds;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final preset = active.preset;
    final metal = BoostMetal.of(preset.tier);
    final languageCode = Localizations.localeOf(context).languageCode;
    const radius = BorderRadius.all(Radius.circular(18));
    return BoostShimmer(
      borderRadius: radius,
      period: const Duration(milliseconds: 5200),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: RadialGradient(
            center: const AlignmentDirectional(-0.75, 0).resolve(
              Directionality.of(context),
            ),
            radius: 1.4,
            colors: [
              Color.lerp(const Color(0xFF241A10), metal.lo, 0.35)!,
              const Color(0xFF0B0805),
            ],
          ),
          border: Border.all(color: metal.base, width: 1.4),
          boxShadow: [
            BoxShadow(
              color: metal.glow.withValues(alpha: 0.35),
              blurRadius: 18,
              spreadRadius: -4,
            ),
          ],
        ),
        child: Row(
          children: [
            BoostRing(
              tier: preset.tier,
              fraction: boostFraction(active, remainingSeconds),
              stroke: 3,
              child: BoostCoin(tier: preset.tier, size: 58),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          (preset.nameFor(languageCode) ?? l10n.dailyCoinBoost)
                              .toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: metal.hi.withValues(alpha: 0.85),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: languageCode == 'ar' ? 0 : 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _Pill(
                        label: l10n.boostActive,
                        color: CasinoColors.raiseHi,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  BoostPercentText(
                    percent: preset.percent,
                    tier: preset.tier,
                    fontSize: 30,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.boostWinsPay(
                      preset.percent,
                      groupedAmount(preset.maxBonus),
                    ),
                    style: TextStyle(
                      color: CasinoColors.text.withValues(alpha: 0.85),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      GameIcon(
                        icon: AppIcons.timer,
                        size: 14,
                        color: metal.hi,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        l10n.boostTimeLeft(boostClock(remainingSeconds)),
                        style: TextStyle(
                          color: metal.hi,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// No boost runs: a dimmed coin and what a boost would do.
class _IdleHero extends StatelessWidget {
  const _IdleHero();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.black.withValues(alpha: 0.3),
        border: Border.all(color: CasinoColors.gold.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const GreyedOut(
            enabled: false,
            child: BoostCoin(tier: BoostTier.gold, size: 52),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.boostNoneActive,
                  style: TextStyle(
                    color: CasinoColors.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  l10n.boostNoneActiveBody,
                  style: TextStyle(
                    color: CasinoColors.textMuted,
                    fontSize: 12.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Waiting boosts of one value, activated one at a time.
class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.group,
    required this.running,
    required this.busy,
    required this.locked,
    required this.onActivate,
  });

  final BoostGroup group;
  final ActiveBoost? running;
  final bool busy;

  /// Another activation is in flight.
  final bool locked;
  final VoidCallback onActivate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final preset = group.preset;
    final metal = BoostMetal.of(preset.tier);
    final languageCode = Localizations.localeOf(context).languageCode;
    final running = this.running;
    // The server's flag is from its last answer; the clock may have moved on.
    final blocked = running != null && running.preset.percent != preset.percent;
    final extends_ = running != null && !blocked;
    final first = group.items.first;
    final label =
        extends_
            ? l10n.boostAddTime(boostDuration(first.minutes))
            : l10n.boostActivate;

    final Widget action =
        busy
            ? const SizedBox(
              width: 36,
              height: 36,
              child: Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
            )
            : GreyedOut(
              enabled: !blocked,
              child: GoldButton(
                compact: true,
                label: label,
                leading:
                    extends_
                        ? const GameIcon(icon: AppIcons.add)
                        : const GameIcon(icon: AppIcons.bolt),
                onPressed: blocked || locked ? null : onActivate,
              ),
            );

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(CasinoColors.surface, metal.lo, 0.18)!,
            CasinoColors.bg,
          ],
        ),
        border: Border.all(
          color: metal.base.withValues(alpha: blocked ? 0.25 : 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GreyedOut(
                enabled: !blocked,
                child: BoostCoin(tier: preset.tier, size: 44),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            preset.nameFor(languageCode) ?? l10n.dailyCoinBoost,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: CasinoColors.text,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (group.items.length > 1) ...[
                          const SizedBox(width: 6),
                          _Pill(
                            label: '×${group.items.length}',
                            color: metal.base,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        BoostPercentText(
                          percent: preset.percent,
                          tier: preset.tier,
                          fontSize: 17,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            group.items
                                .map((item) => boostDuration(item.minutes))
                                .join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: CasinoColors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              action,
            ],
          ),
          if (blocked) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                GameIcon(
                  icon: AppIcons.lock,
                  size: 13,
                  color: CasinoColors.textMuted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.boostWaitsFor(running.preset.percent),
                    style: TextStyle(
                      color: CasinoColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: color.withValues(alpha: 0.16),
        border: Border.all(color: color.withValues(alpha: 0.7)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          height: 1.1,
        ),
      ),
    );
  }
}

class _EmptyInventory extends StatelessWidget {
  const _EmptyInventory({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CasinoColors.gold.withValues(alpha: 0.18)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: CasinoColors.textMuted, fontSize: 13),
      ),
    );
  }
}
