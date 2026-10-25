import 'package:cardgame/ui/theme/game_icon.dart';

typedef _P = GameIconPart;

/// The game's icon set: solid glyphs drawn for this table, on a 100x100
/// grid (see [GameIcon]).
abstract final class AppIcons {
  /// Plus: add one, buy more.
  static const add = GameIconData([_P.solid('M50 16V84M16 50H84', stroke: 13)]);

  /// Minus: take one away.
  static const remove = GameIconData([_P.solid('M16 50H84', stroke: 13)]);

  /// Arrow pointing back.
  static const arrowBack = GameIconData([
    _P.solid('M84 50H18M44 23L17 50L44 77', stroke: 11),
  ]);

  /// Arrow pointing forward.
  static const arrowForward = GameIconData([
    _P.solid('M16 50H82M56 23L83 50L56 77', stroke: 11),
  ]);

  /// Chevron: opens a row.
  static const chevronRight = GameIconData([
    _P.solid('M38 19L69 50L38 81', stroke: 12),
  ]);

  /// Cross: close or cancel.
  static const close = GameIconData([
    _P.solid('M25 25L75 75M75 25L25 75', stroke: 12),
  ]);

  /// Cross knocked out of a disc: clear a field.
  static const clear = GameIconData([
    _P.solid('M8 50A42 42 0 1 1 92 50A42 42 0 1 1 8 50Z'),
    _P.cut('M36 36L64 64M64 36L36 64', stroke: 9),
  ]);

  /// Tick: done, ready, selected.
  static const check = GameIconData([
    _P.solid('M17 52L40 74L83 28', stroke: 13),
  ]);

  /// Tick knocked out of a disc: owned, confirmed.
  static const checkCircle = GameIconData([
    _P.solid('M8 50A42 42 0 1 1 92 50A42 42 0 1 1 8 50Z'),
    _P.cut('M29 51L44 65L71 37', stroke: 10),
  ]);

  /// Three bars: open the menu.
  static const menu = GameIconData([
    _P.solid('M17 27H83M17 50H83M17 73H83', stroke: 11),
  ]);

  /// Three dots: more options.
  static const moreVert = GameIconData([
    _P.solid(
      'M41 20A9 9 0 1 1 59 20A9 9 0 1 1 41 20ZM41 50A9 9 0 1 1 59 50'
      'A9 9 0 1 1 41 50ZM41 80A9 9 0 1 1 59 80A9 9 0 1 1 41 80Z',
    ),
  ]);

  /// Cog.
  static const settings = GameIconData([
    _P.solid(
      'M43.2 15.7L43.9 4.4L56.1 4.4L56.8 15.7A35 35 0 0 1 69.4 20.9'
      'L77.9 13.4L86.6 22.1L79.1 30.6A35 35 0 0 1 84.3 43.2L95.6 43.9'
      'L95.6 56.1L84.3 56.8A35 35 0 0 1 79.1 69.4L86.6 77.9L77.9 86.6'
      'L69.4 79.1A35 35 0 0 1 56.8 84.3L56.1 95.6L43.9 95.6L43.2 84.3'
      'A35 35 0 0 1 30.6 79.1L22.1 86.6L13.4 77.9L20.9 69.4'
      'A35 35 0 0 1 15.7 56.8L4.4 56.1L4.4 43.9L15.7 43.2'
      'A35 35 0 0 1 20.9 30.6L13.4 22.1L22.1 13.4L30.6 20.9'
      'A35 35 0 0 1 43.2 15.7Z',
    ),
    _P.cut('M36 50A14 14 0 1 1 64 50A14 14 0 1 1 36 50Z'),
  ]);

  /// Bell.
  static const notifications = GameIconData([
    _P.solid(
      'M50 12C65 12 74 24 74 39V54L82 65Q85 70 79 70H21Q15 70 18 65'
      'L26 54V39C26 24 35 12 50 12ZM45 10A5 5 0 1 1 55 10'
      'A5 5 0 1 1 45 10Z',
    ),
    _P.solid('M39 78A11 11 0 0 0 61 78Z'),
  ]);

