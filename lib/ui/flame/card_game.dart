import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:cardgame/data/decks/deck_catalog.dart';
import 'package:cardgame/domain/models/game_snapshot.dart';
import 'package:cardgame/services/sfx_service.dart';
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
typedef JackPeekCallback = void Function(String side, int cardIndex);
typedef QueenShuffleCallback = void Function(String side);
typedef QueenReplaceSelectCallback = void Function(String side, int cardIndex);
typedef VoidGameCallback = void Function();

class CardGame extends FlameGame {
  CardTapCallback? onTapCard;
  JackPeekCallback? onJackPeek;
  QueenShuffleCallback? onQueenShuffle;
  QueenReplaceSelectCallback? onQueenReplaceSelect;
  VoidGameCallback? onDraw;
  VoidGameCallback? onThrowHand;

  late final HandArea _opponentHand;
  late final HandArea _localHand;
  late final TableArea _table;
  late final DrawnCardSlot _localDrawn;
  late final DrawnCardSlot _remoteDrawn;
  late final _ShufflePickLabel _localShuffleLabel;
  late final _ShufflePickLabel _opponentShuffleLabel;

  String hintPeek = 'Tap any card to peek…';
  String hintShufflePick = 'Tap Shuffle above a hand…';
  String hintReplaceFirst = 'Tap one card from each hand…';
  String hintReplaceSecond = 'Tap a card on the other hand…';
  String shuffleLabel = 'Shuffle';
  TextDirection uiTextDirection = TextDirection.ltr;
  String? uiFontFamily;

  /// Push localized table copy from the Flutter host.
  void setUiStrings({
    required String hintPeek,
    required String hintShufflePick,
    required String hintReplaceFirst,
    required String hintReplaceSecond,
    required String shuffleLabel,
    required TextDirection textDirection,
    String? fontFamily,
  }) {
    this.hintPeek = hintPeek;
    this.hintShufflePick = hintShufflePick;
    this.hintReplaceFirst = hintReplaceFirst;
    this.hintReplaceSecond = hintReplaceSecond;
    this.shuffleLabel = shuffleLabel;
    uiTextDirection = textDirection;
    uiFontFamily = fontFamily;
    if (!_ready) return;
    _localShuffleLabel.label = shuffleLabel;
    _opponentShuffleLabel.label = shuffleLabel;
    _localShuffleLabel.textDirection = textDirection;
    _opponentShuffleLabel.textDirection = textDirection;
    _localShuffleLabel.fontFamily = fontFamily;
    _opponentShuffleLabel.fontFamily = fontFamily;
    _table.setHintDirection(textDirection);
    _table.setHintFontFamily(fontFamily);
    _syncTableHint();
  }

  /// Back skin applied to every face-down card. Cached art is keyed by skin id,
  /// so a change shows up on the next frame.
  String get cardBackSkinId => CardBackSkins.activeId;

  set cardBackSkinId(String id) => CardBackSkins.select(id);

  GameSnapshot? _snapshot;
  GameSnapshot? _pending;
  final List<GameSnapshot> _snapshotQueue = [];
  int _lastVersion = -1;
  bool _ready = false;
  bool _animatingAction = false;
  bool _peekSelecting = false;
  QueenMode _queenMode = QueenMode.none;
  String? _replaceFirstSide;
  int? _replaceFirstIndex;
  LastAction? _lastZoomCue;
  LastAction? _lastQueenAnim;

  String _youBackSkinId = CardBackSkins.ornateBlue.id;
  String _opponentBackSkinId = CardBackSkins.ornateBlue.id;
  String _turnBackSkinId = CardBackSkins.ornateBlue.id;
  String? _discardBackSkinId;

  /// Hand slot this client last tapped. The server only reports public state,
  /// so the tap index is what lets the board animate the right card.
  int? _pendingTapIndex;

  /// When set, next drawn-slot sync skips the pop-in (ghost already flew in).
  bool? _suppressDrawnAppearSelf;

  /// When set, the next sync snaps the new end-slot card into place (no fly-in).
  bool? _expectingPenaltyAppendSelf;

  bool get peekSelecting => _peekSelecting;

  set peekSelecting(bool value) {
    if (_peekSelecting == value) return;
    _peekSelecting = value;
    if (_ready) _refreshInteraction();
  }

  QueenMode get queenMode => _queenMode;

  set queenMode(QueenMode value) {
    if (_queenMode == value) return;
    _queenMode = value;
    if (value != QueenMode.replacePick) {
      _replaceFirstSide = null;
      _replaceFirstIndex = null;
      if (_ready) _clearReplaceFloat();
    }
    _refreshInteraction();
  }

  void setReplaceSelection({String? side, int? index}) {
    _replaceFirstSide = side;
    _replaceFirstIndex = index;
    if (_ready) {
      _applyReplaceFloat();
      _syncTableHint();
    }
  }

  void _refreshInteraction() {
    if (!_ready || _animatingAction) return;
    final snapshot = _snapshot;
    if (snapshot != null) _wireHandTaps(snapshot);
    _syncShuffleLabels();
    _syncTableHint();
  }

  void _syncTableHint() {
    if (!_ready) return;
    final snapshot = _snapshot;
    final String? message;
    if (_peekSelecting && snapshot?.canJackPeek == true) {
      message = hintPeek;
    } else if (_queenMode == QueenMode.shufflePick) {
      message = hintShufflePick;
    } else if (_queenMode == QueenMode.replacePick) {
      message =
          _replaceFirstSide == null ? hintReplaceFirst : hintReplaceSecond;
    } else {
      message = null;
    }
    _table.setHint(message);
  }

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
    _localShuffleLabel = _ShufflePickLabel(
      onPressed: () => onQueenShuffle?.call('you'),
      label: shuffleLabel,
      textDirection: uiTextDirection,
      fontFamily: uiFontFamily,
    )..position = Vector2(size.x * 0.5, size.y * 0.75 - 90);
    _opponentShuffleLabel = _ShufflePickLabel(
      onPressed: () => onQueenShuffle?.call('opponent'),
      label: shuffleLabel,
      textDirection: uiTextDirection,
      fontFamily: uiFontFamily,
    )..position = Vector2(size.x * 0.5, size.y * 0.25 + 90);

    world.addAll([
      _opponentHand,
      _localHand,
      _table,
      _localDrawn,
      _remoteDrawn,
      _localShuffleLabel,
      _opponentShuffleLabel,
    ]);

