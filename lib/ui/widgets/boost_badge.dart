import 'dart:math' as math;

import 'package:cardgame/data/boost/boost_models.dart';
import 'package:cardgame/ui/theme/app_icons.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/theme/game_icon.dart';
import 'package:flutter/material.dart';

/// The metal a boost tier is struck in: a lit face [hi], its body [base], the
/// shadowed rim [lo], the light it throws [glow], and [ink] for marks on it.
@immutable
class BoostMetal {
  const BoostMetal({
    required this.hi,
    required this.base,
    required this.lo,
    required this.glow,
    required this.ink,
  });

  final Color hi;
  final Color base;
  final Color lo;
  final Color glow;
  final Color ink;

  static const bronze = BoostMetal(
    hi: Color(0xFFFFD9B3),
    base: Color(0xFFD0813F),
    lo: Color(0xFF7A3F17),
    glow: Color(0xFFFF9A4D),
    ink: Color(0xFF3D1C07),
  );
  static const silver = BoostMetal(
    hi: Color(0xFFFFFFFF),
    base: Color(0xFFC9D4E0),
    lo: Color(0xFF6F7D8E),
    glow: Color(0xFFBFE0FF),
    ink: Color(0xFF26303B),
  );
  static const gold = BoostMetal(
    hi: Color(0xFFFFF1B8),
    base: Color(0xFFF5C542),
    lo: Color(0xFFA8740C),
    glow: Color(0xFFFFCF40),
    ink: Color(0xFF4A3000),
  );
  static const diamond = BoostMetal(
    hi: Color(0xFFF3E8FF),
    base: Color(0xFFA77BF3),
    lo: Color(0xFF5426B0),
    glow: Color(0xFFC59BFF),
    ink: Color(0xFF240B57),
  );

  static BoostMetal of(BoostTier tier) => switch (tier) {
    BoostTier.bronze => bronze,
    BoostTier.silver => silver,
    BoostTier.gold => gold,
    BoostTier.diamond => diamond,
  };

  /// Lit face to shadowed rim, top-left to bottom-right.
  LinearGradient get sheen => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [hi, base, lo],
    stops: const [0, 0.45, 1],
  );
}

/// "42:10" under an hour, "3:12:05" above.
String boostClock(int seconds) {
  final s = math.max(0, seconds);
  String two(int v) => v.toString().padLeft(2, '0');
  final h = s ~/ 3600;
  final m = s % 3600 ~/ 60;
  return h > 0 ? '$h:${two(m)}:${two(s % 60)}' : '${two(m)}:${two(s % 60)}';
}

/// A struck metal coin with a bolt: the mark of a Coin Boost.
class BoostCoin extends StatelessWidget {
  const BoostCoin({super.key, required this.tier, this.size = 24});

  final BoostTier tier;
  final double size;

  @override
  Widget build(BuildContext context) {
    final metal = BoostMetal.of(tier);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 0.95,
          colors: [metal.hi, metal.base, metal.lo],
          stops: const [0, 0.55, 1],
        ),
        border: Border.all(
          color: Color.lerp(metal.lo, Colors.black, 0.25)!,
          width: math.max(1, size * 0.04),
        ),
        boxShadow: [
          BoxShadow(
            color: metal.glow.withValues(alpha: 0.45),
            blurRadius: size * 0.35,
          ),
        ],
      ),
      child: Container(
        margin: EdgeInsets.all(size * 0.1),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: metal.hi.withValues(alpha: 0.65),
            width: math.max(0.8, size * 0.03),
          ),
        ),
        child: Center(
          child: GameIcon(
            icon: AppIcons.bolt,
            size: size * 0.5,
            color: metal.ink,
          ),
        ),
      ),
    );
  }
}

/// [child] inside a ring that empties as the boost runs down. [fraction] is
/// the share of the run still left, 0..1; null draws no ring.
class BoostRing extends StatelessWidget {
  const BoostRing({
    super.key,
    required this.tier,
    required this.fraction,
    required this.child,
    this.stroke = 2,
  });

  final BoostTier tier;
  final double? fraction;
  final Widget child;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    final fraction = this.fraction;
    if (fraction == null) return child;
    return CustomPaint(
      foregroundPainter: _RingPainter(
        metal: BoostMetal.of(tier),
        fraction: fraction.clamp(0.0, 1.0),
        stroke: stroke,
      ),
      child: Padding(padding: EdgeInsets.all(stroke + 1.5), child: child),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.metal,
    required this.fraction,
    required this.stroke,
  });

  final BoostMetal metal;
  final double fraction;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);
    canvas.drawArc(
      rect,
      0,
      2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = Colors.black.withValues(alpha: 0.45),
    );
    if (fraction <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * fraction,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: 3 * math.pi / 2,
          colors: [metal.hi, metal.base, metal.hi],
          transform: const GradientRotation(-math.pi / 2),
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.fraction != fraction || old.metal != metal || old.stroke != stroke;
}

/// "+25%" struck in the tier's metal, for dark backgrounds.
class BoostPercentText extends StatelessWidget {
  const BoostPercentText({
    super.key,
    required this.percent,
    required this.tier,
    this.fontSize = 14,
  });

