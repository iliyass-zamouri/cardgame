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
  String get playVsRobot => 'Practice vs Robot';

  @override
  String get robotName => 'Robot';

  @override
  String get retryConnection => 'Retry connection';

  @override
  String get howToPlay => 'How to play';

  @override
  String get deck => 'Deck';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get changeLanguage => 'Change language';

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
  String get marketplace => 'Marketplace';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get marketplaceComingSoonBody =>
      'Card skins and extras will show up here.';

  @override
  String get leaderboard => 'Leaderboard';

  @override
  String get matchHistory => 'Match History';

  @override
  String get elo => 'Elo';

  @override
  String get colWins => 'W';

  @override
  String get colLosses => 'L';

  @override
  String get colDraws => 'D';

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

  @override
  String get friends => 'Friends';

  @override
  String get friendsComingSoonBody =>
      'Connect with friends and invite them to matches soon.';

  @override
  String get requests => 'Requests';

  @override
  String get addFriend => 'Add Friend';

  @override
  String get searchByUsername => 'Search by @username or name...';

  @override
  String get noFriendsYet => 'No friends added yet.';

  @override
  String get noFriendsHint =>
      'Search player usernames in Add Friend tab to connect!';

  @override
  String get noRequests => 'No pending friend requests.';

  @override
  String get incomingRequests => 'Incoming Requests';

  @override
  String get outgoingRequests => 'Outgoing Requests';

  @override
  String get accept => 'Accept';

  @override
  String get decline => 'Decline';

  @override
  String get removeFriend => 'Remove Friend';

  @override
  String removeFriendConfirm(String name) {
    return 'Are you sure you want to remove $name from friends?';
  }

  @override
  String get friendRequestSent => 'Friend request sent!';

  @override
  String get friendRequestAccepted => 'Friend request accepted!';

  @override
  String friendRequestFrom(String name) {
    return '$name sent you a friend request';
  }

  @override
  String friendRequestAcceptedBy(String name) {
    return '$name accepted your friend request';
  }

  @override
  String get friendRemoved => 'Friend removed.';

  @override
  String get requestSent => 'Sent';

  @override
  String get youTag => 'You';

  @override
  String get alreadyFriends => 'Friends';

  @override
  String get changeUsername => 'Change Username';

  @override
  String get usernameHint => 'unique_username';

  @override
  String get usernameAvailable => 'Username is available';

  @override
  String get usernameTaken => 'Username is already taken';

  @override
  String get usernameInvalidFormat =>
      '3-20 characters: lowercase letters, numbers, _';

  @override
  String get save => 'Save';

  @override
  String get displayName => 'Display Name';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get profileUpdated => 'Profile updated successfully!';

  @override
  String get searching => 'Searching...';

  @override
  String get noPlayersFound => 'No players found matching your search.';

  @override
  String get profile => 'Profile';

  @override
  String level(int lvl) {
    return 'Level $lvl';
  }

  @override
  String levelNumber(int lvl) {
    return 'Level $lvl';
  }

  @override
  String get xp => 'XP';

  @override
  String get winRate => 'Win Rate';

  @override
  String get matchesPlayed => 'Matches';

  @override
  String get totalXp => 'Total XP';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get rankTitleNovice => 'Novice';

  @override
  String get rankTitleCardShark => 'Card Shark';

  @override
  String get rankTitleHighRoller => 'High Roller';

  @override
  String get rankTitleTableMaster => 'Table Master';

  @override
  String get rankTitleGrandAce => 'Grand Ace';

  @override
  String get rankTitleShadowLegend => 'Shadow Legend';

  @override
  String get inviteFriends => 'Invite Friends';

  @override
  String get invite => 'Invite';

  @override
  String get invited => 'Invited';

  @override
  String get inviteSent => 'Invite sent!';

  @override
  String tableInviteFrom(String name, String code) {
    return '$name invited you to private table $code';
  }

  @override
  String get joinTable => 'Join Table';

  @override
  String get ignore => 'Ignore';

  @override
  String get noFriendsToInvite => 'No friends added yet to invite.';

  @override
  String get customizeAvatar => 'Customize Avatar';

  @override
  String get locked => 'Locked';

  @override
  String get equipped => 'Equipped';

  @override
  String get equip => 'Equip';

  @override
  String unlockAtLevel(int lvl) {
    return 'Unlocks at Level $lvl';
  }

  @override
  String get defaultAvatar => 'Default';

  @override
  String get blueAvatar => 'Sapphire';

  @override
  String get redAvatar => 'Ruby';

  @override
  String get bronzeAvatar => 'Bronze';

  @override
  String get silverAvatar => 'Silver';

  @override
  String get jokerGirlAvatar => 'Joker Girl';

  @override
  String get violetJokerGirlAvatar => 'Violet Joker';

  @override
  String get violetQueenAvatar => 'Violet Queen';

  @override
  String get queenOfHeartAvatar => 'Queen of Hearts';

  @override
  String get goldenKingAvatar => 'Golden King';

  @override
  String get queenAvatar => 'Queen';

  @override
  String get kingAvatar => 'King';

  @override
  String get money => 'Money';

  @override
  String get chips => 'Chips';

  @override
  String get exchange => 'Exchange';

  @override
  String get avatarShop => 'Avatars';

  @override
  String get deckShop => 'Decks';

  @override
  String get selectMatchStake => 'Select Match Stake';

  @override
  String get stake => 'Stake';

  @override
  String get pot => 'Pot';

  @override
  String get winnerTakesAll => 'Winner takes all';

  @override
  String get getMoreMoney => 'Get Money';

  @override
  String get insufficientChips => 'Not enough chips';

  @override
  String get insufficientMoney => 'Not enough money';

  @override
  String get exchangedSuccess => 'Exchange successful';

  @override
  String get exchangeFailed => 'Exchange failed';

  @override
  String get watchAdForMoney => 'Watch Video Ad';

  @override
  String get freeStashBonus => 'Free Money Bonus';

  @override
  String get adRewardEarned => 'Reward earned!';

  @override
  String get adNotAvailable => 'Ad not ready, try again later';

  @override
  String get chipsToMoney => 'Convert Chips to Money';

  @override
  String get moneyToChips => 'Convert Money to Chips';

  @override
  String get convert => 'Convert';

  @override
  String get claim => 'Claim';

  @override
  String get buy => 'Buy';

  @override
  String get owned => 'Owned';

  @override
  String get unlocked => 'Unlocked';

  @override
  String get purchaseFailed => 'Purchase failed';

  @override
  String get classicDeck => 'Classic Blue';

  @override
  String get classicDeckDesc => 'Standard casino playing cards';

  @override
  String get onyxBlackDeck => 'Onyx Black';

  @override
  String get onyxBlackDeckDesc => 'Obsidian back with gold filigree';

  @override
  String get price => 'Price';

  @override
  String get play => 'Play';

  @override
  String get cityLondon => 'London';

  @override
  String get cityParis => 'Paris';

  @override
  String get cityMoscow => 'Moscow';

  @override
  String get cityCairo => 'Cairo';

  @override
  String get cityMarrakech => 'Marrakech';

  @override
  String get prize => 'Prize';

  @override
  String get entryFee => 'Entry fee';
}
