import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cardgame/ui/flame/suit_shapes.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/theme/felt_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The felt as it was drawn before the weave was cached: one path per glyph.
void _referenceFelt(Canvas canvas, Rect rect, {double vignette = 0.55}) {
  canvas.drawRect(
    rect,
    Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.25),
        radius: 1.1,
        colors: [const Color(0xFF237A4F), CasinoColors.feltDeep, const Color(0xFF0A2618)],
        stops: const [0, 0.55, 1],
      ).createShader(rect),
  );

  canvas.save();
  canvas.clipRect(rect);
  const cell = 46.0;
  const glyph = 14.0;
  final paint = Paint()..color = Colors.black.withValues(alpha: 0.10);
  var row = 0;
  for (var y = rect.top - cell; y < rect.bottom + cell; y += cell, row++) {
    final shift = row.isOdd ? cell / 2 : 0.0;
    var col = 0;
    for (
      var x = rect.left - cell + shift;
      x < rect.right + cell;
      x += cell, col++
    ) {
      canvas.save();
      canvas.translate(x, y);
      canvas.scale(glyph);
      canvas.drawPath(suitPath(SuitShape.values[(row + col) % 4]), paint);
      canvas.restore();
    }
  }
  canvas.restore();

  canvas.drawRect(
    rect,
    Paint()
      ..shader = RadialGradient(
        radius: 0.95,
        colors: [Colors.transparent, Colors.black.withValues(alpha: vignette)],
        stops: const [0.55, 1],
      ).createShader(rect),
  );
}

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('cached felt weave draws the same felt as per-glyph paths', () async {
    // The tile is rasterized for the device's pixel ratio; compare there.
    final scale = ui.PlatformDispatcher.instance.implicitView!.devicePixelRatio
        .clamp(1.0, 3.0);

    for (final (rect, vignette) in [
      // A full phone screen.
      (const Rect.fromLTWH(0, 0, 390, 844), 0.55),
      // An inset felt, like the in-game table, so the weave origin moves.
      (const Rect.fromLTWH(13, 27, 301, 455), 0.3),
    ]) {
      final size = Size(rect.right + 7, rect.bottom + 9);
      final expected = await _render(
        (canvas) => _referenceFelt(canvas, rect, vignette: vignette),
        size,
        scale,
      );
      final actual = await _render(
        (canvas) => paintFeltTexture(canvas, rect, vignette: vignette),
        size,
        scale,
      );

      expect(actual.length, expected.length);
      var maxDelta = 0;
      for (var i = 0; i < expected.length; i++) {
        final delta = (actual[i] - expected[i]).abs();
        if (delta > maxDelta) maxDelta = delta;
      }
      // Only compositing round-off may differ; a misplaced or missing glyph
      // shifts pixels by 10 or more.
      expect(maxDelta, lessThanOrEqualTo(3), reason: 'felt in $rect');
    }
  });
}
