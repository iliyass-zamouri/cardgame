import 'package:flutter/material.dart';

import '../constants/camo_colors.dart';
import '../constants/camo_spacing.dart';
import '../constants/camo_typography.dart';

class CamoScaffold extends StatelessWidget {
  const CamoScaffold({
    super.key,
    required this.title,
    required this.body,
    this.trailing,
    this.floatingAction,
    this.onBack,
    this.backLabel,
  });

  final String title;
  final Widget body;
  final Widget? trailing;
  final Widget? floatingAction;
  final VoidCallback? onBack;
  final String? backLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CamoColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.5),
                radius: 1.2,
                colors: [
                  Color(0xFF2A1052),
                  CamoColors.background,
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CamoPageHeader(
                  title: title,
                  trailing: trailing,
                  backLabel: backLabel,
                  onBack: onBack,
                ),
                Expanded(child: body),
              ],
            ),
          ),
          if (floatingAction != null)
            SafeArea(
              child: Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(CamoSpacing.hudMargin),
                  child: floatingAction,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CamoPageHeader extends StatelessWidget {
  const CamoPageHeader({
    super.key,
    required this.title,
    this.trailing,
    this.onBack,
    this.backLabel,
  });

  final String title;
  final Widget? trailing;
  final VoidCallback? onBack;
  final String? backLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CamoSpacing.sm,
        CamoSpacing.xs,
        CamoSpacing.hudMargin,
        CamoSpacing.sm,
      ),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.chevron_left_rounded),
              color: Colors.white,
              iconSize: 32,
            ),
          if (title.isNotEmpty)
            Text(
              title.toUpperCase(),
              style: CamoTypography.labelCaps(CamoColors.secondary),
            ),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class CamoPanel extends StatelessWidget {
  const CamoPanel({
    super.key,
    required this.child,
    this.padding,
    this.opaque = true,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool opaque;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: opaque
              ? [
                  CamoColors.surfaceContainer,
                  CamoColors.purpleDeep.withValues(alpha: 0.75),
                ]
              : [
                  CamoColors.surfaceContainer.withValues(alpha: 0.92),
                  CamoColors.purpleDeep.withValues(alpha: 0.7),
                ],
        ),
        borderRadius: BorderRadius.circular(CamoSpacing.md),
        border: Border.all(
          color: CamoColors.panelBorder.withValues(alpha: 0.55),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(CamoSpacing.md),
        child: child,
      ),
    );
  }
}
