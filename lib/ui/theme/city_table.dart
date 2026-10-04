import 'dart:math' as math;

import 'package:cardgame/ui/theme/city_theme.dart';
import 'package:flutter/material.dart';

/// Full-stage custom table for a pot city, painted once and cached.
class CityTable extends StatelessWidget {
  const CityTable({super.key, required this.city});

  final CityTheme city;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(painter: CityTablePainter(city), size: Size.infinite),
    );
  }
}

const _gold = Color(0xFFF5C542);

/// Paints backdrop, rail, felt and ornaments. Tiers 0–4 add detail:
/// 0 plain · 1 lattice + brass · 2 studs + rosettes · 3 sun + meander ·
/// 4 zellige stars + jewels + sparkle.
class CityTablePainter extends CustomPainter {
  const CityTablePainter(this.city);

  final CityTheme city;

  @override
  void paint(Canvas canvas, Size size) {
    final tier = city.tier;
    _backdrop(canvas, size);

    final inset = size.width * 0.035;
    final outer = Rect.fromLTRB(
      inset,
      size.height * 0.012 + inset * 0.5,
      size.width - inset,
      size.height * 0.988 - inset * 0.5,
    );
    final railWidth = size.width * (0.045 + tier * 0.004);
    final rail = _stadium(outer);
    final feltRect = outer.deflate(railWidth);
    final felt = _stadium(feltRect);

    _rail(canvas, outer, rail, feltRect);
    _felt(canvas, feltRect, felt);

    canvas.save();
    canvas.clipRRect(felt);
    switch (tier) {
      case 0:
        break;
      case 1:
        _lattice(canvas, feltRect, 44, city.accent.withValues(alpha: 0.10));
      case 2:
        _lattice(canvas, feltRect, 60, city.accent.withValues(alpha: 0.07));
        _rosettes(canvas, feltRect, 60);
      case 3:
        _sunRays(canvas, feltRect);
        _meander(canvas, felt);
      default:
        _zellige(canvas, feltRect);
    }
    canvas.restore();

    _inlays(canvas, felt);
    _railOrnaments(canvas, rail, railWidth);
    _centreRing(canvas, feltRect, size);
    if (tier >= 4) _sparkles(canvas, size);
  }

  RRect _stadium(Rect r) =>
      RRect.fromRectAndRadius(r, Radius.circular(r.width / 2));

