import 'dart:math' as math;
import 'dart:ui';

import 'package:cardgame/ui/flame/card_back_skins.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Premium deck backs sold in the market. Like every [CardBackSkin] they
/// paint in a space one unit wide and `height` units tall. They are
/// rasterized once per card size, so detail costs nothing during play.

// ---- metals -----------------------------------------------------------------

const _goldMetal = [
  Color(0xFFFFF4C2),
  Color(0xFFE9C25A),
  Color(0xFF9C6B12),
  Color(0xFFF6D77A),
  Color(0xFF7A5210),
];

/// Card faces for each premium deck.
abstract final class PremiumFaces {
  static const royalCrimson = CardFaceTheme(
    backgroundGradientColors: [Color(0xFFF8F0E6), Color(0xFFEFE2D2)],
    blackColor: Color(0xFF1B1416),
    redColor: Color(0xFF9E1A24),
    frameAlpha: 0.22,
    borderColor: Color(0x66C9A34A),
    highlightBorderColor: Color(0xFFE2B84C),
    foil: _goldMetal,
  );

  static const sapphireFrost = CardFaceTheme(
    backgroundGradientColors: [Color(0xFFFBF8EF), Color(0xFFE6ECF7)],
    blackColor: Color(0xFF0F2F7A),
    redColor: Color(0xFFB3202F),
    frameAlpha: 0.26,
    borderColor: Color(0x66C9A34A),
    highlightBorderColor: Color(0xFF5FA8FF),
    foil: _goldMetal,
  );

  static const imperialJade = CardFaceTheme(
    backgroundGradientColors: [Color(0xFFFFF8EC), Color(0xFFF3E6C8)],
    blackColor: Color(0xFF1A120C),
    redColor: Color(0xFF9E1B2A),
    frameAlpha: 0.3,
    borderColor: Color(0x66C9A34A),
    highlightBorderColor: Color(0xFFE2B84C),
    foil: _goldMetal,
  );

  static const neonNights = CardFaceTheme(
    backgroundGradientColors: [Color(0xFF1C1033), Color(0xFF0B0716)],
    blackColor: Color(0xFF7DF9FF),
    redColor: Color(0xFFFF3EA5),
    frameAlpha: 0.5,
    borderColor: Color(0x88FF3EA5),
    highlightBorderColor: Color(0xFF7DF9FF),
    foil: [
      Color(0xFFFFD6EC),
      Color(0xFFFF3EA5),
      Color(0xFF6A1B9A),
      Color(0xFF7DF9FF),
      Color(0xFF2A6F8F),
    ],
  );

  static const gilded = CardFaceTheme(
    backgroundGradientColors: [Color(0xFFFFF6DC), Color(0xFFF0D99A)],
    blackColor: Color(0xFF2A1E05),
    redColor: Color(0xFF9E1B1B),
    frameAlpha: 0.34,
    borderColor: Color(0x88B8860B),
    foil: _goldMetal,
  );
}

/// Foil border and corner filigree for a premium face of size [w] × [h].
/// The rank indices sit top-left and bottom-right, so the filigree takes
/// the two free corners.
void paintFoilFaceDecor(Canvas canvas, double w, double h, List<Color> foil) {
  final band = RRect.fromRectAndRadius(
    Rect.fromLTWH(w * 0.025, w * 0.025, w * 0.95, h - w * 0.05),
    Radius.circular(w * 0.08),
  );
  canvas.drawRRect(
    band,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, w * 0.02)
      ..shader = _metal(Rect.fromLTWH(0, 0, w, h), foil),
  );
  canvas.drawRRect(
    band.deflate(w * 0.018),
    _stroke(foil[2].withValues(alpha: 0.6), math.max(0.5, w * 0.005)),
  );
  final scroll = _stroke(foil[2], math.max(0.6, w * 0.012))
    ..strokeCap = StrokeCap.round;
  for (final (corner, sx, sy) in [
    (Offset(w - w * 0.06, w * 0.06), -1.0, 1.0),
    (Offset(w * 0.06, h - w * 0.06), 1.0, -1.0),
  ]) {
    canvas.save();
    canvas.translate(corner.dx, corner.dy);
    canvas.scale(sx * w * 0.2, sy * w * 0.2);
    canvas.drawPath(_cornerCurl, scroll..strokeWidth = 0.06);
    canvas.drawCircle(const Offset(0.16, 0.16), 0.07, _fill(foil[1]));
    canvas.restore();
  }
}

// ---- toolkit ----------------------------------------------------------------

Paint _fill(Color c) => Paint()..color = c;

Paint _stroke(Color c, double w) =>
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..color = c;

Rect _card(double height) => Rect.fromLTWH(0, 0, 1, height);

