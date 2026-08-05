import 'dart:math' as math;
import 'dart:ui';

import 'package:cardgame/domain/models/game_snapshot.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

typedef CardTapCallback = void Function(int cardIndex);
typedef VoidGameCallback = void Function();

class CardGame extends FlameGame {
  CardTapCallback? onTapCard;
  VoidGameCallback? onDraw;
  VoidGameCallback? onThrowHand;

  late final HandArea _opponentHand;
  late final HandArea _localHand;
  late final TableArea _table;
  late final DrawnCardSlot _localDrawn;
  late final DrawnCardSlot _remoteDrawn;

  GameSnapshot? _snapshot;
  GameSnapshot? _pending;
  int _lastVersion = -1;
  bool _ready = false;

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewfinder.anchor = Anchor.topLeft;

    _opponentHand = HandArea(isSelf: false)
      ..position = Vector2(size.x * 0.5, size.y * 0.18);
    _localHand = HandArea(isSelf: true)
      ..position = Vector2(size.x * 0.5, size.y * 0.82);
    _table = TableArea(
      onDraw: () => onDraw?.call(),
    )..position = Vector2(size.x * 0.5, size.y * 0.5);
    _localDrawn = DrawnCardSlot(isSelf: true, onThrow: () => onThrowHand?.call())
      ..position = Vector2(72, size.y - 96);
    _remoteDrawn = DrawnCardSlot(isSelf: false)
      ..position = Vector2(56, 56);

    world.addAll([
      _opponentHand,
      _localHand,
      _table,
      _localDrawn,
      _remoteDrawn,
    ]);

    _ready = true;
    final pending = _pending;
    _pending = null;
    if (pending != null) applySnapshot(pending);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (!_ready) return;
    _opponentHand.position = Vector2(size.x * 0.5, size.y * 0.18);
    _localHand.position = Vector2(size.x * 0.5, size.y * 0.82);
    _table.position = Vector2(size.x * 0.5, size.y * 0.5);
    _localDrawn.position = Vector2(72, size.y - 96);
    _remoteDrawn.position = Vector2(56, 56);
    _layoutHands();
  }

  void applySnapshot(GameSnapshot snapshot) {
    if (!_ready) {
      _pending = snapshot;
      return;
    }
    if (snapshot.version == _lastVersion && _snapshot != null) return;
    final previous = _snapshot;
    _snapshot = snapshot;
    _lastVersion = snapshot.version;

    _opponentHand.syncCards(
      snapshot.opponent?.cards ?? const [],
      highlight: !snapshot.isYourTurn,
      onTap: null,
      animateDeal: previous == null || previous.version > snapshot.version,
      peekIndices: const {},
    );
    _localHand.syncCards(
      snapshot.you.cards,
      highlight: snapshot.isYourTurn,
      onTap: snapshot.isYourTurn ? onTapCard : null,
      animateDeal: previous == null || previous.status != GameStatus.playing,
      peekIndices: snapshot.you.launch == LaunchStatus.launched
          ? {
              for (final card in snapshot.you.cards)
                if (card.visible) card.index,
            }
          : const {},
    );
    _table.sync(
      deckCount: snapshot.deckCount,
      discardTag: snapshot.discardTopTag,
      canDraw: snapshot.isYourTurn &&
          snapshot.you.handCardTag == null &&
          snapshot.status == GameStatus.playing &&
          snapshot.bothRevealed,
    );
    _localDrawn.sync(snapshot.you.handCardTag, faceUp: true);
    _remoteDrawn.sync(
      snapshot.opponent?.hasHandCard == true ? 'BACK' : null,
      faceUp: false,
    );
    _layoutHands();
  }

  void _layoutHands() {
    _opponentHand.layout();
    _localHand.layout();
  }
}

class HandArea extends PositionComponent {
  HandArea({required this.isSelf});

  final bool isSelf;
  final List<PlayingCardComponent> _cards = [];

