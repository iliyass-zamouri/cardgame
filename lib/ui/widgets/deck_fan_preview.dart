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
      painter: DeckBackPreviewPainter(skinId),
      child: const SizedBox.expand(),
    );
  }
}

class DeckBackPreviewPainter extends CustomPainter {
  DeckBackPreviewPainter(this.skinId);

  final String skinId;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.width * 0.1),
    );
    canvas.save();
    canvas.clipRRect(rect);
    canvas.scale(size.width);
    CardBackSkins.byId(skinId).paintUnit(canvas, size.height / size.width);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant DeckBackPreviewPainter oldDelegate) =>
      oldDelegate.skinId != skinId;
}