/// Polished-metal shader running from the top-left to the bottom-right.
Shader _metal(Rect r, List<Color> colors) => Gradient.linear(
  r.topLeft,
  r.bottomRight,
  colors,
  [for (var i = 0; i < colors.length; i++) i / (colors.length - 1)],
);

/// Strokes [path] as a raised metal moulding: shadow below right,
/// highlight above left, metal on top.
void _emboss(
  Canvas canvas,
  Path path,
  double width,
  List<Color> metal,
  Rect bounds,
) {
  canvas.drawPath(
    path.shift(Offset(width * 0.35, width * 0.35)),
    _stroke(const Color(0x88000000), width),
  );
  canvas.drawPath(
    path.shift(Offset(-width * 0.2, -width * 0.2)),
    _stroke(const Color(0x66FFFFFF), width * 0.8),
  );
  canvas.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..shader = _metal(bounds, metal),
  );
}

/// Holographic sheen sweeping diagonally across the whole card.
void _sheen(Canvas canvas, double height, {double strength = 0.22}) {
  canvas.drawRect(
    _card(height),
    Paint()
      ..blendMode = BlendMode.plus
      ..shader = Gradient.linear(
        Offset(0, height * 0.15),
        Offset(1, height * 0.85),
        [
          const Color(0x00FFFFFF),
          Color.fromRGBO(255, 255, 255, strength),
          const Color(0x00FFFFFF),
          Color.fromRGBO(255, 255, 255, strength * 0.5),
          const Color(0x00FFFFFF),
        ],
        const [0.25, 0.4, 0.52, 0.62, 0.72],
      ),
  );
}

Path _star(Offset c, double outer, double inner, int points, double rot) {
  final path = Path();
  for (var i = 0; i < points * 2; i++) {
    final r = i.isEven ? outer : inner;
    final a = rot + i * math.pi / points;
    final p = c + Offset(math.cos(a), math.sin(a)) * r;
    i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
  }
  return path..close();
}

/// Four-point twinkle with a soft halo.
void _sparkle(Canvas canvas, Offset c, double r) {
  canvas.drawCircle(
    c,
    r * 0.7,
    Paint()
      ..shader = Gradient.radial(c, r * 0.7, const [
        Color(0x88FFFFFF),
        Color(0x00FFFFFF),
      ]),
  );
  canvas.drawPath(_star(c, r, r * 0.12, 4, 0), _fill(const Color(0xFFFFFFFF)));
}

/// Pearls or metal beads following [border].
void _beads(
  Canvas canvas,
  RRect border,
  double spacing,
  double r,
  List<Color> colors,
) {
  for (final m in (Path()..addRRect(border)).computeMetrics()) {
    for (var d = spacing / 2; d < m.length; d += spacing) {
      final p = m.getTangentForOffset(d)!.position;
      canvas.drawCircle(
        p,
        r,
        Paint()
          ..shader = Gradient.radial(
            p.translate(-r * 0.4, -r * 0.4),
            r * 1.4,
            [colors[0], colors[1], colors[2]],
            const [0, 0.5, 1],
          ),
      );
    }
  }
}

/// Baroque C-scroll ornament for a corner, drawn in a unit box.
final Path _cornerCurl =
    Path()
      ..moveTo(1, 0.12)
      ..cubicTo(0.6, 0.06, 0.24, 0.2, 0.16, 0.56)
      ..cubicTo(0.1, 0.84, 0.32, 0.98, 0.48, 0.88)
      ..cubicTo(0.62, 0.8, 0.56, 0.6, 0.4, 0.62)
      ..cubicTo(0.3, 0.64, 0.3, 0.74, 0.36, 0.78)
      ..moveTo(0.12, 1)
      ..cubicTo(0.06, 0.6, 0.2, 0.24, 0.56, 0.16)
      ..cubicTo(0.84, 0.1, 0.98, 0.32, 0.88, 0.48)
      ..cubicTo(0.8, 0.62, 0.6, 0.56, 0.62, 0.4)
      ..cubicTo(0.64, 0.3, 0.74, 0.3, 0.78, 0.36)
      // Acanthus leaf along the diagonal.
      ..moveTo(0.24, 0.24)
      ..cubicTo(0.4, 0.3, 0.5, 0.42, 0.56, 0.56)
      ..moveTo(0.24, 0.24)
      ..cubicTo(0.3, 0.4, 0.42, 0.5, 0.56, 0.56);

