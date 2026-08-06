import 'package:flutter/material.dart';

import '../constants/camo_colors.dart';
import '../constants/camo_typography.dart';

class CamoGameTitle extends StatelessWidget {
  const CamoGameTitle(
    this.text, {
    super.key,
    this.fontSize = 36,
    this.stacked = false,
  });

  final String text;
  final double fontSize;
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    if (stacked) {
      final parts = text.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        final mid = (parts.length / 2).ceil();
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _OutlinedLine(parts.sublist(0, mid).join(' '), fontSize),
            SizedBox(height: fontSize * 0.08),
            _OutlinedLine(parts.sublist(mid).join(' '), fontSize),
          ],
        );
      }
    }
    return _OutlinedLine(text, fontSize);
  }
}

class _OutlinedLine extends StatelessWidget {
  const _OutlinedLine(this.text, this.fontSize);

  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final display = text.toUpperCase();
    final fillStyle = CamoTypography.gameTitle(CamoColors.goldLight).copyWith(
      fontSize: fontSize,
      height: 1.0,
      shadows: const [
        Shadow(color: Color(0xFF3D2200), offset: Offset(0, 4), blurRadius: 0),
        Shadow(color: Color(0x66000000), offset: Offset(0, 6), blurRadius: 8),
      ],
    );
    final strokeStyle = fillStyle.copyWith(
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = fontSize * 0.09
        ..color = CamoColors.white.withValues(alpha: 0.95),
    );

    return Stack(
      alignment: Alignment.center,
      children: [
        Text(display, textAlign: TextAlign.center, style: strokeStyle),
        Text(display, textAlign: TextAlign.center, style: fillStyle),
      ],
    );
  }
}
