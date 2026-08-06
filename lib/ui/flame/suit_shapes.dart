import 'dart:typed_data';
import 'dart:ui';

enum SuitShape { spades, hearts, diamonds, clubs }

/// Suit outlines traced from `2091948.svg`, each normalised into a unit square
/// so callers can scale them to whatever card size they need.
Path suitPath(SuitShape shape) =>
    _cache[shape] ??= _normalise(_parseSvgPath(_pathData[shape]!));

final Map<SuitShape, Path> _cache = {};

/// The source file wraps every path in `translate(0,1280) scale(0.1,-0.1)`.
final Float64List _sourceTransform = Float64List.fromList([
  0.1, 0, 0, 0, //
  0, -0.1, 0, 0, //
  0, 0, 1, 0, //
  0, 1280, 0, 1, //
]);

Path _normalise(Path raw) {
  final placed = raw.transform(_sourceTransform);
  final bounds = placed.getBounds();
  final scale = 1 / (bounds.width > bounds.height
      ? bounds.width
      : bounds.height);
  final dx = -bounds.left * scale + (1 - bounds.width * scale) / 2;
  final dy = -bounds.top * scale + (1 - bounds.height * scale) / 2;
  return placed.transform(
    Float64List.fromList([
      scale, 0, 0, 0, //
      0, scale, 0, 0, //
      0, 0, 1, 0, //
      dx, dy, 0, 1, //
    ]),
  );
}

final _token = RegExp(r'[MmLlCcZz]|-?\d*\.?\d+');

Path _parseSvgPath(String data) {
  final tokens =
      _token.allMatches(data).map((match) => match.group(0)!).toList();
  final path = Path();
  var index = 0;
  var command = '';
  var x = 0.0;
  var y = 0.0;
  var startX = 0.0;
  var startY = 0.0;

  double next() => double.parse(tokens[index++]);

  while (index < tokens.length) {
    final token = tokens[index];
    if (_token.stringMatch(token) == token &&
        RegExp(r'^[A-Za-z]$').hasMatch(token)) {
      command = token;
      index++;
      if (command == 'Z' || command == 'z') {
        path.close();
        x = startX;
        y = startY;
        command = '';
        continue;
      }
    }
    switch (command) {
      case 'M':
      case 'm':
        final relative = command == 'm';
        x = relative ? x + next() : next();
        y = relative ? y + next() : next();
        path.moveTo(x, y);
        startX = x;
        startY = y;
        command = relative ? 'l' : 'L';
      case 'L':
      case 'l':
        final relative = command == 'l';
        x = relative ? x + next() : next();
        y = relative ? y + next() : next();
        path.lineTo(x, y);
      case 'C':
      case 'c':
        final relative = command == 'c';
        final x1 = relative ? x + next() : next();
        final y1 = relative ? y + next() : next();
        final x2 = relative ? x + next() : next();
        final y2 = relative ? y + next() : next();
        final x3 = relative ? x + next() : next();
        final y3 = relative ? y + next() : next();
        path.cubicTo(x1, y1, x2, y2, x3, y3);
        x = x3;
        y = y3;
      default:
        index++;
    }
  }
  return path;
}

const Map<SuitShape, String> _pathData = {
  SuitShape.hearts: '''
M7832 12789 c-244 -41 -481 -208 -637 -449 -95 -145 -157 -295 -201
-486 -26 -109 -28 -136 -28 -314 -1 -162 3 -215 22 -315 76 -400 215 -763 457
-1200 129 -232 222 -384 560 -910 334 -519 466 -736 606 -990 88 -161 228
-452 279 -578 12 -32 24 -56 26 -54 2 2 30 68 63 148 163 401 351 732 730
1289 530 780 625 930 773 1216 221 429 338 805 383 1229 20 193 8 345 -42 540
-121 465 -430 798 -811 871 -320 61 -664 -97 -882 -406 -67 -95 -153 -270
-187 -379 l-26 -84 -29 88 c-174 535 -609 858 -1056 784z''',
  SuitShape.spades: '''
M1946 12668 c-12 -75 -74 -245 -129 -356 -153 -306 -340 -540 -756
-947 -626 -611 -742 -734 -868 -927 -217 -331 -249 -628 -98 -928 104 -208
317 -388 554 -469 321 -110 679 -64 956 122 71 48 192 163 231 218 15 22 28
38 30 36 7 -6 -58 -244 -98 -362 -161 -478 -422 -822 -829 -1096 -118 -79
-217 -137 -454 -264 -270 -145 -455 -255 -455 -272 0 -11 328 -13 1930 -13
1602 0 1930 2 1930 13 0 17 -187 128 -455 272 -226 122 -332 183 -455 266
-446 298 -725 698 -878 1261 -22 79 -42 157 -46 173 l-6 30 22 -30 c12 -16 53
-63 92 -102 485 -506 1385 -373 1675 249 49 104 71 188 78 297 11 188 -92 441
-282 696 -120 160 -233 283 -614 665 -397 398 -539 553 -682 742 -179 239
-313 503 -359 711 -7 31 -16 57 -20 57 -4 0 -10 -19 -14 -42z''',
  SuitShape.clubs: '''
M8925 5339 c-111 -12 -242 -51 -344 -104 -526 -272 -693 -942 -355
-1427 23 -34 78 -97 121 -140 69 -70 74 -77 43 -64 -159 66 -401 79 -584 31
-496 -130 -809 -615 -721 -1118 64 -366 331 -665 691 -773 71 -21 117 -27 228
-32 154 -5 234 5 356 46 247 82 460 270 571 505 36 76 36 57 5 -100 -122 -596
-319 -1002 -647 -1332 -163 -164 -367 -311 -719 -516 -203 -119 -398 -244
-419 -269 -12 -15 146 -16 1873 -16 1203 0 1886 3 1886 10 0 14 -190 136 -472
304 -262 155 -420 263 -555 378 -351 298 -591 716 -724 1263 -26 109 -69 324
-69 349 0 5 20 -31 44 -80 124 -254 348 -440 624 -517 65 -18 104 -21 252 -22
154 0 185 3 254 23 169 49 314 133 434 254 132 131 219 284 264 465 31 123 31
341 0 460 -56 216 -171 396 -337 529 -202 163 -470 243 -713 214 -85 -10 -208
-41 -267 -66 -11 -4 11 21 49 56 353 331 416 857 150 1256 -162 244 -411 396
-709 433 -99 12 -95 12 -210 0z''',
  SuitShape.diamonds: '''
M1158 3985 l-977 -1325 980 -1330 981 -1330 223 303 c1421 1926 1734
2353 1732 2359 -5 16 -1949 2648 -1955 2648 -4 0 -447 -596 -984 -1325z''',
};
