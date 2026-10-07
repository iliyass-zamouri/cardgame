import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Outline of the top edge of a pot card's art window.
enum PotWindowShape {
  gothic,
  nouveau,
  onion,
  pylon,
  moorish,
  round,
  deco,
  torii,
}

/// Emblem used in a pot card's corners and on its divider.
enum PotOrnament {
  rose,
  fleurDeLis,
  khokhloma,
  lotus,
  zellige,
  maple,
  decoFan,
  sakura,
}

/// Per-city look of a pot card: ink for the banner and numbers, trim for
/// frames, and an architectural window and ornament from that city.
@immutable
class PotCardStyle {
  const PotCardStyle({
    required this.ink,
    required this.inkDeep,
    required this.window,
    required this.ornament,
    required this.palette,
    this.trim = _gold,
  });

  /// Banner, pot value and corner index colour.
  final Color ink;

  /// Shade at the bottom of the banner gradient.
  final Color inkDeep;

  /// Frames, borders and ribbon edges.
  final Color trim;
  final PotWindowShape window;
  final PotOrnament ornament;

  /// Ornament colours, most prominent first (at least four).
  final List<Color> palette;

  static const _gold = Color(0xFFC9A34A);

  static const london = PotCardStyle(
    ink: Color(0xFF1B4D3E),
    inkDeep: Color(0xFF0F2E25),
    window: PotWindowShape.gothic,
    ornament: PotOrnament.rose,
    palette: [
      Color(0xFFB3262E),
      Color(0xFFFBF5E6),
      Color(0xFFE2B84C),
      Color(0xFF2E6B3F),
    ],
  );

  static const paris = PotCardStyle(
    ink: Color(0xFF1F3A6E),
    inkDeep: Color(0xFF102247),
    window: PotWindowShape.nouveau,
    ornament: PotOrnament.fleurDeLis,
    palette: [
      Color(0xFFD4A63A),
      Color(0xFF1F3A6E),
      Color(0xFFD98BA0),
      Color(0xFF8FB5E8),
    ],
  );

  static const moscow = PotCardStyle(
    ink: Color(0xFF8E1B1B),
    inkDeep: Color(0xFF560E10),
    window: PotWindowShape.onion,
    ornament: PotOrnament.khokhloma,
    palette: [
      Color(0xFFC62828),
      Color(0xFFE2B84C),
      Color(0xFF1E1E22),
      Color(0xFF2E6B3F),
    ],
  );

  static const cairo = PotCardStyle(
    ink: Color(0xFF1E1E22),
    inkDeep: Color(0xFF0B0B0E),
    trim: Color(0xFFD4A63A),
    window: PotWindowShape.pylon,
    ornament: PotOrnament.lotus,
    palette: [
      Color(0xFF1E4F8F),
      Color(0xFF2FA4A0),
      Color(0xFFD4A63A),
      Color(0xFFB4442A),
    ],
  );

  static const marrakech = PotCardStyle(
    ink: Color(0xFF0F5132),
    inkDeep: Color(0xFF083622),
    window: PotWindowShape.moorish,
    ornament: PotOrnament.zellige,
    palette: [
      Color(0xFFE85D2A),
      Color(0xFF1F7A6A),
      Color(0xFFF2C14E),
      Color(0xFFC9372C),
    ],
  );

  static const toronto = PotCardStyle(
    ink: Color(0xFF136F6F),
    inkDeep: Color(0xFF0A4545),
    trim: Color(0xFFA9B4BF),
    window: PotWindowShape.round,
    ornament: PotOrnament.maple,
    palette: [
      Color(0xFFC62828),
      Color(0xFFE07B24),
      Color(0xFFF2C14E),
      Color(0xFF136F6F),
    ],
  );

  static const newYork = PotCardStyle(
    ink: Color(0xFF4B2A7A),
    inkDeep: Color(0xFF2A1450),
    window: PotWindowShape.deco,
    ornament: PotOrnament.decoFan,
    palette: [
      Color(0xFFD4A63A),
      Color(0xFF4B2A7A),
      Color(0xFF1E1E22),
      Color(0xFFFBF5E6),
    ],
  );