void _cornerScrolls(
  Canvas canvas,
  Rect frame,
  double size,
  double width,
  List<Color> metal,
) {
  for (final (corner, sx, sy) in [
    (frame.topLeft, 1.0, 1.0),
    (frame.topRight, -1.0, 1.0),
    (frame.bottomLeft, 1.0, -1.0),
    (frame.bottomRight, -1.0, -1.0),
  ]) {
    canvas.save();
    canvas.translate(corner.dx, corner.dy);
    canvas.scale(sx * size, sy * size);
    _emboss(
      canvas,
      _cornerCurl,
      width / size,
      metal,
      const Rect.fromLTWH(0, 0, 1, 1),
    );
    canvas.drawCircle(
      const Offset(0.2, 0.2),
      0.09,
      Paint()..shader = _metal(const Rect.fromLTWH(0.1, 0.1, 0.2, 0.2), metal),
    );
    canvas.restore();
  }
}

/// Faceted gemstone seen from above: a table, star facets and a girdle of
/// alternating light and dark crown facets.
void _gem(
  Canvas canvas,
  Offset c,
  double r,
  Color base, {
  int sides = 8,
  double rot = -math.pi / 2,
}) {
  final light = Color.lerp(base, const Color(0xFFFFFFFF), 0.55)!;
  final mid = base;
  final dark = Color.lerp(base, const Color(0xFF000000), 0.45)!;
  Offset at(double a, double d) => c + Offset(math.cos(a), math.sin(a)) * d;
  final step = 2 * math.pi / sides;
  for (var i = 0; i < sides; i++) {
    final a0 = rot + i * step;
    final a1 = a0 + step;
    final am = a0 + step / 2;
    // Crown facets between the girdle and the table.
    canvas.drawPath(
      Path()..addPolygon([at(a0, r), at(am, r), at(am, r * 0.55)], true),
      _fill(i.isEven ? light : dark),
    );
    canvas.drawPath(
      Path()..addPolygon([at(am, r), at(a1, r), at(am, r * 0.55)], true),
      _fill(i.isEven ? mid : light),
    );
    canvas.drawPath(
      Path()..addPolygon([at(a0, r), at(am, r * 0.55), at(a0, r * 0.5)], true),
      _fill(i.isOdd ? mid : dark),
    );
  }
  // Table.
  final table =
      Path()..addPolygon([
        for (var i = 0; i < sides; i++) at(rot + i * step, r * 0.5),
      ], true);
  canvas.drawPath(
    table,
    Paint()
      ..shader = Gradient.linear(
        c.translate(-r * 0.5, -r * 0.5),
        c.translate(r * 0.5, r * 0.5),
        [light, mid, dark],
        const [0, 0.5, 1],
      ),
  );
  canvas.drawPath(table, _stroke(light.withValues(alpha: 0.7), r * 0.025));
  canvas.drawPath(
    Path()..addPolygon([
      for (var i = 0; i < sides; i++) at(rot + i * step, r),
    ], true),
    _stroke(dark, r * 0.04),
  );
}

/// Metal bezel with prongs holding a gem.
void _setting(
  Canvas canvas,
  Offset c,
  double r,
  List<Color> metal,
  int prongs,
) {
  final ring = Rect.fromCircle(center: c, radius: r * 1.18);
  canvas.drawCircle(
    c.translate(r * 0.06, r * 0.08),
    r * 1.18,
    _fill(const Color(0x66000000)),
  );
  canvas.drawCircle(c, r * 1.18, Paint()..shader = _metal(ring, metal));
  canvas.drawCircle(c, r * 1.04, _fill(const Color(0xFF1A1A1F)));
  for (var i = 0; i < prongs; i++) {
    final a = i * 2 * math.pi / prongs - math.pi / 2 + math.pi / prongs;
    final p = c + Offset(math.cos(a), math.sin(a)) * r * 1.02;
    canvas.drawOval(
      Rect.fromCenter(center: p, width: r * 0.22, height: r * 0.22),
      Paint()
        ..shader = _metal(Rect.fromCircle(center: p, radius: r * 0.12), metal),
    );
  }
}

// ---- Royal Crimson -----------------------------------------------------------

/// Crimson and gilt engraved plate: crowned figure, lions and filigree,
/// painted from the supplied artwork.
class RoyalCrimsonBack extends CardBackSkin {
  const RoyalCrimsonBack()
    : super(
        id: 'royal_crimson',
        name: 'Royal Crimson',
        faceTheme: PremiumFaces.royalCrimson,
      );

  static const _asset = 'assets/cards/royal_crimson.webp';

  static Image? _art;
  static Future<void>? _loading;
  static final _ready = _ArtReady();

  @override
  Listenable? get repaintListenable => _ready;

  /// Decodes the plate before the first card paint. Safe to call twice.
  static Future<void> ensureLoaded() {
    if (_art != null) return Future<void>.value();
    return _loading ??= _load();
  }

  static Future<void> _load() async {
    try {
      final data = await rootBundle.load(_asset);
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      final codec = await instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      codec.dispose();
      _art = frame.image;
      _ready.ping();
    } catch (e, st) {
      _loading = null;
      debugPrint('Royal crimson back failed to load: $e\n$st');
      rethrow;
    }
  }

