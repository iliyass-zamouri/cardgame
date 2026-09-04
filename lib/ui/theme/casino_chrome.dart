import 'dart:async';
import 'dart:ui';

import 'package:cardgame/gen/assets.gen.dart';
import 'package:cardgame/l10n/l10n_ext.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/widgets/player_avatar.dart';
import 'package:flutter/material.dart';

/// Frosted glass shell for HUD chrome over the felt table.
class CasinoGlass extends StatelessWidget {
  const CasinoGlass({
    super.key,
    required this.child,
    this.borderRadius,
    this.shape,
    this.padding,
    this.clipBehavior = Clip.antiAlias,
  }) : assert(
         borderRadius != null || shape != null,
         'Provide borderRadius or shape',
       );

  final Widget child;
  final BorderRadius? borderRadius;
  final ShapeBorder? shape;
  final EdgeInsetsGeometry? padding;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final resolvedShape =
        shape ??
        RoundedRectangleBorder(borderRadius: borderRadius ?? BorderRadius.zero);
    return ClipPath(
      clipper: ShapeBorderClipper(shape: resolvedShape),
      clipBehavior: clipBehavior,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: CasinoColors.bg.withValues(alpha: 0.55),
            shape: resolvedShape,
          ),
          child: CustomPaint(
            foregroundPainter: _GlassBorderPainter(shape: resolvedShape),
            child:
                padding == null
                    ? child
                    : Padding(padding: padding!, child: child),
          ),
        ),
      ),
    );
  }
}

class _GlassBorderPainter extends CustomPainter {
  _GlassBorderPainter({required this.shape});

  final ShapeBorder shape;

  @override
  void paint(Canvas canvas, Size size) {
    final path = shape.getOuterPath(Offset.zero & size);
    final paint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = Colors.white.withValues(alpha: 0.12);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _GlassBorderPainter oldDelegate) =>
      oldDelegate.shape != shape;
}

/// Circular frosted HUD button (menu / info / end).
class CasinoCircleButton extends StatelessWidget {
  const CasinoCircleButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 38,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    final button = CasinoGlass(
      shape: const CircleBorder(),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        elevation: 0,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, size: size * 0.45, color: CasinoColors.text),
          ),
        ),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
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
  });

  final String label;
  final CasinoActionTone tone;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;
  final double height;

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
        fontSize: 15,
        letterSpacing: locale.languageCode == 'ar' ? 0 : 1.1,
      ),
    );
    final child = AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: enabled ? 1 : 0.45,
      child: Container(
        height: height,
        padding: EdgeInsets.symmetric(horizontal: expanded ? 0 : 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [hi, lo],
          ),
        ),
        child: Center(
          widthFactor: expanded ? null : 1,
          child:
              icon == null
                  ? labelText
                  : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: onTone, size: expanded ? 22 : 18),
                      const SizedBox(width: 8),
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
            child: Icon(
              success ? Icons.check : Icons.close,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
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
              icon: const Icon(Icons.close, size: 18),
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

/// Single player frosted glass HUD pill.
class CasinoPlayerPill extends StatelessWidget {
  const CasinoPlayerPill({
    super.key,
    required this.name,
    required this.connected,
    required this.active,
    this.avatarId,
    this.points,
    this.height = 38,
  });

  final String name;
  final bool connected;
  final bool active;
  final String? avatarId;
  final int? points;
  final double height;

  @override
  Widget build(BuildContext context) {
    // return CasinoGlass(
    //   shape: const StadiumBorder(),
    //   child: SizedBox(
    //     height: height,
    //     child: Padding(
    //       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    return CasinoPlayerSeat(
      name: name,
      avatarId: avatarId,
      connected: connected,
      active: active,
      points: points,
      avatarSize: 34,
      // ),
      //   ),
      // ),
    );
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
                  style: const TextStyle(
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

/// Felt table from [Assets.table] behind the Flame board.
class CasinoTableFrame extends StatelessWidget {
  const CasinoTableFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRect(
          child: ColoredBox(
            color: const Color(0xFF0B1E2D),
            child: Assets.table.image(
              fit: BoxFit.fitHeight,
              width: double.infinity,
              height: double.infinity,
              alignment: Alignment.center,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
        child,
      ],
    );
  }
}
