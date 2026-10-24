import 'package:cardgame/ui/theme/game_icon.dart';

typedef _P = GameIconPart;

/// The game's icon set: chunky outlined glyphs drawn for this table, on a
/// 100x100 grid (see [GameIcon]).
abstract final class AppIcons {
  /// Plus: add one, buy more.
  static const add = GameIconData([_P.body('M50 16V84M16 50H84', stroke: 19)]);

  /// Minus: take one away.
  static const remove = GameIconData([_P.body('M16 50H84', stroke: 19)]);

  /// Fat arrow pointing back.
  static const arrowBack = GameIconData([
    _P.body('M8 50L46 12L46 33L90 33L90 67L46 67L46 88Z'),
  ]);

  /// Fat arrow pointing forward.
  static const arrowForward = GameIconData([
    _P.body('M92 50L54 12L54 33L10 33L10 67L54 67L54 88Z'),
  ]);

  /// Chunky chevron: opens a row.
  static const chevronRight = GameIconData([
    _P.body('M36 18L68 50L36 82', stroke: 19),
  ]);

  /// Chunky cross: close or cancel.
  static const close = GameIconData([
    _P.body('M24 24L76 76M76 24L24 76', stroke: 19),
  ]);

  /// Cross on a disc: clear a field.
  static const clear = GameIconData([
    _P.body('M8 50A42 42 0 1 1 92 50A42 42 0 1 1 8 50Z'),
    _P.ink('M35 35L65 65M65 35L35 65', stroke: 11),
  ]);

  /// Chunky tick: done, ready, selected.
  static const check = GameIconData([
    _P.body('M16 52L40 76L84 26', stroke: 19),
  ]);

  /// Tick on a disc: owned, confirmed.
  static const checkCircle = GameIconData([
    _P.body('M8 50A42 42 0 1 1 92 50A42 42 0 1 1 8 50Z'),
    _P.accent('M29 51L44 66L72 36', stroke: 12),
  ]);

  /// Three bars: open the menu.
  static const menu = GameIconData([
    _P.body('M18 26H82M18 50H82M18 74H82', stroke: 15),
  ]);

  /// Three stacked balls: more options.
  static const moreVert = GameIconData([
    _P.body(
      'M39 18A11 11 0 1 1 61 18A11 11 0 1 1 39 18ZM39 50'
      'A11 11 0 1 1 61 50A11 11 0 1 1 39 50ZM39 82A11 11 0 1 1 61 82'
      'A11 11 0 1 1 39 82Z',
    ),
  ]);

  /// Cog with a bright hub.
  static const settings = GameIconData([
    _P.body(
      'M43.4 16.7L42.6 5.6L57.4 5.6L56.6 16.7A34 34 0 0 1 68.9 21.7'
      'L76.2 13.4L86.6 23.8L78.3 31.1A34 34 0 0 1 83.3 43.4L94.4 42.6'
      'L94.4 57.4L83.3 56.6A34 34 0 0 1 78.3 68.9L86.6 76.2L76.2 86.6'
      'L68.9 78.3A34 34 0 0 1 56.6 83.3L57.4 94.4L42.6 94.4L43.4 83.3'
      'A34 34 0 0 1 31.1 78.3L23.8 86.6L13.4 76.2L21.7 68.9'
      'A34 34 0 0 1 16.7 56.6L5.6 57.4L5.6 42.6L16.7 43.4'
      'A34 34 0 0 1 21.7 31.1L13.4 23.8L23.8 13.4L31.1 21.7'
      'A34 34 0 0 1 43.4 16.7Z',
    ),
    _P.accent('M33 50A17 17 0 1 1 67 50A17 17 0 1 1 33 50Z'),
    _P.ink('M43 50A7 7 0 1 1 57 50A7 7 0 1 1 43 50Z'),
  ]);

  /// Bell with a clapper.
  static const notifications = GameIconData([
    _P.accent('M41 82A9 9 0 1 1 59 82A9 9 0 1 1 41 82Z'),
    _P.body(
      'M50 14C67 14 76 27 76 44L76 56C76 62 80 66 86 70L86 76L14 76'
      'L14 70C20 66 24 62 24 56L24 44C24 27 33 14 50 14ZM43 12'
      'A7 7 0 1 1 57 12A7 7 0 1 1 43 12Z',
    ),
  ]);

  /// Letter i on a disc: details.
  static const info = GameIconData([
    _P.body('M8 50A42 42 0 1 1 92 50A42 42 0 1 1 8 50Z'),
    _P.ink('M42.5 29A7.5 7.5 0 1 1 57.5 29A7.5 7.5 0 1 1 42.5 29Z'),
    _P.ink('M50 46V72', stroke: 13),
  ]);

