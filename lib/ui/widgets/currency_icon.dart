import 'dart:math' as math;

import 'package:cardgame/data/avatars/avatar_catalog.dart';
import 'package:cardgame/ui/flame/suit_shapes.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/theme/felt_chrome.dart';
import 'package:flutter/material.dart';

/// Money: a gold coin with a milled edge and an embossed "$", the pair to
/// [ChipIcon].
///
/// Drawn as vectors so it stays crisp from 12px pills to 30px pot cards.
class CashIcon extends StatelessWidget {
  const CashIcon({super.key, this.size = 16});

  final double size;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.square(size),
        painter: const _CashPainter(),
      ),
    );
  }
}

/// Chips: a black poker chip with ivory edge spots and a gold spade inlay.
class ChipIcon extends StatelessWidget {
  const ChipIcon({super.key, this.size = 16});

  final double size;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.square(size),
        painter: const _ChipPainter(),
      ),
    );
  }
}

class CurrencyIcon extends StatelessWidget {
  const CurrencyIcon({super.key, required this.currency, this.size = 16});

  final CurrencyType currency;
  final double size;

  @override
  Widget build(BuildContext context) {
    return switch (currency) {
      CurrencyType.money => CashIcon(size: size),
      CurrencyType.chips => ChipIcon(size: size),
    };
  }
}

const _goldGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFFFE9A3), CasinoColors.gold, Color(0xFFB8860B)],
);

class _CashPainter extends CustomPainter {
  const _CashPainter();

  static const _amber = Color(0xFFB8690A);
  static const _ink = Color(0xFF8C5C06);
  static const _highlight = Color(0xFFFFF6C8);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final c = size.center(Offset.zero);
    final r = s * 0.46;
    final coin = Rect.fromCircle(center: c, radius: r);

    // Coin thickness: deep amber edge peeking out to the lower right.
    canvas.drawCircle(
      c + Offset(s * 0.025, s * 0.04),
      r,
      Paint()..color = const Color(0xFF94520A),
    );

