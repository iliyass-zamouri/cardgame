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

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

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

  /// No description provided for @appleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Apple sign-in failed. Try again.'**
  String get appleSignInFailed;

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

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @shop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get shop;

  /// No description provided for @collection.
  ///
  /// In en, this message translates to:
  /// **'Collection'**
  String get collection;

  /// No description provided for @collectionCards.
  ///
  /// In en, this message translates to:
  /// **'Cards'**
  String get collectionCards;

  /// No description provided for @collectionAvatars.
  ///
  /// In en, this message translates to:
  /// **'Avatars'**
  String get collectionAvatars;

  /// No description provided for @ownedCount.
  ///
  /// In en, this message translates to:
  /// **'{owned}/{total} owned'**
  String ownedCount(int owned, int total);

  /// No description provided for @getMoreInShop.
  ///
  /// In en, this message translates to:
  /// **'Get more in the Shop'**
  String get getMoreInShop;

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

  /// No description provided for @apple.
  ///
  /// In en, this message translates to:
  /// **'Apple'**
  String get apple;

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
  /// **'Finish with the lowest total. The game ends when a player has no cards left or someone taps End game.'**
  String get ruleGoalBody;

  /// No description provided for @ruleSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Setup'**
  String get ruleSetupTitle;

  /// No description provided for @ruleSetupBody.
  ///
  /// In en, this message translates to:
  /// **'Two players. Each gets four face-down cards in a row.'**
  String get ruleSetupBody;

  /// No description provided for @ruleOpeningPeekTitle.
  ///
  /// In en, this message translates to:
  /// **'Opening peek'**
  String get ruleOpeningPeekTitle;

  /// No description provided for @ruleOpeningPeekBody.
  ///
  /// In en, this message translates to:
  /// **'Before play, tap Reveal to see your two left cards for a few seconds. Remember them — then they flip face-down again.'**
  String get ruleOpeningPeekBody;

  /// No description provided for @ruleYourTurnTitle.
  ///
  /// In en, this message translates to:
  /// **'Your turn'**
  String get ruleYourTurnTitle;

  /// No description provided for @ruleYourTurnBody.
  ///
  /// In en, this message translates to:
  /// **'Before drawing, if the top discard matches a card you know, tap it to discard it (your turn continues). Wrong guess = a penalty card. Then draw from the deck.'**
  String get ruleYourTurnBody;

  /// No description provided for @ruleAfterDrawTitle.
  ///
  /// In en, this message translates to:
  /// **'After you draw'**
  String get ruleAfterDrawTitle;

  /// No description provided for @ruleAfterDrawBody.
  ///
  /// In en, this message translates to:
  /// **'Tap one of your cards to swap (different rank) or double-discard (same rank), or tap the drawn card to throw it. Then your turn ends.'**
  String get ruleAfterDrawBody;

  /// No description provided for @ruleSpecialTitle.
  ///
  /// In en, this message translates to:
  /// **'Special cards'**
  String get ruleSpecialTitle;

  /// No description provided for @ruleSpecialBody.
  ///
  /// In en, this message translates to:
  /// **'When you draw these, you may use their power. Afterwards the card is thrown.'**
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
  /// **'When a player has no cards left or someone taps End game, all cards are revealed and added up. Ace = 1, Jack = 11, Queen = 12. Lowest total wins; equal = tie.'**
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

  /// No description provided for @sapphireFrostDeck.
  ///
  /// In en, this message translates to:
  /// **'Sapphire Dragon'**
  String get sapphireFrostDeck;

  /// No description provided for @sapphireFrostDeckDesc.
  ///
  /// In en, this message translates to:
  /// **'Celtic knotwork in sapphire and gold around twin dragons'**
  String get sapphireFrostDeckDesc;

  /// No description provided for @imperialJadeDeck.
  ///
  /// In en, this message translates to:
  /// **'High Victorian'**
  String get imperialJadeDeck;

  /// No description provided for @imperialJadeDeckDesc.
  ///
  /// In en, this message translates to:
  /// **'Emerald filigree in a gilt Victorian frame'**
  String get imperialJadeDeckDesc;

  /// No description provided for @royalCrimsonDeck.
  ///
  /// In en, this message translates to:
  /// **'Royal Crimson'**
  String get royalCrimsonDeck;

  /// No description provided for @royalCrimsonDeckDesc.
  ///
  /// In en, this message translates to:
  /// **'Gilt filigree and a crowned figure on crimson'**
  String get royalCrimsonDeckDesc;

  /// No description provided for @neonNightsDeck.
  ///
  /// In en, this message translates to:
  /// **'Neon Nights'**
  String get neonNightsDeck;

  /// No description provided for @neonNightsDeckDesc.
  ///
  /// In en, this message translates to:
  /// **'A synthwave sunset over a glowing neon grid'**
  String get neonNightsDeckDesc;

  /// No description provided for @gildedDeck.
  ///
  /// In en, this message translates to:
  /// **'24K Gold'**
  String get gildedDeck;

  /// No description provided for @gildedDeckDesc.
  ///
  /// In en, this message translates to:
  /// **'Engraved solid gold with a brilliant-cut diamond'**
  String get gildedDeckDesc;

  /// No description provided for @rarityRare.
  ///
  /// In en, this message translates to:
  /// **'Rare'**
  String get rarityRare;

  /// No description provided for @rarityEpic.
  ///
  /// In en, this message translates to:
  /// **'Epic'**
  String get rarityEpic;

  /// No description provided for @rarityLegendary.
  ///
  /// In en, this message translates to:
  /// **'Legendary'**
  String get rarityLegendary;

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

  /// No description provided for @cityToronto.
  ///
  /// In en, this message translates to:
  /// **'Toronto'**
  String get cityToronto;

  /// No description provided for @cityNewYork.
  ///
  /// In en, this message translates to:
  /// **'New York'**
  String get cityNewYork;

  /// No description provided for @cityTokyo.
  ///
  /// In en, this message translates to:
  /// **'Tokyo'**
  String get cityTokyo;

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

  /// No description provided for @linkGoogleAccount.
  ///
  /// In en, this message translates to:
  /// **'Link Google account'**
  String get linkGoogleAccount;

  /// No description provided for @linkingGoogle.
  ///
  /// In en, this message translates to:
  /// **'Linking…'**
  String get linkingGoogle;

  /// No description provided for @linkAppleAccount.
  ///
  /// In en, this message translates to:
  /// **'Link Apple account'**
  String get linkAppleAccount;

  /// No description provided for @linkGoogleSuccess.
  ///
  /// In en, this message translates to:
  /// **'Google account linked. Progress saved.'**
  String get linkGoogleSuccess;

  /// No description provided for @linkGoogleSwitched.
  ///
  /// In en, this message translates to:
  /// **'Signed in with your Google account.'**
  String get linkGoogleSwitched;

  /// No description provided for @linkAppleSuccess.
  ///
  /// In en, this message translates to:
  /// **'Apple account linked. Progress saved.'**
  String get linkAppleSuccess;

  /// No description provided for @linkAppleSwitched.
  ///
  /// In en, this message translates to:
  /// **'Signed in with your Apple account.'**
  String get linkAppleSwitched;

  /// No description provided for @saveProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Save your progress'**
  String get saveProgressTitle;

  /// No description provided for @saveProgressBody.
  ///
  /// In en, this message translates to:
  /// **'Link a Google account so you keep your money, chips, and ranking if you change devices.'**
  String get saveProgressBody;

  /// No description provided for @saveProgressBodyIos.
  ///
  /// In en, this message translates to:
  /// **'Link an Apple or Google account so you keep your money, chips, and ranking if you change devices.'**
  String get saveProgressBodyIos;

  /// No description provided for @googleAccountInUseTitle.
  ///
  /// In en, this message translates to:
  /// **'Google account in use'**
  String get googleAccountInUseTitle;

  /// No description provided for @appleAccountInUseTitle.
  ///
  /// In en, this message translates to:
  /// **'Apple account in use'**
  String get appleAccountInUseTitle;

  /// No description provided for @googleAccountInUseBody.
  ///
  /// In en, this message translates to:
  /// **'This Google account already belongs to @{username}. Switch to that account? Your guest progress on this device will be lost.'**
  String googleAccountInUseBody(String username);

  /// No description provided for @appleAccountInUseBody.
  ///
  /// In en, this message translates to:
  /// **'This Apple account already belongs to @{username}. Switch to that account? Your guest progress on this device will be lost.'**
  String appleAccountInUseBody(String username);

  /// No description provided for @switchToGoogleAccount.
  ///
  /// In en, this message translates to:
  /// **'Switch account'**
  String get switchToGoogleAccount;

  /// No description provided for @dontAskAgain.
  ///
  /// In en, this message translates to:
  /// **'Don\'t ask again'**
  String get dontAskAgain;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @youQuit.
  ///
  /// In en, this message translates to:
  /// **'You quit'**
  String get youQuit;

  /// No description provided for @opponentQuit.
  ///
  /// In en, this message translates to:
  /// **'Opponent quit'**
  String get opponentQuit;

  /// No description provided for @turnTimedOut.
  ///
  /// In en, this message translates to:
  /// **'Time\'s up. Your turn was played for you.'**
  String get turnTimedOut;

  /// No description provided for @turnTimedOutWarning.
  ///
  /// In en, this message translates to:
  /// **'Time\'s up. Your turn was played for you. Turns left before you forfeit: {remaining}.'**
  String turnTimedOutWarning(int remaining);

  /// No description provided for @youTimedOut.
  ///
  /// In en, this message translates to:
  /// **'You ran out of time'**
  String get youTimedOut;

  /// No description provided for @opponentTimedOut.
  ///
  /// In en, this message translates to:
  /// **'Opponent ran out of time'**
  String get opponentTimedOut;

  /// No description provided for @matchResultQuit.
  ///
  /// In en, this message translates to:
  /// **'QUIT'**
  String get matchResultQuit;

  /// No description provided for @leaveMatchPenaltyMessage.
  ///
  /// In en, this message translates to:
  /// **'Leaving now counts as a loss: you\'ll lose your stake and 15 points.'**
  String get leaveMatchPenaltyMessage;

  /// No description provided for @notEnoughMoneyTitle.
  ///
  /// In en, this message translates to:
  /// **'Not enough money'**
  String get notEnoughMoneyTitle;

  /// No description provided for @notEnoughMoneyMessage.
  ///
  /// In en, this message translates to:
  /// **'The stake is {required} but you have {money}. Exchange chips or buy more to play the rematch.'**
  String notEnoughMoneyMessage(int required, int money);

  /// No description provided for @stakeCovered.
  ///
  /// In en, this message translates to:
  /// **'You\'re covered — ready for the rematch.'**
  String get stakeCovered;

  /// No description provided for @exchangeChips.
  ///
  /// In en, this message translates to:
  /// **'Exchange chips'**
  String get exchangeChips;

  /// No description provided for @buyMoney.
  ///
  /// In en, this message translates to:
  /// **'Buy money'**
  String get buyMoney;

  /// No description provided for @rematchStarting.
  ///
  /// In en, this message translates to:
  /// **'Taking stakes…'**
  String get rematchStarting;

  /// No description provided for @opponentCantAffordRematch.
  ///
  /// In en, this message translates to:
  /// **'{name} can\'t cover the stake'**
  String opponentCantAffordRematch(String name);

  /// No description provided for @offlineReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Offline · reconnecting…'**
  String get offlineReconnecting;

  /// No description provided for @getMoreChips.
  ///
  /// In en, this message translates to:
  /// **'Get Chips'**
  String get getMoreChips;

  /// No description provided for @notEnoughChipsTitle.
  ///
  /// In en, this message translates to:
  /// **'Not enough chips'**
  String get notEnoughChipsTitle;

  /// No description provided for @notEnoughChipsMessage.
  ///
  /// In en, this message translates to:
  /// **'The stake is {required} chips but you have {chips}. Buy more chips to play the rematch.'**
  String notEnoughChipsMessage(int required, int chips);

  /// No description provided for @buyChips.
  ///
  /// In en, this message translates to:
  /// **'Buy chips'**
  String get buyChips;

  /// No description provided for @tutLessonValuesTitle.
  ///
  /// In en, this message translates to:
  /// **'Goal & card values'**
  String get tutLessonValuesTitle;

  /// No description provided for @tutLessonDealTitle.
  ///
  /// In en, this message translates to:
  /// **'The deal & first look'**
  String get tutLessonDealTitle;

  /// No description provided for @tutLessonSwapTitle.
  ///
  /// In en, this message translates to:
  /// **'Draw & swap'**
  String get tutLessonSwapTitle;

  /// No description provided for @tutLessonThrowTitle.
  ///
  /// In en, this message translates to:
  /// **'Throw a card away'**
  String get tutLessonThrowTitle;

  /// No description provided for @tutLessonDoubleTitle.
  ///
  /// In en, this message translates to:
  /// **'Double discard'**
  String get tutLessonDoubleTitle;

  /// No description provided for @tutLessonMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Match the discard'**
  String get tutLessonMatchTitle;

  /// No description provided for @tutLessonJackTitle.
  ///
  /// In en, this message translates to:
  /// **'Jack: peek'**
  String get tutLessonJackTitle;

  /// No description provided for @tutLessonQueenTitle.
  ///
  /// In en, this message translates to:
  /// **'Queen: swap or shuffle'**
  String get tutLessonQueenTitle;

  /// No description provided for @tutLessonEndTitle.
  ///
  /// In en, this message translates to:
  /// **'Ending & scoring'**
  String get tutLessonEndTitle;

  /// No description provided for @tutLessonTipsTitle.
  ///
  /// In en, this message translates to:
  /// **'Winning tips'**
  String get tutLessonTipsTitle;

  /// No description provided for @tutValuesIntro.
  ///
  /// In en, this message translates to:
  /// **'ShadowHand is a memory game for two. Each player has cards face down. When the game ends, everyone adds up their cards — the lowest total wins.'**
  String get tutValuesIntro;

  /// No description provided for @tutValuesChart.
  ///
  /// In en, this message translates to:
  /// **'Each card is worth points. Ace = 1, number cards = their number, Jack = 11, Queen = 12, red King = 13. The best cards: a black King is worth 0 and a Joker is worth −1!'**
  String get tutValuesChart;

  /// No description provided for @tutValuesQuizLowest.
  ///
  /// In en, this message translates to:
  /// **'Quick quiz: tap the card worth the fewest points.'**
  String get tutValuesQuizLowest;

  /// No description provided for @tutValuesQuizLowestWrong.
  ///
  /// In en, this message translates to:
  /// **'Not quite. The Joker is worth −1 — even lower than an Ace.'**
  String get tutValuesQuizLowestWrong;

  /// No description provided for @tutValuesQuizKing.
  ///
  /// In en, this message translates to:
  /// **'Two Kings here. Tap the one worth 0 points.'**
  String get tutValuesQuizKing;

  /// No description provided for @tutValuesQuizKingWrong.
  ///
  /// In en, this message translates to:
  /// **'Only black Kings (♠ ♣) are worth 0. Red Kings (♥ ♦) are worth 13 — the worst card in the deck!'**
  String get tutValuesQuizKingWrong;

  /// No description provided for @tutValuesDone.
  ///
  /// In en, this message translates to:
  /// **'Perfect! Your goal: keep low cards and get rid of high ones.'**
  String get tutValuesDone;

  /// No description provided for @tutDealIntro.
  ///
  /// In en, this message translates to:
  /// **'Each player gets 4 cards face down in a row. You don\'t know what they are yet — and neither does your opponent.'**
  String get tutDealIntro;

  /// No description provided for @tutDealReveal.
  ///
  /// In en, this message translates to:
  /// **'Before play starts, you get one quick look. Tap Reveal.'**
  String get tutDealReveal;

  /// No description provided for @tutDealMemorize.
  ///
  /// In en, this message translates to:
  /// **'Your two cards on the left are shown for a few seconds. Remember them: a 2 and an 8!'**
  String get tutDealMemorize;

  /// No description provided for @tutDealQuiz.
  ///
  /// In en, this message translates to:
  /// **'They\'re face down again. Where is your 2? Tap it.'**
  String get tutDealQuiz;

  /// No description provided for @tutDealQuizWrong.
  ///
  /// In en, this message translates to:
  /// **'The 2 was your first card, on the far left. Memory is everything in this game!'**
  String get tutDealQuizWrong;

  /// No description provided for @tutDealDone.
  ///
  /// In en, this message translates to:
  /// **'Right! Your other two cards are still a mystery — you\'ll learn more as you play.'**
  String get tutDealDone;

  /// No description provided for @tutDrawPrompt.
  ///
  /// In en, this message translates to:
  /// **'It\'s your turn. Tap the deck to draw a card.'**
  String get tutDrawPrompt;

  /// No description provided for @tutSwapIntro.
  ///
  /// In en, this message translates to:
  /// **'You remember your first two cards: a 2 and a 9. A 9 costs a lot of points — let\'s replace it.'**
  String get tutSwapIntro;

  /// No description provided for @tutSwapPick.
  ///
  /// In en, this message translates to:
  /// **'You drew a 3. That\'s better than your 9! Tap your 9 (second card) to swap them.'**
  String get tutSwapPick;

  /// No description provided for @tutSwapPickWrong.
  ///
  /// In en, this message translates to:
  /// **'Tap your 9 — the second card from the left. Swapping a card you don\'t know is a gamble.'**
  String get tutSwapPickWrong;

  /// No description provided for @tutSwapDone.
  ///
  /// In en, this message translates to:
  /// **'The 3 goes face down where the 9 was, and the 9 goes to the discard pile. That ends your turn — and you just saved 6 points.'**
  String get tutSwapDone;

  /// No description provided for @tutThrowPick.
  ///
  /// In en, this message translates to:
  /// **'Ouch — a red King, worth 13. You don\'t want it! Tap the drawn card to throw it on the discard pile.'**
  String get tutThrowPick;

  /// No description provided for @tutThrowWrong.
  ///
  /// In en, this message translates to:
  /// **'Don\'t keep a bad card. Tap the drawn card (bottom left) to throw it away.'**
  String get tutThrowWrong;

  /// No description provided for @tutThrowDone.
  ///
  /// In en, this message translates to:
  /// **'Thrown away! Your cards didn\'t change and your turn is over. Throw any card that wouldn\'t make your hand better.'**
  String get tutThrowDone;

  /// No description provided for @tutDoubleIntro.
  ///
  /// In en, this message translates to:
  /// **'You remember your first card is a 5.'**
  String get tutDoubleIntro;

  /// No description provided for @tutDoublePick.
  ///
  /// In en, this message translates to:
  /// **'Another 5! When the card you draw has the same rank as one of yours, tap your card: both get discarded.'**
  String get tutDoublePick;

  /// No description provided for @tutDoubleWrong.
  ///
  /// In en, this message translates to:
  /// **'Tap your 5 — the first card on the left.'**
  String get tutDoubleWrong;

  /// No description provided for @tutDoubleDone.
  ///
  /// In en, this message translates to:
  /// **'Both 5s are gone and you have one card fewer. Fewer cards means fewer points — and if you run out of cards, the game ends.'**
  String get tutDoubleDone;

  /// No description provided for @tutMatchIntro.
  ///
  /// In en, this message translates to:
  /// **'You remember your first card is a 7. Now it\'s your opponent\'s turn…'**
  String get tutMatchIntro;

  /// No description provided for @tutMatchPick.
  ///
  /// In en, this message translates to:
  /// **'Your opponent threw a 7! On your turn, before you draw, you can tap a card with the same rank as the top of the discard pile to get rid of it. Tap your 7.'**
  String get tutMatchPick;

  /// No description provided for @tutMatchWrong.
  ///
  /// In en, this message translates to:
  /// **'Tap your 7 — the first card on the left.'**
  String get tutMatchWrong;

  /// No description provided for @tutMatchContinue.
  ///
  /// In en, this message translates to:
  /// **'A free discard! Matching doesn\'t end your turn: you can match again, and then you still draw. Tap the deck.'**
  String get tutMatchContinue;

  /// No description provided for @tutMatchThrow.
  ///
  /// In en, this message translates to:
  /// **'An 8 — not great. Tap it to throw it and end your turn.'**
  String get tutMatchThrow;

  /// No description provided for @tutMatchGuess.
  ///
  /// In en, this message translates to:
  /// **'Next turn, the top card is a 4. You think your middle card might be a 4… but you\'re not sure. Let\'s see what a wrong guess does: tap it.'**
  String get tutMatchGuess;

  /// No description provided for @tutMatchPenalty.
  ///
  /// In en, this message translates to:
  /// **'Wrong — it wasn\'t a 4. You get a penalty card from the deck, face down, and the card you tapped stays. Only match when you\'re sure!'**
  String get tutMatchPenalty;

  /// No description provided for @tutJackPeekButton.
  ///
  /// In en, this message translates to:
  /// **'A Jack! When you draw a Jack you can peek at any one card — yours or your opponent\'s. Tap Peek.'**
  String get tutJackPeekButton;

  /// No description provided for @tutJackPick.
  ///
  /// In en, this message translates to:
  /// **'Now tap the card you want to see. Let\'s spy on your opponent\'s second card.'**
  String get tutJackPick;

  /// No description provided for @tutJackPickWrong.
  ///
  /// In en, this message translates to:
  /// **'Tap your opponent\'s second card from the left.'**
  String get tutJackPickWrong;

  /// No description provided for @tutJackReveal.
  ///
  /// In en, this message translates to:
  /// **'It\'s a Queen — 12 points for them. Remember where it is: it hides again in a moment.'**
  String get tutJackReveal;

  /// No description provided for @tutJackDone.
  ///
  /// In en, this message translates to:
  /// **'After the peek, the Jack is thrown automatically and your turn ends. The power is optional: you can also keep or throw a Jack like any other card.'**
  String get tutJackDone;

  /// No description provided for @tutQueenIntro.
  ///
  /// In en, this message translates to:
  /// **'You remember your second card is a 10. Let\'s give it to your opponent.'**
  String get tutQueenIntro;

  /// No description provided for @tutQueenButtons.
  ///
  /// In en, this message translates to:
  /// **'A Queen! You get a choice. Shuffle mixes up one player\'s cards. Replace swaps one of your cards with one of theirs. Tap Replace.'**
  String get tutQueenButtons;

  /// No description provided for @tutQueenButtonsWrong.
  ///
  /// In en, this message translates to:
  /// **'For this lesson, tap Replace.'**
  String get tutQueenButtonsWrong;

  /// No description provided for @tutQueenPickYours.
  ///
  /// In en, this message translates to:
  /// **'First tap the card you want to give away: your 10, the second card.'**
  String get tutQueenPickYours;

  /// No description provided for @tutQueenPickYoursWrong.
  ///
  /// In en, this message translates to:
  /// **'Tap your 10 — your second card from the left.'**
  String get tutQueenPickYoursWrong;

  /// No description provided for @tutQueenPickTheirs.
  ///
  /// In en, this message translates to:
  /// **'Now tap the opponent\'s card you want to take: their first card.'**
  String get tutQueenPickTheirs;

  /// No description provided for @tutQueenPickTheirsWrong.
  ///
  /// In en, this message translates to:
  /// **'Tap your opponent\'s first card, on the left.'**
  String get tutQueenPickTheirsWrong;

  /// No description provided for @tutQueenDone.
  ///
  /// In en, this message translates to:
  /// **'Swapped! Your 10 now belongs to your opponent. You don\'t see the card you got, but most cards are worth less than 10 — a good deal. The Queen is thrown after use.'**
  String get tutQueenDone;

  /// No description provided for @tutQueenShuffle.
  ///
  /// In en, this message translates to:
  /// **'Shuffle is the other option: mix up your opponent\'s cards and everything they remembered becomes useless. You can also shuffle your own cards.'**
  String get tutQueenShuffle;

  /// No description provided for @tutEndIntro.
  ///
  /// In en, this message translates to:
  /// **'The game ends in one of two ways: a player has no cards left, or someone taps End game.'**
  String get tutEndIntro;

  /// No description provided for @tutEndPress.
  ///
  /// In en, this message translates to:
  /// **'Think your total is lower? Either player can tap End game at any time. Try it.'**
  String get tutEndPress;

  /// No description provided for @tutEndCount.
  ///
  /// In en, this message translates to:
  /// **'All cards are revealed. Add up yours: 3 + 2 + black King + Joker. What\'s your total?'**
  String get tutEndCount;

  /// No description provided for @tutEndCountWrong.
  ///
  /// In en, this message translates to:
  /// **'Remember: a black King is 0 and a Joker is −1. So 3 + 2 + 0 − 1 = 4.'**
  String get tutEndCountWrong;

  /// No description provided for @tutEndWinner.
  ///
  /// In en, this message translates to:
  /// **'Your opponent has 9 + 5 + 7 + 1 = 22. Who wins?'**
  String get tutEndWinner;

  /// No description provided for @tutEndWinnerWrong.
  ///
  /// In en, this message translates to:
  /// **'The lowest total wins: 4 beats 22.'**
  String get tutEndWinnerWrong;

  /// No description provided for @tutEndDone.
  ///
  /// In en, this message translates to:
  /// **'You win! If both totals are equal, it\'s a tie.'**
  String get tutEndDone;

  /// No description provided for @tutTipMemory.
  ///
  /// In en, this message translates to:
  /// **'Tip 1 — Remember everything. Every card you see — at the start, when you swap, with a Jack — tells you something. Keep track of it.'**
  String get tutTipMemory;

  /// No description provided for @tutTipKeepLow.
  ///
  /// In en, this message translates to:
  /// **'Tip 2 — Keep black Kings and Jokers. They\'re worth 0 and −1: never swap them away.'**
  String get tutTipKeepLow;

  /// No description provided for @tutTipDiscard.
  ///
  /// In en, this message translates to:
  /// **'Tip 3 — Watch the discard pile. Every card your opponent throws is a chance to match one of yours for free.'**
  String get tutTipDiscard;

  /// No description provided for @tutTipQueen.
  ///
  /// In en, this message translates to:
  /// **'Tip 4 — Use Queens well. Give away your highest card, or Shuffle to wreck your opponent\'s memory.'**
  String get tutTipQueen;

  /// No description provided for @tutTipEnd.
  ///
  /// In en, this message translates to:
  /// **'Tip 5 — End at the right time. When you think your total is lower, tap End game before your opponent catches up.'**
  String get tutTipEnd;

  /// No description provided for @tutChoiceYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get tutChoiceYou;

  /// No description provided for @tutChoiceOpponent.
  ///
  /// In en, this message translates to:
  /// **'Opponent'**
  String get tutChoiceOpponent;

  /// No description provided for @tutChoiceTie.
  ///
  /// In en, this message translates to:
  /// **'Tie'**
  String get tutChoiceTie;

  /// No description provided for @tutDeckLabel.
  ///
  /// In en, this message translates to:
  /// **'Deck'**
  String get tutDeckLabel;

  /// No description provided for @tutDiscardLabel.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get tutDiscardLabel;

  /// No description provided for @tutDrawnLabel.
  ///
  /// In en, this message translates to:
  /// **'Drawn'**
  String get tutDrawnLabel;

  /// No description provided for @tutAceLabel.
  ///
  /// In en, this message translates to:
  /// **'Ace'**
  String get tutAceLabel;

  /// No description provided for @tutNumberCardsLabel.
  ///
  /// In en, this message translates to:
  /// **'2 to 10'**
  String get tutNumberCardsLabel;

  /// No description provided for @tutRedKingLabel.
  ///
  /// In en, this message translates to:
  /// **'Red King'**
  String get tutRedKingLabel;

  /// No description provided for @tutTapHighlighted.
  ///
  /// In en, this message translates to:
  /// **'Tap the glowing spot to continue.'**
  String get tutTapHighlighted;

  /// No description provided for @tutLessonProgress.
  ///
  /// In en, this message translates to:
  /// **'Lesson {current} of {total}'**
  String tutLessonProgress(int current, int total);

  /// No description provided for @tutSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get tutSkip;

  /// No description provided for @tutLessonDone.
  ///
  /// In en, this message translates to:
  /// **'Lesson complete!'**
  String get tutLessonDone;

  /// No description provided for @tutReplay.
  ///
  /// In en, this message translates to:
  /// **'Replay'**
  String get tutReplay;

  /// No description provided for @tutFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get tutFinish;

  /// No description provided for @tutNextLesson.
  ///
  /// In en, this message translates to:
  /// **'Next lesson'**
  String get tutNextLesson;

  /// No description provided for @tutCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re ready!'**
  String get tutCompleteTitle;

  /// No description provided for @tutCompleteBody.
  ///
  /// In en, this message translates to:
  /// **'You know all the rules. Practice against the robot, then take on real players.'**
  String get tutCompleteBody;

  /// No description provided for @tutHubIntro.
  ///
  /// In en, this message translates to:
  /// **'Learn ShadowHand by playing. Each short lesson puts cards in your hands and walks you through one rule.'**
  String get tutHubIntro;

  /// No description provided for @tutStartAll.
  ///
  /// In en, this message translates to:
  /// **'Start tutorial'**
  String get tutStartAll;

  /// No description provided for @tutContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue tutorial'**
  String get tutContinue;

  /// No description provided for @tutLessonsHeader.
  ///
  /// In en, this message translates to:
  /// **'Lessons'**
  String get tutLessonsHeader;

  /// No description provided for @tutQuickRules.
  ///
  /// In en, this message translates to:
  /// **'Quick rules'**
  String get tutQuickRules;

  /// No description provided for @tutQuickRulesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Every rule in 7 short cards'**
  String get tutQuickRulesSubtitle;

  /// No description provided for @tutPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'New to ShadowHand?'**
  String get tutPromptTitle;

  /// No description provided for @tutPromptBody.
  ///
  /// In en, this message translates to:
  /// **'Learn to play in a quick hands-on tutorial. It takes about 3 minutes.'**
  String get tutPromptBody;

  /// No description provided for @tutPromptLater.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get tutPromptLater;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @chatHint.
  ///
  /// In en, this message translates to:
  /// **'Type a message…'**
  String get chatHint;

  /// No description provided for @chatEmpty.
  ///
  /// In en, this message translates to:
  /// **'No messages yet. Say hi!'**
  String get chatEmpty;

  /// No description provided for @quickPhrases.
  ///
  /// In en, this message translates to:
  /// **'Quick phrases'**
  String get quickPhrases;

  /// No description provided for @phraseHello.
  ///
  /// In en, this message translates to:
  /// **'Hi!'**
  String get phraseHello;

  /// No description provided for @phraseGoodLuck.
  ///
  /// In en, this message translates to:
  /// **'Good luck'**
  String get phraseGoodLuck;

  /// No description provided for @phraseWellPlayed.
  ///
  /// In en, this message translates to:
  /// **'Well played'**
  String get phraseWellPlayed;

  /// No description provided for @phrasePlayFast.
  ///
  /// In en, this message translates to:
  /// **'Play fast!'**
  String get phrasePlayFast;

  /// No description provided for @phraseOops.
  ///
  /// In en, this message translates to:
  /// **'Oops'**
  String get phraseOops;

  /// No description provided for @phraseThanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks'**
  String get phraseThanks;

  /// No description provided for @phraseUnlucky.
  ///
  /// In en, this message translates to:
  /// **'Unlucky draw'**
  String get phraseUnlucky;

  /// No description provided for @phraseHehe.
  ///
  /// In en, this message translates to:
  /// **'Hehe'**
  String get phraseHehe;

  /// No description provided for @phraseGg.
  ///
  /// In en, this message translates to:
  /// **'GG'**
  String get phraseGg;

  /// No description provided for @micOn.
  ///
  /// In en, this message translates to:
  /// **'Mic on'**
  String get micOn;

  /// No description provided for @micOff.
  ///
  /// In en, this message translates to:
  /// **'Mic off'**
  String get micOff;

  /// No description provided for @micPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone access is off. Allow it in your phone settings to talk.'**
  String get micPermissionDenied;

  /// No description provided for @voiceOpponentTalking.
  ///
  /// In en, this message translates to:
  /// **'Voice on'**
  String get voiceOpponentTalking;

  /// No description provided for @muteOpponent.
  ///
  /// In en, this message translates to:
  /// **'Mute player'**
  String get muteOpponent;

  /// No description provided for @unmuteOpponent.
  ///
  /// In en, this message translates to:
  /// **'Unmute player'**
  String get unmuteOpponent;

  /// No description provided for @opponentMutedToast.
  ///
  /// In en, this message translates to:
  /// **'{name} is muted'**
  String opponentMutedToast(String name);

  /// No description provided for @reportPlayer.
  ///
  /// In en, this message translates to:
  /// **'Report player'**
  String get reportPlayer;

  /// No description provided for @reportPlayerConfirm.
  ///
  /// In en, this message translates to:
  /// **'Report {name} for bad behaviour?'**
  String reportPlayerConfirm(String name);

  /// No description provided for @reportedToast.
  ///
  /// In en, this message translates to:
  /// **'Thanks, we\'ll review this player'**
  String get reportedToast;

  /// No description provided for @recentForm.
  ///
  /// In en, this message translates to:
  /// **'Recent form'**
  String get recentForm;

  /// No description provided for @noRecentMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches yet'**
  String get noRecentMatches;

  /// No description provided for @tableChatSettings.
  ///
  /// In en, this message translates to:
  /// **'Table chat'**
  String get tableChatSettings;

  /// No description provided for @showOpponentChat.
  ///
  /// In en, this message translates to:
  /// **'Show opponent chat'**
  String get showOpponentChat;

  /// No description provided for @voiceChatSetting.
  ///
  /// In en, this message translates to:
  /// **'Voice chat'**
  String get voiceChatSetting;

  /// No description provided for @errChatRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Slow down, you\'re sending messages too fast'**
  String get errChatRateLimited;

  /// No description provided for @errChatInvalid.
  ///
  /// In en, this message translates to:
  /// **'Message couldn\'t be sent'**
  String get errChatInvalid;

  /// No description provided for @phraseNiceSwap.
  ///
  /// In en, this message translates to:
  /// **'Nice swap!'**
  String get phraseNiceSwap;

  /// No description provided for @phraseSharpMemory.
  ///
  /// In en, this message translates to:
  /// **'What a memory!'**
  String get phraseSharpMemory;

  /// No description provided for @phraseStopPeeking.
  ///
  /// In en, this message translates to:
  /// **'Stop peeking!'**
  String get phraseStopPeeking;

  /// No description provided for @phraseGiveCardBack.
  ///
  /// In en, this message translates to:
  /// **'Give my card back!'**
  String get phraseGiveCardBack;

  /// No description provided for @phraseBlackKingPlease.
  ///
  /// In en, this message translates to:
  /// **'Black King, please!'**
  String get phraseBlackKingPlease;

  /// No description provided for @phraseLowTotal.
  ///
  /// In en, this message translates to:
  /// **'My total is tiny'**
  String get phraseLowTotal;

  /// No description provided for @phraseFoundJoker.
  ///
  /// In en, this message translates to:
  /// **'I found a Joker!'**
  String get phraseFoundJoker;

  /// No description provided for @phraseKnowMyCards.
  ///
  /// In en, this message translates to:
  /// **'I know all my cards'**
  String get phraseKnowMyCards;

  /// No description provided for @phraseEndingNextTurn.
  ///
  /// In en, this message translates to:
  /// **'Ending it next turn!'**
  String get phraseEndingNextTurn;

  /// No description provided for @dailyStreakTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Streak'**
  String get dailyStreakTitle;

  /// No description provided for @dailyDay.
  ///
  /// In en, this message translates to:
  /// **'Day {day}'**
  String dailyDay(int day);

  /// No description provided for @dailyDayOfWeek.
  ///
  /// In en, this message translates to:
  /// **'Day {day} of 7'**
  String dailyDayOfWeek(int day);

  /// No description provided for @dailyToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dailyToday;

  /// No description provided for @dailyTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get dailyTomorrow;

  /// No description provided for @dailyJackpot.
  ///
  /// In en, this message translates to:
  /// **'Jackpot'**
  String get dailyJackpot;

  /// No description provided for @dailyStreakCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Start your streak} =1{1-day streak} other{{count}-day streak}}'**
  String dailyStreakCount(int count);

  /// No description provided for @dailyBest.
  ///
  /// In en, this message translates to:
  /// **'Best {best}'**
  String dailyBest(int best);

  /// No description provided for @dailyNextIn.
  ///
  /// In en, this message translates to:
  /// **'Next reward in {time}'**
  String dailyNextIn(String time);

  /// No description provided for @dailyComeBackTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Come back tomorrow'**
  String get dailyComeBackTomorrow;

  /// No description provided for @dailyShortAd.
  ///
  /// In en, this message translates to:
  /// **'Short ad'**
  String get dailyShortAd;

  /// No description provided for @dailyBoostedBadge.
  ///
  /// In en, this message translates to:
  /// **'×{multiplier} ad boost'**
  String dailyBoostedBadge(int multiplier);

  /// No description provided for @dailyStreakBrokenTitle.
  ///
  /// In en, this message translates to:
  /// **'Your streak broke'**
  String get dailyStreakBrokenTitle;

  /// No description provided for @dailyStreakBrokenBody.
  ///
  /// In en, this message translates to:
  /// **'Restore it to carry on at Day {day}, or start a new streak from Day 1.'**
  String dailyStreakBrokenBody(int day);

  /// No description provided for @dailyRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get dailyRestore;

  /// No description provided for @dailyStartOver.
  ///
  /// In en, this message translates to:
  /// **'Start over'**
  String get dailyStartOver;

  /// No description provided for @dailyGraceForgiven.
  ///
  /// In en, this message translates to:
  /// **'Missed day forgiven'**
  String get dailyGraceForgiven;

  /// No description provided for @dailyFreezeSaves.
  ///
  /// In en, this message translates to:
  /// **'A Streak Freeze saves your streak'**
  String get dailyFreezeSaves;

  /// No description provided for @dailyNewStreak.
  ///
  /// In en, this message translates to:
  /// **'A new streak starts today'**
  String get dailyNewStreak;

  /// No description provided for @dailyEventEnds.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =0{Ends today} =1{Ends tomorrow} other{Ends in {days} days}}'**
  String dailyEventEnds(int days);

  /// No description provided for @dailyCoinBoost.
  ///
  /// In en, this message translates to:
  /// **'Coin Boost'**
  String get dailyCoinBoost;

  /// No description provided for @dailyCoinBoostBody.
  ///
  /// In en, this message translates to:
  /// **'+{percent}% money on match wins'**
  String dailyCoinBoostBody(int percent);

  /// No description provided for @dailyStreakFreeze.
  ///
  /// In en, this message translates to:
  /// **'Streak Freeze'**
  String get dailyStreakFreeze;

  /// No description provided for @dailyStreakFreezeBody.
  ///
  /// In en, this message translates to:
  /// **'Saves your streak if you miss a day'**
  String get dailyStreakFreezeBody;

  /// No description provided for @dailyMysteryChest.
  ///
  /// In en, this message translates to:
  /// **'Mystery Chest'**
  String get dailyMysteryChest;

  /// No description provided for @dailyChestInside.
  ///
  /// In en, this message translates to:
  /// **'What\'s inside'**
  String get dailyChestInside;

  /// No description provided for @dailyChestNote.
  ///
  /// In en, this message translates to:
  /// **'One reward, picked by chance when you claim.'**
  String get dailyChestNote;

  /// No description provided for @dailyMysteryGift.
  ///
  /// In en, this message translates to:
  /// **'Mystery gift'**
  String get dailyMysteryGift;

  /// No description provided for @dailyNew.
  ///
  /// In en, this message translates to:
  /// **'New!'**
  String get dailyNew;

  /// No description provided for @dailyAlreadyOwned.
  ///
  /// In en, this message translates to:
  /// **'Already owned'**
  String get dailyAlreadyOwned;

  /// No description provided for @dailyCollect.
  ///
  /// In en, this message translates to:
  /// **'Collect'**
  String get dailyCollect;

  /// No description provided for @dailyCollected.
  ///
  /// In en, this message translates to:
  /// **'Collected'**
  String get dailyCollected;

  /// No description provided for @dailyDayReward.
  ///
  /// In en, this message translates to:
  /// **'Day {day} reward'**
  String dailyDayReward(int day);

  /// No description provided for @dailyJackpotWon.
  ///
  /// In en, this message translates to:
  /// **'Jackpot!'**
  String get dailyJackpotWon;

  /// No description provided for @dailyWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back!'**
  String get dailyWelcomeBack;

  /// No description provided for @dailyWelcomeBackBody.
  ///
  /// In en, this message translates to:
  /// **'We kept a gift for you while you were away.'**
  String get dailyWelcomeBackBody;

  /// No description provided for @dailyClaimFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t collect right now. Try again.'**
  String get dailyClaimFailed;

  /// No description provided for @dailyLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your streak.'**
  String get dailyLoadFailed;

  /// No description provided for @dailyRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get dailyRetry;

  /// No description provided for @dailyEntryReady.
  ///
  /// In en, this message translates to:
  /// **'Day {day} reward is ready'**
  String dailyEntryReady(int day);

  /// No description provided for @dailyEntryBroken.
  ///
  /// In en, this message translates to:
  /// **'Streak broken · restore it'**
  String get dailyEntryBroken;

  /// No description provided for @dailyEntryComeback.
  ///
  /// In en, this message translates to:
  /// **'A welcome-back gift is waiting'**
  String get dailyEntryComeback;

  /// No description provided for @boostsTitle.
  ///
  /// In en, this message translates to:
  /// **'Boosts'**
  String get boostsTitle;

  /// No description provided for @boostReady.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 boost ready} other{{count} boosts ready}}'**
  String boostReady(int count);

  /// No description provided for @boostWinsPay.
  ///
  /// In en, this message translates to:
  /// **'Money wins pay +{percent}% (up to {max})'**
  String boostWinsPay(int percent, String max);

  /// No description provided for @boostTimeLeft.
  ///
  /// In en, this message translates to:
  /// **'{time} left'**
  String boostTimeLeft(String time);

  /// No description provided for @boostActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get boostActive;

  /// No description provided for @boostActivate.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get boostActivate;

  /// No description provided for @boostAddTime.
  ///
  /// In en, this message translates to:
  /// **'Add {time}'**
  String boostAddTime(String time);

  /// No description provided for @boostWaitsFor.
  ///
  /// In en, this message translates to:
  /// **'Available when your +{percent}% ends'**
  String boostWaitsFor(int percent);

  /// No description provided for @boostNoneActive.
  ///
  /// In en, this message translates to:
  /// **'No boost running'**
  String get boostNoneActive;

  /// No description provided for @boostNoneActiveBody.
  ///
  /// In en, this message translates to:
  /// **'Activate one to win more from every money match.'**
  String get boostNoneActiveBody;

  /// No description provided for @boostInventoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No boosts waiting. Your daily streak hands them out.'**
  String get boostInventoryEmpty;

  /// No description provided for @boostStarted.
  ///
  /// In en, this message translates to:
  /// **'+{percent}% boost is on!'**
  String boostStarted(int percent);

  /// No description provided for @boostExtended.
  ///
  /// In en, this message translates to:
  /// **'Boost extended by {time}'**
  String boostExtended(String time);

  /// No description provided for @boostActivateFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t activate the boost. Try again.'**
  String get boostActivateFailed;

  /// No description provided for @boostActivateNow.
  ///
  /// In en, this message translates to:
  /// **'Activate now'**
  String get boostActivateNow;

  /// No description provided for @boostInYourBoosts.
  ///
  /// In en, this message translates to:
  /// **'Saved to your boosts'**
  String get boostInYourBoosts;

  /// No description provided for @boostUpTo.
  ///
  /// In en, this message translates to:
  /// **'up to +{amount}'**
  String boostUpTo(String amount);

  /// No description provided for @boostPayout.
  ///
  /// In en, this message translates to:
  /// **'Boost +{percent}%'**
  String boostPayout(int percent);

  /// No description provided for @boostMoneyOnly.
  ///
  /// In en, this message translates to:
  /// **'Money matches only'**
  String get boostMoneyOnly;

  /// No description provided for @boostActiveSemantics.
  ///
  /// In en, this message translates to:
  /// **'Coin Boost +{percent}% active, {time} left'**
  String boostActiveSemantics(int percent, String time);

  /// No description provided for @boostOneAtATime.
  ///
  /// In en, this message translates to:
  /// **'One boost value runs at a time. The same value adds its time.'**
  String get boostOneAtATime;

  /// No description provided for @shopBadgeNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get shopBadgeNew;

  /// No description provided for @shopBadgeHot.
  ///
  /// In en, this message translates to:
  /// **'Hot'**
  String get shopBadgeHot;

  /// No description provided for @shopBadgePopular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get shopBadgePopular;

  /// No description provided for @shopBadgeBestValue.
  ///
  /// In en, this message translates to:
  /// **'Best value'**
  String get shopBadgeBestValue;

  /// No description provided for @shopBadgeLimited.
  ///
  /// In en, this message translates to:
  /// **'Limited'**
  String get shopBadgeLimited;

  /// No description provided for @shopFeatured.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get shopFeatured;

  /// No description provided for @shopSaleOff.
  ///
  /// In en, this message translates to:
  /// **'−{percent}%'**
  String shopSaleOff(int percent);

  /// No description provided for @shopEndsIn.
  ///
  /// In en, this message translates to:
  /// **'Ends in {time}'**
  String shopEndsIn(String time);

  /// No description provided for @shopPackBonus.
  ///
  /// In en, this message translates to:
  /// **'+{amount} bonus'**
  String shopPackBonus(int amount);

  /// No description provided for @shopPriceChanged.
  ///
  /// In en, this message translates to:
  /// **'Prices just changed. Check the new price and try again.'**
  String get shopPriceChanged;

  /// No description provided for @shopOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get shopOpen;

  /// No description provided for @shopDaysHours.
  ///
  /// In en, this message translates to:
  /// **'{days}d {hours}h'**
  String shopDaysHours(int days, int hours);

  /// No description provided for @shopChipPack.
  ///
  /// In en, this message translates to:
  /// **'{amount, plural, =1{1 Chip} other{{amount} Chips}}'**
  String shopChipPack(int amount);

  /// No description provided for @shopCashPack.
  ///
  /// In en, this message translates to:
  /// **'{amount, plural, =1{1 Cash} other{{amount} Cash}}'**
  String shopCashPack(int amount);
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
