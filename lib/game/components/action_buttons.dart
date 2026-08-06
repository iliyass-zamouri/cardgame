import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:game_protocol/game_protocol.dart';

import '../layout/table_layout.dart';
import '../painters/camo_button_painter.dart';

class ActionButtonsComponent extends PositionComponent with TapCallbacks {
  ActionButtonsComponent({required this.onReveal, required this.onCallGame});

  final VoidCallback onReveal;
  final VoidCallback onCallGame;

  MatchSnapshotMessage? _snapshot;
  WirePlayerState? _local;
  TableLayout? _layout;
  String? _pressedId;

  void apply({
    required MatchSnapshotMessage? snapshot,
    required WirePlayerState? local,
    required TableLayout layout,
  }) {
    _snapshot = snapshot;
    _local = local;
    _layout = layout;
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    final layout = _layout;
    if (layout == null) return false;
    const btnW = 180.0;
    const btnH = 48.0;
    final bar = layout.actionBarRect;
    final rect = Rect.fromLTWH(bar.center.dx - btnW / 2, bar.top, btnW, btnH);
    return rect.contains(point.toOffset());
  }

  @override
  void render(Canvas canvas) {
    final snap = _snapshot;
    final layout = _layout;
    if (snap == null || layout == null) return;

    final bar = layout.actionBarRect;
    const btnW = 180.0;
    const btnH = 48.0;
    final cx = bar.center.dx - btnW / 2;
    final cy = bar.top;

    if (snap.phase == WireMatchPhase.reveal) {
      final enabled = _local?.launchReveal == 'NOT_LAUNCHED';
      final label = enabled ? 'REVEAL' : 'PEEKING...';
      CamoButtonPainter.paint(
        canvas: canvas,
        rect: Rect.fromLTWH(cx, cy, btnW, btnH),
        label: label,
        style: CamoButtonStyle.start,
        enabled: enabled,
        pressed: _pressedId == 'reveal',
      );
    } else if (snap.phase == WireMatchPhase.playing && snap.canAct) {
      CamoButtonPainter.paint(
        canvas: canvas,
        rect: Rect.fromLTWH(cx, cy, btnW, btnH),
        label: 'CALL GAME',
        style: CamoButtonStyle.start,
        pressed: _pressedId == 'call',
      );
    }
  }

  @override
  void onTapUp(TapUpEvent event) {
    final snap = _snapshot;
    final layout = _layout;
    if (snap == null || layout == null) return;

    final localPos = event.localPosition;
    final bar = layout.actionBarRect;
    const btnW = 180.0;
    const btnH = 48.0;
    final rect = Rect.fromLTWH(bar.center.dx - btnW / 2, bar.top, btnW, btnH);
    if (!rect.contains(localPos.toOffset())) return;

    if (snap.phase == WireMatchPhase.reveal &&
        _local?.launchReveal == 'NOT_LAUNCHED') {
      onReveal();
    } else if (snap.phase == WireMatchPhase.playing && snap.canAct) {
      onCallGame();
    }
    _pressedId = null;
  }

  @override
  void onTapDown(TapDownEvent event) {
    final layout = _layout;
    final snap = _snapshot;
    if (layout == null || snap == null) return;

    final bar = layout.actionBarRect;
    const btnW = 180.0;
    const btnH = 48.0;
    final rect = Rect.fromLTWH(bar.center.dx - btnW / 2, bar.top, btnW, btnH);
    if (rect.contains(event.localPosition.toOffset())) {
      _pressedId = snap.phase == WireMatchPhase.reveal ? 'reveal' : 'call';
    }
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    _pressedId = null;
  }
}