  /// Magnifying glass.
  static const search = GameIconData([
    _P.body('M66 66L86 86', stroke: 17),
    _P.body('M10 42A32 32 0 1 1 74 42A32 32 0 1 1 10 42Z'),
    _P.accent('M22 42A20 20 0 1 1 62 42A20 20 0 1 1 22 42Z'),
  ]);

  /// Two arrows chasing round: reload.
  static const refresh = GameIconData([
    _P.body('M19.5 44.6A31 31 0 0 1 73 29.3', stroke: 13),
    _P.body('M80.8 15.5L83.1 40.4L58.5 35.6Z', fused: true),
    _P.body('M80.5 55.4A31 31 0 0 1 27 70.7', stroke: 13),
    _P.body('M19.2 84.5L16.9 59.6L41.5 64.4Z', fused: true),
  ]);

  /// Round arrow with a play mark: play again.
  static const replay = GameIconData([
    _P.body('M17.5 55.7A33 33 0 1 0 44.3 17.5', stroke: 13),
    _P.body('M46.6 1.9L29.5 20.1L51.8 31.4Z', fused: true),
    _P.accent('M42 37L64 50L42 63Z'),
  ]);

  /// Round arrow wrapped about a coin: get it back.
  static const restore = GameIconData([
    _P.body('M17.5 55.7A33 33 0 1 0 44.3 17.5', stroke: 13),
    _P.body('M46.6 1.9L29.5 20.1L51.8 31.4Z', fused: true),
    _P.accent(
      'M50 35L54.1 45.3L65.2 46.1L56.7 53.2L59.4 63.9L50 58L40.6 63.9'
      'L43.3 53.2L34.8 46.1L45.9 45.3Z',
    ),
  ]);

  /// Pencil: rename or change.
  static const edit = GameIconData([
    _P.accent('M73.3 11.1L88.9 26.7L79 36.6L63.4 21Z'),
    _P.body('M63.4 21L79 36.6L43.6 71.9L28.1 56.4Z'),
    _P.accent('M28.1 56.4L43.6 71.9L18.9 81.1Z'),
    _P.ink('M22.8 70.9L29.1 77.2L18.9 81.1Z'),
  ]);

  /// Two stacked sheets: copy.
  static const copy = GameIconData([
    _P.accent(
      'M41 8L77 8A9 9 0 0 1 86 17L86 61A9 9 0 0 1 77 70L41 70'
      'A9 9 0 0 1 32 61L32 17A9 9 0 0 1 41 8Z',
    ),
    _P.body(
      'M23 28L59 28A9 9 0 0 1 68 37L68 81A9 9 0 0 1 59 90L23 90'
      'A9 9 0 0 1 14 81L14 37A9 9 0 0 1 23 28Z',
    ),
  ]);

  /// Paper plane: send.
  static const send = GameIconData([
    _P.body('M92 8L8 44L44 60Z'),
    _P.accent('M92 8L44 60L62 92Z'),
  ]);

  /// Arrow leaving a doorway: sign out, leave.
  static const exit = GameIconData([
    _P.body('M12 16A8 8 0 0 1 20 8H52A8 8 0 0 1 60 16V90H12Z'),
    _P.ink('M22 18H50V90H22Z'),
    _P.accent('M94 50L70 26L70 40L34 40L34 60L70 60L70 74Z'),
  ]);

  /// Arrow stepping into a doorway: join a room.
  static const enter = GameIconData([
    _P.body('M40 16A8 8 0 0 1 48 8H80A8 8 0 0 1 88 16V90H40Z'),
    _P.ink('M50 18H78V90H50Z'),
    _P.accent('M68 50L44 26L44 40L8 40L8 60L44 60L44 74Z'),
  ]);

  /// Globe: change language.
  static const language = GameIconData([
    _P.body('M8 50A42 42 0 1 1 92 50A42 42 0 1 1 8 50Z'),
    _P.ink(
      'M50 8A20 42 0 0 0 50 92A20 42 0 0 0 50 8ZM8 50H92M50 8V92'
      'M14.2 28H85.8M14.2 72H85.8',
      stroke: 5.5,
    ),
  ]);

  /// Padlock: locked until earned.
  static const lock = GameIconData([
    _P.accent('M31 44V32A19 19 0 0 1 69 32V44', stroke: 11),
    _P.body(
      'M28 40L72 40A12 12 0 0 1 84 52L84 78A12 12 0 0 1 72 90L28 90'
      'A12 12 0 0 1 16 78L16 52A12 12 0 0 1 28 40Z',
    ),
    _P.ink(
      'M42.5 60A7.5 7.5 0 1 1 57.5 60A7.5 7.5 0 1 1 42.5 60ZM46 62'
      'L54 62L56 76L44 76Z',
    ),
  ]);

