import 'dart:ui';

import 'package:flame/components.dart';
import 'package:game_protocol/game_protocol.dart';

import '../layout/table_layout.dart';
import '../painters/camo_card_painter.dart';
import 'card_component.dart';

typedef HandCardTap = void Function(WireCard card, {required bool fromHand});

class PlayerHandGridComponent extends PositionComponent {
  PlayerHandGridComponent({
    required this.isLocal,
    required this.onCardTap,
  });

  final bool isLocal;
  final HandCardTap onCardTap;

  WirePlayerState? _player;
  bool _canAct = false;
  TableLayout? _layout;

  void apply({
    required WirePlayerState? player,
    required bool canAct,
    required TableLayout layout,
  }) {
    _player = player;
    _canAct = canAct;
    _layout = layout;
    _rebuild();
  }

  bool _faceUp(WireCard card) {
    if (isLocal) {
      return card.isCardShown || card.cardSeen;
    }
    return card.isCardShown || card.isThrown || card.cardSeen;
  }

  void _rebuild() {
    removeAll(children.toList());
    final player = _player;
    final layout = _layout;
    if (player == null || layout == null) return;

    final handRect = isLocal ? layout.localHandRect : layout.remoteHandRect;
    position = Vector2(handRect.left, handRect.top);
    size = Vector2(handRect.width, handRect.height);

    if (player.turn) {
      add(_TurnGradientOverlay(isLocal: isLocal, size: size));
    }

    final cards = isLocal
        ? player.cards
        : player.cards.reversed.toList(growable: false);

    const cols = 2;
    const rows = 2;
    final cellW = handRect.width / cols;
    final cellH = handRect.height / rows;
    final cardW = cellW * 0.92;
    final cardH = cardW * (168 / 140);

    var slot = 0;
    for (final card in cards) {
      if (slot >= cols * rows) break;
      if (card.isThrown) {
        slot++;
        continue;
      }

      final col = slot % cols;
      final row = slot ~/ cols;
      final faceUp = _faceUp(card);

      final sprite = CardComponent(
        tag: card.tag,
        faceUp: faceUp,
        size: Vector2(cardW, cardH),
        onTap: _canAct && isLocal
            ? () => onCardTap(card, fromHand: false)
            : null,
      )
        ..position = Vector2(
          col * cellW + (cellW - cardW) / 2,
          row * cellH + (cellH - cardH) / 2,
        );
      add(sprite);
      slot++;
    }
  }
}

class _TurnGradientOverlay extends PositionComponent {
  _TurnGradientOverlay({required this.isLocal, required Vector2 size})
      : super(size: size);

  final bool isLocal;

  @override
  void render(Canvas canvas) {
    CamoCardPainter.paintTurnGradient(
      canvas: canvas,
      rect: size.toRect(),
      isLocal: isLocal,
    );
  }
}
