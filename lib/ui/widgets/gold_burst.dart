import 'dart:math' as math;

import 'package:cardgame/ui/flame/suit_shapes.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:flutter/material.dart';

/// Slowly turning gold rays that fade out radially, so the burst has no
/// visible edge. [t] loops 0..1 for one full turn; [center] is where the rays
/// start, as a fraction of the canvas.
class GoldRaysPainter extends CustomPainter {
  const GoldRaysPainter({
    required this.t,
    this.center = const Offset(0.5, 0.43),
    this.intensity = 1,
  });

  final double t;
  final Offset center;

  /// Scales the rays' opacity, 0 (hidden) to 1.
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    if (intensity <= 0) return;
    final c = Offset(size.width * center.dx, size.height * center.dy);
    final radius = size.width * 0.5;
    const rays = 20;
    final paint =
        Paint()
          ..shader = RadialGradient(
            colors: [
              CasinoColors.gold.withValues(alpha: 0.28 * intensity),
              CasinoColors.gold.withValues(alpha: 0.07 * intensity),
              CasinoColors.gold.withValues(alpha: 0),
            ],
            stops: const [0, 0.45, 1],
          ).createShader(Rect.fromCircle(center: c, radius: radius));
    final base = t * 2 * math.pi;
    for (var i = 0; i < rays; i++) {
      final a0 = base + i * 2 * math.pi / rays;
      final a1 = a0 + math.pi / rays * 0.8;
      canvas.drawPath(
        Path()
          ..moveTo(c.dx, c.dy)
          ..lineTo(c.dx + math.cos(a0) * radius, c.dy + math.sin(a0) * radius)
          ..lineTo(c.dx + math.cos(a1) * radius, c.dy + math.sin(a1) * radius)
          ..close(),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant GoldRaysPainter old) =>
      old.t != t || old.center != center || old.intensity != intensity;
}

class _Particle {
  const _Particle(
    this.x,
    this.y0,
    this.speed,
    this.sway,
    this.phase,
    this.spin,
    this.size,
    this.shape,
    this.role,
  );

  final double x;
  final double y0;
  final int speed;
  final int sway;
  final double phase;
  final int spin;
  final double size;
  final int shape;

  /// Index into [_confettiColor]. Resolved at paint time, so the particles
  /// created once and cached in [ConfettiPainter] follow the active theme.
  final int role;

  Color get color => _confettiColor(role);
}

/// Confetti colour for a [_Particle.role]; the loss ember is -1.
Color _confettiColor(int role) => switch (role) {
  0 => CasinoColors.gold,
  1 => CasinoColors.goldSoft,
  2 => Colors.white,
  3 => const Color(0xFFE53935),
  4 => const Color(0xFF26A69A),
  _ => const Color(0xFF7A1A1A).withValues(alpha: 0.5),
};

/// Full-screen falling confetti (gold suits and ribbons) for a win, or slow
/// dim spades for a loss. Every motion is an integer number of cycles per
/// [t] loop so the animation wraps seamlessly.
class ConfettiPainter extends CustomPainter {
  ConfettiPainter({required this.t, required this.win});

  final double t;
  final bool win;

  static final List<_Particle> _winParts = _make(win: true);
  static final List<_Particle> _loseParts = _make(win: false);

