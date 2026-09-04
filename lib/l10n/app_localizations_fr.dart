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
      'Videz vos quatre cartes, ou ayez le score le plus bas à la fin. Le total le plus bas gagne.';

  @override
  String get ruleSetupTitle => 'Mise en place';

  @override
  String get ruleSetupBody =>
      'Deux joueurs. Chacun reçoit quatre cartes face cachée.';

  @override
  String get ruleOpeningPeekTitle => 'Aperçu initial';

  @override
  String get ruleOpeningPeekBody =>
      'Avant de jouer, les deux joueurs regardent deux de leurs cartes (rangée du bas) quelques secondes. Mémorisez-les — elles sont retournées face cachée.';

  @override
  String get ruleYourTurnTitle => 'Votre tour';

  @override
  String get ruleYourTurnBody =>
      'Piochez dans le deck, ou si la défausse correspond à une carte que vous connaissez, touchez-la pour la défausser (votre tour continue). Mauvaise guess = une carte pénalité dans votre disposition.';

  @override
  String get ruleAfterDrawTitle => 'Après la pioche';

  @override
  String get ruleAfterDrawBody =>
      'Touchez une de vos cartes pour échanger (rang différent) ou double-défausse (même rang), ou jetez la carte piochée. Puis votre tour se termine.';

  @override
  String get ruleSpecialTitle => 'Cartes spéciales';

  @override
  String get ruleSpecialBody =>
      'Ces rangs déclenchent une capacité quand vous les piochez. Après la capacité, la carte est jetée.';

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
      'Quand quelqu\'un vide sa disposition (ou la partie finit), additionnez les cartes restantes. Le total le plus bas gagne ; égalité = match nul.';

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
  String get prize => 'Prix';

  @override
  String get entryFee => 'Frais d\'entrée';
}
