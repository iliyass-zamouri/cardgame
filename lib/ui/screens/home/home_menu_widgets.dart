import 'dart:async';
import 'dart:math' as math;

import 'package:cardgame/ui/flame/suit_shapes.dart';
import 'package:cardgame/ui/screens/home/nav_art.dart';
import 'package:cardgame/ui/theme/felt_chrome.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/widgets/deck_fan_preview.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// Plays a "dealt onto the table" entrance after [delay].
class DealIn extends StatefulWidget {
  const DealIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.from = const Offset(0, 0.35),
    this.rotation = 0.0,
  });

  final Widget child;
  final Duration delay;
  final Offset from;
  final double rotation;

  @override
  State<DealIn> createState() => _DealInState();
}

class _DealInState extends State<DealIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  late final Animation<double> _t = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutBack,
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (context, child) {
        final inv = 1 - _t.value;
        return Opacity(
          opacity: _controller.value,
          child: FractionalTranslation(
            translation: widget.from * inv,
            child: Transform.rotate(angle: widget.rotation * inv, child: child),
          ),
        );
      },
    );
  }
}

/// Hand of cards fanned out: equipped deck backs revealing two aces.
class HeroCardFan extends StatefulWidget {
  const HeroCardFan({
    super.key,
    required this.deckSkinId,
    required this.height,
  });

  final String deckSkinId;
  final double height;

  @override
  State<HeroCardFan> createState() => _HeroCardFanState();
}

