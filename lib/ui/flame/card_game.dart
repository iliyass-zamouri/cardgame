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
  GameSnapshot? _queuedDuringAnimation;
  int _lastVersion = -1;
  bool _ready = false;
  bool _animatingAction = false;

  /// Hand slot this client last tapped. The server only reports public state,
  /// so the tap index is what lets the board animate the right card.
  int? _pendingTapIndex;

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewfinder.anchor = Anchor.topLeft;

    _opponentHand = HandArea(isSelf: false)
      ..position = Vector2(size.x * 0.5, size.y * 0.20);
    _localHand = HandArea(isSelf: true)
      ..position = Vector2(size.x * 0.5, size.y * 0.75);
    _table = TableArea(onDraw: () => onDraw?.call())
      ..position = Vector2(size.x * 0.5, size.y * 0.5);
    _localDrawn = DrawnCardSlot(
      isSelf: true,
      onThrow: () => onThrowHand?.call(),
    )..position = Vector2(size.x * 0.5, size.y - 92);
    _remoteDrawn = DrawnCardSlot(isSelf: false)
      ..position = Vector2(size.x * 0.5, 52);

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
    _opponentHand.position = Vector2(size.x * 0.5, size.y * 0.20);
    _localHand.position = Vector2(size.x * 0.5, size.y * 0.75);
    _table.position = Vector2(size.x * 0.5, size.y * 0.5);
    _localDrawn.position = Vector2(size.x * 0.5, size.y - 92);
    _remoteDrawn.position = Vector2(size.x * 0.5, 52);
    _layoutHands();
  }

  void applySnapshot(GameSnapshot snapshot) {
    if (!_ready) {
      _pending = snapshot;
      return;
    }
    if (_animatingAction) {
      if (_queuedDuringAnimation == null ||
          snapshot.version > _queuedDuringAnimation!.version) {
        _queuedDuringAnimation = snapshot;
      }
      return;
    }
    if (snapshot.version == _lastVersion && _snapshot != null) return;
    final previous = _snapshot;
    final action = previous == null ? null : _planAction(previous, snapshot);

    if (action != null) {
      _lastVersion = snapshot.version;
      _animatingAction = true;
      _runAction(action, () {
        final completedSnapshot = _queuedDuringAnimation ?? snapshot;
        _queuedDuringAnimation = null;
        _animatingAction = false;
        _syncSnapshot(completedSnapshot);
      });
      return;
    }

    _syncSnapshot(snapshot);
  }

  void _syncSnapshot(GameSnapshot snapshot) {
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
      onTap: snapshot.isYourTurn ? _handleHandTap : null,
      animateDeal: previous == null || previous.status != GameStatus.playing,
      peekIndices:
          snapshot.you.launch == LaunchStatus.launched
              ? {
                for (final card in snapshot.you.cards)
                  if (card.visible) card.index,
              }
              : const {},
    );
    _table.sync(
      deckCount: snapshot.deckCount,
      discardTag: snapshot.discardTopTag,
      canDraw:
          snapshot.isYourTurn &&
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

  /// Works out what just happened from the two snapshots plus the card this
  /// client tapped, and captures on-screen positions before the board moves.
  _CardActionPlan? _planAction(GameSnapshot previous, GameSnapshot snapshot) {
    final tapIndex = _pendingTapIndex;
    if (tapIndex == null) return null;

    final drawnTag = previous.you.handCardTag;
    final before = previous.you.cards.length;
    final after = snapshot.you.cards.length;

    // Snapshots unrelated to our own move (an opponent action, a launch timer)
    // must not consume the pending tap.
    if (before == after && drawnTag == snapshot.you.handCardTag) return null;
    _pendingTapIndex = null;

    final handStart = _localHand.worldPositionFor(tapIndex);
    if (handStart == null) return null;
    final discard = _table.worldDiscardPosition;
    final previousDiscardTop = previous.discardTopTag;

    if (drawnTag != null) {
      if (snapshot.you.handCardTag != null) return null;
      final drawnStart =
          _localDrawn.worldCardPosition ?? _table.worldDeckPosition;

      // A hand that shrinks while holding a drawn card can only be a matching
      // pair discard. Exact faces are a bonus when discardRecent is available.
      if (after < before) {
        final discarded = snapshot.discardRecentTags;
        final tappedTag =
            discarded.length >= 2 && discarded.last == drawnTag
                ? discarded.first
                : null;
        return _CardActionPlan(
          kind: _CardActionKind.doubleDiscard,
          cardIndex: tapIndex,
          tappedTag: tappedTag,
          drawnTag: drawnTag,
          handStart: handStart,
          drawnStart: drawnStart,
          discard: discard,
          previousDiscardTop: previousDiscardTop,
        );
      }
      final swapped = snapshot.discardTopTag;
      if (swapped == null) return null;
      return _CardActionPlan(
        kind: _CardActionKind.swap,
        cardIndex: tapIndex,
        tappedTag: swapped,
        drawnTag: drawnTag,
        handStart: handStart,
        drawnStart: drawnStart,
        discard: discard,
        previousDiscardTop: previousDiscardTop,
      );
    }

    // Tapping a hand card with no drawn card: it either matches the pile top
    // and is discarded, or the miss costs a penalty card from the deck.
    // A collapsed draw-plus-tap frame can also look like this; two new discard
    // cards mean it was actually a double discard.
    if (after < before) {
      final discarded = snapshot.discardRecentTags;
      if (discarded.length >= 2 && discarded.first != previous.discardTopTag) {
        return _CardActionPlan(
          kind: _CardActionKind.doubleDiscard,
          cardIndex: tapIndex,
          tappedTag: discarded.first,
          drawnTag: discarded.last,
          handStart: handStart,
          drawnStart: _table.worldDeckPosition,
          discard: discard,
          previousDiscardTop: previousDiscardTop,
        );
      }
      final matched = snapshot.discardTopTag;
      if (matched == null) return null;
      return _CardActionPlan(
        kind: _CardActionKind.discardMatch,
        cardIndex: tapIndex,
        tappedTag: matched,
        handStart: handStart,
        discard: discard,
        previousDiscardTop: previousDiscardTop,
      );
    }
    if (after > before) {
      return _CardActionPlan(
        kind: _CardActionKind.penaltyDraw,
        cardIndex: tapIndex,
        handStart: handStart,
        discard: discard,
        deckStart: _table.worldDeckPosition,
        handOrigin: _localHand.worldOrigin,
        previousDiscardTop: previousDiscardTop,
      );
    }
    return null;
  }

  void _runAction(_CardActionPlan plan, VoidCallback onComplete) {
    _clearActionOverlays();
    switch (plan.kind) {
      case _CardActionKind.doubleDiscard:
        _runDoubleDiscard(plan, onComplete);
      case _CardActionKind.swap:
        _runSwap(plan, onComplete);
      case _CardActionKind.discardMatch:
        _runDiscardMatch(plan, onComplete);
      case _CardActionKind.penaltyDraw:
        _runPenaltyDraw(plan, onComplete);
    }
  }

  void _handleHandTap(int cardIndex) {
    _pendingTapIndex = cardIndex;
    onTapCard?.call(cardIndex);
  }

  void _clearActionOverlays() {
    _table.releaseDiscard();
    for (final card in _localHand.cards) {
      if (card.opacityOverride < 1) card.opacityOverride = 1;
    }
    _localDrawn.setCardOpacity(1);
  }

  // Shared timing for the action animations, mirroring the reveal: cards lift
  // toward the player, sit enlarged long enough to read, then travel.
  static const _liftDuration = 0.26;
  static const _readDuration = 0.6;
  static const _travelDuration = 0.5;
  static const _peekScale = 1.35;
  static const _liftForward = 60.0;

  void _runDoubleDiscard(_CardActionPlan plan, VoidCallback onComplete) {
    const phaseA = _liftDuration + _readDuration + _travelDuration;
    final tappedTag = plan.tappedTag;
    final drawnTag = plan.drawnTag!;
    final pileRevealTag = tappedTag ?? drawnTag;

    _localHand.cardAt(plan.cardIndex)?.opacityOverride = 0;
    _localDrawn.setCardOpacity(0);
    _table.holdDiscard(plan.previousDiscardTop, pendingTag: pileRevealTag);

    // Phase A: tapped hand card lifts, flips when known, holds, then travels.
    final thrown = _ghostCard(tappedTag, plan.handStart, faceUp: false);
    world.add(thrown);
    if (tappedTag != null) {
      thrown.flipTo(tag: tappedTag, visible: true, delay: 0.1, duration: 0.2);
    }
    thrown.add(
      SequenceEffect([
        MoveEffect.to(
          plan.handStart - Vector2(0, _liftForward),
          EffectController(duration: _liftDuration, curve: Curves.easeOutBack),
        ),
        _PauseEffect(_readDuration),
        MoveEffect.to(
          plan.discard,
          EffectController(
            duration: _travelDuration,
            curve: Curves.easeInOutCubic,
          ),
        ),
        _CallbackEffect(() {
          _table.releaseDiscard();
          _table.holdDiscard(pileRevealTag, pendingTag: drawnTag);
        }),
        RemoveEffect(),
      ]),
    );
    thrown.add(
      SequenceEffect([
        ScaleEffect.to(
          Vector2.all(_peekScale),
          EffectController(duration: _liftDuration, curve: Curves.easeOutBack),
        ),
        _PauseEffect(_readDuration),
        ScaleEffect.to(
          Vector2.all(0.85),
          EffectController(
            duration: _travelDuration,
            curve: Curves.easeInOutCubic,
          ),
        ),
      ]),
    );

    // Phase B: drawn card travels straight onto the discard pile.
    final drawn = _ghostCard(drawnTag, plan.drawnStart!, faceUp: true);
    world.add(drawn);
    drawn.add(
      SequenceEffect([
        _PauseEffect(phaseA),
        MoveEffect.to(
          plan.discard,
          EffectController(
            duration: _travelDuration,
            curve: Curves.easeInOutCubic,
          ),
        ),
        _CallbackEffect(() {
          _table.releaseDiscard();
          onComplete();
        }),
        RemoveEffect(),
      ]),
    );
    drawn.add(
      SequenceEffect([
        _PauseEffect(phaseA),
        ScaleEffect.to(
          Vector2.all(0.85),
          EffectController(
            duration: _travelDuration,
            curve: Curves.easeInOutCubic,
          ),
        ),
      ]),
    );
  }

  /// Tapped card matched the discard top: lift it, reveal it, send it away.
  void _runDiscardMatch(_CardActionPlan plan, VoidCallback onComplete) {
    final tapped = plan.tappedTag!;
    _localHand.cardAt(plan.cardIndex)?.opacityOverride = 0;
    _table.holdDiscard(plan.previousDiscardTop, pendingTag: tapped);

    final card = _ghostCard(tapped, plan.handStart, faceUp: false);
    world.add(card);
    card.flipTo(tag: tapped, visible: true, delay: 0.1, duration: 0.2);
    card.add(
      SequenceEffect([
        MoveEffect.to(
          plan.handStart - Vector2(0, _liftForward),
          EffectController(duration: _liftDuration, curve: Curves.easeOutBack),
        ),
        _PauseEffect(_readDuration),
        MoveEffect.to(
          plan.discard,
          EffectController(
            duration: _travelDuration,
            curve: Curves.easeInOutCubic,
          ),
        ),
        _CallbackEffect(() {
          _table.releaseDiscard();
          onComplete();
        }),
        RemoveEffect(),
      ]),
    );
    card.add(
      SequenceEffect([
        ScaleEffect.to(
          Vector2.all(_peekScale),
          EffectController(duration: _liftDuration, curve: Curves.easeOutBack),
        ),
        _PauseEffect(_readDuration),
        ScaleEffect.to(
          Vector2.all(0.85),
          EffectController(
            duration: _travelDuration,
            curve: Curves.easeInOutCubic,
          ),
        ),
      ]),
    );
  }

  /// Tapped card did not match: the hand shakes and takes a card from the deck.
  void _runPenaltyDraw(_CardActionPlan plan, VoidCallback onComplete) {
    const shake = 0.07;
    final tapped = _localHand.cardAt(plan.cardIndex);
    tapped?.add(
      SequenceEffect([
        MoveEffect.by(
          Vector2(10, 0),
          EffectController(duration: shake, curve: Curves.easeOut),
        ),
        MoveEffect.by(
          Vector2(-20, 0),
          EffectController(duration: shake * 2, curve: Curves.easeInOut),
        ),
        MoveEffect.by(
          Vector2(10, 0),
          EffectController(duration: shake, curve: Curves.easeIn),
        ),
      ]),
    );

    final penalty = _ghostCard(null, plan.deckStart!, faceUp: false);
    world.add(penalty);
    penalty.add(
      SequenceEffect([
        _PauseEffect(shake * 4),
        MoveEffect.to(
          plan.handOrigin!,
          EffectController(
            duration: _travelDuration,
            curve: Curves.easeInOutCubic,
          ),
        ),
        _CallbackEffect(onComplete),
        RemoveEffect(),
      ]),
    );
  }

  void _runSwap(_CardActionPlan plan, VoidCallback onComplete) {
    const phaseA = _liftDuration + _readDuration + _travelDuration;
    final landing = _localHand.cardAt(plan.cardIndex);
    landing?.opacityOverride = 0;
    _table.holdDiscard(plan.previousDiscardTop, pendingTag: plan.tappedTag!);

    // Phase A: tapped card lifts out of the hand and flips face-up in place,
    // holds so it can be read, then travels to the discard pile.
    final thrown = _ghostCard(plan.tappedTag!, plan.handStart, faceUp: false);
    world.add(thrown);
    thrown.flipTo(
      tag: plan.tappedTag!,
      visible: true,
      delay: 0.1,
      duration: 0.2,
    );
    thrown.add(
      SequenceEffect([
        MoveEffect.to(
          plan.handStart - Vector2(0, _liftForward),
          EffectController(duration: _liftDuration, curve: Curves.easeOutBack),
        ),
        _PauseEffect(_readDuration),
        MoveEffect.to(
          plan.discard,
          EffectController(
            duration: _travelDuration,
            curve: Curves.easeInOutCubic,
          ),
        ),
        _CallbackEffect(_table.releaseDiscard),
        RemoveEffect(),
      ]),
    );
    thrown.add(
      SequenceEffect([
        ScaleEffect.to(
          Vector2.all(_peekScale),
          EffectController(duration: _liftDuration, curve: Curves.easeOutBack),
        ),
        _PauseEffect(_readDuration),
        ScaleEffect.to(
          Vector2.all(0.85),
          EffectController(
            duration: _travelDuration,
            curve: Curves.easeInOutCubic,
          ),
        ),
      ]),
    );

    // Phase B: drawn card travels straight into the vacated slot.
    final placed = _ghostCard(plan.drawnTag!, plan.drawnStart!, faceUp: true);
    world.add(placed);
    placed.add(
      SequenceEffect([
        _PauseEffect(phaseA),
        _CallbackEffect(() => _localDrawn.setCardOpacity(0)),
        MoveEffect.to(
          plan.handStart,
          EffectController(
            duration: _travelDuration,
            curve: Curves.easeInOutCubic,
          ),
        ),
        _CallbackEffect(() {
          landing?.opacityOverride = 1;
          onComplete();
        }),
        RemoveEffect(),
      ]),
    );
    placed.add(
      SequenceEffect([
        _PauseEffect(phaseA),
        ScaleEffect.to(
          Vector2.all(1),
          EffectController(
            duration: _travelDuration,
            curve: Curves.easeInOutCubic,
          ),
        ),
      ]),
    );
  }

  PlayingCardComponent _ghostCard(
    String? tag,
    Vector2 start, {
    required bool faceUp,
  }) {
    return PlayingCardComponent(
        cardIndex: -20,
        tag: faceUp ? tag : null,
        visible: faceUp,
        sizeOverride: Vector2(86, 124),
      )
      ..position = start
      ..priority = 100;
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

  List<PlayingCardComponent> get cards => List.unmodifiable(_cards);

  Vector2 get worldOrigin => absolutePositionOfAnchor(Anchor.topLeft);

  PlayingCardComponent? cardAt(int cardIndex) {
    for (final card in _cards) {
      if (card.cardIndex == cardIndex) return card;
    }
    return null;
  }

  Vector2? worldPositionFor(int cardIndex) =>
      cardAt(cardIndex)?.absolutePositionOfAnchor(Anchor.center);

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
        final card =
            PlayingCardComponent(
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
  String? _discardHoldTag;
  bool _holdingDiscard = false;
  String? _pendingDiscardTag;

  Vector2 get worldDiscardPosition =>
      _discard.absolutePositionOfAnchor(Anchor.center);

  Vector2 get worldDeckPosition =>
      _deck.absolutePositionOfAnchor(Anchor.center);

  void holdDiscard(String? tag, {required String pendingTag}) {
    _holdingDiscard = true;
    _discardHoldTag = tag;
    _pendingDiscardTag = pendingTag;
    _applyDiscard(_discardHoldTag, animate: false);
  }

  void releaseDiscard() {
    if (!_holdingDiscard) return;
    _holdingDiscard = false;
    final tag = _pendingDiscardTag ?? _discardHoldTag;
    _discardHoldTag = null;
    _applyDiscard(tag, animate: true);
  }

  void sync({
    required int deckCount,
    required String? discardTag,
    required bool canDraw,
  }) {
    _showDeck = deckCount > 0;
    _deck.opacityOverride = _showDeck ? 1 : 0;
    _deck.highlighted = canDraw && _showDeck;
    _deck.onPressed = canDraw && _showDeck ? onDraw : null;
    _pendingDiscardTag = discardTag;
    if (_holdingDiscard) {
      _applyDiscard(_discardHoldTag, animate: false);
      return;
    }
    _applyDiscard(discardTag, animate: true);
  }

  void _applyDiscard(String? discardTag, {required bool animate}) {
    final previous = _discard.tag;
    _discard.updateFromSnapshot(
      CardSnapshot(index: -2, tag: discardTag, visible: discardTag != null),
      tappable: false,
    );
    if (animate && discardTag != null && discardTag != previous) {
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

  Vector2? get worldCardPosition =>
      _card?.absolutePositionOfAnchor(Anchor.center);

  void setCardOpacity(double opacity) {
    _card?.opacityOverride = opacity;
  }

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
  }) : _tag = tag,
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

  void flipTo({
    required String? tag,
    required bool visible,
    double delay = 0,
    double duration = 0.12,
  }) {
    final effects = <Effect>[
      if (delay > 0) _PauseEffect(delay),
      _FlipEffect(to: 0, duration: duration),
      _CallbackEffect(() {
        _tag = tag;
        _visible = visible;
      }),
      _FlipEffect(to: 1, duration: duration),
    ];
    add(SequenceEffect(effects));
  }

  void updateFromSnapshot(CardSnapshot snapshot, {required bool tappable}) {
    final faceChanged = _visible != snapshot.visible || _tag != snapshot.tag;
    _tappable = tappable;
    if (faceChanged) {
      flipTo(tag: snapshot.tag, visible: snapshot.visible);
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

    final shadow =
        Paint()
          ..color = const Color(0x66000000)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRRect(rect.shift(const Offset(0, 3)), shadow);

    final faceUp = _visible && _tag != null && _flip >= 0;
    final fill =
        Paint()
          ..color = faceUp ? const Color(0xFFFFFDF7) : const Color(0xFF1B5E20);
    canvas.drawRRect(rect, fill);

    final border =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = highlighted ? 3 : 1.5
          ..color =
              highlighted ? const Color(0xFFFFD54F) : const Color(0xFF263238);
    canvas.drawRRect(rect, border);

    if (!faceUp) {
      final inset = rect.deflate(6);
      final pattern =
          Paint()
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
      Offset(left + (width - suit.width) / 2, (size.y - suit.height) / 2),
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

enum _CardActionKind { doubleDiscard, swap, discardMatch, penaltyDraw }

class _CardActionPlan {
  const _CardActionPlan({
    required this.kind,
    required this.cardIndex,
    required this.handStart,
    required this.discard,
    required this.previousDiscardTop,
    this.tappedTag,
    this.drawnTag,
    this.drawnStart,
    this.deckStart,
    this.handOrigin,
  });

  final _CardActionKind kind;
  final int cardIndex;
  final Vector2 handStart;
  final Vector2 discard;
  final String? previousDiscardTop;
  final String? tappedTag;
  final String? drawnTag;
  final Vector2? drawnStart;
  final Vector2? deckStart;
  final Vector2? handOrigin;
}

class _PauseEffect extends Effect {
  _PauseEffect(double duration) : super(EffectController(duration: duration));

  @override
  void apply(double progress) {}
}
