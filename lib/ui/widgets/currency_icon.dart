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

  static const _edge = Color(0xFF8A6512);
  static const _ink = Color(0xFF6E4F0A);
  static const _highlight = Color(0xFFFFF4CC);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final c = size.center(Offset.zero);
    final r = s * 0.47;

    // Coin thickness: a darker disc just below the face, like the chip.
    canvas.drawCircle(
      c + Offset(0, s * 0.035),
      r,
      Paint()..color = const Color(0xFF5C430A),
    );

    final face = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.45),
          radius: 1.15,
          colors: [Color(0xFFFFEDB0), CasinoColors.gold, Color(0xFFB8860B)],
          stops: [0, 0.55, 1],
        ).createShader(face),
    );

    // Milled edge: short radial ticks around the rim.
    final tickCount = s < 20 ? 16 : 28;
    final tick =
        Paint()
          ..color = _edge.withValues(alpha: 0.7)
          ..strokeWidth = math.max(0.6, r * 0.05)
          ..strokeCap = StrokeCap.round;
    for (var i = 0; i < tickCount; i++) {
      final a = i * 2 * math.pi / tickCount;
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(c + dir * r * 0.86, c + dir * r * 0.97, tick);
    }

    // Outer rim line and raised inner ring.
    canvas.drawCircle(
      c,
      r - r * 0.02,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.7, r * 0.05)
        ..color = _edge,
    );
    final inner = r * 0.72;
    canvas.drawCircle(
      c,
      inner,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.7, r * 0.06)
        ..color = _edge.withValues(alpha: 0.85),
    );
    canvas.drawCircle(
      c + Offset(r * 0.03, r * 0.03),
      inner,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.5, r * 0.03)
        ..color = _highlight.withValues(alpha: 0.6),
    );

    // Embossed "$": a light offset copy under the dark glyph.
    _paintGlyph(canvas, c + Offset(r * 0.03, r * 0.04), r, _highlight);
    _paintGlyph(canvas, c, r, _ink);

    // Soft glint on the upper-left of the face.
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r * 0.84),
      math.pi * 1.08,
      math.pi * 0.32,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(0.6, r * 0.06)
        ..color = Colors.white.withValues(alpha: 0.55),
    );
  }

  void _paintGlyph(Canvas canvas, Offset c, double r, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: r'$',
        style: TextStyle(
          fontFamily: CasinoFonts.display,
          color: color,
          fontSize: r * 0.95,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
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
