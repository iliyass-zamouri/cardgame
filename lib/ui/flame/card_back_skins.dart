import 'dart:math' as math;
import 'dart:ui';

/// Painter for the back of a card.
///
/// Skins draw in a normalised space where the card is 1 unit wide and
/// `height` units tall, so one skin covers every card size on the board
/// (hand cards, deck, drawn slot) without per-size tuning.
abstract class CardBackSkin {
  const CardBackSkin({required this.id, required this.name});

  /// Stable identifier. Persisted in player inventory / store purchases, so it
  /// must never change once a skin has shipped.
  final String id;

  final String name;

  /// Paints the back inside the unit-width space. Implementations may assume
  /// the canvas is already clipped to the card shape.
  void paintUnit(Canvas canvas, double height);
}

/// Registry of every drawable back. The store selects by [id]; game code only
/// ever reads [active].
class CardBackSkins {
  CardBackSkins._();

  static const ornateRed = _OrnateBack(
    id: 'ornate_red',
    name: 'Classic Red',
    ink: Color(0xFFE8264A),
  );

  static const ornateBlue = _OrnateBack(
    id: 'ornate_blue',
    name: 'Classic Blue',
    ink: Color(0xFF1D5FA8),
  );

  static const ornateEmerald = _OrnateBack(
    id: 'ornate_emerald',
    name: 'Emerald',
    ink: Color(0xFF12775C),
    paper: Color(0xFFF6F3E7),
  );

  static const ornateMidnight = _OrnateBack(
    id: 'ornate_midnight',
    name: 'Midnight',
    ink: Color(0xFF6C4FD8),
    paper: Color(0xFF15161D),
  );

  static const weave = _WeaveBack(id: 'weave_navy', name: 'Weave');

  static const List<CardBackSkin> all = [
    ornateRed,
    ornateBlue,
    ornateEmerald,
    ornateMidnight,
    weave,
  ];

  static CardBackSkin byId(String? id) {
    for (final skin in all) {
      if (skin.id == id) return skin;
    }
    return ornateRed;
  }

  static String _activeId = ornateRed.id;

  static String get activeId => _activeId;

  static CardBackSkin get active => byId(_activeId);

  /// Unknown ids fall back to the default skin, so a stale saved selection
  /// after a skin is retired cannot break rendering.
  static void select(String id) => _activeId = byId(id).id;
}

/// Ornate filigree back: scrolled border, hatched side panels, bead rows,
/// a floret lattice and a rosette medallion.
class _OrnateBack extends CardBackSkin {
  const _OrnateBack({
    required super.id,
    required super.name,
    required this.ink,
    this.paper = const Color(0xFFFBF7EC),
  });

  final Color ink;
  final Color paper;

  @override
  void paintUnit(Canvas canvas, double height) {
    canvas.drawRect(Rect.fromLTWH(0, 0, 1, height), Paint()..color = paper);

    const margin = 0.055;
    const band = 0.085;
    const stripeWidth = 0.075;
    const beadGutter = 0.05;
    const beadRow = 0.055;

    final frame = Rect.fromLTRB(margin, margin, 1 - margin, height - margin);
    final content = frame.deflate(band);
    final panel = Rect.fromLTRB(
      content.left + stripeWidth + beadGutter,
      content.top,
      content.right - stripeWidth - beadGutter,
      content.bottom,
    );

    _paintFrame(canvas, frame);
    _paintHatch(
      canvas,
      Rect.fromLTRB(
        content.left,
        panel.top + 0.02,
        content.left + stripeWidth,
        panel.bottom - 0.02,
      ),
    );
    _paintHatch(
      canvas,
      Rect.fromLTRB(
        content.right - stripeWidth,
        panel.top + 0.02,
        content.right,
        panel.bottom - 0.02,
      ),
    );
    _paintBeadColumn(
      canvas,
      content.left + stripeWidth + beadGutter / 2,
      panel.top + 0.03,
      panel.bottom - 0.03,
    );
    _paintBeadColumn(
      canvas,
      content.right - stripeWidth - beadGutter / 2,
      panel.top + 0.03,
      panel.bottom - 0.03,
    );

    _paintPanelBorder(canvas, panel);
    _paintBeadRow(canvas, panel.left, panel.right, panel.top + beadRow / 2);
    _paintBeadRow(canvas, panel.left, panel.right, panel.bottom - beadRow / 2);

    final lattice = Rect.fromLTRB(
      panel.left + 0.012,
      panel.top + beadRow,
      panel.right - 0.012,
      panel.bottom - beadRow,
    );
    canvas.save();
    canvas.clipRect(lattice);
    _paintLattice(canvas, lattice);
    canvas.restore();

    _paintMedallion(canvas, Offset(0.5, height / 2), 0.18);
  }