  /// Open eye: look at your cards.
  static const reveal = GameIconData([
    _P.body('M6 50C22 22 78 22 94 50C78 78 22 78 6 50Z'),
    _P.accent('M31 50A19 19 0 1 1 69 50A19 19 0 1 1 31 50Z'),
    _P.ink('M41.5 50A8.5 8.5 0 1 1 58.5 50A8.5 8.5 0 1 1 41.5 50Z'),
  ]);

  /// Magnifier over a card: the Jack peek.
  static const peek = GameIconData([
    _P.accent(
      'M11.9 11.8L41.2 5.6A8 8 0 0 1 50.7 11.7L60.3 56.7'
      'A8 8 0 0 1 54.1 66.2L24.8 72.4A8 8 0 0 1 15.3 66.3L5.7 21.3'
      'A8 8 0 0 1 11.9 11.8Z',
    ),
    _P.body('M74 74L90 90', stroke: 15),
    _P.body('M35 58A25 25 0 1 1 85 58A25 25 0 1 1 35 58Z'),
    _P.accent('M45 58A15 15 0 1 1 75 58A15 15 0 1 1 45 58Z'),
  ]);

  /// Crossing arrows: mix a hand.
  static const shuffle = GameIconData([
    _P.accent('M8 28H24C44 28 52 72 72 72H78', stroke: 12),
    _P.accent('M76 57L95 72L76 87Z', fused: true),
    _P.body('M8 72H24C44 72 52 28 72 28H78', stroke: 12),
    _P.body('M76 13L95 28L76 43Z', fused: true),
  ]);

  /// Two arrows trading places: replace, exchange.
  static const swap = GameIconData([
    _P.body('M92 32L68 10L68 22L12 22L12 42L68 42L68 54Z'),
    _P.accent('M8 68L32 46L32 58L88 58L88 78L32 78L32 90Z'),
  ]);

  /// Chequered flag: finish the round.
  static const endGame = GameIconData([
    _P.accent('M20 14V92', stroke: 9),
    _P.accent('M14 10A6 6 0 1 1 26 10A6 6 0 1 1 14 10Z', fused: true),
    _P.body(
      'M24 12L28 13.7L32 15.2L36 16.2L40 16.5L44 16.2L48 15.2L52 13.7'
      'L56 12L60 10.3L64 8.8L68 7.8L72 7.5L76 7.8L80 8.8L84 10.3L88 12'
      'L88 56L84 54.3L80 52.8L76 51.8L72 51.5L68 51.8L64 52.8L60 54.3'
      'L56 56L52 57.7L48 59.2L44 60.2L40 60.5L36 60.2L32 59.2L28 57.7'
      'L24 56Z',
    ),
    _P.ink(
      'M24 12L28 13.7L32 15.2L36 16.2L40 16.5L40 31.2L36 30.8L32 29.8'
      'L28 28.4L24 26.7ZM56 12L60 10.3L64 8.8L68 7.8L72 7.5L72 22.2'
      'L68 22.5L64 23.5L60 24.9L56 26.7ZM40 31.2L44 30.8L48 29.8'
      'L52 28.4L56 26.7L56 41.3L52 43.1L48 44.5L44 45.5L40 45.8Z'
      'M72 22.2L76 22.5L80 23.5L84 24.9L88 26.7L88 41.3L84 39.6L80 38.2'
      'L76 37.2L72 36.8ZM24 41.3L28 43.1L32 44.5L36 45.5L40 45.8'
      'L40 60.5L36 60.2L32 59.2L28 57.7L24 56ZM56 41.3L60 39.6L64 38.2'
      'L68 37.2L72 36.8L72 51.5L68 51.8L64 52.8L60 54.3L56 56Z',
    ),
  ]);

  /// Flag with a warning mark: report a player.
  static const report = GameIconData([
    _P.accent('M20 14V92', stroke: 9),
    _P.accent('M14 10A6 6 0 1 1 26 10A6 6 0 1 1 14 10Z', fused: true),
    _P.body(
      'M24 12L28 13.7L32 15.2L36 16.2L40 16.5L44 16.2L48 15.2L52 13.7'
      'L56 12L60 10.3L64 8.8L68 7.8L72 7.5L76 7.8L80 8.8L84 10.3L88 12'
      'L88 56L84 54.3L80 52.8L76 51.8L72 51.5L68 51.8L64 52.8L60 54.3'
      'L56 56L52 57.7L48 59.2L44 60.2L40 60.5L36 60.2L32 59.2L28 57.7'
      'L24 56Z',
    ),
    _P.ink('M56 22V36', stroke: 8),
    _P.ink('M51.4 46A4.6 4.6 0 1 1 60.6 46A4.6 4.6 0 1 1 51.4 46Z'),
  ]);

