import 'package:flutter/widgets.dart';
import 'package:cardgame/l10n/app_localizations.dart';

export 'package:cardgame/l10n/app_localizations.dart';

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

String localizeErrorCode(AppLocalizations l10n, String? code) {
  return switch (code) {
    'connection_lost' => l10n.errConnectionLost,
    'enter_room_code' => l10n.errEnterRoomCode,
    'server_not_connected' => l10n.errServerNotConnected,
    'command_failed' => l10n.errCommandFailed,
    'room_full' => l10n.errRoomFull,
    'waiting_for_player' => l10n.errWaitingForPlayer,
    'already_started' => l10n.errAlreadyStarted,
    'not_ended' => l10n.errNotEnded,
    'already_launched' => l10n.errAlreadyLaunched,
    'already_drew' => l10n.errAlreadyDrew,
    'deck_empty' => l10n.errDeckEmpty,
    'no_jack' => l10n.errNoJack,
    'peek_used' => l10n.errPeekUsed,
    'invalid_side' => l10n.errInvalidSide,
    'invalid_card' => l10n.errInvalidCard,
    'cannot_shuffle' => l10n.errCannotShuffle,
    'draw_first' => l10n.errDrawFirst,
    'no_hand_card' => l10n.errNoHandCard,
    'not_in_room' => l10n.errNotInRoom,
    'not_your_turn' => l10n.errNotYourTurn,
    'reveal_first' => l10n.errRevealFirst,
    'not_playing' => l10n.errNotPlaying,
    'peek_in_progress' => l10n.errPeekInProgress,
    'queen_in_progress' => l10n.errQueenInProgress,
    'no_queen' => l10n.errNoQueen,
    'queen_used' => l10n.errQueenUsed,
    'invalid_command' => l10n.errInvalidCommand,
    'room_not_found' => l10n.errRoomNotFound,
    'unknown_command' => l10n.errUnknownCommand,
    'too_many_commands' => l10n.errTooManyCommands,
    _ => l10n.errCommandFailed,
  };
}
