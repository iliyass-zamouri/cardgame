import 'dart:io';
import 'dart:ui';

import 'package:cardgame/ui/flame/card_fonts.dart';
import 'package:cardgame/ui/flame/card_game.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await ensureCardFontsLoaded();
  });

  test('preview', () async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 1050, 300),
      Paint()..color = const Color(0xFFFFFFFF),
    );
    const tags = ['A13', 'C12', 'B11', 'D13', 'A14', 'B14'];
    for (var i = 0; i < tags.length; i++) {
      final card = PlayingCardComponent(
        cardIndex: i,
        tag: tags[i],
        visible: true,
        sizeOverride: Vector2(155, 225),
      );
      canvas.save();
      canvas.translate(25 + i * 175, 35);
      card.render(canvas);
      canvas.restore();
    }
    final image = await recorder.endRecording().toImage(1050, 300);
    final bytes = await image.toByteData(format: ImageByteFormat.png);
    File('/tmp/court.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });

  test('joker at reference scale', () async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 420, 287),
      Paint()..color = const Color(0xFFFFFFFF),
    );
    for (final (i, tag) in ['A14', 'B14'].indexed) {
      final card = PlayingCardComponent(
        cardIndex: i,
        tag: tag,
        visible: true,
        sizeOverride: Vector2(198, 287),
      );
      canvas.save();
      canvas.translate(i * 210.0, 0);
      card.render(canvas);
      canvas.restore();
    }
    final image = await recorder.endRecording().toImage(420, 287);
    final bytes = await image.toByteData(format: ImageByteFormat.png);
    File('/tmp/joker_mine.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });

  test('jack at reference scale', () async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 198, 287),
      Paint()..color = const Color(0xFFFFFFFF),
    );
    final card = PlayingCardComponent(
      cardIndex: 0,
      tag: 'B11',
      visible: true,
      sizeOverride: Vector2(198, 287),
    );
    card.render(canvas);
    final image = await recorder.endRecording().toImage(198, 287);
    final bytes = await image.toByteData(format: ImageByteFormat.png);
    File('/tmp/jack_mine.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });

  test('king at reference scale', () async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 198, 287),
      Paint()..color = const Color(0xFFFFFFFF),
    );
    final card = PlayingCardComponent(
      cardIndex: 0,
      tag: 'A13',
      visible: true,
      sizeOverride: Vector2(198, 287),
    );
    card.render(canvas);
    final image = await recorder.endRecording().toImage(198, 287);
    final bytes = await image.toByteData(format: ImageByteFormat.png);
    File('/tmp/king_mine.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}
