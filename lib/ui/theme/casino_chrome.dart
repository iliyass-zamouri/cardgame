import 'dart:async';
import 'dart:ui';

import 'package:cardgame/l10n/l10n_ext.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/theme/city_table.dart';
import 'package:cardgame/ui/theme/city_theme.dart';
import 'package:cardgame/ui/theme/felt_chrome.dart';
import 'package:cardgame/ui/widgets/player_avatar.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:cardgame/ui/theme/app_icons.dart';

/// Turns [CasinoGlass] blur off for a subtree.
///
/// A [BackdropFilter] over the Flame board re-blurs every frame because the
/// board repaints every frame; the in-game HUD opts out and uses a denser
/// tint instead.
class CasinoGlassScope extends InheritedWidget {
  const CasinoGlassScope({super.key, required this.blur, required super.child});

  final bool blur;

  static bool blurOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CasinoGlassScope>()?.blur ??
      true;

  @override
  bool updateShouldNotify(CasinoGlassScope oldWidget) => oldWidget.blur != blur;
}

/// Frosted glass shell for HUD chrome over the felt table.
class CasinoGlass extends StatelessWidget {
  const CasinoGlass({
    super.key,
    required this.child,
    this.borderRadius,
    this.shape,
    this.padding,
    this.rimColor,
    this.clipBehavior = Clip.antiAlias,
  }) : assert(
         borderRadius != null || shape != null,
         'Provide borderRadius or shape',
       );

  final Widget child;
  final BorderRadius? borderRadius;
  final ShapeBorder? shape;
  final EdgeInsetsGeometry? padding;

  /// Rim tint; defaults to gold. The in-game HUD passes the city accent.
  final Color? rimColor;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final resolvedShape =
        shape ??
        RoundedRectangleBorder(borderRadius: borderRadius ?? BorderRadius.zero);
    final blur = CasinoGlassScope.blurOf(context);
    final surface = DecoratedBox(
      decoration: ShapeDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            CasinoColors.leather.withValues(alpha: blur ? 0.7 : 0.94),
            CasinoColors.leatherDeep.withValues(alpha: blur ? 0.7 : 0.94),
          ],
        ),
        shape: resolvedShape,
      ),
      child: CustomPaint(
        foregroundPainter: _GlassBorderPainter(
          shape: resolvedShape,
          color: (rimColor ?? CasinoColors.gold).withValues(alpha: 0.5),
        ),
        child:
            padding == null ? child : Padding(padding: padding!, child: child),
      ),
    );
    return ClipPath(
      clipper: ShapeBorderClipper(shape: resolvedShape),
      clipBehavior: clipBehavior,
      child:
          blur
              ? BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                child: surface,
              )
              : surface,
    );
  }
}

class _GlassBorderPainter extends CustomPainter {
  _GlassBorderPainter({required this.shape, required this.color});

  final ShapeBorder shape;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = shape.getOuterPath(Offset.zero & size);
    final paint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = color;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _GlassBorderPainter oldDelegate) =>
      oldDelegate.shape != shape || oldDelegate.color != color;
}

enum CasinoHudTone { leather, danger }

