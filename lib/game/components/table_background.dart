import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/constants/camo_colors.dart';

class TableBackgroundComponent extends PositionComponent {
  TableBackgroundComponent();

  @override
  void render(Canvas canvas) {
    final rect = size.toRect();
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, -0.2),
          radius: 1.3,
          colors: [
            Color(0xFF4A2080),
            CamoColors.purpleMid,
            CamoColors.purpleDeep,
            Color(0xFF0D0618),
          ],
          stops: [0.0, 0.35, 0.7, 1.0],
        ).createShader(rect),
    );
    _paintBoardPattern(canvas, rect);
    _paintSparkles(canvas, rect);
    _paintVignette(canvas, rect);
  }

  void _paintBoardPattern(Canvas canvas, Rect rect) {
    const tile = 48.0;
    final cols = (rect.width / tile).ceil() + 1;
    final rows = (rect.height / tile).ceil() + 1;

    final fill = Paint()..color = CamoColors.white.withValues(alpha: 0.025);
    final line = Paint()
      ..color = CamoColors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1;

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final x = rect.left + col * tile;
        final y = rect.top + row * tile;
        final tileRect = Rect.fromLTWH(x, y, tile, tile);

        if ((row + col).isEven) {
          canvas.drawRect(tileRect, fill);
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

  void _paintSparkles(Canvas canvas, Rect rect) {
    const seeds = <(double, double, double)>[
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

    for (final (x, y, scale) in seeds) {
      canvas.drawCircle(
        Offset(rect.left + x * rect.width, rect.top + y * rect.height),
        1.5 * scale,
        Paint()
          ..color = CamoColors.white.withValues(alpha: 0.1 + scale * 0.06),
      );
    }
  }

  void _paintVignette(Canvas canvas, Rect rect) {
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
}