  void syncCards(
    List<CardSnapshot> cards, {
    required bool highlight,
    required CardTapCallback? onTap,
    required bool animateDeal,
    required Set<int> peekIndices,
  }) {
    final keep = <PlayingCardComponent>[];
    for (final snapshot in cards) {
      PlayingCardComponent? existing;
      for (final card in _cards) {
        if (card.cardIndex == snapshot.index) {
          existing = card;
          break;
        }
      }
      if (existing != null) {
        existing.updateFromSnapshot(snapshot, tappable: onTap != null);
        existing.onTap = onTap;
        existing.highlighted = highlight;
        existing.peeking = peekIndices.contains(snapshot.index);
        keep.add(existing);
      } else {
        final card = PlayingCardComponent(
          cardIndex: snapshot.index,
          tag: snapshot.tag,
          visible: snapshot.visible,
          onTap: onTap,
        )
          ..highlighted = highlight
          ..peeking = peekIndices.contains(snapshot.index);
        if (animateDeal) {
          card.scale = Vector2.zero();
          card.add(
            ScaleEffect.to(
              Vector2.all(1),
              EffectController(duration: 0.28, curve: Curves.easeOutBack),
            ),
          );
        }
        add(card);
        keep.add(card);
      }
    }

    for (final card in List<PlayingCardComponent>.from(_cards)) {
      if (!keep.contains(card)) {
        card.add(
          SequenceEffect([
            ScaleEffect.to(
              Vector2.zero(),
              EffectController(duration: 0.18, curve: Curves.easeIn),
            ),
            RemoveEffect(),
          ]),
        );
      }
    }
    _cards
      ..clear()
      ..addAll(keep);
    layout();
  }

  void layout() {
    if (_cards.isEmpty) return;
    const cardWidth = 78.0;
    const gap = 14.0;
    const peekScale = 1.18;
    const peekForward = 34.0;

    final totalWidth = _cards.length * cardWidth + (_cards.length - 1) * gap;
    final peeking = _cards.where((card) => card.peeking).toList();
    final peekWidth = cardWidth * peekScale;
    final peekSpan = peeking.length * peekWidth;
    var peekX = -peekSpan / 2 + peekWidth / 2;
    var slotX = -totalWidth / 2 + cardWidth / 2;

    for (final card in _cards) {
      final Vector2 target;
      if (card.peeking) {
        target = Vector2(peekX, isSelf ? peekForward : -peekForward);
        peekX += peekWidth;
      } else {
        target = Vector2(slotX, 0);
      }
      card.priority = card.peeking ? 10 : 0;
      card.moveTo(target);
      card.scaleTo(card.peeking ? peekScale : 1);
      slotX += cardWidth + gap;
    }
  }
}

class TableArea extends PositionComponent {
  TableArea({required this.onDraw});

  final VoidCallback onDraw;
  final PlayingCardComponent _deck = PlayingCardComponent(
    cardIndex: -1,
    tag: null,
    visible: false,
    sizeOverride: Vector2(86, 124),
  )..position = Vector2(-70, 0);
  final PlayingCardComponent _discard = PlayingCardComponent(
    cardIndex: -2,
    tag: null,
    visible: true,
    sizeOverride: Vector2(86, 124),
  )..position = Vector2(70, 0);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    addAll([_deck, _discard]);
  }

  bool _showDeck = true;

  void sync({
    required int deckCount,
    required String? discardTag,
    required bool canDraw,
  }) {
    _showDeck = deckCount > 0;
    _deck.opacityOverride = _showDeck ? 1 : 0;
    _deck.highlighted = canDraw && _showDeck;
    _deck.onPressed = canDraw && _showDeck ? onDraw : null;
    final previous = _discard.tag;
    _discard.updateFromSnapshot(
      CardSnapshot(index: -2, tag: discardTag, visible: discardTag != null),
      tappable: false,
    );
    if (discardTag != null && discardTag != previous) {
      _discard.scale = Vector2.all(0.7);
      _discard.add(
        ScaleEffect.to(
          Vector2.all(1),
          EffectController(duration: 0.2, curve: Curves.easeOutBack),
        ),
      );
    }
  }
}

