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
}
