import 'package:cardgame/domain/models/game_snapshot.dart';
import 'package:cardgame/ui/flame/card_game.dart';
import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('discard mid-hand must not reuse opacity-0 shell', () async {
    final game = FlameGame();
    await game.onLoad();
    final hand = HandArea(isSelf: true);
    game.world.add(hand);
    await game.ready();

    hand.syncCards(
      const [
        CardSnapshot(index: 0, tag: null, visible: false),
        CardSnapshot(index: 1, tag: null, visible: false),
        CardSnapshot(index: 2, tag: null, visible: false),
        CardSnapshot(index: 3, tag: null, visible: false),
      ],
      highlight: false,
      onTap: null,
      animateDeal: false,
      peekIndices: const {},
    );

    final discarded = hand.cardAt(1)!;
    discarded.opacityOverride = 0;

    hand.syncCards(
      const [
        CardSnapshot(index: 0, tag: null, visible: false),
        CardSnapshot(index: 1, tag: null, visible: false),
        CardSnapshot(index: 2, tag: null, visible: false),
      ],
      highlight: false,
      onTap: null,
      animateDeal: false,
      peekIndices: const {},
    );

    final kept = hand.cards;
    expect(kept.length, 3);
    expect(
      kept.any((c) => identical(c, discarded)),
      isFalse,
      reason: 'opacity-0 discarded shell must not be reused',
    );
    expect(kept.every((c) => c.opacityOverride >= 1), isTrue);
  });
}
