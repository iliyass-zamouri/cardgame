import 'package:flutter/material.dart';

abstract final class CamoColors {
  static const background = Color(0xFF131316);
  static const white = Color(0xFFFFFFFF);
  static const onBackground = Color(0xFFE4E1E5);
  static const surface = Color(0xFF131316);
  static const surfaceContainer = Color(0xFF1F1F22);
  static const surfaceVariant = Color(0xFF353438);
  static const primary = Color(0xFF92CCFF);
  static const primaryContainer = Color(0xFF3498DB);
  static const onPrimaryContainer = Color(0xFF002D47);
  static const secondary = Color(0xFFFFDD74);
  static const secondaryFixedDim = Color(0xFFEEC209);
  static const tertiary = Color(0xFF4AE183);
  static const onSurface = Color(0xFFE4E1E5);
  static const onSurfaceVariant = Color(0xFFBFC7D2);
  static const outlineVariant = Color(0xFF3F4850);
  static const danger = Color(0xFFE53935);
  static const timer = Color(0xFFF0D45A);

  // Arcade palette (Parchisi-inspired)
  static const purpleDeep = Color(0xFF1E0A3C);
  static const purpleMid = Color(0xFF3D1870);
  static const purpleGlow = Color(0xFF6B2FA8);
  static const purpleLight = Color(0xFF9B59D0);
  static const goldLight = Color(0xFFFFECAA);
  static const goldDark = Color(0xFFD4A017);
  static const panelBorder = Color(0xFF5A3D8A);
}

abstract final class GamePaintPalette {
  static const colors = <Color>[
    Color(0xFF1A3A2A),
    Color(0xFF315C4A),
    Color(0xFF4AE183),
    Color(0xFF92CCFF),
    Color(0xFFFFDD74),
    Color(0xFFE8E8E8),
    Color(0xFF8B5E3C),
    Color(0xFF5C4033),
    Color(0xFF3498DB),
    Color(0xFFE74C3C),
    Color(0xFF9B59B6),
    Color(0xFF2C3E50),
  ];
  static const defaultPaint = Color(0xFF315C4A);
}
