import 'dart:async';
import 'dart:math' as math;

import 'package:cardgame/app/auth_providers.dart';
import 'package:cardgame/data/avatars/avatar_catalog.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/widgets/amount_format.dart';
import 'package:cardgame/ui/widgets/currency_icon.dart';
import 'package:cardgame/ui/widgets/hud_counter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where the home top bar's money and chip counters sit, so rewards can fly
/// into them. The top bar puts these keys on its two counters.
abstract final class HudAnchors {
  static final money = GlobalKey(debugLabel: 'hud-money');
  static final chips = GlobalKey(debugLabel: 'hud-chips');

  static GlobalKey of(CurrencyType currency) =>
      currency == CurrencyType.chips ? chips : money;

  /// Global centre of the counter's coin, or null when it isn't on screen.
  static Offset? targetOf(CurrencyType currency) {
    final context = of(currency).currentContext;
    final rect = rectOf(currency);
    if (context == null || rect == null) return null;
    // The coin sits at the counter's start edge and is 30px wide.
    final rtl = Directionality.maybeOf(context) == TextDirection.rtl;
    return Offset(rtl ? rect.right - 15 : rect.left + 15, rect.center.dy);
  }

  /// The counter's global bounds, or null when it isn't on screen.
  static Rect? rectOf(CurrencyType currency) {
    final box = of(currency).currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }
}

/// Flies [count] coins (or chips) from [from] into the matching top-bar
/// counter, above every route, then pops "+[amount]" beside it. The counter
/// usually sits under a modal's scrim, so a lit copy of it shows above
/// everything while the coins land. [onLand] runs as the first coin lands,
/// so both count up while the rest arrive. Completes once the last one is
/// gone. With animations off it only calls [onLand].
Future<void> flyRewardToHud(
  BuildContext context, {
  required CurrencyType currency,
  required Offset from,
  required int amount,
  int count = 8,
  VoidCallback? onLand,
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null || MediaQuery.disableAnimationsOf(context)) {
    onLand?.call();
    return Future.value();
  }
  final screen = MediaQuery.sizeOf(context);
  final hud = HudAnchors.rectOf(currency);
  final target =
      HudAnchors.targetOf(currency) ??
      Offset(screen.width / 2, MediaQuery.paddingOf(context).top + 24);
  final done = Completer<void>();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder:
        (_) => _FlyLayer(
          currency: currency,
          from: from,
          to: target,
          hud: hud,
          amount: amount,
          count: count,
          onLand: onLand,
          onDone: () {
            entry.remove();
            if (!done.isCompleted) done.complete();
          },
        ),
  );
  overlay.insert(entry);
  return done.future;
}

class _Coin {
  const _Coin(this.delay, this.bend, this.spin, this.spread);

  /// Start, as a fraction of the whole flight.
  final double delay;

  /// Sideways pull of the arc, -1..1.
  final double bend;
  final double spin;

  /// Where the coin bursts to before it heads for the counter.
  final Offset spread;
}

class _FlyLayer extends StatefulWidget {
  const _FlyLayer({
    required this.currency,
    required this.from,
    required this.to,
    required this.hud,
    required this.amount,
    required this.count,
    required this.onLand,
    required this.onDone,
  });

  final CurrencyType currency;
  final Offset from;
  final Offset to;

  /// The top-bar counter's bounds, lit up while the coins land.
  final Rect? hud;
  final int amount;
  final int count;
  final VoidCallback? onLand;
  final VoidCallback onDone;

  @override
  State<_FlyLayer> createState() => _FlyLayerState();
}

