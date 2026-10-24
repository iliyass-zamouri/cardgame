import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:path_parsing/path_parsing.dart';

/// How a [GameIconPart] takes its colour from the icon's tint.
enum GameIconTone {
  /// The tint itself, lit from above.
  body,

  /// The tint's partner: ivory beside a colour, gold beside white or black.
  accent,

  /// Fine detail: dark on a light tint, ivory on a dark one.
  ink,
}

/// One shape of a [GameIconData]: SVG path data on a 100x100 grid.
@immutable
class GameIconPart {
  const GameIconPart.body(this.path, {this.stroke, this.fused = false})
    : tone = GameIconTone.body;

  const GameIconPart.accent(this.path, {this.stroke, this.fused = false})
    : tone = GameIconTone.accent;

  const GameIconPart.ink(this.path, {this.stroke})
    : tone = GameIconTone.ink,
      fused = false;

  final String path;
  final GameIconTone tone;

  /// Stroke width in grid units; null fills the path.
  final double? stroke;

  /// Shares the previous part's outline, so the two read as one piece
  /// (an arrow's shaft and head) with no seam where they meet.
  final bool fused;
}

/// A chunky, outlined game icon: [parts] painted back to front.
@immutable
class GameIconData {
  const GameIconData(this.parts);

  final List<GameIconPart> parts;
}

/// Paints a [GameIconData] in [color] (or the ambient icon colour) with the
/// sticker look: dark outline, top light, bottom shade and a drop shadow.
///
/// Dark tints (ink on a gold button or an ivory card) come out as black
/// lacquer with gold trim, like the game's chip.
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

/// Below this luminance a tint is ink, and the icon turns to lacquer.
const _lacquerLuminance = 0.125;

/// How far the top light and bottom shade reach into a shape, in grid units.
const _bevel = 4.0;

/// Corner rounding applied to every filled shape, in grid units.
const _round = 4.0;

const _white = Color(0xFFFFFFFF);
const _black = Color(0xFF000000);
const _silverShade = Color(0xFFB4C3D2);
const _gold = [Color(0xFFFFE69A), Color(0xFFF5C542), Color(0xFFC98F1E)];
const _ivory = [Color(0xFFFFFDF6), Color(0xFFF6EEDB), Color(0xFFE2D5B6)];
const _ivoryInk = Color(0xFFFFF6DE);

class _Shape {
  _Shape(GameIconPart part)
    : tone = part.tone,
      stroke = part.stroke,
      fused = part.fused,
      path = _parse(part.path) {
    if (stroke == null && tone != GameIconTone.ink) {
      light = Path.combine(
        PathOperation.difference,
        path,
        path.shift(const Offset(_bevel * 0.35, _bevel)),
      );
      shade = Path.combine(
        PathOperation.difference,
        path,
        path.shift(const Offset(0, -_bevel)),
      );
    }
  }

  final GameIconTone tone;
  final double? stroke;
  final bool fused;
  final Path path;
  Path? light;
  Path? shade;

  late final Rect bounds = path.getBounds().inflate((stroke ?? _round) / 2);

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

/// The colours one tint paints with.
class _Look {
  factory _Look(Color tint) {
    final hsl = HSLColor.fromColor(tint);
    // Chroma, not HSL saturation, which runs wild for near-whites.
    final chroma =
        math.max(tint.r, math.max(tint.g, tint.b)) -
        math.min(tint.r, math.min(tint.g, tint.b));
    final neutral = chroma < 0.12;
    if (tint.computeLuminance() < _lacquerLuminance) {
      return _Look._(
        body: [
          Color.lerp(tint, _white, 0.34)!,
          tint,
          Color.lerp(tint, _black, 0.5)!,
        ],
        accent: _gold,
        ink: _ivoryInk,
        line: Color.lerp(tint, _black, 0.7)!,
      );
    }
    final line =
        hsl
            .withSaturation(math.min(hsl.saturation, 0.6))
            .withLightness(0.1)
            .toColor();
    if (neutral && hsl.lightness > 0.85) {
      return _Look._(
        body: [_white, tint, _silverShade],
        accent: _gold,
        ink: line,
        line: line,
      );
    }
    return _Look._(
      body: [
        Color.lerp(tint, _white, 0.42)!,
        tint,
        hsl.withLightness(math.max(0, hsl.lightness - 0.2)).toColor(),
      ],
      accent:
          neutral
              ? [
                Color.lerp(tint, _white, 0.75)!,
                Color.lerp(tint, _white, 0.6)!,
                Color.lerp(tint, _white, 0.42)!,
              ]
              : _ivory,
      ink: line,
      line: line,
    );
  }

