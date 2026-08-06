import 'package:flutter/material.dart';

import '../constants/camo_colors.dart';
import '../constants/camo_spacing.dart';
import '../constants/camo_typography.dart';
import 'camo_game_title.dart';
import 'game_background.dart';

/// Splash / matchmaking wait layout — logo top, spinner mid, tip bottom.
class WaitingScreen extends StatefulWidget {
  const WaitingScreen({
    super.key,
    required this.tips,
    this.onCancel,
    this.cancelLabel = 'Cancel search',
    this.statusLine,
  });

  final List<String> tips;
  final VoidCallback? onCancel;
  final String cancelLabel;
  final String? statusLine;

  @override
  State<WaitingScreen> createState() => _WaitingScreenState();
}

class _WaitingScreenState extends State<WaitingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinCtrl;
  late final int _tipIndex;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
    _tipIndex = DateTime.now().millisecond % widget.tips.length;
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: CamoSpacing.xl),
            child: Column(
              children: [
                const Spacer(flex: 2),
                const CamoGameTitle(
                  'Shadow Hand',
                  fontSize: 42,
                  stacked: true,
                ),
                if (widget.statusLine != null) ...[
                  const SizedBox(height: CamoSpacing.lg),
                  Text(
                    widget.statusLine!,
                    textAlign: TextAlign.center,
                    style: CamoTypography.displaySm(CamoColors.secondary),
                  ),
                ],
                const Spacer(flex: 2),
                SizedBox(
                  width: 52,
                  height: 52,
                  child: AnimatedBuilder(
                    animation: _spinCtrl,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: RingSpinnerPainter(progress: _spinCtrl.value),
                      );
                    },
                  ),
                ),
                const Spacer(flex: 3),
                Text(
                  widget.tips[_tipIndex],
                  textAlign: TextAlign.center,
                  style: CamoTypography.bodyLg(
                    CamoColors.white.withValues(alpha: 0.85),
                  ),
                ),
                if (widget.onCancel != null) ...[
                  const SizedBox(height: CamoSpacing.lg),
                  GestureDetector(
                    onTap: widget.onCancel,
                    child: Text(
                      widget.cancelLabel.toUpperCase(),
                      style: CamoTypography.labelCaps(
                        CamoColors.white.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: CamoSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RingSpinnerPainter extends CustomPainter {
  RingSpinnerPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;
    const stroke = 3.5;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = CamoColors.white.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      progress * 6.28318,
      2.0,
      false,
      Paint()
        ..color = CamoColors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant RingSpinnerPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
