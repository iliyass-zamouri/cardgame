import 'package:cardgame/domain/models/game_snapshot.dart';
import 'package:flutter/material.dart';
import 'package:patterns_canvas/patterns_canvas.dart';
import 'package:playing_cards/playing_cards.dart';

const shadowDecoration = BoxDecoration(
  boxShadow: [
    BoxShadow(
      color: Color.fromRGBO(50, 50, 93, 0.25),
      offset: Offset(0, 30),
      blurRadius: 60,
      spreadRadius: -12,
    ),
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.3),
      offset: Offset(0, 18),
      blurRadius: 36,
      spreadRadius: -18,
    ),
  ],
);

class PlayerHandView extends StatelessWidget {
  final List<CardSnapshot> cards;
  final bool isSelf;
  final bool isTurn;
  final void Function(int cardIndex)? onTap;

  const PlayerHandView({
    super.key,
    required this.cards,
    required this.isSelf,
    required this.isTurn,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: isTurn
          ? BoxDecoration(
              gradient: LinearGradient(
                begin: isSelf
                    ? Alignment.bottomCenter
                    : Alignment.topCenter,
                end: isSelf
                    ? Alignment.topCenter
                    : Alignment.bottomCenter,
                colors: const [
                  Colors.white,
                  Color.fromARGB(0, 255, 255, 255),
                  Color.fromARGB(0, 255, 255, 255),
                  Color.fromARGB(0, 255, 255, 255),
                ],
              ),
            )
          : const BoxDecoration(),
      child: Center(
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          reverse: !isSelf,
          itemCount: cards.length,
          itemBuilder: (context, index) {
            final card = cards[index];
            return InkWell(
              key: ValueKey(card.index),
              onTap: onTap == null ? null : () => onTap!(card.index),
              child: FittedBox(
                child: SizedBox(
                  width: 140,
                  child: DecoratedBox(
                    decoration: shadowDecoration,
                    child: PlayingCardView(
                      card: card.card.card,
                      showBack: !card.visible,
                      style: PlayingCardViewStyle(
                        cardBackContentBuilder: (context) {
                          return const PCardPattern();
                        },
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class PCardPattern extends StatelessWidget {
  const PCardPattern({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.red.shade900, width: 4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ClipRRect(
        child: CustomPaint(
          painter: PatternPainter(),
        ),
      ),
    );
  }
}

class PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final pattern = DiagonalStripesThick(
      bgColor: Colors.white,
      fgColor: Colors.red.shade900,
    );
    pattern.paintOnCanvas(canvas, size);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
