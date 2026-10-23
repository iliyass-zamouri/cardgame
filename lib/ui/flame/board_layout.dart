import 'dart:math' as math;
import 'dart:ui';

/// Single source of truth for where the board sits and where its pieces go.
///
/// The board is inset from the safe area by [hudTop] and [hudBottom] so the
/// HUD bars (prize / end game / menu above, chat / mic / action below) never
/// sit over cards. Positions are in world units; on screens shorter than
/// [_designHeight] the board zooms out uniformly instead of letting rows
/// collide. The HUD reads the seat anchors from here so player seats stay
/// aligned with the hands.
class BoardLayout {
  BoardLayout(Size board)
    : zoom = math.min(1.0, board.height / _designHeight),
      _board = board;

  /// Band above the board: top bar (44) plus breathing room.
  static const hudTop = 60.0;

  /// Band below the board: action button (54) plus its 16px margin.
  static const hudBottom = 76.0;

  // Card sizes mirror HandArea / DrawnCardSlot / TableArea.
  static const _handHalf = 112.0 / 2;
  static const _pileHalf = 124.0 / 2;
  static const _drawnHalf = 124.0 / 2;

  /// Local hand centre to board bottom: drawn card, gap, half a hand card.
  static const _bottomStack = 4 + _drawnHalf * 2 + 12 + _handHalf;

  /// Clear space between a hand and the piles, wide enough for a seat.
  static const _seatGap = 64.0;

  /// Space between hand and seat.
  static const _seatInset = 8.0;

  static const _designHeight =
      2 * (_bottomStack + _handHalf + _seatGap + _pileHalf);

  final Size _board;

  /// Camera zoom applied to the Flame world (1 on full-height phones).
  final double zoom;

  double get _worldW => _board.width / zoom;
  double get _worldH => _board.height / zoom;

  Offset get table => Offset(_worldW / 2, _worldH / 2);
  Offset get localHand => Offset(_worldW / 2, _worldH - _bottomStack);
  Offset get opponentHand => Offset(_worldW / 2, _bottomStack);
  Offset get localDrawn => Offset(56, _worldH - 4 - _drawnHalf);
  Offset get remoteDrawn => Offset(_worldW / 2, 46);

  /// Seat tops / bottoms in board pixels, for the Flutter HUD.
  double get opponentSeatTop => (_bottomStack + _handHalf + _seatInset) * zoom;
  double get localSeatBottom => (_bottomStack + _handHalf + _seatInset) * zoom;
}
