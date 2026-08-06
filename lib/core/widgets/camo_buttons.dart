import 'package:flutter/material.dart';

import '../constants/camo_colors.dart';
import '../constants/camo_spacing.dart';
import '../constants/camo_typography.dart';

class CamoMenuButton extends StatefulWidget {
  const CamoMenuButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.primary = false,
    this.icon,
    this.expandWidth = true,
  });

  final String label;
  final VoidCallback onPressed;
  final bool primary;
  final IconData? icon;
  final bool expandWidth;

  @override
  State<CamoMenuButton> createState() => _CamoMenuButtonState();
}

class _CamoMenuButtonState extends State<CamoMenuButton> {
  bool _pressed = false;

  static const _restDepth = 3.0;
  static const _pressedDepth = 1.0;
  static const _pressOffset = 2.0;

  @override
  Widget build(BuildContext context) {
    final depth = _pressed ? _pressedDepth : _restDepth;

    final faceGradient = widget.primary
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF5BB8F5), CamoColors.primaryContainer],
          )
        : LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              CamoColors.surfaceContainer,
              CamoColors.purpleDeep.withValues(alpha: 0.85),
            ],
          );

    final foregroundColor = widget.primary
        ? CamoColors.white
        : CamoColors.primary;
    final sideColor = widget.primary
        ? const Color(0xFF2471A3)
        : CamoColors.surfaceVariant;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        transform: Matrix4.translationValues(0, _pressed ? _pressOffset : 0, 0),
        width: widget.expandWidth ? double.infinity : null,
        padding: EdgeInsets.only(bottom: depth),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: depth,
              bottom: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: sideColor,
                  borderRadius: BorderRadius.circular(CamoSpacing.md),
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              constraints: const BoxConstraints(minHeight: 46),
              padding: const EdgeInsets.symmetric(
                vertical: CamoSpacing.md,
                horizontal: CamoSpacing.lg,
              ),
              decoration: BoxDecoration(
                gradient: faceGradient,
                borderRadius: BorderRadius.circular(CamoSpacing.md),
                border: Border.all(color: sideColor, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, color: foregroundColor, size: 18),
                    const SizedBox(width: CamoSpacing.sm),
                  ],
                  Text(
                    widget.label.toUpperCase(),
                    style: CamoTypography.labelCaps(foregroundColor),
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

class CamoStartButton extends StatefulWidget {
  const CamoStartButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
    this.expandWidth = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool enabled;
  final bool expandWidth;

  @override
  State<CamoStartButton> createState() => _CamoStartButtonState();
}

class _CamoStartButtonState extends State<CamoStartButton> {
  bool _pressed = false;

  static const _restDepth = 4.0;
  static const _pressedDepth = 1.0;
  static const _pressOffset = 3.0;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;
    final depth = _pressed ? _pressedDepth : _restDepth;

    final faceGradient = enabled
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [CamoColors.goldLight, CamoColors.secondary],
          )
        : LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              CamoColors.surfaceContainer,
              CamoColors.purpleDeep.withValues(alpha: 0.8),
            ],
          );

    final foreground =
        enabled ? const Color(0xFF3D2200) : CamoColors.onSurfaceVariant;
    final sideColor = enabled ? CamoColors.goldDark : CamoColors.surfaceVariant;

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onPressed();
            }
          : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: Matrix4.translationValues(0, _pressed ? _pressOffset : 0, 0),
        width: widget.expandWidth ? double.infinity : null,
        padding: EdgeInsets.only(bottom: depth),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: depth,
              bottom: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: sideColor,
                  borderRadius: BorderRadius.circular(CamoSpacing.md),
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              decoration: BoxDecoration(
                gradient: faceGradient,
                borderRadius: BorderRadius.circular(CamoSpacing.md),
                border: Border.all(color: sideColor, width: 2),
                boxShadow: enabled
                    ? [
                        BoxShadow(
                          color: CamoColors.secondary.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize:
                    widget.expandWidth ? MainAxisSize.max : MainAxisSize.min,
                children: [
                  Icon(Icons.play_arrow_rounded, color: foreground, size: 28),
                  const SizedBox(width: CamoSpacing.xs),
                  Text(
                    widget.label,
                    style: CamoTypography.displaySm(foreground).copyWith(
                      fontSize: 22,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w900,
                    ),
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
