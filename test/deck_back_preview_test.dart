import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cardgame/ui/flame/card_back_skins.dart';
import 'package:cardgame/ui/widgets/deck_fan_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<Uint8List> _render(
  void Function(Canvas canvas) paint,
  Size size,
  double scale,
) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..scale(scale);
  paint(canvas);
  final picture = recorder.endRecording();
  final image = await picture.toImage(
    (size.width * scale).round(),
    (size.height * scale).round(),
  );
  picture.dispose();
  final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  image.dispose();
  return bytes!.buffer.asUint8List();
}

/// The back as the preview drew it before caching: live vector ops.
void _paintLive(Canvas canvas, Size size, CardBackSkin skin) {
  canvas.save();
  canvas.clipRRect(
    RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.width * 0.1),
    ),
  );
  canvas.scale(size.width);
  skin.paintUnit(canvas, size.height / size.width);
  canvas.restore();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('cached vector deck backs match live painting', () async {
    const scale = 3.0;
    const size = Size(78, 112);
    final vectorSkins = CardBackSkins.all.where(
      (skin) => skin.repaintListenable == null,
    );
    expect(vectorSkins, isNotEmpty);

    for (final skin in vectorSkins) {
      final painter = DeckBackPreviewPainter(skin.id, devicePixelRatio: scale);
      // Twice: the second paint comes from the cache.
      for (var pass = 0; pass < 2; pass++) {
        final expected = await _render(
          (canvas) => _paintLive(canvas, size, skin),
          size,
          scale,
        );
        final actual = await _render(
          (canvas) => painter.paint(canvas, size),
          size,
          scale,
        );
        var maxDelta = 0;
        for (var i = 0; i < expected.length; i++) {
          final delta = (actual[i] - expected[i]).abs();
          if (delta > maxDelta) maxDelta = delta;
        }
        expect(maxDelta, lessThanOrEqualTo(3), reason: '${skin.id} pass $pass');
      }
    }
  });
}
