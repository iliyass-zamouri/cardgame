import 'package:flutter/material.dart';

import '../constants/camo_colors.dart';
import '../constants/camo_spacing.dart';
import '../constants/camo_typography.dart';

/// Compact top-left profile block — reference-style, no panel chrome.
class CamoLobbyProfile extends StatelessWidget {
  const CamoLobbyProfile({
    super.key,
    required this.displayName,
    this.level = 1,
    this.progressLabel,
  });

  final String displayName;
  final int level;
  final String? progressLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CamoColors.white.withValues(alpha: 0.15),
                border: Border.all(
                  color: CamoColors.white.withValues(alpha: 0.35),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.person,
                color: CamoColors.white.withValues(alpha: 0.9),
                size: 30,
              ),
            ),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: CamoColors.secondary,
                  shape: BoxShape.circle,
                  border: Border.all(color: CamoColors.goldDark, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$level',
                  style: CamoTypography.labelCaps(const Color(0xFF3D2200))
                      .copyWith(fontSize: 9),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: CamoSpacing.sm),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displayName,
                style: CamoTypography.headlineMd(CamoColors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (progressLabel != null) ...[
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: CamoColors.secondary,
                      size: 14,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      progressLabel!,
                      style: CamoTypography.labelCaps(CamoColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Stacked coin/gem pills — top-right reference layout.
class CamoLobbyCurrencyStack extends StatelessWidget {
  const CamoLobbyCurrencyStack({
    super.key,
    required this.coins,
    this.onShopTap,
  });

  final int coins;
  final VoidCallback? onShopTap;

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(2)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Pill(
          icon: Icons.monetization_on_rounded,
          iconColor: CamoColors.secondary,
          value: _fmt(coins),
          onTap: onShopTap,
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.iconColor,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CamoColors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 4),
          Text(value, style: CamoTypography.headlineMd(CamoColors.white)),
          if (onTap != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onTap,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: CamoColors.secondary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.shopping_cart_rounded,
                  color: Color(0xFF3D2200),
                  size: 13,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
