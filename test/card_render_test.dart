import 'dart:ui';

import 'package:cardgame/ui/flame/card_back_skins.dart';
import 'package:cardgame/ui/flame/card_game.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await CardBackSkins.ensureLoaded();
  });

  void renderCard(PlayingCardComponent card) {
    final recorder = PictureRecorder();
    card.render(Canvas(recorder));
    recorder.endRecording().dispose();
  }

  test('rasterized card art renders every face, back and size', () {
    final tags = [
      for (final suit in ['A', 'B', 'C', 'D'])
        for (var value = 1; value <= 13; value++) '$suit$value',
      'A14',
      'B14',
    ];
    final sizes = [Vector2(78, 112), Vector2(86, 124), Vector2(48, 70)];

    for (final size in sizes) {
      for (final tag in tags) {
        renderCard(
          PlayingCardComponent(
            cardIndex: 0,
            tag: tag,
            visible: true,
            sizeOverride: size,
          )..highlighted = tag.endsWith('1'),
        );
      }
      for (final skin in CardBackSkins.all) {
        renderCard(
          PlayingCardComponent(
            cardIndex: 0,
            tag: null,
            visible: false,
            sizeOverride: size,
            backSkinId: skin.id,
          ),
        );
      }
    }
  });

  test('hidden and partially faded cards still render', () {
    final card = PlayingCardComponent(cardIndex: 0, tag: 'C12', visible: true);
    renderCard(card..opacityOverride = 0);
    renderCard(card..opacityOverride = 0.5);
    renderCard(card..opacityOverride = 1);
  });
}