  /// Letter i knocked out of a disc: details.
  static const info = GameIconData([
    _P.solid('M8 50A42 42 0 1 1 92 50A42 42 0 1 1 8 50Z'),
    _P.cut('M43.5 30A6.5 6.5 0 1 1 56.5 30A6.5 6.5 0 1 1 43.5 30Z'),
    _P.cut(
      'M47.5 42L52.5 42A3 3 0 0 1 55.5 45L55.5 71A3 3 0 0 1 52.5 74'
      'L47.5 74A3 3 0 0 1 44.5 71L44.5 45A3 3 0 0 1 47.5 42Z',
    ),
  ]);

  /// Magnifying glass.
  static const search = GameIconData([
    _P.solid('M16 43A27 27 0 1 1 70 43A27 27 0 1 1 16 43Z', stroke: 11),
    _P.solid('M63 63L85 85', stroke: 14, fused: true),
  ]);

  /// Two arrows chasing round: reload.
  static const refresh = GameIconData([
    _P.solid('M20.1 42A31 31 0 0 1 71.9 28.1', stroke: 10),
    _P.solid('M78.3 16.1L80.4 36.6L59.9 34.4Z', fused: true),
    _P.solid('M79.9 58A31 31 0 0 1 28.1 71.9', stroke: 10),
    _P.solid('M21.7 83.9L19.6 63.4L40.1 65.6Z', fused: true),
  ]);

  /// Arrow coming round to a play mark: play again.
  static const replay = GameIconData([
    _P.solid('M17.2 58.8A34 34 0 1 0 44.1 16.5', stroke: 10),
    _P.solid('M45.6 2L31.3 18.8L50.5 29.6Z', fused: true),
    _P.solid('M42 37L63 50L42 63Z'),
  ]);

  /// Clock turned back: get your purchases back.
  static const restore = GameIconData([
    _P.solid('M17.2 58.8A34 34 0 1 0 44.1 16.5', stroke: 10),
    _P.solid('M45.6 2L31.3 18.8L50.5 29.6Z', fused: true),
    _P.solid('M50 33V51L62 59', stroke: 8),
  ]);

  /// Pencil: rename or change.
  static const edit = GameIconData([
    _P.solid('M74 11.8L88.2 26L81.8 32.3L67.7 18.2Z'),
    _P.solid('M63.4 22.4L77.6 36.6L42.9 71.2L28.8 57.1Z'),
    _P.solid('M24.5 61.3L38.7 75.5L18.2 81.8Z'),
  ]);

  /// Two sheets: copy.
  static const copy = GameIconData([
    _P.soft(
      'M40 10L76 10A8 8 0 0 1 84 18L84 62A8 8 0 0 1 76 70L40 70'
      'A8 8 0 0 1 32 62L32 18A8 8 0 0 1 40 10Z',
    ),
    _P.solid(
      'M24 30L60 30A8 8 0 0 1 68 38L68 82A8 8 0 0 1 60 90L24 90'
      'A8 8 0 0 1 16 82L16 38A8 8 0 0 1 24 30Z',
    ),
  ]);

  /// Paper plane: send.
  static const send = GameIconData([
    _P.solid('M8 45L92 10L62 91L47 57Z'),
    _P.cut('M90 12L47 57', stroke: 6),
  ]);

  /// Arrow leaving through a door: sign out, leave.
  static const exit = GameIconData([
    _P.soft('M46 14H26Q16 14 16 24V76Q16 86 26 86H46', stroke: 11),
    _P.solid('M38 50H84M66 31L85 50L66 69', stroke: 11),
  ]);

  /// Arrow stepping in through a door: join a room.
  static const enter = GameIconData([
    _P.soft('M54 14H74Q84 14 84 24V76Q84 86 74 86H54', stroke: 11),
    _P.solid('M14 50H60M42 31L61 50L42 69', stroke: 11),
  ]);

  /// Globe: change language.
  static const language = GameIconData([
    _P.solid('M8 50A42 42 0 1 1 92 50A42 42 0 1 1 8 50Z'),
    _P.cut(
      'M50 8A18 42 0 0 0 50 92A18 42 0 0 0 50 8ZM8 50H92M13.6 29H86.4'
      'M13.6 71H86.4',
      stroke: 6,
    ),
  ]);

  /// Padlock: locked until earned.
  static const lock = GameIconData([
    _P.solid('M32 46V34A18 18 0 0 1 68 34V46', stroke: 10),
    _P.solid(
      'M27 42L73 42A9 9 0 0 1 82 51L82 81A9 9 0 0 1 73 90L27 90'
      'A9 9 0 0 1 18 81L18 51A9 9 0 0 1 27 42Z',
    ),
    _P.cut(
      'M43 61A7 7 0 1 1 57 61A7 7 0 1 1 43 61ZM46.5 62L53.5 62L55 76'
      'L45 76Z',
    ),
  ]);

