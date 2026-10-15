import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Illustrated two-tone icons for the home navigation bar: pale silver
/// bodies with gold accents and a soft drop shadow.
enum NavArt { shop, friends, home, ranking, rules }

class NavArtIcon extends StatelessWidget {
  const NavArtIcon(this.art, {super.key, this.size = 40});

  final NavArt art;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _NavArtPainter(art)),
    );
  }
}

enum _Tone { light, gold, shade, ink, hub }

class _Shape {
  const _Shape(this.path, this.tone, {this.stroke, this.shadow = true});

  final Path path;
  final _Tone tone;

  /// Stroke width; null fills the path.
  final double? stroke;
  final bool shadow;
}

class _NavArtPainter extends CustomPainter {
  _NavArtPainter(this.art);

  final NavArt art;

  static const _shadowOffset = Offset(0, 3.5);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    // Shapes are authored on a 100x100 grid.
    canvas.scale(size.width / 100, size.height / 100);
    final shadow =
        Paint()
          ..color = Colors.black.withValues(alpha: 0.38)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);
    for (final shape in _shapes(art)) {
      if (shape.shadow) {
        _apply(shadow, shape);
        canvas.drawPath(shape.path.shift(_shadowOffset), shadow);
      }
      canvas.drawPath(shape.path, _paintFor(shape));
    }
    canvas.restore();
  }

  void _apply(Paint paint, _Shape shape) {
    if (shape.stroke == null) {
      paint.style = PaintingStyle.fill;
    } else {
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = shape.stroke!
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
    }
  }

  Paint _paintFor(_Shape shape) {
    final paint = Paint();
    _apply(paint, shape);
    final bounds = shape.path.getBounds().inflate((shape.stroke ?? 0) / 2);
    final colors = switch (shape.tone) {
      _Tone.light => const [Color(0xFFF7FAFC), Color(0xFFC2CFDC)],
      _Tone.gold => const [
        Color(0xFFFFE69A),
        Color(0xFFF5C542),
        Color(0xFFC98F1E),
      ],
      _Tone.shade => const [Color(0xFFAEBCCB), Color(0xFF8B9BAD)],
      _Tone.ink => const [Color(0xFF5A3A26), Color(0xFF5A3A26)],
      _Tone.hub => const [Color(0xFF2B1A12), Color(0xFF2B1A12)],
    };
    return paint
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: colors,
      ).createShader(bounds);
  }

  List<_Shape> _shapes(NavArt art) => switch (art) {
    NavArt.shop => _shop(),
    NavArt.friends => _friends(),
    NavArt.home => _home(),
    NavArt.ranking => _ranking(),
    NavArt.rules => _rules(),
  };

  static Path _circle(double x, double y, double r) =>
      Path()..addOval(Rect.fromCircle(center: Offset(x, y), radius: r));

  static Path _rrect(double l, double t, double r, double b, double radius) =>
      Path()..addRRect(RRect.fromLTRBR(l, t, r, b, Radius.circular(radius)));

  static Path _rotated(Path path, double degrees, Offset center) {
    final m =
        Matrix4.translationValues(center.dx, center.dy, 0)
          ..multiply(Matrix4.rotationZ(degrees * math.pi / 180))
          ..multiply(Matrix4.translationValues(-center.dx, -center.dy, 0));
    return path.transform(m.storage);
  }

  List<_Shape> _shop() {
    final basket =
        Path()
          ..moveTo(26, 30)
          ..lineTo(90, 30)
          ..lineTo(82, 64)
          ..lineTo(34, 64)
          ..close();
    return [
      _Shape(
        Path()
          ..moveTo(8, 20)
          ..lineTo(21, 20)
          ..lineTo(33, 68),
        _Tone.light,
        stroke: 8,
      ),
      _Shape(basket, _Tone.light),
      _Shape(basket, _Tone.light, stroke: 6, shadow: false),
      _Shape(
        Path()
          ..moveTo(32, 76)
          ..lineTo(84, 76),
        _Tone.light,
        stroke: 6,
      ),
      _Shape(_circle(40, 87, 8), _Tone.gold),
      _Shape(_circle(78, 87, 8), _Tone.gold),
      _Shape(_circle(40, 87, 3), _Tone.hub, shadow: false),
      _Shape(_circle(78, 87, 3), _Tone.hub, shadow: false),
    ];
  }

  List<_Shape> _friends() {
    Path body(double l, double r, double top, double bottom) {
      final mid = (l + r) / 2;
      return Path()
        ..moveTo(l, bottom)
        ..quadraticBezierTo(l, top, mid, top)
        ..quadraticBezierTo(r, top, r, bottom)
        ..close();
    }

    return [
      _Shape(body(4, 40, 58, 84), _Tone.gold),
      _Shape(_circle(22, 43, 11), _Tone.gold),
      _Shape(body(60, 96, 58, 84), _Tone.gold),
      _Shape(_circle(78, 43, 11), _Tone.gold),
      _Shape(body(22, 78, 56, 92), _Tone.light),
      _Shape(_circle(50, 32, 16), _Tone.light),
    ];
  }

  List<_Shape> _home() {
    final house =
        Path()
          ..moveTo(24, 48)
          ..lineTo(50, 26)
          ..lineTo(76, 48)
          ..lineTo(76, 86)
          ..quadraticBezierTo(76, 90, 72, 90)
          ..lineTo(28, 90)
          ..quadraticBezierTo(24, 90, 24, 86)
          ..close();
    final door =
        Path()..addRRect(
          RRect.fromLTRBAndCorners(
            42,
            62,
            58,
            90,
            topLeft: const Radius.circular(8),
            topRight: const Radius.circular(8),
          ),
        );
    return [
      _Shape(_rrect(64, 16, 76, 44, 2), _Tone.gold),
      _Shape(house, _Tone.light),
      _Shape(door, _Tone.shade, shadow: false),
      _Shape(
        Path()
          ..moveTo(12, 52)
          ..lineTo(50, 20)
          ..lineTo(88, 52),
        _Tone.gold,
        stroke: 11,
      ),
    ];
  }

  List<_Shape> _ranking() {
    final cup =
        Path()
          ..moveTo(26, 14)
          ..lineTo(74, 14)
          ..lineTo(72, 40)
          ..quadraticBezierTo(70, 62, 50, 64)
          ..quadraticBezierTo(30, 62, 28, 40)
          ..close();
    final star = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? 11.0 : 4.8;
      final a = -math.pi / 2 + i * math.pi / 5;
      final p = Offset(50 + r * math.cos(a), 36 + r * math.sin(a));
      i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
    }
    star.close();
    return [
      _Shape(
        Path()
          ..moveTo(30, 24)
          ..quadraticBezierTo(12, 24, 15, 40)
          ..quadraticBezierTo(18, 52, 34, 52),
        _Tone.gold,
        stroke: 6,
      ),
      _Shape(
        Path()
          ..moveTo(70, 24)
          ..quadraticBezierTo(88, 24, 85, 40)
          ..quadraticBezierTo(82, 52, 66, 52),
        _Tone.gold,
        stroke: 6,
      ),
      _Shape(cup, _Tone.gold),
      _Shape(star, _Tone.light, shadow: false),
      _Shape(_rrect(44, 62, 56, 76, 1), _Tone.light),
      _Shape(_rrect(28, 74, 72, 90, 4), _Tone.light),
    ];
  }

  List<_Shape> _rules() {
    const backCenter = Offset(36, 52);
    const frontCenter = Offset(63, 50);
    final question =
        Path()
          ..moveTo(55, 40)
          ..quadraticBezierTo(55, 30, 63, 30)
          ..quadraticBezierTo(71, 30, 71, 38)
          ..quadraticBezierTo(71, 44, 63, 47)
          ..lineTo(63, 53);
    return [
      _Shape(_rotated(_rrect(13, 20, 59, 84, 7), -14, backCenter), _Tone.gold),
      _Shape(
        _rotated(_rrect(20, 27, 52, 77, 4), -14, backCenter),
        _Tone.ink,
        stroke: 2,
        shadow: false,
      ),
      _Shape(_rotated(_rrect(40, 16, 86, 84, 7), 10, frontCenter), _Tone.light),
      _Shape(
        _rotated(question, 10, frontCenter),
        _Tone.ink,
        stroke: 6,
        shadow: false,
      ),
      _Shape(
        _rotated(_circle(63, 64, 3.8), 10, frontCenter),
        _Tone.ink,
        shadow: false,
      ),
    ];
  }

  @override
  bool shouldRepaint(covariant _NavArtPainter old) => old.art != art;
}
