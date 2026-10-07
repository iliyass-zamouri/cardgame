import 'package:cardgame/domain/models/game_snapshot.dart';
import 'package:flutter/material.dart';

/// Look of one pot city on the gameplay screen: a custom painted table whose
/// richness grows with the pot ([tier] 0 = London … 4 = Marrakech and the
/// chip tables).
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

  /// Racing-green tartan felt, mahogany and brass, Big Ben's dial.
  static const london = CityTheme(
    id: 'london',
    tier: 0,
    accent: Color(0xFFE2B84C),
    feltLight: Color(0xFF1F6B45),
    feltDark: Color(0xFF0C2E20),
    railLight: Color(0xFF7A3A22),
    railDark: Color(0xFF2A0F08),
    backdrop: Color(0xFF06140E),
  );

  /// Navy velvet with fleur-de-lis damask, gilded rail and pearls.
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

  /// Crimson felt, gold studded rail, the Kremlin's ruby star.
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

  /// Black felt, gold rail with lapis, winged sun and a jewelled collar.
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

  /// Black and white, like its chip: monochrome zellige on charcoal felt
  /// inside a mother-of-pearl rail.
  static const marrakech = CityTheme(
    id: 'marrakech',
    tier: 4,
    accent: Color(0xFFF2F2F4),
    feltLight: Color(0xFF34343B),
    feltDark: Color(0xFF0E0E11),
    railLight: Color(0xFFFFFFFF),
    railDark: Color(0xFFB4B4BC),
    backdrop: Color(0xFF09090B),
  );

  /// Chip table: teal felt with falling maple leaves, brushed silver.
  static const toronto = CityTheme(
    id: 'toronto',
    tier: 4,
    accent: Color(0xFFE6F2F5),
    feltLight: Color(0xFF2A6F73),
    feltDark: Color(0xFF103538),
    railLight: Color(0xFFE3E7EC),
    railDark: Color(0xFF7B8794),
    backdrop: Color(0xFF061416),
  );

  /// Chip table: violet art-deco felt, gold rail of marquee bulbs.
  static const newYork = CityTheme(
    id: 'new_york',
    tier: 4,
    accent: Color(0xFFE7C8FF),
    feltLight: Color(0xFF4B2A7A),
    feltDark: Color(0xFF1F0F3A),
    railLight: Color(0xFFF5D27A),
    railDark: Color(0xFF8F6A1C),
    backdrop: Color(0xFF0D0618),
  );

  /// Chip table: plum felt with seigaiha waves and sakura, black lacquer
  /// rail trimmed in rose gold.
  static const tokyo = CityTheme(
    id: 'tokyo',
    tier: 4,
    accent: Color(0xFFF2B8A6),
    feltLight: Color(0xFF8A2457),
    feltDark: Color(0xFF2E0A1E),
    railLight: Color(0xFF4A2E38),
    railDark: Color(0xFF0B0507),
    backdrop: Color(0xFF14040D),
  );

  /// Money tables in stake-pool order (20 · 50 · 100 · 200 · 500).
  static const all = [london, paris, moscow, cairo, marrakech];
  static const _pools = [20, 50, 100, 200, 500];

  /// Chip tables in stake-pool order (2 · 10 · 50 chips).
  static const chipTables = [toronto, newYork, tokyo];
  static const _chipPools = [2, 10, 50];

  /// City for a stake pool: the highest tier the pool reaches. Free or
  /// private games (pool 0) have no city.
  static CityTheme? forStake(int stakePool, {bool chips = false}) {
    if (stakePool <= 0) return null;
    final pools = chips ? _chipPools : _pools;
    final cities = chips ? chipTables : all;
    var index = 0;
    for (var i = 0; i < pools.length; i++) {
      if (stakePool >= pools[i]) index = i;
    }
    return cities[index];
  }

  static CityTheme? forGame(GameSnapshot? game) =>
      game == null
          ? null
          : CityTheme.forStake(game.stakePool, chips: game.stakedInChips);
}
