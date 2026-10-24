import 'package:cardgame/ui/flame/suit_shapes.dart';
import 'package:cardgame/ui/theme/app_icons.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/theme/felt_chrome.dart';
import 'package:flutter/material.dart';

/// Opens a reward modal: the page scales up out of the table with a slight
/// overshoot, over a dark scrim.
Future<T?> showRewardDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.72),
    transitionDuration: const Duration(milliseconds: 420),
    pageBuilder: (context, _, _) => builder(context),
    transitionBuilder: (context, animation, _, child) {
      if (MediaQuery.disableAnimationsOf(context)) return child;
      final scale = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.86, end: 1).animate(scale),
          child: child,
        ),
      );
    },
  );
}

/// Leather panel with a gold rim, its title on a ribbon across the top edge
/// and a close button, centred and kept inside the safe area.
class RewardPanel extends StatelessWidget {
  const RewardPanel({
    super.key,
    required this.title,
    required this.child,
    this.onClose,
    this.maxWidth = 420,
  });

  final String title;
  final Widget child;

  /// Null hides the close button (while a claim is running).
  final VoidCallback? onClose;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final maxHeight = media.size.height - media.padding.vertical - 20;
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              maxHeight: maxHeight,
            ),
            child: Material(
              type: MaterialType.transparency,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 22),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF3A2416),
                          CasinoColors.leather,
                          CasinoColors.leatherDeep,
                        ],
                      ),
                      border: Border.all(
                        color: CasinoColors.gold.withValues(alpha: 0.75),
                        width: 1.4,
                      ),
                      boxShadow: [
                        const BoxShadow(
                          color: Color(0xB3000000),
                          blurRadius: 30,
                          offset: Offset(0, 14),
                        ),
                        BoxShadow(
                          color: CasinoColors.gold.withValues(alpha: 0.16),
                          blurRadius: 26,
                        ),
                      ],
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: CasinoColors.gold.withValues(alpha: 0.18),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(10, 36, 10, 12),
                      child: child,
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 40,
                    right: 40,
                    child: Center(child: TitleRibbon(title: title)),
                  ),
                  if (onClose != null)
                    PositionedDirectional(
                      top: 30,
                      end: 8,
                      child: FeltIconButton(
                        icon: AppIcons.close,
                        size: 32,
                        tooltip:
                            MaterialLocalizations.of(
                              context,
                            ).closeButtonTooltip,
                        onTap: onClose,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Gold banner with folded tails and suit pips, like a casino marquee.
class TitleRibbon extends StatelessWidget {
  const TitleRibbon({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    const ink = Color(0xFF3A2A06);
    return CustomPaint(
      painter: const _RibbonPainter(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(36, 9, 36, 13),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SuitGlyph(suit: SuitShape.spades, size: 11, color: ink),
            const SizedBox(width: 8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  casinoButtonLabel(title, locale),
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: CasinoFonts.displayFor(locale),
                    color: ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: locale.languageCode == 'ar' ? 0 : 1.6,
                    height: 1.1,
                    shadows: const [
                      Shadow(color: Color(0x66FFF6C8), offset: Offset(0, 1)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const SuitGlyph(suit: SuitShape.hearts, size: 11, color: ink),
          ],
        ),
      ),
    );
  }
}

class _RibbonPainter extends CustomPainter {
  const _RibbonPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const tail = 22.0;
    final bandBottom = h - 5;
    final tailPaint = Paint()..color = const Color(0xFF8A6512);
    final foldPaint = Paint()..color = const Color(0xFF5E430A);

    // Notched tails behind both ends, then the fold where each tucks under.
    for (final mirror in [false, true]) {
      double x(double v) => mirror ? w - v : v;
      canvas.drawPath(
        Path()
          ..moveTo(x(-4), h * 0.3)
          ..lineTo(x(tail + 6), h * 0.3)
          ..lineTo(x(tail + 6), h)
          ..lineTo(x(-4), h)
          ..lineTo(x(8), h * 0.65)
          ..close(),
        tailPaint,
      );
      canvas.drawPath(
        Path()
          ..moveTo(x(tail), bandBottom)
          ..lineTo(x(tail + 6), h)
          ..lineTo(x(tail + 6), bandBottom)
          ..close(),
        foldPaint,
      );
    }

    final band = RRect.fromRectAndRadius(
      Rect.fromLTRB(tail, 0, w - tail, bandBottom),
      const Radius.circular(6),
    );
    canvas.drawRRect(
      band.shift(const Offset(0, 3)),
      Paint()..color = const Color(0x66000000),
    );
    canvas.drawRRect(
      band,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFEDA8), Color(0xFFF5C542), Color(0xFFC8961E)],
          stops: [0, 0.5, 1],
        ).createShader(band.outerRect),
    );
    canvas.drawRRect(
      band,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xFF7A5A0E),
    );
    // Stitched hairline just inside the band.
    canvas.drawRRect(
      band.deflate(3.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = const Color(0xFF7A5A0E).withValues(alpha: 0.45),
    );
  }

  @override
  bool shouldRepaint(covariant _RibbonPainter oldDelegate) => false;
}

/// Mini felt table the day cards are dealt onto.
class FeltInset extends StatelessWidget {
  const FeltInset({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(10),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CasinoColors.gold.withValues(alpha: 0.3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x80000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: CustomPaint(
          painter: const _InsetFeltPainter(),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class _InsetFeltPainter extends CustomPainter {
  const _InsetFeltPainter();

  @override
  void paint(Canvas canvas, Size size) =>
      paintFeltTexture(canvas, Offset.zero & size, vignette: 0.45);

  @override
  bool shouldRepaint(covariant _InsetFeltPainter oldDelegate) => false;
}