class _HeroCardFanState extends State<HeroCardFan>
    with TickerProviderStateMixin {
  // Faces by fan slot (left to right); null is a deck back.
  static const _hand = <SuitShape?>[
    null,
    null,
    SuitShape.spades,
    SuitShape.hearts,
    null,
  ];
  // Paint order keeps the two aces on top of the fan.
  static const _paintOrder = [0, 1, 4, 2, 3];

  late final AnimationController _spread = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Idle bobbing is decorative; honour the OS reduce-motion setting.
    if (MediaQuery.disableAnimationsOf(context)) {
      _float.stop();
    } else if (!_float.isAnimating) {
      _float.repeat();
    }
  }

  @override
  void dispose() {
    _spread.dispose();
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Outer cards plus their tilt span roughly 3.2 card widths.
        final cardW = math.min(
          widget.height * 0.82 * 78 / 112,
          constraints.maxWidth / 3.2,
        );
        return _buildFan(cardW, cardW * 112 / 78);
      },
    );
  }

  Widget _buildFan(double cardW, double cardH) {
    final cards = [
      for (final suit in _hand)
        RepaintBoundary(
          child: SizedBox(
            width: cardW,
            height: cardH,
            child: _CardShell(
              child:
                  suit == null
                      ? DeckBackPreview(skinId: widget.deckSkinId)
                      : CustomPaint(
                        painter: _AceFacePainter(suit),
                        child: const SizedBox.expand(),
                      ),
            ),
          ),
        ),
    ];

    // The idle bob repaints every frame; its own layer keeps that from
    // repainting the rest of the home page with it.
    return RepaintBoundary(
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      CasinoColors.gold.withValues(alpha: 0.22),
                      Colors.transparent,
                    ],
                    stops: const [0, 0.7],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: AnimatedBuilder(
                animation: Listenable.merge([_spread, _float]),
                builder: (context, _) {
                  final s = Curves.easeOutCubic.transform(_spread.value);
                  final phase = _float.value * 2 * math.pi;
                  final bob = math.sin(phase) * 4;
                  return Stack(
                    alignment: Alignment.bottomCenter,
                    clipBehavior: Clip.none,
                    children: [
                      for (final i in _paintOrder)
                        Transform.translate(
                          offset: Offset(
                            (i - 2) * cardW * 0.42 * s,
                            -widget.height * 0.06 +
                                (i - 2).abs() * cardH * 0.04 * s +
                                bob * (i.isEven ? 1 : 0.7),
                          ),
                          child: Transform.rotate(
                            alignment: Alignment.bottomCenter,
                            angle:
                                (i - 2) * 0.16 * s +
                                math.sin(phase + i) * 0.012,
                            child: cards[i],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x73000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(10), child: child),
    );
  }
}

class _AceFacePainter extends CustomPainter {
  _AceFacePainter(this.suit);

  final SuitShape suit;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [CardInk.ivory, CardInk.ivoryShade],
        ).createShader(rect),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.deflate(w * 0.05),
        Radius.circular(w * 0.06),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = CardInk.goldLine.withValues(alpha: 0.6),
    );

    final color = suitColor(suit);
    final suitPaint = Paint()..color = color;
    final rank = TextPainter(
      text: TextSpan(
        text: 'A',
        style: TextStyle(
          fontFamily: CasinoFonts.display,
          fontWeight: FontWeight.w800,
          fontSize: w * 0.2,
          color: color,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final pip = w * 0.13;
    final x = w * 0.1;
    final y = w * 0.09;

    void corner() {
      rank.paint(canvas, Offset(x + (pip - rank.width) / 2, y));
      canvas.save();
      canvas.translate(x, y + rank.height + w * 0.02);
      canvas.scale(pip);
      canvas.drawPath(suitPath(suit), suitPaint);
      canvas.restore();
    }

    corner();
    canvas.save();
    canvas.translate(size.width, size.height);
    canvas.rotate(math.pi);
    corner();
    canvas.restore();

    final big = w * 0.5;
    canvas.save();
    canvas.translate((w - big) / 2, (size.height - big) / 2);
    canvas.scale(big);
    canvas.drawPath(suitPath(suit), suitPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AceFacePainter old) => old.suit != suit;
}

/// The big gold-trimmed card for the primary play action.
class PrimaryPlayCard extends StatelessWidget {
  const PrimaryPlayCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final List<List<dynamic>> icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 92,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [CasinoColors.goldHi, CasinoColors.gold, CasinoColors.goldLo],
          ),
          boxShadow: [
            BoxShadow(
              color: CasinoColors.gold.withValues(alpha: 0.35),
              blurRadius: 22,
              spreadRadius: -4,
            ),
            const BoxShadow(
              color: Color(0x80000000),
              blurRadius: 10,
              offset: Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF7A5A0E).withValues(alpha: 0.45),
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              end: -14,
              top: -10,
              child: SuitGlyph(
                suit: SuitShape.spades,
                size: 120,
                color: Colors.black.withValues(alpha: 0.08),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: CardInk.black,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x55000000),
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: HugeIcon(
                      icon: icon,
                      size: 26,
                      color: CasinoColors.gold,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            casinoButtonLabel(title, locale),
                            style: TextStyle(
                              fontFamily: CasinoFonts.displayFor(locale),
                              color: CardInk.black,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing:
                                  locale.languageCode == 'ar' ? 0 : 1.2,
                              height: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF4A3708),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SuitGlyph(suit: SuitShape.spades, size: 22),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ivory playing card used for secondary modes (create / join / robot).
class ModePlayingCard extends StatelessWidget {
  const ModePlayingCard({
    super.key,
    required this.label,
    required this.suit,
    required this.icon,
    required this.onTap,
    this.height = 132,
  });

  final String label;
  final SuitShape suit;
  final List<List<dynamic>> icon;
  final VoidCallback? onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    final color = suitColor(suit);
    final locale = Localizations.localeOf(context);
    final pip = SuitGlyph(suit: suit, size: 11);
    return Pressable(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [CardInk.ivory, CardInk.ivoryShade],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x80000000),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: CardInk.goldLine.withValues(alpha: 0.5)),
          ),
          child: Stack(
            children: [
              Positioned(top: 5, left: 5, child: pip),
              Positioned(
                bottom: 5,
                right: 5,
                child: Transform.rotate(angle: math.pi, child: pip),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withValues(alpha: 0.1),
                        border: Border.all(
                          color: color.withValues(alpha: 0.35),
                        ),
                      ),
                      child: HugeIcon(icon: icon, size: 20, color: color),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 32,
                      child: Center(
                        child: _WordFitText(
                          casinoButtonLabel(label, locale),
                          style: TextStyle(
                            fontFamily: CasinoFonts.uiFor(locale),
                            color: CardInk.black,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing:
                                locale.languageCode == 'ar' ? 0 : 0.6,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Two-line centered label that shrinks its font until the longest word fits
/// on one line, so long localized words never break mid-word.
class _WordFitText extends StatelessWidget {
  const _WordFitText(this.text, {required this.style});

  final String text;
  final TextStyle style;

  static const _minFontSize = 7.5;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final direction = Directionality.of(context);
        final scaler = MediaQuery.textScalerOf(context);
        final words = text.split(RegExp(r'\s+'));
        final baseSize = style.fontSize ?? 12;
        final baseSpacing = style.letterSpacing ?? 0;
        // Tracking shrinks with the font so tight labels stay legible.
        TextStyle at(double s) => style.copyWith(
          fontSize: s,
          letterSpacing: baseSpacing * s / baseSize,
        );
        var size = baseSize;
        // Small margin absorbs sub-pixel rounding in the real layout.
        bool fits(double s) => words.every((word) {
          final tp = TextPainter(
            text: TextSpan(text: word, style: at(s)),
            textDirection: direction,
            textScaler: scaler,
            maxLines: 1,
          )..layout();
          return tp.width <= constraints.maxWidth - 2;
        });
        while (size > _minFontSize && !fits(size)) {
          size -= 0.5;
        }
        return Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: at(size),
        );
      },
    );
  }
}

class RailDockItem {
  const RailDockItem({
    required this.art,
    required this.label,
    required this.onTap,
    this.badge = 0,
    this.selected = false,
  });

  final NavArt art;
  final String label;
  final VoidCallback onTap;
  final int badge;
  final bool selected;
}

/// Small rounded-square count bubble pinned to a corner of an icon.
class CountBadge extends StatelessWidget {
  const CountBadge({
    super.key,
    required this.count,
    this.color = const Color(0xFF3DB83A),
    this.borderColor = Colors.white,
  });

  final int count;
  final Color color;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 18),
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

/// Full-width bottom navigation whose top edge arcs gently from edge to
/// edge; a gold pointer on the arc slides to the highlighted tab.
class HomeNavBar extends StatefulWidget {
  const HomeNavBar({super.key, required this.items});

  final List<RailDockItem> items;

  static const barHeight = 76.0;

  /// How far the arc's ends sit below its crest.
  static const arcDrop = 16.0;

  /// Room above the crest for the selected-tab pointer.
  static const pointerHeight = 14.0;

  @override
  State<HomeNavBar> createState() => _HomeNavBarState();
}

class _HomeNavBarState extends State<HomeNavBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slide = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    value: 1,
  );
  final _tween = Tween<double>(begin: -1, end: -1);

  /// Selected slot in physical left-to-right order; fractional mid-slide and
  /// negative when no tab is highlighted.
  late final Animation<double> _slot = _tween.animate(
    CurvedAnimation(parent: _slide, curve: Curves.easeOutCubic),
  );
  int? _target;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncSelection();
  }

  @override
  void didUpdateWidget(HomeNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncSelection();
  }

  void _syncSelection() {
    final items = widget.items;
    final selected = items.indexWhere((item) => item.selected);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    // The painters work in physical left-to-right order.
    final target =
        selected < 0 || !rtl ? selected : items.length - 1 - selected;
    if (target == _target) return;
    final from = _slot.value;
    final animate =
        _target != null &&
        from >= 0 &&
        target >= 0 &&
        !MediaQuery.disableAnimationsOf(context);
    _target = target;
    _tween
      ..begin = animate ? from : target.toDouble()
      ..end = target.toDouble();
    if (animate) {
      _slide.forward(from: 0);
    } else {
      _slide.value = 1;
    }
  }

  @override
  void dispose() {
    _slide.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final count = widget.items.length;
    return SizedBox(
      height:
          HomeNavBar.pointerHeight +
          HomeNavBar.arcDrop +
          HomeNavBar.barHeight +
          bottom,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // The leather only repaints when the tab count or inset changes;
          // a slide repaints just the selection layer above it.
          IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _NavBarBodyPainter(count: count, bottomInset: bottom),
              ),
            ),
          ),
          IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _NavSelectionPainter(count: count, slot: _slot),
              ),
            ),
          ),
          // Only the leather swallows taps; the see-through strip above the
          // arc lets them reach the page underneath.
          const ClipPath(
            clipper: _NavBodyClipper(),
            child: ColoredBox(color: Colors.transparent),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: bottom),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final item in widget.items)
                  Expanded(child: _NavTile(item: item)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const _navCrest = HomeNavBar.pointerHeight;
const _navEnds = HomeNavBar.pointerHeight + HomeNavBar.arcDrop;

/// Height of the nav arc at [x]: a quadratic through both ends and the crest.
double _navArcY(double x, double width) {
  final t = (x / width).clamp(0.0, 1.0);
  return _navEnds - 4 * (_navEnds - _navCrest) * t * (1 - t);
}

Path _navArcEdge(double width) =>
    Path()
      ..moveTo(0, _navEnds)
      ..quadraticBezierTo(width / 2, 2 * _navCrest - _navEnds, width, _navEnds);

Path _navBody(Size size) =>
    _navArcEdge(size.width)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

class _NavBodyClipper extends CustomClipper<Path> {
  const _NavBodyClipper();

  @override
  Path getClip(Size size) => _navBody(size);

  @override
  bool shouldReclip(covariant _NavBodyClipper oldClipper) => false;
}

class _NavBarBodyPainter extends CustomPainter {
  _NavBarBodyPainter({required this.count, required this.bottomInset});

  final int count;
  final double bottomInset;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final slot = w / count;
    final body = _navBody(size);

    canvas.drawShadow(body, Colors.black, 8, false);
    canvas.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFF4A2C1B), CasinoColors.leather, CasinoColors.leatherDeep],
        ).createShader(Offset.zero & size),
    );

    // Dividers between tabs.
    final divider =
        Paint()
          ..color = Colors.black.withValues(alpha: 0.35)
          ..strokeWidth = 1.5;
    for (var i = 1; i < count; i++) {
      final x = i * slot;
      canvas.drawLine(
        Offset(x, _navArcY(x, w)),
        Offset(x, size.height - bottomInset),
        divider,
      );
    }

    canvas.drawPath(
      _navArcEdge(w),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = CasinoColors.gold.withValues(alpha: 0.8),
    );
  }

  @override
  bool shouldRepaint(covariant _NavBarBodyPainter old) =>
      old.count != count || old.bottomInset != bottomInset;
}