  /// Bin: delete for good.
  static const trash = GameIconData([
    _P.accent(
      'M43 6L57 6A5 5 0 0 1 62 11L62 15A5 5 0 0 1 57 20L43 20'
      'A5 5 0 0 1 38 15L38 11A5 5 0 0 1 43 6Z',
    ),
    _P.body('M20 30L80 30L74 90L26 90Z'),
    _P.accent(
      'M18 18L82 18A6 6 0 0 1 88 24L88 26A6 6 0 0 1 82 32L18 32'
      'A6 6 0 0 1 12 26L12 24A6 6 0 0 1 18 18Z',
    ),
    _P.ink('M38 44V76M50 44V76M62 44V76', stroke: 6),
  ]);

  /// Shield with a keyhole: privacy, protection.
  static const shield = GameIconData([
    _P.body('M50 8L84 20V46C84 68 70 82 50 92C30 82 16 68 16 46V20Z'),
    _P.ink(
      'M41.5 42A8.5 8.5 0 1 1 58.5 42A8.5 8.5 0 1 1 41.5 42ZM45 46'
      'L55 46L58 66L42 66Z',
    ),
  ]);

  /// Page with a folded corner: terms.
  static const document = GameIconData([
    _P.body('M22 8H62L84 30V86Q84 92 78 92H22Q16 92 16 86V14Q16 8 22 8Z'),
    _P.accent('M62 8V24Q62 30 68 30H84Z'),
    _P.ink('M30 48H70M30 62H70M30 76H56', stroke: 6),
  ]);

  /// Open book: how to play.
  static const rules = GameIconData([
    _P.body(
      'M50 26C38 16 20 16 6 20V84C20 80 38 82 50 90C62 82 80 80 94 84'
      'V20C80 16 62 16 50 26Z',
    ),
    _P.accent('M47 24C37 16 24 14 12 16V76C24 74 37 76 47 82Z'),
    _P.accent('M53 24C63 16 76 14 88 16V76C76 74 63 76 53 82Z'),
    _P.ink(
      'M20 32C27 31 34 32 40 35M20 46C27 45 34 46 40 49M20 60'
      'C27 59 34 60 40 63',
      stroke: 4.5,
    ),
    _P.ink(
      'M70 34C73.1 38.2 80.9 42.4 80.9 48.1'
      'C80.9 51.7 77.8 53.8 74.4 53.3C72.9 53 71.6 52 71 50.9'
      'C71.3 53.8 72.3 55.9 74.2 57.7L65.8 57.7'
      'C67.7 55.9 68.7 53.8 69 50.9C68.4 52 67.1 53 65.6 53.3'
      'C62.2 53.8 59.1 51.7 59.1 48.1C59.1 42.4 66.9 38.2 70 34Z',
    ),
  ]);

  /// Two friends side by side.
  static const people = GameIconData([
    _P.accent(
      'M54 30A13 13 0 1 1 80 30A13 13 0 1 1 54 30ZM44 80'
      'C44 60 54.4 52 67 52C79.7 52 90 60 90 80Z',
    ),
    _P.body(
      'M22 35A16 16 0 1 1 54 35A16 16 0 1 1 22 35ZM8 90'
      'C8 66 21.5 58 38 58C54.5 58 68 66 68 90Z',
    ),
  ]);

  /// A group of three: the friends tab.
  static const friends = GameIconData([
    _P.accent(
      'M11 40A12 12 0 1 1 35 40A12 12 0 1 1 11 40ZM3 84'
      'C3 66 12 58 23 58C34 58 43 66 43 84Z',
    ),
    _P.accent(
      'M65 40A12 12 0 1 1 89 40A12 12 0 1 1 65 40ZM57 84'
      'C57 66 66 58 77 58C88 58 97 66 97 84Z',
    ),
    _P.body(
      'M34 32A16 16 0 1 1 66 32A16 16 0 1 1 34 32ZM21 92'
      'C21 64 34 56 50 56C66 56 79 64 79 92Z',
    ),
  ]);