  /// Eye: look at your cards.
  static const reveal = GameIconData([
    _P.solid('M4 50C19 23 81 23 96 50C81 77 19 77 4 50Z'),
    _P.cut('M31 50A19 19 0 1 1 69 50A19 19 0 1 1 31 50Z'),
    _P.solid(
      'M39.5 50A10.5 10.5 0 1 1 60.5 50A10.5 10.5 0 1 1 39.5 50Z',
      fused: true,
    ),
  ]);

  /// Magnifier over a card: the Jack peek.
  static const peek = GameIconData([
    _P.soft(
      'M11.1 11.8L40.4 5.5A7 7 0 0 1 48.7 10.9L58.3 55.9'
      'A7 7 0 0 1 52.9 64.2L23.6 70.5A7 7 0 0 1 15.3 65.1L5.7 20.1'
      'A7 7 0 0 1 11.1 11.8Z',
    ),
    _P.solid('M38 58A22 22 0 1 1 82 58A22 22 0 1 1 38 58Z', stroke: 10),
    _P.solid('M76 74L90 88', stroke: 13, fused: true),
  ]);

  /// Crossing arrows: mix a hand.
  static const shuffle = GameIconData([
    _P.solid('M10 30H24C44 30 52 70 72 70H79', stroke: 10),
    _P.solid('M76 56L94 70L76 84Z', fused: true),
    _P.solid('M10 70H24C44 70 52 30 72 30H79', stroke: 10),
    _P.solid('M76 16L94 30L76 44Z', fused: true),
  ]);

  /// Two arrows trading places: replace, exchange.
  static const swap = GameIconData([
    _P.solid('M14 32H80M63 15L81 32L63 49', stroke: 11),
    _P.solid('M86 68H20M37 51L19 68L37 85', stroke: 11),
  ]);

  /// Chequered flag: finish the round.
  static const endGame = GameIconData([
    _P.solid('M17 12V92', stroke: 9),
    _P.solid(
      'M26 13L29.9 14.3L33.8 15.5L37.6 16.2L41.5 16.5L45.4 16.2'
      'L49.2 15.5L53.1 14.3L57 13L60.9 11.7L64.8 10.5L68.6 9.8L72.5 9.5'
      'L76.4 9.8L80.2 10.5L84.1 11.7L88 13L88 57L84.1 55.7L80.2 54.5'
      'L76.4 53.8L72.5 53.5L68.6 53.8L64.8 54.5L60.9 55.7L57 57'
      'L53.1 58.3L49.2 59.5L45.4 60.2L41.5 60.5L37.6 60.2L33.8 59.5'
      'L29.9 58.3L26 57Z',
    ),
    _P.cut(
      'M26 13L29.9 14.3L33.8 15.5L37.6 16.2L41.5 16.5L41.5 31.2'
      'L37.6 30.9L33.8 30.1L29.9 29L26 27.7ZM57 13L60.9 11.7L64.8 10.5'
      'L68.6 9.8L72.5 9.5L72.5 24.2L68.6 24.4L64.8 25.2L60.9 26.3'
      'L57 27.7ZM41.5 31.2L45.4 30.9L49.2 30.1L53.1 29L57 27.7L57 42.3'
      'L53.1 43.7L49.2 44.8L45.4 45.6L41.5 45.8ZM72.5 24.2L76.4 24.4'
      'L80.2 25.2L84.1 26.3L88 27.7L88 42.3L84.1 41L80.2 39.9L76.4 39.1'
      'L72.5 38.8ZM26 42.3L29.9 43.7L33.8 44.8L37.6 45.6L41.5 45.8'
      'L41.5 60.5L37.6 60.2L33.8 59.5L29.9 58.3L26 57ZM57 42.3L60.9 41'
      'L64.8 39.9L68.6 39.1L72.5 38.8L72.5 53.5L68.6 53.8L64.8 54.5'
      'L60.9 55.7L57 57Z',
    ),
  ]);