/// Lit panel behind the selected tab plus the gold pointer riding the arc
/// above it. Repaints straight from [slot], so a slide never rebuilds.
class _NavSelectionPainter extends CustomPainter {
  _NavSelectionPainter({required this.count, required this.slot})
    : super(repaint: slot);

  final int count;
  final Animation<double> slot;

  @override
  void paint(Canvas canvas, Size size) {
    final position = slot.value;
    if (position < 0) return;
    final slotWidth = size.width / count;

    canvas.save();
    canvas.clipPath(_navBody(size));
    canvas.drawRect(
      Rect.fromLTWH(position * slotWidth, 0, slotWidth, size.height),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            CasinoColors.gold.withValues(alpha: 0.24),
            CasinoColors.gold.withValues(alpha: 0.06),
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.restore();

    _paintPointer(canvas, size, (position + 0.5) * slotWidth, slotWidth);
  }

  /// Gold band riding the arc centred on [cx], peaked in the middle.
  void _paintPointer(Canvas canvas, Size size, double cx, double slotWidth) {
    final w = size.width;
    final half = slotWidth * 0.42;
    const band = 7.0;
    const peak = 7.0;
    const peakHalf = 16.0;
    double y(double x) => _navArcY(x, w);
    final left = cx - half;
    final right = cx + half;

    final path =
        Path()
          ..moveTo(left, y(left) + 1)
          ..lineTo(left, y(left) - band)
          ..lineTo(cx - peakHalf, y(cx - peakHalf) - band)
          ..lineTo(cx, y(cx) - band - peak)
          ..lineTo(cx + peakHalf, y(cx + peakHalf) - band)
          ..lineTo(right, y(right) - band)
          ..lineTo(right, y(right) + 1);
    for (var x = right; x >= left; x -= 4) {
      path.lineTo(x, y(x) + 1);
    }
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [CasinoColors.goldHi, CasinoColors.gold, CasinoColors.goldLo],
        ).createShader(
          Rect.fromLTRB(left, y(cx) - band - peak, right, y(left) + 1),
        ),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0xFF7A5A0E),
    );
  }

  @override
  bool shouldRepaint(covariant _NavSelectionPainter old) =>
      old.count != count || old.slot != slot;
}

class _NavTile extends StatelessWidget {
  const _NavTile({required this.item});

  final RailDockItem item;

  static const _iconSize = 46.0;

  @override
  Widget build(BuildContext context) {
    final selected = item.selected;
    return Semantics(
      selected: selected,
      button: true,
      child: Pressable(
        onTap: item.onTap,
        child: SizedBox(
          height: HomeNavBar.barHeight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Scaling keeps layout fixed, so selection is compositor-only.
                AnimatedScale(
                  scale: selected ? 1 : 42 / _iconSize,
                  alignment: Alignment.bottomCenter,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutBack,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      NavArtIcon(item.art, size: _iconSize),
                      if (item.badge > 0)
                        PositionedDirectional(
                          top: -4,
                          end: -10,
                          child: CountBadge(count: item.badge),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      color: selected ? CasinoColors.gold : CasinoColors.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      shadows: const [
                        Shadow(color: Color(0x99000000), blurRadius: 3),
                      ],
                    ),
                    child: Text(item.label, maxLines: 1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
