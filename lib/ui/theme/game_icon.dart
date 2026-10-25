import 'dart:ui' show ImageFilter;

import 'package:flutter/widgets.dart';
import 'package:path_parsing/path_parsing.dart';

/// How a [GameIconPart] is painted.
enum GameIconTone {
  /// The tint at full strength: the part that carries the meaning.
  solid,

  /// The tint at reduced strength: supporting shapes behind the main one.
  soft,

  /// Negative space, cut clean through everything painted before it.
  cut,
}

/// One shape of a [GameIconData]: SVG path data on a 100x100 grid.
@immutable
class GameIconPart {
  const GameIconPart.solid(this.path, {this.stroke, this.fused = false})
    : tone = GameIconTone.solid;

  const GameIconPart.soft(this.path, {this.stroke, this.fused = false})
    : tone = GameIconTone.soft;

  const GameIconPart.cut(this.path, {this.stroke})
    : tone = GameIconTone.cut,
      fused = false;

  final String path;
  final GameIconTone tone;

  /// Stroke width in grid units; null fills the path.
  final double? stroke;

  /// Joins the previous part without the hairline gap that otherwise keeps
  /// overlapping pieces apart (an arrow's shaft and its head).
  final bool fused;
}

/// A glyph built from [parts], painted back to front.
@immutable
class GameIconData {
  const GameIconData(this.parts);

  final List<GameIconPart> parts;
}

/// Paints a [GameIconData] in [color] (or the ambient icon colour): a solid
/// glyph with knocked-out detail, faintly lit from above, on a tight shadow.
///
/// Dark ink (on a gold button or an ivory card) sits on a pale lip instead,
/// as if pressed into the surface.
class GameIcon extends StatelessWidget {
  const GameIcon({super.key, required this.icon, this.size = 24, this.color});

  final GameIconData icon;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    var tint =
        color ??
        theme.color ??
        DefaultTextStyle.of(context).style.color ??
        const Color(0xFFFFFFFF);
    final opacity = theme.opacity ?? 1;
    if (opacity < 1) tint = tint.withValues(alpha: tint.a * opacity);
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _GameIconPainter(icon, tint)),
    );
  }
}

/// Below this luminance a tint is ink on a light surface.
const _inkLuminance = 0.125;

/// Corner softening applied to every filled shape, in grid units.
const _round = 3.0;

/// Strength of [GameIconTone.soft] parts; see-through, so they sit back on
/// any surface.
const _softAlpha = 0.55;

const _white = Color(0xFFFFFFFF);
const _black = Color(0xFF000000);

class _Shape {
  _Shape(GameIconPart part)
    : tone = part.tone,
      stroke = part.stroke,
      fused = part.fused,
      path = _parse(part.path);

  final GameIconTone tone;
  final double? stroke;
  final bool fused;
  final Path path;

  static Path _parse(String data) {
    final proxy = _PathProxy();
    writeSvgPathDataToPath(data, proxy);
    return proxy.path;
  }
}

class _PathProxy extends PathProxy {
  final path = Path();

  @override
  void moveTo(double x, double y) => path.moveTo(x, y);

  @override
  void lineTo(double x, double y) => path.lineTo(x, y);

  @override
  void cubicTo(
    double x1,
    double y1,
    double x2,
    double y2,
    double x3,
    double y3,
  ) => path.cubicTo(x1, y1, x2, y2, x3, y3);

  @override
  void close() => path.close();
}

/// Parsed shapes, built once per icon.
final _shapes = Expando<List<_Shape>>();

List<_Shape> _shapesOf(GameIconData icon) =>
    _shapes[icon] ??= [for (final part in icon.parts) _Shape(part)];

class _GameIconPainter extends CustomPainter {
  _GameIconPainter(this.icon, this.color);

  final GameIconData icon;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final px = size.shortestSide;
    if (px <= 0 || color.a == 0) return;
    final unit = px / 100;
    final shapes = _shapesOf(icon);
    final tint = color.withValues(alpha: 1);
    final ink = tint.computeLuminance() < _inkLuminance;
    final gap = (px * 0.045).clamp(0.8, 2.4) / unit;
    final face =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(tint, _white, ink ? 0.12 : 0.18)!,
              tint,
              Color.lerp(tint, _black, 0.1)!,
            ],
          ).createShader(const Rect.fromLTWH(0, 0, 100, 100));
    final soft =
        Paint()
          ..color = tint.withValues(alpha: _softAlpha)
          ..blendMode = BlendMode.src;

    canvas.save();
    canvas.translate((size.width - px) / 2, (size.height - px) / 2);
    final faded = color.a < 1;
    if (faded) {
      canvas.saveLayer(
        null,
        Paint()..color = _black.withValues(alpha: color.a),
      );
    }

    // Under the glyph: a tight shadow, or a pale lip under dark ink.
    final sigma = px * 0.02;
    canvas.saveLayer(
      null,
      Paint()
        ..colorFilter = ColorFilter.mode(
          (ink ? _white : _black).withValues(alpha: ink ? 0.4 : 0.35),
          BlendMode.srcIn,
        )
        ..imageFilter =
            ink ? null : ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
    );
    canvas.translate(0, (px * 0.04).clamp(0.6, 2.0));
    canvas.scale(unit);
    _glyph(canvas, shapes, face, soft, gap);
    canvas.restore();

    canvas.save();
    canvas.scale(unit);
    _glyph(canvas, shapes, face, soft, gap);
    canvas.restore();

    if (faded) canvas.restore();
    canvas.restore();
  }

  void _glyph(
    Canvas canvas,
    List<_Shape> shapes,
    Paint face,
    Paint soft,
    double gap,
  ) {
    canvas.saveLayer(null, Paint());
    final clear = Paint()..blendMode = BlendMode.clear;
    for (var i = 0; i < shapes.length; i++) {
      final shape = shapes[i];
      if (shape.tone == GameIconTone.cut) {
        _draw(canvas, shape, clear, 0);
        continue;
      }
      // A hairline of clear space keeps each piece apart from the last.
      if (i > 0 && !shape.fused) _draw(canvas, shape, clear, gap);
      _draw(canvas, shape, shape.tone == GameIconTone.solid ? face : soft, 0);
    }
    canvas.restore();
  }

  /// Fills [shape] with softened corners (or strokes a line part), grown by
  /// [grow] on every side.
  void _draw(Canvas canvas, _Shape shape, Paint paint, double grow) {
    final stroke = shape.stroke;
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = (stroke ?? _round) + grow * 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(shape.path, paint);
    if (stroke == null) {
      paint.style = PaintingStyle.fill;
      canvas.drawPath(shape.path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GameIconPainter old) =>
      old.icon != icon || old.color != color;
}
