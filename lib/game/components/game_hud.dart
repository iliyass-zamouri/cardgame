import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:game_protocol/game_protocol.dart';

import '../../core/constants/camo_colors.dart';
import '../../core/constants/camo_typography.dart';
import '../layout/table_layout.dart';

class GameHudComponent extends PositionComponent {
  MatchSnapshotMessage? _snapshot;
  TableLayout? _layout;

  void apply({
    required MatchSnapshotMessage? snapshot,
    required TableLayout layout,
  }) {
    _snapshot = snapshot;
    _layout = layout;
  }

  @override
  void render(Canvas canvas) {
    final snap = _snapshot;
    final layout = _layout;
    if (snap == null || layout == null) return;

    final hud = layout.hudRect;
    var x = hud.left;

    _paintLabel(canvas, (snap.phase.name).toUpperCase(), x, hud.top, CamoColors.timer);
    x += _labelWidth((snap.phase.name).toUpperCase()) + 10;

    if (snap.topDiscardValue != null) {
      final topLabel = 'TOP ${_valueLabel(snap.topDiscardValue)}';
      _paintLabel(canvas, topLabel, x, hud.top, CamoColors.primary);
    }

    final isReveal = snap.phase == WireMatchPhase.reveal;
    final rightLabel = isReveal
        ? '${snap.revealSecondsLeft}s'
        : (snap.canAct ? 'YOUR TURN' : 'WAIT');
    final rightColor = isReveal
        ? CamoColors.secondary
        : (snap.canAct ? CamoColors.tertiary : CamoColors.onSurfaceVariant);
    final rw = _labelWidth(rightLabel);
    _paintLabel(canvas, rightLabel, hud.right - rw, hud.top, rightColor);
  }

  void _paintLabel(Canvas canvas, String text, double x, double y, Color color) {
    final style = CamoTypography.labelCaps(color);
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x, y));
  }

  double _labelWidth(String text) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: CamoTypography.labelCaps(CamoColors.white)),
      textDirection: TextDirection.ltr,
    )..layout();
    return tp.width;
  }

  String _valueLabel(int? value) {
    if (value == null) return '--';
    const faces = {1: 'A', 11: 'J', 12: 'Q', 13: 'K'};
    return faces[value] ?? '$value';
  }
}
