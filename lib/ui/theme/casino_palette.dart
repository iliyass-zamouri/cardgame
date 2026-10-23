import 'package:flutter/material.dart';

/// Every colour token the app draws with. [casino] is the original green-felt
/// look; other themes supply their own values (see app_theme.dart).
@immutable
class CasinoPalette {
  const CasinoPalette({
    required this.bg,
    required this.bgElevated,
    required this.surface,
    required this.surfaceHi,
    required this.rim,
    required this.leather,
    required this.leatherDeep,
    required this.felt,
    required this.feltHi,
    required this.feltDeep,
    required this.feltEdge,
    required this.room,
    required this.roomDeep,
    required this.seatRing,
    required this.gold,
    required this.goldSoft,
    required this.goldHi,
    required this.goldLo,
    required this.text,
    required this.textMuted,
    required this.silver,
    required this.fold,
    required this.foldHi,
    required this.check,
    required this.checkHi,
    required this.raise,
    required this.raiseHi,
    required this.success,
    required this.borderGlow,
  });

  final Color bg;
  final Color bgElevated;
  final Color surface;
  final Color surfaceHi;
  final Color rim;
  final Color leather;
  final Color leatherDeep;
  final Color felt;
  final Color feltHi;
  final Color feltDeep;
  final Color feltEdge;

  /// Room around a free table, and its ring of seats.
  final Color room;
  final Color roomDeep;
  final Color seatRing;

  final Color gold;
  final Color goldSoft;
  final Color goldHi;
  final Color goldLo;
  final Color text;
  final Color textMuted;
  final Color silver;
  final Color fold;
  final Color foldHi;
  final Color check;
  final Color checkHi;
  final Color raise;
  final Color raiseHi;
  final Color success;
  final Color borderGlow;

  static const casino = CasinoPalette(
    bg: Color(0xFF07150F),
    bgElevated: Color(0xFF0D2118),
    surface: Color(0xFF12291F),
    surfaceHi: Color(0xFF1C3B2D),
    rim: Color(0xFF0A1711),
    leather: Color(0xFF2B1A12),
    leatherDeep: Color(0xFF170D08),
    felt: Color(0xFF1F6B45),
    feltHi: Color(0xFF237A4F),
    feltDeep: Color(0xFF155234),
    feltEdge: Color(0xFF0A2618),
    room: Color(0xFF12293A),
    roomDeep: Color(0xFF07131D),
    seatRing: Color(0xFF3FA36F),
    gold: Color(0xFFF5C542),
    goldSoft: Color(0xFFFFE082),
    goldHi: Color(0xFFFFE08A),
    goldLo: Color(0xFFC8961E),
    text: Color(0xFFF2F2F5),
    textMuted: Color(0xFFA9BDB1),
    silver: Color(0xFFD9D9D9),
    fold: Color(0xFFB71C1C),
    foldHi: Color(0xFFD32F2F),
    check: Color(0xFFE65100),
    checkHi: Color(0xFFFF6D00),
    raise: Color(0xFF00897B),
    raiseHi: Color(0xFF26A69A),
    success: Color(0xFF2E7D32),
    borderGlow: Color(0xFF3D8B5F),
  );

  /// Witch's-parlour purple felt, pumpkin gold, slime-green raises.
  static const halloween = CasinoPalette(
    bg: Color(0xFF0A0612),
    bgElevated: Color(0xFF130A21),
    surface: Color(0xFF1A0F2E),
    surfaceHi: Color(0xFF2A1948),
    rim: Color(0xFF080410),
    leather: Color(0xFF2D1710),
    leatherDeep: Color(0xFF170A06),
    felt: Color(0xFF4B2A7A),
    feltHi: Color(0xFF5B348F),
    feltDeep: Color(0xFF321B5A),
    feltEdge: Color(0xFF120824),
    room: Color(0xFF1B1033),
    roomDeep: Color(0xFF07030F),
    seatRing: Color(0xFFA77BFF),
    gold: Color(0xFFFF8A1F),
    goldSoft: Color(0xFFFFC074),
    goldHi: Color(0xFFFFB259),
    goldLo: Color(0xFFC25A00),
    text: Color(0xFFF7F1FF),
    textMuted: Color(0xFFB8A9D6),
    silver: Color(0xFFE4DCEE),
    fold: Color(0xFFB3122A),
    foldHi: Color(0xFFE0314B),
    check: Color(0xFF7E4DD2),
    checkHi: Color(0xFFA074F2),
    raise: Color(0xFF27873F),
    raiseHi: Color(0xFF38AA55),
    success: Color(0xFF3DBB5A),
    borderGlow: Color(0xFF9B6BFF),
  );
}
