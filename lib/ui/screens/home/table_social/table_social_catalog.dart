import 'package:cardgame/l10n/app_localizations.dart';

/// Reaction emojis by id. Ids are what goes over the wire (server allowlist
/// in `server/chat/room_chat.js`).
const tableEmojis = <String, String>{
  'laugh': '😂',
  'love': '😍',
  'cry': '😭',
  'angry': '😡',
  'cool': '😎',
  'shock': '😱',
  'fist': '👊',
  'clap': '👏',
};

/// Quick phrase ids in display order, three per row; bluffs grouped in
/// rows four and five (server allowlist mirrors this).
const tablePhraseIds = [
  'hello',
  'goodLuck',
  'wellPlayed',
  'niceSwap',
  'sharpMemory',
  'playFast',
  'stopPeeking',
  'giveCardBack',
  'blackKingPlease',
  'foundJoker',
  'knowMyCards',
  'lowTotal',
  'endingNextTurn',
  'unlucky',
  'oops',
  'thanks',
  'hehe',
  'gg',
];

/// Each player reads phrases in their own language.
String tablePhraseLabel(AppLocalizations l10n, String phraseId) {
  return switch (phraseId) {
    'hello' => l10n.phraseHello,
    'goodLuck' => l10n.phraseGoodLuck,
    'wellPlayed' => l10n.phraseWellPlayed,
    'niceSwap' => l10n.phraseNiceSwap,
    'sharpMemory' => l10n.phraseSharpMemory,
    'playFast' => l10n.phrasePlayFast,
    'stopPeeking' => l10n.phraseStopPeeking,
    'giveCardBack' => l10n.phraseGiveCardBack,
    'blackKingPlease' => l10n.phraseBlackKingPlease,
    'foundJoker' => l10n.phraseFoundJoker,
    'knowMyCards' => l10n.phraseKnowMyCards,
    'lowTotal' => l10n.phraseLowTotal,
    'endingNextTurn' => l10n.phraseEndingNextTurn,
    'unlucky' => l10n.phraseUnlucky,
    'oops' => l10n.phraseOops,
    'thanks' => l10n.phraseThanks,
    'hehe' => l10n.phraseHehe,
    'gg' => l10n.phraseGg,
    _ => phraseId,
  };
}
