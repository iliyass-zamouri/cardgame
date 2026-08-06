import 'package:flutter/material.dart';

import '../../core/constants/camo_colors.dart';

abstract final class CamoCardPainter {
  static const cardBackGreen = Color(0xFF315C4A);
  static const cardFace = Color(0xFFE8E8E8);
  static const cardBorder = Color(0xFF353438);
  static const stripeRed = Color(0xFF7F1D1D);

  static void paintCard({
    required Canvas canvas,
    required Rect rect,
    required String tag,
    required bool faceUp,
    double cornerRadius = 10,
  }) {
    _paintShadow(canvas, rect);

    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(cornerRadius));
    if (faceUp && tag != 'XX') {
      canvas.drawRRect(rrect, Paint()..color = cardFace);
      canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = cardBorder,
      );
      _paintFaceLabel(canvas, rect, tag);
    } else {
      _paintCardBack(canvas, rrect);
    }
  }

  static void _paintShadow(Canvas canvas, Rect rect) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.shift(const Offset(0, 18)),
        const Radius.circular(10),
      ),
      Paint()
        ..color = const Color.fromRGBO(0, 0, 0, 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.shift(const Offset(0, 30)),
        const Radius.circular(10),
      ),
      Paint()
        ..color = const Color.fromRGBO(50, 50, 93, 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
    );
  }

  static void _paintCardBack(Canvas canvas, RRect rrect) {
    canvas.drawRRect(rrect, Paint()..color = cardBackGreen);
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = cardBorder,
    );

    final inner = rrect.deflate(6);
    final innerRrect = RRect.fromRectAndRadius(
      inner.outerRect,
      Radius.circular(inner.outerRect.width * 0.08),
    );
    canvas.drawRRect(innerRrect, Paint()..color = CamoColors.white);
    canvas.drawRRect(
      innerRrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = stripeRed,
    );

    canvas.save();
    canvas.clipRRect(innerRrect);
    _paintDiagonalStripes(canvas, inner.outerRect);
    canvas.restore();
  }

  static void _paintDiagonalStripes(Canvas canvas, Rect rect) {
    const stripeWidth = 12.0;
    final paint = Paint()..color = stripeRed.withValues(alpha: 0.85);
    final diag = rect.width + rect.height;
    for (var i = -diag; i < diag; i += stripeWidth * 2) {
      final path = Path()
        ..moveTo(rect.left + i, rect.top)
        ..lineTo(rect.left + i + stripeWidth, rect.top)
        ..lineTo(rect.left + i + stripeWidth - rect.height, rect.bottom)
        ..lineTo(rect.left + i - rect.height, rect.bottom)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  static void _paintFaceLabel(Canvas canvas, Rect rect, String tag) {
    final label = _label(tag);
    final color = _suitColor(tag);
    final fontSize = (rect.width * 0.18).clamp(10.0, 18.0);
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: rect.width);
    tp.paint(canvas, rect.topLeft + Offset(rect.width * 0.08, rect.height * 0.06));
  }

  static String _label(String tag) {
    if (tag.length < 2) return '?';
    final v = int.tryParse(tag.substring(1)) ?? 0;
    const faces = {1: 'A', 11: 'J', 12: 'Q', 13: 'K'};
    final suit = {'A': '♣', 'B': '♦', 'C': '♥', 'D': '♠'}[tag[0]] ?? '';
    return '${faces[v] ?? v}$suit';
  }

  static Color _suitColor(String tag) {
    if (tag.startsWith('B') || tag.startsWith('C')) {
      return const Color(0xFFE74C3C);
    }
    return const Color(0xFF1A1A1E);
  }

  static void paintTurnGradient({
    required Canvas canvas,
    required Rect rect,
    required bool isLocal,
  }) {
    final gradient = LinearGradient(
      begin: isLocal ? Alignment.bottomCenter : Alignment.topCenter,
      end: isLocal ? Alignment.topCenter : Alignment.bottomCenter,
      colors: [
        CamoColors.white.withValues(alpha: 0.35),
        CamoColors.white.withValues(alpha: 0),
      ],
    );
    canvas.drawRect(
      rect,
      Paint()..shader = gradient.createShader(rect),
    );
  }
}
