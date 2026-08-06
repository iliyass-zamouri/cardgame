import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

/// App loading indicator — `discreteCircle` (white base + casino accents).
class SuitCardLoader extends StatelessWidget {
  const SuitCardLoader({
    super.key,
    this.height = 28,
    this.color = Colors.white,
  });

  final double height;

  /// Base ring color (defaults white).
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LoadingAnimationWidget.discreteCircle(
      color: color,
      secondRingColor: CasinoColors.gold,
      thirdRingColor: CasinoColors.raiseHi,
      size: height,
    );
  }
}
