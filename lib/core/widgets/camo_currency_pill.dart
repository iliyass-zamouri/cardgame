import 'package:flutter/material.dart';

import '../constants/camo_colors.dart';
import '../constants/camo_spacing.dart';
import '../constants/camo_typography.dart';

class CamoCurrencyPill extends StatelessWidget {
  const CamoCurrencyPill({
    super.key,
    required this.icon,
    required this.value,
    required this.iconColor,
    this.onAdd,
  });

  final IconData icon;
  final String value;
  final Color iconColor;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(CamoSpacing.sm, 4, 4, 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            CamoColors.surfaceContainer.withValues(alpha: 0.95),
            CamoColors.purpleDeep.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CamoColors.panelBorder.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: CamoSpacing.xs),
          Text(
            value,
            style: CamoTypography.headlineMd(CamoColors.white),
          ),
          if (onAdd != null) ...[
            const SizedBox(width: CamoSpacing.xs),
            _AddButton(onTap: onAdd!),
          ],
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [CamoColors.tertiary, Color(0xFF2DB86A)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1A8F4A), width: 1.5),
        ),
        child: const Icon(Icons.add, color: CamoColors.white, size: 16),
      ),
    );
  }
}

class CamoCurrencyBar extends StatelessWidget {
  const CamoCurrencyBar({
    super.key,
    required this.coins,
    this.onShopTap,
  });

  final int coins;
  final VoidCallback? onShopTap;

  String _formatCoins(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(2)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CamoCurrencyPill(
          icon: Icons.monetization_on_rounded,
          value: _formatCoins(coins),
          iconColor: CamoColors.secondary,
          onAdd: onShopTap,
        ),
      ],
    );
  }
}
