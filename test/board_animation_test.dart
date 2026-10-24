import 'dart:math' as math;

import 'package:cardgame/domain/models/game_snapshot.dart';
import 'package:cardgame/ui/flame/card_back_skins.dart';
import 'package:cardgame/ui/flame/card_game.dart';
import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';

const _frame = Duration(milliseconds: 16);

/// Mounts [game] in a real [GameWidget] so components mount and effects
/// resolve their targets the way they do in the app.
Future<void> _mount(WidgetTester tester, FlameGame game) async {
  await tester.pumpWidget(GameWidget(game: game));
  await _settleLifecycle(tester);
}

/// A few frames for queued adds (and their onLoad children) to mount.
Future<void> _settleLifecycle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(_frame);
  }
}

/// Pumps frames for [seconds], returning the largest value [probe] reported.
Future<double> _run(
  WidgetTester tester,
  double seconds, [
  double Function()? probe,
]) async {
  var peak = double.negativeInfinity;
  final frames = (seconds * 1000 / _frame.inMilliseconds).ceil();
  for (var i = 0; i < frames; i++) {
    await tester.pump(_frame);
    if (probe != null) peak = math.max(peak, probe());
  }
  return peak;
}

GameSnapshot _snapshot({
  required int version,
  String? discardTop,
  String? discardSource,
  String? myDrawn,
  bool opponentHasDrawn = false,
}) {
  const hidden = [
    CardSnapshot(index: 0, tag: null, visible: false),
    CardSnapshot(index: 1, tag: null, visible: false),
    CardSnapshot(index: 2, tag: null, visible: false),
    CardSnapshot(index: 3, tag: null, visible: false),
  ];
  return GameSnapshot(
    roomId: 'room-1',
    version: version,
    status: GameStatus.playing,
    ready: true,
    deckCount: 30,
    discardTopTag: discardTop,
    discardRecentTags: [if (discardTop != null) discardTop],
    discardSource: discardSource,
    isYourTurn: true,
    you: PlayerSnapshot(
      connected: true,
      displayName: 'Alice',
      playerId: 'guest-1',
      launch: LaunchStatus.ended,
      total: 0,
      cards: hidden,
      handCardTag: myDrawn,
      hasHandCard: myDrawn != null,
    ),
    opponent: PlayerSnapshot(
      connected: true,
      displayName: 'Bob',
      playerId: 'guest-2',
      launch: LaunchStatus.ended,
      total: 0,
      cards: hidden,
      handCardTag: null,
      hasHandCard: opponentHasDrawn,
    ),
    result: null,
    lastAction: null,
  );
}

PlayingCardComponent _pileOf(CardGame game) => game.world.children
    .whereType<TableArea>()
    .single
    .children
    .whereType<PlayingCardComponent>()
    .firstWhere((card) => card.cardIndex == -2);