  /// Double-ruled border with a scrolled flourish mirrored into each corner.
  void _paintFrame(Canvas canvas, Rect frame) {
    final line =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.009
          ..color = ink;
    canvas.drawRect(frame, line);
    canvas.drawRect(
      frame.deflate(0.022),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.005
        ..color = ink,
    );

    const size = 0.26;
    final corners = <(Offset, double, double)>[
      (frame.topLeft, 1, 1),
      (frame.topRight, -1, 1),
      (frame.bottomLeft, 1, -1),
      (frame.bottomRight, -1, -1),
    ];
    for (final (origin, flipX, flipY) in corners) {
      canvas.save();
      canvas.translate(origin.dx, origin.dy);
      canvas.scale(flipX * size, flipY * size);
      canvas.drawPath(
        _cornerScroll,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.07
          ..strokeCap = StrokeCap.round
          ..color = ink,
      );
      canvas.drawCircle(const Offset(0.22, 0.22), 0.09, Paint()..color = ink);
      canvas.restore();
    }

    // Runs of vertical ticks fill the border band along the long edges,
    // matching the engraved look of a printed back.
    final tick =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.007
          ..color = ink;
    for (var x = frame.left + size; x < frame.right - size; x += 0.028) {
      canvas.drawLine(
        Offset(x, frame.top + 0.006),
        Offset(x, frame.top + 0.016),
        tick,
      );
      canvas.drawLine(
        Offset(x, frame.bottom - 0.006),
        Offset(x, frame.bottom - 0.016),
        tick,
      );
    }
    for (var y = frame.top + size; y < frame.bottom - size; y += 0.028) {
      canvas.drawLine(
        Offset(frame.left + 0.006, y),
        Offset(frame.left + 0.016, y),
        tick,
      );
      canvas.drawLine(
        Offset(frame.right - 0.006, y),
        Offset(frame.right - 0.016, y),
        tick,
      );
    }
  }

  void _paintHatch(Canvas canvas, Rect area) {
    final stroke =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.011
          ..color = ink;
    for (var y = area.top; y <= area.bottom; y += 0.026) {
      canvas.drawLine(Offset(area.left, y), Offset(area.right, y), stroke);
    }
  }

  void _paintPanelBorder(Canvas canvas, Rect panel) {
    canvas.drawRect(
      panel,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.011
        ..color = ink,
    );
  }

  void _paintBeadRow(Canvas canvas, double left, double right, double y) {
    const step = 0.072;
    final fill = Paint()..color = ink;
    for (var x = left + step * 0.6; x < right - step * 0.3; x += step) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, y), width: 0.05, height: 0.024),
          const Radius.circular(0.012),
        ),
        fill,
      );
    }
  }

  void _paintBeadColumn(Canvas canvas, double x, double top, double bottom) {
    const step = 0.062;
    final fill = Paint()..color = ink;
    for (var y = top + step * 0.5; y < bottom; y += step) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, y), width: 0.024, height: 0.044),
          const Radius.circular(0.012),
        ),
        fill,
      );
    }
  }

  /// Dense floret grid: a barbed diamond per cell with dots on the diagonals,
  /// the repeating motif of an engraved back.
  void _paintLattice(Canvas canvas, Rect area) {
    const cell = 0.076;
    final fill = Paint()..color = ink;
    final columns = (area.width / cell).ceil() + 1;
    final rows = (area.height / cell).ceil() + 1;
    final originX = area.center.dx - columns * cell / 2 + cell / 2;
    final originY = area.center.dy - rows * cell / 2 + cell / 2;

    for (var row = 0; row <= rows; row++) {
      for (var column = 0; column <= columns; column++) {
        final center = Offset(originX + column * cell, originY + row * cell);
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.scale(cell);
        canvas.drawPath(_floret, fill);
        canvas.restore();
        canvas.drawCircle(
          center + const Offset(cell / 2, cell / 2),
          cell * 0.1,
          fill,
        );
      }
    }
  }

  void _paintMedallion(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(center, radius, Paint()..color = paper);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.016
        ..color = ink,
    );
    canvas.drawCircle(
      center,
      radius - 0.03,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.007
        ..color = ink,
    );

    final fill = Paint()..color = ink;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    for (var i = 0; i < 6; i++) {
      canvas.save();
      canvas.rotate(i * math.pi / 3);
      canvas.scale(radius - 0.042);
      canvas.drawPath(_petal, fill);
      canvas.restore();
    }
    canvas.restore();

    canvas.drawCircle(center, radius * 0.22, fill);
    canvas.drawCircle(center, radius * 0.1, Paint()..color = paper);
  }
}