  const _Look._({
    required this.body,
    required this.accent,
    required this.ink,
    required this.line,
  });

  final List<Color> body;
  final List<Color> accent;
  final Color ink;

  /// The outline round every piece.
  final Color line;
}

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
    final look = _Look(color.withValues(alpha: 1));
    final outline = (px * 0.06).clamp(1.0, 3.2) / unit;
    canvas.save();
    canvas.translate((size.width - px) / 2, (size.height - px) / 2);
    canvas.scale(unit);
    final faded = color.a < 1;
    if (faded) {
      canvas.saveLayer(
        null,
        Paint()..color = _black.withValues(alpha: color.a),
      );
    }

    // Drop shadow: every silhouette, flattened into one soft layer.
    canvas.saveLayer(null, Paint()..color = _black.withValues(alpha: 0.42));
    canvas.save();
    canvas.translate(0, (px * 0.05).clamp(0.8, 3.0) / unit);
    final shadow =
        Paint()
          ..color = _black
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            (px * 0.02).clamp(0.4, 1.4) / unit,
          );
    for (final shape in shapes) {
      _silhouette(canvas, shape, shadow, outline);
    }
    canvas.restore();
    canvas.restore();

    final ink = Paint()..color = look.ink;
    final rim = Paint()..color = look.line;
    for (var i = 0; i < shapes.length; i++) {
      final shape = shapes[i];
      if (shape.tone == GameIconTone.ink) {
        _fill(canvas, shape, ink);
        continue;
      }
      // A fused run is outlined as one piece, then filled.
      if (!shape.fused) {
        for (var j = i; j < shapes.length; j++) {
          if (j > i && !shapes[j].fused) break;
          _outline(canvas, shapes[j], outline, rim);
        }
      }
      _fill(
        canvas,
        shape,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: shape.tone == GameIconTone.body ? look.body : look.accent,
          ).createShader(shape.bounds),
      );
      _light(canvas, shape);
    }

    if (faded) canvas.restore();
    canvas.restore();
  }

  void _silhouette(Canvas canvas, _Shape shape, Paint paint, double outline) {
    final stroke = shape.stroke;
    canvas.drawPath(
      shape.path,
      Paint()
        ..color = paint.color
        ..maskFilter = paint.maskFilter
        ..style = PaintingStyle.stroke
        ..strokeWidth = (stroke ?? _round) + outline * 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    if (stroke == null) canvas.drawPath(shape.path, paint);
  }

  /// Strokes [width] beyond the shape's edge on every side.
  void _outline(Canvas canvas, _Shape shape, double width, Paint paint) {
    canvas.drawPath(
      shape.path,
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = (shape.stroke ?? _round) + width * 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  /// Fills a shape with its corners rounded off, or strokes a line part.
  void _fill(Canvas canvas, _Shape shape, Paint paint) {
    final stroke = shape.stroke;
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke ?? _round
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(shape.path, paint);
    if (stroke == null) {
      paint.style = PaintingStyle.fill;
      canvas.drawPath(shape.path, paint);
    }
  }

  void _light(Canvas canvas, _Shape shape) {
    final stroke = shape.stroke;
    if (stroke == null) {
      canvas.drawPath(
        shape.light!,
        Paint()..color = _white.withValues(alpha: 0.42),
      );
      canvas.drawPath(
        shape.shade!,
        Paint()..color = _black.withValues(alpha: 0.16),
      );
      return;
    }
    // A line part gets a glint along its upper edge instead.
    canvas.drawPath(
      shape.path.shift(Offset(-stroke * 0.08, -stroke * 0.18)),
      Paint()
        ..color = _white.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke * 0.3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _GameIconPainter old) =>
      old.icon != icon || old.color != color;
}
