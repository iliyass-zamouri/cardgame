import 'dart:math' as math;

import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/theme/city_theme.dart';
import 'package:cardgame/ui/theme/pot_card_style.dart';
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

/// How a city's rail is finished.
enum _Rail { wood, gilt, silver, pearl, lacquer }

/// Geometry shared by every layer of one table.
class _Table {
  _Table(this.canvas, this.size, this.city) {
    final inset = size.width * 0.035;
    outer = Rect.fromLTRB(
      inset,
      size.height * 0.012 + inset * 0.5,
      size.width - inset,
      size.height * 0.988 - inset * 0.5,
    );
    railWidth = size.width * (0.045 + city.tier * 0.004);
    rail = _stadium(outer);
    feltRect = outer.deflate(railWidth);
    felt = _stadium(feltRect);
  }

  final Canvas canvas;
  final Size size;
  final CityTheme city;
  late final Rect outer;
  late final double railWidth;
  late final RRect rail;
  late final Rect feltRect;
  late final RRect felt;

  Offset get centre => feltRect.center;

  /// Radius of the ring around the deck and discard pile.
  double get ringRadius => size.width * 0.3;

  static RRect _stadium(Rect r) =>
      RRect.fromRectAndRadius(r, Radius.circular(r.width / 2));
}

/// Paints backdrop, rail, felt and each city's signature: a felt pattern,
/// a border band, a centrepiece, its skyline at both ends, and rail
/// ornaments. Colours come from [CityTheme]; emblems match the pot cards.
class CityTablePainter extends CustomPainter {
  const CityTablePainter(this.city);

  final CityTheme city;

  PotCardStyle get _card => PotCardStyle.forCity(city.id);

  _Rail get _railFinish => switch (city.id) {
    'london' => _Rail.wood,
    'toronto' => _Rail.silver,
    'marrakech' => _Rail.pearl,
    'tokyo' => _Rail.lacquer,
    _ => _Rail.gilt,
  };

  @override
  void paint(Canvas canvas, Size size) {
    final t = _Table(canvas, size, city);
    _backdrop(t);
    _rail(t);
    _felt(t);

    canvas.save();
    canvas.clipRRect(t.felt);
    _pattern(t);
    _skylines(t);
    canvas.restore();

    _band(t);
    _centrepiece(t);
    _railOrnaments(t);
  }

  // ---- base layers -------------------------------------------------------