/// Diagonal weave back — the original hand-drawn look, kept as an alternate.
class _WeaveBack extends CardBackSkin {
  const _WeaveBack({required super.id, required super.name});

  @override
  void paintUnit(Canvas canvas, double height) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, 1, height),
      Paint()..color = const Color(0xFFFAFAFA),
    );
    final inner = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.06, height * 0.03, 0.88, height * 0.94),
      const Radius.circular(0.075),
    );
    canvas.drawRRect(inner, Paint()..color = const Color(0xFF1B3C6E));

    canvas.save();
    canvas.clipRRect(inner);
    final stripe =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.02
          ..color = const Color(0x33FFFFFF);
    for (var x = -height; x < 1 + height; x += 0.18) {
      canvas.drawLine(Offset(x, 0), Offset(x + height, height), stripe);
      canvas.drawLine(Offset(x, height), Offset(x + height, 0), stripe);
    }
    canvas.restore();

    canvas.drawRRect(
      inner.deflate(0.035),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.018
        ..color = const Color(0x66FFFFFF),
    );
  }
}

/// Barbed petal pointing up from the origin, inside a unit radius.
final Path _petal =
    Path()
      ..moveTo(0, -1)
      ..lineTo(0.12, -0.7)
      ..cubicTo(0.3, -0.66, 0.32, -0.42, 0.16, -0.32)
      ..cubicTo(0.1, -0.28, 0.05, -0.24, 0, -0.2)
      ..cubicTo(-0.05, -0.24, -0.1, -0.28, -0.16, -0.32)
      ..cubicTo(-0.32, -0.42, -0.3, -0.66, -0.12, -0.7)
      ..close();

/// Lattice motif inside a unit cell centred on the origin.
final Path _floret =
    Path()
      ..moveTo(0, -0.36)
      ..cubicTo(0.09, -0.27, 0.27, -0.09, 0.36, 0)
      ..cubicTo(0.27, 0.09, 0.09, 0.27, 0, 0.36)
      ..cubicTo(-0.09, 0.27, -0.27, 0.09, -0.36, 0)
      ..cubicTo(-0.27, -0.09, -0.09, -0.27, 0, -0.36)
      ..close();

/// Corner flourish anchored at the origin, drawn inside a unit box.
final Path _cornerScroll =
    Path()
      ..moveTo(1, 0.1)
      ..cubicTo(0.58, 0.06, 0.2, 0.24, 0.13, 0.62)
      ..cubicTo(0.09, 0.86, 0.26, 1.0, 0.42, 0.92)
      ..cubicTo(0.56, 0.85, 0.52, 0.62, 0.36, 0.64)
      ..cubicTo(0.27, 0.65, 0.25, 0.75, 0.32, 0.79)
      ..moveTo(0.1, 1)
      ..cubicTo(0.06, 0.6, 0.24, 0.22, 0.62, 0.13)
      ..cubicTo(0.86, 0.09, 1.0, 0.26, 0.92, 0.42)
      ..cubicTo(0.85, 0.56, 0.62, 0.52, 0.64, 0.36)
      ..cubicTo(0.65, 0.27, 0.75, 0.25, 0.79, 0.32);
