import 'package:cardgame/ui/flame/card_game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// A board card (same art as the Flame table) as a plain Flutter widget.
/// [faceUp] false draws the card back.
class PlayingCardFace extends StatelessWidget {
  const PlayingCardFace({
    super.key,
    required this.tag,
    required this.width,
    this.faceUp = true,
  });

  /// Card aspect ratio used on the board (78 × 112).
  static const aspect = 112 / 78;

  final String? tag;
  final double width;
  final bool faceUp;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: width * aspect,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(width * 0.09),
        boxShadow: const [
          BoxShadow(color: Color(0x40000000), blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: CustomPaint(painter: _CardPainter(tag, faceUp)),
    );
  }
}

class _CardPainter extends CustomPainter {
  const _CardPainter(this.tag, this.faceUp);

  final String? tag;
  final bool faceUp;

  @override
  void paint(Canvas canvas, Size size) {
    PlayingCardComponent(
      cardIndex: 0,
      tag: faceUp ? tag : null,
      visible: faceUp && tag != null,
      sizeOverride: Vector2(size.width, size.height),
    ).render(canvas);
  }

  @override
  bool shouldRepaint(_CardPainter oldDelegate) =>
      oldDelegate.tag != tag || oldDelegate.faceUp != faceUp;
}