  /// Flag with a warning mark: report a player.
  static const report = GameIconData([
    _P.solid('M17 12V92', stroke: 9),
    _P.solid(
      'M26 13L29.9 14.3L33.8 15.5L37.6 16.2L41.5 16.5L45.4 16.2'
      'L49.2 15.5L53.1 14.3L57 13L60.9 11.7L64.8 10.5L68.6 9.8L72.5 9.5'
      'L76.4 9.8L80.2 10.5L84.1 11.7L88 13L88 57L84.1 55.7L80.2 54.5'
      'L76.4 53.8L72.5 53.5L68.6 53.8L64.8 54.5L60.9 55.7L57 57'
      'L53.1 58.3L49.2 59.5L45.4 60.2L41.5 60.5L37.6 60.2L33.8 59.5'
      'L29.9 58.3L26 57Z',
    ),
    _P.cut(
      'M56 22L58 22A3 3 0 0 1 61 25L61 36A3 3 0 0 1 58 39L56 39'
      'A3 3 0 0 1 53 36L53 25A3 3 0 0 1 56 22Z',
    ),
    _P.cut('M52.5 47A4.5 4.5 0 1 1 61.5 47A4.5 4.5 0 1 1 52.5 47Z'),
  ]);

  /// Bin: delete for good.
  static const trash = GameIconData([
    _P.solid('M38 21V15Q38 10 43 10H57Q62 10 62 15V21', stroke: 7),
    _P.solid('M15 25H85', stroke: 9, fused: true),
    _P.solid('M23 36L77 36L72 88L28 88Z'),
    _P.cut('M40 48V76M60 48V76', stroke: 6),
  ]);

  /// Shield with a keyhole: privacy, protection.
  static const shield = GameIconData([
    _P.solid('M50 8L84 20V46C84 68 70 82 50 92C30 82 16 68 16 46V20Z'),
    _P.cut(
      'M42 42A8 8 0 1 1 58 42A8 8 0 1 1 42 42ZM45.5 46L54.5 46L57 64'
      'L43 64Z',
    ),
  ]);

  /// Page with a folded corner: terms.
  static const document = GameIconData([
    _P.solid('M26 8H58L80 30V86Q80 92 74 92H26Q20 92 20 86V14Q20 8 26 8Z'),
    _P.soft('M58 8V25Q58 30 63 30H80Z'),
    _P.cut('M32 50H68M32 64H68M32 78H56', stroke: 6),
  ]);

  /// Open book: how to play.
  static const rules = GameIconData([
    _P.solid('M47 22C38 16 24 14 9 17V80C24 77 38 79 47 85Z'),
    _P.solid('M53 22C62 16 76 14 91 17V80C76 77 62 79 53 85Z'),
  ]);

  /// Two friends.
  static const people = GameIconData([
    _P.soft(
      'M55 29A12 12 0 1 1 79 29A12 12 0 1 1 55 29ZM45 78'
      'C45 57.7 54.9 49 67 49C79.1 49 89 57.7 89 78Z',
    ),
    _P.solid(
      'M23 33A15 15 0 1 1 53 33A15 15 0 1 1 23 33ZM9 90'
      'C9 64.1 22 53 38 53C54 53 67 64.1 67 90Z',
    ),
  ]);

  /// A group of three: the friends tab.
  static const friends = GameIconData([
    _P.soft(
      'M10 39A11 11 0 1 1 32 39A11 11 0 1 1 10 39ZM3 84'
      'C3 64.4 11.1 56 21 56C30.9 56 39 64.4 39 84Z',
    ),
    _P.soft(
      'M68 39A11 11 0 1 1 90 39A11 11 0 1 1 68 39ZM61 84'
      'C61 64.4 69.1 56 79 56C88.9 56 97 64.4 97 84Z',
    ),
    _P.solid(
      'M35 31A15 15 0 1 1 65 31A15 15 0 1 1 35 31ZM23 90'
      'C23 62.7 35.1 51 50 51C64.8 51 77 62.7 77 90Z',
    ),
  ]);

  /// A player.
  static const person = GameIconData([
    _P.solid(
      'M32 29A18 18 0 1 1 68 29A18 18 0 1 1 32 29ZM15 90'
      'C15 64.1 30.8 53 50 53C69.2 53 85 64.1 85 90Z',
    ),
  ]);

  /// Player with a plus: add a friend.
  static const personAdd = GameIconData([
    _P.solid(
      'M24 30A16 16 0 1 1 56 30A16 16 0 1 1 24 30ZM10 90'
      'C10 64.1 23.5 53 40 53C56.5 53 70 64.1 70 90Z',
    ),
    _P.solid('M78 47V77M63 62H93', stroke: 10),
  ]);

