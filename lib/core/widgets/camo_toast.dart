import 'package:flutter/material.dart';

import '../constants/camo_colors.dart';
import '../constants/camo_spacing.dart';
import '../constants/camo_typography.dart';

OverlayEntry? _toastEntry;

void showCamoToast(BuildContext context, String message, {bool error = false}) {
  hideCamoToast();
  final overlay = Overlay.of(context);
  _toastEntry = OverlayEntry(
    builder: (context) => _CamoToastCard(message: message, error: error),
  );
  overlay.insert(_toastEntry!);
  Future.delayed(const Duration(milliseconds: 2200), hideCamoToast);
}

void hideCamoToast() {
  _toastEntry?.remove();
  _toastEntry = null;
}

class _CamoToastCard extends StatefulWidget {
  const _CamoToastCard({required this.message, required this.error});

  final String message;
  final bool error;

  @override
  State<_CamoToastCard> createState() => _CamoToastCardState();
}

class _CamoToastCardState extends State<_CamoToastCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _slide = Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: CamoSpacing.hudMargin),
          child: SlideTransition(
            position: _slide,
            child: FadeTransition(
              opacity: _fade,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: CamoColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(CamoSpacing.sm),
                    border: Border.all(
                      color: widget.error
                          ? CamoColors.danger
                          : CamoColors.surfaceVariant,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(CamoSpacing.md),
                    child: Text(
                      widget.message,
                      style: CamoTypography.bodyLg(
                        widget.error ? CamoColors.danger : CamoColors.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
