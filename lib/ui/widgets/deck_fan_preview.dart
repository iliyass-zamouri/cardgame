import 'dart:ui' as ui;

import 'package:cardgame/ui/flame/card_back_skins.dart';
import 'package:flutter/material.dart';

/// Fanned card-backs preview (marketplace list + profile hero).
class DeckFanPreview extends StatelessWidget {
  const DeckFanPreview({
    super.key,
    required this.skinId,
    this.cardWidth = 108,
    this.count = 5,
    this.spread = 16,
    this.tilt = 0.06,
    this.heightPadding = 16,
  });

  final String skinId;
  final double cardWidth;
  final int count;
  final double spread;
  final double tilt;
  final double heightPadding;

  double get _cardHeight => cardWidth * 112 / 78;

  @override
  Widget build(BuildContext context) {
    final radius = (cardWidth * 0.11).clamp(6.0, 12.0);
    return SizedBox(
      height: _cardHeight + heightPadding,
      width: cardWidth + spread * (count - 1),
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (var i = 0; i < count; i++)
            Transform.translate(
              offset: Offset((i - (count - 1) / 2) * spread, 0),
              child: Transform.rotate(
                angle: (i - (count - 1) / 2) * tilt,
                child: Container(
                  width: cardWidth,
                  height: _cardHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(radius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.42),
                        blurRadius: cardWidth < 70 ? 4 : 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: DeckBackPreview(skinId: skinId),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class DeckBackPreview extends StatelessWidget {
  const DeckBackPreview({super.key, required this.skinId});

  final String skinId;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DeckBackPreviewPainter(
        skinId,
        devicePixelRatio: MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.0,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class DeckBackPreviewPainter extends CustomPainter {
  DeckBackPreviewPainter(this.skinId, {this.devicePixelRatio = 2.0})
    : super(repaint: CardBackSkins.byId(skinId).repaintListenable);

  final String skinId;
  final double devicePixelRatio;

  static final Paint _imagePaint =
      Paint()..filterQuality = FilterQuality.medium;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final skin = CardBackSkins.byId(skinId);
    // Plate skins already paint one bitmap and may still be decoding, so
    // they stay live; vector skins are hundreds of ops, so they are cached.
    if (skin.repaintListenable != null) {
      _paintBack(canvas, size, skin);
      return;
    }
    final image = _DeckBackRaster.of(skin, size, devicePixelRatio);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Offset.zero & size,
      _imagePaint,
    );
  }

  @override
  bool shouldRepaint(covariant DeckBackPreviewPainter oldDelegate) =>
      oldDelegate.skinId != skinId ||
      oldDelegate.devicePixelRatio != devicePixelRatio;
}

void _paintBack(Canvas canvas, Size size, CardBackSkin skin) {
  final rect = RRect.fromRectAndRadius(
    Offset.zero & size,
    Radius.circular(size.width * 0.1),
  );
  canvas.save();
  canvas.clipRRect(rect);
  canvas.scale(size.width);
  skin.paintUnit(canvas, size.height / size.width);
  canvas.restore();
}

/// Vector card backs rasterized once per skin and pixel size.
///
/// The ornate backs are hundreds of path and stroke ops each. Replaying them
/// live re-ran all of that on every frame of the home fan's idle bob, of a
/// route transition and of a shop or collection scroll, since Impeller has
/// no raster cache. The game board caches its cards the same way.
abstract final class _DeckBackRaster {
  /// Bounded so cycling through skins and sizes cannot grow texture memory
  /// without limit. Comfortably above one screen's working set.
  static const _maxImages = 32;

  static final Map<String, ui.Image> _images = <String, ui.Image>{};

  static ui.Image of(CardBackSkin skin, Size size, double devicePixelRatio) {
    // Past 3x the extra texels are invisible at preview sizes.
    final scale = devicePixelRatio.clamp(1.0, 3.0);
    final width = (size.width * scale).ceil();
    final height = (size.height * scale).ceil();
    final key = '${skin.id}|$width|$height';
    final cached = _images.remove(key);
    if (cached != null) {
      // Re-insert to mark most recently used.
      return _images[key] = cached;
    }
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)
      ..scale(width / size.width, height / size.height);
    _paintBack(canvas, size, skin);
    final picture = recorder.endRecording();
    final image = picture.toImageSync(width, height);
    picture.dispose();
    _images[key] = image;
    if (_images.length > _maxImages) {
      // Drop the reference only; frames already recorded keep their own
      // handle, and the finalizer frees the texture once nothing uses it.
      _images.remove(_images.keys.first);
    }
    return image;
  }
}