class _FlyLayerState extends State<_FlyLayer> with TickerProviderStateMixin {
  static const _flight = 0.42;
  static const _burst = 0.12;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  );

  /// The lit counter: in as the coins arrive, held while it counts up, out.
  late final AnimationController _echo = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  );
  late final List<_Coin> _coins = _makeCoins();
  bool _landed = false;
  bool _done = false;

  List<_Coin> _makeCoins() {
    final rnd = math.Random(widget.amount + widget.count);
    return List.generate(widget.count, (i) {
      final angle = rnd.nextDouble() * 2 * math.pi;
      final radius = 18 + rnd.nextDouble() * 34;
      return _Coin(
        i * 0.045,
        rnd.nextDouble() * 2 - 1,
        (rnd.nextDouble() - 0.5) * 6,
        Offset(math.cos(angle) * radius, math.sin(angle) * radius),
      );
    });
  }

  double get _firstLanding => _coins.first.delay + _burst + _flight;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_watchLanding);
    _controller.addStatusListener((_) => _finishWhenSettled());
    _echo.addStatusListener((_) => _finishWhenSettled());
    _controller.forward();
  }

  void _watchLanding() {
    final t = _controller.value;
    // Light the counter just before the first coin reaches it.
    if (widget.hud != null && !_echo.isAnimating && _echo.value == 0) {
      if (t >= _firstLanding - 0.1) _echo.forward();
    }
    if (_landed || t < _firstLanding) return;
    _landed = true;
    HapticFeedback.lightImpact();
    widget.onLand?.call();
  }

  void _finishWhenSettled() {
    final echoing = widget.hud != null && !_echo.isCompleted;
    if (_done || !_controller.isCompleted || echoing) return;
    _done = true;
    widget.onDone();
  }

  @override
  void dispose() {
    _controller.dispose();
    _echo.dispose();
    super.dispose();
  }

  /// Position, scale and opacity of [coin] at time [t], or null before it
  /// starts and after it lands.
  (Offset, double, double)? _place(_Coin coin, double t) {
    final local = (t - coin.delay) / (_burst + _flight);
    if (local <= 0 || local >= 1) return null;
    final burstShare = _burst / (_burst + _flight);
    if (local < burstShare) {
      final b = Curves.easeOutCubic.transform(local / burstShare);
      return (widget.from + coin.spread * b, 0.7 + 0.3 * b, b);
    }
    final p = Curves.easeInCubic.transform(
      (local - burstShare) / (1 - burstShare),
    );
    final start = widget.from + coin.spread;
    final control = Offset(
      (start.dx + widget.to.dx) / 2 + coin.bend * 120,
      math.min(start.dy, widget.to.dy) - 60,
    );
    final q = 1 - p;
    final position =
        start * (q * q) + control * (2 * q * p) + widget.to * (p * p);
    return (position, 1 - 0.35 * p, 1);
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.maybeLocaleOf(context) ?? const Locale('en');
    final hud = widget.hud;
    // Overlay entries carry no Material, so text would take the framework's
    // fallback style.
    return Material(
      type: MaterialType.transparency,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: Listenable.merge([_controller, _echo]),
          builder: (context, _) {
            final t = _controller.value;
            final popT = ((t - _firstLanding) / (1 - _firstLanding)).clamp(
              0.0,
              1.0,
            );
            final e = _echo.value;
            final echo = e < 0.1 ? e / 0.1 : (e > 0.75 ? (1 - e) / 0.25 : 1.0);
            return Stack(
              children: [
                if (hud != null && e > 0)
                  Positioned.fromRect(
                    rect: hud,
                    child: Opacity(
                      opacity: echo.clamp(0.0, 1.0),
                      child: _LitCounter(currency: widget.currency),
                    ),
                  ),
                for (final coin in _coins)
                  if (_place(coin, t) case (
                    final at,
                    final scale,
                    final opacity,
                  ))
                    Positioned(
                      left: at.dx - 13,
                      top: at.dy - 13,
                      child: Opacity(
                        opacity: opacity,
                        child: Transform.rotate(
                          angle: coin.spin * t,
                          child: Transform.scale(
                            scale: scale,
                            child: CurrencyIcon(
                              currency: widget.currency,
                              size: 26,
                            ),
                          ),
                        ),
                      ),
                    ),
                // "+amount" drifts up from just under the counter.
                if (_landed)
                  Positioned(
                    left: hud?.center.dx ?? widget.to.dx,
                    top: (hud?.bottom ?? widget.to.dy + 14) + 8 - 10 * popT,
                    child: FractionalTranslation(
                      translation: const Offset(-0.5, 0),
                      child: Opacity(
                        opacity: popT < 0.7 ? 1 : (1 - popT) / 0.3,
                        child: Text(
                          '+${groupedAmount(widget.amount)}',
                          style: TextStyle(
                            fontFamily: CasinoFonts.displayFor(locale),
                            color: CasinoColors.goldSoft,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            shadows: const [
                              Shadow(color: Color(0xCC000000), blurRadius: 6),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The top-bar counter, lit, showing the live balance as it counts up.
class _LitCounter extends ConsumerWidget {
  const _LitCounter({required this.currency});

  final CurrencyType currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(
      playerProfileProvider.select(
        (profile) =>
            currency == CurrencyType.chips
                ? profile.value?.chips
                : profile.value?.money,
      ),
    );
    return HudCounter(currency: currency, value: balance ?? 0, lit: true);
  }
}
