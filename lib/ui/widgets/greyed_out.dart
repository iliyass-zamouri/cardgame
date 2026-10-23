import 'package:flutter/material.dart';

/// Greys out [child] and ignores taps while [enabled] is false.
class GreyedOut extends StatelessWidget {
  const GreyedOut({super.key, required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  /// Rec. 709 luma weights, so colour drops out to grey.
  static const _greyscale = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0, //
  ]);

  @override
  Widget build(BuildContext context) {
    if (enabled) return child;
    return IgnorePointer(
      child: ColorFiltered(
        colorFilter: _greyscale,
        child: Opacity(opacity: 0.6, child: child),
      ),
    );
  }
}