  @override
  void paintUnit(Canvas canvas, double height) {
    final dest = Rect.fromLTWH(0, 0, 1, height);
    final art = _art;
    if (art == null) {
      canvas.drawRect(dest, _fill(const Color(0xFF8E1524)));
      canvas.drawRect(dest.deflate(0.04), _fill(const Color(0xFFF4E8DA)));
      return;
    }
    canvas.drawImageRect(
      art,
      Rect.fromLTWH(0, 0, art.width.toDouble(), art.height.toDouble()),
      dest,
      Paint()..filterQuality = FilterQuality.high,
    );
  }
}

// ---- Sapphire Dragon ---------------------------------------------------------

/// Sapphire and gold Celtic plate: twin dragons knotted in a gold braid,
/// with triquetras and blue interlace roundels. Painted from a plate so the
/// knotwork stays the supplied artwork.
class SapphireDragonBack extends CardBackSkin {
  const SapphireDragonBack()
    : super(
        id: 'sapphire_frost',
        name: 'Sapphire Dragon',
        faceTheme: PremiumFaces.sapphireFrost,
      );

  static const _asset = 'assets/cards/sapphire_dragon.webp';

  static Image? _art;
  static Future<void>? _loading;
  static final _ready = _ArtReady();

  @override
  Listenable? get repaintListenable => _ready;

  /// Decodes the plate before the first card paint. Safe to call twice.
  static Future<void> ensureLoaded() {
    if (_art != null) return Future<void>.value();
    return _loading ??= _load();
  }

  static Future<void> _load() async {
    try {
      final data = await rootBundle.load(_asset);
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      final codec = await instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      codec.dispose();
      _art = frame.image;
      _ready.ping();
    } catch (e, st) {
      _loading = null;
      debugPrint('Sapphire dragon back failed to load: $e\n$st');
      rethrow;
    }
  }

  @override
  void paintUnit(Canvas canvas, double height) {
    final dest = Rect.fromLTWH(0, 0, 1, height);
    final art = _art;
    if (art == null) {
      canvas.drawRect(dest, _fill(const Color(0xFF071433)));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          dest.deflate(0.03),
          const Radius.circular(0.04),
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.04
          ..shader = _metal(dest, _goldMetal),
      );
      return;
    }
    canvas.drawImageRect(
      art,
      Rect.fromLTWH(0, 0, art.width.toDouble(), art.height.toDouble()),
      dest,
      Paint()..filterQuality = FilterQuality.high,
    );
  }
}

class _ArtReady extends ChangeNotifier {
  void ping() => notifyListeners();
}

// ---- High Victorian ----------------------------------------------------------

/// Emerald filigree under a gilt frame: guilloche ring, rosette medallion
/// and corner scrolls, in the manner of an engraved Victorian back.
class ImperialJadeBack extends CardBackSkin {
  const ImperialJadeBack()
    : super(
        id: 'imperial_jade',
        name: 'High Victorian',
        faceTheme: PremiumFaces.imperialJade,
      );

  static const _deep = Color(0xFF06281C);
  static const _leaf = Color(0xFF146B4A);

  @override
  void paintUnit(Canvas canvas, double height) {
    final card = _card(height);
    canvas.drawRect(card, Paint()..shader = _metal(card, _goldMetal));
    final plate = RRect.fromRectAndRadius(
      Rect.fromLTRB(0.042, 0.042, 0.958, height - 0.042),
      const Radius.circular(0.04),
    );
    canvas.drawRRect(plate, _fill(const Color(0xFF140E08)));
    final field = plate.deflate(0.01);
    canvas.drawRRect(
      field,
      Paint()
        ..shader = Gradient.radial(
          Offset(0.5, height * 0.42),
          height * 0.72,
          const [Color(0xFF1E8A64), Color(0xFF0E4A38), Color(0xFF06281C)],
          const [0, 0.55, 1],
        ),
    );

    canvas.save();
    canvas.clipRRect(field);
    _filigree(canvas, height);
    canvas.restore();

    _rule(canvas, field.deflate(0.016), card, 0.007);
    _rule(canvas, field.deflate(0.03), card, 0.003);
    _beads(canvas, field.deflate(0.04), 0.026, 0.005, _goldMetal);
    final inner = field.deflate(0.058).outerRect;
    _rule(
      canvas,
      RRect.fromRectAndRadius(inner, const Radius.circular(0.02)),
      card,
      0.004,
    );
    _cornerScrolls(canvas, inner.deflate(0.01), 0.18, 0.011, _goldMetal);

    final c = Offset(0.5, height / 2);
    _shell(canvas, Offset(0.5, inner.top + 0.08), 1, card);
    _shell(canvas, Offset(0.5, inner.bottom - 0.08), -1, card);
    _seal(canvas, Offset(inner.left + 0.075, c.dy), 0.048, card);
    _seal(canvas, Offset(inner.right - 0.075, c.dy), 0.048, card);
    _medallion(canvas, c, 0.22, card);
    _sheen(canvas, height, strength: 0.12);
  }