  /// Player with a minus: remove a friend.
  static const personRemove = GameIconData([
    _P.solid(
      'M24 30A16 16 0 1 1 56 30A16 16 0 1 1 24 30ZM10 90'
      'C10 64.1 23.5 53 40 53C56.5 53 70 64.1 70 90Z',
    ),
    _P.solid('M63 62H93', stroke: 10),
  ]);

  /// Portrait in a frame: avatars.
  static const avatars = GameIconData([
    _P.solid(
      'M24 10L76 10A14 14 0 0 1 90 24L90 76A14 14 0 0 1 76 90L24 90'
      'A14 14 0 0 1 10 76L10 24A14 14 0 0 1 24 10Z',
    ),
    _P.cut(
      'M38 40A12 12 0 1 1 62 40A12 12 0 1 1 38 40ZM28 80'
      'C28 63.2 37.9 56 50 56C62.1 56 72 63.2 72 80Z',
    ),
  ]);

  /// Speech bubble: table chat.
  static const chat = GameIconData([
    _P.solid(
      'M26 12H74A18 18 0 0 1 92 30V52A18 18 0 0 1 74 70H46L24 88V70'
      'A16 16 0 0 1 8 52V30A18 18 0 0 1 26 12Z',
    ),
    _P.cut(
      'M24.5 41A6.5 6.5 0 1 1 37.5 41A6.5 6.5 0 1 1 24.5 41ZM43.5 41'
      'A6.5 6.5 0 1 1 56.5 41A6.5 6.5 0 1 1 43.5 41ZM62.5 41'
      'A6.5 6.5 0 1 1 75.5 41A6.5 6.5 0 1 1 62.5 41Z',
    ),
  ]);

  /// Microphone: voice on.
  static const mic = GameIconData([
    _P.solid(
      'M24 46C24 62 36 72 50 72C64 72 76 62 76 46M50 72V86M36 88H64',
      stroke: 9,
    ),
    _P.solid(
      'M50 8L50 8A16 16 0 0 1 66 24L66 46A16 16 0 0 1 50 62L50 62'
      'A16 16 0 0 1 34 46L34 24A16 16 0 0 1 50 8Z',
    ),
  ]);

  /// Microphone struck through: voice off.
  static const micOff = GameIconData([
    _P.solid(
      'M24 46C24 62 36 72 50 72C64 72 76 62 76 46M50 72V86M36 88H64',
      stroke: 9,
    ),
    _P.solid(
      'M50 8L50 8A16 16 0 0 1 66 24L66 46A16 16 0 0 1 50 62L50 62'
      'A16 16 0 0 1 34 46L34 24A16 16 0 0 1 50 8Z',
    ),
    _P.solid('M16 14L84 86', stroke: 9),
  ]);

  /// Speaker with sound waves.
  static const volume = GameIconData([
    _P.solid('M10 36L28 36L52 15L52 85L28 64L10 64Z'),
    _P.solid('M66 36C72 42 72 58 66 64M77 25C90 38 90 62 77 75', stroke: 9),
  ]);

  /// Speaker with a cross: muted.
  static const volumeMute = GameIconData([
    _P.solid('M10 36L28 36L52 15L52 85L28 64L10 64Z'),
    _P.solid('M66 39L88 61M88 39L66 61', stroke: 9),
  ]);

  /// Envelope: invites and requests.
  static const mail = GameIconData([
    _P.solid(
      'M17 18L83 18A9 9 0 0 1 92 27L92 73A9 9 0 0 1 83 82L17 82'
      'A9 9 0 0 1 8 73L8 27A9 9 0 0 1 17 18Z',
    ),
    _P.cut('M15 27L50 54L85 27', stroke: 6),
  ]);

  /// Lightning bolt: quick match.
  static const bolt = GameIconData([
    _P.solid('M60 4L17 57L46 57L38 96L83 41L54 41Z'),
  ]);

