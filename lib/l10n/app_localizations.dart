import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('pt'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'ShadowHand'**
  String get appTitle;

  /// No description provided for @authError.
  ///
  /// In en, this message translates to:
  /// **'Auth error: {error}'**
  String authError(String error);

  /// No description provided for @signInToPlay.
  ///
  /// In en, this message translates to:
  /// **'Sign in to play online'**
  String get signInToPlay;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @signingIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in…'**
  String get signingIn;

  /// No description provided for @playAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Play as Guest'**
  String get playAsGuest;

  /// No description provided for @entering.
  ///
  /// In en, this message translates to:
  /// **'Entering…'**
  String get entering;

  /// No description provided for @guestSignInServerDown.
  ///
  /// In en, this message translates to:
  /// **'Guest sign-in failed. Is the server running?'**
  String get guestSignInServerDown;

  /// No description provided for @guestSignInConnection.
  ///
  /// In en, this message translates to:
  /// **'Guest sign-in failed. Check connection.'**
  String get guestSignInConnection;

  /// No description provided for @googleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed. Try again.'**
  String get googleSignInFailed;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Two players. One table.'**
  String get tagline;

  /// No description provided for @findMatch.
  ///
  /// In en, this message translates to:
  /// **'Find match'**
  String get findMatch;

  /// No description provided for @createRoom.
  ///
  /// In en, this message translates to:
  /// **'Create room'**
  String get createRoom;

  /// No description provided for @joinRoom.
  ///
  /// In en, this message translates to:
  /// **'Join room'**
  String get joinRoom;

  /// No description provided for @playVsRobot.
  ///
  /// In en, this message translates to:
  /// **'Practice vs Robot'**
  String get playVsRobot;

  /// No description provided for @robotName.
  ///
  /// In en, this message translates to:
  /// **'Robot'**
  String get robotName;

  /// No description provided for @retryConnection.
  ///
  /// In en, this message translates to:
  /// **'Retry connection'**
  String get retryConnection;

  /// No description provided for @howToPlay.
  ///
  /// In en, this message translates to:
  /// **'How to play'**
  String get howToPlay;

  /// No description provided for @deck.
  ///
  /// In en, this message translates to:
  /// **'Deck'**
  String get deck;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change language'**
  String get changeLanguage;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @guest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guest;

  /// No description provided for @google.
  ///
  /// In en, this message translates to:
  /// **'Google'**
  String get google;

  /// No description provided for @player.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get player;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get connecting;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @joinRoomTitle.
  ///
  /// In en, this message translates to:
  /// **'Join room'**
  String get joinRoomTitle;

  /// No description provided for @joinRoomHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-letter code from your friend.'**
  String get joinRoomHint;

  /// No description provided for @codeHint.
  ///
  /// In en, this message translates to:
  /// **'CODE'**
  String get codeHint;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @join.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get join;

  /// No description provided for @findingOpponent.
  ///
  /// In en, this message translates to:
  /// **'Finding opponent'**
  String get findingOpponent;

  /// No description provided for @matchmakingHint.
  ///
  /// In en, this message translates to:
  /// **'Hang tight — matching you with a player.'**
  String get matchmakingHint;

  /// No description provided for @privateTable.
  ///
  /// In en, this message translates to:
  /// **'Private table'**
  String get privateTable;

  /// No description provided for @shareCodeWithFriend.
  ///
  /// In en, this message translates to:
  /// **'Share this code with a friend'**
  String get shareCodeWithFriend;

  /// No description provided for @waitingForOpponentNamed.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {name}…'**
  String waitingForOpponentNamed(String name);

  /// No description provided for @opponentIsReady.
  ///
  /// In en, this message translates to:
  /// **'{name} is ready'**
  String opponentIsReady(String name);

  /// No description provided for @bothPlayersJoined.
  ///
  /// In en, this message translates to:
  /// **'Both players joined'**
  String get bothPlayersJoined;

  /// No description provided for @codeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied'**
  String get codeCopied;

  /// No description provided for @tapToCopy.
  ///
  /// In en, this message translates to:
  /// **'Tap to copy'**
  String get tapToCopy;

  /// No description provided for @ready.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get ready;

  /// No description provided for @waitingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Waiting…'**
  String get waitingEllipsis;

  /// No description provided for @leaveRoom.
  ///
  /// In en, this message translates to:
  /// **'Leave room'**
  String get leaveRoom;

  /// No description provided for @vs.
  ///
  /// In en, this message translates to:
  /// **'VS'**
  String get vs;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @notReady.
  ///
  /// In en, this message translates to:
  /// **'Not ready'**
  String get notReady;

  /// No description provided for @waitingEllipsisShort.
  ///
  /// In en, this message translates to:
  /// **'Waiting…'**
  String get waitingEllipsisShort;

  /// No description provided for @endGame.
  ///
  /// In en, this message translates to:
  /// **'End game'**
  String get endGame;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @endGameTitle.
  ///
  /// In en, this message translates to:
  /// **'End game?'**
  String get endGameTitle;

  /// No description provided for @endGameMessage.
  ///
  /// In en, this message translates to:
  /// **'Cards get revealed and scores are counted.'**
  String get endGameMessage;

  /// No description provided for @reveal.
  ///
  /// In en, this message translates to:
  /// **'Reveal'**
  String get reveal;

  /// No description provided for @peek.
  ///
  /// In en, this message translates to:
  /// **'Peek'**
  String get peek;

  /// No description provided for @shuffle.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get shuffle;

  /// No description provided for @replace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get replace;

  /// No description provided for @waitingOpponentReveal.
  ///
  /// In en, this message translates to:
  /// **'Waiting for opponent to see their cards…'**
  String get waitingOpponentReveal;

  /// No description provided for @gameOver.
  ///
  /// In en, this message translates to:
  /// **'Game over'**
  String get gameOver;

  /// No description provided for @victory.
  ///
  /// In en, this message translates to:
  /// **'Victory'**
  String get victory;

  /// No description provided for @defeat.
  ///
  /// In en, this message translates to:
  /// **'Defeat'**
  String get defeat;

  /// No description provided for @draw.
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get draw;

  /// No description provided for @seriesScore.
  ///
  /// In en, this message translates to:
  /// **'SERIES  {yours} – {theirs}'**
  String seriesScore(int yours, int theirs);

  /// No description provided for @opponent.
  ///
  /// In en, this message translates to:
  /// **'Opponent'**
  String get opponent;

  /// No description provided for @waitingRematch.
  ///
  /// In en, this message translates to:
  /// **'Waiting for opponent to rematch…'**
  String get waitingRematch;

  /// No description provided for @opponentAskingRematch.
  ///
  /// In en, this message translates to:
  /// **'{name} is asking for a rematch'**
  String opponentAskingRematch(String name);

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @rematch.
  ///
  /// In en, this message translates to:
  /// **'Rematch'**
  String get rematch;

  /// No description provided for @points.
  ///
  /// In en, this message translates to:
  /// **'pts'**
  String get points;

  /// No description provided for @roomInfo.
  ///
  /// In en, this message translates to:
  /// **'Room info'**
  String get roomInfo;

  /// No description provided for @roomCodePlaying.
  ///
  /// In en, this message translates to:
  /// **'{roomId} · {turn}'**
  String roomCodePlaying(String roomId, String turn);

  /// No description provided for @codeRoomId.
  ///
  /// In en, this message translates to:
  /// **'Code {roomId}'**
  String codeRoomId(String roomId);

  /// No description provided for @roomToastPlaying.
  ///
  /// In en, this message translates to:
  /// **'Room {roomId} · {turn}'**
  String roomToastPlaying(String roomId, String turn);

  /// No description provided for @roomToast.
  ///
  /// In en, this message translates to:
  /// **'Room {roomId}'**
  String roomToast(String roomId);

  /// No description provided for @yourTurn.
  ///
  /// In en, this message translates to:
  /// **'Your turn'**
  String get yourTurn;

  /// No description provided for @opponentTurn.
  ///
  /// In en, this message translates to:
  /// **'Opponent turn'**
  String get opponentTurn;

  /// No description provided for @leaveRoomTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave room?'**
  String get leaveRoomTitle;

  /// No description provided for @leaveRoomMessage.
  ///
  /// In en, this message translates to:
  /// **'You will drop out of this game.'**
  String get leaveRoomMessage;

  /// No description provided for @stepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String stepOf(int current, int total);

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @ruleGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get ruleGoalTitle;

  /// No description provided for @ruleGoalBody.
  ///
  /// In en, this message translates to:
  /// **'Empty your four cards, or hold the lowest score when the game ends. Lowest total wins.'**
  String get ruleGoalBody;

  /// No description provided for @ruleSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Setup'**
  String get ruleSetupTitle;

  /// No description provided for @ruleSetupBody.
  ///
  /// In en, this message translates to:
  /// **'Two players. Each gets four face-down cards.'**
  String get ruleSetupBody;

  /// No description provided for @ruleOpeningPeekTitle.
  ///
  /// In en, this message translates to:
  /// **'Opening peek'**
  String get ruleOpeningPeekTitle;

  /// No description provided for @ruleOpeningPeekBody.
  ///
  /// In en, this message translates to:
  /// **'Before play, both players peek at two of their own cards (bottom row) for a few seconds. Remember them — then they flip face-down again.'**
  String get ruleOpeningPeekBody;

  /// No description provided for @ruleYourTurnTitle.
  ///
  /// In en, this message translates to:
  /// **'Your turn'**
  String get ruleYourTurnTitle;

  /// No description provided for @ruleYourTurnBody.
  ///
  /// In en, this message translates to:
  /// **'Draw from the deck, or if the discard top matches a card you know, tap that card to discard it (your turn continues). Wrong guess = a penalty card into your layout.'**
  String get ruleYourTurnBody;

  /// No description provided for @ruleAfterDrawTitle.
  ///
  /// In en, this message translates to:
  /// **'After you draw'**
  String get ruleAfterDrawTitle;

  /// No description provided for @ruleAfterDrawBody.
  ///
  /// In en, this message translates to:
  /// **'Tap one of your cards to swap (different rank) or double-discard (same rank), or throw the drawn card to the discard pile. Then your turn ends.'**
  String get ruleAfterDrawBody;

  /// No description provided for @ruleSpecialTitle.
  ///
  /// In en, this message translates to:
  /// **'Special cards'**
  String get ruleSpecialTitle;

  /// No description provided for @ruleSpecialBody.
  ///
  /// In en, this message translates to:
  /// **'These ranks trigger an ability when you draw them. After the ability, the card is thrown.'**
  String get ruleSpecialBody;

  /// No description provided for @ruleJackLabel.
  ///
  /// In en, this message translates to:
  /// **'Jack'**
  String get ruleJackLabel;

  /// No description provided for @ruleJackDesc.
  ///
  /// In en, this message translates to:
  /// **'Peek one card — yours or theirs — then the Jack is thrown.'**
  String get ruleJackDesc;

  /// No description provided for @ruleQueenLabel.
  ///
  /// In en, this message translates to:
  /// **'Queen'**
  String get ruleQueenLabel;

  /// No description provided for @ruleQueenDesc.
  ///
  /// In en, this message translates to:
  /// **'Shuffle a hand, or swap one of yours with one of theirs, then the Queen is thrown.'**
  String get ruleQueenDesc;

  /// No description provided for @ruleScoringTitle.
  ///
  /// In en, this message translates to:
  /// **'Scoring'**
  String get ruleScoringTitle;

  /// No description provided for @ruleScoringBody.
  ///
  /// In en, this message translates to:
  /// **'When someone empties their layout (or the game ends), sum remaining cards. Lower total wins; equal = tie.'**
  String get ruleScoringBody;

  /// No description provided for @ruleJokerLabel.
  ///
  /// In en, this message translates to:
  /// **'Joker'**
  String get ruleJokerLabel;

  /// No description provided for @ruleJokerDesc.
  ///
  /// In en, this message translates to:
  /// **'Counts as −1 point.'**
  String get ruleJokerDesc;

  /// No description provided for @ruleBlackKingLabel.
  ///
  /// In en, this message translates to:
  /// **'Black King'**
  String get ruleBlackKingLabel;

  /// No description provided for @ruleBlackKingDesc.
  ///
  /// In en, this message translates to:
  /// **'Clubs or spades King counts as 0. Red Kings count as 13.'**
  String get ruleBlackKingDesc;

  /// No description provided for @hintPeek.
  ///
  /// In en, this message translates to:
  /// **'Tap any card to peek…'**
  String get hintPeek;

  /// No description provided for @hintShufflePick.
  ///
  /// In en, this message translates to:
  /// **'Tap Shuffle above a hand…'**
  String get hintShufflePick;

  /// No description provided for @hintReplaceFirst.
  ///
  /// In en, this message translates to:
  /// **'Tap one card from each hand…'**
  String get hintReplaceFirst;

  /// No description provided for @hintReplaceSecond.
  ///
  /// In en, this message translates to:
  /// **'Tap a card on the other hand…'**
  String get hintReplaceSecond;

  /// No description provided for @errConnectionLost.
  ///
  /// In en, this message translates to:
  /// **'Connection lost'**
  String get errConnectionLost;

  /// No description provided for @errEnterRoomCode.
  ///
  /// In en, this message translates to:
  /// **'Enter a room code'**
  String get errEnterRoomCode;

  /// No description provided for @errServerNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Server is not connected'**
  String get errServerNotConnected;

  /// No description provided for @errCommandFailed.
  ///
  /// In en, this message translates to:
  /// **'Command failed'**
  String get errCommandFailed;

  /// No description provided for @errRoomFull.
  ///
  /// In en, this message translates to:
  /// **'Room already has two players'**
  String get errRoomFull;

  /// No description provided for @errWaitingForPlayer.
  ///
  /// In en, this message translates to:
  /// **'Two players required'**
  String get errWaitingForPlayer;

  /// No description provided for @errAlreadyStarted.
  ///
  /// In en, this message translates to:
  /// **'Game already started'**
  String get errAlreadyStarted;

  /// No description provided for @errNotEnded.
  ///
  /// In en, this message translates to:
  /// **'Game is not over'**
  String get errNotEnded;

  /// No description provided for @errAlreadyLaunched.
  ///
  /// In en, this message translates to:
  /// **'Cards already revealed'**
  String get errAlreadyLaunched;

  /// No description provided for @errAlreadyDrew.
  ///
  /// In en, this message translates to:
  /// **'Throw or swap drawn card first'**
  String get errAlreadyDrew;

  /// No description provided for @errDeckEmpty.
  ///
  /// In en, this message translates to:
  /// **'No cards available'**
  String get errDeckEmpty;

  /// No description provided for @errNoJack.
  ///
  /// In en, this message translates to:
  /// **'Jack peek requires a drawn Jack'**
  String get errNoJack;

  /// No description provided for @errPeekUsed.
  ///
  /// In en, this message translates to:
  /// **'Jack peek already used'**
  String get errPeekUsed;

  /// No description provided for @errInvalidSide.
  ///
  /// In en, this message translates to:
  /// **'Invalid side'**
  String get errInvalidSide;

  /// No description provided for @errInvalidCard.
  ///
  /// In en, this message translates to:
  /// **'Card index is invalid'**
  String get errInvalidCard;

  /// No description provided for @errCannotShuffle.
  ///
  /// In en, this message translates to:
  /// **'Not enough cards to shuffle'**
  String get errCannotShuffle;

  /// No description provided for @errDrawFirst.
  ///
  /// In en, this message translates to:
  /// **'Draw a card first'**
  String get errDrawFirst;

  /// No description provided for @errNoHandCard.
  ///
  /// In en, this message translates to:
  /// **'Draw a card first'**
  String get errNoHandCard;

  /// No description provided for @errNotInRoom.
  ///
  /// In en, this message translates to:
  /// **'Join room first'**
  String get errNotInRoom;

  /// No description provided for @errNotYourTurn.
  ///
  /// In en, this message translates to:
  /// **'It is not your turn'**
  String get errNotYourTurn;

  /// No description provided for @errRevealFirst.
  ///
  /// In en, this message translates to:
  /// **'Both players must reveal first'**
  String get errRevealFirst;

  /// No description provided for @errNotPlaying.
  ///
  /// In en, this message translates to:
  /// **'Game is not running'**
  String get errNotPlaying;

  /// No description provided for @errPeekInProgress.
  ///
  /// In en, this message translates to:
  /// **'Wait for peek to finish'**
  String get errPeekInProgress;

  /// No description provided for @errQueenInProgress.
  ///
  /// In en, this message translates to:
  /// **'Wait for Queen ability to finish'**
  String get errQueenInProgress;

  /// No description provided for @errNoQueen.
  ///
  /// In en, this message translates to:
  /// **'Queen ability requires a drawn Queen'**
  String get errNoQueen;

  /// No description provided for @errQueenUsed.
  ///
  /// In en, this message translates to:
  /// **'Queen ability already used'**
  String get errQueenUsed;

  /// No description provided for @errInvalidCommand.
  ///
  /// In en, this message translates to:
  /// **'Command type is required'**
  String get errInvalidCommand;

  /// No description provided for @errRoomNotFound.
  ///
  /// In en, this message translates to:
  /// **'Room not found'**
  String get errRoomNotFound;

  /// No description provided for @errUnknownCommand.
  ///
  /// In en, this message translates to:
  /// **'Unknown command'**
  String get errUnknownCommand;

  /// No description provided for @errTooManyCommands.
  ///
  /// In en, this message translates to:
  /// **'Too many commands'**
  String get errTooManyCommands;

  /// No description provided for @globalRanking.
  ///
  /// In en, this message translates to:
  /// **'Global Ranking'**
  String get globalRanking;

  /// No description provided for @marketplace.
  ///
  /// In en, this message translates to:
  /// **'Marketplace'**
  String get marketplace;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @marketplaceComingSoonBody.
  ///
  /// In en, this message translates to:
  /// **'Card skins and extras will show up here.'**
  String get marketplaceComingSoonBody;

  /// No description provided for @leaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboard;

  /// No description provided for @matchHistory.
  ///
  /// In en, this message translates to:
  /// **'Match History'**
  String get matchHistory;

  /// No description provided for @elo.
  ///
  /// In en, this message translates to:
  /// **'Elo'**
  String get elo;

  /// No description provided for @colWins.
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get colWins;

  /// No description provided for @colLosses.
  ///
  /// In en, this message translates to:
  /// **'L'**
  String get colLosses;

  /// No description provided for @colDraws.
  ///
  /// In en, this message translates to:
  /// **'D'**
  String get colDraws;

  /// No description provided for @rankingEmpty.
  ///
  /// In en, this message translates to:
  /// **'No ranked players yet. Play a random match!'**
  String get rankingEmpty;

  /// No description provided for @matchHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No ranked matches yet.'**
  String get matchHistoryEmpty;

  /// No description provided for @rankingLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load ranking. Is the server running?'**
  String get rankingLoadError;

  /// No description provided for @matchResultWin.
  ///
  /// In en, this message translates to:
  /// **'WIN'**
  String get matchResultWin;

  /// No description provided for @matchResultLoss.
  ///
  /// In en, this message translates to:
  /// **'LOSS'**
  String get matchResultLoss;

  /// No description provided for @matchResultDraw.
  ///
  /// In en, this message translates to:
  /// **'DRAW'**
  String get matchResultDraw;

  /// No description provided for @recordWinsLossesDraws.
  ///
  /// In en, this message translates to:
  /// **'{wins}W · {losses}L · {draws}D'**
  String recordWinsLossesDraws(int wins, int losses, int draws);

  /// No description provided for @matchScoreLine.
  ///
  /// In en, this message translates to:
  /// **'You {myScore} · Opp {oppScore}'**
  String matchScoreLine(int myScore, int oppScore);

  /// No description provided for @friends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get friends;

  /// No description provided for @friendsComingSoonBody.
  ///
  /// In en, this message translates to:
  /// **'Connect with friends and invite them to matches soon.'**
  String get friendsComingSoonBody;

  /// No description provided for @requests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get requests;

  /// No description provided for @addFriend.
  ///
  /// In en, this message translates to:
  /// **'Add Friend'**
  String get addFriend;

  /// No description provided for @searchByUsername.
  ///
  /// In en, this message translates to:
  /// **'Search by @username or name...'**
  String get searchByUsername;

  /// No description provided for @noFriendsYet.
  ///
  /// In en, this message translates to:
  /// **'No friends added yet.'**
  String get noFriendsYet;

  /// No description provided for @noFriendsHint.
  ///
  /// In en, this message translates to:
  /// **'Search player usernames in Add Friend tab to connect!'**
  String get noFriendsHint;

  /// No description provided for @noRequests.
  ///
  /// In en, this message translates to:
  /// **'No pending friend requests.'**
  String get noRequests;

  /// No description provided for @incomingRequests.
  ///
  /// In en, this message translates to:
  /// **'Incoming Requests'**
  String get incomingRequests;

  /// No description provided for @outgoingRequests.
  ///
  /// In en, this message translates to:
  /// **'Outgoing Requests'**
  String get outgoingRequests;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @removeFriend.
  ///
  /// In en, this message translates to:
  /// **'Remove Friend'**
  String get removeFriend;

  /// No description provided for @removeFriendConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove {name} from friends?'**
  String removeFriendConfirm(String name);

  /// No description provided for @friendRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Friend request sent!'**
  String get friendRequestSent;

  /// No description provided for @friendRequestAccepted.
  ///
  /// In en, this message translates to:
  /// **'Friend request accepted!'**
  String get friendRequestAccepted;

  /// No description provided for @friendRequestFrom.
  ///
  /// In en, this message translates to:
  /// **'{name} sent you a friend request'**
  String friendRequestFrom(String name);

  /// No description provided for @friendRequestAcceptedBy.
  ///
  /// In en, this message translates to:
  /// **'{name} accepted your friend request'**
  String friendRequestAcceptedBy(String name);

  /// No description provided for @friendRemoved.
  ///
  /// In en, this message translates to:
  /// **'Friend removed.'**
  String get friendRemoved;

  /// No description provided for @requestSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get requestSent;

  /// No description provided for @youTag.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get youTag;

  /// No description provided for @alreadyFriends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get alreadyFriends;

  /// No description provided for @changeUsername.
  ///
  /// In en, this message translates to:
  /// **'Change Username'**
  String get changeUsername;

  /// No description provided for @usernameHint.
  ///
  /// In en, this message translates to:
  /// **'unique_username'**
  String get usernameHint;

  /// No description provided for @usernameAvailable.
  ///
  /// In en, this message translates to:
  /// **'Username is available'**
  String get usernameAvailable;

  /// No description provided for @usernameTaken.
  ///
  /// In en, this message translates to:
  /// **'Username is already taken'**
  String get usernameTaken;

  /// No description provided for @usernameInvalidFormat.
  ///
  /// In en, this message translates to:
  /// **'3-20 characters: lowercase letters, numbers, _'**
  String get usernameInvalidFormat;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get displayName;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully!'**
  String get profileUpdated;

  /// No description provided for @searching.
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get searching;

  /// No description provided for @noPlayersFound.
  ///
  /// In en, this message translates to:
  /// **'No players found matching your search.'**
  String get noPlayersFound;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @level.
  ///
  /// In en, this message translates to:
  /// **'Level {lvl}'**
  String level(int lvl);

  /// No description provided for @levelNumber.
  ///
  /// In en, this message translates to:
  /// **'Level {lvl}'**
  String levelNumber(int lvl);

  /// No description provided for @xp.
  ///
  /// In en, this message translates to:
  /// **'XP'**
  String get xp;

  /// No description provided for @winRate.
  ///
  /// In en, this message translates to:
  /// **'Win Rate'**
  String get winRate;

  /// No description provided for @matchesPlayed.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get matchesPlayed;

  /// No description provided for @totalXp.
  ///
  /// In en, this message translates to:
  /// **'Total XP'**
  String get totalXp;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @rankTitleNovice.
  ///
  /// In en, this message translates to:
  /// **'Novice'**
  String get rankTitleNovice;

  /// No description provided for @rankTitleCardShark.
  ///
  /// In en, this message translates to:
  /// **'Card Shark'**
  String get rankTitleCardShark;

  /// No description provided for @rankTitleHighRoller.
  ///
  /// In en, this message translates to:
  /// **'High Roller'**
  String get rankTitleHighRoller;

  /// No description provided for @rankTitleTableMaster.
  ///
  /// In en, this message translates to:
  /// **'Table Master'**
  String get rankTitleTableMaster;

  /// No description provided for @rankTitleGrandAce.
  ///
  /// In en, this message translates to:
  /// **'Grand Ace'**
  String get rankTitleGrandAce;

  /// No description provided for @rankTitleShadowLegend.
  ///
  /// In en, this message translates to:
  /// **'Shadow Legend'**
  String get rankTitleShadowLegend;

  /// No description provided for @inviteFriends.
  ///
  /// In en, this message translates to:
  /// **'Invite Friends'**
  String get inviteFriends;

  /// No description provided for @invite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get invite;

  /// No description provided for @invited.
  ///
  /// In en, this message translates to:
  /// **'Invited'**
  String get invited;

  /// No description provided for @inviteSent.
  ///
  /// In en, this message translates to:
  /// **'Invite sent!'**
  String get inviteSent;

  /// No description provided for @tableInviteFrom.
  ///
  /// In en, this message translates to:
  /// **'{name} invited you to private table {code}'**
  String tableInviteFrom(String name, String code);

  /// No description provided for @joinTable.
  ///
  /// In en, this message translates to:
  /// **'Join Table'**
  String get joinTable;

  /// No description provided for @ignore.
  ///
  /// In en, this message translates to:
  /// **'Ignore'**
  String get ignore;

  /// No description provided for @noFriendsToInvite.
  ///
  /// In en, this message translates to:
  /// **'No friends added yet to invite.'**
  String get noFriendsToInvite;

  /// No description provided for @customizeAvatar.
  ///
  /// In en, this message translates to:
  /// **'Customize Avatar'**
  String get customizeAvatar;

  /// No description provided for @locked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get locked;

  /// No description provided for @equipped.
  ///
  /// In en, this message translates to:
  /// **'Equipped'**
  String get equipped;

  /// No description provided for @equip.
  ///
  /// In en, this message translates to:
  /// **'Equip'**
  String get equip;

  /// No description provided for @unlockAtLevel.
  ///
  /// In en, this message translates to:
  /// **'Unlocks at Level {lvl}'**
  String unlockAtLevel(int lvl);

  /// No description provided for @defaultAvatar.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultAvatar;

  /// No description provided for @blueAvatar.
  ///
  /// In en, this message translates to:
  /// **'Sapphire'**
  String get blueAvatar;

  /// No description provided for @redAvatar.
  ///
  /// In en, this message translates to:
  /// **'Ruby'**
  String get redAvatar;

  /// No description provided for @bronzeAvatar.
  ///
  /// In en, this message translates to:
  /// **'Bronze'**
  String get bronzeAvatar;

  /// No description provided for @silverAvatar.
  ///
  /// In en, this message translates to:
  /// **'Silver'**
  String get silverAvatar;

  /// No description provided for @jokerGirlAvatar.
  ///
  /// In en, this message translates to:
  /// **'Joker Girl'**
  String get jokerGirlAvatar;

  /// No description provided for @violetJokerGirlAvatar.
  ///
  /// In en, this message translates to:
  /// **'Violet Joker'**
  String get violetJokerGirlAvatar;

  /// No description provided for @violetQueenAvatar.
  ///
  /// In en, this message translates to:
  /// **'Violet Queen'**
  String get violetQueenAvatar;

  /// No description provided for @queenOfHeartAvatar.
  ///
  /// In en, this message translates to:
  /// **'Queen of Hearts'**
  String get queenOfHeartAvatar;

  /// No description provided for @goldenKingAvatar.
  ///
  /// In en, this message translates to:
  /// **'Golden King'**
  String get goldenKingAvatar;

  /// No description provided for @queenAvatar.
  ///
  /// In en, this message translates to:
  /// **'Queen'**
  String get queenAvatar;

  /// No description provided for @kingAvatar.
  ///
  /// In en, this message translates to:
  /// **'King'**
  String get kingAvatar;

  /// No description provided for @money.
  ///
  /// In en, this message translates to:
  /// **'Money'**
  String get money;

  /// No description provided for @chips.
  ///
  /// In en, this message translates to:
  /// **'Chips'**
  String get chips;

  /// No description provided for @exchange.
  ///
  /// In en, this message translates to:
  /// **'Exchange'**
  String get exchange;

  /// No description provided for @avatarShop.
  ///
  /// In en, this message translates to:
  /// **'Avatars'**
  String get avatarShop;

  /// No description provided for @deckShop.
  ///
  /// In en, this message translates to:
  /// **'Decks'**
  String get deckShop;

  /// No description provided for @selectMatchStake.
  ///
  /// In en, this message translates to:
  /// **'Select Match Stake'**
  String get selectMatchStake;

  /// No description provided for @stake.
  ///
  /// In en, this message translates to:
  /// **'Stake'**
  String get stake;

  /// No description provided for @pot.
  ///
  /// In en, this message translates to:
  /// **'Pot'**
  String get pot;

  /// No description provided for @winnerTakesAll.
  ///
  /// In en, this message translates to:
  /// **'Winner takes all'**
  String get winnerTakesAll;

  /// No description provided for @getMoreMoney.
  ///
  /// In en, this message translates to:
  /// **'Get Money'**
  String get getMoreMoney;

  /// No description provided for @insufficientChips.
  ///
  /// In en, this message translates to:
  /// **'Not enough chips'**
  String get insufficientChips;

  /// No description provided for @insufficientMoney.
  ///
  /// In en, this message translates to:
  /// **'Not enough money'**
  String get insufficientMoney;

  /// No description provided for @exchangedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Exchange successful'**
  String get exchangedSuccess;

  /// No description provided for @exchangeFailed.
  ///
  /// In en, this message translates to:
  /// **'Exchange failed'**
  String get exchangeFailed;

  /// No description provided for @watchAdForMoney.
  ///
  /// In en, this message translates to:
  /// **'Watch Video Ad'**
  String get watchAdForMoney;

  /// No description provided for @freeStashBonus.
  ///
  /// In en, this message translates to:
  /// **'Free Money Bonus'**
  String get freeStashBonus;

  /// No description provided for @adRewardEarned.
  ///
  /// In en, this message translates to:
  /// **'Reward earned!'**
  String get adRewardEarned;

  /// No description provided for @adNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Ad not ready, try again later'**
  String get adNotAvailable;

  /// No description provided for @chipsToMoney.
  ///
  /// In en, this message translates to:
  /// **'Convert Chips to Money'**
  String get chipsToMoney;

  /// No description provided for @moneyToChips.
  ///
  /// In en, this message translates to:
  /// **'Convert Money to Chips'**
  String get moneyToChips;

  /// No description provided for @convert.
  ///
  /// In en, this message translates to:
  /// **'Convert'**
  String get convert;

  /// No description provided for @claim.
  ///
  /// In en, this message translates to:
  /// **'Claim'**
  String get claim;

  /// No description provided for @buy.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get buy;

  /// No description provided for @owned.
  ///
  /// In en, this message translates to:
  /// **'Owned'**
  String get owned;

  /// No description provided for @unlocked.
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get unlocked;

  /// No description provided for @purchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'Purchase failed'**
  String get purchaseFailed;

  /// No description provided for @classicDeck.
  ///
  /// In en, this message translates to:
  /// **'Classic Blue'**
  String get classicDeck;

  /// No description provided for @classicDeckDesc.
  ///
  /// In en, this message translates to:
  /// **'Standard casino playing cards'**
  String get classicDeckDesc;

  /// No description provided for @onyxBlackDeck.
  ///
  /// In en, this message translates to:
  /// **'Onyx Black'**
  String get onyxBlackDeck;

  /// No description provided for @onyxBlackDeckDesc.
  ///
  /// In en, this message translates to:
  /// **'Obsidian back with gold filigree'**
  String get onyxBlackDeckDesc;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @cityLondon.
  ///
  /// In en, this message translates to:
  /// **'London'**
  String get cityLondon;

  /// No description provided for @cityParis.
  ///
  /// In en, this message translates to:
  /// **'Paris'**
  String get cityParis;

  /// No description provided for @cityMoscow.
  ///
  /// In en, this message translates to:
  /// **'Moscow'**
  String get cityMoscow;

  /// No description provided for @cityCairo.
  ///
  /// In en, this message translates to:
  /// **'Cairo'**
  String get cityCairo;

  /// No description provided for @cityMarrakech.
  ///
  /// In en, this message translates to:
  /// **'Marrakech'**
  String get cityMarrakech;

  /// No description provided for @prize.
  ///
  /// In en, this message translates to:
  /// **'Prize'**
  String get prize;

  /// No description provided for @entryFee.
  ///
  /// In en, this message translates to:
  /// **'Entry fee'**
  String get entryFee;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'es', 'fr', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
