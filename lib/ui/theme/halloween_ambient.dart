import 'dart:math' as math;

import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:flutter/material.dart';

/// Halloween backdrop drawn over the whole app: a moon, cobwebs and haze that
/// sit still, with bats, fog and embers drifting over them. Painted in code,
/// so it needs no assets, and it ignores touches.
///
/// [animated] false, or the system's reduce-motion setting, freezes it on one
/// frame. The still layer is painted once; only the drift layer repaints.
class HalloweenAmbient extends StatefulWidget {
  const HalloweenAmbient({super.key, required this.animated});

  final bool animated;

  @override
  State<HalloweenAmbient> createState() => _HalloweenAmbientState();
}

class _HalloweenAmbientState extends State<HalloweenAmbient>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 90),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didUpdateWidget(HalloweenAmbient oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMotion();
  }

  void _syncMotion() {
    final still = !widget.animated || MediaQuery.disableAnimationsOf(context);
    if (still) {
      _drift.stop();
    } else if (!_drift.isAnimating) {
      _drift.repeat();
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const RepaintBoundary(
            child: CustomPaint(painter: _StillPainter(), size: Size.infinite),
          ),
          RepaintBoundary(
            child: CustomPaint(
              painter: _DriftPainter(_drift),
              size: Size.infinite,
            ),
          ),
        ],
      ),
    );
  }
}

/// Fractional part, always in 0..1, so wrapped motion stays continuous.
double _frac(double x) => x - x.floorToDouble();

