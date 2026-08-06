import 'package:flutter/material.dart';

import 'camo_colors.dart';
import 'camo_typography.dart';

abstract final class AppTheme {
  static ThemeData get dark {
    const base = ColorScheme.dark(
      surface: CamoColors.surface,
      primary: CamoColors.primary,
      secondary: CamoColors.secondary,
      tertiary: CamoColors.tertiary,
      onSurface: CamoColors.onSurface,
      onPrimary: CamoColors.onPrimaryContainer,
      error: CamoColors.danger,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: base,
      scaffoldBackgroundColor: CamoColors.background,
      textTheme: TextTheme(
        displayLarge: CamoTypography.displayLg(CamoColors.onBackground),
        headlineMedium: CamoTypography.headlineMd(CamoColors.onBackground),
        bodyLarge: CamoTypography.bodyLg(CamoColors.onBackground),
        labelLarge: CamoTypography.labelCaps(CamoColors.onBackground),
      ),
    );
  }
}