  /// A single player.
  static const person = GameIconData([
    _P.body(
      'M31 30A19 19 0 1 1 69 30A19 19 0 1 1 31 30ZM14 90'
      'C14 64 30.2 56 50 56C69.8 56 86 64 86 90Z',
    ),
  ]);

  /// Player with a plus: add a friend.
  static const personAdd = GameIconData([
    _P.body(
      'M23 30A17 17 0 1 1 57 30A17 17 0 1 1 23 30ZM8 90'
      'C8 64 22.4 56 40 56C57.6 56 72 64 72 90Z',
    ),
    _P.accent('M78 46V78M62 62H94', stroke: 12),
  ]);

  /// Player with a minus: remove a friend.
  static const personRemove = GameIconData([
    _P.body(
      'M23 30A17 17 0 1 1 57 30A17 17 0 1 1 23 30ZM8 90'
      'C8 64 22.4 56 40 56C57.6 56 72 64 72 90Z',
    ),
    _P.accent('M62 62H94', stroke: 12),
  ]);

  /// Framed portrait: avatars.
  static const avatars = GameIconData([
    _P.body(
      'M26 10L74 10A16 16 0 0 1 90 26L90 74A16 16 0 0 1 74 90L26 90'
      'A16 16 0 0 1 10 74L10 26A16 16 0 0 1 26 10Z',
    ),
    _P.accent(
      'M29 20L71 20A9 9 0 0 1 80 29L80 71A9 9 0 0 1 71 80L29 80'
      'A9 9 0 0 1 20 71L20 29A9 9 0 0 1 29 20Z',
    ),
    _P.body(
      'M38 43A12 12 0 1 1 62 43A12 12 0 1 1 38 43ZM28 80'
      'C28 68 37.9 60 50 60C62.1 60 72 68 72 80Z',
    ),
  ]);

  /// Speech bubble: table chat.
  static const chat = GameIconData([
    _P.body(
      'M28 12H72A20 20 0 0 1 92 32V50A20 20 0 0 1 72 70H46L22 88L26 70'
      'A18 18 0 0 1 8 52V32A20 20 0 0 1 28 12Z',
    ),
    _P.ink(
      'M23 41A7 7 0 1 1 37 41A7 7 0 1 1 23 41ZM43 41A7 7 0 1 1 57 41'
      'A7 7 0 1 1 43 41ZM63 41A7 7 0 1 1 77 41A7 7 0 1 1 63 41Z',
    ),
  ]);

  /// Microphone: voice on.
  static const mic = GameIconData([
    _P.accent(
      'M22 44C22 62 34 72 50 72C66 72 78 62 78 44M50 72V86M34 87H66',
      stroke: 8,
    ),
    _P.body(
      'M50 6L50 6A18 18 0 0 1 68 24L68 44A18 18 0 0 1 50 62L50 62'
      'A18 18 0 0 1 32 44L32 24A18 18 0 0 1 50 6Z',
    ),
  ]);

  /// Microphone struck through: voice off.
  static const micOff = GameIconData([
    _P.accent(
      'M22 44C22 62 34 72 50 72C66 72 78 62 78 44M50 72V86M34 87H66',
      stroke: 8,
    ),
    _P.body(
      'M50 6L50 6A18 18 0 0 1 68 24L68 44A18 18 0 0 1 50 62L50 62'
      'A18 18 0 0 1 32 44L32 24A18 18 0 0 1 50 6Z',
    ),
    _P.body('M16 14L84 86', stroke: 10),
  ]);

  /// Speaker with sound waves.
  static const volume = GameIconData([
    _P.body('M10 36L28 36L52 14L52 86L28 64L10 64Z'),
    _P.accent('M64 34C71 41 71 59 64 66M75 23C88 36 88 64 75 77', stroke: 8),
  ]);

  /// Speaker with a cross: muted.
  static const volumeMute = GameIconData([
    _P.body('M10 36L28 36L52 14L52 86L28 64L10 64Z'),
    _P.accent('M66 38L88 60M88 38L66 60', stroke: 9),
  ]);

  /// Envelope: invites and requests.
  static const mail = GameIconData([
    _P.body(
      'M18 18L82 18A10 10 0 0 1 92 28L92 72A10 10 0 0 1 82 82L18 82'
      'A10 10 0 0 1 8 72L8 28A10 10 0 0 1 18 18Z',
    ),
    _P.accent('M10 22L90 22L50 54Z'),
  ]);

  /// Lightning bolt: quick match.
  static const bolt = GameIconData([
    _P.body('M62 4L16 56L46 56L36 96L84 40L54 40Z'),
  ]);