  void _backdrop(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.1),
          radius: 1.1,
          colors: [
            Color.lerp(city.backdrop, city.accent, 0.10 + city.tier * 0.03)!,
            city.backdrop,
          ],
        ).createShader(rect),
    );
    if (city.tier >= 3) {
      // Warm glow behind the table.
      canvas.drawCircle(
        rect.center,
        size.width * 0.9,
        Paint()
          ..shader = RadialGradient(
            colors: [
              city.railLight.withValues(alpha: city.tier >= 4 ? 0.30 : 0.20),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(center: rect.center, radius: size.width * 0.9),
          ),
      );
    }
  }

  void _rail(Canvas canvas, Rect outer, RRect rail, Rect feltRect) {
    canvas.drawRRect(
      rail.shift(const Offset(0, 8)),
      Paint()
        ..color = const Color(0xAA000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    final metallic = city.tier >= 1;
    canvas.drawRRect(
      rail,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              metallic
                  ? [
                    city.railLight,
                    city.railDark,
                    city.railLight,
                    city.railDark,
                  ]
                  : [city.railLight, city.railDark],
          stops: metallic ? const [0, 0.35, 0.6, 1] : null,
        ).createShader(outer),
    );
    // Specular edge.
    canvas.drawRRect(
      rail.deflate(1.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Colors.white.withValues(alpha: metallic ? 0.35 : 0.12),
    );
    if (!metallic) {
      // Wood grain.
      final grain =
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = Colors.black.withValues(alpha: 0.18);
      for (var i = 1; i <= 3; i++) {
        canvas.drawRRect(
          rail.deflate(i * (outer.width - feltRect.width) / 8),
          grain,
        );
      }
    }
  }

  void _felt(Canvas canvas, Rect feltRect, RRect felt) {
    canvas.drawRRect(
      felt,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.1),
          radius: 0.95,
          colors: [city.feltLight, city.feltDark],
        ).createShader(feltRect),
    );
    // Shadow where the felt tucks under the rail.
    canvas.save();
    canvas.clipRRect(felt);
    canvas.drawRRect(
      felt.inflate(6),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..color = const Color(0x77000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.restore();
  }

  void _inlays(Canvas canvas, RRect felt) {
    final tier = city.tier;
    final line =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = tier >= 2 ? 1.6 : 1.1
          ..color = (tier >= 2 ? _gold : city.accent).withValues(alpha: 0.55);
    canvas.drawRRect(felt.deflate(7), line);
    if (tier == 0) {
      // Stitched seam.
      _dashed(
        canvas,
        felt.deflate(13),
        city.accent.withValues(alpha: 0.25),
        6,
        5,
      );
    }
    if (tier >= 2) {
      canvas.drawRRect(felt.deflate(13), line..strokeWidth = 0.9);
    }
    if (tier >= 4) {
      canvas.drawRRect(
        felt.deflate(19),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = _gold.withValues(alpha: 0.45),
      );
    }
  }

  void _dashed(
    Canvas canvas,
    RRect rrect,
    Color color,
    double dash,
    double gap,
  ) {
    final paint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = color;
    for (final m in (Path()..addRRect(rrect)).computeMetrics()) {
      for (var d = 0.0; d < m.length; d += dash + gap) {
        canvas.drawPath(m.extractPath(d, math.min(d + dash, m.length)), paint);
      }
    }
  }

  void _centreRing(Canvas canvas, Rect feltRect, Size size) {
    final c = feltRect.center;
    final r = size.width * 0.3;
    final ring =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = (city.tier >= 2 ? _gold : city.accent).withValues(
            alpha: 0.32 + city.tier * 0.06,
          );
    canvas.drawCircle(c, r, ring);
    if (city.tier >= 2) canvas.drawCircle(c, r - 6, ring..strokeWidth = 0.9);
  }

  // ---- felt patterns -----------------------------------------------------

  void _lattice(Canvas canvas, Rect rect, double cell, Color color) {
    final p =
        Paint()
          ..strokeWidth = 1
          ..color = color;
    final span = rect.width + rect.height;
    for (var d = -rect.height; d < span; d += cell) {
      canvas.drawLine(
        Offset(rect.left + d, rect.top),
        Offset(rect.left + d + rect.height, rect.bottom),
        p,
      );
      canvas.drawLine(
        Offset(rect.left + d + rect.height, rect.top),
        Offset(rect.left + d, rect.bottom),
        p,
      );
    }
  }

  void _rosettes(Canvas canvas, Rect rect, double cell) {
    final p = Paint()..color = _gold.withValues(alpha: 0.16);
    var row = 0;
    for (var y = rect.top; y < rect.bottom + cell; y += cell, row++) {
      final shift = row.isOdd ? cell / 2 : 0.0;
      for (var x = rect.left + shift; x < rect.right + cell; x += cell) {
        for (var k = 0; k < 4; k++) {
          final a = k * math.pi / 2;
          canvas.drawCircle(
            Offset(x + math.cos(a) * 4.5, y + math.sin(a) * 4.5),
            3,
            p,
          );
        }
        canvas.drawCircle(Offset(x, y), 2, p);
      }
    }
  }

  void _sunRays(Canvas canvas, Rect rect) {
    final c = rect.center;
    final radius = rect.height;
    final p = Paint()..color = _gold.withValues(alpha: 0.05);
    const rays = 24;
    for (var i = 0; i < rays; i += 2) {
      final a0 = i * 2 * math.pi / rays;
      final a1 = (i + 1) * 2 * math.pi / rays;
      canvas.drawPath(
        Path()
          ..moveTo(c.dx, c.dy)
          ..lineTo(c.dx + math.cos(a0) * radius, c.dy + math.sin(a0) * radius)
          ..lineTo(c.dx + math.cos(a1) * radius, c.dy + math.sin(a1) * radius)
          ..close(),
        p,
      );
    }
    canvas.drawCircle(
      c,
      rect.width * 0.12,
      Paint()
        ..shader = RadialGradient(
          colors: [_gold.withValues(alpha: 0.35), Colors.transparent],
        ).createShader(Rect.fromCircle(center: c, radius: rect.width * 0.12)),
    );
  }

  /// Greek-key style border: stepped ticks along the felt edge.
  void _meander(Canvas canvas, RRect felt) {
    final path = Path()..addRRect(felt.deflate(26));
    final p =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = _gold.withValues(alpha: 0.38);
    for (final m in path.computeMetrics()) {
      var i = 0;
      for (var d = 0.0; d < m.length; d += 12, i++) {
        final t = m.getTangentForOffset(d);
        if (t == null) continue;
        final n = Offset(-t.vector.dy, t.vector.dx);
        final len = i.isEven ? 7.0 : 3.0;
        canvas.drawLine(t.position, t.position + n * len, p);
      }
    }
  }

  void _zellige(Canvas canvas, Rect rect) {
    const cell = 64.0;
    final fill = Paint()..color = city.accent.withValues(alpha: 0.10);
    final edge =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = _gold.withValues(alpha: 0.28);
    for (var y = rect.top; y < rect.bottom + cell; y += cell) {
      for (var x = rect.left; x < rect.right + cell; x += cell) {
        final star = _star(Offset(x, y), 26, 14, 8, math.pi / 8);
        canvas.drawPath(star, fill);
        canvas.drawPath(star, edge);
        // Interlocking tile centre between stars.
        canvas.drawPath(
          _star(Offset(x + cell / 2, y + cell / 2), 10, 5, 4, math.pi / 4),
          edge,
        );
      }
    }
    final c = rect.center;
    canvas.drawPath(
      _star(c, rect.width * 0.42, rect.width * 0.34, 16, 0),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = _gold.withValues(alpha: 0.32),
    );
  }

  Path _star(Offset c, double outer, double inner, int points, double rot) {
    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final r = i.isEven ? outer : inner;
      final a = rot + i * math.pi / points;
      final pt = Offset(c.dx + math.cos(a) * r, c.dy + math.sin(a) * r);
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    return path..close();
  }

  // ---- rail ornaments ----------------------------------------------------

  void _railOrnaments(Canvas canvas, RRect rail, double railWidth) {
    final tier = city.tier;
    if (tier == 1) {
      // Brass pinstripe along the rail centre.
      canvas.drawRRect(
        rail.deflate(railWidth / 2),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Colors.black.withValues(alpha: 0.35),
      );
      return;
    }
    if (tier == 0) return;

    final path = Path()..addRRect(rail.deflate(railWidth / 2));
    const gems = [Color(0xFFE53935), Color(0xFF1E88E5), Color(0xFF43A047)];
    for (final m in path.computeMetrics()) {
      final step = tier >= 4 ? 30.0 : 24.0;
      var i = 0;
      for (var d = step / 2; d < m.length; d += step, i++) {
        final pos = m.getTangentForOffset(d)!.position;
        if (tier >= 4) {
          _gem(canvas, pos, i.isEven ? 6 : 4, gems[i % gems.length], i.isEven);
        } else {
          final big = tier == 3 && i % 4 == 0;
          _stud(canvas, pos, big ? 4.2 : 2.6);
        }
      }
    }
  }

  void _stud(Canvas canvas, Offset p, double r) {
    canvas.drawCircle(
      p.translate(0, 1),
      r,
      Paint()..color = const Color(0x88000000),
    );
    canvas.drawCircle(
      p,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.4, -0.4),
          colors: [Colors.white, _gold, Color(0xFF8A6119)],
          stops: [0, 0.45, 1],
        ).createShader(Rect.fromCircle(center: p, radius: r)),
    );
  }

  void _gem(Canvas canvas, Offset p, double r, Color color, bool faceted) {
    canvas.drawCircle(
      p.translate(0, 1.2),
      r + 1.4,
      Paint()..color = const Color(0x88000000),
    );
    // Gold bezel.
    canvas.drawCircle(p, r + 1.4, Paint()..color = const Color(0xFF8A6119));
    canvas.drawCircle(
      p,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.4),
          colors: [Colors.white, color, Color.lerp(color, Colors.black, 0.5)!],
          stops: const [0, 0.4, 1],
        ).createShader(Rect.fromCircle(center: p, radius: r)),
    );
    if (faceted) {
      canvas.drawCircle(
        p.translate(-r * 0.3, -r * 0.3),
        r * 0.22,
        Paint()..color = Colors.white.withValues(alpha: 0.9),
      );
    }
  }

  void _sparkles(Canvas canvas, Size size) {
    final rnd = math.Random(7);
    final p = Paint()..color = Colors.white.withValues(alpha: 0.85);
    for (var i = 0; i < 14; i++) {
      final c = Offset(
        size.width * (0.12 + rnd.nextDouble() * 0.76),
        size.height * (0.05 + rnd.nextDouble() * 0.9),
      );
      final r = 3 + rnd.nextDouble() * 4;
      canvas.drawPath(
        Path()
          ..moveTo(c.dx, c.dy - r)
          ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
          ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
          ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
          ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CityTablePainter oldDelegate) =>
      oldDelegate.city != city;
}
