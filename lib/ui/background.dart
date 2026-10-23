import 'package:cardgame/ui/theme/felt_chrome.dart';
import 'package:flutter/material.dart';

/// App-wide stage: the green felt card table behind every root screen. It stays
/// still under Halloween, since screens that paint their own felt animate.
class GameBackground extends StatelessWidget {
  final Widget child;
  const GameBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return FeltTableBackground(animated: false, child: child);
  }
}
