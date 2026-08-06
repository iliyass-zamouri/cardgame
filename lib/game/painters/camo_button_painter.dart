import 'package:flutter/material.dart';

import '../../core/constants/camo_colors.dart';
import '../../core/constants/camo_spacing.dart';

enum CamoButtonStyle { start, menuPrimary, menuSecondary }

abstract final class CamoButtonPainter {
  static const restDepth = 4.0;

  static void paint({
    required Canvas canvas,
    required Rect rect,
    required String label,
    required CamoButtonStyle style,
    bool enabled = true,
    bool pressed = false,
  }) {
    final depth = pressed ? 1.0 : restDepth;
    final faceRect = rect.deflate(0).translate(0, pressed ? 3 : 0);
    final shadowRect = Rect.fromLTWH(
      faceRect.left,
      faceRect.top + depth,
      faceRect.width,
      faceRect.height,
    );

    final (faceGradient, sideColor, foreground) = _colors(style, enabled);
    final r = CamoSpacing.md;

    canvas.drawRRect(
      RRect.fromRectAndRadius(shadowRect, Radius.circular(r)),
      Paint()..color = sideColor,
    );

    final faceRrect = RRect.fromRectAndRadius(faceRect, Radius.circular(r));
    canvas.drawRRect(
      faceRrect,
      Paint()
        ..shader = faceGradient.createShader(faceRect),
    );
    canvas.drawRRect(
      faceRrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = style == CamoButtonStyle.start ? 2 : 1.5
        ..color = sideColor,
    );

    final fontSize = style == CamoButtonStyle.start ? 18.0 : 11.0;
    final tp = TextPainter(
      text: TextSpan(
        text: label.toUpperCase(),
        style: TextStyle(
          color: foreground,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: style == CamoButtonStyle.start ? 1.2 : 0.8,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: faceRect.width - 16);
    tp.paint(
      canvas,
      faceRect.center - Offset(tp.width / 2, tp.height / 2),
    );
  }

  static (Gradient, Color, Color) _colors(CamoButtonStyle style, bool enabled) {
    switch (style) {
      case CamoButtonStyle.start:
        if (enabled) {
          return (
            const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [CamoColors.goldLight, CamoColors.secondary],
            ),
            CamoColors.goldDark,
            const Color(0xFF3D2200),
          );
        }
        return (
          LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              CamoColors.surfaceContainer,
              CamoColors.purpleDeep.withValues(alpha: 0.8),
            ],
          ),
          CamoColors.surfaceVariant,
          CamoColors.onSurfaceVariant,
        );
      case CamoButtonStyle.menuPrimary:
        return (
          const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF5BB8F5), CamoColors.primaryContainer],
          ),
          const Color(0xFF2471A3),
          CamoColors.white,
        );
      case CamoButtonStyle.menuSecondary:
        return (
          LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              CamoColors.surfaceContainer,
              CamoColors.purpleDeep.withValues(alpha: 0.85),
            ],
          ),
          CamoColors.surfaceVariant,
          CamoColors.primary,
        );
    }
  }
}