    // Smooth polished rim, bright at the top left, amber at the bottom right.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFF6B0),
            Color(0xFFFFD233),
            Color(0xFFF0A818),
            Color(0xFFC77A0A),
          ],
          stops: [0, 0.35, 0.7, 1],
        ).createShader(coin),
    );

    // Recessed face: its bevel is shaded opposite to the rim.
    final face = r * 0.78;
    final faceRect = Rect.fromCircle(center: c, radius: face);
    canvas.drawCircle(
      c,
      face,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.45),
          radius: 1.1,
          colors: [Color(0xFFFFF0A0), Color(0xFFFFD43B), Color(0xFFF5AE1E)],
          stops: [0, 0.5, 1],
        ).createShader(faceRect),
    );
    canvas.drawCircle(
      c,
      face,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.8, r * 0.07)
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFC77A0A), Color(0xFFE9A21C), Color(0xFFFFF4B8)],
        ).createShader(faceRect),
    );

    // Embossed "$": light edge below right, amber body on top.
    _paintGlyph(
      canvas,
      c + Offset(r * 0.02, r * 0.025),
      r,
      _highlight.withValues(alpha: 0.85),
    );
    _paintGlyph(canvas, c, r, _ink);

    // Glossy shine along the upper-left rim, plus a small sparkle.
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r * 0.89),
      math.pi * 1.05,
      math.pi * 0.38,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(0.7, r * 0.09)
        ..color = Colors.white.withValues(alpha: 0.7),
    );
    if (s >= 20) {
      canvas.drawCircle(
        c + Offset(-r * 0.5, -r * 0.62),
        r * 0.06,
        Paint()..color = Colors.white.withValues(alpha: 0.9),
      );
    }

    // Fine outline keeps the coin crisp on light and dark backgrounds.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.5, r * 0.025)
        ..color = _amber.withValues(alpha: 0.75),
    );
  }

  /// Drawn "$" so its ink, not a font's line box, sits dead centre.
  void _paintGlyph(Canvas canvas, Offset c, double r, Color color) {
    final h = r * 0.46;
    final w = r * 0.27;
    final s =
        Path()
          ..moveTo(c.dx + w * 0.92, c.dy - h * 0.62)
          ..cubicTo(
            c.dx + w * 0.72,
            c.dy - h * 0.9,
            c.dx + w * 0.4,
            c.dy - h,
            c.dx,
            c.dy - h,
          )
          ..cubicTo(
            c.dx - w * 0.6,
            c.dy - h,
            c.dx - w,
            c.dy - h * 0.76,
            c.dx - w,
            c.dy - h * 0.48,
          )
          ..cubicTo(
            c.dx - w,
            c.dy - h * 0.14,
            c.dx - w * 0.5,
            c.dy - h * 0.08,
            c.dx,
            c.dy,
          )
          ..cubicTo(
            c.dx + w * 0.5,
            c.dy + h * 0.08,
            c.dx + w,
            c.dy + h * 0.14,
            c.dx + w,
            c.dy + h * 0.48,
          )
          ..cubicTo(
            c.dx + w,
            c.dy + h * 0.76,
            c.dx + w * 0.6,
            c.dy + h,
            c.dx,
            c.dy + h,
          )
          ..cubicTo(
            c.dx - w * 0.4,
            c.dy + h,
            c.dx - w * 0.72,
            c.dy + h * 0.9,
            c.dx - w * 0.92,
            c.dy + h * 0.62,
          );
    final stroke =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = color;
    canvas.drawPath(s, stroke..strokeWidth = math.max(1.2, r * 0.14));
    canvas.drawLine(
      c - Offset(0, h * 1.36),
      c + Offset(0, h * 1.36),
      stroke..strokeWidth = math.max(0.9, r * 0.085),
    );
  }

  @override
  bool shouldRepaint(covariant _CashPainter oldDelegate) => false;
}

class _ChipPainter extends CustomPainter {
  const _ChipPainter();

  static const _body = Color(0xFF1C1C22);
  static const _bodyHi = Color(0xFF3A3A44);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final c = size.center(Offset.zero);
    final r = s * 0.47;

    // Edge thickness: a darker disc just below the face.
    canvas.drawCircle(
      c + Offset(0, s * 0.035),
      r,
      Paint()..color = const Color(0xFF0A0A0D),
    );

    final face = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.4),
          radius: 1.1,
          colors: [_bodyHi, _body],
        ).createShader(face),
    );

    // Ivory edge spots around the rim.
    final spot =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.24
          ..color = CardInk.ivory;
    final rim = Rect.fromCircle(center: c, radius: r * 0.8);
    for (var i = 0; i < 6; i++) {
      canvas.drawArc(
        rim,
        i * math.pi / 3 - math.pi / 18,
        math.pi / 9,
        false,
        spot,
      );
    }

    // Gold outer rim and inner ring.
    canvas.drawCircle(
      c,
      r - r * 0.04,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.8, r * 0.08)
        ..shader = _goldGradient.createShader(face),
    );
    final inner = Rect.fromCircle(center: c, radius: r * 0.56);
    canvas.drawCircle(c, r * 0.56, Paint()..color = _body);
    canvas.drawCircle(
      c,
      r * 0.56,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.7, r * 0.07)
        ..shader = _goldGradient.createShader(inner),
    );

    // Gold spade inlay.
    final pip = r * 0.62;
    final pipRect = Rect.fromCenter(center: c, width: pip, height: pip);
    canvas.save();
    canvas.translate(pipRect.left, pipRect.top);
    canvas.scale(pip);
    canvas.drawPath(
      suitPath(SuitShape.spades),
      Paint()
        ..shader = _goldGradient.createShader(const Rect.fromLTWH(0, 0, 1, 1)),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ChipPainter oldDelegate) => false;
}
