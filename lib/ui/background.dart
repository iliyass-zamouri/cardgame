import 'package:cardgame/gen/assets.gen.dart';
import 'package:flutter/material.dart';

const int _backgroundDecodeWidth = 1080;

class GameBackground extends StatelessWidget {
  final Widget child;
  const GameBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: ResizeImage(
            Assets.table.provider(),
            width: _backgroundDecodeWidth,
          ),
          fit: BoxFit.fitHeight,
        ),
      ),
      child: child,
    );
  }
}