  /// Staggered gilt fleurs, large enough to read on a hand card.
  void _filigree(Canvas canvas, double height) {
    const cell = 0.092;
    final gold = _fill(const Color(0xFFC9963A));
    final dark = _fill(const Color(0xFF083528));
    for (var row = 0; row < 28; row++) {
      final y = 0.08 + row * cell * 0.72;
      if (y > height - 0.06) break;
      final shift = row.isOdd ? cell * 0.5 : 0.0;
      for (var col = 0; col < 14; col++) {
        final x = 0.055 + col * cell + shift;
        if (x > 0.96) break;
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(row.isOdd ? math.pi / 4 : 0);
        canvas.scale(0.04);
        canvas.drawPath(_fleur, dark);
        canvas.scale(0.68);
        canvas.drawPath(_fleur, gold);
        canvas.restore();
      }
    }
  }

  void _rule(Canvas canvas, RRect rect, Rect card, double width) {
    canvas.drawRRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..shader = _metal(card, _goldMetal),
    );
  }

  /// Scallop shell, a stock Victorian corner of the frame.
  void _shell(Canvas canvas, Offset c, double dir, Rect card) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(1, dir);
    final shell =
        Path()
          ..moveTo(-0.1, 0.01)
          ..quadraticBezierTo(-0.09, -0.06, 0, -0.085)
          ..quadraticBezierTo(0.09, -0.06, 0.1, 0.01)
          ..close();
    canvas.drawPath(shell, _fill(_deep));
    _emboss(
      canvas,
      shell,
      0.005,
      _goldMetal,
      const Rect.fromLTWH(-0.12, -0.1, 0.24, 0.14),
    );
    final rib = _stroke(const Color(0xFFE2B84C), 0.0025);
    for (var i = -3; i <= 3; i++) {
      canvas.drawLine(Offset(i * 0.01, -0.005), Offset(i * 0.026, -0.065), rib);
    }
    canvas.restore();
  }

  /// Small side roundel: six gilt petals on emerald.
  void _seal(Canvas canvas, Offset c, double r, Rect card) {
    final bounds = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(c, r, _fill(_deep));
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.14
        ..shader = _metal(bounds, _goldMetal),
    );
    canvas.drawCircle(c, r * 0.7, _fill(_leaf));
    for (var i = 0; i < 6; i++) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(i * math.pi / 3);
      final petal =
          Path()..addOval(
            Rect.fromCenter(
              center: Offset(0, -r * 0.28),
              width: r * 0.26,
              height: r * 0.42,
            ),
          );
      canvas.drawPath(petal, Paint()..shader = _metal(card, _goldMetal));
      canvas.restore();
    }
    canvas.drawCircle(c, r * 0.14, _fill(_deep));
    canvas.drawCircle(c, r * 0.14, _stroke(const Color(0xFFE2B84C), 0.003));
  }

  /// Concentric gilt ring, guilloche, and an eight-point rosette.
  void _medallion(Canvas canvas, Offset c, double r, Rect card) {
    final bounds = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c.translate(0.006, 0.008),
      r,
      _fill(const Color(0x66000000)),
    );
    canvas.drawCircle(c, r, _fill(_deep));
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.012
        ..shader = _metal(card, _goldMetal),
    );
    _guilloche(canvas, c, r - 0.018, 0.007, 22);
    canvas.drawCircle(c, r - 0.036, _stroke(const Color(0xFFE2B84C), 0.003));

    for (var i = 0; i < 16; i++) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(i * math.pi / 8);
      final petal =
          Path()
            ..moveTo(0, -r * 0.34)
            ..quadraticBezierTo(r * 0.1, -r * 0.55, 0, -r * 0.7)
            ..quadraticBezierTo(-r * 0.1, -r * 0.55, 0, -r * 0.34)
            ..close();
      canvas.drawPath(petal, _fill(i.isEven ? _leaf : const Color(0xFF0C3D2E)));
      _emboss(canvas, petal, 0.0035, _goldMetal, bounds);
      canvas.restore();
    }

    canvas.drawCircle(
      c,
      r * 0.36,
      Paint()..shader = _metal(bounds, _goldMetal),
    );
    canvas.drawCircle(c, r * 0.28, _fill(_deep));
    canvas.drawPath(
      _star(c, r * 0.22, r * 0.09, 8, -math.pi / 2),
      Paint()..shader = _metal(bounds, _goldMetal),
    );
    canvas.drawCircle(c, r * 0.07, _fill(const Color(0xFF1E8A64)));
    canvas.drawCircle(c, r * 0.07, _stroke(const Color(0xFFFFF4C2), 0.003));
    _sparkle(canvas, c.translate(-r * 0.62, -r * 0.62), 0.03);
  }

  /// Two sine strands braided around a circle.
  void _guilloche(Canvas canvas, Offset c, double r, double amp, int waves) {
    for (final phase in const [0.0, math.pi]) {
      final path = Path();
      for (var i = 0; i <= 240; i++) {
        final a = i * 2 * math.pi / 240;
        final rr = r + math.sin(a * waves + phase) * amp;
        final p = c + Offset(math.cos(a), math.sin(a)) * rr;
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(path, _stroke(const Color(0xFFE2B84C), 0.003));
    }
  }
}