class DrawnCardSlot extends PositionComponent {
  DrawnCardSlot({required this.isSelf, this.onThrow});

  final bool isSelf;
  final VoidCallback? onThrow;
  PlayingCardComponent? _card;

  void sync(String? tag, {required bool faceUp}) {
    if (tag == null) {
      _card?.removeFromParent();
      _card = null;
      return;
    }
    final visibleTag = tag == 'BACK' ? null : tag;
    if (_card == null) {
      _card = PlayingCardComponent(
        cardIndex: isSelf ? -10 : -11,
        tag: visibleTag,
        visible: faceUp && visibleTag != null,
        sizeOverride: Vector2(isSelf ? 86 : 48, isSelf ? 124 : 70),
      )..onPressed = isSelf ? () => onThrow?.call() : null;
      add(_card!);
      _card!
        ..scale = Vector2.zero()
        ..add(
          ScaleEffect.to(
            Vector2.all(1),
            EffectController(duration: 0.25, curve: Curves.easeOutBack),
          ),
        );
    } else {
      _card!.updateFromSnapshot(
        CardSnapshot(
          index: _card!.cardIndex,
          tag: visibleTag,
          visible: faceUp && visibleTag != null,
        ),
        tappable: isSelf,
      );
    }
  }
}

class PlayingCardComponent extends PositionComponent with TapCallbacks {
  PlayingCardComponent({
    required this.cardIndex,
    required String? tag,
    required bool visible,
    this.onTap,
    Vector2? sizeOverride,
  })  : _tag = tag,
        _visible = visible {
    size = sizeOverride ?? Vector2(78, 112);
    anchor = Anchor.center;
  }

  final int cardIndex;
  String? _tag;
  bool _visible;
  bool highlighted = false;
  bool peeking = false;
  bool _tappable = false;
  CardTapCallback? onTap;
  VoidCallback? onPressed;
  double _flip = 1;
  double opacityOverride = 1;
  Vector2? _targetPosition;
  double _targetScale = 1;

  String? get tag => _tag;

  void moveTo(Vector2 target) {
    if (_targetPosition != null && (_targetPosition! - target).length < 0.5) {
      return;
    }
    _targetPosition = target.clone();
    if ((position - target).length <= 1) {
      position = target;
      return;
    }
    for (final effect in children.whereType<MoveEffect>().toList()) {
      effect.removeFromParent();
    }
    add(
      MoveEffect.to(
        target,
        EffectController(duration: 0.26, curve: Curves.easeOutCubic),
      ),
    );
  }

  void scaleTo(double value) {
    if ((_targetScale - value).abs() < 0.01) return;
    _targetScale = value;
    add(
      ScaleEffect.to(
        Vector2.all(value),
        EffectController(duration: 0.26, curve: Curves.easeOutBack),
      ),
    );
  }

  void updateFromSnapshot(CardSnapshot snapshot, {required bool tappable}) {
    final faceChanged = _visible != snapshot.visible || _tag != snapshot.tag;
    _tappable = tappable;
    if (faceChanged) {
      add(
        SequenceEffect([
          _FlipEffect(to: 0, duration: 0.12),
          _CallbackEffect(() {
            _tag = snapshot.tag;
            _visible = snapshot.visible;
          }),
          _FlipEffect(to: 1, duration: 0.12),
        ]),
      );
    } else {
      _tag = snapshot.tag;
      _visible = snapshot.visible;
    }
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (onPressed != null) {
      _bounce();
      onPressed!();
      return;
    }
    if (!_tappable || onTap == null || cardIndex < 0) return;
    _bounce();
    onTap!(cardIndex);
  }

  void _bounce() {
    add(
      SequenceEffect([
        ScaleEffect.to(
          Vector2.all(_targetScale * 0.94),
          EffectController(duration: 0.07),
        ),
        ScaleEffect.to(
          Vector2.all(_targetScale),
          EffectController(duration: 0.07),
        ),
      ]),
    );
  }

