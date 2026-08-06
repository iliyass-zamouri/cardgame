import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart';
import 'package:game_protocol/game_protocol.dart';

typedef CardActionCallback = void Function(CardActionMessage action);

class ShadowHandGame extends FlameGame with HasCollisionDetection {
  ShadowHandGame({required this.onAction});

  final CardActionCallback onAction;
  MatchSnapshotMessage? _snapshot;
  late final TableComponent table;

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    table = TableComponent(onAction: onAction);
    await add(table);
  }

  void applySnapshot(MatchSnapshotMessage? snapshot) {
    _snapshot = snapshot;
    table.applySnapshot(snapshot);
  }

  MatchSnapshotMessage? get snapshot => _snapshot;
}

class TableComponent extends PositionComponent with HasGameReference<ShadowHandGame> {
  TableComponent({required this.onAction});

  final CardActionCallback onAction;
  MatchSnapshotMessage? snapshot;
  final List<CardSprite> _sprites = [];

  void applySnapshot(MatchSnapshotMessage? snap) {
    snapshot = snap;
    for (final s in _sprites) {
      s.removeFromParent();
    }
    _sprites.clear();
    if (snap == null) return;

    final local = snap.players.where((p) => p.id == snap.localPlayerId).firstOrNull;
    final remote = snap.players.where((p) => p.id != snap.localPlayerId).firstOrNull;
    final canAct = snap.canAct;

    if (remote != null) {
      _layoutPlayer(remote, y: 40, canAct: false, faceUpDefault: false);
    }
    if (local != null) {
      _layoutPlayer(
        local,
        y: game.size.y - 160,
        canAct: canAct,
        faceUpDefault: true,
        hasHand: local.handCard != null,
        topValue: snap.topDiscardValue,
      );
    }

    final thrown = snap.throwedCards;
    if (thrown.isNotEmpty) {
      final tag = thrown.last;
      final sprite = CardSprite(tag: tag, faceUp: true, onTap: null)
        ..position = Vector2(game.size.x / 2 + 40, game.size.y / 2 - 40);
      _sprites.add(sprite);
      add(sprite);
    }

    final deck = CardSprite(
      tag: 'XX',
      faceUp: false,
      onTap: canAct && local?.handCard == null
          ? () => onAction(const CardActionMessage(type: WireCardActionType.draw))
          : null,
    )..position = Vector2(game.size.x / 2 - 70, game.size.y / 2 - 40);
    _sprites.add(deck);
    add(deck);
  }

  void _layoutPlayer(
    WirePlayerState player, {
    required double y,
    required bool canAct,
    required bool faceUpDefault,
    bool hasHand = false,
    int? topValue,
  }) {
    final startX = (game.size.x - (player.cards.length * 58)) / 2;
    for (var i = 0; i < player.cards.length; i++) {
      final card = player.cards[i];
      if (card.isThrown) continue;
      final faceUp = faceUpDefault || card.isCardShown;
      final sprite = CardSprite(
        tag: card.tag,
        faceUp: faceUp,
        onTap: canAct
            ? () {
                if (hasHand) {
                  onAction(CardActionMessage(
                    type: WireCardActionType.throwCard,
                    cardTag: card.tag,
                    hand: true,
                  ));
                } else {
                  onAction(CardActionMessage(
                    type: WireCardActionType.throwCard,
                    cardTag: card.tag,
                  ));
                }
              }
            : null,
      )..position = Vector2(startX + i * 58, y);
      _sprites.add(sprite);
      add(sprite);
    }

    if (player.handCard != null && player.handCard!.tag != 'XX') {
      final hand = CardSprite(
        tag: player.handCard!.tag,
        faceUp: true,
        onTap: canAct
            ? () => onAction(const CardActionMessage(
                  type: WireCardActionType.throwCard,
                  hand: true,
                ))
            : null,
      )..position = Vector2(game.size.x / 2 - 30, y - 70);
      _sprites.add(hand);
      add(hand);
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    applySnapshot(snapshot);
  }
}

class CardSprite extends PositionComponent with TapCallbacks {
  CardSprite({
    required this.tag,
    required this.faceUp,
    this.onTap,
  }) : super(size: Vector2(52, 78));

  final String tag;
  final bool faceUp;
  final VoidCallback? onTap;

  @override
  void onTapUp(TapUpEvent event) {
    onTap?.call();
  }

  @override
  void render(Canvas canvas) {
    final rect = size.toRect();
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));
    const fillUp = Color(0xFFE8E8E8);
    const fillDown = Color(0xFF315C4A);
    const border = Color(0xFF353438);
    final fill = faceUp ? fillUp : fillDown;
    canvas.drawRRect(rrect, Paint()..color = fill);
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = border,
    );
    if (faceUp && tag != 'XX') {
      final tp = TextPainter(
        text: TextSpan(
          text: _label(tag),
          style: TextStyle(
            color: _suitColor(tag),
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.x);
      tp.paint(canvas, const Offset(6, 6));
    }
  }

  String _label(String tag) {
    if (tag.length < 2) return '?';
    final v = int.tryParse(tag.substring(1)) ?? 0;
    const faces = {1: 'A', 11: 'J', 12: 'Q', 13: 'K'};
    final suit = {'A': '♣', 'B': '♦', 'C': '♥', 'D': '♠'}[tag[0]] ?? '';
    return '${faces[v] ?? v}$suit';
  }

  Color _suitColor(String tag) {
    if (tag.startsWith('B') || tag.startsWith('C')) {
      return const Color(0xFFE74C3C);
    }
    return const Color(0xFF1A1A1E);
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}
