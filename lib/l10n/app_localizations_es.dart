// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'ShadowHand';

  @override
  String authError(String error) {
    return 'Error de auth: $error';
  }

  @override
  String get signInToPlay => 'Inicia sesión para jugar en línea';

  @override
  String get continueWithGoogle => 'Continuar con Google';

  @override
  String get signingIn => 'Iniciando sesión…';

  @override
  String get playAsGuest => 'Jugar como invitado';

  @override
  String get entering => 'Entrando…';

  @override
  String get guestSignInServerDown =>
      'Falló el acceso de invitado. ¿Está el servidor en marcha?';

  @override
  String get guestSignInConnection =>
      'Falló el acceso de invitado. Revisa la conexión.';

  @override
  String get googleSignInFailed =>
      'Falló el inicio con Google. Inténtalo de nuevo.';

  @override
  String get tagline => 'Dos jugadores. Una mesa.';

  @override
  String get findMatch => 'Buscar partida';

  @override
  String get createRoom => 'Crear sala';

  @override
  String get joinRoom => 'Unirse';

  @override
  String get playVsRobot => 'Practicar vs Robot';

  @override
  String get robotName => 'Robot';

  @override
  String get retryConnection => 'Reintentar conexión';

  @override
  String get howToPlay => 'Cómo jugar';

  @override
  String get deck => 'Baraja';

  @override
  String get settings => 'Ajustes';

  @override
  String get language => 'Idioma';

  @override
  String get changeLanguage => 'Cambiar idioma';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get guest => 'Invitado';

  @override
  String get google => 'Google';

  @override
  String get player => 'Jugador';

  @override
  String get online => 'En línea';

  @override
  String get connecting => 'Conectando';

  @override
  String get offline => 'Sin conexión';

  @override
  String get joinRoomTitle => 'Unirse a sala';

  @override
  String get joinRoomHint => 'Introduce el código de 6 letras de tu amigo.';

  @override
  String get codeHint => 'CÓDIGO';

  @override
  String get cancel => 'Cancelar';

  @override
  String get join => 'Unirse';

  @override
  String get findingOpponent => 'Buscando rival';

  @override
  String get matchmakingHint => 'Espera — emparejándote con un jugador.';

  @override
  String get privateTable => 'Mesa privada';

  @override
  String get shareCodeWithFriend => 'Comparte este código con un amigo';

  @override
  String waitingForOpponentNamed(String name) {
    return 'Esperando a $name…';
  }

  @override
  String opponentIsReady(String name) {
    return '$name está listo';
  }

  @override
  String get bothPlayersJoined => 'Ambos jugadores unidos';

  @override
  String get codeCopied => 'Código copiado';

  @override
  String get tapToCopy => 'Toca para copiar';

  @override
  String get ready => 'Listo';

  @override
  String get waitingEllipsis => 'Esperando…';

  @override
  String get leaveRoom => 'Salir de la sala';

  @override
  String get vs => 'VS';

  @override
  String get you => 'Tú';

  @override
  String get notReady => 'No listo';

  @override
  String get waitingEllipsisShort => 'Esperando…';

  @override
  String get endGame => 'Terminar partida';

  @override
  String get menu => 'Menú';

  @override
  String get endGameTitle => '¿Terminar partida?';

  @override
  String get endGameMessage => 'Las cartas se revelan y se cuentan los puntos.';

  @override
  String get reveal => 'Revelar';

  @override
  String get peek => 'Mirar';

  @override
  String get shuffle => 'Barajar';

  @override
  String get replace => 'Cambiar';

  @override
  String get waitingOpponentReveal =>
      'Esperando a que el rival vea sus cartas…';

  @override
  String get gameOver => 'Fin de la partida';

  @override
  String get victory => 'Victoria';

  @override
  String get defeat => 'Derrota';

  @override
  String get draw => 'Empate';

  @override
  String seriesScore(int yours, int theirs) {
    return 'SERIE  $yours – $theirs';
  }

  @override
  String get opponent => 'Rival';

  @override
  String get waitingRematch => 'Esperando revancha del rival…';

  @override
  String opponentAskingRematch(String name) {
    return '$name pide una revancha';
  }

  @override
  String get leave => 'Salir';

  @override
  String get rematch => 'Revancha';

  @override
  String get points => 'pts';

  @override
  String get roomInfo => 'Info de sala';

  @override
  String roomCodePlaying(String roomId, String turn) {
    return '$roomId · $turn';
  }

  @override
  String codeRoomId(String roomId) {
    return 'Código $roomId';
  }

  @override
  String roomToastPlaying(String roomId, String turn) {
    return 'Sala $roomId · $turn';
  }

  @override
  String roomToast(String roomId) {
    return 'Sala $roomId';
  }

  @override
  String get yourTurn => 'Tu turno';

  @override
  String get opponentTurn => 'Turno rival';

  @override
  String get leaveRoomTitle => '¿Salir de la sala?';

  @override
  String get leaveRoomMessage => 'Abandonarás esta partida.';

  @override
  String stepOf(int current, int total) {
    return 'Paso $current de $total';
  }

  @override
  String get back => 'Atrás';

  @override
  String get next => 'Siguiente';

  @override
  String get gotIt => 'Entendido';

  @override
  String get ruleGoalTitle => 'Objetivo';

  @override
  String get ruleGoalBody =>
      'Vacía tus cuatro cartas, o ten la puntuación más baja al final. Gana el total más bajo.';

  @override
  String get ruleSetupTitle => 'Preparación';

  @override
  String get ruleSetupBody =>
      'Dos jugadores. Cada uno recibe cuatro cartas boca abajo.';

  @override
  String get ruleOpeningPeekTitle => 'Mirada inicial';

  @override
  String get ruleOpeningPeekBody =>
      'Antes de jugar, ambos miran dos de sus cartas (fila inferior) unos segundos. Memoriza — luego se vuelven a tapar.';

  @override
  String get ruleYourTurnTitle => 'Tu turno';

  @override
  String get ruleYourTurnBody =>
      'Roba del mazo, o si el descarte coincide con una carta que conoces, tócala para descartarla (tu turno continúa). Fallo = carta de penalización en tu zona.';

  @override
  String get ruleAfterDrawTitle => 'Tras robar';

  @override
  String get ruleAfterDrawBody =>
      'Toca una de tus cartas para intercambiar (rango distinto) o doble descarte (mismo rango), o tira la carta robada al descarte. Luego termina tu turno.';

  @override
  String get ruleSpecialTitle => 'Cartas especiales';

  @override
  String get ruleSpecialBody =>
      'Estos rangos activan una habilidad al robarlos. Tras la habilidad, la carta se tira.';

  @override
  String get ruleJackLabel => 'Jota';

  @override
  String get ruleJackDesc =>
      'Mira una carta — tuya o del rival — luego se tira la Jota.';

  @override
  String get ruleQueenLabel => 'Reina';

  @override
  String get ruleQueenDesc =>
      'Baraja una mano, o intercambia una tuya con una del rival, luego se tira la Reina.';

  @override
  String get ruleScoringTitle => 'Puntuación';

  @override
  String get ruleScoringBody =>
      'Cuando alguien vacía su zona (o acaba la partida), suma las cartas restantes. Gana el total más bajo; igual = empate.';

  @override
  String get ruleJokerLabel => 'Joker';

  @override
  String get ruleJokerDesc => 'Cuenta como −1 punto.';

  @override
  String get ruleBlackKingLabel => 'Rey negro';

  @override
  String get ruleBlackKingDesc =>
      'Rey de tréboles o picas = 0. Los reyes rojos valen 13.';

  @override
  String get hintPeek => 'Toca una carta para mirar…';

  @override
  String get hintShufflePick => 'Toca Barajar sobre una mano…';

  @override
  String get hintReplaceFirst => 'Toca una carta de cada mano…';

  @override
  String get hintReplaceSecond => 'Toca una carta de la otra mano…';

  @override
  String get errConnectionLost => 'Conexión perdida';

  @override
  String get errEnterRoomCode => 'Introduce un código de sala';

  @override
  String get errServerNotConnected => 'Servidor no conectado';

  @override
  String get errCommandFailed => 'Comando fallido';

  @override
  String get errRoomFull => 'La sala ya tiene dos jugadores';

  @override
  String get errWaitingForPlayer => 'Se necesitan dos jugadores';

  @override
  String get errAlreadyStarted => 'La partida ya empezó';

  @override
  String get errNotEnded => 'La partida no ha terminado';

  @override
  String get errAlreadyLaunched => 'Cartas ya reveladas';

  @override
  String get errAlreadyDrew => 'Tira o intercambia primero la carta robada';

  @override
  String get errDeckEmpty => 'No hay cartas disponibles';

  @override
  String get errNoJack => 'Mirar requiere una Jota robada';

  @override
  String get errPeekUsed => 'Mirada de Jota ya usada';

  @override
  String get errInvalidSide => 'Lado inválido';

  @override
  String get errInvalidCard => 'Índice de carta inválido';

  @override
  String get errCannotShuffle => 'No hay suficientes cartas para barajar';

  @override
  String get errDrawFirst => 'Roba una carta primero';

  @override
  String get errNoHandCard => 'Roba una carta primero';

  @override
  String get errNotInRoom => 'Únete a una sala primero';

  @override
  String get errNotYourTurn => 'No es tu turno';

  @override
  String get errRevealFirst => 'Ambos jugadores deben revelar primero';

  @override
  String get errNotPlaying => 'La partida no está en curso';

  @override
  String get errPeekInProgress => 'Espera a que termine la mirada';

  @override
  String get errQueenInProgress => 'Espera a que termine la habilidad de Reina';

  @override
  String get errNoQueen => 'La habilidad de Reina requiere una Reina robada';

  @override
  String get errQueenUsed => 'Habilidad de Reina ya usada';

  @override
  String get errInvalidCommand => 'Se requiere el tipo de comando';

  @override
  String get errRoomNotFound => 'Sala no encontrada';

  @override
  String get errUnknownCommand => 'Comando desconocido';

  @override
  String get errTooManyCommands => 'Demasiados comandos';

  @override
  String get globalRanking => 'Ranking global';

  @override
  String get marketplace => 'Mercado';

  @override
  String get comingSoon => 'Próximamente';

  @override
  String get marketplaceComingSoonBody =>
      'Aquí aparecerán skins de cartas y extras.';

  @override
  String get leaderboard => 'Clasificación';

  @override
  String get matchHistory => 'Historial';

  @override
  String get elo => 'Elo';

  @override
  String get colWins => 'V';

  @override
  String get colLosses => 'D';

  @override
  String get colDraws => 'E';

  @override
  String get rankingEmpty =>
      'Aún no hay jugadores clasificados. ¡Juega una partida aleatoria!';

  @override
  String get matchHistoryEmpty => 'Aún no hay partidas clasificadas.';

  @override
  String get rankingLoadError =>
      'No se pudo cargar el ranking. ¿Está el servidor en marcha?';

  @override
  String get matchResultWin => 'VICTORIA';

  @override
  String get matchResultLoss => 'DERROTA';

  @override
  String get matchResultDraw => 'EMPATE';

  @override
  String recordWinsLossesDraws(int wins, int losses, int draws) {
    return '${wins}V · ${losses}D · ${draws}E';
  }

  @override
  String matchScoreLine(int myScore, int oppScore) {
    return 'Tú $myScore · Riv $oppScore';
  }

  @override
  String get friends => 'Amigos';

  @override
  String get friendsComingSoonBody =>
      'Conéctate con amigos e invítalos a partidas pronto.';

  @override
  String get requests => 'Solicitudes';

  @override
  String get addFriend => 'Añadir amigo';

  @override
  String get searchByUsername => 'Buscar por @usuario o nombre...';

  @override
  String get noFriendsYet => 'Aún no hay amigos añadidos.';

  @override
  String get noFriendsHint =>
      '¡Busca usuarios en la pestaña Añadir amigo para conectar!';

  @override
  String get noRequests => 'No hay solicitudes pendientes.';

  @override
  String get incomingRequests => 'Solicitudes recibidas';

  @override
  String get outgoingRequests => 'Solicitudes enviadas';

  @override
  String get accept => 'Aceptar';

  @override
  String get decline => 'Rechazar';

  @override
  String get removeFriend => 'Eliminar amigo';

  @override
  String removeFriendConfirm(String name) {
    return '¿Seguro que quieres eliminar a $name de amigos?';
  }

  @override
  String get friendRequestSent => '¡Solicitud de amistad enviada!';

  @override
  String get friendRequestAccepted => '¡Solicitud de amistad aceptada!';

  @override
  String friendRequestFrom(String name) {
    return '$name te envió una solicitud de amistad';
  }

  @override
  String friendRequestAcceptedBy(String name) {
    return '$name aceptó tu solicitud de amistad';
  }

  @override
  String get friendRemoved => 'Amigo eliminado.';

  @override
  String get requestSent => 'Enviada';

  @override
  String get youTag => 'Tú';

  @override
  String get alreadyFriends => 'Amigos';

  @override
  String get changeUsername => 'Cambiar usuario';

  @override
  String get usernameHint => 'usuario_unico';

  @override
  String get usernameAvailable => 'El usuario está disponible';

  @override
  String get usernameTaken => 'El usuario ya está en uso';

  @override
  String get usernameInvalidFormat => '3-20 caracteres: minúsculas, números, _';

  @override
  String get save => 'Guardar';

  @override
  String get displayName => 'Nombre visible';

  @override
  String get editProfile => 'Editar perfil';

  @override
  String get profileUpdated => '¡Perfil actualizado!';

  @override
  String get searching => 'Buscando...';

  @override
  String get noPlayersFound =>
      'No hay jugadores que coincidan con tu búsqueda.';

  @override
  String get profile => 'Perfil';

  @override
  String level(int lvl) {
    return 'Nivel $lvl';
  }

  @override
  String levelNumber(int lvl) {
    return 'Nivel $lvl';
  }

  @override
  String get xp => 'XP';

  @override
  String get winRate => 'Ratio de victorias';

  @override
  String get matchesPlayed => 'Partidas';

  @override
  String get totalXp => 'XP total';

  @override
  String get copiedToClipboard => 'Copiado al portapapeles';

  @override
  String get rankTitleNovice => 'Novato';

  @override
  String get rankTitleCardShark => 'Tiburón de cartas';

  @override
  String get rankTitleHighRoller => 'Gran apostador';

  @override
  String get rankTitleTableMaster => 'Maestro de mesa';

  @override
  String get rankTitleGrandAce => 'Gran as';

  @override
  String get rankTitleShadowLegend => 'Leyenda sombría';

  @override
  String get inviteFriends => 'Invitar amigos';

  @override
  String get invite => 'Invitar';

  @override
  String get invited => 'Invitado';

  @override
  String get inviteSent => '¡Invitación enviada!';

  @override
  String tableInviteFrom(String name, String code) {
    return '$name te invitó a la mesa privada $code';
  }

  @override
  String get joinTable => 'Unirse a la mesa';

  @override
  String get ignore => 'Ignorar';

  @override
  String get noFriendsToInvite => 'Aún no hay amigos para invitar.';

  @override
  String get customizeAvatar => 'Personalizar avatar';

  @override
  String get locked => 'Bloqueado';

  @override
  String get equipped => 'Equipado';

  @override
  String get equip => 'Equipar';

  @override
  String unlockAtLevel(int lvl) {
    return 'Se desbloquea en el nivel $lvl';
  }

  @override
  String get defaultAvatar => 'Por defecto';

  @override
  String get blueAvatar => 'Zafiro';

  @override
  String get redAvatar => 'Rubí';

  @override
  String get bronzeAvatar => 'Bronce';

  @override
  String get silverAvatar => 'Plata';

  @override
  String get jokerGirlAvatar => 'Joker Girl';

  @override
  String get violetJokerGirlAvatar => 'Joker violeta';

  @override
  String get violetQueenAvatar => 'Reina violeta';

  @override
  String get queenOfHeartAvatar => 'Reina de corazones';

  @override
  String get goldenKingAvatar => 'Rey dorado';

  @override
  String get queenAvatar => 'Reina';

  @override
  String get kingAvatar => 'Rey';

  @override
  String get money => 'Dinero';

  @override
  String get chips => 'Fichas';

  @override
  String get exchange => 'Intercambio';

  @override
  String get avatarShop => 'Avatares';

  @override
  String get deckShop => 'Barajas';

  @override
  String get selectMatchStake => 'Elegir apuesta';

  @override
  String get stake => 'Apuesta';

  @override
  String get pot => 'Bote';

  @override
  String get winnerTakesAll => 'El ganador se lo lleva todo';

  @override
  String get getMoreMoney => 'Obtener dinero';

  @override
  String get insufficientChips => 'No hay suficientes fichas';

  @override
  String get insufficientMoney => 'No hay suficiente dinero';

  @override
  String get exchangedSuccess => 'Intercambio exitoso';

  @override
  String get exchangeFailed => 'Falló el intercambio';

  @override
  String get watchAdForMoney => 'Ver anuncio';

  @override
  String get freeStashBonus => 'Bonus de dinero gratis';

  @override
  String get adRewardEarned => '¡Recompensa obtenida!';

  @override
  String get adNotAvailable => 'Anuncio no listo, inténtalo más tarde';

  @override
  String get chipsToMoney => 'Convertir fichas a dinero';

  @override
  String get moneyToChips => 'Convertir dinero a fichas';

  @override
  String get convert => 'Convertir';

  @override
  String get claim => 'Reclamar';

  @override
  String get buy => 'Comprar';

  @override
  String get owned => 'Poseído';

  @override
  String get unlocked => 'Desbloqueado';

  @override
  String get purchaseFailed => 'Falló la compra';

  @override
  String get classicDeck => 'Azul clásico';

  @override
  String get classicDeckDesc => 'Cartas estándar de casino';

  @override
  String get onyxBlackDeck => 'Ónix negro';

  @override
  String get onyxBlackDeckDesc => 'Dorso de obsidiana con filigrana dorada';

  @override
  String get price => 'Precio';

  @override
  String get play => 'Jugar';

  @override
  String get cityLondon => 'Londres';

  @override
  String get cityParis => 'París';

  @override
  String get cityMoscow => 'Moscú';

  @override
  String get cityCairo => 'El Cairo';

  @override
  String get cityMarrakech => 'Marrakech';

  @override
  String get prize => 'Premio';

  @override
  String get entryFee => 'Entrada';
}
