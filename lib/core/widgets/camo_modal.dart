import 'package:flutter/material.dart';

import '../constants/camo_colors.dart';
import '../constants/camo_spacing.dart';
import '../constants/camo_typography.dart';

Future<T?> showCamoModal<T>({
  required BuildContext context,
  required Widget child,
}) {
  return showDialog<T>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.65),
    builder: (context) => Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Material(
          color: CamoColors.surfaceContainer,
          borderRadius: BorderRadius.circular(CamoSpacing.sm),
          child: Padding(
            padding: const EdgeInsets.all(CamoSpacing.lg),
            child: child,
          ),
        ),
      ),
    ),
  );
}

class CamoModalContent extends StatelessWidget {
  const CamoModalContent({
    super.key,
    required this.title,
    required this.body,
  });

  final String title;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title.toUpperCase(),
          style: CamoTypography.labelCaps(CamoColors.secondary),
        ),
        const SizedBox(height: CamoSpacing.md),
        body,
      ],
    );
  }
}
