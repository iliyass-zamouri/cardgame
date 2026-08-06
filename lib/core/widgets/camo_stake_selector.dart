import 'package:flutter/material.dart';

import '../constants/camo_colors.dart';
import '../constants/camo_spacing.dart';
import '../constants/camo_typography.dart';

class CamoStakeSelector extends StatelessWidget {
  const CamoStakeSelector({
    super.key,
    required this.stakes,
    required this.selected,
    required this.onSelected,
  });

  final List<int> stakes;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: stakes.map((stake) {
        final isSelected = stake == selected;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: stake == stakes.last ? 0 : CamoSpacing.sm,
            ),
            child: _StakeChip(
              stake: stake,
              selected: isSelected,
              onTap: () => onSelected(stake),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _StakeChip extends StatefulWidget {
  const _StakeChip({
    required this.stake,
    required this.selected,
    required this.onTap,
  });

  final int stake;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_StakeChip> createState() => _StakeChipState();
}

class _StakeChipState extends State<_StakeChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final depth = _pressed ? 1.0 : 3.0;

    final faceGradient = selected
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

    final sideColor =
        selected ? CamoColors.goldDark : CamoColors.surfaceVariant;
    final textColor =
        selected ? const Color(0xFF3D2200) : CamoColors.onSurface;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: Matrix4.translationValues(0, _pressed ? 2 : 0, 0),
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
                  borderRadius: BorderRadius.circular(CamoSpacing.sm),
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(vertical: CamoSpacing.md),
              decoration: BoxDecoration(
                gradient: faceGradient,
                borderRadius: BorderRadius.circular(CamoSpacing.sm),
                border: Border.all(
                  color: selected
                      ? CamoColors.goldDark
                      : CamoColors.panelBorder.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: CamoColors.secondary.withValues(alpha: 0.4),
                          blurRadius: 10,
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${widget.stake}',
                    style: CamoTypography.displaySm(textColor).copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'STAKE',
                    style: CamoTypography.labelCaps(
                      textColor.withValues(alpha: 0.7),
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