/// Raised HUD button for the in-game top bar: a round leather icon button,
/// or with [label] a pill carrying icon and text. [danger] is the red
/// variant for destructive actions such as ending the game.
class CasinoHudButton extends StatelessWidget {
  const CasinoHudButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.label,
    this.tooltip,
    this.tone = CasinoHudTone.leather,
    this.accent,
  });

  static const height = 44.0;

  final List<List<dynamic>> icon;
  final VoidCallback onPressed;
  final String? label;
  final String? tooltip;
  final CasinoHudTone tone;

  /// Rim and icon tint; defaults to gold. The HUD passes the city accent.
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final danger = tone == CasinoHudTone.danger;
    final rim = accent ?? CasinoColors.gold;
    const dangerRed = Color(0xFFFF6B5E);
    final foreground = danger ? Colors.white : rim;
    final label = this.label;

    final button = Pressable(
      onTap: onPressed,
      child: Container(
        height: height,
        width: label == null ? height : null,
        padding:
            label == null
                ? null
                : const EdgeInsetsDirectional.fromSTEB(12, 0, 16, 0),
        decoration:
            danger
                // Deep red glass: mostly opaque so it reads on any table.
                ? BoxDecoration(
                  borderRadius: BorderRadius.circular(height / 2),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      CasinoColors.foldHi.withValues(alpha: 0.85),
                      const Color(0xFF7A1010).withValues(alpha: 0.85),
                    ],
                  ),
                  border: Border.all(color: dangerRed, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: dangerRed.withValues(alpha: 0.35),
                      blurRadius: 10,
                    ),
                  ],
                )
                : BoxDecoration(
                  borderRadius: BorderRadius.circular(height / 2),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF5A3826),
                      CasinoColors.leather,
                      CasinoColors.leatherDeep,
                    ],
                  ),
                  border: Border.all(
                    color: rim.withValues(alpha: 0.85),
                    width: 1.4,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x8C000000),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(height / 2),
          // Glossy top highlight.
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.center,
            colors: [
              Colors.white.withValues(alpha: danger ? 0.08 : 0.16),
              Colors.white.withValues(alpha: 0),
            ],
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(icon: icon, size: 20, color: foreground),
            if (label != null) ...[
              const SizedBox(width: 7),
              Text(
                casinoButtonLabel(label, locale),
                maxLines: 1,
                style: TextStyle(
                  fontFamily: CasinoFonts.displayFor(locale),
                  color: foreground,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: locale.languageCode == 'ar' ? 0 : 0.8,
                  height: 1.2,
                  shadows: const [
                    Shadow(
                      color: Color(0x99000000),
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
    final message = tooltip ?? label;
    if (message == null) return button;
    return Tooltip(message: message, child: button);
  }
}

/// Dark pill with optional leading widget (chip / cards strip).
class CasinoPill extends StatelessWidget {
  const CasinoPill({
    super.key,
    required this.child,
    this.onTap,
    this.borderColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color? borderColor;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final body = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: CasinoColors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: borderColor ?? CasinoColors.borderGlow.withValues(alpha: 0.55),
          width: 1.2,
        ),
      ),
      child: child,
    );
    if (onTap == null) return body;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: body,
      ),
    );
  }
}

enum CasinoActionTone { fold, check, raise, gold }

/// Large bottom action button (FOLD / CHECK / RAISE look).
class CasinoActionButton extends StatelessWidget {
  const CasinoActionButton({
    super.key,
    required this.label,
    required this.tone,
    required this.onPressed,
    this.icon,
    this.expanded = true,
    this.height = 52,
    this.raised = false,
  });

  final String label;
  final CasinoActionTone tone;
  final VoidCallback? onPressed;
  final List<List<dynamic>>? icon;
  final bool expanded;
  final double height;

  /// Bevelled, glossy finish with a tone glow for the in-game primary CTA.
  final bool raised;

  (Color, Color) get _colors => switch (tone) {
    CasinoActionTone.fold => (CasinoColors.fold, CasinoColors.foldHi),
    CasinoActionTone.check => (CasinoColors.check, CasinoColors.checkHi),
    CasinoActionTone.raise => (CasinoColors.raise, CasinoColors.raiseHi),
    CasinoActionTone.gold => (CasinoColors.gold, CasinoColors.goldSoft),
  };

  @override
  Widget build(BuildContext context) {
    final (lo, hi) = _colors;
    final enabled = onPressed != null;
    final onTone =
        tone == CasinoActionTone.gold ? CasinoColors.bg : CasinoColors.text;
    final locale = Localizations.localeOf(context);
    final labelText = Text(
      casinoButtonLabel(label, locale),
      style: TextStyle(
        fontFamily: CasinoFonts.uiFor(locale),
        color: onTone,
        fontWeight: FontWeight.w800,
        fontSize: raised ? 16 : 15,
        letterSpacing: locale.languageCode == 'ar' ? 0 : (raised ? 1.6 : 1.1),
        shadows:
            raised
                ? const [
                  Shadow(
                    color: Color(0x66000000),
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ]
                : null,
      ),
    );
    final child = AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: enabled ? 1 : 0.45,
      child: Container(
        height: height,
        padding: EdgeInsets.symmetric(
          horizontal: expanded ? 0 : (raised ? 26 : 16),
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [hi, lo],
          ),
          border:
              raised
                  ? Border.all(color: hi.withValues(alpha: 0.9), width: 1.2)
                  : null,
          boxShadow:
              raised
                  ? [
                    const BoxShadow(
                      color: Color(0x99000000),
                      blurRadius: 12,
                      offset: Offset(0, 5),
                    ),
                    BoxShadow(color: hi.withValues(alpha: 0.4), blurRadius: 20),
                  ]
                  : null,
        ),
        foregroundDecoration:
            raised
                // Glossy top bevel.
                ? BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.center,
                    colors: [
                      Colors.white.withValues(alpha: 0.22),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                )
                : null,
        child: Center(
          widthFactor: expanded ? null : 1,
          child:
              icon == null
                  ? labelText
                  : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HugeIcon(
                        icon: icon!,
                        color: onTone,
                        size: expanded || raised ? 22 : 18,
                      ),
                      SizedBox(width: raised ? 10 : 8),
                      labelText,
                    ],
                  ),
        ),
      ),
    );

    final tappable = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPressed,
        child: child,
      ),
    );

    if (!expanded) return tappable;
    return Expanded(child: tappable);
  }
}