  void _backdrop(_Table t) {
    final rect = Offset.zero & t.size;
    t.canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.1),
          radius: 1.1,
          colors: [
            Color.lerp(city.backdrop, city.feltLight, 0.35)!,
            city.backdrop,
          ],
        ).createShader(rect),
    );
    // Soft glow of the city's accent behind the table.
    final glow = Rect.fromCircle(center: rect.center, radius: t.size.width);
    t.canvas.drawCircle(
      rect.center,
      t.size.width,
      Paint()
        ..shader = RadialGradient(
          colors: [city.accent.withValues(alpha: 0.16), Colors.transparent],
        ).createShader(glow),
    );
  }

  void _rail(_Table t) {
    final canvas = t.canvas;
    canvas.drawRRect(
      t.rail.shift(const Offset(0, 8)),
      Paint()
        ..color = const Color(0xAA000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    final finish = _railFinish;
    final List<Color> colors;
    List<double>? stops;
    switch (finish) {
      case _Rail.wood:
        colors = [city.railLight, city.railDark];
      case _Rail.gilt:
        colors = [city.railLight, city.railDark, city.railLight, city.railDark];
        stops = const [0, 0.35, 0.6, 1];
      case _Rail.silver:
        // Brushed steel: many soft bands.
        colors = [
          for (var i = 0; i < 9; i++) i.isEven ? city.railLight : city.railDark,
        ];
      case _Rail.pearl:
        colors = const [
          Color(0xFFFFFFFF),
          Color(0xFFE6E2F0),
          Color(0xFFFFFBF2),
          Color(0xFFD9E4EC),
          Color(0xFFFFFFFF),
        ];
      case _Rail.lacquer:
        colors = [city.railLight, city.railDark, city.railDark];
        stops = const [0, 0.45, 1];
    }
    canvas.drawRRect(
      t.rail,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
          stops: stops,
        ).createShader(t.outer),
    );
    // Cut the felt opening out of the rail visually with an inner lip.
    canvas.drawRRect(
      t.felt.inflate(2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.black.withValues(alpha: 0.45),
    );
    // Specular edge.
    canvas.drawRRect(
      t.rail.deflate(1.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Colors.white.withValues(
          alpha: finish == _Rail.wood ? 0.12 : 0.4,
        ),
    );

    if (finish == _Rail.wood) {
      // Mahogany grain: wavering rings around the rail.
      final grain =
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.9
            ..color = Colors.black.withValues(alpha: 0.2);
      for (var i = 1; i <= 5; i++) {
        canvas.drawRRect(t.rail.deflate(i * t.railWidth / 6), grain);
      }
    }
    if (finish == _Rail.lacquer) {
      // Rose-gold edges either side of the black lacquer.
      final edge =
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = city.accent;
      canvas.drawRRect(t.rail.deflate(2.5), edge);
      canvas.drawRRect(t.felt.inflate(4), edge..strokeWidth = 1.4);
    }
  }

  void _felt(_Table t) {
    final canvas = t.canvas;
    canvas.drawRRect(
      t.felt,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.1),
          radius: 0.95,
          colors: [city.feltLight, city.feltDark],
        ).createShader(t.feltRect),
    );
    canvas.save();
    canvas.clipRRect(t.felt);
    // Fine cloth weave.
    final weave = Paint()..color = Colors.black.withValues(alpha: 0.05);
    for (var y = t.feltRect.top; y < t.feltRect.bottom; y += 3) {
      canvas.drawRect(
        Rect.fromLTWH(t.feltRect.left, y, t.feltRect.width, 1),
        weave,
      );
    }
    // Shadow where the felt tucks under the rail.
    canvas.drawRRect(
      t.felt.inflate(6),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..color = const Color(0x77000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.restore();
  }

  // ---- felt patterns -----------------------------------------------------

  void _pattern(_Table t) {
    switch (city.id) {
      case 'london':
        _tartan(t);
      case 'paris':
        _damask(t);
      case 'moscow':
        _lattice(t, 52, _gold.withValues(alpha: 0.07));
        _dotRosettes(t, 52);
      case 'cairo':
        _sunRays(t);
      case 'marrakech':
        _zellige(t);
      case 'toronto':
        _fallingLeaves(t);
      case 'new_york':
        _decoRays(t);
      case 'tokyo':
        _seigaiha(t);
        _petals(t);
    }
  }

  void _tartan(_Table t) {
    final r = t.feltRect;
    final dark = Paint()..color = Colors.black.withValues(alpha: 0.07);
    final thin =
        Paint()
          ..strokeWidth = 1
          ..color = city.accent.withValues(alpha: 0.07);
    final red =
        Paint()
          ..strokeWidth = 1
          ..color = const Color(0xFFB3262E).withValues(alpha: 0.10);
    const step = 44.0;
    for (var x = r.left; x < r.right; x += step) {
      t.canvas.drawRect(Rect.fromLTWH(x, r.top, 12, r.height), dark);
      t.canvas.drawLine(Offset(x + 22, r.top), Offset(x + 22, r.bottom), thin);
      t.canvas.drawLine(Offset(x + 30, r.top), Offset(x + 30, r.bottom), red);
    }
    for (var y = r.top; y < r.bottom; y += step) {
      t.canvas.drawRect(Rect.fromLTWH(r.left, y, r.width, 12), dark);
      t.canvas.drawLine(Offset(r.left, y + 22), Offset(r.right, y + 22), thin);
      t.canvas.drawLine(Offset(r.left, y + 30), Offset(r.right, y + 30), red);
    }
  }

  void _damask(_Table t) {
    final r = t.feltRect;
    final style = _mono(_card, city.accent);
    const cell = 46.0;
    _faded(t, r, 0.11, () {
      var row = 0;
      for (var y = r.top + cell / 2; y < r.bottom; y += cell, row++) {
        final shift = row.isOdd ? cell / 2 : 0.0;
        for (var x = r.left + shift; x < r.right + cell; x += cell) {
          t.canvas.save();
          t.canvas.translate(x, y);
          paintPotGlyph(t.canvas, style, 8);
          t.canvas.restore();
        }
      }
    });
  }

  void _lattice(_Table t, double cell, Color color) {
    final r = t.feltRect;
    final p =
        Paint()
          ..strokeWidth = 1
          ..color = color;
    for (var d = -r.height; d < r.width + r.height; d += cell) {
      t.canvas.drawLine(
        Offset(r.left + d, r.top),
        Offset(r.left + d + r.height, r.bottom),
        p,
      );
      t.canvas.drawLine(
        Offset(r.left + d + r.height, r.top),
        Offset(r.left + d, r.bottom),
        p,
      );
    }
  }

  void _dotRosettes(_Table t, double cell) {
    final r = t.feltRect;
    final p = Paint()..color = _gold.withValues(alpha: 0.16);
    var row = 0;
    for (var y = r.top; y < r.bottom + cell; y += cell / 2, row++) {
      final shift = row.isOdd ? cell / 2 : 0.0;
      for (var x = r.left + shift; x < r.right + cell; x += cell) {
        for (var k = 0; k < 4; k++) {
          final a = k * math.pi / 2;
          t.canvas.drawCircle(
            Offset(x + math.cos(a) * 4.5, y + math.sin(a) * 4.5),
            2.6,
            p,
          );
        }
        t.canvas.drawCircle(Offset(x, y), 1.8, p);
      }
    }
  }

  void _sunRays(_Table t) {
    final c = t.centre;
    final radius = t.feltRect.height;
    final p = Paint()..color = _gold.withValues(alpha: 0.05);
    const rays = 28;
    for (var i = 0; i < rays; i += 2) {
      final a0 = i * 2 * math.pi / rays;
      final a1 = (i + 1) * 2 * math.pi / rays;
      t.canvas.drawPath(
        Path()
          ..moveTo(c.dx, c.dy)
          ..lineTo(c.dx + math.cos(a0) * radius, c.dy + math.sin(a0) * radius)
          ..lineTo(c.dx + math.cos(a1) * radius, c.dy + math.sin(a1) * radius)
          ..close(),
        p,
      );
    }
  }

  void _zellige(_Table t) {
    final r = t.feltRect;
    const cell = 60.0;
    final fill = Paint()..color = Colors.white.withValues(alpha: 0.03);
    final edge =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.9
          ..color = Colors.white.withValues(alpha: 0.14);
    for (var y = r.top; y < r.bottom + cell; y += cell) {
      for (var x = r.left; x < r.right + cell; x += cell) {
        final star = _star(Offset(x, y), 24, 13, 8, math.pi / 8);
        t.canvas.drawPath(star, fill);
        t.canvas.drawPath(star, edge);
        t.canvas.drawPath(
          _star(Offset(x + cell / 2, y + cell / 2), 10, 5, 4, math.pi / 4),
          edge,
        );
      }
    }
  }

  void _fallingLeaves(_Table t) {
    final r = t.feltRect;
    final rnd = math.Random(11);
    const tones = [Color(0xFFC62828), Color(0xFFE07B24), Color(0xFFF2C14E)];
    for (var i = 0; i < 26; i++) {
      final pos = Offset(
        r.left + rnd.nextDouble() * r.width,
        r.top + rnd.nextDouble() * r.height,
      );
      final leaf = _mono(_card, tones[i % tones.length]);
      _faded(t, Rect.fromCircle(center: pos, radius: 20), 0.18, () {
        t.canvas.save();
        t.canvas.translate(pos.dx, pos.dy);
        t.canvas.rotate(rnd.nextDouble() * math.pi * 2);
        paintPotGlyph(t.canvas, leaf, 6 + rnd.nextDouble() * 9);
        t.canvas.restore();
      });
    }
  }

  void _decoRays(_Table t) {
    final c = t.centre;
    final p =
        Paint()
          ..strokeWidth = 1
          ..color = _gold.withValues(alpha: 0.09);
    const rays = 40;
    for (var i = 0; i < rays; i++) {
      final a = i * 2 * math.pi / rays;
      final dir = Offset(math.cos(a), math.sin(a));
      t.canvas.drawLine(c + dir * t.ringRadius, c + dir * t.feltRect.height, p);
    }
    // Stepped chevrons stacked toward both ends.
    final chevron =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = _gold.withValues(alpha: 0.12);
    for (final dir in const [-1.0, 1.0]) {
      for (var k = 0; k < 4; k++) {
        final y = c.dy + dir * (t.ringRadius + 34 + k * 16);
        final w = t.feltRect.width * (0.42 - k * 0.06);
        t.canvas.drawPath(
          Path()
            ..moveTo(c.dx - w, y)
            ..lineTo(c.dx, y + dir * 14)
            ..lineTo(c.dx + w, y),
          chevron,
        );
      }
    }
  }

  void _seigaiha(_Table t) {
    final r = t.feltRect;
    const w = 34.0;
    final p =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = city.accent.withValues(alpha: 0.09);
    var row = 0;
    for (var y = r.top; y < r.bottom + w; y += w / 4, row++) {
      final shift = row.isOdd ? w / 2 : 0.0;
      for (var x = r.left - w + shift; x < r.right + w; x += w) {
        for (var k = 1; k <= 3; k++) {
          t.canvas.drawArc(
            Rect.fromCircle(center: Offset(x, y), radius: w / 2 * k / 3),
            math.pi,
            math.pi,
            false,
            p,
          );
        }
      }
    }
  }

  void _petals(_Table t) {
    final r = t.feltRect;
    final rnd = math.Random(5);
    final paint = Paint()..color = const Color(0xFFF6B6C8);
    for (var i = 0; i < 34; i++) {
      final pos = Offset(
        r.left + rnd.nextDouble() * r.width,
        r.top + rnd.nextDouble() * r.height,
      );
      final s = 3 + rnd.nextDouble() * 4;
      t.canvas.save();
      t.canvas.translate(pos.dx, pos.dy);
      t.canvas.rotate(rnd.nextDouble() * math.pi * 2);
      t.canvas.drawPath(
        Path()
          ..moveTo(0, 0)
          ..quadraticBezierTo(s, -s, 0, -s * 2)
          ..lineTo(-s * 0.2, -s * 1.7)
          ..quadraticBezierTo(-s, -s, 0, 0),
        paint
          ..color = paint.color.withValues(
            alpha: 0.2 + rnd.nextDouble() * 0.25,
          ),
      );
      t.canvas.restore();
    }
  }

  // ---- skylines ----------------------------------------------------------

  /// The city's landmarks rise into the far end of the felt, with a
  /// fainter reflection in the near end, like the skyline over water.
  void _skylines(_Table t) {
    final r = t.feltRect;
    final w = r.width * 0.9;
    final h = r.width * 0.42;
    final base = r.top + r.width * 0.5;
    final line = _skyline(city.id);
    for (final reflected in const [false, true]) {
      t.canvas.save();
      if (reflected) {
        t.canvas.translate(0, t.centre.dy * 2);
        t.canvas.scale(1, -1);
      }
      t.canvas.translate(r.center.dx - w / 2, base - h);
      t.canvas.scale(w, h);
      t.canvas.drawPath(
        line,
        Paint()..color = city.accent.withValues(alpha: reflected ? 0.06 : 0.1),
      );
      t.canvas.restore();
    }
  }

  // ---- border band -------------------------------------------------------

  void _band(_Table t) {
    final canvas = t.canvas;
    final metal = city.id == 'marrakech' ? Colors.white : _gold;
    final line =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = metal.withValues(alpha: 0.55);
    canvas.drawRRect(t.felt.deflate(7), line);

    switch (city.id) {
      case 'london':
        _dashed(canvas, t.felt.deflate(13), city.accent.withValues(alpha: 0.3));
        _alongBorder(
          t.felt.deflate(13),
          4,
          (pos, _, __) => _emblem(t, pos, 8, 0.75),
          evenly: true,
        );
      case 'paris':
        _scallops(t, t.felt.deflate(12), 20, _gold.withValues(alpha: 0.4));
        _alongBorder(t.felt.deflate(20), 120, (pos, _, __) {
          canvas.drawCircle(pos, 1.6, Paint()..color = const Color(0xFFF7F3EA));
        });
      case 'moscow':
        canvas.drawRRect(t.felt.deflate(13), line..strokeWidth = 0.9);
        _alongBorder(t.felt.deflate(18), 64, (pos, _, i) {
          if (i.isEven) _emblem(t, pos, 5, 0.6);
        });
      case 'cairo':
        _collar(t);
      case 'marrakech':
        _scallops(
          t,
          t.felt.deflate(12),
          22,
          Colors.white.withValues(alpha: 0.35),
          pointed: true,
        );
      case 'toronto':
        canvas.drawRRect(
          t.felt.deflate(12),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..color = const Color(0xFFC62828).withValues(alpha: 0.55),
        );
      case 'new_york':
        _zigzag(t, t.felt.deflate(14), _gold.withValues(alpha: 0.4));
      case 'tokyo':
        _dashed(canvas, t.felt.deflate(13), city.accent.withValues(alpha: 0.4));
    }
  }

  void _collar(_Table t) {
    // Egyptian broad collar: beads of lapis, turquoise, gold, carnelian.
    const beads = [
      Color(0xFF1E4F8F),
      Color(0xFF2FA4A0),
      Color(0xFFD4A63A),
      Color(0xFFB4442A),
    ];
    _alongBorder(t.felt.deflate(16), 9, (pos, normal, i) {
      t.canvas.drawLine(
        pos - normal * 4,
        pos + normal * 4,
        Paint()
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..color = beads[i % beads.length].withValues(alpha: 0.7),
      );
    });
    t.canvas.drawRRect(
      t.felt.deflate(24),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = _gold.withValues(alpha: 0.45),
    );
  }

  void _scallops(
    _Table t,
    RRect border,
    double step,
    Color color, {
    bool pointed = false,
  }) {
    final p =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = color;
    _alongBorder(border, step, (pos, normal, _) {
      // Each scallop arches inward toward the centre.
      final tangent = Offset(normal.dy, -normal.dx);
      final a = pos - tangent * step / 2;
      final b = pos + tangent * step / 2;
      final peak = pos + normal * step * (pointed ? 0.75 : 0.5);
      final path = Path()..moveTo(a.dx, a.dy);
      if (pointed) {
        // Moorish arch: rounded shoulders meeting in a point.
        final ca = a + normal * step * 0.55;
        final cb = b + normal * step * 0.55;
        path
          ..quadraticBezierTo(ca.dx, ca.dy, peak.dx, peak.dy)
          ..quadraticBezierTo(cb.dx, cb.dy, b.dx, b.dy);
      } else {
        final ctl = pos + normal * step;
        path.quadraticBezierTo(ctl.dx, ctl.dy, b.dx, b.dy);
      }
      t.canvas.drawPath(path, p);
    });
  }

  void _zigzag(_Table t, RRect border, Color color) {
    final path = Path();
    var first = true;
    _alongBorder(border, 8, (pos, normal, i) {
      final pt = pos + normal * (i.isEven ? 0 : 7);
      if (first) {
        path.moveTo(pt.dx, pt.dy);
        first = false;
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    });
    t.canvas.drawPath(
      path..close(),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = color,
    );
  }

  // ---- centrepiece -------------------------------------------------------

  void _centrepiece(_Table t) {
    final canvas = t.canvas;
    final c = t.centre;
    final r = t.ringRadius;
    final metal = city.id == 'marrakech' ? Colors.white : _gold;
    final ring =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = metal.withValues(alpha: 0.5);
    canvas.drawCircle(c, r, ring);
    canvas.drawCircle(c, r - 6, ring..strokeWidth = 0.9);

    switch (city.id) {
      case 'london':
        _clockDial(t);
      case 'paris':
        for (var k = 0; k < 4; k++) {
          final a = k * math.pi / 2 - math.pi / 2;
          canvas.save();
          canvas.translate(c.dx + math.cos(a) * r, c.dy + math.sin(a) * r);
          canvas.rotate(a + math.pi / 2);
          _medallionBacking(t, Offset.zero, 13);
          paintPotGlyph(canvas, _card, 10);
          canvas.restore();
        }
        _alongCircle(c, r - 12, 48, (pos, _) {
          canvas.drawCircle(pos, 1.4, Paint()..color = const Color(0x99F7F3EA));
        });
      case 'moscow':
        _kokoshniks(t);
        _faded(t, Rect.fromCircle(center: c, radius: r), 0.55, () {
          _rubyStar(canvas, c, r * 0.32);
        });
      case 'cairo':
        _wingedSun(t);
      case 'marrakech':
        canvas.drawPath(
          _star(c, r * 1.12, r * 0.94, 16, 0),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..color = Colors.white.withValues(alpha: 0.32),
        );
        _faded(t, Rect.fromCircle(center: c, radius: r), 0.35, () {
          canvas.save();
          canvas.translate(c.dx, c.dy);
          paintPotRosette(canvas, _card, r * 0.42);
          canvas.restore();
        });
      case 'toronto':
        _faded(t, Rect.fromCircle(center: c, radius: r), 0.3, () {
          canvas.save();
          canvas.translate(c.dx, c.dy);
          paintPotGlyph(canvas, _card, r * 0.55);
          canvas.restore();
        });
      case 'new_york':
        _faded(t, Rect.fromCircle(center: c, radius: r), 0.3, () {
          canvas.save();
          canvas.translate(c.dx, c.dy);
          paintPotRosette(canvas, _card, r * 0.7);
          canvas.restore();
        });
        canvas.drawCircle(c, r + 8, ring..strokeWidth = 0.9);
      case 'tokyo':
        // Red sun with a sakura blossom over it.
        canvas.drawCircle(
          c,
          r * 0.55,
          Paint()..color = const Color(0xFFE0344D).withValues(alpha: 0.28),
        );
        _faded(t, Rect.fromCircle(center: c, radius: r), 0.5, () {
          canvas.save();
          canvas.translate(c.dx, c.dy);
          paintPotGlyph(canvas, _card, r * 0.4);
          canvas.restore();
        });
    }
  }

  /// Big Ben's dial: minute ticks, hour bars and Roman numerals.
  void _clockDial(_Table t) {
    final canvas = t.canvas;
    final c = t.centre;
    final r = t.ringRadius;
    final tick =
        Paint()
          ..strokeCap = StrokeCap.round
          ..color = city.accent.withValues(alpha: 0.5);
    for (var i = 0; i < 60; i++) {
      final a = i * math.pi / 30;
      final dir = Offset(math.cos(a), math.sin(a));
      final hour = i % 5 == 0;
      canvas.drawLine(
        c + dir * (r - 8),
        c + dir * (r - (hour ? 18 : 12)),
        tick..strokeWidth = hour ? 2.2 : 1,
      );
    }
    const numerals = [
      'XII', 'I', 'II', 'III', 'IIII', 'V', //
      'VI', 'VII', 'VIII', 'IX', 'X', 'XI',
    ];
    for (var h = 0; h < 12; h++) {
      final a = h * math.pi / 6 - math.pi / 2;
      final pos = c + Offset(math.cos(a), math.sin(a)) * (r - 30);
      final tp = TextPainter(
        text: TextSpan(
          text: numerals[h],
          style: TextStyle(
            fontFamily: CasinoFonts.display,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: city.accent.withValues(alpha: 0.55),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(a + math.pi / 2);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
    _faded(t, Rect.fromCircle(center: c, radius: r), 0.7, () {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      paintPotRosette(canvas, _card, r * 0.22);
      canvas.restore();
    });
  }

  /// Ring of kokoshnik gables (pointed onion arches) around the centre.
  void _kokoshniks(_Table t) {
    final canvas = t.canvas;
    final c = t.centre;
    final r = t.ringRadius;
    final p =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = _gold.withValues(alpha: 0.45);
    const count = 12;
    for (var i = 0; i < count; i++) {
      final a = i * 2 * math.pi / count;
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(a);
      canvas.translate(0, -r);
      canvas.drawPath(
        Path()
          ..moveTo(-12, 0)
          ..cubicTo(-14, -10, -3, -10, 0, -20)
          ..cubicTo(3, -10, 14, -10, 12, 0),
        p,
      );
      canvas.drawCircle(const Offset(0, -22), 1.6, Paint()..color = p.color);
      canvas.restore();
    }
  }

  void _rubyStar(Canvas canvas, Offset c, double r) {
    final star = _star(c, r, r * 0.42, 5, -math.pi / 2);
    canvas.drawPath(
      star,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFFF5A5A), Color(0xFFB71C1C)],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawPath(
      star,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = _gold,
    );
  }

  /// Winged sun disc with the outer ring of Cairo's centre.
  void _wingedSun(_Table t) {
    final canvas = t.canvas;
    final c = t.centre;
    final r = t.ringRadius;
    _faded(t, Rect.fromCircle(center: c, radius: r * 1.5), 0.45, () {
      final wing = Paint()..color = _gold;
      for (final side in const [-1.0, 1.0]) {
        for (var k = 0; k < 4; k++) {
          final y = c.dy - 8 + k * 6;
          final len = r * (1.05 - k * 0.14);
          canvas.drawPath(
            Path()
              ..moveTo(c.dx + side * r * 0.2, y)
              ..quadraticBezierTo(
                c.dx + side * len * 0.6,
                y - 10 + k * 2,
                c.dx + side * len,
                y - 4,
              )
              ..lineTo(c.dx + side * len * 0.96, y + 2)
              ..quadraticBezierTo(
                c.dx + side * len * 0.6,
                y - 4 + k * 2,
                c.dx + side * r * 0.2,
                y + 4,
              )
              ..close(),
            wing,
          );
        }
      }
      canvas.drawCircle(
        c,
        r * 0.22,
        Paint()
          ..shader = const RadialGradient(
            colors: [Color(0xFFFFE38A), Color(0xFFD4A63A)],
          ).createShader(Rect.fromCircle(center: c, radius: r * 0.22)),
      );
      canvas.drawCircle(
        c,
        r * 0.22,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFFB4442A),
      );
    });
  }

  // ---- rail ornaments ----------------------------------------------------

  void _railOrnaments(_Table t) {
    final mid = t.rail.deflate(t.railWidth / 2);
    switch (city.id) {
      case 'london':
        _alongBorder(
          mid,
          4,
          (pos, normal, _) => _brassPlate(t.canvas, pos, normal),
          evenly: true,
        );
      case 'paris':
        _alongBorder(mid, 12, (pos, _, __) => _pearl(t.canvas, pos, 2.6));
      case 'moscow':
        _alongBorder(mid, 22, (pos, _, i) {
          i % 6 == 0
              ? _gem(t.canvas, pos, 4.5, const Color(0xFFE53935))
              : _stud(t.canvas, pos, 2.6);
        });
      case 'cairo':
        _alongBorder(mid, 26, (pos, normal, i) {
          final colour =
              i.isEven ? const Color(0xFF1E4F8F) : const Color(0xFF2FA4A0);
          _inlay(t.canvas, pos, normal, colour, t.railWidth * 0.32, 7);
        });
      case 'marrakech':
        _alongBorder(mid, 18, (pos, normal, _) {
          _diamond(t.canvas, pos, normal, const Color(0xFF17171C), 5);
        });
      case 'toronto':
        _alongBorder(mid, 26, (pos, _, __) => _rivet(t.canvas, pos));
        t.canvas.drawRRect(
          mid,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = const Color(0xFFC62828).withValues(alpha: 0.7),
        );
      case 'new_york':
        _alongBorder(mid, 18, (pos, _, __) => _bulb(t.canvas, pos));
      case 'tokyo':
        _alongBorder(mid, 30, (pos, _, i) {
          if (i.isEven) _stud(t.canvas, pos, 2.6, tint: city.accent);
        });
    }
  }

  void _stud(Canvas canvas, Offset p, double r, {Color tint = _gold}) {
    canvas.drawCircle(
      p.translate(0, 1),
      r,
      Paint()..color = const Color(0x88000000),
    );
    canvas.drawCircle(
      p,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.4),
          colors: [Colors.white, tint, Color.lerp(tint, Colors.black, 0.45)!],
          stops: const [0, 0.45, 1],
        ).createShader(Rect.fromCircle(center: p, radius: r)),
    );
  }

  void _gem(Canvas canvas, Offset p, double r, Color color) {
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
  }

  void _pearl(Canvas canvas, Offset p, double r) {
    canvas.drawCircle(
      p,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.4, -0.4),
          colors: [Colors.white, Color(0xFFEDE6DA), Color(0xFFA89C8A)],
          stops: [0, 0.5, 1],
        ).createShader(Rect.fromCircle(center: p, radius: r)),
    );
  }

  void _rivet(Canvas canvas, Offset p) {
    canvas.drawCircle(p, 2.4, Paint()..color = const Color(0xFF5E6872));
    canvas.drawCircle(
      p.translate(-0.5, -0.5),
      1.6,
      Paint()..color = const Color(0xFFF1F4F7),
    );
  }

  void _bulb(Canvas canvas, Offset p) {
    // Broadway marquee bulb with a warm halo.
    canvas.drawCircle(
      p,
      7,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFE9A8).withValues(alpha: 0.55),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: p, radius: 7)),
    );
    canvas.drawCircle(p, 2.8, Paint()..color = const Color(0xFF7A5416));
    canvas.drawCircle(p, 2.2, Paint()..color = const Color(0xFFFFF4D0));
  }

  void _brassPlate(Canvas canvas, Offset p, Offset normal) {
    final angle = math.atan2(normal.dy, normal.dx) + math.pi / 2;
    canvas.save();
    canvas.translate(p.dx, p.dy);
    canvas.rotate(angle);
    final plate = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-16, -6, 32, 12),
      const Radius.circular(3),
    );
    canvas.drawRRect(
      plate,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFE9A8), Color(0xFFC9A34A), Color(0xFF7A5416)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(plate.outerRect),
    );
    for (final x in const [-11.0, 11.0]) {
      canvas.drawCircle(
        Offset(x, 0),
        1.6,
        Paint()..color = const Color(0xFF5C430A),
      );
    }
    canvas.restore();
  }

  void _inlay(
    Canvas canvas,
    Offset p,
    Offset normal,
    Color color,
    double length,
    double width,
  ) {
    final tangent = Offset(normal.dy, -normal.dx);
    final path =
        Path()..moveTo(
          (p + normal * length / 2 - tangent * width / 2).dx,
          (p + normal * length / 2 - tangent * width / 2).dy,
        );
    for (final o in [
      p + normal * length / 2 + tangent * width / 2,
      p - normal * length / 2 + tangent * width / 2,
      p - normal * length / 2 - tangent * width / 2,
    ]) {
      path.lineTo(o.dx, o.dy);
    }
    canvas.drawPath(path..close(), Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = const Color(0xFF8A6119),
    );
  }

  void _diamond(Canvas canvas, Offset p, Offset normal, Color color, double r) {
    final tangent = Offset(normal.dy, -normal.dx);
    final pts = [
      p + normal * r,
      p + tangent * r * 0.7,
      p - normal * r,
      p - tangent * r * 0.7,
    ];
    canvas.drawPath(Path()..addPolygon(pts, true), Paint()..color = color);
  }

  // ---- helpers -----------------------------------------------------------

  /// Card emblem drawn on the felt at [pos].
  void _emblem(_Table t, Offset pos, double r, double opacity) {
    _faded(t, Rect.fromCircle(center: pos, radius: r * 1.5), opacity, () {
      t.canvas.save();
      t.canvas.translate(pos.dx, pos.dy);
      paintPotRosette(t.canvas, _card, r);
      t.canvas.restore();
    });
  }

  void _medallionBacking(_Table t, Offset c, double r) {
    t.canvas.drawCircle(
      c,
      r,
      Paint()..color = city.feltDark.withValues(alpha: 0.8),
    );
    t.canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = _gold.withValues(alpha: 0.6),
    );
  }

  /// Runs [paint] into a layer composited at [opacity].
  void _faded(_Table t, Rect bounds, double opacity, VoidCallback paint) {
    t.canvas.saveLayer(
      bounds.inflate(4),
      Paint()..color = Color.fromRGBO(0, 0, 0, opacity),
    );
    paint();
    t.canvas.restore();
  }

  /// Visits points along [border], one every [step] px; with [evenly],
  /// [step] is instead a count of evenly spaced points, starting [phase] of
  /// the way round. [visit] gets the point, the inward normal and the index.
  void _alongBorder(
    RRect border,
    double step,
    void Function(Offset pos, Offset normal, int i) visit, {
    bool evenly = false,
    double phase = 0,
  }) {
    for (final m in (Path()..addRRect(border)).computeMetrics()) {
      final gap = evenly ? m.length / step : step;
      final count = (m.length / gap).floor();
      for (var i = 0; i < count; i++) {
        final d = (phase * m.length + i * gap + gap / 2) % m.length;
        final tan = m.getTangentForOffset(d);
        if (tan == null) continue;
        // Path runs clockwise, so the inward normal is the tangent turned right.
        final normal = Offset(-tan.vector.dy, tan.vector.dx);
        visit(tan.position, normal, i);
      }
    }
  }

  void _alongCircle(
    Offset c,
    double r,
    int count,
    void Function(Offset pos, double angle) visit,
  ) {
    for (var i = 0; i < count; i++) {
      final a = i * 2 * math.pi / count;
      visit(c + Offset(math.cos(a), math.sin(a)) * r, a);
    }
  }

  void _dashed(Canvas canvas, RRect rrect, Color color) {
    final paint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = color;
    for (final m in (Path()..addRRect(rrect)).computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 11) {
        canvas.drawPath(m.extractPath(d, math.min(d + 6, m.length)), paint);
      }
    }
  }

  Path _star(Offset c, double outer, double inner, int points, double rot) {
    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final r = i.isEven ? outer : inner;
      final a = rot + i * math.pi / points;
      final pt = Offset(c.dx + math.cos(a) * r, c.dy + math.sin(a) * r);
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    return path..close();
  }

  /// [style] repainted in a single [colour], for tone-on-tone motifs.
  PotCardStyle _mono(PotCardStyle style, Color colour) => PotCardStyle(
    ink: style.ink,
    inkDeep: style.inkDeep,
    window: style.window,
    ornament: style.ornament,
    palette: [colour, colour, colour, colour],
  );

  @override
  bool shouldRepaint(covariant CityTablePainter oldDelegate) =>
      oldDelegate.city != city;
}

