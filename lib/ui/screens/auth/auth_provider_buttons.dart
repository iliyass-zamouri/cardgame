import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';

/// Pill auth CTAs styled for the casino theme.
class AuthProviderButton extends StatefulWidget {
  const AuthProviderButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.leading,
    this.borderColor,
  });

  factory AuthProviderButton.google({
    Key? key,
    required String label,
    VoidCallback? onPressed,
  }) {
    return AuthProviderButton(
      key: key,
      label: label,
      onPressed: onPressed,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF191C1D),
      borderColor: const Color(0xFFC4C6CC),
      leading: SvgPicture.string(_googleSvg, width: 20, height: 20),
    );
  }

  factory AuthProviderButton.guest({
    Key? key,
    required String label,
    VoidCallback? onPressed,
  }) {
    return AuthProviderButton(
      key: key,
      label: label,
      onPressed: onPressed,
      backgroundColor: CasinoColors.raise,
      foregroundColor: CasinoColors.text,
      leading: const Icon(Icons.person_outline, size: 22),
    );
  }

  final String label;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;
  final Widget leading;

  @override
  State<AuthProviderButton> createState() => _AuthProviderButtonState();
}

class _AuthProviderButtonState extends State<AuthProviderButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return Material(
      color: Colors.transparent,
      elevation: enabled ? 2 : 0,
      shadowColor: Colors.black45,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: widget.onPressed,
        onHighlightChanged: (value) => setState(() => _pressed = value),
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: widget.backgroundColor.withValues(
              alpha: enabled ? (_pressed ? 0.92 : 1) : 0.45,
            ),
            borderRadius: BorderRadius.circular(999),
            border:
                widget.borderColor == null
                    ? null
                    : Border.all(color: widget.borderColor!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconTheme(
                data: IconThemeData(color: widget.foregroundColor, size: 22),
                child: widget.leading,
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: CasinoFonts.ui,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    letterSpacing: 0.3,
                    color: widget.foregroundColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _googleSvg = '''
<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
  <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
  <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
  <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
  <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
</svg>
''';
