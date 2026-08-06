import 'package:flutter/material.dart';

import '../constants/camo_colors.dart';
import '../constants/camo_spacing.dart';
import '../constants/camo_typography.dart';

class AuthProviderButton extends StatefulWidget {
  const AuthProviderButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.gradient,
    required this.foregroundColor,
    required this.borderColor,
    this.icon,
    this.sideColor,
  });

  final String label;
  final VoidCallback onPressed;
  final List<Color> gradient;
  final Color foregroundColor;
  final Color borderColor;
  final Color? sideColor;
  final Widget? icon;

  @override
  State<AuthProviderButton> createState() => _AuthProviderButtonState();
}

class _AuthProviderButtonState extends State<AuthProviderButton> {
  bool _pressed = false;

  static const _restDepth = 4.0;
  static const _pressedDepth = 1.0;
  static const _pressOffset = 3.0;

  @override
  Widget build(BuildContext context) {
    final depth = _pressed ? _pressedDepth : _restDepth;
    final side = widget.sideColor ?? widget.borderColor;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: Matrix4.translationValues(0, _pressed ? _pressOffset : 0, 0),
        width: double.infinity,
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
                  color: side,
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: widget.gradient,
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: widget.borderColor, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    widget.icon!,
                    const SizedBox(width: CamoSpacing.md),
                  ],
                  Text(
                    widget.label,
                    style: CamoTypography.headlineMd(widget.foregroundColor)
                        .copyWith(fontSize: 16, fontWeight: FontWeight.w700),
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

class GoogleAuthButton extends StatelessWidget {
  const GoogleAuthButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AuthProviderButton(
      label: 'Continue with Google',
      onPressed: onPressed,
      gradient: const [Color(0xFF5BB8FF), Color(0xFF3498DB)],
      foregroundColor: CamoColors.white,
      borderColor: const Color(0xFF2471A3),
      sideColor: const Color(0xFF1A5A85),
      icon: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: CamoColors.white,
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: const Text(
          'G',
          style: TextStyle(
            color: Color(0xFF4285F4),
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}

class AppleAuthButton extends StatelessWidget {
  const AppleAuthButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AuthProviderButton(
      label: 'Continue with Apple',
      onPressed: onPressed,
      gradient: const [Color(0xFF1A2840), Color(0xFF0F1C2C)],
      foregroundColor: CamoColors.white,
      borderColor: CamoColors.surfaceVariant,
      sideColor: const Color(0xFF0A1220),
      icon: const Icon(Icons.apple, color: CamoColors.white, size: 24),
    );
  }
}

class GuestAuthButton extends StatelessWidget {
  const GuestAuthButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AuthProviderButton(
      label: 'Play as Guest',
      onPressed: onPressed,
      gradient: const [Color(0xFFF5F5F5), Color(0xFFD8D8D8)],
      foregroundColor: const Color(0xFF191C1D),
      borderColor: const Color(0xFFB0B0B0),
      sideColor: const Color(0xFF909090),
      icon: const Icon(
        Icons.person_outline_rounded,
        color: Color(0xFF191C1D),
        size: 22,
      ),
    );
  }
}