/// Four-petal fleur centred on the origin, inside a unit radius.
final Path _fleur = _buildFleur();

Path _buildFleur() {
  final path = Path();
  for (var i = 0; i < 4; i++) {
    final a = i * math.pi / 2;
    final tip = Offset(math.cos(a), math.sin(a));
    final left = Offset(math.cos(a + 0.9), math.sin(a + 0.9)) * 0.45;
    final right = Offset(math.cos(a - 0.9), math.sin(a - 0.9)) * 0.45;
    path
      ..moveTo(0, 0)
      ..quadraticBezierTo(left.dx, left.dy, tip.dx, tip.dy)
      ..quadraticBezierTo(right.dx, right.dy, 0, 0);
  }
  path.addOval(Rect.fromCircle(center: Offset.zero, radius: 0.16));
  return path;
}

// ---- Neon Nights -------------------------------------------------------------

/// Synthwave: neon sun over a glowing grid, palms and a skyline in
/// silhouette, scanlines and a neon tube frame.
class NeonNightsBack extends CardBackSkin {
  const NeonNightsBack()
    : super(
        id: 'neon_nights',
        name: 'Neon Nights',
        faceTheme: PremiumFaces.neonNights,
      );

  static const _pink = Color(0xFFFF3EA5);
  static const _cyan = Color(0xFF7DF9FF);
  static const _night = Color(0xFF12061F);

