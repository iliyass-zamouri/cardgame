import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cardgame/data/app/app_theme_config.dart';
import 'package:cardgame/ui/flame/suit_shapes.dart';
import 'package:cardgame/ui/theme/app_icons.dart';
import 'package:cardgame/ui/theme/app_theme.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/theme/game_icon.dart';
import 'package:cardgame/ui/theme/halloween_ambient.dart';
import 'package:cardgame/ui/theme/wide_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    this.maxBodyWidth = WideLayout.readableMaxWidth,
  });

  final String title;
  final Widget body;
  final List<Widget> actions;
  final TabBar? tabs;
  final Widget? floatingActionButton;
  final bool showBack;

  /// Widest [body] runs in a wide window; the felt and header still span it.
  final double maxBodyWidth;

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
        body:
            WideLayout.of(context)
                ? CenteredContent(maxWidth: maxBodyWidth, child: body)
                : body,
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
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [CasinoColors.leather, CasinoColors.leatherDeep],
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
                Container(
                  padding: _tabsPadding,
                  // A wide window keeps the track a tab bar, not a banner.
                  constraints:
                      WideLayout.of(context)
                          ? const BoxConstraints(maxWidth: 560)
                          : null,
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

  final GameIconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final int badge;
  final double size;
  final bool mirrorInRtl;

  @override
  Widget build(BuildContext context) {
    Widget glyph = GameIcon(
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
///
/// Under the Halloween theme the scene (moon, cobwebs, bats, fog) is painted on
/// the felt, behind [child]. [animated] false keeps it still: the root stage is
/// covered by the home tab's own felt, so animating it would be wasted work.
class FeltTableBackground extends StatelessWidget {
  const FeltTableBackground({
    super.key,
    required this.child,
    this.animated = true,
  });

  final Widget child;
  final bool animated;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.active;
    return Stack(
      fit: StackFit.expand,
      children: [
        const RepaintBoundary(
          child: CustomPaint(painter: _FeltPainter(), size: Size.infinite),
        ),
        if (theme.id == AppThemeId.halloween)
          HalloweenAmbient(animated: animated && theme.animated),
        child,
      ],
    );
  }
}

class _FeltPainter extends CustomPainter {
  const _FeltPainter();

  @override
  void paint(Canvas canvas, Size size) =>
      paintFeltTexture(canvas, Offset.zero & size);

  @override
  bool shouldRepaint(covariant _FeltPainter oldDelegate) => false;
}

/// The home screen's green felt: radial gradient, embossed suit weave and a
/// dark vignette of strength [vignette], filling [rect].
void paintFeltTexture(Canvas canvas, Rect rect, {double vignette = 0.55}) {
  canvas.drawRect(
    rect,
    Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.25),
        radius: 1.1,
        colors: [
          CasinoColors.feltHi,
          CasinoColors.feltDeep,
          CasinoColors.feltEdge,
        ],
        stops: const [0, 0.55, 1],
      ).createShader(rect),
  );

  // Faint staggered weave of suits, like an embossed felt pattern.
  _FeltWeave.paint(canvas, rect);

  canvas.drawRect(
    rect,
    Paint()
      ..shader = RadialGradient(
        radius: 0.95,
        colors: [Colors.transparent, Colors.black.withValues(alpha: vignette)],
        stops: const [0.55, 1],
      ).createShader(rect),
  );
}

/// The felt's suit weave, filled from a cached tile.
///
/// Drawing it glyph by glyph cost ~250 path fills per screen-sized felt, and
/// every pushed route stacks its own felt. Impeller has no raster cache, so
/// that work repeated on every frame of a transition or idle animation. The
/// weave repeats every 4x4 cells, so one tile is rasterized at device
/// resolution and filled as an image shader in a single draw.
abstract final class _FeltWeave {
  static const _cell = 46.0;
  static const _glyph = 14.0;

  /// Row parity sets the stagger and `(row + col) % 4` the suit, so the
  /// pattern repeats every four cells in both directions.
  static const _span = _cell * 4;

  static Paint? _paint;
  static int _tilePixels = 0;

  static void paint(Canvas canvas, Rect rect) {
    final paint = _paintFor(_pixelsForDevice());
    // The weave starts one cell before the felt's top-left corner.
    final origin = rect.topLeft - const Offset(_cell, _cell);
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.drawRect(rect.shift(-origin), paint);
    canvas.restore();
  }

  /// Tile side in device pixels, rounded so it repeats without seams.
  static int _pixelsForDevice() {
    final dpr =
        ui.PlatformDispatcher.instance.implicitView?.devicePixelRatio ?? 2.0;
    return (_span * dpr.clamp(1.0, 3.0)).round();
  }

