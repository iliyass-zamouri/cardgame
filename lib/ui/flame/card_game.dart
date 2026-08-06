import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:cardgame/domain/models/game_snapshot.dart';
import 'package:cardgame/ui/flame/suit_shapes.dart';
import 'package:cardgame/ui/flame/court_svg_art.dart';
import 'package:cardgame/ui/flame/joker_svg_art.dart';
import 'package:cardgame/ui/flame/card_back_skins.dart';
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

  /// Back skin applied to every face-down card. Cached art is keyed by skin id,
  /// so a change shows up on the next frame.
  String get cardBackSkinId => CardBackSkins.activeId;

  set cardBackSkinId(String id) => CardBackSkins.select(id);

  GameSnapshot? _snapshot;
  GameSnapshot? _pending;
  GameSnapshot? _queuedDuringAnimation;
  int _lastVersion = -1;
  bool _ready = false;
  bool _animatingAction = false;

  /// Hand slot this client last tapped. The server only reports public state,
  /// so the tap index is what lets the board animate the right card.
  int? _pendingTapIndex;
  bool _expectingPenaltyAppend = false;

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewfinder.anchor = Anchor.topLeft;

    _opponentHand = HandArea(isSelf: false)
      ..position = Vector2(size.x * 0.5, size.y * 0.25);
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
    _opponentHand.position = Vector2(size.x * 0.5, size.y * 0.25);
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
    final snapIndices = <int>{};
    if (_expectingPenaltyAppend &&
        previous != null &&
        snapshot.you.cards.length == previous.you.cards.length + 1 &&
        snapshot.you.cards.isNotEmpty) {
      snapIndices.add(snapshot.you.cards.last.index);
    }
    _expectingPenaltyAppend = false;

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
      snapToPositionIndices: snapIndices,
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
      // Reflow now so the ghost lands where the new end card will sit.
      _localHand.layout(projectedCount: after);
      return _CardActionPlan(
        kind: _CardActionKind.penaltyDraw,
        cardIndex: tapIndex,
        handStart: handStart,
        discard: discard,
        deckStart: _table.worldDeckPosition,
        handOrigin: _localHand.worldSlotCenter(after - 1, count: after),
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
    final hidden = _localHand.cardAt(plan.cardIndex);
    hidden?.opacityOverride = 0;
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

  /// Tapped card did not match: the hand shakes and takes a card from the deck
  /// into the end slot (always appended).
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

    final landing = plan.handOrigin!;
    final penalty = _ghostCard(null, plan.deckStart!, faceUp: false);
    _expectingPenaltyAppend = true;
    world.add(penalty);
    penalty.add(
      SequenceEffect([
        _PauseEffect(shake * 4),
        MoveEffect.to(
          landing,
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

  static const cardsPerRow = 4;
  static const cardWidth = 78.0;
  static const cardHeight = 112.0;
  static const gapX = 14.0;
  static const gapY = 16.0;

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

  /// World centre of hand slot [index] when the hand holds [count] cards.
  Vector2 worldSlotCenter(int index, {required int count}) =>
      absolutePositionOf(_slotCenter(index, count));

  /// Local centre for slot [index] in a hand of [count] cards (4 per row).
  ///
  /// Local hand grows down (away from deck). Opponent hand is mirrored:
  /// first row sits near the deck, later / penalty rows grow up toward the
  /// top of the screen.
  Vector2 _slotCenter(int index, int count) {
    assert(count > 0 && index >= 0 && index < count);
    final row = index ~/ cardsPerRow;
    final colInRow = index % cardsPerRow;
    final cardsInRow = math.min(cardsPerRow, count - row * cardsPerRow);
    // Mirror left/right across the table for the opponent.
    final col = isSelf ? colInRow : cardsInRow - 1 - colInRow;
    final rowWidth = cardsInRow * cardWidth + (cardsInRow - 1) * gapX;
    final x = -rowWidth / 2 + cardWidth / 2 + col * (cardWidth + gapX);
    final rowSign = isSelf ? 1.0 : -1.0;
    final y = rowSign * row * (cardHeight + gapY);
    return Vector2(x, y);
  }

  void syncCards(
    List<CardSnapshot> cards, {
    required bool highlight,
    required CardTapCallback? onTap,
    required bool animateDeal,
    Set<int> snapToPositionIndices = const {},
    required Set<int> peekIndices,
  }) {
    final keep = <PlayingCardComponent>[];
    final used = <PlayingCardComponent>{};
    PlayingCardComponent? takeNextUnused() {
      for (final card in _cards) {
        if (used.contains(card)) continue;
        // Discard animations hide the leaving card with opacity 0. Never reuse
        // that shell for a surviving slot or a neighbor goes invisible.
        if (card.opacityOverride < 1) continue;
        return card;
      }
      return null;
    }

    for (final snapshot in cards) {
      PlayingCardComponent? existing;
      if (snapshot.tag != null) {
        for (final card in _cards) {
          if (used.contains(card)) continue;
          if (card.opacityOverride < 1) continue;
          if (card.tag == snapshot.tag) {
            existing = card;
            break;
          }
        }
      }
      existing ??= takeNextUnused();
      if (existing != null) {
        used.add(existing);
        existing.updateFromSnapshot(snapshot, tappable: onTap != null);
        existing.onTap = onTap;
        existing.highlighted = highlight;
        existing.peeking = peekIndices.contains(snapshot.index);
        existing.opacityOverride = 1;
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
        if (snapToPositionIndices.contains(snapshot.index)) {
          card.position = _slotCenter(snapshot.index, cards.length);
        }
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

  /// Positions cards in rows of [cardsPerRow]. Pass [projectedCount] to lay
  /// out as if extra end slots already exist (penalty-draw fly-in).
  void layout({int? projectedCount}) {
    if (_cards.isEmpty) return;
    const peekScale = 1.18;
    const peekForward = 34.0;

    final count = projectedCount ?? _cards.length;
    final peeking = _cards.where((card) => card.peeking).toList();
    final peekWidth = cardWidth * peekScale;
    final peekSpan = peeking.length * peekWidth;
    var peekX = -peekSpan / 2 + peekWidth / 2;

    for (var i = 0; i < _cards.length; i++) {
      final card = _cards[i];
      final Vector2 target;
      if (card.peeking) {
        target = Vector2(peekX, isSelf ? peekForward : -peekForward);
        peekX += peekWidth;
      } else {
        target = _slotCenter(i, count);
      }
      card.priority = card.peeking ? 10 : 0;
      card.moveTo(target);
      card.scaleTo(card.peeking ? peekScale : 1);
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

  int cardIndex;
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
    cardIndex = snapshot.index;
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
    final squeeze = _flip.abs().clamp(0.08, 1.0);
    final faceUp = _visible && _tag != null && _flip >= 0;

    canvas.saveLayer(
      Rect.fromLTWH(-6, -6, size.x + 12, size.y + 12),
      Paint()..color = Color.fromRGBO(255, 255, 255, opacityOverride),
    );
    canvas.save();
    canvas.translate(size.x / 2, 0);
    canvas.scale(squeeze, 1);
    canvas.translate(-size.x / 2, 0);
    canvas.drawPicture(
      _CardArt.picture(
        tag: faceUp ? _tag : null,
        width: size.x,
        height: size.y,
        highlighted: highlighted,
      ),
    );
    canvas.restore();
    canvas.restore();
  }
}

/// Engraved Roman capitals, the register printed decks use for their indices.
const String _cardFontFamily = 'Cinzel';

/// Draws card faces and backs once per tag/size and replays the recording, so
/// the pip layouts cost nothing per frame.
class _CardArt {
  static final Map<String, Picture> _cache = {};

  static Picture picture({
    required String? tag,
    required double width,
    required double height,
    required bool highlighted,
  }) {
    final face = tag ?? 'back:${CardBackSkins.activeId}';
    final key = '$face|$width|$height|$highlighted';
    return _cache.putIfAbsent(
      key,
      () => _record(tag, width, height, highlighted),
    );
  }

  static Picture _record(String? tag, double w, double h, bool highlighted) {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      Radius.circular(w * 0.1),
    );

    canvas.drawRRect(
      rect.shift(const Offset(0, 4)),
      Paint()
        ..color = const Color(0x3F000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    canvas.drawRRect(
      rect.shift(const Offset(0, 1)),
      Paint()
        ..color = const Color(0x33000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    if (tag == null) {
      _paintBack(canvas, rect, w, h);
    } else {
      _paintFace(canvas, rect, w, h, _CardMeta.fromTag(tag));
    }

    canvas.drawRRect(
      rect.deflate(0.75),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = highlighted ? 3 : 1.5
        ..color =
            highlighted ? const Color(0xFFFFD54F) : const Color(0x33263238),
    );
    return recorder.endRecording();
  }

  /// Hands the back over to the selected skin in a space one unit wide, so a
  /// single skin definition renders every card size on the board.
  static void _paintBack(Canvas canvas, RRect rect, double w, double h) {
    canvas.save();
    canvas.clipRRect(rect);
    canvas.scale(w);
    CardBackSkins.active.paintUnit(canvas, h / w);
    canvas.restore();
  }

  static void _paintFace(
    Canvas canvas,
    RRect rect,
    double w,
    double h,
    _CardMeta meta,
  ) {
    canvas.drawRRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment(-0.7, -1),
          end: Alignment(0.7, 1),
          colors: [Color(0xFFFFFFFF), Color(0xFFFDF8EF)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // Hairline frame in the suit colour: keeps the face from looking bare
    // without competing with the pips.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.05, h * 0.035, w * 0.9, h * 0.93),
        Radius.circular(w * 0.06),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.6, w * 0.008)
        ..color = meta.color.withValues(alpha: 0.14),
    );

    if (meta.isJoker) {
      _paintJoker(canvas, w, h, meta);
      return;
    }

    _paintIndex(canvas, w, h, meta);
    canvas.save();
    canvas.translate(w, h);
    canvas.rotate(math.pi);
    _paintIndex(canvas, w, h, meta);
    canvas.restore();

    if (meta.isFace) {
      _paintCourt(canvas, w, h, meta);
      return;
    }
    if (meta.value == 1) {
      _paintSuit(canvas, meta, w * 0.44, Offset(w * 0.5, h * 0.5));
      return;
    }
    for (final pip in _pipLayout(meta.value)) {
      final (x, y, flipped) = pip;
      canvas.save();
      canvas.translate(w * x, h * y);
      if (flipped) canvas.rotate(math.pi);
      _paintSuit(canvas, meta, w * 0.18, Offset.zero);
      canvas.restore();
    }
  }

  /// Rank over suit in the corner, the way a real card reads when fanned.
  static void _paintIndex(Canvas canvas, double w, double h, _CardMeta meta) {
    final centerX = w * 0.163;
    _paintGlyph(
      canvas,
      meta.rank,
      w * 0.19,
      meta.color,
      Offset(centerX, h * 0.102),
      bold: true,
      maxWidth: w * 0.17,
    );
    // Same filled suit mark as pip cards.
    _paintSuit(canvas, meta, w * 0.115, Offset(centerX, h * 0.212));
  }

  /// Joker: SVG face in the centre, with JOKER running down both edges
  /// (mirrored so the card reads the same either way up).
  /// Black joker = `FwOp801`; red joker = `YEP0T01`.
  /// Girl portrait kept in [jokerGirlSvgFills] for later.
  static void _paintJoker(Canvas canvas, double w, double h, _CardMeta meta) {
    _paintJokerWord(canvas, w, h, meta.color);
    canvas.save();
    canvas.translate(w, h);
    canvas.rotate(math.pi);
    _paintJokerWord(canvas, w, h, meta.color);
    canvas.restore();

    final red =
        meta.suit == SuitShape.diamonds || meta.suit == SuitShape.hearts;
    final aspect = jokerSvgAspect(red: red);
    // Red fills the face; black stays modest so lettering stays clear.
    final maxW = w * (red ? 0.92 : 0.68);
    final maxH = h * (red ? 0.86 : 0.55);
    var faceW = maxW;
    var faceH = faceW / aspect;
    if (faceH > maxH) {
      faceH = maxH;
      faceW = faceH * aspect;
    }
    final left = (w - faceW) / 2;
    final top = (h - faceH) / 2;
    final toFace = Float64List.fromList([
      faceW, 0, 0, 0, //
      0, faceH, 0, 0, //
      0, 0, 1, 0, //
      left, top, 0, 1, //
    ]);
    final fill = Paint()..color = meta.color;
    for (final path in jokerSvgFills(red: red)) {
      canvas.drawPath(path.transform(toFace), fill);
    }
  }

  static void _paintJokerWord(Canvas canvas, double w, double h, Color color) {
    const word = 'JOKER';
    final fontSize = w * 0.15;
    final step = fontSize * 1.15;
    for (var i = 0; i < word.length; i++) {
      _paintGlyph(
        canvas,
        word[i],
        fontSize,
        color,
        Offset(w * 0.11, h * 0.08 + i * step),
        bold: true,
      );
    }
  }

  /// Suits are drawn as paths so they stay crisp and identical on every
  /// platform, instead of depending on the system font's glyphs.
  static void _paintSuit(
    Canvas canvas,
    _CardMeta meta,
    double size,
    Offset center,
  ) {
    canvas.save();
    canvas.translate(center.dx - size / 2, center.dy - size / 2);
    canvas.scale(size);
    canvas.drawPath(meta.path, Paint()..color = meta.color);
    canvas.restore();
  }

  /// Classic court layout: SVG figure (both halves included) inside a broken
  /// L-frame. Indices/suits stay from `_paintIndex`.
  static void _paintCourt(Canvas canvas, double w, double h, _CardMeta meta) {
    final frame = Rect.fromLTRB(w * 0.0884, h * 0.0505, w * 0.9116, h * 0.9495);
    final line =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.011
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round
          ..color = meta.color;
    final fill = Paint()..color = meta.color;

    // Broken L-frame: open at the index corners (top-left / bottom-right).
    final gapX = w * 0.22;
    final gapY = h * 0.20;
    canvas.drawPath(
      Path()
        ..moveTo(frame.left + gapX, frame.top)
        ..lineTo(frame.right, frame.top)
        ..lineTo(frame.right, frame.bottom - gapY)
        ..moveTo(frame.right - gapX, frame.bottom)
        ..lineTo(frame.left, frame.bottom)
        ..lineTo(frame.left, frame.top + gapY),
      line,
    );

    final fills = switch (meta.value) {
      11 => jackSvgFills(),
      12 => queenSvgFills(),
      _ => kingSvgFills(),
    };
    final toCard = Float64List.fromList([
      w, 0, 0, 0, //
      0, h, 0, 0, //
      0, 0, 1, 0, //
      0, 0, 0, 1, //
    ]);
    for (final path in fills) {
      canvas.drawPath(path.transform(toCard), fill);
    }
  }

  static void _paintGlyph(
    Canvas canvas,
    String text,
    double fontSize,
    Color color,
    Offset center, {
    bool bold = false,
    double? maxWidth,
  }) {
    var painter = _layoutGlyph(text, fontSize, color, bold);
    if (maxWidth != null && painter.width > maxWidth) {
      painter = _layoutGlyph(
        text,
        fontSize * maxWidth / painter.width,
        color,
        bold,
      );
    }
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  static TextPainter _layoutGlyph(
    String text,
    double fontSize,
    Color color,
    bool bold,
  ) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontFamily: _cardFontFamily,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          letterSpacing: -fontSize * 0.03,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  /// Standard pip grid: fractional position plus whether the pip is upside
  /// down, mirroring how printed cards read from both ends.
  static List<(double, double, bool)> _pipLayout(int value) {
    const left = 0.365;
    const right = 0.635;
    const mid = 0.5;
    // Rows pulled in from the card edges so the pips read as one block.
    const top = 0.26;
    const bottom = 0.74;
    const upper = 0.34;
    const lower = 0.66;
    const nearTop = 0.38;
    const nearBottom = 0.62;
    const overTop = 0.42;
    const overBottom = 0.58;
    return switch (value) {
      2 => const [(mid, top, false), (mid, bottom, true)],
      3 => const [(mid, top, false), (mid, mid, false), (mid, bottom, true)],
      4 => const [
        (left, top, false),
        (right, top, false),
        (left, bottom, true),
        (right, bottom, true),
      ],
      5 => const [
        (left, top, false),
        (right, top, false),
        (mid, mid, false),
        (left, bottom, true),
        (right, bottom, true),
      ],
      6 => const [
        (left, top, false),
        (right, top, false),
        (left, mid, false),
        (right, mid, false),
        (left, bottom, true),
        (right, bottom, true),
      ],
      7 => const [
        (left, top, false),
        (right, top, false),
        (mid, nearTop, false),
        (left, mid, false),
        (right, mid, false),
        (left, bottom, true),
        (right, bottom, true),
      ],
      8 => const [
        (left, top, false),
        (right, top, false),
        (mid, nearTop, false),
        (left, mid, false),
        (right, mid, false),
        (mid, nearBottom, true),
        (left, bottom, true),
        (right, bottom, true),
      ],
      9 => const [
        (left, top, false),
        (right, top, false),
        (left, overTop, false),
        (right, overTop, false),
        (mid, mid, false),
        (left, overBottom, true),
        (right, overBottom, true),
        (left, bottom, true),
        (right, bottom, true),
      ],
      10 => const [
        (left, top, false),
        (right, top, false),
        (mid, upper, false),
        (left, overTop, false),
        (right, overTop, false),
        (left, overBottom, true),
        (right, overBottom, true),
        (mid, lower, true),
        (left, bottom, true),
        (right, bottom, true),
      ],
      _ => const [(mid, mid, false)],
    };
  }
}

class _CardMeta {
  const _CardMeta(this.rank, this.suit, this.color, this.value);

  final String rank;
  final SuitShape suit;
  final Color color;
  final int value;

  bool get isFace => value >= 11 && value <= 13;

  bool get isJoker => value == 14;

  /// Suit outline inside a unit square.
  Path get path => suitPath(suit);

  factory _CardMeta.fromTag(String tag) {
    final value = int.parse(tag.substring(1));
    final suit = switch (tag[0]) {
      'B' => SuitShape.diamonds,
      'C' => SuitShape.hearts,
      'D' => SuitShape.spades,
      _ => SuitShape.clubs,
    };
    final red = suit == SuitShape.diamonds || suit == SuitShape.hearts;
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
      red ? const Color(0xFFA31819) : const Color(0xFF1A1A1A),
      value,
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