/// City skyline in a unit box (x 0..1, y 0..1 with the ground at y = 1).
Path _skyline(String city) {
  final p = Path();
  void block(double l, double t, double r) =>
      p.addRect(Rect.fromLTRB(l, t, r, 1));
  void poly(List<double> xy) => p.addPolygon([
    for (var i = 0; i < xy.length; i += 2) Offset(xy[i], xy[i + 1]),
  ], true);
  void dome(double cx, double base, double w, double h) {
    // Onion dome on a drum, finished with a spire.
    p
      ..moveTo(cx - w * 0.35, base)
      ..cubicTo(
        cx - w * 0.75,
        base - h * 0.45,
        cx - w * 0.1,
        base - h * 0.6,
        cx,
        base - h,
      )
      ..cubicTo(
        cx + w * 0.1,
        base - h * 0.6,
        cx + w * 0.75,
        base - h * 0.45,
        cx + w * 0.35,
        base,
      )
      ..close();
  }

  switch (city) {
    case 'london':
      // Houses of Parliament with Big Ben, and Tower Bridge.
      block(0.05, 0.72, 0.5);
      for (var x = 0.07; x < 0.5; x += 0.05) {
        poly([x, 0.72, x + 0.012, 0.6, x + 0.024, 0.72]);
      }
      block(0.38, 0.5, 0.44);
      poly([0.38, 0.5, 0.41, 0.4, 0.44, 0.5]);
      block(0.52, 0.28, 0.6);
      poly([0.51, 0.28, 0.56, 0.08, 0.61, 0.28]);
      block(0.7, 0.45, 0.75);
      block(0.86, 0.45, 0.91);
      poly([0.7, 0.45, 0.725, 0.35, 0.75, 0.45]);
      poly([0.86, 0.45, 0.885, 0.35, 0.91, 0.45]);
      block(0.62, 0.84, 0.98);
      block(0.75, 0.52, 0.86);
    case 'paris':
      // Eiffel Tower between Notre-Dame and the Arc de Triomphe.
      p
        ..moveTo(0.38, 1)
        ..quadraticBezierTo(0.47, 0.55, 0.49, 0.06)
        ..lineTo(0.51, 0.06)
        ..quadraticBezierTo(0.53, 0.55, 0.62, 1)
        ..lineTo(0.56, 1)
        ..quadraticBezierTo(0.5, 0.86, 0.44, 1)
        ..close();
      block(0.42, 0.62, 0.58);
      block(0.06, 0.6, 0.12);
      block(0.18, 0.6, 0.24);
      block(0.06, 0.74, 0.24);
      block(0.76, 0.68, 0.94);
      block(0.26, 0.82, 0.36);
      block(0.64, 0.84, 0.74);
    case 'moscow':
      // St Basil's domes and the Spasskaya tower.
      for (final (cx, h) in const [(0.1, 0.4), (0.2, 0.55), (0.3, 0.42)]) {
        block(cx - 0.035, 1 - h + 0.12, cx + 0.035);
        dome(cx, 1 - h + 0.12, 0.09, 0.14);
      }
      block(0.05, 0.82, 0.35);
      block(0.62, 0.38, 0.72);
      poly([0.6, 0.38, 0.67, 0.12, 0.74, 0.38]);
      block(0.4, 0.78, 0.98);
      for (var x = 0.42; x < 0.98; x += 0.05) {
        poly([x, 0.78, x + 0.02, 0.72, x + 0.04, 0.78]);
      }
    case 'cairo':
      // The Giza pyramids, the Sphinx and a minaret.
      poly([0.2, 1, 0.42, 0.45, 0.64, 1]);
      poly([0.5, 1, 0.66, 0.6, 0.82, 1]);
      poly([0.74, 1, 0.84, 0.76, 0.94, 1]);
      block(0.04, 0.82, 0.2);
      poly([0.1, 0.82, 0.13, 0.74, 0.16, 0.82]);
      block(0.06, 0.4, 0.08);
      poly([0.055, 0.4, 0.07, 0.3, 0.085, 0.4]);
    case 'marrakech':
      // The Koutoubia minaret over low riads and palms.
      block(0.44, 0.22, 0.56);
      block(0.47, 0.12, 0.53);
      poly([0.48, 0.12, 0.5, 0.05, 0.52, 0.12]);
      block(0.04, 0.78, 0.4);
      block(0.6, 0.74, 0.96);
      block(0.14, 0.7, 0.24);
      block(0.72, 0.66, 0.82);
      for (final x in const [0.3, 0.88]) {
        block(x - 0.008, 0.5, x + 0.008);
        p.addOval(
          Rect.fromCenter(center: Offset(x, 0.5), width: 0.1, height: 0.05),
        );
      }
    case 'toronto':
      // The CN Tower, the dome and a dense skyline.
      block(0.66, 0.12, 0.68);
      p.addOval(
        Rect.fromCenter(
          center: const Offset(0.67, 0.36),
          width: 0.07,
          height: 0.05,
        ),
      );
      poly([0.64, 1, 0.665, 0.38, 0.675, 0.38, 0.7, 1]);
      for (final (l, t, r) in const [
        (0.04, 0.62, 0.1),
        (0.1, 0.5, 0.16),
        (0.17, 0.58, 0.23),
        (0.24, 0.42, 0.3),
        (0.31, 0.55, 0.37),
        (0.38, 0.66, 0.44),
        (0.74, 0.5, 0.8),
        (0.81, 0.6, 0.87),
        (0.88, 0.7, 0.96),
      ]) {
        block(l, t, r);
      }
      p.addArc(const Rect.fromLTRB(0.46, 0.76, 0.62, 1.12), math.pi, math.pi);
    case 'new_york':
      // Empire State and Chrysler buildings in the Manhattan skyline.
      block(0.44, 0.3, 0.56);
      block(0.47, 0.2, 0.53);
      block(0.49, 0.1, 0.51);
      block(0.495, 0.02, 0.505);
      block(0.66, 0.34, 0.74);
      poly([0.66, 0.34, 0.7, 0.14, 0.74, 0.34]);
      for (final (l, t, r) in const [
        (0.02, 0.6, 0.08),
        (0.09, 0.48, 0.15),
        (0.16, 0.56, 0.22),
        (0.23, 0.4, 0.3),
        (0.31, 0.52, 0.38),
        (0.38, 0.62, 0.43),
        (0.57, 0.5, 0.65),
        (0.75, 0.44, 0.82),
        (0.83, 0.58, 0.9),
        (0.9, 0.66, 0.98),
      ]) {
        block(l, t, r);
      }
    case 'tokyo':
      // Mount Fuji, a pagoda and Tokyo Tower.
      poly([0.18, 1, 0.4, 0.46, 0.5, 0.46, 0.72, 1]);
      for (var k = 0; k < 4; k++) {
        final y = 0.84 - k * 0.12;
        poly([0.02, y, 0.08, y - 0.06, 0.2, y - 0.06, 0.26, y]);
        block(0.07, y - 0.06, 0.21);
      }
      block(0.135, 0.3, 0.145);
      poly([0.74, 1, 0.8, 0.5, 0.82, 0.5, 0.88, 1]);
      block(0.805, 0.14, 0.815);
      block(0.775, 0.62, 0.845);
  }
  return p..fillType = PathFillType.nonZero;
}
