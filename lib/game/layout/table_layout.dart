import 'dart:ui';

import 'package:flame/components.dart';

import '../../core/constants/camo_spacing.dart';

/// Viewport-relative layout matching the old home_screen proportions.
class TableLayout {
  TableLayout(this.size);

  final Vector2 size;

  static const handBandFraction = 0.4;
  static const gridWidth = 220.0;
  static const deckCardWidth = 120.0;
  static const localHandCardWidth = 120.0;
  static const remoteHandCardWidth = 40.0;
  static const edgeInset = 4.0;
  static const hudTop = CamoSpacing.hudMargin + 44.0;
  static const actionBottom = CamoSpacing.hudMargin + 56.0;

  double get cardAspect => 140 / 168;

  double get deckCardHeight => deckCardWidth / cardAspect * (168 / 140);

  static double _safeClamp(double value, double min, double max) {
    if (max < min) return max;
    return value.clamp(min, max);
  }

  static double _minOf(double a, double b) => a < b ? a : b;

  Rect get remoteHandRect {
    final bandW = size.x * handBandFraction;
    final bandH = size.y * handBandFraction;
    final maxH = size.y * 0.38;
    final w = _safeClamp(bandW, _minOf(180.0, gridWidth), gridWidth);
    final h = _safeClamp(bandH, _minOf(120.0, maxH), maxH);
    return Rect.fromLTWH(
      (size.x - w) / 2,
      hudTop,
      w,
      h,
    );
  }

  Rect get localHandRect {
    final bandW = size.x * handBandFraction;
    final bandH = size.y * handBandFraction;
    final maxH = size.y * 0.38;
    final w = _safeClamp(bandW, _minOf(180.0, gridWidth), gridWidth);
    final h = _safeClamp(bandH, _minOf(120.0, maxH), maxH);
    return Rect.fromLTWH(
      (size.x - w) / 2,
      size.y - h - actionBottom,
      w,
      h,
    );
  }

  Rect get centerRowRect {
    final top = remoteHandRect.bottom;
    final bottom = localHandRect.top;
    final height = _safeClamp(bottom - top, 48.0, size.y);
    return Rect.fromLTWH(0, top, size.x, height);
  }

  Rect get deckRect {
    final row = centerRowRect;
    final maxH = row.height * 0.85;
    final minH = _minOf(100.0, maxH);
    final cardH = _safeClamp(deckCardHeight, minH, maxH);
    final cardW = cardH * (140 / 168);
    final cy = row.center.dy;
    return Rect.fromCenter(
      center: Offset(size.x / 2 - cardW - CamoSpacing.lg, cy),
      width: cardW,
      height: cardH,
    );
  }

  Rect get discardRect {
    final row = centerRowRect;
    final maxH = row.height * 0.85;
    final minH = _minOf(100.0, maxH);
    final cardH = _safeClamp(deckCardHeight, minH, maxH);
    final cardW = cardH * (140 / 168);
    final cy = row.center.dy;
    return Rect.fromCenter(
      center: Offset(size.x / 2 + cardW + CamoSpacing.lg, cy),
      width: cardW,
      height: cardH,
    );
  }

  Rect get localHandCardRect {
    final cardH = localHandCardWidth / cardAspect * (168 / 140);
    return Rect.fromLTWH(
      edgeInset,
      size.y - cardH - edgeInset - actionBottom * 0.3,
      localHandCardWidth,
      cardH,
    );
  }

  Rect get remoteHandCardRect {
    final cardH = remoteHandCardWidth / cardAspect * (168 / 140);
    return Rect.fromLTWH(
      edgeInset,
      hudTop * 0.15 + edgeInset,
      remoteHandCardWidth,
      cardH,
    );
  }

  Rect get hudRect => Rect.fromLTWH(
        CamoSpacing.hudMargin,
        CamoSpacing.hudMargin,
        size.x - CamoSpacing.hudMargin * 2,
        36,
      );

  Rect get actionBarRect => Rect.fromLTWH(
        CamoSpacing.hudMargin,
        size.y - actionBottom,
        size.x - CamoSpacing.hudMargin * 2,
        48,
      );
}
