import 'package:cardgame/ui/theme/app_theme.dart';
import 'package:cardgame/ui/theme/casino_palette.dart';
import 'package:flutter/material.dart';

/// Card-table tokens: surfaces are deep felt greens so panels sit naturally
/// on the green table background (not Material 3).
///
/// Every token reads the active theme's palette (see [AppTheme.active]), so
/// the values can change at runtime. Never cache one in a field or a static:
/// read it where it is drawn.
abstract final class CasinoColors {
  static CasinoPalette get _p => AppTheme.active.palette;

  static Color get bg => _p.bg;
  static Color get bgElevated => _p.bgElevated;
  static Color get surface => _p.surface;
  static Color get surfaceHi => _p.surfaceHi;
  static Color get rim => _p.rim;
  static Color get leather => _p.leather;
  static Color get leatherDeep => _p.leatherDeep;
  static Color get felt => _p.felt;
  static Color get feltHi => _p.feltHi;
  static Color get feltDeep => _p.feltDeep;
  static Color get feltEdge => _p.feltEdge;
  static Color get room => _p.room;
  static Color get roomDeep => _p.roomDeep;
  static Color get seatRing => _p.seatRing;
  static Color get gold => _p.gold;
  static Color get goldSoft => _p.goldSoft;
  static Color get goldHi => _p.goldHi;
  static Color get goldLo => _p.goldLo;
  static Color get text => _p.text;
  static Color get textMuted => _p.textMuted;
  static Color get fold => _p.fold;
  static Color get foldHi => _p.foldHi;
  static Color get check => _p.check;
  static Color get checkHi => _p.checkHi;
  static Color get raise => _p.raise;
  static Color get raiseHi => _p.raiseHi;
  static Color get success => _p.success;
  static Color get borderGlow => _p.borderGlow;
  static Color get silver => _p.silver;
}

/// [display] = Cinzel (Latin brand). [ui] = DM Sans. [arabicUi] = Cairo.
abstract final class CasinoFonts {
  static const display = 'Cinzel';
  static const ui = 'DM Sans';
  static const arabicUi = 'Cairo';

  static String uiFor(Locale locale) =>
      locale.languageCode == 'ar' ? arabicUi : ui;

  static String displayFor(Locale locale) =>
      locale.languageCode == 'ar' ? arabicUi : display;

  static String uiOf(BuildContext context) =>
      uiFor(Localizations.localeOf(context));

  static String displayOf(BuildContext context) =>
      displayFor(Localizations.localeOf(context));
}

ThemeData buildCasinoTheme({Locale locale = const Locale('en')}) {
  final uiFamily = CasinoFonts.uiFor(locale);
  final displayFamily = CasinoFonts.displayFor(locale);

  final scheme = ColorScheme.dark(
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
      // fixed — floating + tall content/AppBar triggers off-screen assert
      behavior: SnackBarBehavior.fixed,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 0,
    ),
    tabBarTheme: TabBarThemeData(
      indicator: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [CasinoColors.goldSoft, CasinoColors.gold],
        ),
      ),
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: Colors.transparent,
      labelColor: CasinoColors.bg,
      unselectedLabelColor: CasinoColors.goldSoft,
      labelStyle: TextStyle(
        fontFamily: uiFamily,
        fontWeight: FontWeight.w800,
        fontSize: 13,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: uiFamily,
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      splashFactory: NoSplash.splashFactory,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: CasinoColors.surface,
      modalBackgroundColor: CasinoColors.surface,
      // No border here: every sheet draws its own framed panel (CasinoGlass
      // etc.) on a transparent background, so a themed rim showed twice.
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      // Full width on a phone; a wide window centres a sheet-sized panel.
      constraints: const BoxConstraints(maxWidth: 640),
    ),
    dividerTheme: DividerThemeData(
      color: CasinoColors.gold.withValues(alpha: 0.12),
      thickness: 1,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: CasinoColors.gold,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected)
                ? CasinoColors.gold
                : CasinoColors.textMuted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected)
                ? CasinoColors.gold.withValues(alpha: 0.4)
                : CasinoColors.surfaceHi,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: CasinoColors.gold),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: CasinoColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: CasinoColors.gold.withValues(alpha: 0.35)),
      ),
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
        borderSide: BorderSide(color: CasinoColors.surfaceHi),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide(color: CasinoColors.borderGlow, width: 1.4),
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