  static List<_Particle> _make({required bool win}) {
    final rnd = math.Random(win ? 11 : 5);
    final count = win ? 44 : 14;
    return List.generate(count, (i) {
      return _Particle(
        rnd.nextDouble(),
        rnd.nextDouble(),
        win ? 2 + rnd.nextInt(3) : 1,
        1 + rnd.nextInt(3),
        rnd.nextDouble(),
        1 + rnd.nextInt(4),
        win ? 7 + rnd.nextDouble() * 8 : 14 + rnd.nextDouble() * 12,
        win ? rnd.nextInt(5) : 0,
        win ? rnd.nextInt(5) : -1,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final parts = win ? _winParts : _loseParts;
    for (final p in parts) {
      final fy = (p.y0 + t * p.speed) % 1.0;
      final dx = math.sin(2 * math.pi * (t * p.sway + p.phase)) * 14;
      final pos = Offset(p.x * size.width + dx, fy * (size.height + 60) - 30);
      final angle = 2 * math.pi * (t * p.spin + p.phase);
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(angle);
      final paint = Paint()..color = p.color;
      if (p.shape >= 4) {
        // Ribbon.
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size * 0.5,
            height: p.size * 1.6,
          ),
          paint,
        );
      } else {
        final suit = win ? SuitShape.values[p.shape % 4] : SuitShape.spades;
        canvas.scale(p.size);
        canvas.drawPath(suitPath(suit), paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant ConfettiPainter old) =>
      old.t != t || old.win != win;
}

class _Shard {
  const _Shard(
    this.angle,
    this.speed,
    this.spin,
    this.size,
    this.shape,
    this.role,
  );

  final double angle;
  final double speed;
  final double spin;
  final double size;

  /// 0..3 a suit, 4 a four-point spark.
  final int shape;
  final int role;
}

/// One-shot burst of gold suits and sparks thrown out from [origin] (as a
/// fraction of the canvas), falling back under gravity as they fade. [t] runs
/// 0..1 once; [big] throws more, wider, for a jackpot.
class GoldBurstPainter extends CustomPainter {
  GoldBurstPainter({
    required this.t,
    this.origin = const Offset(0.5, 0.42),
    this.big = false,
  });

  final double t;
  final Offset origin;
  final bool big;

  static final List<_Shard> _small = _make(28, 3);
  static final List<_Shard> _large = _make(56, 9);

  static List<_Shard> _make(int count, int seed) {
    final rnd = math.Random(seed);
    return List.generate(count, (i) {
      return _Shard(
        rnd.nextDouble() * 2 * math.pi,
        0.35 + rnd.nextDouble() * 0.65,
        (rnd.nextDouble() - 0.5) * 8,
        6 + rnd.nextDouble() * 9,
        rnd.nextInt(6) > 3 ? 4 : rnd.nextInt(4),
        rnd.nextInt(3),
      );
    });
  }

  static void _spark(Canvas canvas, double size, Paint paint) {
    final s = size / 2;
    final w = s * 0.28;
    canvas.drawPath(
      Path()
        ..moveTo(0, -s)
        ..quadraticBezierTo(w, -w, s, 0)
        ..quadraticBezierTo(w, w, 0, s)
        ..quadraticBezierTo(-w, w, -s, 0)
        ..quadraticBezierTo(-w, -w, 0, -s)
        ..close(),
      paint,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final shards = big ? _large : _small;
    final center = Offset(size.width * origin.dx, size.height * origin.dy);
    final reach = size.shortestSide * (big ? 0.62 : 0.48);
    final travel = Curves.easeOutCubic.transform(t);
    final fade = math.pow(1 - t, 1.4).toDouble();
    for (final shard in shards) {
      final distance = reach * shard.speed * travel;
      // Gravity pulls the shards down as the throw slows.
      final drop = reach * 0.35 * t * t;
      final pos =
          center +
          Offset(
            math.cos(shard.angle) * distance,
            math.sin(shard.angle) * distance + drop,
          );
      final color = switch (shard.role) {
        0 => CasinoColors.gold,
        1 => CasinoColors.goldSoft,
        _ => Colors.white,
      };
      final paint = Paint()..color = color.withValues(alpha: fade);
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(shard.spin * t);
      final scale = 1 - t * 0.35;
      if (shard.shape == 4) {
        _spark(canvas, shard.size * 1.3 * scale, paint);
      } else {
        final glyph = shard.size * scale;
        canvas.translate(-glyph / 2, -glyph / 2);
        canvas.scale(glyph);
        canvas.drawPath(suitPath(SuitShape.values[shard.shape]), paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant GoldBurstPainter old) =>
      old.t != t || old.origin != origin || old.big != big;
}