  /// Robot: play against the computer.
  static const robot = GameIconData([
    _P.solid(
      'M7 47L9 47A3 3 0 0 1 12 50L12 66A3 3 0 0 1 9 69L7 69'
      'A3 3 0 0 1 4 66L4 50A3 3 0 0 1 7 47ZM91 47L93 47A3 3 0 0 1 96 50'
      'L96 66A3 3 0 0 1 93 69L91 69A3 3 0 0 1 88 66L88 50'
      'A3 3 0 0 1 91 47Z',
    ),
    _P.solid('M50 30V17', stroke: 6),
    _P.solid('M44 12A6 6 0 1 1 56 12A6 6 0 1 1 44 12Z', fused: true),
    _P.solid(
      'M28 28L72 28A14 14 0 0 1 86 42L86 72A14 14 0 0 1 72 86L28 86'
      'A14 14 0 0 1 14 72L14 42A14 14 0 0 1 28 28Z',
    ),
    _P.cut(
      'M33 46L39 46A4 4 0 0 1 43 50L43 56A4 4 0 0 1 39 60L33 60'
      'A4 4 0 0 1 29 56L29 50A4 4 0 0 1 33 46ZM61 46L67 46'
      'A4 4 0 0 1 71 50L71 56A4 4 0 0 1 67 60L61 60A4 4 0 0 1 57 56'
      'L57 50A4 4 0 0 1 61 46Z',
    ),
    _P.cut('M40 73H60', stroke: 5),
  ]);

  /// House: the lobby.
  static const home = GameIconData([
    _P.solid(
      'M50 10L88 42V84Q88 90 82 90H18Q12 90 12 84V42ZM68 14L75 14'
      'A2 2 0 0 1 77 16L77 36A2 2 0 0 1 75 38L68 38A2 2 0 0 1 66 36'
      'L66 16A2 2 0 0 1 68 14Z',
    ),
    _P.cut('M42 90V71Q42 65 48 65H52Q58 65 58 71V90Z'),
  ]);

  /// House with a plus: open a private room.
  static const createRoom = GameIconData([
    _P.solid(
      'M50 10L88 42V84Q88 90 82 90H18Q12 90 12 84V42ZM68 14L75 14'
      'A2 2 0 0 1 77 16L77 36A2 2 0 0 1 75 38L68 38A2 2 0 0 1 66 36'
      'L66 16A2 2 0 0 1 68 14Z',
    ),
    _P.cut('M50 52V80M36 66H64', stroke: 8),
  ]);

  /// Fan of cards: card decks.
  static const decks = GameIconData([
    _P.soft(
      'M10.7 34.7L30.8 25.8A6 6 0 0 1 38.7 28.8L55 65.3'
      'A6 6 0 0 1 51.9 73.3L31.8 82.2A6 6 0 0 1 23.9 79.2L7.6 42.6'
      'A6 6 0 0 1 10.7 34.7Z',
    ),
    _P.soft(
      'M69.2 25.8L89.3 34.7A6 6 0 0 1 92.4 42.6L76.1 79.2'
      'A6 6 0 0 1 68.2 82.2L48.1 73.3A6 6 0 0 1 45 65.3L61.3 28.8'
      'A6 6 0 0 1 69.2 25.8Z',
    ),
    _P.solid(
      'M39 22L61 22A6 6 0 0 1 67 28L67 68A6 6 0 0 1 61 74L39 74'
      'A6 6 0 0 1 33 68L33 28A6 6 0 0 1 39 22Z',
    ),
    _P.cut(
      'M50 37.9C52.6 41.4 59.2 44.9 59.2 49.8'
      'C59.2 52.8 56.6 54.6 53.7 54.2C52.4 53.9 51.3 53.1 50.9 52.2'
      'C51.1 54.6 52 56.4 53.5 57.9L46.5 57.9'
      'C48 56.4 48.9 54.6 49.1 52.2C48.7 53.1 47.6 53.9 46.3 54.2'
      'C43.4 54.6 40.8 52.8 40.8 49.8C40.8 44.9 47.4 41.4 50 37.9Z',
    ),
  ]);

  /// Hourglass: waiting.
  static const hourglass = GameIconData([
    _P.soft(
      'M27 16H73C73 36 57 44 57 50C57 56 73 64 73 84H27'
      'C27 64 43 56 43 50C43 44 27 36 27 16Z',
    ),
    _P.solid(
      'M37 26H63C61 34 54 40 50 44C46 40 39 34 37 26ZM31 79'
      'C35 70 44 66 50 64C56 66 65 70 69 79Z',
    ),
    _P.solid(
      'M21 6L79 6A4 4 0 0 1 83 10L83 12A4 4 0 0 1 79 16L21 16'
      'A4 4 0 0 1 17 12L17 10A4 4 0 0 1 21 6ZM21 84L79 84'
      'A4 4 0 0 1 83 88L83 90A4 4 0 0 1 79 94L21 94A4 4 0 0 1 17 90'
      'L17 88A4 4 0 0 1 21 84Z',
    ),
  ]);