  static Paint _paintFor(int pixels) {
    final cached = _paint;
    if (cached != null && _tilePixels == pixels) return cached;
    final scale = pixels / _span;
    final tile = _rasterizeTile(pixels, scale);
    _tilePixels = pixels;
    return _paint =
        Paint()
          ..shader = ui.ImageShader(
            tile,
            TileMode.repeated,
            TileMode.repeated,
            Float64List.fromList([
              1 / scale, 0, 0, 0, //
              0, 1 / scale, 0, 0, //
              0, 0, 1, 0, //
              0, 0, 0, 1, //
            ]),
            filterQuality: FilterQuality.low,
          );
  }

  static ui.Image _rasterizeTile(int pixels, double scale) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(scale);
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.10);
    for (var row = 0; row < 4; row++) {
      final shift = row.isOdd ? _cell / 2 : 0.0;
      for (var col = 0; col < 4; col++) {
        canvas.save();
        canvas.translate(col * _cell + shift, row * _cell);
        canvas.scale(_glyph);
        canvas.drawPath(suitPath(SuitShape.values[(row + col) % 4]), paint);
        canvas.restore();
      }
    }
    final picture = recorder.endRecording();
    final image = picture.toImageSync(pixels, pixels);
    picture.dispose();
    return image;
  }
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
RoundedRectangleBorder get feltDialogShape => RoundedRectangleBorder(
  borderRadius: const BorderRadius.all(Radius.circular(20)),
  side: BorderSide(color: CasinoColors.gold.withValues(alpha: 0.4)),
);

/// Leather gradient with a gold hairline: the shared look of [FeltPanel],
/// list rows and sheets.
BoxDecoration leatherPanelDecoration({
  double radius = 18,
  bool highlighted = false,
}) => BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      CasinoColors.leather.withValues(alpha: 0.94),
      CasinoColors.leatherDeep.withValues(alpha: 0.94),
    ],
  ),
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(
    color: CasinoColors.gold.withValues(alpha: highlighted ? 0.75 : 0.28),
    width: highlighted ? 1.5 : 1,
  ),
  boxShadow: [
    const BoxShadow(
      color: Color(0x66000000),
      blurRadius: 12,
      offset: Offset(0, 5),
    ),
    if (highlighted)
      BoxShadow(
        color: CasinoColors.gold.withValues(alpha: 0.2),
        blurRadius: 18,
      ),
  ],
);

/// Leather inlay panel for grouped content on the felt (settings groups,
/// stats, list rows). [highlighted] adds a brighter gold rim and glow.
class FeltPanel extends StatelessWidget {
  const FeltPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = 18,
    this.highlighted = false,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool highlighted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    final decoration = leatherPanelDecoration(
      radius: radius,
      highlighted: highlighted,
    );
    if (onTap == null) {
      return Container(padding: padding, decoration: decoration, child: child);
    }
    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Ink(padding: padding, decoration: decoration, child: child),
      ),
    );
  }
}

/// Ivory playing-card face for collectible and shop content. Text inside
/// defaults to card ink; [suit] adds corner pips like a real card.
class IvoryCard extends StatelessWidget {
  const IvoryCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.radius = 16,
    this.suit,
    this.highlighted = false,
    this.rimColor,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final SuitShape? suit;
  final bool highlighted;