  @override
  void paintUnit(Canvas canvas, double height) {
    final card = _card(height);
    canvas.drawRect(
      card,
      Paint()
        ..shader = Gradient.linear(
          Offset.zero,
          Offset(0, height),
          const [Color(0xFF07030F), Color(0xFF3A0F5A), Color(0xFF07030F)],
          const [0, 0.52, 1],
        ),
    );

    final rnd = math.Random(9);
    for (var i = 0; i < 50; i++) {
      canvas.drawCircle(
        Offset(rnd.nextDouble(), rnd.nextDouble() * height * 0.5),
        0.002 + rnd.nextDouble() * 0.004,
        _fill(Color.fromRGBO(255, 255, 255, 0.3 + rnd.nextDouble() * 0.5)),
      );
    }

    final horizon = height * 0.56;
    final sunC = Offset(0.5, horizon - 0.02);
    const sunR = 0.27;
    canvas.drawCircle(
      sunC,
      sunR * 1.5,
      Paint()
        ..shader = Gradient.radial(sunC, sunR * 1.5, const [
          Color(0x66FF3EA5),
          Color(0x00FF3EA5),
        ]),
    );
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, 0, 1, horizon));
    canvas.drawCircle(
      sunC,
      sunR,
      Paint()
        ..shader = Gradient.linear(
          sunC.translate(0, -sunR),
          sunC.translate(0, sunR * 0.4),
          const [Color(0xFFFFE066), Color(0xFFFF7A3D), _pink],
          const [0, 0.5, 1],
        ),
    );
    for (var k = 0; k < 5; k++) {
      final y = horizon - 0.03 - k * 0.032;
      canvas.drawRect(
        Rect.fromLTRB(0, y, 1, y + 0.012 - k * 0.002),
        _fill(const Color(0xFF3A0F5A)),
      );
    }
    canvas.restore();

    _skyline(canvas, horizon);
    _palm(canvas, Offset(0.12, horizon), 0.3, -1);
    _palm(canvas, Offset(0.9, horizon), 0.24, 1);

    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, horizon, 1, height));
    canvas.drawRect(Rect.fromLTRB(0, horizon, 1, height), _fill(_night));
    // Sun reflection on the floor.
    canvas.drawRect(
      Rect.fromLTRB(0.3, horizon, 0.7, horizon + 0.12),
      Paint()
        ..shader = Gradient.linear(
          Offset(0.5, horizon),
          Offset(0.5, horizon + 0.12),
          const [Color(0x88FF3EA5), Color(0x00FF3EA5)],
        ),
    );
    final glow = _stroke(_cyan.withValues(alpha: 0.35), 0.012)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.01);
    final line = _stroke(_cyan, 0.004);
    for (var i = -8; i <= 8; i++) {
      final top = Offset(0.5 + i * 0.03, horizon);
      final bottom = Offset(0.5 + i * 0.22, height);
      canvas.drawLine(top, bottom, glow);
      canvas.drawLine(top, bottom, line);
    }
    for (var k = 1; k <= 7; k++) {
      final y = horizon + (height - horizon) * math.pow(k / 7, 1.8);
      canvas.drawLine(Offset(0, y), Offset(1, y), glow);
      canvas.drawLine(Offset(0, y), Offset(1, y), line);
    }
    canvas.restore();
    canvas.drawLine(
      Offset(0, horizon),
      Offset(1, horizon),
      _stroke(_pink, 0.006),
    );

    // CRT scanlines.
    for (var y = 0.0; y < height; y += 0.012) {
      canvas.drawRect(
        Rect.fromLTWH(0, y, 1, 0.004),
        _fill(const Color(0x14000000)),
      );
    }

    final frame = RRect.fromRectAndRadius(
      Rect.fromLTRB(0.05, 0.05, 0.95, height - 0.05),
      const Radius.circular(0.06),
    );
    canvas.drawRRect(
      frame,
      _stroke(_pink.withValues(alpha: 0.5), 0.03)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.015),
    );
    canvas.drawRRect(frame, _stroke(_pink, 0.008));
    canvas.drawRRect(frame, _stroke(const Color(0xFFFFD6EC), 0.003));
    canvas.drawRRect(
      frame.deflate(0.03),
      _stroke(_cyan.withValues(alpha: 0.4), 0.014)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.01),
    );
    canvas.drawRRect(frame.deflate(0.03), _stroke(_cyan, 0.003));
  }

  void _skyline(Canvas canvas, double horizon) {
    final p = Path();
    final rnd = math.Random(4);
    var x = 0.22;
    while (x < 0.8) {
      final w = 0.03 + rnd.nextDouble() * 0.04;
      final h = 0.04 + rnd.nextDouble() * 0.12;
      p.addRect(Rect.fromLTRB(x, horizon - h, x + w, horizon));
      x += w + 0.005;
    }
    canvas.drawPath(p, _fill(_night));
    canvas.drawPath(p, _stroke(_pink.withValues(alpha: 0.5), 0.003));
    for (var i = 0; i < 30; i++) {
      final wx = 0.23 + rnd.nextDouble() * 0.55;
      final wy = horizon - 0.01 - rnd.nextDouble() * 0.1;
      if (p.contains(Offset(wx, wy))) {
        canvas.drawRect(
          Rect.fromLTWH(wx, wy, 0.006, 0.006),
          _fill(const Color(0xCCFFE066)),
        );
      }
    }
  }

  void _palm(Canvas canvas, Offset base, double h, double lean) {
    final top = base.translate(lean * h * 0.15, -h);
    final trunk =
        Path()
          ..moveTo(base.dx - 0.012, base.dy)
          ..quadraticBezierTo(
            base.dx + lean * h * 0.2,
            base.dy - h * 0.5,
            top.dx,
            top.dy,
          )
          ..lineTo(top.dx + 0.006, top.dy)
          ..quadraticBezierTo(
            base.dx + lean * h * 0.2 + 0.012,
            base.dy - h * 0.5,
            base.dx + 0.012,
            base.dy,
          )
          ..close();
    canvas.drawPath(trunk, _fill(const Color(0xFF07030F)));
    for (var i = 0; i < 7; i++) {
      final a = -math.pi / 2 + (i - 3) * 0.5;
      final tip = top + Offset(math.cos(a), math.sin(a) + 0.6) * h * 0.38;
      final ctl = top + Offset(math.cos(a), math.sin(a) - 0.1) * h * 0.3;
      canvas.drawPath(
        Path()
          ..moveTo(top.dx, top.dy)
          ..quadraticBezierTo(ctl.dx, ctl.dy - 0.02, tip.dx, tip.dy)
          ..quadraticBezierTo(ctl.dx, ctl.dy + 0.01, top.dx, top.dy),
        _fill(const Color(0xFF07030F)),
      );
    }
    // Neon rim light so the silhouette reads against the night sky.
    canvas.drawPath(trunk, _stroke(_pink.withValues(alpha: 0.7), 0.003));
  }
}

// ---- 24K Gold ----------------------------------------------------------------

/// Solid gold: engine-turned guilloché, bevelled frame with diamond pavé
/// corners, a black enamel sunburst plaque and a brilliant-cut diamond.
class GildedBack extends CardBackSkin {
  const GildedBack()
    : super(
        id: 'gilded_gold',
        name: '24K Gold',
        faceTheme: PremiumFaces.gilded,
      );