  /// Stopwatch: time left.
  static const timer = GameIconData([
    _P.solid(
      'M44 5L56 5A3 3 0 0 1 59 8L59 12A3 3 0 0 1 56 15L44 15'
      'A3 3 0 0 1 41 12L41 8A3 3 0 0 1 44 5Z',
    ),
    _P.solid('M16 56A34 34 0 1 1 84 56A34 34 0 1 1 16 56Z', stroke: 10),
    _P.solid('M50 56V37', stroke: 8),
    _P.solid('M44 56A6 6 0 1 1 56 56A6 6 0 1 1 44 56Z', fused: true),
  ]);

  /// Trophy cup.
  static const trophy = GameIconData([
    _P.solid(
      'M27 22H17Q12 22 12 28C12 38 20 46 30 46M73 22H83Q88 22 88 28'
      'C88 38 80 46 70 46',
      stroke: 8,
    ),
    _P.solid('M26 12H74V36C74 52 64 62 50 62C36 62 26 52 26 36Z'),
    _P.solid('M44 60H56V76H44Z', fused: true),
    _P.solid(
      'M32 76L68 76A4 4 0 0 1 72 80L72 84A4 4 0 0 1 68 88L32 88'
      'A4 4 0 0 1 28 84L28 80A4 4 0 0 1 32 76Z',
    ),
    _P.cut(
      'M50 22L52.9 30L61.4 30.3L54.8 35.5L57.1 43.7L50 39L42.9 43.7'
      'L45.2 35.5L38.6 30.3L47.1 30Z',
    ),
  ]);

  /// Medal on a ribbon.
  static const medal = GameIconData([
    _P.soft('M25 4L44 4L58 38L39 38Z'),
    _P.soft('M75 4L56 4L42 38L61 38Z'),
    _P.solid('M23 64A27 27 0 1 1 77 64A27 27 0 1 1 23 64Z'),
    _P.cut(
      'M50 50L53.5 59.1L63.3 59.7L55.7 65.9L58.2 75.3L50 70L41.8 75.3'
      'L44.3 65.9L36.7 59.7L46.5 59.1Z',
    ),
  ]);

  /// Crown: top spot, VIP.
  static const crown = GameIconData([
    _P.solid(
      'M10 30L31 50L50 22L69 50L90 30L82 70L18 70ZM4.5 28'
      'A5.5 5.5 0 1 1 15.5 28A5.5 5.5 0 1 1 4.5 28ZM44 19'
      'A6 6 0 1 1 56 19A6 6 0 1 1 44 19ZM84.5 28A5.5 5.5 0 1 1 95.5 28'
      'A5.5 5.5 0 1 1 84.5 28Z',
    ),
    _P.solid(
      'M21 76L79 76A3 3 0 0 1 82 79L82 84A3 3 0 0 1 79 87L21 87'
      'A3 3 0 0 1 18 84L18 79A3 3 0 0 1 21 76Z',
    ),
  ]);

  /// Cut gem.
  static const diamond = GameIconData([
    _P.solid('M28 14L72 14L92 38L50 88L8 38Z'),
    _P.cut('M10 38H90M31 38L50 84L69 38M37 15L31 38M63 15L69 38', stroke: 5),
  ]);

  /// Sparkles: something special.
  static const sparkles = GameIconData([
    _P.solid(
      'M42 20Q49.2 48.8 78 56Q49.2 63.2 42 92Q34.8 63.2 6 56'
      'Q34.8 48.8 42 20Z',
    ),
    _P.soft(
      'M78 6Q80.8 17.2 92 20Q80.8 22.8 78 34Q75.2 22.8 64 20'
      'Q75.2 17.2 78 6Z',
    ),
    _P.soft(
      'M82 71Q83.8 78.2 91 80Q83.8 81.8 82 89Q80.2 81.8 73 80'
      'Q80.2 78.2 82 71Z',
    ),
  ]);

