import 'package:flutter/material.dart';

import '../constants/camo_colors.dart';
import '../constants/camo_spacing.dart';
import '../constants/camo_typography.dart';

/// Bottom floating action row — no navbar bar, icons float on background.
class CamoLobbyFloatingBar extends StatelessWidget {
  const CamoLobbyFloatingBar({
    super.key,
    required this.onFriends,
    required this.onShop,
    required this.onPlay,
    this.playLabel = 'QUICK MATCH',
  });

  final VoidCallback onFriends;
  final VoidCallback onShop;
  final VoidCallback onPlay;
  final String playLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CamoSpacing.lg,
        CamoSpacing.sm,
        CamoSpacing.lg,
        CamoSpacing.md,
      ),
      child: Row(
        children: [
          _CircleIcon(icon: Icons.group_rounded, onTap: onFriends),
          const SizedBox(width: CamoSpacing.sm),
          _CircleIcon(
            icon: Icons.storefront_rounded,
            onTap: onShop,
            iconColor: CamoColors.secondary,
          ),
          const SizedBox(width: CamoSpacing.md),
          Expanded(
            child: GestureDetector(
              onTap: onPlay,
              child: Container(
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [CamoColors.goldLight, CamoColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: CamoColors.goldDark, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: CamoColors.secondary.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  playLabel.toUpperCase(),
                  style: CamoTypography.labelCaps(const Color(0xFF3D2200))
                      .copyWith(fontSize: 13, letterSpacing: 1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon({
    required this.icon,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
          border: Border.all(color: CamoColors.white.withValues(alpha: 0.15)),
        ),
        child: Icon(icon, color: iconColor ?? CamoColors.white, size: 24),
      ),
    );
  }
}

/// Vertical game-mode card for horizontal carousel.
class CamoModeCard extends StatelessWidget {
  const CamoModeCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.child,
    this.accent,
  });

  final String title;
  final String subtitle;
  final Color color;
  final Widget child;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: CamoSpacing.sm),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(color, CamoColors.white, 0.12)!,
            color,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: CamoColors.white.withValues(alpha: 0.25),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(CamoSpacing.lg),
              child: child,
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: CamoSpacing.md),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(18),
              ),
            ),
            child: Column(
              children: [
                if (accent != null)
                  Text(
                    subtitle.toUpperCase(),
                    style: CamoTypography.labelCaps(accent!),
                  ),
                Text(
                  title.toUpperCase(),
                  style: CamoTypography.displaySm(CamoColors.white).copyWith(
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
