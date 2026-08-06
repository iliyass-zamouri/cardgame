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

enum CasinoActionTone { fold, check, raise }

/// Large bottom action button (FOLD / CHECK / RAISE look).
class CasinoActionButton extends StatelessWidget {
  const CasinoActionButton({
    super.key,
    required this.label,
    required this.tone,
    required this.onPressed,
    this.icon,
    this.expanded = true,
  });

  final String label;
  final CasinoActionTone tone;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;

  (Color, Color) get _colors => switch (tone) {
    CasinoActionTone.fold => (CasinoColors.fold, CasinoColors.foldHi),
    CasinoActionTone.check => (CasinoColors.check, CasinoColors.checkHi),
    CasinoActionTone.raise => (CasinoColors.raise, CasinoColors.raiseHi),
  };

  @override
  Widget build(BuildContext context) {
    final (lo, hi) = _colors;
    final enabled = onPressed != null;
    final labelText = Text(
      label.toUpperCase(),
      style: const TextStyle(
        color: CasinoColors.text,
        fontWeight: FontWeight.w800,
        fontSize: 15,
        letterSpacing: 1.1,
      ),
    );
    final child = AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: enabled ? 1 : 0.45,
      child: Container(
        height: expanded ? 52 : 44,
        padding: EdgeInsets.symmetric(horizontal: expanded ? 0 : 22),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(expanded ? 14 : 12),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [hi, lo],
          ),
        ),
        child: icon == null
            ? labelText
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: CasinoColors.text, size: expanded ? 22 : 18),
                  const SizedBox(width: 8),
                  labelText,
                ],
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
  });

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

/// Compact seat under a hand: optional name, small avatar, turn ring.
class CasinoTurnBadge extends StatelessWidget {
  const CasinoTurnBadge({
    super.key,
    required this.active,
    this.name,
    this.nameAbove = true,
    this.offline = false,
    this.avatarSize = 32,
  });

  final bool active;
  final String? name;
  final bool nameAbove;
  final bool offline;
  final double avatarSize;

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      width: avatarSize,
      height: avatarSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: CasinoColors.surfaceHi,
        border: Border.all(
          color: active ? CasinoColors.gold : Colors.white24,
          width: active ? 2.5 : 1.5,
        ),
      ),
      child: Icon(
        Icons.person,
        size: avatarSize * 0.55,
        color: CasinoColors.text.withValues(alpha: 0.9),
      ),
    );

    final nameLabel = name == null
        ? null
        : Text(
            offline ? '$name · offline' : name!,
            style: TextStyle(
              color: active ? CasinoColors.gold : CasinoColors.text,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              shadows: const [
                Shadow(
                  color: Color(0xCC000000),
                  blurRadius: 4,
                ),
              ],
            ),
          );

    return Opacity(
      opacity: offline ? 0.55 : 1,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (nameLabel != null && nameAbove) ...[
            nameLabel,
            const SizedBox(height: 4),
          ],
          avatar,
          if (nameLabel != null && !nameAbove) ...[
            const SizedBox(height: 4),
            nameLabel,
          ],
        ],
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
