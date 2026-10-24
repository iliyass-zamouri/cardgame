import 'package:flutter/widgets.dart';

/// Desktop windows and landscape tablets: room to lay screens out side by
/// side instead of stretching the phone layout across the width.
abstract final class WideLayout {
  /// Below either size the phone layout is used. The height keeps phones in
  /// landscape on it.
  static const minWidth = 900.0;
  static const minHeight = 560.0;

  /// Widest the home page's content runs before centring with margins.
  static const contentMaxWidth = 1180.0;

  /// Widest a list or form page runs, so rows stay readable.
  static const readableMaxWidth = 760.0;

  static bool of(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.width >= minWidth && size.height >= minHeight;
  }
}

/// Centres [child] at no more than [maxWidth], filling the height, so a
/// wide window keeps it at a readable width over a full-bleed background.
class CenteredContent extends StatelessWidget {
  const CenteredContent({
    super.key,
    required this.child,
    this.maxWidth = WideLayout.readableMaxWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(width: maxWidth, height: double.infinity, child: child),
    );
  }
}
