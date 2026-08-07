// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'ShadowHand';

  @override
  String authError(String error) {
    return 'Auth error: $error';
  }

  @override
  String get signInToPlay => 'Sign in to play online';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get signingIn => 'Signing in…';

  @override
  String get playAsGuest => 'Play as Guest';

  @override
  String get entering => 'Entering…';

  @override
  String get guestSignInServerDown =>
      'Guest sign-in failed. Is the server running?';

  @override
  String get guestSignInConnection => 'Guest sign-in failed. Check connection.';

  @override
  String get googleSignInFailed => 'Google sign-in failed. Try again.';

  @override
  String get tagline => 'Two players. One table.';

  @override
  String get findMatch => 'Find match';

  @override
  String get createRoom => 'Create room';

  @override
  String get joinRoom => 'Join room';

  @override
  String get retryConnection => 'Retry connection';

  @override
  String get howToPlay => 'How to play';

  @override
  String get deck => 'Deck';

  @override
  String get signOut => 'Sign out';

  @override
  String get guest => 'Guest';

  @override
  String get google => 'Google';

  @override
  String get player => 'Player';

  @override
  String get online => 'Online';

  @override
  String get connecting => 'Connecting';

  @override
  String get offline => 'Offline';

  @override
  String get joinRoomTitle => 'Join room';

  @override
  String get joinRoomHint => 'Enter the 6-letter code from your friend.';

  @override
  String get codeHint => 'CODE';

  @override
  String get cancel => 'Cancel';

  @override
  String get join => 'Join';

  @override
  String get findingOpponent => 'Finding opponent';

  @override
  String get matchmakingHint => 'Hang tight — matching you with a player.';

  @override
  String get privateTable => 'Private table';

  @override
  String get shareCodeWithFriend => 'Share this code with a friend';

  @override
  String waitingForOpponentNamed(String name) {
    return 'Waiting for $name…';
  }

  @override
  String opponentIsReady(String name) {
    return '$name is ready';
  }

  @override
  String get bothPlayersJoined => 'Both players joined';

  @override
  String get codeCopied => 'Code copied';

  @override
  String get tapToCopy => 'Tap to copy';

  @override
  String get ready => 'Ready';

  @override
  String get waitingEllipsis => 'Waiting…';

  @override
  String get leaveRoom => 'Leave room';

  @override
  String get vs => 'VS';

  @override
  String get you => 'You';

  @override
  String get notReady => 'Not ready';

  @override
  String get waitingEllipsisShort => 'Waiting…';

  @override
  String get endGame => 'End game';

  @override
  String get menu => 'Menu';

  @override
  String get endGameTitle => 'End game?';

  @override
  String get endGameMessage => 'Cards get revealed and scores are counted.';

  @override
  String get reveal => 'Reveal';

  @override
  String get peek => 'Peek';

  @override
  String get shuffle => 'Shuffle';

  @override
  String get replace => 'Replace';

  @override
  String get waitingOpponentReveal =>
      'Waiting for opponent to see their cards…';

  @override
  String get gameOver => 'Game over';

  @override
  String get victory => 'Victory';

  @override
  String get defeat => 'Defeat';

  @override
  String get draw => 'Draw';

  @override
  String seriesScore(int yours, int theirs) {
    return 'SERIES  $yours – $theirs';
  }

  @override
  String get opponent => 'Opponent';

  @override
  String get waitingRematch => 'Waiting for opponent to rematch…';

  @override
  String opponentAskingRematch(String name) {
    return '$name is asking for a rematch';
  }

  @override
  String get leave => 'Leave';

  @override
  String get rematch => 'Rematch';

  @override
  String get points => 'pts';

  @override
  String get roomInfo => 'Room info';

  @override
  String roomCodePlaying(String roomId, String turn) {
    return '$roomId · $turn';
  }

  @override
  String codeRoomId(String roomId) {
    return 'Code $roomId';
  }

  @override
  String roomToastPlaying(String roomId, String turn) {
    return 'Room $roomId · $turn';
  }

  @override
  String roomToast(String roomId) {
    return 'Room $roomId';
  }

  @override
  String get yourTurn => 'Your turn';

  @override
  String get opponentTurn => 'Opponent turn';

  @override
  String get leaveRoomTitle => 'Leave room?';

  @override
  String get leaveRoomMessage => 'You will drop out of this game.';

  @override
  String stepOf(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get gotIt => 'Got it';

  @override
  String get ruleGoalTitle => 'Goal';

  @override
  String get ruleGoalBody =>
      'Empty your four cards, or hold the lowest score when the game ends. Lowest total wins.';

  @override
  String get ruleSetupTitle => 'Setup';

  @override
  String get ruleSetupBody => 'Two players. Each gets four face-down cards.';

  @override
  String get ruleOpeningPeekTitle => 'Opening peek';

  @override
  String get ruleOpeningPeekBody =>
      'Before play, both players peek at two of their own cards (bottom row) for a few seconds. Remember them — then they flip face-down again.';

  @override
  String get ruleYourTurnTitle => 'Your turn';

  @override
  String get ruleYourTurnBody =>
      'Draw from the deck, or if the discard top matches a card you know, tap that card to discard it (your turn continues). Wrong guess = a penalty card into your layout.';

  @override
  String get ruleAfterDrawTitle => 'After you draw';

  @override
  String get ruleAfterDrawBody =>
      'Tap one of your cards to swap (different rank) or double-discard (same rank), or throw the drawn card to the discard pile. Then your turn ends.';

  @override
  String get ruleSpecialTitle => 'Special cards';

  @override
  String get ruleSpecialBody =>
      'These ranks trigger an ability when you draw them. After the ability, the card is thrown.';

  @override
  String get ruleJackLabel => 'Jack';

  @override
  String get ruleJackDesc =>
      'Peek one card — yours or theirs — then the Jack is thrown.';

  @override
  String get ruleQueenLabel => 'Queen';

  @override
  String get ruleQueenDesc =>
      'Shuffle a hand, or swap one of yours with one of theirs, then the Queen is thrown.';

  @override
  String get ruleScoringTitle => 'Scoring';

  @override
  String get ruleScoringBody =>
      'When someone empties their layout (or the game ends), sum remaining cards. Lower total wins; equal = tie.';

  @override
  String get ruleJokerLabel => 'Joker';

  @override
  String get ruleJokerDesc => 'Counts as −1 point.';

  @override
  String get ruleBlackKingLabel => 'Black King';

  @override
  String get ruleBlackKingDesc =>
      'Clubs or spades King counts as 0. Red Kings count as 13.';

  @override
  String get hintPeek => 'Tap any card to peek…';

  @override
  String get hintShufflePick => 'Tap Shuffle above a hand…';

  @override
  String get hintReplaceFirst => 'Tap one card from each hand…';

  @override
  String get hintReplaceSecond => 'Tap a card on the other hand…';

  @override
  String get errConnectionLost => 'Connection lost';

  @override
  String get errEnterRoomCode => 'Enter a room code';

  @override
  String get errServerNotConnected => 'Server is not connected';

  @override
  String get errCommandFailed => 'Command failed';

  @override
  String get errRoomFull => 'Room already has two players';

  @override
  String get errWaitingForPlayer => 'Two players required';

  @override
  String get errAlreadyStarted => 'Game already started';

  @override
  String get errNotEnded => 'Game is not over';

  @override
  String get errAlreadyLaunched => 'Cards already revealed';

  @override
  String get errAlreadyDrew => 'Throw or swap drawn card first';

  @override
  String get errDeckEmpty => 'No cards available';

  @override
  String get errNoJack => 'Jack peek requires a drawn Jack';

  @override
  String get errPeekUsed => 'Jack peek already used';

  @override
  String get errInvalidSide => 'Invalid side';

  @override
  String get errInvalidCard => 'Card index is invalid';

  @override
  String get errCannotShuffle => 'Not enough cards to shuffle';

  @override
  String get errDrawFirst => 'Draw a card first';

  @override
  String get errNoHandCard => 'Draw a card first';

  @override
  String get errNotInRoom => 'Join room first';

  @override
  String get errNotYourTurn => 'It is not your turn';

  @override
  String get errRevealFirst => 'Both players must reveal first';

  @override
  String get errNotPlaying => 'Game is not running';

  @override
  String get errPeekInProgress => 'Wait for peek to finish';

  @override
  String get errQueenInProgress => 'Wait for Queen ability to finish';

  @override
  String get errNoQueen => 'Queen ability requires a drawn Queen';

  @override
  String get errQueenUsed => 'Queen ability already used';

  @override
  String get errInvalidCommand => 'Command type is required';

  @override
  String get errRoomNotFound => 'Room not found';

  @override
  String get errUnknownCommand => 'Unknown command';

  @override
  String get errTooManyCommands => 'Too many commands';

  @override
  String get globalRanking => 'Global Ranking';

  @override
  String get leaderboard => 'Leaderboard';

  @override
  String get matchHistory => 'Match History';

  @override
  String get elo => 'Elo';

  @override
  String get rankingEmpty => 'No ranked players yet. Play a random match!';

  @override
  String get matchHistoryEmpty => 'No ranked matches yet.';

  @override
  String get rankingLoadError =>
      'Could not load ranking. Is the server running?';

  @override
  String get matchResultWin => 'WIN';

  @override
  String get matchResultLoss => 'LOSS';

  @override
  String get matchResultDraw => 'DRAW';

  @override
  String recordWinsLossesDraws(int wins, int losses, int draws) {
    return '${wins}W · ${losses}L · ${draws}D';
  }

  @override
  String matchScoreLine(int myScore, int oppScore) {
    return 'You $myScore · Opp $oppScore';
  }
}