/// Screenshot-style toast: dark rounded banner + green check + dismiss.
class CasinoToast extends StatelessWidget {
  const CasinoToast({
    super.key,
    required this.message,
    this.onClose,
    this.success = true,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final VoidCallback? onClose;
  final bool success;
  final String? actionLabel;
  final VoidCallback? onAction;

  static OverlayEntry? _entry;
  static Timer? _timer;

  static void hide() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }

  /// Top-of-screen toast via root [Overlay].
  /// Never use floating [SnackBar] + huge bottom margin — AppBar makes it assert.
  static void show(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    bool dismissible = true,
    bool success = true,
    String? actionLabel,
    VoidCallback? onAction,
    VoidCallback? onDismiss,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    // Kill any leftover SnackBar (hot-reload / old callers).
    ScaffoldMessenger.maybeOf(context)?.clearSnackBars();
    hide();

    final hasAction = actionLabel != null && onAction != null;
    final effectiveDuration =
        hasAction && duration == const Duration(seconds: 3)
            ? const Duration(seconds: 8)
            : duration;

    var acted = false;
    void dismissWithoutAction() {
      hide();
      if (!acted) onDismiss?.call();
    }

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) {
        final top = MediaQuery.viewPaddingOf(ctx).top + 8;
        return Positioned(
          top: top,
          left: 8,
          right: 8,
          child: Material(
            color: Colors.transparent,
            child: _ToastSlide(
              child: CasinoToast(
                message: message,
                success: success,
                actionLabel: actionLabel,
                onAction:
                    hasAction
                        ? () {
                          acted = true;
                          hide();
                          onAction();
                        }
                        : null,
                onClose: dismissible ? dismissWithoutAction : null,
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(entry);
    _entry = entry;
    _timer = Timer(effectiveDuration, dismissWithoutAction);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
      decoration: BoxDecoration(
        color: CasinoColors.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x88000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: success ? CasinoColors.success : CasinoColors.fold,
              shape: BoxShape.circle,
            ),
            child: HugeIcon(
              icon: success ? AppIcons.check : AppIcons.close,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: CasinoColors.text,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: 4),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: CasinoColors.gold,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ],
          if (onClose != null)
            IconButton(
              onPressed: onClose,
              icon: const HugeIcon(icon: AppIcons.close, size: 18),
              color: CasinoColors.textMuted,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}

class _ToastSlide extends StatefulWidget {
  const _ToastSlide({required this.child});

  final Widget child;

  @override
  State<_ToastSlide> createState() => _ToastSlideState();
}

class _ToastSlideState extends State<_ToastSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..forward();

  late final Animation<Offset> _offset = Tween<Offset>(
    begin: const Offset(0, -0.4),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}

/// Single player chip: avatar with connection badge, name (+ optional points).
class CasinoPlayerSeat extends StatelessWidget {
  const CasinoPlayerSeat({
    super.key,
    required this.name,
    required this.connected,
    required this.active,
    this.avatarId,
    this.points,
    this.avatarSize = 28,
  });

  final String name;
  final bool connected;
  final bool active;
  final String? avatarId;
  final int? points;
  final double avatarSize;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Opacity(
      opacity: connected ? 1 : 0.55,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PlayerAvatar(
            avatarId: avatarId ?? 'default',
            size: avatarSize,
            statusDotColor:
                connected ? const Color(0xFF7ED50E) : CasinoColors.foldHi,
          ),
          const SizedBox(width: 6),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  color: active ? CasinoColors.gold : CasinoColors.text,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              if (points != null)
                Text(
                  '${l10n.elo} $points',
                  style: TextStyle(
                    color: CasinoColors.goldSoft.withValues(alpha: 0.9),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// In-game seat: a ringed avatar with the name and rating set straight on
/// the felt, no container. The ring lights up on that player's turn.
/// [mirrored] puts the avatar on the trailing side (opponent seat on the
/// right rail).
class CasinoTableSeat extends StatelessWidget {
  const CasinoTableSeat({
    super.key,
    required this.name,
    required this.connected,
    required this.active,
    this.avatarId,
    this.points,
    this.avatarSize = 52,
    this.accent,
    this.mirrored = false,
    this.onTap,
    this.trailing,
    this.avatarOverlay,
  });

  final String name;
  final bool connected;
  final bool active;
  final String? avatarId;
  final int? points;
  final double avatarSize;
  final Color? accent;
  final bool mirrored;

  /// Opens the player's profile card.
  final VoidCallback? onTap;

  /// Small status widget after the name (e.g. voice indicator).
  final Widget? trailing;

  /// Painted over the avatar, e.g. a turn countdown. Ignores touches.
  final Widget? avatarOverlay;

  static const _textShadows = [
    Shadow(color: Color(0xE6000000), blurRadius: 6, offset: Offset(0, 1)),
    Shadow(color: Color(0x99000000), blurRadius: 14),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ring = accent ?? CasinoColors.gold;
    final align = mirrored ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    final avatar = AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
      padding: EdgeInsets.all(active ? 3 : 2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              active
                  ? [CasinoColors.goldSoft, ring, ring.withValues(alpha: 0.8)]
                  : [
                    ring.withValues(alpha: 0.55),
                    ring.withValues(alpha: 0.25),
                    ring.withValues(alpha: 0.45),
                  ],
        ),
        boxShadow: [
          const BoxShadow(
            color: Color(0x99000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
          if (active)
            BoxShadow(
              color: ring.withValues(alpha: 0.55),
              blurRadius: 18,
              spreadRadius: 1,
            ),
        ],
      ),
      child: PlayerAvatar(
        avatarId: avatarId ?? 'default',
        size: avatarSize,
        statusDotColor:
            connected ? const Color(0xFF7ED50E) : CasinoColors.foldHi,
      ),
    );

    final nameRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (mirrored && trailing != null) ...[
          trailing!,
          const SizedBox(width: 5),
        ],
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 120),
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: active ? CasinoColors.goldSoft : CasinoColors.text,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
              height: 1.15,
              shadows: _textShadows,
            ),
          ),
        ),
        if (!mirrored && trailing != null) ...[
          const SizedBox(width: 5),
          trailing!,
        ],
      ],
    );

    final info = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: align,
      children: [
        nameRow,
        if (points != null) ...[
          const SizedBox(height: 2),
          Text(
            '${l10n.elo} $points',
            style: TextStyle(
              color: CasinoColors.gold.withValues(alpha: 0.95),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              height: 1.1,
              shadows: _textShadows,
            ),
          ),
        ],
      ],
    );

    // The overlay may spill past the avatar's edge, so it is not clipped.
    final avatarSlot =
        avatarOverlay == null
            ? avatar
            : Stack(
              clipBehavior: Clip.none,
              children: [
                avatar,
                Positioned.fill(child: IgnorePointer(child: avatarOverlay)),
              ],
            );

    final seat = Opacity(
      opacity: connected ? 1 : 0.55,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children:
            mirrored
                ? [info, const SizedBox(width: 10), avatarSlot]
                : [avatarSlot, const SizedBox(width: 10), info],
      ),
    );
    final onTap = this.onTap;
    return onTap == null ? seat : Pressable(onTap: onTap, child: seat);
  }
}

/// VS players pill (frosted glass HUD).
class CasinoMenuPlayersPill extends StatelessWidget {
  const CasinoMenuPlayersPill({
    super.key,
    required this.youName,
    required this.opponentName,
    required this.youConnected,
    required this.opponentConnected,
    required this.yourTurn,
    required this.opponentTurn,
    this.youPoints,
    this.opponentPoints,
    this.height = 44,
  });

  final String youName;
  final String opponentName;
  final bool youConnected;
  final bool opponentConnected;
  final bool yourTurn;
  final bool opponentTurn;
  final int? youPoints;
  final int? opponentPoints;
  final double height;

  @override
  Widget build(BuildContext context) {
    return CasinoGlass(
      shape: const StadiumBorder(),
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CasinoPlayerSeat(
                name: youName,
                connected: youConnected,
                active: yourTurn,
                points: youPoints,
                avatarSize: 26,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  context.l10n.vs,
                  style: TextStyle(
                    color: CasinoColors.goldSoft,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              CasinoPlayerSeat(
                name: opponentName,
                connected: opponentConnected,
                active: opponentTurn,
                points: opponentPoints,
                avatarSize: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Table behind the Flame board. With a [city] a custom painted table (richer
/// for bigger pots) fills the stage; without one (private / robot games) it
/// shows the [ClassicTable].
class CasinoTableFrame extends StatelessWidget {
  const CasinoTableFrame({
    super.key,
    required this.child,
    this.city,
    this.inset = EdgeInsets.zero,
  });

  final Widget child;
  final CityTheme? city;

  /// Space kept clear above and below the table and board for HUD chrome.
  final EdgeInsets inset;

  @override
  Widget build(BuildContext context) {
    final city = this.city;
    return Stack(
      fit: StackFit.expand,
      children: [
        city == null
            ? ClassicTable(inset: inset)
            : CityTable(city: city, inset: inset),
        Padding(padding: inset, child: child),
      ],
    );
  }
}
