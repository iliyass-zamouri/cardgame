import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:game_protocol/game_protocol.dart';

import '../layout/table_layout.dart';
import 'card_component.dart';

class DeckDiscardRowComponent extends PositionComponent {
  DeckDiscardRowComponent({required this.onDraw});

  final VoidCallback onDraw;

  MatchSnapshotMessage? _snapshot;
  TableLayout? _layout;

  void apply({
    required MatchSnapshotMessage? snapshot,
    required TableLayout layout,
  }) {
    _snapshot = snapshot;
    _layout = layout;
    _rebuild();
  }

  void _rebuild() {
    removeAll(children.toList());
    final snap = _snapshot;
    final layout = _layout;
    if (snap == null || layout == null) return;

    position = Vector2.zero();
    size = layout.size;

    WirePlayerState? localPlayer;
    for (final p in snap.players) {
      if (p.id == snap.localPlayerId) {
        localPlayer = p;
        break;
      }
    }

    final canAct = snap.canAct;
    final hasHand = localPlayer?.handCard != null &&
        localPlayer!.handCard!.tag != 'XX';

    final deckRect = layout.deckRect;
    add(
      CardComponent(
        tag: 'XX',
        faceUp: false,
        size: Vector2(deckRect.width, deckRect.height),
        onTap: canAct && !hasHand ? onDraw : null,
      )..position = Vector2(deckRect.left, deckRect.top),
    );

    final thrown = snap.throwedCards;
    if (thrown.isNotEmpty) {
      final discardRect = layout.discardRect;
      add(
        CardComponent(
          tag: thrown.last,
          faceUp: true,
          size: Vector2(discardRect.width, discardRect.height),
        )..position = Vector2(discardRect.left, discardRect.top),
      );
    }
  }
}
