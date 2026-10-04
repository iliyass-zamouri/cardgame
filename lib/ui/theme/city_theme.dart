import 'package:flutter/material.dart';

/// Look of one pot city on the gameplay screen: a custom painted table whose
/// richness grows with the pot ([tier] 0 = London … 4 = Marrakech).
@immutable
class CityTheme {
  const CityTheme({
    required this.id,
    required this.tier,
    required this.accent,
    required this.feltLight,
    required this.feltDark,
    required this.railLight,
    required this.railDark,
    required this.backdrop,
  });

  final String id;

  /// 0..4; drives how ornate the table is.
  final int tier;

  /// HUD highlight, felt inlays and ornaments.
  final Color accent;

  /// Felt gradient, centre to edge.
  final Color feltLight;
  final Color feltDark;

  /// Rail gradient (highlight to shade).
  final Color railLight;
  final Color railDark;

  /// Room colour around the table.
  final Color backdrop;

  /// Plain green felt on a wooden rail.
  static const london = CityTheme(
    id: 'london',
    tier: 0,
    accent: Color(0xFF8BC98F),
    feltLight: Color(0xFF1F6B45),
    feltDark: Color(0xFF0E3A26),
    railLight: Color(0xFF6B4527),
    railDark: Color(0xFF2E1B0F),
    backdrop: Color(0xFF07150F),
  );

  /// Blue felt, brass rail, diamond lattice.
  static const paris = CityTheme(
    id: 'paris',
    tier: 1,
    accent: Color(0xFF9CC7F5),
    feltLight: Color(0xFF2358A0),
    feltDark: Color(0xFF0E2A55),
    railLight: Color(0xFFC9A24E),
    railDark: Color(0xFF6B5020),
    backdrop: Color(0xFF050B1E),
  );

  /// Crimson felt, gold studded rail, double inlay and rosettes.
  static const moscow = CityTheme(
    id: 'moscow',
    tier: 2,
    accent: Color(0xFFFFD27A),
    feltLight: Color(0xFF9B2626),
    feltDark: Color(0xFF4A0F12),
    railLight: Color(0xFFE6B94A),
    railDark: Color(0xFF7A5416),
    backdrop: Color(0xFF14050A),
  );

  /// Black felt, gold rail, sun disc and meander border.
  static const cairo = CityTheme(
    id: 'cairo',
    tier: 3,
    accent: Color(0xFFFFC857),
    feltLight: Color(0xFF2B2B33),
    feltDark: Color(0xFF0E0E12),
    railLight: Color(0xFFF2CB62),
    railDark: Color(0xFF8A6119),
    backdrop: Color(0xFF0B0803),
  );

  /// Ivory and gold: zellige stars, jewelled rail, sparkle.
  static const marrakech = CityTheme(
    id: 'marrakech',
    tier: 4,
    accent: Color(0xFFFFE9A8),
    feltLight: Color(0xFF3E7C9E),
    feltDark: Color(0xFF173A52),
    railLight: Color(0xFFFFF0C2),
    railDark: Color(0xFFB98A2E),
    backdrop: Color(0xFF0C1620),
  );

  /// In stake-pool order (20 · 50 · 100 · 200 · 500).
  static const all = [london, paris, moscow, cairo, marrakech];
  static const _pools = [20, 50, 100, 200, 500];

  /// City for a stake pool: the highest tier the pool reaches. Free or
  /// private games (pool 0) have no city.
  static CityTheme? forStake(int stakePool) {
    if (stakePool <= 0) return null;
    var index = 0;
    for (var i = 0; i < _pools.length; i++) {
      if (stakePool >= _pools[i]) index = i;
    }
    return all[index];
  }
}
