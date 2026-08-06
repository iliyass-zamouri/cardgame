import 'package:flutter/material.dart';

import '../constants/camo_colors.dart';
import '../constants/camo_spacing.dart';
import '../constants/camo_typography.dart';

class CamoProfileHeader extends StatelessWidget {
  const CamoProfileHeader({
    super.key,
    required this.displayName,
    this.subtitle,
  });

  final String displayName;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CamoSpacing.md,
        vertical: CamoSpacing.sm,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            CamoColors.purpleMid.withValues(alpha: 0.9),
            CamoColors.purpleDeep.withValues(alpha: 0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(CamoSpacing.md),
        border: Border.all(
          color: CamoColors.purpleLight.withValues(alpha: 0.45),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: CamoColors.purpleGlow.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [CamoColors.primary, CamoColors.primaryContainer],
              ),
              border: Border.all(
                color: CamoColors.secondary.withValues(alpha: 0.7),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: CamoColors.secondary.withValues(alpha: 0.35),
                  blurRadius: 8,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: CamoTypography.displaySm(CamoColors.white),
            ),
          ),
          const SizedBox(width: CamoSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: CamoTypography.displaySm(CamoColors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: CamoTypography.labelCaps(CamoColors.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
