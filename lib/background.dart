import 'package:cardgame/gen/assets.gen.dart';
import 'package:flutter/material.dart';

class GameBackground extends StatelessWidget {
  final Widget child;
  const GameBackground({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
          image: DecorationImage(
              image: Assets.table.provider(),
              // colorFilter:
              //     const ColorFilter.mode(Colors.black45, BlendMode.darken),
              fit: BoxFit.fitHeight)),
      child: child,
    );
  }
}