  /// Overrides the inner frame line colour (e.g. medal gold/silver/bronze).
  final Color? rimColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pip = suit == null ? null : SuitGlyph(suit: suit!, size: 11);
    final card = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [CardInk.ivory, CardInk.ivoryShade],
        ),
        boxShadow: [
          const BoxShadow(
            color: Color(0x80000000),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
          if (highlighted)
            BoxShadow(
              color: CasinoColors.gold.withValues(alpha: 0.45),
              blurRadius: 16,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius - 4),
                border: Border.all(
                  color:
                      rimColor ??
                      (highlighted
                          ? CasinoColors.gold
                          : CardInk.goldLine.withValues(alpha: 0.55)),
                  width: highlighted || rimColor != null ? 1.6 : 1,
                ),
              ),
            ),
          ),
          if (pip != null) ...[
            Positioned(top: 9, left: 9, child: pip),
            Positioned(
              bottom: 9,
              right: 9,
              child: Transform.rotate(angle: 3.14159, child: pip),
            ),
          ],
          Padding(
            padding: padding,
            child: DefaultTextStyle.merge(
              style: const TextStyle(color: CardInk.black),
              child: IconTheme.merge(
                data: const IconThemeData(color: CardInk.black),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return card;
    return Pressable(onTap: onTap, child: card);
  }
}

/// Primary action in the gold "Play" style.
class GoldButton extends StatelessWidget {
  const GoldButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leading,
    this.height = 48,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;
  final double height;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final h = compact ? 36.0 : height;
    return Pressable(
      onTap: onPressed,
      child: Container(
        height: h,
        padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(compact ? 11 : 14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              CasinoColors.goldHi,
              CasinoColors.gold,
              CasinoColors.goldLo,
            ],
          ),
          border: Border.all(
            color: const Color(0xFF7A5A0E).withValues(alpha: 0.5),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x55000000),
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leading != null) ...[
              IconTheme.merge(
                data: IconThemeData(
                  color: CardInk.black,
                  size: compact ? 16 : 20,
                ),
                child: leading!,
              ),
              SizedBox(width: compact ? 6 : 8),
            ],
            Flexible(
              child: Text(
                casinoButtonLabel(label, locale),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily:
                      compact
                          ? CasinoFonts.uiFor(locale)
                          : CasinoFonts.displayFor(locale),
                  color: CardInk.black,
                  fontSize: compact ? 13 : 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: locale.languageCode == 'ar' ? 0 : 0.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Secondary action: dark leather with a gold (or [color]) outline.
class LeatherButton extends StatelessWidget {
  const LeatherButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leading,
    this.color,
    this.height = 48,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;
  final Color? color;
  final double height;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? CasinoColors.gold;
    final locale = Localizations.localeOf(context);
    final h = compact ? 36.0 : height;
    return Pressable(
      onTap: onPressed,
      child: Container(
        height: h,
        padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(compact ? 11 : 14),
          color: Colors.black.withValues(alpha: 0.32),
          border: Border.all(color: color.withValues(alpha: 0.7)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leading != null) ...[
              IconTheme.merge(
                data: IconThemeData(color: color, size: compact ? 16 : 20),
                child: leading!,
              ),
              SizedBox(width: compact ? 6 : 8),
            ],
            Flexible(
              child: Text(
                casinoButtonLabel(label, locale),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: compact ? 13 : 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: locale.languageCode == 'ar' ? 0 : 0.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Round gold-rimmed medallion holding an icon, used to lead list rows.
class FeltMedallion extends StatelessWidget {
  const FeltMedallion({
    super.key,
    required this.icon,
    this.color,
    this.size = 38,
  });

  final GameIconData icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? CasinoColors.goldSoft;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.32),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Center(
        child: GameIcon(icon: icon, color: color, size: size * 0.5),
      ),
    );
  }
}

/// Row inside a [FeltTileGroup]: medallion, title/subtitle, trailing widget
/// (a chevron by default when tappable).
class FeltTile extends StatelessWidget {
  const FeltTile({
    super.key,
    required this.title,
    this.icon,
    this.leading,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.destructive = false,
  });

  final String title;
  final GameIconData? icon;
  final Widget? leading;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final accent = destructive ? CasinoColors.foldHi : CasinoColors.goldSoft;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    Widget? trail = trailing;
    if (trail == null && onTap != null) {
      final chevron = GameIcon(
        icon: AppIcons.chevronRight,
        size: 20,
        color: CasinoColors.gold.withValues(alpha: 0.6),
      );
      trail = rtl ? Transform.flip(flipX: true, child: chevron) : chevron;
    }
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            leading ??
                (icon == null
                    ? const SizedBox.shrink()
                    : FeltMedallion(icon: icon!, color: accent)),
            if (leading != null || icon != null) const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color:
                          destructive ? CasinoColors.foldHi : CasinoColors.text,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: CasinoColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trail != null) ...[const SizedBox(width: 8), trail],
          ],
        ),
      ),
    );
  }
}

/// Leather panel holding [FeltTile]s separated by gold hairlines, with an
/// optional suited section header above it.
class FeltTileGroup extends StatelessWidget {
  const FeltTileGroup({
    super.key,
    required this.children,
    this.header,
    this.suit = SuitShape.spades,
  });

  final List<Widget> children;
  final String? header;
  final SuitShape suit;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(
          Divider(
            height: 1,
            thickness: 1,
            indent: 64,
            endIndent: 14,
            color: CasinoColors.gold.withValues(alpha: 0.12),
          ),
        );
      }
      rows.add(children[i]);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (header != null) FeltSectionHeader(label: header!, suit: suit),
        FeltPanel(
          padding: EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Material(
              type: MaterialType.transparency,
              child: Column(children: rows),
            ),
          ),
        ),
      ],
    );
  }
}

/// Gold progress bar on a recessed track (XP, levels).
class GoldProgressBar extends StatelessWidget {
  const GoldProgressBar({
    super.key,
    required this.value,
    this.height = 10,
    this.trackColor,
  });

  final double value;
  final double height;

  /// Recessed track fill; defaults to a dark inset for leather/felt.
  final Color? trackColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: trackColor ?? Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(height),
        border: Border.all(color: CasinoColors.gold.withValues(alpha: 0.25)),
      ),
      child: FractionallySizedBox(
        alignment: AlignmentDirectional.centerStart,
        widthFactor: value.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(height),
            gradient: LinearGradient(
              colors: [
                CasinoColors.goldLo,
                CasinoColors.gold,
                CasinoColors.goldHi,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
