import 'package:flutter/material.dart';

/// Visual tokens matched to the dark poker-app screenshot (not Material 3).
abstract final class CasinoColors {
  static const bg = Color(0xFF0B0B0D);
  static const bgElevated = Color(0xFF16161A);
  static const surface = Color(0xFF1E1E24);
  static const surfaceHi = Color(0xFF2A2A32);
  static const rim = Color(0xFF141418);
  static const felt = Color(0xFF1F6B45);
  static const feltDeep = Color(0xFF155234);
  static const gold = Color(0xFFF5C542);
  static const goldSoft = Color(0xFFFFE082);
  static const text = Color(0xFFF2F2F5);
  static const textMuted = Color(0xFFA8A8B3);
  static const fold = Color(0xFFB71C1C);
  static const foldHi = Color(0xFFD32F2F);
  static const check = Color(0xFFE65100);
  static const checkHi = Color(0xFFFF6D00);
  static const raise = Color(0xFF00897B);
  static const raiseHi = Color(0xFF26A69A);
  static const success = Color(0xFF2E7D32);
  static const borderGlow = Color(0xFF3D8B5F);
}

/// [display] = Cinzel (Latin brand). [ui] = DM Sans. [arabicUi] for Arabic locale.
abstract final class CasinoFonts {
  static const display = 'Cinzel';
  static const ui = 'DM Sans';
  static const arabicUi = 'Noto Naskh Arabic';

  static String uiFor(Locale locale) =>
      locale.languageCode == 'ar' ? arabicUi : ui;

  static String displayFor(Locale locale) =>
      locale.languageCode == 'ar' ? arabicUi : display;
}

ThemeData buildCasinoTheme({Locale locale = const Locale('en')}) {
  final uiFamily = CasinoFonts.uiFor(locale);
  final displayFamily = CasinoFonts.displayFor(locale);

  const scheme = ColorScheme.dark(
    surface: CasinoColors.bg,
    primary: CasinoColors.raise,
    onPrimary: CasinoColors.text,
    secondary: CasinoColors.gold,
    onSecondary: CasinoColors.bg,
    error: CasinoColors.fold,
    onSurface: CasinoColors.text,
  );

  final ui = TextStyle(fontFamily: uiFamily);
  final display = TextStyle(fontFamily: displayFamily);

  return ThemeData(
    useMaterial3: false,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: Colors.transparent,
    fontFamily: uiFamily,
    splashFactory: InkRipple.splashFactory,
    textTheme: TextTheme(
      displaySmall: display.copyWith(
        color: CasinoColors.text,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
      headlineMedium: display.copyWith(
        color: CasinoColors.text,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
      titleLarge: ui.copyWith(
        color: CasinoColors.text,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: ui.copyWith(
        color: CasinoColors.text,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: ui.copyWith(color: CasinoColors.text),
      bodyMedium: ui.copyWith(color: CasinoColors.textMuted),
      bodySmall: ui.copyWith(color: CasinoColors.textMuted, fontSize: 12),
      labelLarge: ui.copyWith(
        color: CasinoColors.text,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: CasinoColors.surface.withValues(alpha: 0.94),
      contentTextStyle: TextStyle(
        fontFamily: uiFamily,
        color: CasinoColors.text,
        fontSize: 13,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 0,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: CasinoColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: TextStyle(
        fontFamily: uiFamily,
        color: CasinoColors.text,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      contentTextStyle: TextStyle(
        fontFamily: uiFamily,
        color: CasinoColors.textMuted,
        fontSize: 14,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: CasinoColors.surfaceHi,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(color: CasinoColors.surfaceHi),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(
          color: CasinoColors.borderGlow,
          width: 1.4,
        ),
      ),
      labelStyle: TextStyle(
        fontFamily: uiFamily,
        color: CasinoColors.textMuted,
      ),
      hintStyle: TextStyle(fontFamily: uiFamily, color: CasinoColors.textMuted),
    ),
  );
}

/// Uppercase Latin labels only; leave Arabic (and similar) untouched.
String casinoButtonLabel(String label, Locale locale) {
  if (locale.languageCode == 'ar') return label;
  return label.toUpperCase();
}
