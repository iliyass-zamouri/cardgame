import 'package:cardgame/l10n/l10n_ext.dart';
import 'package:cardgame/ui/flame/card_game.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Every card the server can deal, drawn with the same painter the board uses.
class DeckPreviewScreen extends StatelessWidget {
  const DeckPreviewScreen({
    super.key,
    this.title,
    this.backSkinId = 'ornate_blue',
  });

  final String? title;
  final String backSkinId;

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
      backgroundColor: CasinoColors.bg,
      appBar: AppBar(
        backgroundColor: CasinoColors.surface,
        foregroundColor: CasinoColors.text,
        title: Text(
          title ?? context.l10n.deck,
          style: const TextStyle(
            color: CasinoColors.gold,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tags.length,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 92,
          childAspectRatio: 78 / 112,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemBuilder:
            (context, index) => CustomPaint(
              painter: _CardPainter(tags[index], backSkinId: backSkinId),
            ),
      ),
    );
  }
}

class _CardPainter extends CustomPainter {
  const _CardPainter(this.tag, {required this.backSkinId});

  final String? tag;
  final String backSkinId;

  @override
  void paint(Canvas canvas, Size size) {
    PlayingCardComponent(
      cardIndex: 0,
      tag: tag,
      visible: tag != null,
      sizeOverride: Vector2(size.width, size.height),
      backSkinId: backSkinId,
    ).render(canvas);
  }

  @override
  bool shouldRepaint(_CardPainter oldDelegate) =>
      oldDelegate.tag != tag || oldDelegate.backSkinId != backSkinId;
}