  /// Friendly robot: play against the computer.
  static const robot = GameIconData([
    _P.body(
      'M8 48L12 48A4 4 0 0 1 16 52L16 66A4 4 0 0 1 12 70L8 70'
      'A4 4 0 0 1 4 66L4 52A4 4 0 0 1 8 48ZM88 48L92 48A4 4 0 0 1 96 52'
      'L96 66A4 4 0 0 1 92 70L88 70A4 4 0 0 1 84 66L84 52'
      'A4 4 0 0 1 88 48Z',
    ),
    _P.body('M50 30V16', stroke: 7),
    _P.accent('M43 12A7 7 0 1 1 57 12A7 7 0 1 1 43 12Z'),
    _P.body(
      'M32 28L68 28A18 18 0 0 1 86 46L86 70A18 18 0 0 1 68 88L32 88'
      'A18 18 0 0 1 14 70L14 46A18 18 0 0 1 32 28Z',
    ),
    _P.accent(
      'M36 40L64 40A12 12 0 0 1 76 52L76 64A12 12 0 0 1 64 76L36 76'
      'A12 12 0 0 1 24 64L24 52A12 12 0 0 1 36 40Z',
    ),
    _P.ink(
      'M32 57A7 7 0 1 1 46 57A7 7 0 1 1 32 57ZM54 57A7 7 0 1 1 68 57'
      'A7 7 0 1 1 54 57Z',
    ),
  ]);

  /// House with a chimney: the lobby.
  static const home = GameIconData([
    _P.accent(
      'M67 12L74 12A3 3 0 0 1 77 15L77 35A3 3 0 0 1 74 38L67 38'
      'A3 3 0 0 1 64 35L64 15A3 3 0 0 1 67 12Z',
    ),
    _P.body('M18 40H82V84Q82 90 76 90H24Q18 90 18 84Z'),
    _P.accent('M50 8L94 46L6 46Z'),
    _P.ink('M41 90V71A9 9 0 0 1 59 71V90Z'),
  ]);

  /// House with a plus: open a private room.
  static const createRoom = GameIconData([
    _P.accent(
      'M67 12L74 12A3 3 0 0 1 77 15L77 35A3 3 0 0 1 74 38L67 38'
      'A3 3 0 0 1 64 35L64 15A3 3 0 0 1 67 12Z',
    ),
    _P.body('M18 40H82V84Q82 90 76 90H24Q18 90 18 84Z'),
    _P.accent('M50 8L94 46L6 46Z'),
    _P.ink('M50 55V81M37 68H63', stroke: 10),
  ]);

  /// Fan of cards: card decks.
  static const decks = GameIconData([
    _P.body(
      'M11.6 34.3L29.9 26.2A7 7 0 0 1 39.1 29.7L54.5 64.4'
      'A7 7 0 0 1 51 73.7L32.7 81.8A7 7 0 0 1 23.5 78.2L8 43.5'
      'A7 7 0 0 1 11.6 34.3Z',
    ),
    _P.body(
      'M70.1 26.2L88.4 34.3A7 7 0 0 1 92 43.5L76.5 78.2'
      'A7 7 0 0 1 67.3 81.8L49 73.7A7 7 0 0 1 45.5 64.4L60.9 29.7'
      'A7 7 0 0 1 70.1 26.2Z',
    ),
    _P.accent(
      'M40 22L60 22A7 7 0 0 1 67 29L67 67A7 7 0 0 1 60 74L40 74'
      'A7 7 0 0 1 33 67L33 29A7 7 0 0 1 40 22Z',
    ),
    _P.ink(
      'M50 36.9C52.6 40.4 59.2 43.9 59.2 48.8'
      'C59.2 51.8 56.6 53.6 53.7 53.2C52.4 52.9 51.3 52.1 50.9 51.2'
      'C51.1 53.6 52 55.4 53.5 56.9L46.5 56.9'
      'C48 55.4 48.9 53.6 49.1 51.2C48.7 52.1 47.6 52.9 46.3 53.2'
      'C43.4 53.6 40.8 51.8 40.8 48.8C40.8 43.9 47.4 40.4 50 36.9Z',
    ),
  ]);

  /// Hourglass: waiting.
  static const hourglass = GameIconData([
    _P.accent(
      'M26 18H74C74 38 57 44 57 50C57 56 74 62 74 82H26'
      'C26 62 43 56 43 50C43 44 26 38 26 18Z',
    ),
    _P.ink(
      'M38 30H62C60 38 52 42 50 45C48 42 40 38 38 30ZM32 78'
      'C36 68 46 64 50 62C54 64 64 68 68 78Z',
    ),
    _P.ink('M50 46V62', stroke: 3),
    _P.body(
      'M21 6L79 6A5 5 0 0 1 84 11L84 13A5 5 0 0 1 79 18L21 18'
      'A5 5 0 0 1 16 13L16 11A5 5 0 0 1 21 6ZM21 82L79 82'
      'A5 5 0 0 1 84 87L84 89A5 5 0 0 1 79 94L21 94A5 5 0 0 1 16 89'
      'L16 87A5 5 0 0 1 21 82Z',
    ),
  ]);

