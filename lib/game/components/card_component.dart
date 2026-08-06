import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../painters/camo_card_painter.dart';

class CardComponent extends PositionComponent with TapCallbacks {
  CardComponent({
    required this.tag,
    required this.faceUp,
    this.onTap,
    Vector2? size,
  }) : super(size: size ?? Vector2(120, 168));

  final String tag;
  final bool faceUp;
  final VoidCallback? onTap;

  @override
  void onTapUp(TapUpEvent event) {
    onTap?.call();
  }

  @override
  void render(Canvas canvas) {
    CamoCardPainter.paintCard(
      canvas: canvas,
      rect: size.toRect(),
      tag: tag,
      faceUp: faceUp,
    );
  }
}
