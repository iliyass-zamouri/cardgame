import 'package:cardgame/ui/flame/card_game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Every card the server can deal, drawn with the same painter the board uses.
class DeckPreviewScreen extends StatelessWidget {
  const DeckPreviewScreen({super.key});

  static const _suits = ['A', 'B', 'C', 'D'];

  List<String?> get _tags => [
        for (final suit in _suits)
          for (var value = 1; value <= 13; value++) '$suit$value',
        'A14',
        'B14',
        null,
      ];

  @override
  Widget build(BuildContext context) {
    final tags = _tags;
    return Scaffold(
      appBar: AppBar(title: const Text('Deck')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tags.length,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 92,
          childAspectRatio: 78 / 112,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (context, index) => CustomPaint(
          painter: _CardPainter(tags[index]),
        ),
      ),
    );
  }
}

class _CardPainter extends CustomPainter {
  const _CardPainter(this.tag);

  final String? tag;

  @override
  void paint(Canvas canvas, Size size) {
    PlayingCardComponent(
      cardIndex: 0,
      tag: tag,
      visible: tag != null,
      sizeOverride: Vector2(size.width, size.height),
    ).render(canvas);
  }

  @override
  bool shouldRepaint(_CardPainter oldDelegate) => oldDelegate.tag != tag;
}