void main() {
  setUpAll(() async {
    await CardBackSkins.ensureLoaded();
  });

  group('discard pile', () {
    late TableArea table;

    PlayingCardComponent pile() => table.children
        .whereType<PlayingCardComponent>()
        .firstWhere((card) => card.cardIndex == -2);

    void sync(String? top) => table.sync(
      deckCount: 30,
      discardTag: top,
      canDraw: false,
      deckBackSkinId: 'ornate_blue',
      discardBackSkinId: 'ornate_blue',
    );

    Future<void> mountTable(WidgetTester tester) async {
      final game = FlameGame();
      await _mount(tester, game);
      table = TableArea(onDraw: () {});
      game.world.add(table);
      await _settleLifecycle(tester);
      sync('A5');
      await _run(tester, 1);
    }

    testWidgets('a thrown card landing never leaves the pile zoomed in', (
      tester,
    ) async {
      await mountTable(tester);

      table.holdDiscard('A5', pendingTag: 'B7');
      // The ghost lands, then the post-action sync runs before the next tick.
      table.releaseDiscard();
      sync('B7');

      final peak = await _run(tester, 1, () => pile().scale.x);
      expect(peak, lessThanOrEqualTo(1 + 1e-6));
      expect(pile().scale.x, closeTo(1, 1e-6));
      expect(pile().shownTag, 'B7');
    });

    testWidgets('a new top with no ghost settles in without overshooting', (
      tester,
    ) async {
      await mountTable(tester);

      sync('C3');

      expect(pile().shownTag, 'C3', reason: 'the pile never flips');
      final peak = await _run(tester, 1, () => pile().scale.x);
      expect(peak, lessThanOrEqualTo(1 + 1e-6));
      expect(pile().scale.x, closeTo(1, 1e-6));
    });
  });

  group('card tweens started before the same tick', () {
    late PlayingCardComponent card;

    Future<void> mountCard(WidgetTester tester) async {
      final game = FlameGame();
      await _mount(tester, game);
      card = PlayingCardComponent(cardIndex: 0, tag: null, visible: false);
      game.world.add(card);
      await _settleLifecycle(tester);
    }

    testWidgets('a repeated pop does not stack', (tester) async {
      await mountCard(tester);

      card
        ..snapScale(0.7)
        ..scaleTo(1)
        ..snapScale(0.7)
        ..scaleTo(1);

      final peak = await _run(tester, 1, () => card.scale.x);
      expect(peak, lessThanOrEqualTo(1 + 1e-6));
      expect(card.scale.x, closeTo(1, 1e-6));
    });

    testWidgets('a reveal wins over a flip queued just before it', (
      tester,
    ) async {
      await mountCard(tester);

      card
        ..flipTo(tag: 'C3', visible: true, sfx: false)
        ..reveal(tag: 'D9', visible: true);

      await _run(tester, 1);
      expect(card.tag, 'D9');
      expect(card.shownTag, 'D9');
    });

    testWidgets('a snap wins over a move queued just before it', (
      tester,
    ) async {
      await mountCard(tester);

      card
        ..moveTo(Vector2(100, 0))
        ..snapTo(Vector2(-50, 20));

      await _run(tester, 1);
      expect(card.position.x, closeTo(-50, 1e-6));
      expect(card.position.y, closeTo(20, 1e-6));
    });
  });

  group('a full throw through the board', () {
    testWidgets('my drawn card goes straight to the pile at full size', (
      tester,
    ) async {
      final game = CardGame();
      await _mount(tester, game);
      game.applySnapshot(_snapshot(version: 1, discardTop: 'A5', myDrawn: 'B7'));
      await _run(tester, 2);

      game.applySnapshot(
        _snapshot(version: 2, discardTop: 'B7', discardSource: 'drawn'),
      );
      final pile = _pileOf(game);
      final peak = await _run(tester, 0.6, () => pile.scale.x);

      expect(pile.shownTag, 'B7', reason: 'landed within the quick throw');
      expect(peak, lessThanOrEqualTo(1 + 1e-6));
      expect(pile.scale.x, closeTo(1, 1e-6));
    });

    testWidgets('an opponent throw lifts to read, then lands at full size', (
      tester,
    ) async {
      final game = CardGame();
      await _mount(tester, game);
      game.applySnapshot(
        _snapshot(version: 1, discardTop: 'A5', opponentHasDrawn: true),
      );
      await _run(tester, 2);

      game.applySnapshot(
        _snapshot(version: 2, discardTop: 'B7', discardSource: 'drawn'),
      );
      final pile = _pileOf(game);
      await _run(tester, 0.6);
      expect(pile.shownTag, 'A5', reason: 'still lifted for reading');

      final peak = await _run(tester, 2, () => pile.scale.x);
      expect(pile.shownTag, 'B7');
      expect(peak, lessThanOrEqualTo(1 + 1e-6));
      expect(pile.scale.x, closeTo(1, 1e-6));
    });
  });

  testWidgets('the board loop sleeps when still and wakes for an update', (
    tester,
  ) async {
    final game = CardGame();
    await _mount(tester, game);

    game.applySnapshot(_snapshot(version: 1, discardTop: 'A2'));
    await _run(tester, 0.05);
    expect(game.paused, isFalse, reason: 'the deal is still animating');

    await _run(tester, 3);
    expect(game.paused, isTrue);

    game.applySnapshot(_snapshot(version: 2, discardTop: 'A2'));
    expect(game.paused, isFalse);
    await _run(tester, 3);
    expect(game.paused, isTrue);
  });
}