  /// Stopwatch: time left.
  static const timer = GameIconData([
    _P.body(
      'M46 4L54 4A4 4 0 0 1 58 8L58 12A4 4 0 0 1 54 16L46 16'
      'A4 4 0 0 1 42 12L42 8A4 4 0 0 1 46 4Z',
    ),
    _P.body('M12 56A38 38 0 1 1 88 56A38 38 0 1 1 12 56Z'),
    _P.accent('M22 56A28 28 0 1 1 78 56A28 28 0 1 1 22 56Z'),
    _P.body('M50 56L50 31A25 25 0 0 1 71.7 68.5Z'),
    _P.ink('M50 56L50 36', stroke: 7),
    _P.ink('M44 56A6 6 0 1 1 56 56A6 6 0 1 1 44 56Z'),
  ]);

  /// Trophy cup with a star.
  static const trophy = GameIconData([
    _P.body(
      'M28 22H18C12 22 10 28 12 34C14 42 22 48 30 48M72 22H82'
      'C88 22 90 28 88 34C86 42 78 48 70 48',
      stroke: 8,
    ),
    _P.body('M44 60H56V78H44Z'),
    _P.accent(
      'M30 76L70 76A4 4 0 0 1 74 80L74 86A4 4 0 0 1 70 90L30 90'
      'A4 4 0 0 1 26 86L26 80A4 4 0 0 1 30 76Z',
    ),
    _P.body('M24 10H76V34C76 54 64 66 50 66C36 66 24 54 24 34Z'),
    _P.accent(
      'M50 21L53.5 30.1L63.3 30.7L55.7 36.9L58.2 46.3L50 41L41.8 46.3'
      'L44.3 36.9L36.7 30.7L46.5 30.1Z',
    ),
  ]);

  /// Medal on a ribbon.
  static const medal = GameIconData([
    _P.accent('M24 4L46 4L60 44L38 44Z'),
    _P.accent('M76 4L54 4L40 44L62 44Z'),
    _P.body('M22 64A28 28 0 1 1 78 64A28 28 0 1 1 22 64Z'),
    _P.accent(
      'M50 48L54.1 58.3L65.2 59.1L56.7 66.2L59.4 76.9L50 71L40.6 76.9'
      'L43.3 66.2L34.8 59.1L45.9 58.3Z',
    ),
  ]);

  /// Crown: top spot, VIP.
  static const crown = GameIconData([
    _P.body('M10 30L32 54L50 24L68 54L90 30L82 80L18 80Z'),
    _P.accent(
      'M22 70L78 70A4 4 0 0 1 82 74L82 82A4 4 0 0 1 78 86L22 86'
      'A4 4 0 0 1 18 82L18 74A4 4 0 0 1 22 70Z',
    ),
    _P.accent(
      'M3 28A7 7 0 1 1 17 28A7 7 0 1 1 3 28ZM42 20A8 8 0 1 1 58 20'
      'A8 8 0 1 1 42 20ZM83 28A7 7 0 1 1 97 28A7 7 0 1 1 83 28Z',
    ),
  ]);

  /// Cut gem.
  static const diamond = GameIconData([
    _P.body('M28 12L72 12L92 38L50 90L8 38Z'),
    _P.accent('M28 12L72 12L92 38L8 38Z'),
    _P.accent('M30 38L70 38L50 86Z'),
  ]);

  /// Sparkles: something special.
  static const sparkles = GameIconData([
    _P.body(
      'M42 18Q49.6 48.4 80 56Q49.6 63.6 42 94Q34.4 63.6 4 56'
      'Q34.4 48.4 42 18Z',
    ),
    _P.accent('M78 5Q81 17 93 20Q81 23 78 35Q75 23 63 20Q75 17 78 5Z'),
    _P.accent('M82 70Q84 78 92 80Q84 82 82 90Q80 82 72 80Q80 78 82 70Z'),
  ]);