  /// Wrapped gift.
  static const gift = GameIconData([
    _P.solid(
      'M50 30C44 15 26 12 26 24C26 30 36 32 50 30ZM50 30'
      'C56 15 74 12 74 24C74 30 64 32 50 30Z',
    ),
    _P.solid(
      'M14 32L86 32A4 4 0 0 1 90 36L90 44A4 4 0 0 1 86 48L14 48'
      'A4 4 0 0 1 10 44L10 36A4 4 0 0 1 14 32Z',
    ),
    _P.solid(
      'M20 52L80 52A4 4 0 0 1 84 56L84 86A4 4 0 0 1 80 90L20 90'
      'A4 4 0 0 1 16 86L16 56A4 4 0 0 1 20 52Z',
    ),
    _P.cut('M50 32V90', stroke: 9),
  ]);

  /// Flame: daily streak.
  static const fire = GameIconData([
    _P.solid(
      'M52 4C56 22 72 30 78 48C84 66 76 84 60 90C55 92 45 92 40 90'
      'C24 84 16 68 20 52C22 44 27 38 33 33C33 42 36 48 42 51'
      'C40 38 44 22 52 4Z',
    ),
    _P.cut(
      'M50 52C53 60 62 65 62 74C62 81 56.5 85 50 85C43.5 85 38 81 38 74'
      'C38 65 47 60 50 52Z',
    ),
  ]);

  /// Snowflake: a streak freeze.
  static const freeze = GameIconData([
    _P.solid(
      'M50 50L50 8M50 24L40.3 15.3M50 24L59.7 15.3M50 50L86.4 29'
      'M72.5 37L75.2 24.3M72.5 37L84.9 41M50 50L86.4 71M72.5 63L84.9 59'
      'M72.5 63L75.2 75.7M50 50L50 92M50 76L59.7 84.7M50 76L40.3 84.7'
      'M50 50L13.6 71M27.5 63L24.8 75.7M27.5 63L15.1 59M50 50L13.6 29'
      'M27.5 37L15.1 41M27.5 37L24.8 24.3',
      stroke: 8,
    ),
  ]);

  /// Screen playing a video: watch an ad for a reward.
  static const watchAd = GameIconData([
    _P.solid(
      'M16 12L84 12A10 10 0 0 1 94 22L94 62A10 10 0 0 1 84 72L16 72'
      'A10 10 0 0 1 6 62L6 22A10 10 0 0 1 16 12Z',
    ),
    _P.cut('M42 30L63 42L42 54Z'),
    _P.solid('M50 74V84', stroke: 8),
    _P.solid('M32 88H68', stroke: 8, fused: true),
  ]);

  /// Play mark knocked out of a disc.
  static const playCircle = GameIconData([
    _P.solid('M8 50A42 42 0 1 1 92 50A42 42 0 1 1 8 50Z'),
    _P.cut('M41 32L68 50L41 68Z'),
  ]);

  /// Winners podium: ranking.
  static const ranking = GameIconData([
    _P.solid(
      'M11 54L31 54A3 3 0 0 1 34 57L34 87A3 3 0 0 1 31 90L11 90'
      'A3 3 0 0 1 8 87L8 57A3 3 0 0 1 11 54Z',
    ),
    _P.solid(
      'M69 64L89 64A3 3 0 0 1 92 67L92 87A3 3 0 0 1 89 90L69 90'
      'A3 3 0 0 1 66 87L66 67A3 3 0 0 1 69 64Z',
    ),
    _P.solid(
      'M40 38L60 38A3 3 0 0 1 63 41L63 87A3 3 0 0 1 60 90L40 90'
      'A3 3 0 0 1 37 87L37 41A3 3 0 0 1 40 38Z',
    ),
    _P.cut('M47 53L52 49V76', stroke: 5.5),
    _P.solid(
      'M50 5L52.9 13L61.4 13.3L54.8 18.5L57.1 26.7L50 22L42.9 26.7'
      'L45.2 18.5L38.6 13.3L47.1 13Z',
    ),
  ]);

  /// Shopping cart: the shop.
  static const shop = GameIconData([
    _P.solid('M6 14H18L30 66H82', stroke: 9),
    _P.solid('M24 24L92 24L84 56L32 56Z'),
    _P.solid(
      'M29 82A7 7 0 1 1 43 82A7 7 0 1 1 29 82ZM69 82A7 7 0 1 1 83 82'
      'A7 7 0 1 1 69 82Z',
    ),
  ]);

  /// Premium membership wears the crown.
  static const premium = crown;
}