  static const tokyo = PotCardStyle(
    ink: Color(0xFFA3245C),
    inkDeep: Color(0xFF5E0F33),
    trim: Color(0xFFD9A08E),
    window: PotWindowShape.torii,
    ornament: PotOrnament.sakura,
    palette: [
      Color(0xFFF6B6C8),
      Color(0xFFE58AA6),
      Color(0xFFA3245C),
      Color(0xFFF2C14E),
    ],
  );

  static PotCardStyle forCity(String id) => switch (id) {
    'london' => london,
    'paris' => paris,
    'moscow' => moscow,
    'cairo' => cairo,
    'marrakech' => marrakech,
    'toronto' => toronto,
    'new_york' => newYork,
    'tokyo' => tokyo,
    _ => london,
  };
}

/// Art window outline for [shape] in a box of [size]; the shaped crown takes
/// the top fifth, the rest is a rectangle with softly rounded feet.
Path potWindowPath(PotWindowShape shape, Size size) {
  final w = size.width;
  final h = size.height;
  final a = h * 0.22;
  const foot = 6.0;
  final p = Path()..moveTo(0, h - foot);

  switch (shape) {
    case PotWindowShape.gothic:
      p
        ..lineTo(0, a)
        ..cubicTo(0, a * 0.4, w * 0.35, a * 0.15, w / 2, 0)
        ..cubicTo(w * 0.65, a * 0.15, w, a * 0.4, w, a);
    case PotWindowShape.nouveau:
      p
        ..lineTo(0, a + 8)
        ..quadraticBezierTo(0, a, 8, a)
        ..lineTo(w * 0.22, a)
        ..cubicTo(w * 0.3, a, w * 0.3, 0, w / 2, 0)
        ..cubicTo(w * 0.7, 0, w * 0.7, a, w * 0.78, a)
        ..lineTo(w - 8, a)
        ..quadraticBezierTo(w, a, w, a + 8);
    case PotWindowShape.onion:
      p
        ..lineTo(0, a)
        ..lineTo(w * 0.33, a)
        ..cubicTo(w * 0.27, a * 0.45, w * 0.47, a * 0.4, w / 2, 0)
        ..cubicTo(w * 0.53, a * 0.4, w * 0.73, a * 0.45, w * 0.67, a)
        ..lineTo(w, a);
    case PotWindowShape.pylon:
      // Tapered temple walls under a flared cavetto cornice.
      p
        ..lineTo(w * 0.04, a * 0.75)
        ..quadraticBezierTo(w * 0.02, a * 0.35, 0, a * 0.2)
        ..lineTo(w, a * 0.2)
        ..quadraticBezierTo(w * 0.98, a * 0.35, w * 0.96, a * 0.75);
    case PotWindowShape.moorish:
      p
        ..lineTo(0, a)
        ..quadraticBezierTo(0, a * 0.55, w * 0.08, a * 0.55)
        ..lineTo(w * 0.3, a * 0.55)
        ..cubicTo(w * 0.4, a * 0.55, w * 0.42, a * 0.1, w / 2, 0)
        ..cubicTo(w * 0.58, a * 0.1, w * 0.6, a * 0.55, w * 0.7, a * 0.55)
        ..lineTo(w * 0.92, a * 0.55)
        ..quadraticBezierTo(w, a * 0.55, w, a);
    case PotWindowShape.round:
      p
        ..lineTo(0, a)
        ..cubicTo(0, -a / 3, w, -a / 3, w, a);
    case PotWindowShape.deco:
      final steps = [0.0, 0.14, 0.28, 0.4];
      p.lineTo(0, a);
      for (var i = 1; i < steps.length; i++) {
        final y = a * (1 - i / (steps.length - 1));
        p
          ..lineTo(w * steps[i], a * (1 - (i - 1) / (steps.length - 1)))
          ..lineTo(w * steps[i], y);
      }
      for (var i = steps.length - 1; i >= 1; i--) {
        final y = a * (1 - i / (steps.length - 1));
        p
          ..lineTo(w * (1 - steps[i]), y)
          ..lineTo(w * (1 - steps[i]), a * (1 - (i - 1) / (steps.length - 1)));
      }
      p.lineTo(w, a);
    case PotWindowShape.torii:
      // Kasagi beam: ends sweep up, the middle sags.
      p
        ..lineTo(0, 0)
        ..quadraticBezierTo(w / 2, a * 1.1, w, 0);
  }

  return p
    ..lineTo(w, h - foot)
    ..quadraticBezierTo(w, h, w - foot, h)
    ..lineTo(foot, h)
    ..quadraticBezierTo(0, h, 0, h - foot)
    ..close();
}

