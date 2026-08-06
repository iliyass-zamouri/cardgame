import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:flutter/material.dart';

/// Dark charcoal stage behind the oval table — matches the screenshot, not a
/// full-bleed felt photo.
class GameBackground extends StatelessWidget {
  final Widget child;
  const GameBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF101014),
            CasinoColors.bg,
            Color(0xFF070709),
          ],
        ),
      ),
      child: child,
    );
  }
}
