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
  String get continueWithApple => 'Continue with Apple';

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
  String get appleSignInFailed => 'Apple sign-in failed. Try again.';

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
  String get home => 'Home';

  @override
  String get shop => 'Shop';

  @override
  String get collection => 'Collection';

  @override
  String get collectionCards => 'Cards';

  @override
  String get collectionAvatars => 'Avatars';

  @override
  String ownedCount(int owned, int total) {
    return '$owned/$total owned';
  }

  @override
  String get getMoreInShop => 'Get more in the Shop';

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
  String get apple => 'Apple';

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
      'Finish with the lowest total. The game ends when a player has no cards left or someone taps End game.';

  @override
  String get ruleSetupTitle => 'Setup';

  @override
  String get ruleSetupBody =>
      'Two players. Each gets four face-down cards in a row.';

  @override
  String get ruleOpeningPeekTitle => 'Opening peek';

  @override
  String get ruleOpeningPeekBody =>
      'Before play, tap Reveal to see your two left cards for a few seconds. Remember them — then they flip face-down again.';

  @override
  String get ruleYourTurnTitle => 'Your turn';

  @override
  String get ruleYourTurnBody =>
      'Before drawing, if the top discard matches a card you know, tap it to discard it (your turn continues). Wrong guess = a penalty card. Then draw from the deck.';

  @override
  String get ruleAfterDrawTitle => 'After you draw';

  @override
  String get ruleAfterDrawBody =>
      'Tap one of your cards to swap (different rank) or double-discard (same rank), or tap the drawn card to throw it. Then your turn ends.';

  @override
  String get ruleSpecialTitle => 'Special cards';

  @override
  String get ruleSpecialBody =>
      'When you draw these, you may use their power. Afterwards the card is thrown.';

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
      'When a player has no cards left or someone taps End game, all cards are revealed and added up. Ace = 1, Jack = 11, Queen = 12. Lowest total wins; equal = tie.';

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
  String get sapphireFrostDeck => 'Sapphire Dragon';

  @override
  String get sapphireFrostDeckDesc =>
      'Celtic knotwork in sapphire and gold around twin dragons';

  @override
  String get imperialJadeDeck => 'High Victorian';

  @override
  String get imperialJadeDeckDesc =>
      'Emerald filigree in a gilt Victorian frame';

  @override
  String get royalCrimsonDeck => 'Royal Crimson';

  @override
  String get royalCrimsonDeckDesc =>
      'Gilt filigree and a crowned figure on crimson';

  @override
  String get neonNightsDeck => 'Neon Nights';

  @override
  String get neonNightsDeckDesc =>
      'A synthwave sunset over a glowing neon grid';

  @override
  String get gildedDeck => '24K Gold';

  @override
  String get gildedDeckDesc =>
      'Engraved solid gold with a brilliant-cut diamond';

  @override
  String get rarityRare => 'Rare';

  @override
  String get rarityEpic => 'Epic';

  @override
  String get rarityLegendary => 'Legendary';

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
  String get cityToronto => 'Toronto';

  @override
  String get cityNewYork => 'New York';

  @override
  String get cityTokyo => 'Tokyo';

  @override
  String get prize => 'Prize';

  @override
  String get entryFee => 'Entry fee';

  @override
  String get linkGoogleAccount => 'Link Google account';

  @override
  String get linkingGoogle => 'Linking…';

  @override
  String get linkAppleAccount => 'Link Apple account';

  @override
  String get linkGoogleSuccess => 'Google account linked. Progress saved.';

  @override
  String get linkGoogleSwitched => 'Signed in with your Google account.';

  @override
  String get linkAppleSuccess => 'Apple account linked. Progress saved.';

  @override
  String get linkAppleSwitched => 'Signed in with your Apple account.';

  @override
  String get saveProgressTitle => 'Save your progress';

  @override
  String get saveProgressBody =>
      'Link a Google account so you keep your money, chips, and ranking if you change devices.';

  @override
  String get saveProgressBodyIos =>
      'Link an Apple or Google account so you keep your money, chips, and ranking if you change devices.';

  @override
  String get googleAccountInUseTitle => 'Google account in use';

  @override
  String get appleAccountInUseTitle => 'Apple account in use';

  @override
  String googleAccountInUseBody(String username) {
    return 'This Google account already belongs to @$username. Switch to that account? Your guest progress on this device will be lost.';
  }

  @override
  String appleAccountInUseBody(String username) {
    return 'This Apple account already belongs to @$username. Switch to that account? Your guest progress on this device will be lost.';
  }

  @override
  String get switchToGoogleAccount => 'Switch account';

  @override
  String get dontAskAgain => 'Don\'t ask again';

  @override
  String get later => 'Later';

  @override
  String get youQuit => 'You quit';

  @override
  String get opponentQuit => 'Opponent quit';

  @override
  String get turnTimedOut => 'Time\'s up. Your turn was played for you.';

  @override
  String turnTimedOutWarning(int remaining) {
    return 'Time\'s up. Your turn was played for you. Turns left before you forfeit: $remaining.';
  }

  @override
  String get youTimedOut => 'You ran out of time';

  @override
  String get opponentTimedOut => 'Opponent ran out of time';

  @override
  String get matchResultQuit => 'QUIT';

  @override
  String get leaveMatchPenaltyMessage =>
      'Leaving now counts as a loss: you\'ll lose your stake and 15 points.';

  @override
  String get notEnoughMoneyTitle => 'Not enough money';

  @override
  String notEnoughMoneyMessage(int required, int money) {
    return 'The stake is $required but you have $money. Exchange chips or buy more to play the rematch.';
  }

  @override
  String get stakeCovered => 'You\'re covered — ready for the rematch.';

  @override
  String get exchangeChips => 'Exchange chips';

  @override
  String get buyMoney => 'Buy money';

  @override
  String get rematchStarting => 'Taking stakes…';

  @override
  String opponentCantAffordRematch(String name) {
    return '$name can\'t cover the stake';
  }

  @override
  String get offlineReconnecting => 'Offline · reconnecting…';

  @override
  String get getMoreChips => 'Get Chips';

  @override
  String get notEnoughChipsTitle => 'Not enough chips';

  @override
  String notEnoughChipsMessage(int required, int chips) {
    return 'The stake is $required chips but you have $chips. Buy more chips to play the rematch.';
  }

  @override
  String get buyChips => 'Buy chips';

  @override
  String get tutLessonValuesTitle => 'Goal & card values';

  @override
  String get tutLessonDealTitle => 'The deal & first look';

  @override
  String get tutLessonSwapTitle => 'Draw & swap';

  @override
  String get tutLessonThrowTitle => 'Throw a card away';

  @override
  String get tutLessonDoubleTitle => 'Double discard';

  @override
  String get tutLessonMatchTitle => 'Match the discard';

  @override
  String get tutLessonJackTitle => 'Jack: peek';

  @override
  String get tutLessonQueenTitle => 'Queen: swap or shuffle';

  @override
  String get tutLessonEndTitle => 'Ending & scoring';

  @override
  String get tutLessonTipsTitle => 'Winning tips';

  @override
  String get tutValuesIntro =>
      'ShadowHand is a memory game for two. Each player has cards face down. When the game ends, everyone adds up their cards — the lowest total wins.';

  @override
  String get tutValuesChart =>
      'Each card is worth points. Ace = 1, number cards = their number, Jack = 11, Queen = 12, red King = 13. The best cards: a black King is worth 0 and a Joker is worth −1!';

  @override
  String get tutValuesQuizLowest =>
      'Quick quiz: tap the card worth the fewest points.';

  @override
  String get tutValuesQuizLowestWrong =>
      'Not quite. The Joker is worth −1 — even lower than an Ace.';

  @override
  String get tutValuesQuizKing => 'Two Kings here. Tap the one worth 0 points.';

  @override
  String get tutValuesQuizKingWrong =>
      'Only black Kings (♠ ♣) are worth 0. Red Kings (♥ ♦) are worth 13 — the worst card in the deck!';

  @override
  String get tutValuesDone =>
      'Perfect! Your goal: keep low cards and get rid of high ones.';

  @override
  String get tutDealIntro =>
      'Each player gets 4 cards face down in a row. You don\'t know what they are yet — and neither does your opponent.';

  @override
  String get tutDealReveal =>
      'Before play starts, you get one quick look. Tap Reveal.';

  @override
  String get tutDealMemorize =>
      'Your two cards on the left are shown for a few seconds. Remember them: a 2 and an 8!';

  @override
  String get tutDealQuiz =>
      'They\'re face down again. Where is your 2? Tap it.';

  @override
  String get tutDealQuizWrong =>
      'The 2 was your first card, on the far left. Memory is everything in this game!';

  @override
  String get tutDealDone =>
      'Right! Your other two cards are still a mystery — you\'ll learn more as you play.';

  @override
  String get tutDrawPrompt => 'It\'s your turn. Tap the deck to draw a card.';

  @override
  String get tutSwapIntro =>
      'You remember your first two cards: a 2 and a 9. A 9 costs a lot of points — let\'s replace it.';

  @override
  String get tutSwapPick =>
      'You drew a 3. That\'s better than your 9! Tap your 9 (second card) to swap them.';

  @override
  String get tutSwapPickWrong =>
      'Tap your 9 — the second card from the left. Swapping a card you don\'t know is a gamble.';

  @override
  String get tutSwapDone =>
      'The 3 goes face down where the 9 was, and the 9 goes to the discard pile. That ends your turn — and you just saved 6 points.';

  @override
  String get tutThrowPick =>
      'Ouch — a red King, worth 13. You don\'t want it! Tap the drawn card to throw it on the discard pile.';

  @override
  String get tutThrowWrong =>
      'Don\'t keep a bad card. Tap the drawn card (bottom left) to throw it away.';

  @override
  String get tutThrowDone =>
      'Thrown away! Your cards didn\'t change and your turn is over. Throw any card that wouldn\'t make your hand better.';

  @override
  String get tutDoubleIntro => 'You remember your first card is a 5.';

  @override
  String get tutDoublePick =>
      'Another 5! When the card you draw has the same rank as one of yours, tap your card: both get discarded.';

  @override
  String get tutDoubleWrong => 'Tap your 5 — the first card on the left.';

  @override
  String get tutDoubleDone =>
      'Both 5s are gone and you have one card fewer. Fewer cards means fewer points — and if you run out of cards, the game ends.';

  @override
  String get tutMatchIntro =>
      'You remember your first card is a 7. Now it\'s your opponent\'s turn…';

  @override
  String get tutMatchPick =>
      'Your opponent threw a 7! On your turn, before you draw, you can tap a card with the same rank as the top of the discard pile to get rid of it. Tap your 7.';

  @override
  String get tutMatchWrong => 'Tap your 7 — the first card on the left.';

  @override
  String get tutMatchContinue =>
      'A free discard! Matching doesn\'t end your turn: you can match again, and then you still draw. Tap the deck.';

  @override
  String get tutMatchThrow =>
      'An 8 — not great. Tap it to throw it and end your turn.';

  @override
  String get tutMatchGuess =>
      'Next turn, the top card is a 4. You think your middle card might be a 4… but you\'re not sure. Let\'s see what a wrong guess does: tap it.';

  @override
  String get tutMatchPenalty =>
      'Wrong — it wasn\'t a 4. You get a penalty card from the deck, face down, and the card you tapped stays. Only match when you\'re sure!';

  @override
  String get tutJackPeekButton =>
      'A Jack! When you draw a Jack you can peek at any one card — yours or your opponent\'s. Tap Peek.';

  @override
  String get tutJackPick =>
      'Now tap the card you want to see. Let\'s spy on your opponent\'s second card.';

  @override
  String get tutJackPickWrong =>
      'Tap your opponent\'s second card from the left.';

  @override
  String get tutJackReveal =>
      'It\'s a Queen — 12 points for them. Remember where it is: it hides again in a moment.';

  @override
  String get tutJackDone =>
      'After the peek, the Jack is thrown automatically and your turn ends. The power is optional: you can also keep or throw a Jack like any other card.';

  @override
  String get tutQueenIntro =>
      'You remember your second card is a 10. Let\'s give it to your opponent.';

  @override
  String get tutQueenButtons =>
      'A Queen! You get a choice. Shuffle mixes up one player\'s cards. Replace swaps one of your cards with one of theirs. Tap Replace.';

  @override
  String get tutQueenButtonsWrong => 'For this lesson, tap Replace.';

  @override
  String get tutQueenPickYours =>
      'First tap the card you want to give away: your 10, the second card.';

  @override
  String get tutQueenPickYoursWrong =>
      'Tap your 10 — your second card from the left.';

  @override
  String get tutQueenPickTheirs =>
      'Now tap the opponent\'s card you want to take: their first card.';

  @override
  String get tutQueenPickTheirsWrong =>
      'Tap your opponent\'s first card, on the left.';

  @override
  String get tutQueenDone =>
      'Swapped! Your 10 now belongs to your opponent. You don\'t see the card you got, but most cards are worth less than 10 — a good deal. The Queen is thrown after use.';

  @override
  String get tutQueenShuffle =>
      'Shuffle is the other option: mix up your opponent\'s cards and everything they remembered becomes useless. You can also shuffle your own cards.';

  @override
  String get tutEndIntro =>
      'The game ends in one of two ways: a player has no cards left, or someone taps End game.';

  @override
  String get tutEndPress =>
      'Think your total is lower? Either player can tap End game at any time. Try it.';

  @override
  String get tutEndCount =>
      'All cards are revealed. Add up yours: 3 + 2 + black King + Joker. What\'s your total?';

  @override
  String get tutEndCountWrong =>
      'Remember: a black King is 0 and a Joker is −1. So 3 + 2 + 0 − 1 = 4.';

  @override
  String get tutEndWinner => 'Your opponent has 9 + 5 + 7 + 1 = 22. Who wins?';

  @override
  String get tutEndWinnerWrong => 'The lowest total wins: 4 beats 22.';

  @override
  String get tutEndDone => 'You win! If both totals are equal, it\'s a tie.';

  @override
  String get tutTipMemory =>
      'Tip 1 — Remember everything. Every card you see — at the start, when you swap, with a Jack — tells you something. Keep track of it.';

  @override
  String get tutTipKeepLow =>
      'Tip 2 — Keep black Kings and Jokers. They\'re worth 0 and −1: never swap them away.';

  @override
  String get tutTipDiscard =>
      'Tip 3 — Watch the discard pile. Every card your opponent throws is a chance to match one of yours for free.';

  @override
  String get tutTipQueen =>
      'Tip 4 — Use Queens well. Give away your highest card, or Shuffle to wreck your opponent\'s memory.';

  @override
  String get tutTipEnd =>
      'Tip 5 — End at the right time. When you think your total is lower, tap End game before your opponent catches up.';

  @override
  String get tutChoiceYou => 'You';

  @override
  String get tutChoiceOpponent => 'Opponent';

  @override
  String get tutChoiceTie => 'Tie';

  @override
  String get tutDeckLabel => 'Deck';

  @override
  String get tutDiscardLabel => 'Discard';

  @override
  String get tutDrawnLabel => 'Drawn';

  @override
  String get tutAceLabel => 'Ace';

  @override
  String get tutNumberCardsLabel => '2 to 10';

  @override
  String get tutRedKingLabel => 'Red King';

  @override
  String get tutTapHighlighted => 'Tap the glowing spot to continue.';

  @override
  String tutLessonProgress(int current, int total) {
    return 'Lesson $current of $total';
  }

  @override
  String get tutSkip => 'Skip';

  @override
  String get tutLessonDone => 'Lesson complete!';

  @override
  String get tutReplay => 'Replay';

  @override
  String get tutFinish => 'Finish';

  @override
  String get tutNextLesson => 'Next lesson';

  @override
  String get tutCompleteTitle => 'You\'re ready!';

  @override
  String get tutCompleteBody =>
      'You know all the rules. Practice against the robot, then take on real players.';

  @override
  String get tutHubIntro =>
      'Learn ShadowHand by playing. Each short lesson puts cards in your hands and walks you through one rule.';

  @override
  String get tutStartAll => 'Start tutorial';

  @override
  String get tutContinue => 'Continue tutorial';

  @override
  String get tutLessonsHeader => 'Lessons';

  @override
  String get tutQuickRules => 'Quick rules';

  @override
  String get tutQuickRulesSubtitle => 'Every rule in 7 short cards';

  @override
  String get tutPromptTitle => 'New to ShadowHand?';

  @override
  String get tutPromptBody =>
      'Learn to play in a quick hands-on tutorial. It takes about 3 minutes.';

  @override
  String get tutPromptLater => 'Not now';

  @override
  String get chat => 'Chat';

  @override
  String get chatHint => 'Type a message…';

  @override
  String get chatEmpty => 'No messages yet. Say hi!';

  @override
  String get quickPhrases => 'Quick phrases';

  @override
  String get phraseHello => 'Hi!';

  @override
  String get phraseGoodLuck => 'Good luck';

  @override
  String get phraseWellPlayed => 'Well played';

  @override
  String get phrasePlayFast => 'Play fast!';

  @override
  String get phraseOops => 'Oops';

  @override
  String get phraseThanks => 'Thanks';

  @override
  String get phraseUnlucky => 'Unlucky draw';

  @override
  String get phraseHehe => 'Hehe';

  @override
  String get phraseGg => 'GG';

  @override
  String get micOn => 'Mic on';

  @override
  String get micOff => 'Mic off';

  @override
  String get micPermissionDenied =>
      'Microphone access is off. Allow it in your phone settings to talk.';

  @override
  String get voiceOpponentTalking => 'Voice on';

  @override
  String get muteOpponent => 'Mute player';

  @override
  String get unmuteOpponent => 'Unmute player';

  @override
  String opponentMutedToast(String name) {
    return '$name is muted';
  }

  @override
  String get reportPlayer => 'Report player';

  @override
  String reportPlayerConfirm(String name) {
    return 'Report $name for bad behaviour?';
  }

  @override
  String get reportedToast => 'Thanks, we\'ll review this player';

  @override
  String get recentForm => 'Recent form';

  @override
  String get noRecentMatches => 'No matches yet';

  @override
  String get tableChatSettings => 'Table chat';

  @override
  String get showOpponentChat => 'Show opponent chat';

  @override
  String get voiceChatSetting => 'Voice chat';

  @override
  String get errChatRateLimited =>
      'Slow down, you\'re sending messages too fast';

  @override
  String get errChatInvalid => 'Message couldn\'t be sent';

  @override
  String get phraseNiceSwap => 'Nice swap!';

  @override
  String get phraseSharpMemory => 'What a memory!';

  @override
  String get phraseStopPeeking => 'Stop peeking!';

  @override
  String get phraseGiveCardBack => 'Give my card back!';

  @override
  String get phraseBlackKingPlease => 'Black King, please!';

  @override
  String get phraseLowTotal => 'My total is tiny';

  @override
  String get phraseFoundJoker => 'I found a Joker!';

  @override
  String get phraseKnowMyCards => 'I know all my cards';

  @override
  String get phraseEndingNextTurn => 'Ending it next turn!';

  @override
  String get dailyStreakTitle => 'Daily Streak';

  @override
  String dailyDay(int day) {
    return 'Day $day';
  }

  @override
  String dailyDayOfWeek(int day) {
    return 'Day $day of 7';
  }

  @override
  String get dailyToday => 'Today';

  @override
  String get dailyTomorrow => 'Tomorrow';

  @override
  String get dailyJackpot => 'Jackpot';

  @override
  String dailyStreakCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count-day streak',
      one: '1-day streak',
      zero: 'Start your streak',
    );
    return '$_temp0';
  }

  @override
  String dailyBest(int best) {
    return 'Best $best';
  }

  @override
  String dailyNextIn(String time) {
    return 'Next reward in $time';
  }

  @override
  String get dailyComeBackTomorrow => 'Come back tomorrow';

  @override
  String get dailyShortAd => 'Short ad';

  @override
  String dailyBoostedBadge(int multiplier) {
    return '×$multiplier ad boost';
  }

  @override
  String get dailyStreakBrokenTitle => 'Your streak broke';

  @override
  String dailyStreakBrokenBody(int day) {
    return 'Restore it to carry on at Day $day, or start a new streak from Day 1.';
  }

  @override
  String get dailyRestore => 'Restore';

  @override
  String get dailyStartOver => 'Start over';

  @override
  String get dailyGraceForgiven => 'Missed day forgiven';

  @override
  String get dailyFreezeSaves => 'A Streak Freeze saves your streak';

  @override
  String get dailyNewStreak => 'A new streak starts today';

  @override
  String dailyEventEnds(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Ends in $days days',
      one: 'Ends tomorrow',
      zero: 'Ends today',
    );
    return '$_temp0';
  }

  @override
  String get dailyCoinBoost => 'Coin Boost';

  @override
  String dailyCoinBoostBody(int percent) {
    return '+$percent% money on match wins';
  }

  @override
  String get dailyStreakFreeze => 'Streak Freeze';

  @override
  String get dailyStreakFreezeBody => 'Saves your streak if you miss a day';

  @override
  String get dailyMysteryChest => 'Mystery Chest';

  @override
  String get dailyChestInside => 'What\'s inside';

  @override
  String get dailyChestNote => 'One reward, picked by chance when you claim.';

  @override
  String get dailyMysteryGift => 'Mystery gift';

  @override
  String get dailyNew => 'New!';

  @override
  String get dailyAlreadyOwned => 'Already owned';

  @override
  String get dailyCollect => 'Collect';

  @override
  String get dailyCollected => 'Collected';

  @override
  String dailyDayReward(int day) {
    return 'Day $day reward';
  }

  @override
  String get dailyJackpotWon => 'Jackpot!';

  @override
  String get dailyWelcomeBack => 'Welcome back!';

  @override
  String get dailyWelcomeBackBody =>
      'We kept a gift for you while you were away.';

  @override
  String get dailyClaimFailed => 'Couldn\'t collect right now. Try again.';

  @override
  String get dailyLoadFailed => 'Couldn\'t load your streak.';

  @override
  String get dailyRetry => 'Try again';

  @override
  String dailyEntryReady(int day) {
    return 'Day $day reward is ready';
  }

  @override
  String get dailyEntryBroken => 'Streak broken · restore it';

  @override
  String get dailyEntryComeback => 'A welcome-back gift is waiting';

  @override
  String get boostsTitle => 'Boosts';

  @override
  String boostReady(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count boosts ready',
      one: '1 boost ready',
    );
    return '$_temp0';
  }

  @override
  String boostWinsPay(int percent, String max) {
    return 'Money wins pay +$percent% (up to $max)';
  }

  @override
  String boostTimeLeft(String time) {
    return '$time left';
  }

  @override
  String get boostActive => 'Active';

  @override
  String get boostActivate => 'Activate';

  @override
  String boostAddTime(String time) {
    return 'Add $time';
  }

  @override
  String boostWaitsFor(int percent) {
    return 'Available when your +$percent% ends';
  }

  @override
  String get boostNoneActive => 'No boost running';

  @override
  String get boostNoneActiveBody =>
      'Activate one to win more from every money match.';

  @override
  String get boostInventoryEmpty =>
      'No boosts waiting. Your daily streak hands them out.';

  @override
  String boostStarted(int percent) {
    return '+$percent% boost is on!';
  }

  @override
  String boostExtended(String time) {
    return 'Boost extended by $time';
  }

  @override
  String get boostActivateFailed => 'Couldn\'t activate the boost. Try again.';

  @override
  String get boostActivateNow => 'Activate now';

  @override
  String get boostInYourBoosts => 'Saved to your boosts';

  @override
  String boostUpTo(String amount) {
    return 'up to +$amount';
  }

  @override
  String boostPayout(int percent) {
    return 'Boost +$percent%';
  }

  @override
  String get boostMoneyOnly => 'Money matches only';

  @override
  String boostActiveSemantics(int percent, String time) {
    return 'Coin Boost +$percent% active, $time left';
  }

  @override
  String get boostOneAtATime =>
      'One boost value runs at a time. The same value adds its time.';
}