class PotWindowClipper extends CustomClipper<Path> {
  const PotWindowClipper(this.shape);

  final PotWindowShape shape;

  @override
  Path getClip(Size size) => potWindowPath(shape, size);

  @override
  bool shouldReclip(covariant PotWindowClipper old) => old.shape != shape;
}

/// Trim line around the art window, with a fine inner echo.
class PotWindowFramePainter extends CustomPainter {
  const PotWindowFramePainter(this.style);

  final PotCardStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final path = potWindowPath(style.window, size);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = style.trim,
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = Colors.white.withValues(alpha: 0.55),
    );
  }

  @override
  bool shouldRepaint(covariant PotWindowFramePainter old) => old.style != style;
}

/// Ribbon with pointed ends: the city name banner and the entry fee tag.
class PotRibbonPainter extends CustomPainter {
  const PotRibbonPainter(this.style, {this.tail = false});

  final PotCardStyle style;

  /// Small trim pennant hanging under the centre.
  final bool tail;

  Path _ribbon(Rect r) {
    final d = r.height * 0.45;
    return Path()
      ..moveTo(r.left + d, r.top)
      ..lineTo(r.right - d, r.top)
      ..lineTo(r.right, r.center.dy)
      ..lineTo(r.right - d, r.bottom)
      ..lineTo(r.left + d, r.bottom)
      ..lineTo(r.left, r.center.dy)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    if (tail) {
      final c = size.width / 2;
      canvas.drawPath(
        Path()
          ..moveTo(c - 7, size.height - 1)
          ..lineTo(c, size.height + 6)
          ..lineTo(c + 7, size.height - 1)
          ..close(),
        Paint()..color = style.trim,
      );
    }
    final outer = _ribbon(rect);
    canvas.drawShadow(outer, Colors.black, 2, false);
    canvas.drawPath(
      outer,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [style.ink, style.inkDeep],
        ).createShader(rect),
    );
    canvas.drawPath(
      outer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = style.trim,
    );
    canvas.drawPath(
      _ribbon(rect.deflate(3.2)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6
        ..color = style.trim.withValues(alpha: 0.7),
    );
  }

  @override
  bool shouldRepaint(covariant PotRibbonPainter old) =>
      old.style != style || old.tail != tail;
}

/// Quarter ornaments tucked into the top-right and bottom-left corners of
/// the card face (sized to [Size]).
class PotCornerPainter extends CustomPainter {
  const PotCornerPainter(this.style, {this.inset = 7, this.radius = 40});

