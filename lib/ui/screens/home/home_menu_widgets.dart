import 'dart:async';
import 'dart:math' as math;

import 'package:cardgame/ui/flame/suit_shapes.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/widgets/deck_fan_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';

/// Card-face palette for the home menu.
abstract final class _CardInk {
  static const ivory = Color(0xFFFBF5E6);
  static const ivoryShade = Color(0xFFEADFC4);
  static const black = Color(0xFF17171C);
  static const red = Color(0xFFC62828);
  static const goldLine = Color(0xFFC9A34A);
}

Color suitColor(SuitShape suit) =>
    suit == SuitShape.hearts || suit == SuitShape.diamonds
        ? _CardInk.red
        : _CardInk.black;

/// Green felt table with a soft spotlight, vignette and faint suit weave.
class FeltTableBackground extends StatelessWidget {
  const FeltTableBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const RepaintBoundary(
          child: CustomPaint(painter: _FeltPainter(), size: Size.infinite),
        ),
        child,
      ],
    );
  }
}

class _FeltPainter extends CustomPainter {
  const _FeltPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, -0.25),
          radius: 1.1,
          colors: [Color(0xFF237A4F), CasinoColors.feltDeep, Color(0xFF0A2618)],
          stops: [0, 0.55, 1],
        ).createShader(rect),
    );

    // Faint staggered weave of suits, like an embossed felt pattern.
    const cell = 46.0;
    const glyph = 14.0;
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.10);
    var row = 0;
    for (var y = -cell; y < size.height + cell; y += cell, row++) {
      final shift = row.isOdd ? cell / 2 : 0.0;
      var col = 0;
      for (var x = -cell + shift; x < size.width + cell; x += cell, col++) {
        canvas.save();
        canvas.translate(x, y);
        canvas.scale(glyph);
        canvas.drawPath(suitPath(SuitShape.values[(row + col) % 4]), paint);
        canvas.restore();
      }
    }

    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          radius: 0.95,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.55)],
          stops: const [0.55, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _FeltPainter oldDelegate) => false;
}

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

/// Scale-down press feedback with a haptic tick.
class _Pressable extends StatefulWidget {
  const _Pressable({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;

  void _set(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final onTap = widget.onTap;
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _set(true) : null,
        onTapCancel: enabled ? () => _set(false) : null,
        onTapUp: enabled ? (_) => _set(false) : null,
        onTap:
            enabled
                ? () {
                  HapticFeedback.selectionClick();
                  onTap();
                }
                : null,
        child: AnimatedScale(
          scale: _down ? 0.95 : 1,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: enabled ? 1 : 0.5,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Unit-square suit glyph scaled to [size].
class SuitGlyph extends StatelessWidget {
  const SuitGlyph({super.key, required this.suit, this.size = 16, this.color});

  final SuitShape suit;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _SuitPainter(suit, color ?? suitColor(suit)),
    );
  }
}

class _SuitPainter extends CustomPainter {
  _SuitPainter(this.suit, this.color);

  final SuitShape suit;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width);
    canvas.drawPath(suitPath(suit), Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _SuitPainter old) =>
      old.suit != suit || old.color != color;
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

    return SizedBox(
      height: widget.height,
      width: double.infinity,
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
                    angle: (i - 2) * 0.16 * s + math.sin(phase + i) * 0.012,
                    child: cards[i],
                  ),
                ),
            ],
          );
        },
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
          colors: [_CardInk.ivory, _CardInk.ivoryShade],
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
        ..color = _CardInk.goldLine.withValues(alpha: 0.6),
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
    return _Pressable(
      onTap: onTap,
      child: Container(
        height: 92,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFE08A), CasinoColors.gold, Color(0xFFC8961E)],
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
                      color: _CardInk.black,
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
                              color: _CardInk.black,
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
    return _Pressable(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_CardInk.ivory, _CardInk.ivoryShade],
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
            border: Border.all(color: _CardInk.goldLine.withValues(alpha: 0.5)),
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
                            color: _CardInk.black,
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
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge = 0,
  });

  final List<List<dynamic>> icon;
  final String label;
  final VoidCallback onTap;
  final int badge;
}

/// Padded leather rail along the table edge holding secondary navigation.
class TableRailDock extends StatelessWidget {
  const TableRailDock({super.key, required this.items});

  final List<RailDockItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2B1A12), Color(0xFF170D08)],
        ),
        border: Border.all(color: CasinoColors.gold.withValues(alpha: 0.35)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          for (final item in items)
            Expanded(
              child: _Pressable(
                onTap: item.onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Badge.count(
                        count: item.badge,
                        isLabelVisible: item.badge > 0,
                        backgroundColor: CasinoColors.gold,
                        textColor: CasinoColors.bg,
                        textStyle: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                        child: HugeIcon(
                          icon: item.icon,
                          size: 24,
                          color: CasinoColors.goldSoft,
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          item.label,
                          maxLines: 1,
                          style: const TextStyle(
                            color: CasinoColors.text,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
