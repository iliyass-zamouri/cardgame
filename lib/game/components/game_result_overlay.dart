import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:game_protocol/game_protocol.dart';

import '../../core/constants/camo_colors.dart';
import '../../core/constants/camo_spacing.dart';
import '../../core/constants/camo_typography.dart';
import '../painters/camo_button_painter.dart';

class GameResultOverlayComponent extends PositionComponent with TapCallbacks {
  GameResultOverlayComponent({
    required this.onRematch,
    required this.onLobby,
  });

  final VoidCallback onRematch;
  final VoidCallback onLobby;

  MatchSnapshotMessage? _snapshot;
  bool _visible = false;
  String? _pressedId;

  void apply({
    required MatchSnapshotMessage? snapshot,
    required bool visible,
  }) {
    _snapshot = snapshot;
    _visible = visible;
  }

  @override
  void render(Canvas canvas) {
    if (!_visible || _snapshot == null) return;

    final snap = _snapshot!;
    final rect = size.toRect();

    canvas.drawRect(
      rect,
      Paint()..color = const Color(0xA6000000),
    );

    const panelW = 340.0;
    const panelH = 320.0;
    final panelRect = Rect.fromCenter(
      center: rect.center,
      width: panelW,
      height: panelH,
    );

    final panelRrect = RRect.fromRectAndRadius(
      panelRect,
      const Radius.circular(CamoSpacing.lg),
    );
    canvas.drawRRect(
      panelRrect,
      Paint()..color = CamoColors.surfaceContainer.withValues(alpha: 0.95),
    );
    canvas.drawRRect(
      panelRrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = CamoColors.panelBorder,
    );

    final outcome = snap.outcome == 'draw'
        ? 'DRAW'
        : (snap.winnerId == snap.localPlayerId ? 'VICTORY' : 'DEFEAT');
    _paintCentered(
      canvas,
      outcome,
      CamoTypography.displayLg(CamoColors.secondary),
      panelRect.top + CamoSpacing.xl,
      panelRect.width,
      panelRect.left,
    );

    var y = panelRect.top + 72;
    for (final p in snap.players) {
      final line = '${p.displayName ?? p.id}: ${p.total}';
      _paintCentered(
        canvas,
        line,
        CamoTypography.bodyLg(CamoColors.onSurface),
        y,
        panelRect.width,
        panelRect.left,
      );
      y += 22;
    }

    const btnW = panelW - CamoSpacing.xl * 2;
    const btnH = 46.0;
    final rematchRect = Rect.fromLTWH(
      panelRect.left + CamoSpacing.xl,
      panelRect.bottom - btnH * 2 - CamoSpacing.lg * 2,
      btnW,
      btnH,
    );
    final lobbyRect = Rect.fromLTWH(
      panelRect.left + CamoSpacing.xl,
      panelRect.bottom - btnH - CamoSpacing.lg,
      btnW,
      btnH,
    );

    CamoButtonPainter.paint(
      canvas: canvas,
      rect: rematchRect,
      label: 'REMATCH',
      style: CamoButtonStyle.start,
      pressed: _pressedId == 'rematch',
    );
    CamoButtonPainter.paint(
      canvas: canvas,
      rect: lobbyRect,
      label: 'LOBBY',
      style: CamoButtonStyle.menuSecondary,
      pressed: _pressedId == 'lobby',
    );
  }

  void _paintCentered(
    Canvas canvas,
    String text,
    TextStyle style,
    double y,
    double width,
    double left,
  ) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width - CamoSpacing.lg * 2);
    tp.paint(canvas, Offset(left + (width - tp.width) / 2, y));
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (!_visible) return;
    _pressedId = _hitTest(event.localPosition.toOffset());
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (!_visible) return;
    final hit = _hitTest(event.localPosition.toOffset());
    if (hit == 'rematch') onRematch();
    if (hit == 'lobby') onLobby();
    _pressedId = null;
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    _pressedId = null;
  }

  String? _hitTest(Offset pos) {
    final rect = size.toRect();
    const panelW = 340.0;
    const panelH = 320.0;
    final panelRect = Rect.fromCenter(
      center: rect.center,
      width: panelW,
      height: panelH,
    );
    const btnW = panelW - CamoSpacing.xl * 2;
    const btnH = 46.0;
    final rematchRect = Rect.fromLTWH(
      panelRect.left + CamoSpacing.xl,
      panelRect.bottom - btnH * 2 - CamoSpacing.lg * 2,
      btnW,
      btnH,
    );
    final lobbyRect = Rect.fromLTWH(
      panelRect.left + CamoSpacing.xl,
      panelRect.bottom - btnH - CamoSpacing.lg,
      btnW,
      btnH,
    );
    if (rematchRect.contains(pos)) return 'rematch';
    if (lobbyRect.contains(pos)) return 'lobby';
    return null;
  }
}
