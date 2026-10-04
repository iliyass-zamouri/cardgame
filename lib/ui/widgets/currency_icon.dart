import 'dart:math' as math;

import 'package:cardgame/data/avatars/avatar_catalog.dart';
import 'package:cardgame/ui/flame/suit_shapes.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/theme/felt_chrome.dart';
import 'package:flutter/material.dart';

/// Money: a small stack of felt-green banknotes with a gold "$" seal.
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

  static const _billLight = Color(0xFF34A86B);
  static const _billDark = Color(0xFF1B6A43);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-0.28);

    final w = s * 0.76;
    final h = s * 0.5;
    final radius = Radius.circular(s * 0.07);
    final stroke = math.max(0.8, s * 0.03);

    // Two bills peeking out underneath, then the top bill.
    for (var i = 2; i >= 0; i--) {
      final offset = Offset(i * s * 0.035, i * s * 0.07);
      final rect = Rect.fromCenter(
        center: offset - Offset(s * 0.035, s * 0.07),
        width: w,
        height: h,
      );
      final rrect = RRect.fromRectAndRadius(rect, radius);
      final shade = i == 0 ? 1.0 : (i == 1 ? 0.8 : 0.65);
      canvas.drawRRect(
        rrect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(_billDark, _billLight, shade)!,
              Color.lerp(Colors.black, _billDark, shade)!,
            ],
          ).createShader(rect),
      );
      canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke * 0.8
          ..color = const Color(0x66000000),
      );
      if (i == 0) {
        // Ivory engraved border on the top bill.
        canvas.drawRRect(
          rrect.deflate(s * 0.05),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke
            ..color = CardInk.ivory.withValues(alpha: 0.85),
        );
        _drawSeal(canvas, rect.center, h * 0.4, s);
      }
    }
  }

  void _drawSeal(Canvas canvas, Offset c, double r, double s) {
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(c, r, Paint()..shader = _goldGradient.createShader(rect));
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.6, s * 0.02)
        ..color = const Color(0xFF7A5A0E),
    );
    final tp = TextPainter(
      text: TextSpan(
        text: r'$',
        style: TextStyle(
          fontFamily: CasinoFonts.display,
          color: CardInk.black,
          fontSize: r * 1.5,
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