    _ready = true;
    _localShuffleLabel.label = shuffleLabel;
    _opponentShuffleLabel.label = shuffleLabel;
    _localShuffleLabel.textDirection = uiTextDirection;
    _opponentShuffleLabel.textDirection = uiTextDirection;
    _localShuffleLabel.fontFamily = uiFontFamily;
    _opponentShuffleLabel.fontFamily = uiFontFamily;
    _table.setHintDirection(uiTextDirection);
    _table.setHintFontFamily(uiFontFamily);
    _syncShuffleLabels();
    _applyReplaceFloat();
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
    _localDrawn.position = Vector2(56, size.y - 92);
    _remoteDrawn.position = Vector2(size.x * 0.5, 52);
    _localShuffleLabel.position = Vector2(size.x * 0.5, size.y * 0.75 - 90);
    _opponentShuffleLabel.position = Vector2(size.x * 0.5, size.y * 0.25 + 90);
    _layoutHands();
  }

  void applySnapshot(GameSnapshot snapshot) {
    if (!_ready) {
      _pending = snapshot;
      return;
    }
    if (_animatingAction) {
      _enqueueSnapshot(snapshot);
      return;
    }
    if (snapshot.version == _lastVersion &&
        _snapshot != null &&
        snapshot.roomId == _snapshot!.roomId) {
      return;
    }
    // Room change: drop stale queue from prior match.
    if (_snapshot != null && snapshot.roomId != _snapshot!.roomId) {
      _snapshotQueue.clear();
    }
    final previous = _snapshot;

    final queenAnim = _planQueenAbilityAnim(previous, snapshot);
    if (queenAnim != null) {
      _lastVersion = snapshot.version;
      _animatingAction = true;
      queenAnim(() => _completeActionAnim(snapshot));
      return;
    }

    final action =
        previous == null
            ? null
            : _planAction(previous, snapshot) ??
                _planOpponentAction(previous, snapshot);

    if (action != null) {
      _lastVersion = snapshot.version;
      _animatingAction = true;
      _runAction(action, () => _completeActionAnim(snapshot));
      return;
    }

    _syncSnapshot(snapshot);
    _drainSnapshotQueue();
  }

  void _enqueueSnapshot(GameSnapshot snapshot) {
    if (_snapshotQueue.any(
      (queued) =>
          queued.version == snapshot.version &&
          queued.roomId == snapshot.roomId,
    )) {
      return;
    }
    if (_snapshot != null &&
        snapshot.roomId == _snapshot!.roomId &&
        snapshot.version <= _lastVersion) {
      return;
    }
    _snapshotQueue.add(snapshot);
    _snapshotQueue.sort((a, b) => a.version.compareTo(b.version));
  }

  /// Sync the frame we just animated, then play the next queued snapshot.
  void _completeActionAnim(GameSnapshot animatedSnapshot) {
    _animatingAction = false;
    _syncSnapshot(animatedSnapshot);
    _drainSnapshotQueue();
  }

  void _drainSnapshotQueue() {
    while (!_animatingAction && _snapshotQueue.isNotEmpty) {
      final next = _snapshotQueue.removeAt(0);
      if (_snapshot != null &&
          next.roomId == _snapshot!.roomId &&
          next.version <= _lastVersion) {
        continue;
      }
      applySnapshot(next);
    }
  }

  void Function(VoidCallback onComplete)? _planQueenAbilityAnim(
    GameSnapshot? previous,
    GameSnapshot snapshot,
  ) {
    final action = snapshot.lastAction;
    if (action == null) return null;
    if (action.sameAs(_lastQueenAnim) &&
        previous?.lastAction?.sameAs(action) == true) {
      return null;
    }
    if (action.type == LastActionType.queenShuffle && action.side != null) {
      return (onComplete) {
        _lastQueenAnim = action;
        _runQueenShuffle(action, onComplete);
      };
    }
    if (action.type == LastActionType.queenReplace &&
        action.youIndex != null &&
        action.opponentIndex != null) {
      return (onComplete) {
        _lastQueenAnim = action;
        _runQueenReplace(action, onComplete);
      };
    }
    return null;
  }

  void _syncSnapshot(GameSnapshot snapshot) {
    final previous = _snapshot;
    _snapshot = snapshot;
    _lastVersion = snapshot.version;
    final localSnapIndices = <int>{};
    final opponentSnapIndices = <int>{};
    final expectingSelf = _expectingPenaltyAppendSelf;
    _expectingPenaltyAppendSelf = null;
    if (expectingSelf == true &&
        previous != null &&
        snapshot.you.cards.length == previous.you.cards.length + 1 &&
        snapshot.you.cards.isNotEmpty) {
      localSnapIndices.add(snapshot.you.cards.last.index);
    }
    if (expectingSelf == false &&
        previous != null &&
        previous.opponent != null &&
        snapshot.opponent != null &&
        snapshot.opponent!.cards.length ==
            previous.opponent!.cards.length + 1 &&
        snapshot.opponent!.cards.isNotEmpty) {
      opponentSnapIndices.add(snapshot.opponent!.cards.last.index);
    }

    _youBackSkinId = DeckCatalog.skinIdFor(snapshot.you.deckId);
    _opponentBackSkinId = DeckCatalog.skinIdFor(snapshot.opponent?.deckId);
    _turnBackSkinId =
        snapshot.isYourTurn ? _youBackSkinId : _opponentBackSkinId;

    if (snapshot.discardDeckId != null) {
      _discardBackSkinId = DeckCatalog.skinIdFor(snapshot.discardDeckId);
    } else {
      final lastActionActor = snapshot.lastAction?.actor;
      if (lastActionActor == LastActionActor.you) {
        _discardBackSkinId = _youBackSkinId;
      } else if (lastActionActor == LastActionActor.opponent) {
        _discardBackSkinId = _opponentBackSkinId;
      }
    }
    final currentDiscardSkin = _discardBackSkinId ?? _turnBackSkinId;

    _opponentHand.syncCards(
      snapshot.opponent?.cards ?? const [],
      highlight:
          !snapshot.isYourTurn ||
          _peekSelecting ||
          _queenMode != QueenMode.none,
      onTap: null,
      animateDeal: previous == null || previous.version > snapshot.version,
      snapToPositionIndices: opponentSnapIndices,
      peekIndices: _jackPeekIndices(snapshot, side: 'opponent'),
      backSkinId: _opponentBackSkinId,
    );
    _localHand.syncCards(
      snapshot.you.cards,
      highlight:
          snapshot.isYourTurn || _peekSelecting || _queenMode != QueenMode.none,
      onTap: null,
      animateDeal: previous == null || previous.status != GameStatus.playing,
      snapToPositionIndices: localSnapIndices,
      peekIndices: _localPeekIndices(snapshot),
      backSkinId: _youBackSkinId,
    );
    _wireHandTaps(snapshot);
    _syncShuffleLabels();
    _table.sync(
      deckCount: snapshot.deckCount,
      discardTag: snapshot.discardTopTag,
      canDraw:
          snapshot.isYourTurn &&
          snapshot.you.handCardTag == null &&
          snapshot.status == GameStatus.playing &&
          snapshot.bothRevealed &&
          !_peekSelecting &&
          _queenMode == QueenMode.none,
      deckBackSkinId: _turnBackSkinId,
      discardBackSkinId: currentDiscardSkin,
    );
    _localDrawn.sync(
      snapshot.you.handCardTag,
      faceUp: true,
      animateAppear: _suppressDrawnAppearSelf != true,
      throwable:
          snapshot.isYourTurn &&
          !snapshot.abilityLockActive &&
          _queenMode == QueenMode.none,
      backSkinId: _youBackSkinId,
    );
    _remoteDrawn.sync(
      snapshot.opponent?.hasHandCard == true ? 'BACK' : null,
      faceUp: false,
      animateAppear: _suppressDrawnAppearSelf != false,
      backSkinId: _opponentBackSkinId,
    );
    _suppressDrawnAppearSelf = null;
    _layoutHands();
    _applyJackPeekZoom(snapshot, previous);
    _syncTableHint();
  }

  Set<int> _localPeekIndices(GameSnapshot snapshot) {
    if (snapshot.you.launch == LaunchStatus.launched) {
      return {
        for (final card in snapshot.you.cards)
          if (card.visible) card.index,
      };
    }
    return _jackPeekIndices(snapshot, side: 'you');
  }

  Set<int> _jackPeekIndices(GameSnapshot snapshot, {required String side}) {
    final action = snapshot.lastAction;
    if (action == null ||
        action.type != LastActionType.jackPeek ||
        action.actor != LastActionActor.you ||
        action.side != side ||
        action.cardIndex == null) {
      return const {};
    }
    final cards = side == 'you' ? snapshot.you.cards : snapshot.opponent?.cards;
    if (cards == null) return const {};
    final match = cards.where((card) => card.index == action.cardIndex);
    if (match.isEmpty || !match.first.visible) return const {};
    return {action.cardIndex!};
  }

  void _wireHandTaps(GameSnapshot snapshot) {
    if (_peekSelecting && snapshot.canJackPeek) {
      _localHand.setTapHandler((index) => _handleJackPeekTap('you', index));
      _opponentHand.setTapHandler(
        (index) => _handleJackPeekTap('opponent', index),
      );
      return;
    }
    if (_queenMode == QueenMode.replacePick && snapshot.canQueenAbility) {
      _localHand.setTapHandler((index) => _handleQueenReplaceTap('you', index));
      _opponentHand.setTapHandler(
        (index) => _handleQueenReplaceTap('opponent', index),
      );
      return;
    }
    final canTapHand =
        snapshot.isYourTurn &&
        !snapshot.abilityLockActive &&
        _queenMode == QueenMode.none;
    _localHand.setTapHandler(canTapHand ? _handleHandTap : null);
    _opponentHand.setTapHandler(null);
  }

  void _syncShuffleLabels() {
    if (!_ready) return;
    final show = _queenMode == QueenMode.shufflePick;
    _localShuffleLabel.visible = show;
    _opponentShuffleLabel.visible = show;
  }

  void _handleQueenReplaceTap(String side, int cardIndex) {
    onQueenReplaceSelect?.call(side, cardIndex);
  }

  void _clearReplaceFloat() {
    if (!_ready) return;
    for (final card in _localHand.cards) {
      card.peeking = false;
    }
    for (final card in _opponentHand.cards) {
      card.peeking = false;
    }
    _layoutHands();
  }

  void _applyReplaceFloat() {
    if (!_ready) return;
    _clearReplaceFloat();
    final side = _replaceFirstSide;
    final index = _replaceFirstIndex;
    if (side == null || index == null) return;
    final hand = side == 'you' ? _localHand : _opponentHand;
    final card = hand.cardAt(index);
    if (card == null) return;
    card.peeking = true;
    hand.layout();
  }

  void _runQueenShuffle(LastAction action, VoidCallback onComplete) {
    final sideFromActor = action.side!;
    final HandArea hand;
    if (action.actor == LastActionActor.you) {
      hand = sideFromActor == 'you' ? _localHand : _opponentHand;
    } else {
      hand = sideFromActor == 'you' ? _opponentHand : _localHand;
    }
    hand.playShuffleAnimation(onComplete: onComplete);
  }

  void _runQueenReplace(LastAction action, VoidCallback onComplete) {
    _clearReplaceFloat();
    final int localIndex;
    final int opponentIndex;
    if (action.actor == LastActionActor.you) {
      localIndex = action.youIndex!;
      opponentIndex = action.opponentIndex!;
    } else {
      localIndex = action.opponentIndex!;
      opponentIndex = action.youIndex!;
    }
    final localCard = _localHand.cardAt(localIndex);
    final oppCard = _opponentHand.cardAt(opponentIndex);
    if (localCard == null || oppCard == null) {
      onComplete();
      return;
    }

    final localStart = localCard.absolutePositionOfAnchor(Anchor.center);
    final oppStart = oppCard.absolutePositionOfAnchor(Anchor.center);
    final localLift = _liftPos(localStart, isSelf: true);
    final oppLift = _liftPos(oppStart, isSelf: false);
    final localSlot = _localHand.worldSlotCenter(
      localIndex,
      count: _localHand.cards.length,
    );
    final oppSlot = _opponentHand.worldSlotCenter(
      opponentIndex,
      count: _opponentHand.cards.length,
    );

    localCard.opacityOverride = 0;
    oppCard.opacityOverride = 0;

    final ghostA = _ghostCard(
      localCard.tag,
      localStart,
      faceUp: localCard.tag != null,
      backSkinId: _youBackSkinId,
    );
    final ghostB = _ghostCard(
      oppCard.tag,
      oppStart,
      faceUp: oppCard.tag != null,
      backSkinId: _opponentBackSkinId,
    );
    world.addAll([ghostA, ghostB]);

    void finish() {
      // Keep shells in the same slot indices; sync will refresh faces.
      localCard
        ..position = _localHand._slotCenter(localIndex, _localHand.cards.length)
        ..opacityOverride = 1;
      oppCard
        ..position = _opponentHand._slotCenter(
          opponentIndex,
          _opponentHand.cards.length,
        )
        ..opacityOverride = 1;
      onComplete();
    }

    ghostA.add(
      SequenceEffect([
        MoveEffect.to(
          localLift,
          EffectController(duration: _liftDuration, curve: Curves.easeOutBack),
        ),
        ScaleEffect.to(
          Vector2.all(_peekScale),
          EffectController(duration: 0.12),
        ),
        _PauseEffect(_readDuration),
        MoveEffect.to(
          oppSlot,
          EffectController(
            duration: _travelDuration,
            curve: Curves.easeInOutCubic,
          ),
        ),
        RemoveEffect(),
      ]),
    );
    ghostB.add(
      SequenceEffect([
        MoveEffect.to(
          oppLift,
          EffectController(duration: _liftDuration, curve: Curves.easeOutBack),
        ),
        ScaleEffect.to(
          Vector2.all(_peekScale),
          EffectController(duration: 0.12),
        ),
        _PauseEffect(_readDuration),
        MoveEffect.to(
          localSlot,
          EffectController(
            duration: _travelDuration,
            curve: Curves.easeInOutCubic,
          ),
        ),
        _CallbackEffect(finish),
        RemoveEffect(),
      ]),
    );
  }

  void _applyJackPeekZoom(GameSnapshot snapshot, GameSnapshot? previous) {
    final action = snapshot.lastAction;
    if (action == null ||
        action.type != LastActionType.jackPeek ||
        action.cardIndex == null ||
        action.side == null) {
      return;
    }
    if (action.sameAs(_lastZoomCue) &&
        previous?.lastAction?.sameAs(action) == true) {
      return;
    }
    _lastZoomCue = action;

    // Own-card peek: flip/lift only (no zoom icon).
    if (action.actor == LastActionActor.you && action.side == 'you') {
      SfxService.instance.flip();
      return;
    }

    final HandArea hand;
    final bool showFace;
    if (action.actor == LastActionActor.you) {
      // Peeker looking at opponent card: zoom + private face.
      hand = _opponentHand;
      showFace = true;
    } else {
      // Opponent peeked: their "you" is our opponent hand; their "opponent" is us.
      hand = action.side == 'you' ? _opponentHand : _localHand;
      showFace = false;
    }
    SfxService.instance.flip();
    hand.playZoomCue(action.cardIndex!, showFace: showFace);
  }

  /// Local seat: pending tap drives match/swap/penalty; draw/throw from diff.
  _CardActionPlan? _planAction(GameSnapshot previous, GameSnapshot snapshot) {
    final tapIndex = _pendingTapIndex;
    final before = previous.you.cards.length;

    if (tapIndex != null) {
      // Snapshots unrelated to our own move must not consume the pending tap.
      if (before == snapshot.you.cards.length &&
          previous.you.handCardTag == snapshot.you.handCardTag) {
        return null;
      }
      _pendingTapIndex = null;
      return _planSeatAction(
        previous: previous,
        snapshot: snapshot,
        isSelf: true,
        prevPlayer: previous.you,
        nextPlayer: snapshot.you,
        hand: _localHand,
        drawnSlot: _localDrawn,
        tapIndex: tapIndex,
        hintCardTag: null,
        hintDrawnTag: previous.you.handCardTag,
        preferThrow: false,
      );
    }

    // No tap: still animate local draw / throw from seat diff.
    return _planSeatAction(
      previous: previous,
      snapshot: snapshot,
      isSelf: true,
      prevPlayer: previous.you,
      nextPlayer: snapshot.you,
      hand: _localHand,
      drawnSlot: _localDrawn,
      tapIndex: null,
      hintCardTag:
          snapshot.lastAction?.actor == LastActionActor.you
              ? snapshot.lastAction?.cardTag
              : null,
      hintDrawnTag: previous.you.handCardTag,
      preferThrow: snapshot.lastAction?.type == LastActionType.throwHand,
      drawThrowOnly: true,
    );
  }

  /// Opponent seat: front-end diff of public opponent state (no lastAction required).
  _CardActionPlan? _planOpponentAction(
    GameSnapshot previous,
    GameSnapshot snapshot,
  ) {
    final prevOpp = previous.opponent;
    final nextOpp = snapshot.opponent;
    if (prevOpp == null || nextOpp == null) return null;

    // Own move this frame — local planner owns it.
    final youChanged =
        previous.you.cards.length != snapshot.you.cards.length ||
        previous.you.handCardTag != snapshot.you.handCardTag ||
        previous.you.hasHandCard != snapshot.you.hasHandCard;
    if (youChanged) return null;

    final oppChanged =
        prevOpp.cards.length != nextOpp.cards.length ||
        prevOpp.hasHandCard != nextOpp.hasHandCard ||
        previous.discardTopTag != snapshot.discardTopTag;
    if (!oppChanged) return null;

    final hint =
        snapshot.lastAction?.actor == LastActionActor.opponent
            ? snapshot.lastAction
            : null;
    final before = prevOpp.cards.length;
    // Prefer server slot when this frame is a swap; otherwise mid-hand fallback.
    final tapIndex = hint?.cardIndex ?? (before > 0 ? before ~/ 2 : null);
    final isSwapHint = hint?.type == LastActionType.swap;

    return _planSeatAction(
      previous: previous,
      snapshot: snapshot,
      isSelf: false,
      prevPlayer: prevOpp,
      nextPlayer: nextOpp,
      hand: _opponentHand,
      drawnSlot: _remoteDrawn,
      tapIndex: tapIndex,
      hintCardTag: hint?.cardTag,
      hintDrawnTag: hint?.drawnTag,
      // Throw vs swap are identical in public state. Only animate a hand-slot
      // swap+reveal when the server marks this frame as a swap.
      preferThrow: !isSwapHint,
      drawThrowOnly: false,
    );
  }

  /// Shared branches for either seat — same outcomes as the original local planner.
  _CardActionPlan? _planSeatAction({
    required GameSnapshot previous,
    required GameSnapshot snapshot,
    required bool isSelf,
    required PlayerSnapshot prevPlayer,
    required PlayerSnapshot nextPlayer,
    required HandArea hand,
    required DrawnCardSlot drawnSlot,
    required int? tapIndex,
    required String? hintCardTag,
    required String? hintDrawnTag,
    required bool preferThrow,
    bool drawThrowOnly = false,
  }) {
    final hadDrawn = prevPlayer.hasHandCard;
    final hasDrawn = nextPlayer.hasHandCard;
    final before = prevPlayer.cards.length;
    final after = nextPlayer.cards.length;
    final discard = _table.worldDiscardPosition;
    final previousDiscardTop = previous.discardTopTag;
    final discarded = snapshot.discardRecentTags;
    final discardChanged = snapshot.discardTopTag != previous.discardTopTag;
    final drawnStart =
        drawnSlot.worldCardPosition ?? drawnSlot.worldSlotPosition;
    final knownDrawnTag = isSelf ? previous.you.handCardTag : hintDrawnTag;

    // --- draw / throw (no hand tap required) ---
    if (!hadDrawn && hasDrawn && before == after) {
      return _CardActionPlan(
        kind: _CardActionKind.draw,
        isSelf: isSelf,
        cardIndex: -1,
        handStart: drawnSlot.worldSlotPosition,
        discard: discard,
        deckStart: _table.worldDeckPosition,
        drawnTag: isSelf ? nextPlayer.handCardTag : null,
        drawnFaceUp: isSelf,
        previousDiscardTop: previousDiscardTop,
      );
    }

    if (hadDrawn && !hasDrawn && before == after && discardChanged) {
      final thrownTag = hintCardTag ?? snapshot.discardTopTag;
      if (thrownTag == null) return null;

      // discardSource is public and unambiguous: hand → swap reveal, drawn → throw.
      final wantSwap = switch (snapshot.discardSource) {
        'hand' => true,
        'drawn' => false,
        _ => !drawThrowOnly && (isSelf || !preferThrow),
      };

      if (wantSwap) {
        final handStart = _resolveHandStart(hand, tapIndex, before);
        if (handStart == null) return null;
        final cardIndex = _resolveCardIndex(hand, tapIndex, before);
        return _CardActionPlan(
          kind: _CardActionKind.swap,
          isSelf: isSelf,
          cardIndex: cardIndex,
          tappedTag: thrownTag,
          drawnTag: isSelf ? knownDrawnTag : null,
          drawnFaceUp: isSelf,
          handStart: handStart,
          drawnStart: drawnStart,
          discard: discard,
          previousDiscardTop: previousDiscardTop,
        );
      }

      return _CardActionPlan(
        kind: _CardActionKind.throwHand,
        isSelf: isSelf,
        cardIndex: -1,
        handStart: drawnStart,
        discard: discard,
        tappedTag: thrownTag,
        drawnTag: knownDrawnTag ?? thrownTag,
        drawnFaceUp: isSelf,
        drawnStart: drawnStart,
        previousDiscardTop: previousDiscardTop,
      );
    }

    if (drawThrowOnly) return null;

    final handStart = _resolveHandStart(hand, tapIndex, before);
    if (handStart == null) return null;
    final cardIndex = _resolveCardIndex(hand, tapIndex, before);

    if (hadDrawn && !hasDrawn) {
      if (after < before) {
        final tappedTag =
            hintCardTag ??
            (discarded.length >= 2 &&
                    knownDrawnTag != null &&
                    discarded.last == knownDrawnTag
                ? discarded.first
                : (discarded.length >= 2
                    ? discarded.first
                    : snapshot.discardTopTag));
        final drawnTag =
            hintDrawnTag ??
            knownDrawnTag ??
            (discarded.length >= 2 ? discarded.last : snapshot.discardTopTag);
        if (drawnTag == null) return null;
        return _CardActionPlan(
          kind: _CardActionKind.doubleDiscard,
          isSelf: isSelf,
          cardIndex: cardIndex,
          tappedTag: tappedTag,
          drawnTag: drawnTag,
          drawnFaceUp: true,
          handStart: handStart,
          drawnStart: drawnStart,
          discard: discard,
          previousDiscardTop: previousDiscardTop,
        );
      }
      final swapped = hintCardTag ?? snapshot.discardTopTag;
      if (swapped == null) return null;
      return _CardActionPlan(
        kind: _CardActionKind.swap,
        isSelf: isSelf,
        cardIndex: cardIndex,
        tappedTag: swapped,
        drawnTag: knownDrawnTag,
        drawnFaceUp: isSelf,
        handStart: handStart,
        drawnStart: drawnStart,
        discard: discard,
        previousDiscardTop: previousDiscardTop,
      );
    }

    if (!hadDrawn && after < before) {
      if (discarded.length >= 2 && discarded.first != previous.discardTopTag) {
        return _CardActionPlan(
          kind: _CardActionKind.doubleDiscard,
          isSelf: isSelf,
          cardIndex: cardIndex,
          tappedTag: hintCardTag ?? discarded.first,
          drawnTag: hintDrawnTag ?? discarded.last,
          drawnFaceUp: true,
          handStart: handStart,
          drawnStart: _table.worldDeckPosition,
          discard: discard,
          previousDiscardTop: previousDiscardTop,
        );
      }
      final matched = hintCardTag ?? snapshot.discardTopTag;
      if (matched == null) return null;
      return _CardActionPlan(
        kind: _CardActionKind.discardMatch,
        isSelf: isSelf,
        cardIndex: cardIndex,
        tappedTag: matched,
        handStart: handStart,
        discard: discard,
        previousDiscardTop: previousDiscardTop,
      );
    }

    if (!hadDrawn && after > before) {
      hand.layout(projectedCount: after);
      return _CardActionPlan(
        kind: _CardActionKind.penaltyDraw,
        isSelf: isSelf,
        cardIndex: cardIndex,
        handStart: handStart,
        discard: discard,
        deckStart: _table.worldDeckPosition,
        handOrigin: hand.worldSlotCenter(after - 1, count: after),
        previousDiscardTop: previousDiscardTop,
      );
    }

    return null;
  }

  int _resolveCardIndex(HandArea hand, int? tapIndex, int count) {
    if (tapIndex != null && hand.cardAt(tapIndex) != null) return tapIndex;
    if (hand.cards.isEmpty) return tapIndex ?? 0;
    final fallback = (tapIndex ?? (count ~/ 2)).clamp(0, hand.cards.length - 1);
    return hand.cards[fallback].cardIndex;
  }

  Vector2? _resolveHandStart(HandArea hand, int? tapIndex, int count) {
    if (tapIndex != null) {
      final pos = hand.worldPositionFor(tapIndex);
      if (pos != null) return pos;
    }
    if (hand.cards.isEmpty) {
      if (count <= 0) return null;
      final slot = (tapIndex ?? (count ~/ 2)).clamp(0, count - 1);
      return hand.worldSlotCenter(slot, count: count);
    }
    final fallback = (tapIndex ?? (count ~/ 2)).clamp(0, hand.cards.length - 1);
    return hand.cards[fallback].absolutePositionOfAnchor(Anchor.center);
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
        SfxService.instance.draw();
        _runPenaltyDraw(plan, onComplete);
      case _CardActionKind.draw:
        SfxService.instance.draw();
        _runDraw(plan, onComplete);
      case _CardActionKind.throwHand:
        _runThrow(plan, onComplete);
    }
  }

  void _handleHandTap(int cardIndex) {
    _pendingTapIndex = cardIndex;
    onTapCard?.call(cardIndex);
  }

  void _handleJackPeekTap(String side, int cardIndex) {
    _peekSelecting = false;
    onJackPeek?.call(side, cardIndex);
  }

  HandArea _handFor(_CardActionPlan plan) =>
      plan.isSelf ? _localHand : _opponentHand;

  DrawnCardSlot _drawnFor(_CardActionPlan plan) =>
      plan.isSelf ? _localDrawn : _remoteDrawn;

  void _clearActionOverlays() {
    _table.releaseDiscard();
    for (final card in _localHand.cards) {
      if (card.opacityOverride < 1) card.opacityOverride = 1;
    }
    for (final card in _opponentHand.cards) {
      if (card.opacityOverride < 1) card.opacityOverride = 1;
    }
    _localDrawn.setCardOpacity(1);
    _remoteDrawn.setCardOpacity(1);
  }

  // Shared timing for the action animations, mirroring the reveal: cards lift
  // toward the player, sit enlarged long enough to read, then travel.
  static const _liftDuration = 0.26;
  static const _readDuration = 0.6;
  static const _travelDuration = 0.5;
  static const _peekScale = 1.35;
  static const _liftForward = 60.0;

  /// Put SFX before card fully settles on discard (~55% through travel).
  static const _putEarlyFraction = 0.55;

  /// Fire put mid-flight toward discard (after optional lift+read).
  void _schedulePutSfx({required bool withLiftRead, double extraPause = 0}) {
    final beforeTravel =
        (withLiftRead ? _liftDuration + _readDuration : 0.0) + extraPause;
    final early = beforeTravel + _travelDuration * _putEarlyFraction;
    // Attach to world so it survives ghost card removal timing.
    world.add(
      TimerComponent(
        period: early,
        removeOnFinish: true,
        onTick: () => SfxService.instance.throwCard(),
      ),
    );
  }

  /// Lift toward table centre so opponent hand mirrors local hand motion.
  Vector2 _liftPos(Vector2 from, {required bool isSelf}) =>
      from + Vector2(0, isSelf ? -_liftForward : _liftForward);

  void _runDoubleDiscard(_CardActionPlan plan, VoidCallback onComplete) {
    const phaseA = _liftDuration + _readDuration + _travelDuration;
    final tappedTag = plan.tappedTag;
    final drawnTag = plan.drawnTag!;
    final pileRevealTag = tappedTag ?? drawnTag;
    final hand = _handFor(plan);
    final drawnSlot = _drawnFor(plan);
    final throwerSkin = _handSkin(isSelf: plan.isSelf);
    _discardBackSkinId = throwerSkin;

    hand.cardAt(plan.cardIndex)?.opacityOverride = 0;
    drawnSlot.setCardOpacity(0);
    _table.holdDiscard(
      plan.previousDiscardTop,
      pendingTag: pileRevealTag,
      pendingBackSkinId: throwerSkin,
    );

    // Phase A: tapped hand card lifts, flips when known, holds, then travels.
    final thrown = _ghostCard(
      tappedTag,
      plan.handStart,
      faceUp: false,
      backSkinId: _handSkin(isSelf: plan.isSelf),
    );
    world.add(thrown);
    _schedulePutSfx(withLiftRead: true);
    if (tappedTag != null) {
      thrown.flipTo(
        tag: tappedTag,
        visible: true,
        delay: 0.1,
        duration: 0.2,
        sfx: false,
      );
    }
    thrown.add(
      SequenceEffect([
        MoveEffect.to(
          _liftPos(plan.handStart, isSelf: plan.isSelf),
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
    final drawn = _ghostCard(
      drawnTag,
      plan.drawnStart!,
      faceUp: plan.drawnFaceUp,
      backSkinId: _handSkin(isSelf: plan.isSelf),
    );
    world.add(drawn);
    if (!plan.drawnFaceUp) {
      drawn.flipTo(
        tag: drawnTag,
        visible: true,
        delay: 0.05,
        duration: 0.2,
        sfx: false,
      );
    }
    _schedulePutSfx(withLiftRead: false, extraPause: phaseA);
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
    final hand = _handFor(plan);
    final hidden = hand.cardAt(plan.cardIndex);
    final throwerSkin = _handSkin(isSelf: plan.isSelf);
    _discardBackSkinId = throwerSkin;

    hidden?.opacityOverride = 0;
    _table.holdDiscard(
      plan.previousDiscardTop,
      pendingTag: tapped,
      pendingBackSkinId: throwerSkin,
    );

    final card = _ghostCard(
      tapped,
      plan.handStart,
      faceUp: false,
      backSkinId: _handSkin(isSelf: plan.isSelf),
    );
    world.add(card);
    card.flipTo(
      tag: tapped,
      visible: true,
      delay: 0.1,
      duration: 0.2,
      sfx: false,
    );
    _schedulePutSfx(withLiftRead: true);
    card.add(
      SequenceEffect([
        MoveEffect.to(
          _liftPos(plan.handStart, isSelf: plan.isSelf),
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
    final hand = _handFor(plan);
    final tapped = hand.cardAt(plan.cardIndex);
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
    final penalty = _ghostCard(
      null,
      plan.deckStart!,
      faceUp: false,
      backSkinId: _turnBackSkinId,
    );
    _expectingPenaltyAppendSelf = plan.isSelf;
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
    // Same reveal timing as discard-match / double-discard (those work).
    const phaseA = _liftDuration + _readDuration + _travelDuration;
    final hand = _handFor(plan);
    final drawnSlot = _drawnFor(plan);
    final landing = hand.cardAt(plan.cardIndex);
    final swappedTag = plan.tappedTag!;
    final throwerSkin = _handSkin(isSelf: plan.isSelf);
    _discardBackSkinId = throwerSkin;

    landing?.opacityOverride = 0;
    _table.holdDiscard(
      plan.previousDiscardTop,
      pendingTag: swappedTag,
      pendingBackSkinId: throwerSkin,
    );

    // Phase A: chosen hand card lifts, flips face-up to reveal, holds, then
    // travels to discard — identical motion language to a matching discard.
    final thrown = _ghostCard(
      swappedTag,
      plan.handStart,
      faceUp: false,
      backSkinId: _handSkin(isSelf: plan.isSelf),
    )..priority = 200;
    world.add(thrown);
    thrown.flipTo(
      tag: swappedTag,
      visible: true,
      delay: 0.1,
      duration: 0.2,
      sfx: false,
    );
    _schedulePutSfx(withLiftRead: true);
    thrown.add(
      SequenceEffect([
        MoveEffect.to(
          _liftPos(plan.handStart, isSelf: plan.isSelf),
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

    // Phase B: drawn replacement travels into the vacated slot (face private
    // for opponent).
    final placed = _ghostCard(
      plan.drawnTag,
      plan.drawnStart!,
      faceUp: plan.drawnFaceUp,
      backSkinId: _handSkin(isSelf: plan.isSelf),
    )..priority = 200;
    world.add(placed);
    placed.add(
      SequenceEffect([
        _PauseEffect(phaseA),
        _CallbackEffect(() => drawnSlot.setCardOpacity(0)),
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

  /// Deck → drawn slot (face-up for local, face-down for opponent).
  void _runDraw(_CardActionPlan plan, VoidCallback onComplete) {
    final landing = plan.handStart;
    _suppressDrawnAppearSelf = plan.isSelf;
    final card = _ghostCard(
      plan.drawnTag,
      plan.deckStart!,
      faceUp: plan.drawnFaceUp,
      backSkinId: _turnBackSkinId,
    );
    world.add(card);
    card.add(
      SequenceEffect([
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

  /// Drawn slot → discard pile.
  void _runThrow(_CardActionPlan plan, VoidCallback onComplete) {
    final drawnSlot = _drawnFor(plan);
    final tag = plan.tappedTag!;
    final throwerSkin = _handSkin(isSelf: plan.isSelf);
    _discardBackSkinId = throwerSkin;

    drawnSlot.setCardOpacity(0);
    _table.holdDiscard(
      plan.previousDiscardTop,
      pendingTag: tag,
      pendingBackSkinId: throwerSkin,
    );

    final card = _ghostCard(
      plan.drawnTag ?? tag,
      plan.drawnStart!,
      faceUp: plan.drawnFaceUp,
      backSkinId: _handSkin(isSelf: plan.isSelf),
    );
    world.add(card);
    if (!plan.drawnFaceUp) {
      card.flipTo(
        tag: tag,
        visible: true,
        delay: 0.1,
        duration: 0.2,
        sfx: false,
      );
    }
    _schedulePutSfx(withLiftRead: true);
    card.add(
      SequenceEffect([
        MoveEffect.to(
          _liftPos(plan.drawnStart!, isSelf: plan.isSelf),
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

  String _handSkin({required bool isSelf}) =>
      isSelf ? _youBackSkinId : _opponentBackSkinId;

  PlayingCardComponent _ghostCard(
    String? tag,
    Vector2 start, {
    required bool faceUp,
    required String backSkinId,
  }) {
    return PlayingCardComponent(
        cardIndex: -20,
        tag: faceUp ? tag : null,
        visible: faceUp,
        sizeOverride: Vector2(86, 124),
        backSkinId: backSkinId,
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
    required String backSkinId,
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
      // Prefer same slot index so replace/shuffle keep cards in place.
      for (final card in _cards) {
        if (used.contains(card)) continue;
        if (card.opacityOverride < 1) continue;
        if (card.cardIndex == snapshot.index) {
          existing = card;
          break;
        }
      }
      if (existing == null && snapshot.tag != null) {
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
        existing.backSkinId = backSkinId;
        existing.updateFromSnapshot(snapshot, tappable: onTap != null);
        existing.onTap = onTap;
        existing.highlighted = highlight;
        existing.peeking = peekIndices.contains(snapshot.index);
        existing.opacityOverride = 1;
        if (snapToPositionIndices.contains(snapshot.index)) {
          existing.position = _slotCenter(snapshot.index, cards.length);
        }
        keep.add(existing);
      } else {
        final card =
            PlayingCardComponent(
                cardIndex: snapshot.index,
                tag: snapshot.tag,
                visible: snapshot.visible,
                onTap: onTap,
                backSkinId: backSkinId,
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

  void setTapHandler(CardTapCallback? onTap) {
    for (final card in _cards) {
      card.onTap = onTap;
      card.setTappable(onTap != null);
    }
  }

  void playZoomCue(int cardIndex, {required bool showFace}) {
    final card = cardAt(cardIndex);
    if (card == null) return;
    card.playZoomCue(showFace: showFace);
  }

  void playShuffleAnimation({required VoidCallback onComplete}) {
    if (_cards.isEmpty) {
      onComplete();
      return;
    }
    unawaited(SfxService.instance.startShuffle());
    final count = _cards.length;
    final pileCenter = Vector2(0, isSelf ? 8 : -8);
    var pending = count;

    void doneOne() {
      pending -= 1;
      if (pending > 0) return;
      for (final card in _cards) {
        card.priority = 0;
      }
      layout();
      unawaited(SfxService.instance.stopShuffle());
      onComplete();
    }

    for (var i = 0; i < count; i++) {
      final card = _cards[i];
      for (final effect in card.children.whereType<MoveEffect>().toList()) {
        effect.removeFromParent();
      }
      for (final effect in card.children.whereType<SequenceEffect>().toList()) {
        effect.removeFromParent();
      }

      // Slight deck offset so the stack reads as a pile, not one card.
      final stackPos = pileCenter + Vector2(i * 1.2, -i * 0.8);
      card.priority = 30 + i;
      card.scaleTo(1);

      card.add(
        SequenceEffect([
          // Gather into one deck.
          MoveEffect.to(
            stackPos,
            EffectController(duration: 0.3, curve: Curves.easeInOutCubic),
          ),
          // Shake the pile.
          MoveEffect.by(
            Vector2(12, 0),
            EffectController(duration: 0.05, curve: Curves.linear),
          ),
          MoveEffect.by(
            Vector2(-24, 0),
            EffectController(duration: 0.07, curve: Curves.linear),
          ),
          MoveEffect.by(
            Vector2(22, 2),
            EffectController(duration: 0.06, curve: Curves.linear),
          ),
          MoveEffect.by(
            Vector2(-18, -4),
            EffectController(duration: 0.06, curve: Curves.linear),
          ),
          MoveEffect.by(
            Vector2(14, 3),
            EffectController(duration: 0.05, curve: Curves.linear),
          ),
          MoveEffect.by(
            Vector2(-10, -2),
            EffectController(duration: 0.05, curve: Curves.linear),
          ),
          MoveEffect.to(
            stackPos,
            EffectController(duration: 0.08, curve: Curves.easeOut),
          ),
          _PauseEffect(0.06),
          // Fan back into hand slots.
          MoveEffect.to(
            _slotCenter(i, count),
            EffectController(duration: 0.34, curve: Curves.easeOutBack),
          ),
          _CallbackEffect(doneOne),
        ]),
      );
    }
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
  final _TableHintLabel _hint = _TableHintLabel()..position = Vector2(0, 88);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    addAll([_deck, _discard, _hint]);
  }

  bool _showDeck = true;
  String? _discardHoldTag;
  String? _discardHoldSkinId;
  bool _holdingDiscard = false;
  String? _pendingDiscardTag;
  String? _pendingDiscardSkinId;

  Vector2 get worldDiscardPosition =>
      _discard.absolutePositionOfAnchor(Anchor.center);

  Vector2 get worldDeckPosition =>
      _deck.absolutePositionOfAnchor(Anchor.center);

  void setHint(String? message) => _hint.setMessage(message);

  void setHintDirection(TextDirection direction) =>
      _hint.setTextDirection(direction);

  void setHintFontFamily(String? family) => _hint.setFontFamily(family);

  void holdDiscard(
    String? tag, {
    required String pendingTag,
    String? currentBackSkinId,
    String? pendingBackSkinId,
  }) {
    _holdingDiscard = true;
    _discardHoldTag = tag;
    _discardHoldSkinId = currentBackSkinId ?? _discard.backSkinId;
    _pendingDiscardTag = pendingTag;
    _pendingDiscardSkinId = pendingBackSkinId;
    _applyDiscard(
      _discardHoldTag,
      backSkinId: _discardHoldSkinId,
      animate: false,
    );
  }

  void releaseDiscard() {
    if (!_holdingDiscard) return;
    _holdingDiscard = false;
    final tag = _pendingDiscardTag ?? _discardHoldTag;
    final skinId = _pendingDiscardSkinId ?? _discardHoldSkinId;
    _discardHoldTag = null;
    _discardHoldSkinId = null;
    _pendingDiscardTag = null;
    _pendingDiscardSkinId = null;
    _applyDiscard(tag, backSkinId: skinId, animate: true);
  }

  void sync({
    required int deckCount,
    required String? discardTag,
    required bool canDraw,
    required String deckBackSkinId,
    required String discardBackSkinId,
  }) {
    _showDeck = deckCount > 0;
    _deck.backSkinId = deckBackSkinId;
    _deck.opacityOverride = _showDeck ? 1 : 0;
    _deck.highlighted = canDraw && _showDeck;
    _deck.onPressed = canDraw && _showDeck ? onDraw : null;
    _pendingDiscardTag = discardTag;
    if (_holdingDiscard) {
      _applyDiscard(
        _discardHoldTag,
        backSkinId: _discardHoldSkinId,
        animate: false,
      );
      return;
    }
    _applyDiscard(discardTag, backSkinId: discardBackSkinId, animate: true);
  }

  void _applyDiscard(
    String? discardTag, {
    String? backSkinId,
    required bool animate,
  }) {
    final previous = _discard.tag;
    if (backSkinId != null) {
      _discard.backSkinId = backSkinId;
    }
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

  Vector2 get worldSlotPosition => absolutePositionOfAnchor(Anchor.center);

  void setCardOpacity(double opacity) {
    _card?.opacityOverride = opacity;
  }

  void sync(
    String? tag, {
    required bool faceUp,
    bool animateAppear = true,
    bool throwable = true,
    String backSkinId = 'ornate_blue',
  }) {
    if (tag == null) {
      _card?.removeFromParent();
      _card = null;
      return;
    }
    final visibleTag = tag == 'BACK' ? null : tag;
    final canThrow = isSelf && throwable;
    if (_card == null) {
      _card = PlayingCardComponent(
        cardIndex: isSelf ? -10 : -11,
        tag: visibleTag,
        visible: faceUp && visibleTag != null,
        sizeOverride: Vector2(isSelf ? 86 : 48, isSelf ? 124 : 70),
        backSkinId: backSkinId,
      )..onPressed = canThrow ? () => onThrow?.call() : null;
      add(_card!);
      if (animateAppear) {
        _card!
          ..scale = Vector2.zero()
          ..add(
            ScaleEffect.to(
              Vector2.all(1),
              EffectController(duration: 0.25, curve: Curves.easeOutBack),
            ),
          );
      }
    } else {
      _card!.backSkinId = backSkinId;
      _card!.onPressed = canThrow ? () => onThrow?.call() : null;
      _card!.updateFromSnapshot(
        CardSnapshot(
          index: _card!.cardIndex,
          tag: visibleTag,
          visible: faceUp && visibleTag != null,
        ),
        tappable: canThrow,
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
    String? backSkinId,
  }) : _tag = tag,
       _visible = visible,
       backSkinId = backSkinId ?? CardBackSkins.ornateBlue.id {
    size = sizeOverride ?? Vector2(78, 112);
    anchor = Anchor.center;
  }

  int cardIndex;
  String? _tag;
  bool _visible;
  String backSkinId;
  bool highlighted = false;
  bool peeking = false;
  bool _tappable = false;
  CardTapCallback? onTap;
  VoidCallback? onPressed;
  double _flip = 1;
  double opacityOverride = 1;
  Vector2? _targetPosition;
  double _targetScale = 1;
  double _zoomCue = 0;
  bool _zoomCueActive = false;

  String? get tag => _tag;

  void setTappable(bool value) {
    _tappable = value;
  }

  void playZoomCue({required bool showFace}) {
    _zoomCueActive = true;
    _zoomCue = 0;
    for (final effect in children.whereType<_ZoomCueEffect>().toList()) {
      effect.removeFromParent();
    }
    add(
      _ZoomCueEffect(
        onProgress: (value) => _zoomCue = value,
        onDone: () {
          _zoomCueActive = false;
          _zoomCue = 0;
        },
      ),
    );
    if (showFace) {
      // Face already flipped via snapshot; bump scale for lens feel.
      scaleTo(_targetScale * 1.12);
      add(
        SequenceEffect([
          _PauseEffect(2.8),
          _CallbackEffect(() => scaleTo(peeking ? 1.18 : 1)),
        ]),
      );
    } else {
      add(
        SequenceEffect([
          ScaleEffect.to(
            Vector2.all(_targetScale * 1.08),
            EffectController(duration: 0.2, curve: Curves.easeOut),
          ),
          _PauseEffect(2.6),
          ScaleEffect.to(
            Vector2.all(_targetScale),
            EffectController(duration: 0.25, curve: Curves.easeIn),
          ),
        ]),
      );
    }
  }

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
    bool sfx = true,
  }) {
    if (sfx) {
      // Delay-matched cue so sound lines up with the half-flip.
      if (delay <= 0) {
        SfxService.instance.flip();
      } else {
        add(
          SequenceEffect([
            _PauseEffect(delay),
            _CallbackEffect(SfxService.instance.flip),
          ]),
        );
      }
    }
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

  /// Instantly set face without animation (used inside sequenced swap reveal).
  void reveal({required String? tag, required bool visible}) {
    _tag = tag;
    _visible = visible;
  }

  void updateFromSnapshot(CardSnapshot snapshot, {required bool tappable}) {
    cardIndex = snapshot.index;
    final faceChanged = _visible != snapshot.visible || _tag != snapshot.tag;
    _tappable = tappable;
    if (faceChanged) {
      // Sync/deal flips stay silent — action anims + peek own their SFX.
      flipTo(tag: snapshot.tag, visible: snapshot.visible, sfx: false);
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
        backSkinId: backSkinId,
      ),
    );
    canvas.restore();
    if (_zoomCueActive && _zoomCue > 0) {
      _paintZoomCue(canvas, _zoomCue);
    }
    canvas.restore();
  }

  void _paintZoomCue(Canvas canvas, double progress) {
    final pulse = math.sin(progress * math.pi * 2) * 0.08 + 1.0;
    final alpha = (progress < 0.15
            ? progress / 0.15
            : progress > 0.85
            ? (1 - progress) / 0.15
            : 1.0)
        .clamp(0.0, 1.0);
    final cx = size.x * 0.72;
    final cy = size.y * 0.28;
    final radius = size.x * 0.18 * pulse;
    final stroke =
        Paint()
          ..color = Color.fromRGBO(255, 213, 79, alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;
    canvas.drawCircle(Offset(cx, cy), radius, stroke);
    canvas.drawCircle(
      Offset(cx, cy),
      radius * 0.55,
      Paint()..color = Color.fromRGBO(255, 255, 255, 0.35 * alpha),
    );
    canvas.drawLine(
      Offset(cx + radius * 0.65, cy + radius * 0.65),
      Offset(cx + radius * 1.35, cy + radius * 1.35),
      stroke..strokeWidth = 3.5,
    );
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
    required String backSkinId,
  }) {
    final face = tag ?? 'back';
    final key = '$face|$backSkinId|$width|$height|$highlighted';
    return _cache.putIfAbsent(
      key,
      () => _record(tag, width, height, highlighted, backSkinId),
    );
  }

  static Picture _record(
    String? tag,
    double w,
    double h,
    bool highlighted,
    String backSkinId,
  ) {
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

    final skin = CardBackSkins.byId(backSkinId);
    final faceTheme = skin.faceTheme;

    if (tag == null) {
      _paintBack(canvas, rect, w, h, skin);
    } else {
      _paintFace(
        canvas,
        rect,
        w,
        h,
        _CardMeta.fromTag(tag, faceTheme: faceTheme),
        faceTheme,
      );
    }

    canvas.drawRRect(
      rect.deflate(0.75),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = highlighted ? 3 : 1.5
        ..color =
            highlighted
                ? faceTheme.highlightBorderColor
                : faceTheme.borderColor,
    );
    return recorder.endRecording();
  }

  /// Hands the back over to the selected skin in a space one unit wide, so a
  /// single skin definition renders every card size on the board.
  static void _paintBack(
    Canvas canvas,
    RRect rect,
    double w,
    double h,
    CardBackSkin skin,
  ) {
    canvas.save();
    canvas.clipRRect(rect);
    canvas.scale(w);
    skin.paintUnit(canvas, h / w);
    canvas.restore();
  }

  static void _paintFace(
    Canvas canvas,
    RRect rect,
    double w,
    double h,
    _CardMeta meta,
    CardFaceTheme faceTheme,
  ) {
    final bgColors = faceTheme.backgroundGradientColors;
    canvas.drawRRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: const Alignment(-0.7, -1),
          end: const Alignment(0.7, 1),
          colors:
              bgColors.length >= 2
                  ? bgColors
                  : [bgColors.first, bgColors.first],
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
        ..color = meta.color.withValues(alpha: faceTheme.frameAlpha),
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

  factory _CardMeta.fromTag(
    String tag, {
    CardFaceTheme faceTheme = CardFaceTheme.classic,
  }) {
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
      red ? faceTheme.redColor : faceTheme.blackColor,
      value,
    );
  }
}

class _TableHintLabel extends PositionComponent {
  _TableHintLabel() {
    size = Vector2(220, 32);
    anchor = Anchor.topCenter;
    priority = 40;
  }

  String? _message;
  TextDirection _textDirection = TextDirection.ltr;
  String? _fontFamily;

  void setTextDirection(TextDirection direction) {
    if (_textDirection == direction) return;
    _textDirection = direction;
    _relayout();
  }

  void setFontFamily(String? family) {
    if (_fontFamily == family) return;
    _fontFamily = family;
    _relayout();
  }

  void setMessage(String? message) {
    if (_message == message) return;
    _message = message;
    if (message == null) {
      size = Vector2(1, 1);
      return;
    }
    _relayout();
  }

  void _relayout() {
    final message = _message;
    if (message == null) return;
    final painter = _painter(message)..layout();
    size = Vector2((painter.width + 8).clamp(80, 320), painter.height + 4);
  }

  TextPainter _painter(String text) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: _fontFamily,
          color: const Color(0xFFF2F2F5),
          fontSize: 13,
          fontWeight: FontWeight.w600,
          shadows: const [Shadow(color: Color(0xCC000000), blurRadius: 6)],
        ),
      ),
      textDirection: _textDirection,
      maxLines: 2,
      textAlign: TextAlign.center,
    );
  }

  @override
  void render(Canvas canvas) {
    final message = _message;
    if (message == null) return;
    final painter = _painter(message)..layout(maxWidth: size.x);
    painter.paint(
      canvas,
      Offset((size.x - painter.width) / 2, (size.y - painter.height) / 2),
    );
  }
}

class _ShufflePickLabel extends PositionComponent with TapCallbacks {
  _ShufflePickLabel({
    required this.onPressed,
    this.label = 'Shuffle',
    this.textDirection = TextDirection.ltr,
    this.fontFamily,
  }) {
    size = Vector2(120, 36);
    anchor = Anchor.center;
    priority = 50;
  }

  final VoidCallback onPressed;
  String label;
  TextDirection textDirection;
  String? fontFamily;
  bool visible = false;

  @override
  bool containsLocalPoint(Vector2 point) {
    if (!visible) return false;
    return super.containsLocalPoint(point);
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (!visible) return;
    onPressed();
  }

  @override
  void render(Canvas canvas) {
    if (!visible) return;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      const Radius.circular(18),
    );
    canvas.drawRRect(rect, Paint()..color = const Color(0x99000000));
    canvas.drawRRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xAAFFD54F),
    );
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontFamily: fontFamily,
          color: const Color(0xEEFFFFFF),
          fontSize: 14,
          fontWeight: FontWeight.w700,
          shadows: const [Shadow(color: Color(0xCC000000), blurRadius: 4)],
        ),
      ),
      textDirection: textDirection,
    )..layout();
    painter.paint(
      canvas,
      Offset((size.x - painter.width) / 2, (size.y - painter.height) / 2),
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

enum _CardActionKind {
  doubleDiscard,
  swap,
  discardMatch,
  penaltyDraw,
  draw,
  throwHand,
}

class _CardActionPlan {
  const _CardActionPlan({
    required this.kind,
    required this.isSelf,
    required this.cardIndex,
    required this.handStart,
    required this.discard,
    required this.previousDiscardTop,
    this.tappedTag,
    this.drawnTag,
    this.drawnStart,
    this.deckStart,
    this.handOrigin,
    this.drawnFaceUp = true,
  });

  final _CardActionKind kind;
  final bool isSelf;
  final int cardIndex;
  final Vector2 handStart;
  final Vector2 discard;
  final String? previousDiscardTop;
  final String? tappedTag;
  final String? drawnTag;
  final Vector2? drawnStart;
  final Vector2? deckStart;
  final Vector2? handOrigin;
  final bool drawnFaceUp;
}

class _PauseEffect extends Effect {
  _PauseEffect(double duration) : super(EffectController(duration: duration));

  @override
  void apply(double progress) {}
}

class _ZoomCueEffect extends Effect {
  _ZoomCueEffect({required this.onProgress, required this.onDone})
    : super(EffectController(duration: 3.2, curve: Curves.linear));

  final void Function(double value) onProgress;
  final VoidCallback onDone;
  bool _done = false;

  @override
  void apply(double progress) {
    onProgress(progress);
  }

  @override
  void onFinish() {
    if (_done) return;
    _done = true;
    onDone();
    super.onFinish();
  }
}
