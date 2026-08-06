import 'package:cardgame/gen/assets.gen.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:flutter/material.dart';

/// Circular dark chrome button (menu / info style from the screenshot).
class CasinoCircleButton extends StatelessWidget {
  const CasinoCircleButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 42,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: CasinoColors.surfaceHi,
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
    final labelText = Text(
      label.toUpperCase(),
      style: TextStyle(
        color: onTone,
        fontWeight: FontWeight.w800,
        fontSize: 15,
        letterSpacing: 1.1,
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
  const CasinoToast({super.key, required this.message, this.onClose});

  final String message;
  final VoidCallback? onClose;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: CasinoColors.success,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, size: 18, color: Colors.white),
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

/// Single player chip: avatar with connection badge, name to the right.
class CasinoPlayerSeat extends StatelessWidget {
  const CasinoPlayerSeat({
    super.key,
    required this.name,
    required this.connected,
    required this.active,
    this.avatarSize = 28,
  });

  final String name;
  final bool connected;
  final bool active;
  final double avatarSize;

  @override
  Widget build(BuildContext context) {
    final dotSize = avatarSize * 0.32;
    return Opacity(
      opacity: connected ? 1 : 0.55,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: avatarSize,
            height: avatarSize,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: CasinoColors.bgElevated,
                    border: Border.all(
                      color: active ? CasinoColors.gold : Colors.white24,
                      width: active ? 2 : 1.2,
                    ),
                  ),
                  child: Icon(
                    Icons.person,
                    size: avatarSize * 0.55,
                    color: CasinoColors.text.withValues(alpha: 0.9),
                  ),
                ),
                Positioned(
                  right: -1,
                  bottom: -1,
                  child: Container(
                    width: dotSize,
                    height: dotSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          connected
                              ? const Color(0xFF7ED50E)
                              : CasinoColors.foldHi,
                      border: Border.all(
                        color: CasinoColors.surfaceHi,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            name,
            style: TextStyle(
              color: active ? CasinoColors.gold : CasinoColors.text,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Menu + VS players in one chrome pill (matches [CasinoCircleButton] fill).
class CasinoMenuPlayersPill extends StatelessWidget {
  const CasinoMenuPlayersPill({
    super.key,
    required this.onMenuPressed,
    required this.youName,
    required this.opponentName,
    required this.youConnected,
    required this.opponentConnected,
    required this.yourTurn,
    required this.opponentTurn,
    this.height = 42,
  });

  final VoidCallback onMenuPressed;
  final String youName;
  final String opponentName;
  final bool youConnected;
  final bool opponentConnected;
  final bool yourTurn;
  final bool opponentTurn;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CasinoColors.surfaceHi,
      shape: const StadiumBorder(),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: height,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip(
              message: 'Leave room',
              child: InkWell(
                onTap: onMenuPressed,
                child: SizedBox(
                  width: height,
                  height: height,
                  child: Icon(
                    Icons.menu,
                    size: height * 0.34,
                    color: CasinoColors.text,
                  ),
                ),
              ),
            ),
            Container(width: 1, height: height * 0.45, color: Colors.white12),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 14, 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CasinoPlayerSeat(
                    name: youName,
                    connected: youConnected,
                    active: yourTurn,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'VS',
                      style: TextStyle(
                        color: CasinoColors.goldSoft,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  CasinoPlayerSeat(
                    name: opponentName,
                    connected: opponentConnected,
                    active: opponentTurn,
                  ),
                ],
              ),
            ),
          ],
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