  final PotCardStyle style;
  final double inset;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final frame = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(inset),
      const Radius.circular(11),
    );
    canvas.save();
    canvas.clipRRect(frame);
    _corner(canvas, Offset(size.width - inset, inset), math.pi * 0.75);
    _corner(canvas, Offset(inset, size.height - inset), -math.pi * 0.25);
    canvas.restore();
  }

  /// [inward] is the direction from the corner toward the card centre.
  void _corner(Canvas canvas, Offset corner, double inward) {
    canvas.save();
    canvas.translate(corner.dx, corner.dy);
    final edge =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = style.trim;
    if (_isRosette(style.ornament)) {
      paintPotRosette(canvas, style, radius);
    } else {
      // A spray of emblems fanning toward the centre.
      canvas.drawCircle(
        Offset.zero,
        radius,
        Paint()..color = style.palette[0].withValues(alpha: 0.12),
      );
      for (final (spread, distance, size) in const [
        (-0.62, 0.58, 0.3),
        (0.62, 0.58, 0.3),
        (0.0, 0.5, 0.46),
      ]) {
        final angle = inward + spread;
        canvas.save();
        canvas.translate(
          math.cos(angle) * radius * distance,
          math.sin(angle) * radius * distance,
        );
        // Glyphs point up (-y); turn them to face away from the corner.
        canvas.rotate(angle + math.pi / 2);
        paintPotGlyph(canvas, style, radius * size);
        canvas.restore();
      }
    }
    canvas.drawCircle(Offset.zero, radius, edge);
    canvas.drawCircle(Offset.zero, radius + 3, edge..strokeWidth = 0.6);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PotCornerPainter old) =>
      old.style != style || old.inset != inset || old.radius != radius;
}

/// Centre emblem of the divider under the city name.
class PotEmblemPainter extends CustomPainter {
  const PotEmblemPainter(this.style);

  final PotCardStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2;
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    if (_isRosette(style.ornament)) {
      paintPotRosette(canvas, style, r);
      canvas.drawCircle(
        Offset.zero,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = style.trim,
      );
    } else {
      paintPotGlyph(canvas, style, r);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PotEmblemPainter old) => old.style != style;
}

bool _isRosette(PotOrnament o) => switch (o) {
  PotOrnament.rose ||
  PotOrnament.khokhloma ||
  PotOrnament.lotus ||
  PotOrnament.zellige ||
  PotOrnament.decoFan => true,
  _ => false,
};

Paint _fill(Color c) => Paint()..color = c;

Paint _line(Color c, [double width = 0.8]) =>
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..color = c;