  @override
  void render(Canvas canvas) {
    if (opacityOverride <= 0) return;
    canvas.saveLayer(
      Offset.zero & Size(size.x, size.y),
      Paint()..color = Color.fromRGBO(255, 255, 255, opacityOverride),
    );
    final width = size.x * _flip.abs().clamp(0.08, 1);
    final left = (size.x - width) / 2;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, 0, width, size.y),
      const Radius.circular(8),
    );

    final shadow = Paint()
      ..color = const Color(0x66000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRRect(rect.shift(const Offset(0, 3)), shadow);

    final faceUp = _visible && _tag != null && _flip >= 0;
    final fill = Paint()
      ..color = faceUp ? const Color(0xFFFFFDF7) : const Color(0xFF1B5E20);
    canvas.drawRRect(rect, fill);

    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = highlighted ? 3 : 1.5
      ..color = highlighted ? const Color(0xFFFFD54F) : const Color(0xFF263238);
    canvas.drawRRect(rect, border);

    if (!faceUp) {
      final inset = rect.deflate(6);
      final pattern = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = const Color(0xFF81C784);
      for (var i = -size.y; i < size.x + size.y; i += 10) {
        canvas.drawLine(
          Offset(inset.left + i, inset.top),
          Offset(inset.left + i + size.y, inset.bottom),
          pattern,
        );
      }
      canvas.restore();
      return;
    }

    final meta = _CardMeta.fromTag(_tag!);
    final textStyle = TextStyle(
      color: meta.color,
      fontSize: size.x * 0.28,
      fontWeight: FontWeight.w700,
      height: 1,
    );
    final rank = TextPainter(
      text: TextSpan(text: meta.rank, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    final suit = TextPainter(
      text: TextSpan(
        text: meta.suit,
        style: textStyle.copyWith(fontSize: size.x * 0.34),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    rank.paint(canvas, Offset(left + 6, 6));
    suit.paint(
      canvas,
      Offset(
        left + (width - suit.width) / 2,
        (size.y - suit.height) / 2,
      ),
    );
    canvas.save();
    canvas.translate(left + width - 6, size.y - 6);
    canvas.rotate(math.pi);
    rank.paint(canvas, Offset.zero);
    canvas.restore();
    canvas.restore();
  }
}

class _CardMeta {
  const _CardMeta(this.rank, this.suit, this.color);

  final String rank;
  final String suit;
  final Color color;

  factory _CardMeta.fromTag(String tag) {
    final suitCode = tag[0];
    final value = int.parse(tag.substring(1));
    final red = suitCode == 'B' || suitCode == 'C';
    final suit = switch (suitCode) {
      'A' => '♣',
      'B' => '♦',
      'C' => '♥',
      'D' => '♠',
      _ => '?',
    };
    final rank = switch (value) {
      1 => 'A',
      11 => 'J',
      12 => 'Q',
      13 => 'K',
      14 => '★',
      _ => '$value',
    };
    return _CardMeta(
      rank,
      suit,
      red ? const Color(0xFFC62828) : const Color(0xFF212121),
    );
  }
}

class _FlipEffect extends Effect {
  _FlipEffect({required this.to, required double duration})
      : super(EffectController(duration: duration));

  final double to;
  late double _from;

  @override
  void onStart() {
    final target = parent;
    if (target is PlayingCardComponent) {
      _from = target._flip;
    }
  }

  @override
  void apply(double progress) {
    final target = parent;
    if (target is PlayingCardComponent) {
      target._flip = lerpDouble(_from, to, progress)!;
    }
  }
}

class _CallbackEffect extends Effect {
  _CallbackEffect(this.callback) : super(EffectController(duration: 0));

  final VoidCallback callback;
  bool _ran = false;

  @override
  void apply(double progress) {
    if (_ran) return;
    _ran = true;
    callback();
  }
}