  /// Wrapped gift with a bow.
  static const gift = GameIconData([
    _P.accent(
      'M50 32C42 14 22 12 24 26C25 33 36 34 50 32ZM50 32'
      'C58 14 78 12 76 26C75 33 64 34 50 32Z',
    ),
    _P.body(
      'M21 44L79 44A5 5 0 0 1 84 49L84 85A5 5 0 0 1 79 90L21 90'
      'A5 5 0 0 1 16 85L16 49A5 5 0 0 1 21 44Z',
    ),
    _P.body(
      'M15 30L85 30A5 5 0 0 1 90 35L90 43A5 5 0 0 1 85 48L15 48'
      'A5 5 0 0 1 10 43L10 35A5 5 0 0 1 15 30Z',
    ),
    _P.accent('M43 30H57V90H43Z'),
  ]);

  /// Flame: daily streak.
  static const fire = GameIconData([
    _P.body(
      'M52 4C56 22 72 30 78 48C84 66 76 84 60 90C55 92 45 92 40 90'
      'C24 84 16 68 20 52C22 44 27 38 33 33C33 42 36 48 42 51'
      'C40 38 44 22 52 4Z',
    ),
    _P.accent(
      'M50 50C53 59 62 64 62 73C62 80 56.5 84 50 84C43.5 84 38 80 38 73'
      'C38 64 47 59 50 50Z',
    ),
  ]);

  /// Snowflake: a streak freeze.
  static const freeze = GameIconData([
    _P.body(
      'M50 50L50 8M50 25L39.6 15.6M50 25L60.4 15.6M50 50L86.4 29'
      'M71.7 37.5L74.6 23.8M71.7 37.5L85 41.8M50 50L86.4 71M71.7 62.5'
      'L85 58.2M71.7 62.5L74.6 76.2M50 50L50 92M50 75L60.4 84.4M50 75'
      'L39.6 84.4M50 50L13.6 71M28.3 62.5L25.4 76.2M28.3 62.5L15 58.2'
      'M50 50L13.6 29M28.3 37.5L15 41.8M28.3 37.5L25.4 23.8',
      stroke: 8.5,
    ),
  ]);

  /// TV playing a video: watch an ad for a reward.
  static const watchAd = GameIconData([
    _P.body('M34 6L50 20L66 6', stroke: 6),
    _P.body(
      'M22 20L78 20A14 14 0 0 1 92 34L92 70A14 14 0 0 1 78 84L22 84'
      'A14 14 0 0 1 8 70L8 34A14 14 0 0 1 22 20Z',
    ),
    _P.accent(
      'M25 29L75 29A8 8 0 0 1 83 37L83 67A8 8 0 0 1 75 75L25 75'
      'A8 8 0 0 1 17 67L17 37A8 8 0 0 1 25 29Z',
    ),
    _P.body('M43 40L63 52L43 64Z'),
  ]);

  /// Play button on a disc.
  static const playCircle = GameIconData([
    _P.body('M8 50A42 42 0 1 1 92 50A42 42 0 1 1 8 50Z'),
    _P.accent('M40 30L70 50L40 70Z'),
  ]);

  /// Winners podium: ranking.
  static const ranking = GameIconData([
    _P.accent(
      'M10 50L32 50A4 4 0 0 1 36 54L36 86A4 4 0 0 1 32 90L10 90'
      'A4 4 0 0 1 6 86L6 54A4 4 0 0 1 10 50Z',
    ),
    _P.accent(
      'M68 60L90 60A4 4 0 0 1 94 64L94 86A4 4 0 0 1 90 90L68 90'
      'A4 4 0 0 1 64 86L64 64A4 4 0 0 1 68 60Z',
    ),
    _P.body(
      'M38 34L62 34A4 4 0 0 1 66 38L66 86A4 4 0 0 1 62 90L38 90'
      'A4 4 0 0 1 34 86L34 38A4 4 0 0 1 38 34Z',
    ),
    _P.ink('M46 50L52 46V74', stroke: 6),
    _P.accent(
      'M50 3L53.2 11.6L62.4 12L55.2 17.7L57.6 26.5L50 21.5L42.4 26.5'
      'L44.8 17.7L37.6 12L46.8 11.6Z',
    ),
  ]);

  /// Shopping cart: the shop.
  static const shop = GameIconData([
    _P.body('M6 14H18L30 66H82', stroke: 9),
    _P.body('M22 24L92 24L82 58L30 58Z'),
    _P.accent(
      'M27.5 82A8.5 8.5 0 1 1 44.5 82A8.5 8.5 0 1 1 27.5 82ZM67.5 82'
      'A8.5 8.5 0 1 1 84.5 82A8.5 8.5 0 1 1 67.5 82Z',
    ),
  ]);

  /// Premium membership wears the crown.
  static const premium = crown;
}