/// Moon, cobwebs and a violet haze. Colours are read at paint time, so a
/// theme switch repaints it without the painter being rebuilt.
class _StillPainter extends CustomPainter {
  const _StillPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.center,
          colors: [
            CasinoColors.check.withValues(alpha: 0.16),
            Colors.transparent,
          ],
        ).createShader(rect),
    );

    final reach = size.shortestSide * 0.42;
    _cobweb(canvas, Offset.zero, 1, reach);
    _cobweb(canvas, Offset(size.width, 0), -1, reach);
    _moon(canvas, size);
  }

  void _moon(Canvas canvas, Size size) {
    final radius = size.shortestSide * 0.075;
    final centre = Offset(size.width * 0.8, size.height * 0.14);
    final glow = Rect.fromCircle(center: centre, radius: radius * 3.2);
    canvas.drawCircle(
      centre,
      radius * 3.2,
      Paint()
        ..shader = RadialGradient(
          colors: [
            CasinoColors.goldSoft.withValues(alpha: 0.22),
            Colors.transparent,
          ],
        ).createShader(glow),
    );
    canvas.drawCircle(
      centre,
      radius,
      Paint()..color = CasinoColors.silver.withValues(alpha: 0.88),
    );
    final crater =
        Paint()..color = CasinoColors.textMuted.withValues(alpha: 0.18);
    canvas.drawCircle(
      centre + Offset(-radius * 0.35, -radius * 0.2),
      radius * 0.22,
      crater,
    );
    canvas.drawCircle(
      centre + Offset(radius * 0.3, radius * 0.25),
      radius * 0.16,
      crater,
    );
    canvas.drawCircle(
      centre + Offset(-radius * 0.1, radius * 0.45),
      radius * 0.1,
      crater,
    );
  }

  /// A web anchored at [corner]. [sign] mirrors it to the right-hand corner.
  void _cobweb(Canvas canvas, Offset corner, double sign, double reach) {
    final line =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = CasinoColors.silver.withValues(alpha: 0.2);
    const spokes = 6;
    for (var i = 0; i <= spokes; i++) {
      final angle = (math.pi / 2) * i / spokes;
      final dir = Offset(math.cos(angle) * sign, math.sin(angle));
      canvas.drawLine(corner, corner + dir * reach, line);
    }
    final start = sign > 0 ? 0.0 : math.pi / 2;
    for (var ring = 1; ring <= 4; ring++) {
      final r = reach * ring / 4;
      canvas.drawArc(
        Rect.fromCircle(center: corner, radius: r),
        start,
        math.pi / 2,
        false,
        line,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StillPainter oldDelegate) => false;
}

class _Bat {
  const _Bat(this.x0, this.y0, this.crossings, this.bobCycles, this.scale);

  /// Start across the screen (0..1) and height in the top half (0..1).
  final double x0;
  final double y0;

  /// Screen widths flown per drift loop, and bob cycles per loop.
  final int crossings;
  final int bobCycles;
  final double scale;
}

const _bats = [
  _Bat(0.10, 0.18, 9, 6, 1.0),
  _Bat(0.55, 0.10, 11, 7, 0.7),
  _Bat(0.30, 0.34, 10, 8, 0.85),
  _Bat(0.80, 0.26, 12, 5, 0.6),
];

class _Ember {
  const _Ember(
    this.x0,
    this.y0,
    this.rise,
    this.wobble,
    this.phase,
    this.radius,
  );

  final double x0;
  final double y0;
  final int rise;
  final int wobble;
  final double phase;
  final double radius;
}

/// Seeded once, so the embers are the same on every launch.
final _emberSeeds = () {
  final rng = math.Random(7);
  return List.generate(
    18,
    (_) => _Ember(
      rng.nextDouble(),
      rng.nextDouble(),
      2 + rng.nextInt(3),
      1 + rng.nextInt(3),
      rng.nextDouble(),
      1.2 + rng.nextDouble() * 1.2,
    ),
  );
}();

/// Bats, fog and embers. Every motion repeats a whole number of times per
/// drift loop, so the loop wraps without a jump.
class _DriftPainter extends CustomPainter {
  _DriftPainter(this.drift) : super(repaint: drift);

  final Animation<double> drift;

  @override
  void paint(Canvas canvas, Size size) {
    final t = drift.value;
    _fog(canvas, size, t);
    final span = size.shortestSide * 0.045;
    for (final bat in _bats) {
      final x =
          _frac(bat.x0 + t * bat.crossings) * (size.width + span * 4) -
          span * 2;
      final y =
          bat.y0 * size.height +
          math.sin(2 * math.pi * t * bat.bobCycles) * span * 1.5;
      final flap = math.sin(2 * math.pi * t * 180) * span * 0.45;
      _bat(canvas, Offset(x, y), span * bat.scale, flap);
    }
    _embers(canvas, size, t);
  }

  void _fog(Canvas canvas, Size size, double t) {
    for (var band = 0; band < 3; band++) {
      final top = size.height * (0.58 + 0.14 * band);
      final height = size.height * 0.16;
      final tile = Rect.fromLTWH(0, top, size.width, height);
      final shader = LinearGradient(
        colors: [
          Colors.transparent,
          CasinoColors.borderGlow.withValues(alpha: 0.09),
          Colors.transparent,
        ],
        stops: const [0, 0.5, 1],
        tileMode: TileMode.repeated,
      ).createShader(tile);
      final shift = _frac(t * (band + 1)) * size.width;
      canvas.save();
      canvas.translate(shift, 0);
      canvas.drawRect(
        Rect.fromLTWH(-size.width, top, size.width * 3, height),
        Paint()..shader = shader,
      );
      canvas.restore();
    }
  }

  void _bat(Canvas canvas, Offset c, double span, double flap) {
    final body = Paint()..color = CasinoColors.bg.withValues(alpha: 0.85);
    canvas.drawPath(_wing(c, span, flap, 1), body);
    canvas.drawPath(_wing(c, span, flap, -1), body);
    canvas.drawOval(
      Rect.fromCenter(center: c, width: span * 0.32, height: span * 0.5),
      body,
    );
  }

  /// One wing; [side] is 1 for the right wing and -1 for the left.
  Path _wing(Offset c, double span, double flap, double side) {
    return Path()
      ..moveTo(c.dx, c.dy)
      ..quadraticBezierTo(
        c.dx + side * span * 0.5,
        c.dy - span * 0.8 - flap,
        c.dx + side * span,
        c.dy - span * 0.1 - flap * 0.5,
      )
      ..quadraticBezierTo(
        c.dx + side * span * 0.75,
        c.dy + span * 0.3,
        c.dx + side * span * 0.5,
        c.dy + span * 0.12,
      )
      ..quadraticBezierTo(
        c.dx + side * span * 0.25,
        c.dy + span * 0.3,
        c.dx,
        c.dy,
      )
      ..close();
  }

  void _embers(Canvas canvas, Size size, double t) {
    for (final e in _emberSeeds) {
      final p = _frac(e.y0 + t * e.rise);
      final x =
          size.width *
          (e.x0 + 0.015 * math.sin(2 * math.pi * (t * e.wobble + e.phase)));
      final y = size.height * (1 - p);
      final alpha = 0.55 * math.sin(math.pi * p);
      canvas.drawCircle(
        Offset(x, y),
        e.radius,
        Paint()..color = CasinoColors.goldSoft.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DriftPainter oldDelegate) => false;
}
