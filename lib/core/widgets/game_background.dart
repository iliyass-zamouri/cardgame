import 'package:flutter/material.dart';

import '../constants/camo_colors.dart';

class GameBackground extends StatelessWidget {
  const GameBackground({
    super.key,
    required this.child,
    this.showBoardPattern = true,
  });

  final Widget child;
  final bool showBoardPattern;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.2),
          radius: 1.3,
          colors: [
            Color(0xFF4A2080),
            CamoColors.purpleMid,
            CamoColors.purpleDeep,
            Color(0xFF0D0618),
          ],
          stops: [0.0, 0.35, 0.7, 1.0],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (showBoardPattern) CustomPaint(painter: _BoardPatternPainter()),
          CustomPaint(painter: _SparklePainter()),
          CustomPaint(painter: _VignettePainter()),
          child,
        ],
      ),
    );
  }
}

class _BoardPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const tile = 48.0;
    final cols = (size.width / tile).ceil() + 1;
    final rows = (size.height / tile).ceil() + 1;

    final fill = Paint()
      ..color = CamoColors.white.withValues(alpha: 0.025);
    final line = Paint()
      ..color = CamoColors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1;

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final x = col * tile;
        final y = row * tile;
        final rect = Rect.fromLTWH(x, y, tile, tile);

        if ((row + col).isEven) {
          canvas.drawRect(rect, fill);
        }

        canvas.drawLine(Offset(x, y), Offset(x + tile, y), line);
        canvas.drawLine(Offset(x, y), Offset(x, y + tile), line);

        const inner = tile * 0.22;
        canvas.drawLine(
          Offset(x + inner, y + inner),
          Offset(x + tile - inner, y + inner),
          line,
        );
        canvas.drawLine(
          Offset(x + inner, y + inner),
          Offset(x + inner, y + tile - inner),
          line,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SparklePainter extends CustomPainter {
  static const _seeds = <(double, double, double)>[
    (0.12, 0.08, 1.2),
    (0.88, 0.12, 0.9),
    (0.25, 0.22, 0.7),
    (0.72, 0.28, 1.0),
    (0.45, 0.15, 0.6),
    (0.08, 0.35, 0.8),
    (0.92, 0.42, 0.65),
    (0.55, 0.05, 1.1),
    (0.33, 0.38, 0.55),
    (0.67, 0.18, 0.75),
    (0.18, 0.52, 0.5),
    (0.78, 0.55, 0.45),
    (0.5, 0.32, 0.85),
    (0.95, 0.68, 0.6),
    (0.05, 0.72, 0.7),
    (0.62, 0.72, 0.5),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final (x, y, scale) in _seeds) {
      final center = Offset(x * size.width, y * size.height);
      canvas.drawCircle(
        center,
        1.5 * scale,
        Paint()
          ..color = CamoColors.white.withValues(alpha: 0.1 + scale * 0.06),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _VignettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.1,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.3),
          ],
          stops: const [0.6, 1.0],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
