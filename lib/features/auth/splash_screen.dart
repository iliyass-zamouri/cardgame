import 'package:flutter/material.dart';

import '../../core/constants/camo_colors.dart';
import '../../core/constants/camo_spacing.dart';
import '../../core/constants/camo_typography.dart';
import '../../core/widgets/camo_game_title.dart';
import '../../core/widgets/game_background.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const tips = [
    'Lowest score wins the round.',
    'Pick your stake before queuing.',
    'Private room games are for friends only.',
    'Reveal phase — peek or launch at the right time.',
  ];

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinCtrl;
  int _tipIndex = 0;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();

    _tipIndex = DateTime.now().millisecond % SplashScreen.tips.length;
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
                const Spacer(flex: 2),
                SizedBox(
                  width: 52,
                  height: 52,
                  child: AnimatedBuilder(
                    animation: _spinCtrl,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _RingSpinnerPainter(progress: _spinCtrl.value),
                      );
                    },
                  ),
                ),
                const Spacer(flex: 3),
                Text(
                  SplashScreen.tips[_tipIndex],
                  textAlign: TextAlign.center,
                  style: CamoTypography.bodyLg(
                    CamoColors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: CamoSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingSpinnerPainter extends CustomPainter {
  _RingSpinnerPainter({required this.progress});

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
  bool shouldRepaint(covariant _RingSpinnerPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
