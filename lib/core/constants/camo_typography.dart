import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class CamoTypography {
  static String _localeCode = 'en';

  static void setLocaleCode(String code) {
    _localeCode = code;
  }

  static bool get isArabic => _localeCode == 'ar';

  static TextStyle displayLg(Color color) {
    if (isArabic) {
      return GoogleFonts.cairo(
        fontSize: 28,
        height: 32 / 28,
        letterSpacing: 0,
        fontWeight: FontWeight.w800,
        color: color,
      );
    }
    return GoogleFonts.rubik(
      fontSize: 28,
      height: 32 / 28,
      letterSpacing: -0.02 * 28,
      fontWeight: FontWeight.w900,
      fontStyle: FontStyle.italic,
      color: color,
    );
  }

  static TextStyle displaySm(Color color) {
    if (isArabic) {
      return GoogleFonts.cairo(
        fontSize: 18,
        height: 22 / 18,
        fontWeight: FontWeight.w700,
        color: color,
      );
    }
    return GoogleFonts.rubik(
      fontSize: 18,
      height: 22 / 18,
      fontWeight: FontWeight.w800,
      color: color,
    );
  }

  static TextStyle headlineMd(Color color) {
    if (isArabic) {
      return GoogleFonts.cairo(
        fontSize: 14,
        height: 18 / 14,
        fontWeight: FontWeight.w700,
        color: color,
      );
    }
    return GoogleFonts.rubik(
      fontSize: 14,
      height: 18 / 14,
      fontWeight: FontWeight.w700,
      color: color,
    );
  }

  static TextStyle bodyLg(Color color) {
    if (isArabic) {
      return GoogleFonts.cairo(
        fontSize: 13,
        height: 16 / 13,
        fontWeight: FontWeight.w500,
        color: color,
      );
    }
    return GoogleFonts.rubik(
      fontSize: 13,
      height: 16 / 13,
      fontWeight: FontWeight.w500,
      color: color,
    );
  }

  static TextStyle labelCaps(Color color) {
    if (isArabic) {
      return GoogleFonts.cairo(
        fontSize: 11,
        height: 12 / 11,
        letterSpacing: 0,
        fontWeight: FontWeight.w700,
        color: color,
      );
    }
    return GoogleFonts.spaceGrotesk(
      fontSize: 10,
      height: 12 / 10,
      letterSpacing: 0.08 * 10,
      fontWeight: FontWeight.w700,
      color: color,
    );
  }

  /// Bubbly arcade title with heavy weight — pair with [CamoGameTitle] for shadow.
  static TextStyle gameTitle(Color color) {
    if (isArabic) {
      return GoogleFonts.cairo(
        fontSize: 32,
        height: 1.05,
        fontWeight: FontWeight.w900,
        color: color,
      );
    }
    return GoogleFonts.rubik(
      fontSize: 32,
      height: 1.05,
      letterSpacing: 0.5,
      fontWeight: FontWeight.w900,
      color: color,
    );
  }
}
