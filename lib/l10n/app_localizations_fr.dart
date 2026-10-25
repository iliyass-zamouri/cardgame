// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'ShadowHand';

  @override
  String authError(String error) {
    return 'Erreur d\'auth : $error';
  }

  @override
  String get signInToPlay => 'Connectez-vous pour jouer en ligne';

  @override
  String get continueWithGoogle => 'Continuer avec Google';

  @override
  String get continueWithApple => 'Continuer avec Apple';

  @override
  String get signingIn => 'Connexion…';

  @override
  String get playAsGuest => 'Jouer en invité';

  @override
  String get entering => 'Entrée…';

  @override
  String get guestSignInServerDown =>
      'Échec de la connexion invité. Le serveur tourne-t-il ?';

  @override
  String get guestSignInConnection =>
      'Échec de la connexion invité. Vérifiez la connexion.';

  @override
  String get googleSignInFailed => 'Échec de la connexion Google. Réessayez.';

  @override
  String get appleSignInFailed => 'Échec de la connexion Apple. Réessayez.';

  @override
  String get tagline => 'Deux joueurs. Une table.';

  @override
  String get findMatch => 'Trouver une partie';

  @override
  String get createRoom => 'Créer une salle';

  @override
  String get joinRoom => 'Rejoindre';

  @override
  String get playVsRobot => 'Entraînement vs Robot';

  @override
  String get robotName => 'Robot';

  @override
  String get retryConnection => 'Réessayer la connexion';

  @override
  String get howToPlay => 'Comment jouer';

  @override
  String get home => 'Accueil';

  @override
  String get shop => 'Boutique';

  @override
  String get collection => 'Collection';

  @override
  String get collectionCards => 'Cartes';

  @override
  String get collectionAvatars => 'Avatars';

  @override
  String ownedCount(int owned, int total) {
    return '$owned/$total possédés';
  }

  @override
  String get getMoreInShop => 'Plus dans la Boutique';

  @override
  String get deck => 'Jeu';

  @override
  String get settings => 'Réglages';

  @override
  String get language => 'Langue';

  @override
  String get changeLanguage => 'Changer de langue';

  @override
  String get signOut => 'Déconnexion';

  @override
  String get guest => 'Invité';

  @override
  String get google => 'Google';

  @override
  String get apple => 'Apple';

  @override
  String get player => 'Joueur';

  @override
  String get online => 'En ligne';

  @override
  String get connecting => 'Connexion';

  @override
  String get offline => 'Hors ligne';

  @override
  String get joinRoomTitle => 'Rejoindre une salle';

  @override
  String get joinRoomHint => 'Entrez le code à 6 lettres de votre ami.';

  @override
  String get codeHint => 'CODE';

  @override
  String get cancel => 'Annuler';

  @override
  String get join => 'Rejoindre';

  @override
  String get findingOpponent => 'Recherche d\'adversaire';

  @override
  String get matchmakingHint => 'Patience — appariement avec un joueur.';

  @override
  String get privateTable => 'Table privée';

  @override
  String get shareCodeWithFriend => 'Partagez ce code avec un ami';

  @override
  String waitingForOpponentNamed(String name) {
    return 'En attente de $name…';
  }

  @override
  String opponentIsReady(String name) {
    return '$name est prêt';
  }

  @override
  String get bothPlayersJoined => 'Les deux joueurs sont là';

  @override
  String get codeCopied => 'Code copié';

  @override
  String get tapToCopy => 'Appuyez pour copier';

  @override
  String get ready => 'Prêt';

  @override
  String get waitingEllipsis => 'En attente…';

  @override
  String get leaveRoom => 'Quitter la salle';

  @override
  String get vs => 'VS';

  @override
  String get you => 'Vous';

  @override
  String get notReady => 'Pas prêt';

  @override
  String get waitingEllipsisShort => 'En attente…';

  @override
  String get endGame => 'Finir la partie';

  @override
  String get menu => 'Menu';

  @override
  String get endGameTitle => 'Finir la partie ?';

  @override
  String get endGameMessage =>
      'Les cartes sont révélées et les scores comptés.';

  @override
  String get reveal => 'Révéler';

  @override
  String get peek => 'Voir';

  @override
  String get shuffle => 'Mélanger';

  @override
  String get replace => 'Échanger';

  @override
  String get waitingOpponentReveal =>
      'En attente que l\'adversaire voie ses cartes…';

  @override
  String get gameOver => 'Partie terminée';

  @override
  String get victory => 'Victoire';

  @override
  String get defeat => 'Défaite';

  @override
  String get draw => 'Égalité';

  @override
  String seriesScore(int yours, int theirs) {
    return 'SÉRIE  $yours – $theirs';
  }

  @override
  String get opponent => 'Adversaire';

  @override
  String get waitingRematch => 'En attente d\'une revanche…';

  @override
  String opponentAskingRematch(String name) {
    return '$name demande une revanche';
  }

  @override
  String get leave => 'Quitter';

  @override
  String get rematch => 'Revanche';

  @override
  String get points => 'pts';

  @override
  String get roomInfo => 'Info salle';

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
    return 'Salle $roomId · $turn';
  }

  @override
  String roomToast(String roomId) {
    return 'Salle $roomId';
  }

  @override
  String get yourTurn => 'Votre tour';

  @override
  String get opponentTurn => 'Tour adverse';

  @override
  String get leaveRoomTitle => 'Quitter la salle ?';

  @override
  String get leaveRoomMessage => 'Vous quitterez cette partie.';

  @override
  String stepOf(int current, int total) {
    return 'Étape $current sur $total';
  }

  @override
  String get back => 'Retour';

  @override
  String get next => 'Suivant';

  @override
  String get gotIt => 'Compris';

  @override
  String get ruleGoalTitle => 'Objectif';

  @override
  String get ruleGoalBody =>
      'Termine avec le total le plus bas. La partie s\'arrête quand un joueur n\'a plus de cartes ou que quelqu\'un touche Finir la partie.';

  @override
  String get ruleSetupTitle => 'Mise en place';

  @override
  String get ruleSetupBody =>
      'Deux joueurs. Chacun reçoit quatre cartes face cachée, en ligne.';

  @override
  String get ruleOpeningPeekTitle => 'Aperçu initial';

  @override
  String get ruleOpeningPeekBody =>
      'Avant de jouer, touche Révéler pour voir tes deux cartes de gauche quelques secondes. Retiens-les — puis elles se retournent.';

  @override
  String get ruleYourTurnTitle => 'Votre tour';

  @override
  String get ruleYourTurnBody =>
      'Avant de piocher, si le haut de la défausse correspond à une carte que tu connais, touche-la pour la défausser (ton tour continue). Erreur = carte de pénalité. Puis pioche.';

  @override
  String get ruleAfterDrawTitle => 'Après la pioche';

  @override
  String get ruleAfterDrawBody =>
      'Touche une de tes cartes pour échanger (rang différent) ou double-défausser (même rang), ou touche la carte piochée pour la jeter. Ton tour se termine.';

  @override
  String get ruleSpecialTitle => 'Cartes spéciales';

  @override
  String get ruleSpecialBody =>
      'Quand tu pioches ces cartes, tu peux utiliser leur pouvoir. Ensuite, la carte est jetée.';

  @override
  String get ruleJackLabel => 'Valet';

  @override
  String get ruleJackDesc =>
      'Regardez une carte — la vôtre ou la sienne — puis le Valet est jeté.';

  @override
  String get ruleQueenLabel => 'Dame';

  @override
  String get ruleQueenDesc =>
      'Mélangez une main, ou échangez une des vôtres avec une des siennes, puis la Dame est jetée.';

  @override
  String get ruleScoringTitle => 'Score';

  @override
  String get ruleScoringBody =>
      'Quand un joueur n\'a plus de cartes ou que quelqu\'un touche Finir la partie, toutes les cartes sont révélées et additionnées. As = 1, Valet = 11, Dame = 12. Le plus bas gagne ; égalité possible.';

  @override
  String get ruleJokerLabel => 'Joker';

  @override
  String get ruleJokerDesc => 'Compte pour −1 point.';

  @override
  String get ruleBlackKingLabel => 'Roi noir';

  @override
  String get ruleBlackKingDesc =>
      'Roi de trèfle ou pique = 0. Les rois rouges comptent 13.';

  @override
  String get hintPeek => 'Touchez une carte pour voir…';

  @override
  String get hintShufflePick => 'Touchez Mélanger au-dessus d\'une main…';

  @override
  String get hintReplaceFirst => 'Touchez une carte de chaque main…';

  @override
  String get hintReplaceSecond => 'Touchez une carte de l\'autre main…';

  @override
  String get errConnectionLost => 'Connexion perdue';

  @override
  String get errEnterRoomCode => 'Entrez un code de salle';

  @override
  String get errServerNotConnected => 'Serveur non connecté';

  @override
  String get errCommandFailed => 'Commande échouée';

  @override
  String get errRoomFull => 'La salle a déjà deux joueurs';

  @override
  String get errWaitingForPlayer => 'Deux joueurs requis';

  @override
  String get errAlreadyStarted => 'Partie déjà commencée';

  @override
  String get errNotEnded => 'La partie n\'est pas terminée';

  @override
  String get errAlreadyLaunched => 'Cartes déjà révélées';

  @override
  String get errAlreadyDrew => 'Jetez ou échangez d\'abord la carte piochée';

  @override
  String get errDeckEmpty => 'Aucune carte disponible';

  @override
  String get errNoJack => 'Voir nécessite un Valet pioché';

  @override
  String get errPeekUsed => 'Aperçu Valet déjà utilisé';

  @override
  String get errInvalidSide => 'Côté invalide';

  @override
  String get errInvalidCard => 'Index de carte invalide';

  @override
  String get errCannotShuffle => 'Pas assez de cartes à mélanger';

  @override
  String get errDrawFirst => 'Piochez d\'abord une carte';

  @override
  String get errNoHandCard => 'Piochez d\'abord une carte';

  @override
  String get errNotInRoom => 'Rejoignez d\'abord une salle';

  @override
  String get errNotYourTurn => 'Ce n\'est pas votre tour';

  @override
  String get errRevealFirst => 'Les deux joueurs doivent d\'abord révéler';

  @override
  String get errNotPlaying => 'La partie n\'est pas en cours';

  @override
  String get errPeekInProgress => 'Attendez la fin de l\'aperçu';

  @override
  String get errQueenInProgress => 'Attendez la fin de la capacité Dame';

  @override
  String get errNoQueen => 'La capacité Dame nécessite une Dame piochée';

  @override
  String get errQueenUsed => 'Capacité Dame déjà utilisée';

  @override
  String get errInvalidCommand => 'Type de commande requis';

  @override
  String get errRoomNotFound => 'Salle introuvable';

  @override
  String get errUnknownCommand => 'Commande inconnue';

  @override
  String get errTooManyCommands => 'Trop de commandes';

  @override
  String get globalRanking => 'Classement mondial';

  @override
  String get marketplace => 'Marché';

  @override
  String get comingSoon => 'Bientôt disponible';

  @override
  String get marketplaceComingSoonBody =>
      'Les skins de cartes et extras arriveront ici.';

  @override
  String get leaderboard => 'Classement';

  @override
  String get matchHistory => 'Historique';

  @override
  String get elo => 'Elo';

  @override
  String get colWins => 'V';

  @override
  String get colLosses => 'D';

  @override
  String get colDraws => 'N';

  @override
  String get rankingEmpty =>
      'Aucun joueur classé. Jouez une partie aléatoire !';

  @override
  String get matchHistoryEmpty => 'Aucune partie classée pour l\'instant.';

  @override
  String get rankingLoadError =>
      'Impossible de charger le classement. Le serveur tourne-t-il ?';

  @override
  String get matchResultWin => 'VICTOIRE';

  @override
  String get matchResultLoss => 'DÉFAITE';

  @override
  String get matchResultDraw => 'ÉGALITÉ';

  @override
  String recordWinsLossesDraws(int wins, int losses, int draws) {
    return '${wins}V · ${losses}D · ${draws}N';
  }

  @override
  String matchScoreLine(int myScore, int oppScore) {
    return 'Vous $myScore · Adv $oppScore';
  }

  @override
  String get friends => 'Amis';

  @override
  String get friendsComingSoonBody =>
      'Connectez-vous avec vos amis et invitez-les bientôt à des parties.';

  @override
  String get requests => 'Demandes';

  @override
  String get addFriend => 'Ajouter un ami';

  @override
  String get searchByUsername => 'Rechercher par @pseudo ou nom...';

  @override
  String get noFriendsYet => 'Aucun ami pour le moment.';

  @override
  String get noFriendsHint =>
      'Recherchez des pseudos dans l\'onglet Ajouter pour vous connecter !';

  @override
  String get noRequests => 'Aucune demande d\'ami en attente.';

  @override
  String get incomingRequests => 'Demandes reçues';

  @override
  String get outgoingRequests => 'Demandes envoyées';

  @override
  String get accept => 'Accepter';

  @override
  String get decline => 'Refuser';

  @override
  String get removeFriend => 'Supprimer l\'ami';

  @override
  String removeFriendConfirm(String name) {
    return 'Êtes-vous sûr de vouloir supprimer $name de vos amis ?';
  }

  @override
  String get friendRequestSent => 'Demande d\'ami envoyée !';

  @override
  String get friendRequestAccepted => 'Demande d\'ami acceptée !';

  @override
  String friendRequestFrom(String name) {
    return '$name vous a envoyé une demande d\'ami';
  }

  @override
  String friendRequestAcceptedBy(String name) {
    return '$name a accepté votre demande d\'ami';
  }

  @override
  String get friendRemoved => 'Ami supprimé.';

  @override
  String get requestSent => 'Envoyée';

  @override
  String get youTag => 'Vous';

  @override
  String get alreadyFriends => 'Amis';

  @override
  String get changeUsername => 'Modifier le pseudo';

  @override
  String get usernameHint => 'pseudo_unique';

  @override
  String get usernameAvailable => 'Le pseudo est disponible';

  @override
  String get usernameTaken => 'Ce pseudo est déjà pris';

  @override
  String get usernameInvalidFormat =>
      '3-20 caractères : minuscules, chiffres, _';

  @override
  String get save => 'Enregistrer';

  @override
  String get displayName => 'Nom affiché';

  @override
  String get editProfile => 'Modifier le profil';

  @override
  String get profileUpdated => 'Profil mis à jour avec succès !';

  @override
  String get searching => 'Recherche en cours...';

  @override
  String get noPlayersFound =>
      'Aucun joueur trouvé correspondant à la recherche.';

  @override
  String get profile => 'Profil';

  @override
  String level(int lvl) {
    return 'Niveau $lvl';
  }

  @override
  String levelNumber(int lvl) {
    return 'Niveau $lvl';
  }

  @override
  String get xp => 'XP';

  @override
  String get winRate => 'Taux de Victoire';

  @override
  String get matchesPlayed => 'Parties';

  @override
  String get totalXp => 'XP Total';

  @override
  String get copiedToClipboard => 'Copié dans le presse-papiers';

  @override
  String get rankTitleNovice => 'Novice';

  @override
  String get rankTitleCardShark => 'Requin des Cartes';

  @override
  String get rankTitleHighRoller => 'Grand Joueur';

  @override
  String get rankTitleTableMaster => 'Maître de Table';

  @override
  String get rankTitleGrandAce => 'Grand As';

  @override
  String get rankTitleShadowLegend => 'Légende de l\'Ombre';

  @override
  String get inviteFriends => 'Inviter des amis';

  @override
  String get invite => 'Inviter';

  @override
  String get invited => 'Invité';

  @override
  String get inviteSent => 'Invitation envoyée !';

  @override
  String tableInviteFrom(String name, String code) {
    return '$name vous a invité à la table privée $code';
  }

  @override
  String get joinTable => 'Rejoindre la table';

  @override
  String get ignore => 'Ignorer';

  @override
  String get noFriendsToInvite => 'Aucun ami ajouté pour l\'instant à inviter.';

  @override
  String get customizeAvatar => 'Personnaliser l\'avatar';

  @override
  String get locked => 'Verrouillé';

  @override
  String get equipped => 'Équipé';

  @override
  String get equip => 'Équiper';

  @override
  String unlockAtLevel(int lvl) {
    return 'Débloqué au niveau $lvl';
  }

  @override
  String get defaultAvatar => 'Par défaut';

  @override
  String get blueAvatar => 'Saphir';

  @override
  String get redAvatar => 'Rubis';

  @override
  String get bronzeAvatar => 'Bronze';

  @override
  String get silverAvatar => 'Argent';

  @override
  String get jokerGirlAvatar => 'Joker Girl';

  @override
  String get violetJokerGirlAvatar => 'Joker Violet';

  @override
  String get violetQueenAvatar => 'Reine Violette';

  @override
  String get queenOfHeartAvatar => 'Reine de Cœur';

  @override
  String get goldenKingAvatar => 'Roi Doré';

  @override
  String get queenAvatar => 'Reine';

  @override
  String get kingAvatar => 'Roi';

  @override
  String get money => 'Argent';

  @override
  String get chips => 'Jetons';

  @override
  String get exchange => 'Échange';

  @override
  String get avatarShop => 'Avatars';

  @override
  String get deckShop => 'Cartes';

  @override
  String get selectMatchStake => 'Choisir la mise';

  @override
  String get stake => 'Mise';

  @override
  String get pot => 'Cagnotte';

  @override
  String get winnerTakesAll => 'Le gagnant rafle tout';

  @override
  String get getMoreMoney => 'Obtenir de l\'argent';

  @override
  String get insufficientChips => 'Pas assez de jetons';

  @override
  String get insufficientMoney => 'Pas assez d\'argent';

  @override
  String get exchangedSuccess => 'Échange réussi';

  @override
  String get exchangeFailed => 'Échec de l\'échange';

  @override
  String get watchAdForMoney => 'Regarder une vidéo';

  @override
  String get freeStashBonus => 'Bonus d\'argent gratuit';

  @override
  String get adRewardEarned => 'Récompense obtenue !';

  @override
  String get adNotAvailable => 'Publicité non disponible';

  @override
  String get chipsToMoney => 'Convertir Jetons en Argent';

  @override
  String get moneyToChips => 'Convertir Argent en Jetons';

  @override
  String get convert => 'Convertir';

  @override
  String get claim => 'Réclamer';

  @override
  String get buy => 'Acheter';

  @override
  String get owned => 'Possédé';

  @override
  String get unlocked => 'Débloqué';

  @override
  String get purchaseFailed => 'Échec de l\'achat';

  @override
  String get classicDeck => 'Bleu Classique';

  @override
  String get classicDeckDesc => 'Cartes standard de casino';

  @override
  String get onyxBlackDeck => 'Onyx Noir';

  @override
  String get onyxBlackDeckDesc => 'Dos obsidienne à filigrane doré';

  @override
  String get sapphireFrostDeck => 'Dragon de Saphir';

  @override
  String get sapphireFrostDeckDesc =>
      'Entrelacs celtiques saphir et or autour de deux dragons';

  @override
  String get imperialJadeDeck => 'Haut Victorien';

  @override
  String get imperialJadeDeckDesc =>
      'Filigrane émeraude dans un cadre victorien doré';

  @override
  String get royalCrimsonDeck => 'Pourpre Royal';

  @override
  String get royalCrimsonDeckDesc =>
      'Filigrane doré et figure couronnée sur cramoisi';

  @override
  String get neonNightsDeck => 'Nuits Néon';

  @override
  String get neonNightsDeckDesc =>
      'Un coucher de soleil synthwave sur une grille néon';

  @override
  String get gildedDeck => 'Or 24 carats';

  @override
  String get gildedDeckDesc => 'Or massif gravé et diamant taille brillant';

  @override
  String get rarityRare => 'Rare';

  @override
  String get rarityEpic => 'Épique';

  @override
  String get rarityLegendary => 'Légendaire';

  @override
  String get price => 'Prix';

  @override
  String get play => 'Jouer';

  @override
  String get cityLondon => 'Londres';

  @override
  String get cityParis => 'Paris';

  @override
  String get cityMoscow => 'Moscou';

  @override
  String get cityCairo => 'Le Caire';

  @override
  String get cityMarrakech => 'Marrakech';

  @override
  String get cityToronto => 'Toronto';

  @override
  String get cityNewYork => 'New York';

  @override
  String get cityTokyo => 'Tokyo';

  @override
  String get prize => 'Prix';

  @override
  String get entryFee => 'Frais d\'entrée';

  @override
  String get linkGoogleAccount => 'Lier un compte Google';

  @override
  String get linkingGoogle => 'Liaison…';

  @override
  String get linkAppleAccount => 'Lier un compte Apple';

  @override
  String get linkGoogleSuccess => 'Compte Google lié. Progression enregistrée.';

  @override
  String get linkGoogleSwitched => 'Connecté avec votre compte Google.';

  @override
  String get linkAppleSuccess => 'Compte Apple lié. Progression enregistrée.';

  @override
  String get linkAppleSwitched => 'Connecté avec votre compte Apple.';

  @override
  String get saveProgressTitle => 'Sauvegardez votre progression';

  @override
  String get saveProgressBody =>
      'Liez un compte Google pour conserver argent, jetons et classement si vous changez d\'appareil.';

  @override
  String get saveProgressBodyIos =>
      'Liez un compte Apple ou Google pour conserver argent, jetons et classement si vous changez d\'appareil.';

  @override
  String get googleAccountInUseTitle => 'Compte Google déjà utilisé';

  @override
  String get appleAccountInUseTitle => 'Compte Apple déjà utilisé';

  @override
  String googleAccountInUseBody(String username) {
    return 'Ce compte Google appartient déjà à @$username. Passer à ce compte ? La progression invité sur cet appareil sera perdue.';
  }

  @override
  String appleAccountInUseBody(String username) {
    return 'Ce compte Apple appartient déjà à @$username. Passer à ce compte ? La progression invité sur cet appareil sera perdue.';
  }

  @override
  String get switchToGoogleAccount => 'Changer de compte';

  @override
  String get dontAskAgain => 'Ne plus demander';

  @override
  String get later => 'Plus tard';

  @override
  String get youQuit => 'Vous avez abandonné';

  @override
  String get opponentQuit => 'L\'adversaire a abandonné';

  @override
  String get turnTimedOut =>
      'Temps écoulé : votre tour a été joué automatiquement.';

  @override
  String turnTimedOutWarning(int remaining) {
    return 'Temps écoulé : votre tour a été joué automatiquement. Tours restants avant forfait : $remaining.';
  }

  @override
  String get youTimedOut => 'Temps écoulé pour vous';

  @override
  String get opponentTimedOut => 'Temps écoulé pour l\'adversaire';

  @override
  String get matchResultQuit => 'ABANDON';

  @override
  String get leaveMatchPenaltyMessage =>
      'Partir maintenant compte comme une défaite : vous perdrez votre mise et 15 points.';

  @override
  String get notEnoughMoneyTitle => 'Pas assez d\'argent';

  @override
  String notEnoughMoneyMessage(int required, int money) {
    return 'La mise est de $required mais vous avez $money. Échangez des jetons ou achetez-en pour rejouer.';
  }

  @override
  String get stakeCovered => 'C\'est couvert — prêt pour la revanche.';

  @override
  String get exchangeChips => 'Échanger des jetons';

  @override
  String get buyMoney => 'Acheter de l\'argent';

  @override
  String get rematchStarting => 'Prélèvement des mises…';

  @override
  String opponentCantAffordRematch(String name) {
    return '$name ne peut pas couvrir la mise';
  }

  @override
  String get offlineReconnecting => 'Hors ligne · reconnexion…';

  @override
  String get getMoreChips => 'Obtenir des jetons';

  @override
  String get notEnoughChipsTitle => 'Pas assez de jetons';

  @override
  String notEnoughChipsMessage(int required, int chips) {
    return 'La mise est de $required jetons mais vous avez $chips. Achetez des jetons pour rejouer.';
  }

  @override
  String get buyChips => 'Acheter des jetons';

  @override
  String get tutLessonValuesTitle => 'But & valeur des cartes';

  @override
  String get tutLessonDealTitle => 'La donne & premier coup d\'œil';

  @override
  String get tutLessonSwapTitle => 'Piocher & échanger';

  @override
  String get tutLessonThrowTitle => 'Jeter une carte';

  @override
  String get tutLessonDoubleTitle => 'Double défausse';

  @override
  String get tutLessonMatchTitle => 'Égaler la défausse';

  @override
  String get tutLessonJackTitle => 'Valet : regarder';

  @override
  String get tutLessonQueenTitle => 'Dame : échanger ou mélanger';

  @override
  String get tutLessonEndTitle => 'Fin & score';

  @override
  String get tutLessonTipsTitle => 'Astuces pour gagner';

  @override
  String get tutValuesIntro =>
      'ShadowHand est un jeu de mémoire à deux. Chaque joueur a des cartes face cachée. À la fin de la partie, chacun additionne ses cartes — le total le plus bas gagne.';

  @override
  String get tutValuesChart =>
      'Chaque carte vaut des points. As = 1, cartes numérotées = leur valeur, Valet = 11, Dame = 12, Roi rouge = 13. Les meilleures : un Roi noir vaut 0 et un Joker vaut −1 !';

  @override
  String get tutValuesQuizLowest =>
      'Petit quiz : touche la carte qui vaut le moins de points.';

  @override
  String get tutValuesQuizLowestWrong =>
      'Pas tout à fait. Le Joker vaut −1 — encore moins qu\'un As.';

  @override
  String get tutValuesQuizKing =>
      'Voici deux Rois. Touche celui qui vaut 0 point.';

  @override
  String get tutValuesQuizKingWrong =>
      'Seuls les Rois noirs (♠ ♣) valent 0. Les Rois rouges (♥ ♦) valent 13 — la pire carte du jeu !';

  @override
  String get tutValuesDone =>
      'Parfait ! Ton objectif : garder les petites cartes et te débarrasser des grosses.';

  @override
  String get tutDealIntro =>
      'Chaque joueur reçoit 4 cartes face cachée, en ligne. Tu ne sais pas encore ce qu\'elles sont — ton adversaire non plus.';

  @override
  String get tutDealReveal =>
      'Avant de jouer, tu as droit à un coup d\'œil. Touche Révéler.';

  @override
  String get tutDealMemorize =>
      'Tes deux cartes de gauche sont visibles quelques secondes. Retiens-les : un 2 et un 8 !';

  @override
  String get tutDealQuiz =>
      'Elles sont de nouveau cachées. Où est ton 2 ? Touche-le.';

  @override
  String get tutDealQuizWrong =>
      'Le 2 était ta première carte, tout à gauche. Dans ce jeu, la mémoire est tout !';

  @override
  String get tutDealDone =>
      'Exact ! Tes deux autres cartes restent un mystère — tu en apprendras plus en jouant.';

  @override
  String get tutDrawPrompt =>
      'C\'est ton tour. Touche la pioche pour piocher une carte.';

  @override
  String get tutSwapIntro =>
      'Tu te souviens de tes deux premières cartes : un 2 et un 9. Un 9 coûte cher — remplaçons-le.';

  @override
  String get tutSwapPick =>
      'Tu as pioché un 3. C\'est mieux que ton 9 ! Touche ton 9 (deuxième carte) pour les échanger.';

  @override
  String get tutSwapPickWrong =>
      'Touche ton 9 — la deuxième carte en partant de la gauche. Échanger une carte inconnue, c\'est un pari.';

  @override
  String get tutSwapDone =>
      'Le 3 prend la place du 9, face cachée, et le 9 part à la défausse. Ton tour est terminé — et tu viens d\'économiser 6 points.';

  @override
  String get tutThrowPick =>
      'Aïe — un Roi rouge, qui vaut 13. Tu n\'en veux pas ! Touche la carte piochée pour la jeter sur la défausse.';

  @override
  String get tutThrowWrong =>
      'Ne garde pas une mauvaise carte. Touche la carte piochée (en bas à gauche) pour la jeter.';

  @override
  String get tutThrowDone =>
      'Jetée ! Tes cartes n\'ont pas changé et ton tour est fini. Jette toute carte qui n\'améliorerait pas ta main.';

  @override
  String get tutDoubleIntro => 'Tu te souviens que ta première carte est un 5.';

  @override
  String get tutDoublePick =>
      'Encore un 5 ! Quand la carte piochée a le même rang qu\'une des tiennes, touche ta carte : les deux sont défaussées.';

  @override
  String get tutDoubleWrong => 'Touche ton 5 — la première carte à gauche.';

  @override
  String get tutDoubleDone =>
      'Les deux 5 sont partis et tu as une carte de moins. Moins de cartes, moins de points — et si tu n\'as plus de cartes, la partie s\'arrête.';

  @override
  String get tutMatchIntro =>
      'Tu te souviens que ta première carte est un 7. C\'est maintenant au tour de ton adversaire…';

  @override
  String get tutMatchPick =>
      'Ton adversaire a jeté un 7 ! À ton tour, avant de piocher, tu peux toucher une carte du même rang que le haut de la défausse pour t\'en débarrasser. Touche ton 7.';

  @override
  String get tutMatchWrong => 'Touche ton 7 — la première carte à gauche.';

  @override
  String get tutMatchContinue =>
      'Défausse gratuite ! Égaler ne termine pas ton tour : tu peux recommencer, puis tu pioches quand même. Touche la pioche.';

  @override
  String get tutMatchThrow =>
      'Un 8 — pas terrible. Touche-le pour le jeter et finir ton tour.';

  @override
  String get tutMatchGuess =>
      'Au tour suivant, la défausse montre un 4. Tu penses que ta carte du milieu est peut-être un 4… sans en être sûr. Voyons ce qui se passe en cas d\'erreur : touche-la.';

  @override
  String get tutMatchPenalty =>
      'Raté — ce n\'était pas un 4. Tu reçois une carte de pénalité face cachée, et la carte touchée reste. N\'égale que si tu es sûr !';

  @override
  String get tutJackPeekButton =>
      'Un Valet ! Quand tu pioches un Valet, tu peux regarder une carte — la tienne ou celle de ton adversaire. Touche Voir.';

  @override
  String get tutJackPick =>
      'Touche maintenant la carte à voir. Espionnons la deuxième carte de ton adversaire.';

  @override
  String get tutJackPickWrong =>
      'Touche la deuxième carte de ton adversaire en partant de la gauche.';

  @override
  String get tutJackReveal =>
      'C\'est une Dame — 12 points pour lui. Retiens sa place : elle se cache dans un instant.';

  @override
  String get tutJackDone =>
      'Après le coup d\'œil, le Valet est jeté automatiquement et ton tour se termine. Le pouvoir est facultatif : tu peux aussi garder ou jeter un Valet comme une autre carte.';

  @override
  String get tutQueenIntro =>
      'Tu te souviens que ta deuxième carte est un 10. Donnons-le à ton adversaire.';

  @override
  String get tutQueenButtons =>
      'Une Dame ! Tu as le choix. Mélanger mélange les cartes d\'un joueur. Échanger troque une de tes cartes contre une des siennes. Touche Échanger.';

  @override
  String get tutQueenButtonsWrong => 'Pour cette leçon, touche Échanger.';

  @override
  String get tutQueenPickYours =>
      'Touche d\'abord la carte à donner : ton 10, la deuxième carte.';

  @override
  String get tutQueenPickYoursWrong =>
      'Touche ton 10 — ta deuxième carte en partant de la gauche.';

  @override
  String get tutQueenPickTheirs =>
      'Touche maintenant la carte adverse à prendre : sa première carte.';

  @override
  String get tutQueenPickTheirsWrong =>
      'Touche la première carte de ton adversaire, à gauche.';

  @override
  String get tutQueenDone =>
      'Échangé ! Ton 10 appartient maintenant à ton adversaire. Tu ne vois pas la carte reçue, mais la plupart valent moins de 10 — bonne affaire. La Dame est jetée après usage.';

  @override
  String get tutQueenShuffle =>
      'Mélanger est l\'autre option : mélange les cartes de ton adversaire et tout ce qu\'il avait retenu ne sert plus à rien. Tu peux aussi mélanger les tiennes.';

  @override
  String get tutEndIntro =>
      'La partie se termine de deux façons : un joueur n\'a plus de cartes, ou quelqu\'un touche Finir la partie.';

  @override
  String get tutEndPress =>
      'Tu penses avoir le total le plus bas ? Chaque joueur peut toucher Finir la partie à tout moment. Essaie.';

  @override
  String get tutEndCount =>
      'Toutes les cartes sont révélées. Additionne les tiennes : 3 + 2 + Roi noir + Joker. Quel est ton total ?';

  @override
  String get tutEndCountWrong =>
      'Rappel : un Roi noir vaut 0 et un Joker −1. Donc 3 + 2 + 0 − 1 = 4.';

  @override
  String get tutEndWinner => 'Ton adversaire a 9 + 5 + 7 + 1 = 22. Qui gagne ?';

  @override
  String get tutEndWinnerWrong => 'Le total le plus bas gagne : 4 bat 22.';

  @override
  String get tutEndDone =>
      'Tu gagnes ! Si les deux totaux sont égaux, c\'est une égalité.';

  @override
  String get tutTipMemory =>
      'Astuce 1 — Retiens tout. Chaque carte vue — au départ, en échangeant, avec un Valet — t\'apprend quelque chose. Garde-la en tête.';

  @override
  String get tutTipKeepLow =>
      'Astuce 2 — Garde les Rois noirs et les Jokers. Ils valent 0 et −1 : ne les échange jamais.';

  @override
  String get tutTipDiscard =>
      'Astuce 3 — Surveille la défausse. Chaque carte jetée par ton adversaire est une chance d\'égaler gratuitement.';

  @override
  String get tutTipQueen =>
      'Astuce 4 — Utilise bien les Dames. Donne ta plus grosse carte, ou Mélange pour ruiner la mémoire de ton adversaire.';

  @override
  String get tutTipEnd =>
      'Astuce 5 — Termine au bon moment. Si tu penses avoir le total le plus bas, touche Finir la partie avant que ton adversaire ne te rattrape.';

  @override
  String get tutChoiceYou => 'Toi';

  @override
  String get tutChoiceOpponent => 'Adversaire';

  @override
  String get tutChoiceTie => 'Égalité';

  @override
  String get tutDeckLabel => 'Pioche';

  @override
  String get tutDiscardLabel => 'Défausse';

  @override
  String get tutDrawnLabel => 'Piochée';

  @override
  String get tutAceLabel => 'As';

  @override
  String get tutNumberCardsLabel => '2 à 10';

  @override
  String get tutRedKingLabel => 'Roi rouge';

  @override
  String get tutTapHighlighted =>
      'Touche l\'élément qui brille pour continuer.';

  @override
  String tutLessonProgress(int current, int total) {
    return 'Leçon $current sur $total';
  }

  @override
  String get tutSkip => 'Passer';

  @override
  String get tutLessonDone => 'Leçon terminée !';

  @override
  String get tutReplay => 'Rejouer';

  @override
  String get tutFinish => 'Terminer';

  @override
  String get tutNextLesson => 'Leçon suivante';

  @override
  String get tutCompleteTitle => 'Tu es prêt !';

  @override
  String get tutCompleteBody =>
      'Tu connais toutes les règles. Entraîne-toi contre le robot, puis affronte de vrais joueurs.';

  @override
  String get tutHubIntro =>
      'Apprends ShadowHand en jouant. Chaque courte leçon te met les cartes en main et t\'explique une règle.';

  @override
  String get tutStartAll => 'Commencer le tutoriel';

  @override
  String get tutContinue => 'Continuer le tutoriel';

  @override
  String get tutLessonsHeader => 'Leçons';

  @override
  String get tutQuickRules => 'Règles rapides';

  @override
  String get tutQuickRulesSubtitle => 'Toutes les règles en 7 cartes';

  @override
  String get tutPromptTitle => 'Nouveau sur ShadowHand ?';

  @override
  String get tutPromptBody =>
      'Apprends à jouer avec un tutoriel interactif. Ça prend environ 3 minutes.';

  @override
  String get tutPromptLater => 'Plus tard';

  @override
  String get chat => 'Chat';

  @override
  String get chatHint => 'Écris un message…';

  @override
  String get chatEmpty => 'Aucun message. Dis bonjour !';

  @override
  String get quickPhrases => 'Phrases rapides';

  @override
  String get phraseHello => 'Salut !';

  @override
  String get phraseGoodLuck => 'Bonne chance';

  @override
  String get phraseWellPlayed => 'Bien joué';

  @override
  String get phrasePlayFast => 'Joue vite !';

  @override
  String get phraseOops => 'Oups';

  @override
  String get phraseThanks => 'Merci';

  @override
  String get phraseUnlucky => 'Mauvaise pioche';

  @override
  String get phraseHehe => 'Héhé';

  @override
  String get phraseGg => 'GG';

  @override
  String get micOn => 'Micro activé';

  @override
  String get micOff => 'Micro coupé';

  @override
  String get micPermissionDenied =>
      'L\'accès au micro est désactivé. Autorise-le dans les réglages du téléphone pour parler.';

  @override
  String get voiceOpponentTalking => 'Voix active';

  @override
  String get muteOpponent => 'Couper le joueur';

  @override
  String get unmuteOpponent => 'Réactiver le joueur';

  @override
  String opponentMutedToast(String name) {
    return '$name est en sourdine';
  }

  @override
  String get reportPlayer => 'Signaler le joueur';

  @override
  String reportPlayerConfirm(String name) {
    return 'Signaler $name pour mauvais comportement ?';
  }

  @override
  String get reportedToast => 'Merci, nous allons examiner ce joueur';

  @override
  String get recentForm => 'Forme récente';

  @override
  String get noRecentMatches => 'Aucune partie';

  @override
  String get tableChatSettings => 'Chat de table';

  @override
  String get showOpponentChat => 'Afficher le chat adverse';

  @override
  String get voiceChatSetting => 'Chat vocal';

  @override
  String get errChatRateLimited =>
      'Doucement, tu envoies des messages trop vite';

  @override
  String get errChatInvalid => 'Le message n\'a pas pu être envoyé';

  @override
  String get phraseNiceSwap => 'Bel échange !';

  @override
  String get phraseSharpMemory => 'Quelle mémoire !';

  @override
  String get phraseStopPeeking => 'Arrête d\'espionner !';

  @override
  String get phraseGiveCardBack => 'Rends-moi ma carte !';

  @override
  String get phraseBlackKingPlease => 'Un Roi noir, pitié !';

  @override
  String get phraseLowTotal => 'Mon total est minuscule';

  @override
  String get phraseFoundJoker => 'J\'ai trouvé un Joker !';

  @override
  String get phraseKnowMyCards => 'Je connais toutes mes cartes';

  @override
  String get phraseEndingNextTurn => 'Je termine au prochain tour !';

  @override
  String get dailyStreakTitle => 'Série quotidienne';

  @override
  String dailyDay(int day) {
    return 'Jour $day';
  }

  @override
  String dailyDayOfWeek(int day) {
    return 'Jour $day sur 7';
  }

  @override
  String get dailyToday => 'Aujourd\'hui';

  @override
  String get dailyTomorrow => 'Demain';

  @override
  String get dailyJackpot => 'Jackpot';

  @override
  String dailyStreakCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Série de $count jours',
      one: 'Série de 1 jour',
      zero: 'Commencez votre série',
    );
    return '$_temp0';
  }

  @override
  String dailyBest(int best) {
    return 'Record $best';
  }

  @override
  String dailyNextIn(String time) {
    return 'Prochaine récompense dans $time';
  }

  @override
  String get dailyComeBackTomorrow => 'Revenez demain';

  @override
  String get dailyShortAd => 'Pub courte';

  @override
  String dailyBoostedBadge(int multiplier) {
    return 'Bonus pub ×$multiplier';
  }

  @override
  String get dailyStreakBrokenTitle => 'Votre série s\'est arrêtée';

  @override
  String dailyStreakBrokenBody(int day) {
    return 'Restaurez-la pour continuer au jour $day, ou recommencez une série au jour 1.';
  }

  @override
  String get dailyRestore => 'Restaurer';

  @override
  String get dailyStartOver => 'Recommencer';

  @override
  String get dailyGraceForgiven => 'Jour manqué pardonné';

  @override
  String get dailyFreezeSaves => 'Un Gel de série sauve votre série';

  @override
  String get dailyNewStreak => 'Une nouvelle série commence aujourd\'hui';

  @override
  String dailyEventEnds(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Se termine dans $days jours',
      one: 'Se termine demain',
      zero: 'Se termine aujourd\'hui',
    );
    return '$_temp0';
  }

  @override
  String get dailyCoinBoost => 'Boost de pièces';

  @override
  String dailyCoinBoostBody(int percent) {
    return '+$percent % d\'argent sur les victoires';
  }

  @override
  String get dailyStreakFreeze => 'Gel de série';

  @override
  String get dailyStreakFreezeBody =>
      'Sauve votre série si vous manquez un jour';

  @override
  String get dailyMysteryChest => 'Coffre mystère';

  @override
  String get dailyChestInside => 'Contenu possible';

  @override
  String get dailyChestNote =>
      'Une récompense, tirée au sort quand vous la réclamez.';

  @override
  String get dailyMysteryGift => 'Cadeau mystère';

  @override
  String get dailyNew => 'Nouveau !';

  @override
  String get dailyAlreadyOwned => 'Déjà possédé';

  @override
  String get dailyCollect => 'Récupérer';

  @override
  String get dailyCollected => 'Récupéré';

  @override
  String dailyDayReward(int day) {
    return 'Récompense du jour $day';
  }

  @override
  String get dailyJackpotWon => 'Jackpot !';

  @override
  String get dailyWelcomeBack => 'Bon retour !';

  @override
  String get dailyWelcomeBackBody =>
      'On vous a gardé un cadeau pendant votre absence.';

  @override
  String get dailyClaimFailed =>
      'Impossible de récupérer pour le moment. Réessayez.';

  @override
  String get dailyLoadFailed => 'Impossible de charger votre série.';

  @override
  String get dailyRetry => 'Réessayer';

  @override
  String dailyEntryReady(int day) {
    return 'La récompense du jour $day est prête';
  }

  @override
  String get dailyEntryBroken => 'Série arrêtée · restaurez-la';

  @override
  String get dailyEntryComeback => 'Un cadeau de retour vous attend';

  @override
  String get boostsTitle => 'Boosts';

  @override
  String boostReady(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count boosts prêts',
      one: '1 boost prêt',
    );
    return '$_temp0';
  }

  @override
  String boostWinsPay(int percent, String max) {
    return 'Les victoires en argent rapportent +$percent% (jusqu\'à $max)';
  }

  @override
  String boostTimeLeft(String time) {
    return 'Encore $time';
  }

  @override
  String get boostActive => 'Actif';

  @override
  String get boostActivate => 'Activer';

  @override
  String boostAddTime(String time) {
    return 'Ajouter $time';
  }

  @override
  String boostWaitsFor(int percent) {
    return 'Disponible à la fin de votre +$percent%';
  }

  @override
  String get boostNoneActive => 'Aucun boost actif';

  @override
  String get boostNoneActiveBody =>
      'Activez-en un pour gagner plus à chaque partie d\'argent.';

  @override
  String get boostInventoryEmpty =>
      'Aucun boost en attente. Votre série quotidienne en offre.';

  @override
  String boostStarted(int percent) {
    return 'Boost +$percent% activé !';
  }

  @override
  String boostExtended(String time) {
    return 'Boost prolongé de $time';
  }

  @override
  String get boostActivateFailed =>
      'Impossible d\'activer le boost. Réessayez.';

  @override
  String get boostActivateNow => 'Activer maintenant';

  @override
  String get boostInYourBoosts => 'Ajouté à vos boosts';

  @override
  String boostUpTo(String amount) {
    return 'jusqu\'à +$amount';
  }

  @override
  String boostPayout(int percent) {
    return 'Boost +$percent%';
  }

  @override
  String get boostMoneyOnly => 'Parties d\'argent uniquement';

  @override
  String boostActiveSemantics(int percent, String time) {
    return 'Boost +$percent% actif, encore $time';
  }

  @override
  String get boostOneAtATime =>
      'Un seul niveau de boost à la fois. Le même niveau ajoute son temps.';
}
