import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:game_protocol/game_protocol.dart';

import '../layout/table_layout.dart';
import 'card_component.dart';

class CornerHandCardComponent extends PositionComponent {
  CornerHandCardComponent({
    required this.isLocal,
    required this.onTap,
  });

  final bool isLocal;
  final VoidCallback? onTap;

  WireCard? _handCard;
  TableLayout? _layout;
  bool _canAct = false;

  void apply({
    required WireCard? handCard,
    required bool canAct,
    required TableLayout layout,
  }) {
    _handCard = handCard;
    _canAct = canAct;
    _layout = layout;
    _rebuild();
  }

  void _rebuild() {
    removeAll(children.toList());
    final card = _handCard;
    final layout = _layout;
    if (card == null || card.tag == 'XX' || layout == null) return;

    final rect = isLocal ? layout.localHandCardRect : layout.remoteHandCardRect;
    position = Vector2(rect.left, rect.top);
    size = Vector2(rect.width, rect.height);

    add(
      CardComponent(
        tag: card.tag,
        faceUp: isLocal,
        size: size.clone(),
        onTap: isLocal && _canAct ? onTap : null,
      ),
    );
  }
}