  final int percent;
  final BoostTier tier;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final metal = BoostMetal.of(tier);
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback:
          (bounds) => LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [metal.hi, metal.base, metal.hi],
            stops: const [0, 0.6, 1],
          ).createShader(bounds),
      child: Text(
        '+$percent%',
        textDirection: TextDirection.ltr,
        style: TextStyle(
          fontFamily: CasinoFonts.display,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          height: 1.1,
          color: Colors.white,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

/// A band of light that crosses [child] once every few seconds, so a running
/// boost reads as live. Still when animations are off.
class BoostShimmer extends StatefulWidget {
  const BoostShimmer({
    super.key,
    required this.child,
    required this.borderRadius,
    this.period = const Duration(milliseconds: 4200),
  });

  final Widget child;
  final BorderRadius borderRadius;
  final Duration period;

  @override
  State<BoostShimmer> createState() => _BoostShimmerState();
}

class _BoostShimmerState extends State<BoostShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: widget.period,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _sweep.stop();
    } else if (!_sweep.isAnimating) {
      _sweep.repeat();
    }
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: ClipRRect(
              borderRadius: widget.borderRadius,
              child: CustomPaint(painter: _SweepPainter(_sweep)),
            ),
          ),
        ),
      ],
    );
  }
}

class _SweepPainter extends CustomPainter {
  _SweepPainter(this.sweep) : super(repaint: sweep);

  final Animation<double> sweep;

  /// The band crosses in this share of each period, then rests.
  static const _crossing = 0.28;

  @override
  void paint(Canvas canvas, Size size) {
    final t = sweep.value / _crossing;
    if (t <= 0 || t >= 1) return;
    final band = size.height * 1.6;
    final x = -band + (size.width + 2 * band) * Curves.easeInOut.transform(t);
    final rect = Rect.fromLTWH(x - band / 2, 0, band, size.height);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: 0.32),
            Colors.white.withValues(alpha: 0),
          ],
          transform: const GradientRotation(-0.35),
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _SweepPainter old) => false;
}

/// A metal sash across the top corner of a money pot card: the boost's
/// percent and the most it adds to this pot. Laid out in the card's design
/// pixels ([cardWidth] wide), so it scales with the card.
class BoostSash extends StatelessWidget {
  const BoostSash({
    super.key,
    required this.preset,
    required this.upToLabel,
    required this.cardWidth,
    this.start = false,
  });

  final BoostPreset preset;

  /// "up to +500".
  final String upToLabel;
  final double cardWidth;

  /// Across the top-left corner (right-to-left layouts) instead of top-right.
  final bool start;

  static const _length = 190.0;
  static const _thickness = 38.0;

  /// The sash centre sits this far in from both card edges.
  static const _inset = 44.0;

  @override
  Widget build(BuildContext context) {
    final metal = BoostMetal.of(preset.tier);
    final cx = start ? _inset : cardWidth - _inset;
    return Positioned(
      left: cx - _length / 2,
      top: _inset - _thickness / 2,
      width: _length,
      height: _thickness,
      child: IgnorePointer(
        child: Transform.rotate(
          angle: start ? -math.pi / 4 : math.pi / 4,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [metal.hi, metal.base, metal.lo],
                stops: const [0, 0.5, 1],
              ),
              border: Border.symmetric(
                horizontal: BorderSide(
                  color: Color.lerp(metal.lo, Colors.black, 0.3)!,
                ),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 52),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GameIcon(
                          icon: AppIcons.bolt,
                          size: 13,
                          color: metal.ink,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '+${preset.percent}%',
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                            fontFamily: CasinoFonts.display,
                            color: metal.ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(
                      upToLabel.toUpperCase(),
                      style: TextStyle(
                        color: metal.ink.withValues(alpha: 0.85),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The boost a seat brought into a money match, worn on the prize pill: a
/// metal divider, a coin and its percent.
class BoostPrizeSegment extends StatelessWidget {
  const BoostPrizeSegment({super.key, required this.preset});

  final BoostPreset preset;

  @override
  Widget build(BuildContext context) {
    final metal = BoostMetal.of(preset.tier);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 1.2,
          height: 26,
          margin: const EdgeInsetsDirectional.only(start: 10, end: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                metal.base.withValues(alpha: 0),
                metal.base,
                metal.base.withValues(alpha: 0),
              ],
            ),
          ),
        ),
        BoostCoin(tier: preset.tier, size: 20),
        const SizedBox(width: 5),
        BoostPercentText(
          percent: preset.percent,
          tier: preset.tier,
          fontSize: 15,
        ),
      ],
    );
  }
}

/// "Boost +25% · +50": what a boost paid on top of a won pot, for the ivory
/// game-over panel. [amount] is drawn by the caller so it can count up.
class BoostPayoutPill extends StatelessWidget {
  const BoostPayoutPill({
    super.key,
    required this.tier,
    required this.label,
    required this.amount,
  });

  final BoostTier tier;

  /// "Boost +25%".
  final String label;
  final Widget amount;

  @override
  Widget build(BuildContext context) {
    final metal = BoostMetal.of(tier);
    // Shrinks rather than overflow a narrow panel or a long translation.
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: _pill(metal),
    );
  }

  Widget _pill(BoostMetal metal) {
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(4, 4, 12, 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(metal.hi, Colors.white, 0.4)!,
            metal.hi.withValues(alpha: 0.9),
          ],
        ),
        border: Border.all(color: metal.lo.withValues(alpha: 0.8), width: 1.2),
        boxShadow: [
          BoxShadow(color: metal.glow.withValues(alpha: 0.4), blurRadius: 10),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BoostCoin(tier: tier, size: 24),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: metal.ink,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          Container(
            width: 3,
            height: 3,
            margin: const EdgeInsets.symmetric(horizontal: 7),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: metal.ink.withValues(alpha: 0.5),
            ),
          ),
          amount,
        ],
      ),
    );
  }
}