  static const _deep = Color(0xFF7A5210);
  static const _enamel = Color(0xFF111114);

  @override
  void paintUnit(Canvas canvas, double height) {
    final card = _card(height);
    canvas.drawRect(
      card,
      Paint()
        ..shader = Gradient.linear(
          Offset.zero,
          Offset(1, height),
          const [
            Color(0xFFFFF4C2),
            Color(0xFFE9C25A),
            Color(0xFFB8860B),
            Color(0xFFF6D77A),
            Color(0xFFFFF1B8),
            Color(0xFFC9962A),
          ],
          const [0, 0.2, 0.42, 0.6, 0.78, 1],
        ),
    );
    final c = Offset(0.5, height / 2);

    // Engine-turned field: waves across the card...
    final wave = _stroke(_deep.withValues(alpha: 0.22), 0.0022);
    for (var y = 0.0; y < height + 0.02; y += 0.018) {
      final p = Path()..moveTo(0, y);
      for (var x = 0.0; x <= 1.0; x += 0.02) {
        p.lineTo(x, y + math.sin(x * math.pi * 10 + y * 40) * 0.006);
      }
      canvas.drawPath(p, wave);
    }
    // ...and a rosette of offset circles round the plaque.
    final rosette = _stroke(_deep.withValues(alpha: 0.35), 0.0018);
    for (var i = 0; i < 72; i++) {
      final a = i * math.pi / 36;
      canvas.drawCircle(
        c + Offset(math.cos(a), math.sin(a)) * 0.1,
        0.3,
        rosette,
      );
    }

    // Bevelled frame with an enamel pinstripe.
    final frame = RRect.fromRectAndRadius(
      Rect.fromLTRB(0.05, 0.05, 0.95, height - 0.05),
      const Radius.circular(0.05),
    );
    _emboss(canvas, Path()..addRRect(frame), 0.03, _goldMetal, card);
    canvas.drawRRect(frame.deflate(0.026), _stroke(_enamel, 0.008));
    canvas.drawRRect(
      frame.deflate(0.036),
      _stroke(const Color(0xFFFFF4C2), 0.003),
    );
    _cornerScrolls(
      canvas,
      frame.deflate(0.04).outerRect,
      0.17,
      0.012,
      _goldMetal,
    );
    for (final p in [
      frame.outerRect.topLeft.translate(0.045, 0.045),
      frame.outerRect.topRight.translate(-0.045, 0.045),
      frame.outerRect.bottomLeft.translate(0.045, -0.045),
      frame.outerRect.bottomRight.translate(-0.045, -0.045),
    ]) {
      _setting(canvas, p, 0.02, _goldMetal, 4);
      _gem(canvas, p, 0.02, const Color(0xFFE6F2FF));
    }

    // Black enamel plaque with a gold sunburst.
    final plaque =
        Path()..addPolygon([
          for (var i = 0; i < 8; i++)
            c +
                Offset(
                      math.cos(i * math.pi / 4 + math.pi / 8),
                      math.sin(i * math.pi / 4 + math.pi / 8),
                    ) *
                    0.27,
        ], true);
    canvas.drawPath(
      plaque.shift(const Offset(0.008, 0.012)),
      _fill(const Color(0x88000000)),
    );
    canvas.drawPath(plaque, _fill(_enamel));
    canvas.save();
    canvas.clipPath(plaque);
    for (var i = 0; i < 48; i += 2) {
      final a0 = i * math.pi / 24;
      final a1 = (i + 1) * math.pi / 24;
      canvas.drawPath(
        Path()..addPolygon([
          c,
          c + Offset(math.cos(a0), math.sin(a0)) * 0.4,
          c + Offset(math.cos(a1), math.sin(a1)) * 0.4,
        ], true),
        _fill(const Color(0x33E9C25A)),
      );
    }
    canvas.restore();
    _emboss(canvas, plaque, 0.014, _goldMetal, card);

    // Pavé ring and the centre stone.
    for (var i = 0; i < 16; i++) {
      final a = i * math.pi / 8;
      final p = c + Offset(math.cos(a), math.sin(a)) * 0.2;
      canvas.drawCircle(
        p,
        0.014,
        Paint()
          ..shader = _metal(
            Rect.fromCircle(center: p, radius: 0.014),
            _goldMetal,
          ),
      );
      _gem(canvas, p, 0.011, const Color(0xFFE6F2FF), sides: 6);
    }
    _setting(canvas, c, 0.13, _goldMetal, 6);
    _gem(canvas, c, 0.13, const Color(0xFFDCEBFA), sides: 8);
    _sparkle(canvas, c.translate(-0.05, -0.06), 0.08);
    _sparkle(canvas, c.translate(0.07, 0.04), 0.04);
    _sheen(canvas, height, strength: 0.3);
  }
}
