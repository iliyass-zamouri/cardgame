import 'dart:math' as math;

import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:flutter/material.dart';

/// Illustrated two-tone icons for the home navigation bar: pale silver
/// bodies with gold accents and a soft drop shadow.
enum NavArt { shop, friends, home, rules, collection }

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
      _Tone.hub => [CasinoColors.leather, CasinoColors.leather],
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
    NavArt.rules => _rules(),
    NavArt.collection => _collection(),
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

  List<_Shape> _collection() {
    const backCenter = Offset(40, 40);
    const frontCenter = Offset(64, 42);
    const dieCenter = Offset(44, 70);
    Path pip(double x, double y) =>
        _rotated(_circle(x, y, 3.6), -12, dieCenter);
    return [
      _Shape(_rotated(_rrect(18, 8, 62, 72, 6), -14, backCenter), _Tone.light),
      _Shape(
        _rotated(_rrect(24, 15, 56, 65, 3), -14, backCenter),
        _Tone.shade,
        stroke: 2,
        shadow: false,
      ),
      _Shape(_rotated(_rrect(42, 10, 86, 74, 6), 10, frontCenter), _Tone.light),
      _Shape(
        _rotated(_rrect(48, 17, 80, 67, 3), 10, frontCenter),
        _Tone.shade,
        stroke: 2,
        shadow: false,
      ),
      _Shape(
        _rotated(_circle(64, 42, 7), 10, frontCenter),
        _Tone.shade,
        shadow: false,
      ),
      _Shape(_rotated(_rrect(26, 52, 62, 88, 8), -12, dieCenter), _Tone.gold),
      _Shape(pip(35, 61), _Tone.ink, shadow: false),
      _Shape(pip(53, 61), _Tone.ink, shadow: false),
      _Shape(pip(44, 70), _Tone.ink, shadow: false),
      _Shape(pip(35, 79), _Tone.ink, shadow: false),
      _Shape(pip(53, 79), _Tone.ink, shadow: false),
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