/// Round ornament of radius [r] centred on the canvas origin.
void paintPotRosette(Canvas canvas, PotCardStyle style, double r) {
  final p = style.palette;
  switch (style.ornament) {
    case PotOrnament.rose:
      // Tudor rose: red outer petals, white inner petals, gold heart.
      for (var i = 0; i < 5; i++) {
        final a = i * 2 * math.pi / 5 - math.pi / 2;
        final sepal = a + math.pi / 5;
        canvas.drawPath(
          Path()
            ..moveTo(
              math.cos(sepal - 0.2) * r * 0.6,
              math.sin(sepal - 0.2) * r * 0.6,
            )
            ..lineTo(math.cos(sepal) * r * 0.98, math.sin(sepal) * r * 0.98)
            ..lineTo(
              math.cos(sepal + 0.2) * r * 0.6,
              math.sin(sepal + 0.2) * r * 0.6,
            )
            ..close(),
          _fill(p[3]),
        );
        final c = Offset(math.cos(a), math.sin(a)) * r * 0.48;
        canvas.drawCircle(c, r * 0.4, _fill(p[0]));
        canvas.drawCircle(c, r * 0.4, _line(p[2]));
      }
      for (var i = 0; i < 5; i++) {
        final a = i * 2 * math.pi / 5 - math.pi / 2 + math.pi / 5;
        final c = Offset(math.cos(a), math.sin(a)) * r * 0.22;
        canvas.drawCircle(c, r * 0.22, _fill(p[1]));
        canvas.drawCircle(c, r * 0.22, _line(p[0], 0.6));
      }
      canvas.drawCircle(Offset.zero, r * 0.13, _fill(p[2]));
    case PotOrnament.khokhloma:
      // Folk flower: red teardrops on gold, black heart, red berries.
      canvas.drawCircle(Offset.zero, r, _fill(p[1].withValues(alpha: 0.25)));
      for (var i = 0; i < 8; i++) {
        canvas.save();
        canvas.rotate(i * math.pi / 4);
        canvas.drawPath(_petal(r * 0.9, r * 0.32), _fill(p[0]));
        canvas.drawPath(_petal(r * 0.9, r * 0.32), _line(p[1]));
        canvas.drawPath(_petal(r * 0.55, r * 0.12), _fill(p[1]));
        canvas.rotate(math.pi / 8);
        canvas.drawCircle(Offset(0, -r * 0.82), r * 0.09, _fill(p[0]));
        canvas.drawCircle(Offset(0, -r * 0.82), r * 0.09, _line(p[2], 0.5));
        canvas.restore();
      }
      canvas.drawCircle(Offset.zero, r * 0.22, _fill(p[2]));
      canvas.drawCircle(Offset.zero, r * 0.12, _fill(p[1]));
    case PotOrnament.lotus:
      // Lotus: lapis outer petals, turquoise inner petals, gold disc.
      for (var i = 0; i < 12; i++) {
        canvas.save();
        canvas.rotate(i * math.pi / 6);
        canvas.drawPath(_petal(r * 0.98, r * 0.26), _fill(p[0]));
        canvas.drawPath(_petal(r * 0.98, r * 0.26), _line(p[2], 0.7));
        canvas.rotate(math.pi / 12);
        canvas.drawPath(_petal(r * 0.7, r * 0.2), _fill(p[1]));
        canvas.restore();
      }
      canvas.drawCircle(Offset.zero, r * 0.3, _fill(p[2]));
      canvas.drawCircle(Offset.zero, r * 0.15, _fill(p[3]));
    case PotOrnament.zellige:
      // Moroccan star tile: layered eight-point stars and rings.
      canvas.drawPath(_star8(r), _fill(p[0]));
      canvas.drawPath(_star8(r), _line(const Color(0xFFFBF5E6), 1));
      canvas.drawCircle(Offset.zero, r * 0.66, _fill(p[1]));
      for (var i = 0; i < 8; i++) {
        canvas.save();
        canvas.rotate(i * math.pi / 4 + math.pi / 8);
        canvas.drawPath(_petal(r * 0.64, r * 0.14), _fill(p[2]));
        canvas.restore();
      }
      canvas.drawPath(_star8(r * 0.42), _fill(p[2]));
      canvas.drawPath(_star8(r * 0.42), _line(p[1], 0.8));
      canvas.drawCircle(Offset.zero, r * 0.18, _fill(p[3]));
    case PotOrnament.decoFan:
      // Art-deco sunburst: alternating rays with gold rings.
      const rays = 24;
      for (var i = 0; i < rays; i++) {
        final a0 = i * 2 * math.pi / rays;
        canvas.drawPath(
          Path()
            ..moveTo(0, 0)
            ..arcTo(
              Rect.fromCircle(center: Offset.zero, radius: r),
              a0,
              2 * math.pi / rays,
              false,
            )
            ..close(),
          _fill(i.isEven ? p[0] : p[1]),
        );
      }
      canvas.drawCircle(Offset.zero, r * 0.72, _line(p[3], 1.2));
      canvas.drawCircle(Offset.zero, r * 0.46, _fill(p[2]));
      canvas.drawCircle(Offset.zero, r * 0.46, _line(p[0], 1.2));
      canvas.drawCircle(Offset.zero, r * 0.22, _fill(p[0]));
    case PotOrnament.fleurDeLis:
    case PotOrnament.maple:
    case PotOrnament.sakura:
      paintPotGlyph(canvas, style, r);
  }
}

/// Single emblem of half-height [r], centred on the origin, pointing up.
void paintPotGlyph(Canvas canvas, PotCardStyle style, double r) {
  final p = style.palette;
  canvas.save();
  canvas.scale(r);
  switch (style.ornament) {
    case PotOrnament.fleurDeLis:
      final fleur = _fleurDeLis();
      canvas.drawPath(fleur, _fill(p[0]));
      canvas.drawPath(fleur, _line(p[1], 0.06));
    case PotOrnament.maple:
      final leaf = _mapleLeaf();
      canvas.drawPath(leaf, _fill(p[0]));
      canvas.drawPath(leaf, _line(p[1], 0.05));
    case PotOrnament.sakura:
      for (var i = 0; i < 5; i++) {
        canvas.save();
        canvas.rotate(i * 2 * math.pi / 5);
        final petal = _sakuraPetal();
        canvas.drawPath(petal, _fill(p[0]));
        canvas.drawPath(petal, _line(p[1], 0.05));
        canvas.restore();
      }
      canvas.drawCircle(Offset.zero, 0.2, _fill(p[2]));
      for (var i = 0; i < 5; i++) {
        final a = i * 2 * math.pi / 5 + math.pi / 5 - math.pi / 2;
        canvas.drawCircle(
          Offset(math.cos(a), math.sin(a)) * 0.34,
          0.06,
          _fill(p[3]),
        );
      }
    default:
      canvas.restore();
      paintPotRosette(canvas, style, r);
      return;
  }
  canvas.restore();
}

