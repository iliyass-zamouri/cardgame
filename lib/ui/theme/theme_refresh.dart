import 'package:flutter/widgets.dart';

/// Repaints the whole UI after [AppTheme.activate].
///
/// A parent rebuild skips a `const` child, and a painter whose shouldRepaint
/// returns false is never repainted, so this marks every element for build
/// and every render object for paint. Call it outside build and paint.
void refreshEntireUi(BuildContext context) {
  void mark(Element element) {
    element.markNeedsBuild();
    if (element is RenderObjectElement) {
      element.renderObject.markNeedsPaint();
    }
    element.visitChildren(mark);
  }

  mark(context as Element);
}
