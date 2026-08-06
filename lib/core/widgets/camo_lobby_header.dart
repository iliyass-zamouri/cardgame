import 'package:flutter/material.dart';

import '../constants/camo_colors.dart';
import '../constants/camo_typography.dart';

class CamoLobbyProfile extends StatelessWidget {
  const CamoLobbyProfile({
    super.key,
    required this.displayName,
    this.level = 1,
    this.starCurrent = 0,
    this.starMax = 15,
  });

  final String displayName;
  final int level;
  final int starCurrent;
  final int starMax;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6B6B7B),
                border: Border.all(color: CamoColors.white, width: 2.5),
              ),
              child: Icon(
                Icons.person,
                color: CamoColors.white.withValues(alpha: 0.85),
                size: 32,
              ),
            ),
            Positioned(
              right: -4,
              bottom: -4,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: CamoColors.secondary,
                  shape: BoxShape.circle,
                  border: Border.all(color: CamoColors.goldDark, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$level',
                  style: const TextStyle(
                    color: Color(0xFF3D2200),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displayName,
                style: CamoTypography.headlineMd(CamoColors.white).copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: CamoColors.secondary,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$starCurrent / $starMax',
                    style: CamoTypography.bodyLg(CamoColors.white).copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.bolt_rounded,
                    color: CamoColors.white.withValues(alpha: 0.5),
                    size: 14,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class CamoLobbyCurrencyStack extends StatelessWidget {
  const CamoLobbyCurrencyStack({
    super.key,
    required this.coins,
    this.gems = 0,
    this.onShopTap,
  });

  final int coins;
  final int gems;
  final VoidCallback? onShopTap;

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(2)}M';
    if (n >= 1000) return '${n ~/ 1000}';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        _CurrencyPill(
          icon: Icons.monetization_on_rounded,
          iconColor: CamoColors.secondary,
          value: _fmt(coins),
          onShopTap: onShopTap,
        ),
        const SizedBox(height: 6),
        _CurrencyPill(
          icon: Icons.hexagon_rounded,
          iconColor: CamoColors.tertiary,
          value: _fmt(gems),
          onShopTap: onShopTap,
        ),
      ],
    );
  }
}

class _CurrencyPill extends StatelessWidget {
  const _CurrencyPill({
    required this.icon,
    required this.iconColor,
    required this.value,
    this.onShopTap,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final VoidCallback? onShopTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.only(left: 8, right: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 6),
          Text(
            value,
            style: CamoTypography.headlineMd(CamoColors.white).copyWith(
              fontSize: 14,
            ),
          ),
          if (onShopTap != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onShopTap,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: CamoColors.secondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.shopping_cart_rounded,
                  color: Color(0xFF3D2200),
                  size: 15,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