/// Petal from the origin pointing up to length [length].
Path _petal(double length, double width) =>
    Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(width, -length * 0.55, 0, -length)
      ..quadraticBezierTo(-width, -length * 0.55, 0, 0)
      ..close();

Path _star8(double r) {
  final path = Path();
  for (var i = 0; i < 16; i++) {
    final a = i * math.pi / 8 - math.pi / 2;
    final d = i.isEven ? r : r * 0.72;
    final pt = Offset(math.cos(a), math.sin(a)) * d;
    i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
  }
  return path..close();
}

/// Fleur-de-lis in a unit box around the origin.
Path _fleurDeLis() {
  final path =
      Path()
        // Centre petal.
        ..moveTo(0, -1)
        ..cubicTo(0.3, -0.7, 0.24, -0.32, 0.06, -0.12)
        ..lineTo(-0.06, -0.12)
        ..cubicTo(-0.24, -0.32, -0.3, -0.7, 0, -1)
        ..close()
        // Band.
        ..addRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-0.42, -0.14, 0.84, 0.16),
            const Radius.circular(0.04),
          ),
        )
        // Foot.
        ..moveTo(-0.1, 0.02)
        ..lineTo(0.1, 0.02)
        ..lineTo(0, 0.42)
        ..close();
  for (final s in const [1.0, -1.0]) {
    path
      ..moveTo(0.08 * s, -0.14)
      ..cubicTo(0.2 * s, -0.55, 0.72 * s, -0.68, 0.7 * s, -0.32)
      ..cubicTo(0.68 * s, -0.12, 0.5 * s, -0.1, 0.44 * s, -0.24)
      ..cubicTo(0.5 * s, -0.36, 0.36 * s, -0.38, 0.28 * s, -0.14)
      ..close()
      ..moveTo(0.06 * s, 0.02)
      ..cubicTo(0.2 * s, 0.1, 0.5 * s, 0.1, 0.56 * s, 0.32)
      ..cubicTo(0.4 * s, 0.24, 0.22 * s, 0.24, 0.04 * s, 0.2)
      ..close();
  }
  return path;
}

/// Eleven-point maple leaf in a unit box around the origin.
Path _mapleLeaf() {
  const half = [
    Offset(0, -1),
    Offset(0.14, -0.7),
    Offset(0.27, -0.78),
    Offset(0.21, -0.38),
    Offset(0.45, -0.62),
    Offset(0.5, -0.48),
    Offset(0.74, -0.54),
    Offset(0.63, -0.28),
    Offset(0.76, -0.22),
    Offset(0.42, 0.06),
    Offset(0.47, 0.2),
    Offset(0.06, 0.13),
    Offset(0.06, 0.5),
  ];
  final points = [
    ...half,
    for (final o in half.reversed)
      if (o.dx != 0) Offset(-o.dx, o.dy),
  ];
  return Path()..addPolygon(points, true);
}

/// One notched cherry-blossom petal pointing up from the origin.
Path _sakuraPetal() =>
    Path()
      ..moveTo(0, -0.1)
      ..cubicTo(-0.42, -0.35, -0.42, -0.85, -0.17, -1)
      ..lineTo(0, -0.86)
      ..lineTo(0.17, -1)
      ..cubicTo(0.42, -0.85, 0.42, -0.35, 0, -0.1)
      ..close();
