import 'package:cardgame/ui/flame/suit_shapes.dart';
import 'package:cardgame/ui/theme/app_icons.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';

/// Card-table page shell: felt background + leather header with a gold title.
///
/// Drop-in for `Scaffold(appBar: AppBar(...))` on secondary screens.
class FeltScaffold extends StatelessWidget {
  const FeltScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions = const [],
    this.tabs,
    this.floatingActionButton,
    this.showBack = true,
  });

  final String title;
  final Widget body;
  final List<Widget> actions;
  final TabBar? tabs;
  final Widget? floatingActionButton;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return FeltTableBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: FeltAppBar(
          title: title,
          actions: actions,
          tabs: tabs,
          showBack: showBack,
        ),
        floatingActionButton: floatingActionButton,
        body: body,
      ),
    );
  }
}

/// Leather rail header matching the home screen dock.
class FeltAppBar extends StatelessWidget implements PreferredSizeWidget {
  const FeltAppBar({
    super.key,
    required this.title,
    this.actions = const [],
    this.tabs,
    this.showBack = true,
  });

  final String title;
  final List<Widget> actions;
  final TabBar? tabs;
  final bool showBack;

  static const _barHeight = 60.0;
  static const _tabsPadding = EdgeInsets.fromLTRB(12, 0, 12, 10);

  @override
  Size get preferredSize => Size.fromHeight(
    1 + // gold bottom border
        _barHeight +
        (tabs == null
            ? 0
            // Track padding (4+4) and its 1px border (1+1).
            : tabs!.preferredSize.height + 10 + _tabsPadding.vertical),
  );

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final canPop = showBack && (ModalRoute.of(context)?.canPop ?? false);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2B1A12), Color(0xFF170D08)],
          ),
          border: Border(
            bottom: BorderSide(color: CasinoColors.gold.withValues(alpha: 0.4)),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x80000000),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: _barHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 44 + (actions.length > 1 ? 44.0 : 0),
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child:
                              canPop
                                  ? FeltIconButton(
                                    icon: AppIcons.arrowBack,
                                    mirrorInRtl: true,
                                    tooltip:
                                        MaterialLocalizations.of(
                                          context,
                                        ).backButtonTooltip,
                                    onTap:
                                        () => Navigator.of(context).maybePop(),
                                  )
                                  : null,
                        ),
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SuitGlyph(
                              suit: SuitShape.spades,
                              size: 11,
                              color: CasinoColors.gold.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  casinoButtonLabel(title, locale),
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontFamily: CasinoFonts.displayFor(locale),
                                    color: CasinoColors.gold,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing:
                                        locale.languageCode == 'ar' ? 0 : 1.4,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SuitGlyph(
                              suit: SuitShape.hearts,
                              size: 11,
                              color: CasinoColors.gold.withValues(alpha: 0.7),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 44 + (actions.length > 1 ? 44.0 : 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: actions,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (tabs != null)
                Padding(
                  padding: _tabsPadding,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: CasinoColors.gold.withValues(alpha: 0.18),
                      ),
                    ),
                    child: tabs,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Round dark HUD button with a gold icon, used in headers and top bars.
class FeltIconButton extends StatelessWidget {
  const FeltIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.badge = 0,
    this.size = 40,
    this.mirrorInRtl = false,
  });

  final List<List<dynamic>> icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final int badge;
  final double size;
  final bool mirrorInRtl;

  @override
  Widget build(BuildContext context) {
    Widget glyph = HugeIcon(
      icon: icon,
      color: CasinoColors.goldSoft,
      size: size * 0.52,
    );
    if (mirrorInRtl && Directionality.of(context) == TextDirection.rtl) {
      glyph = Transform.flip(flipX: true, child: glyph);
    }
    final button = Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.38),
            border: Border.all(
              color: CasinoColors.gold.withValues(alpha: 0.28),
            ),
          ),
          child: Center(
            child: Badge(
              isLabelVisible: badge > 0,
              label: Text('$badge'),
              backgroundColor: CasinoColors.gold,
              textColor: CasinoColors.bg,
              child: glyph,
            ),
          ),
        ),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

/// Dark translucent panel that sits on the felt like a leather inlay.
BoxDecoration feltPanelDecoration({
  double radius = 16,
  bool highlighted = false,
}) => BoxDecoration(
  color: Colors.black.withValues(alpha: highlighted ? 0.42 : 0.32),
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(
    color: CasinoColors.gold.withValues(alpha: highlighted ? 0.55 : 0.2),
    width: highlighted ? 1.4 : 1,
  ),
);

/// Small-caps section label flanked by a suit pip, for grouping content.
class FeltSectionHeader extends StatelessWidget {
  const FeltSectionHeader({
    super.key,
    required this.label,
    this.suit = SuitShape.spades,
    this.trailing,
  });

  final String label;
  final SuitShape suit;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SuitGlyph(suit: suit, size: 12, color: CasinoColors.gold),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              casinoButtonLabel(label, locale),
              style: TextStyle(
                color: CasinoColors.goldSoft,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: locale.languageCode == 'ar' ? 0 : 1.2,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Card-face palette for the home menu.
abstract final class CardInk {
  static const ivory = Color(0xFFFBF5E6);
  static const ivoryShade = Color(0xFFEADFC4);
  static const black = Color(0xFF17171C);
  static const red = Color(0xFFC62828);
  static const goldLine = Color(0xFFC9A34A);
}

Color suitColor(SuitShape suit) =>
    suit == SuitShape.hearts || suit == SuitShape.diamonds
        ? CardInk.red
        : CardInk.black;

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

/// Scale-down press feedback with a haptic tick.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, required this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<Pressable> createState() => PressableState();
}

class PressableState extends State<Pressable> {
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

/// Gold-rimmed outline shared by dialogs and floating panels.
const feltDialogShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.all(Radius.circular(20)),
  side: BorderSide(color: Color(0x66F5C542)),
);
