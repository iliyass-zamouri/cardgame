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
  String get continueWithApple => 'Continuar con Apple';

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
  String get appleSignInFailed =>
      'Falló el inicio con Apple. Inténtalo de nuevo.';

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
  String get home => 'Inicio';

  @override
  String get shop => 'Tienda';

  @override
  String get collection => 'Colección';

  @override
  String get collectionCards => 'Cartas';

  @override
  String get collectionAvatars => 'Avatares';

  @override
  String ownedCount(int owned, int total) {
    return '$owned/$total en propiedad';
  }

  @override
  String get getMoreInShop => 'Consigue más en la Tienda';

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
  String get apple => 'Apple';

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
      'Termina con el total más bajo. La partida acaba cuando un jugador se queda sin cartas o alguien toca Terminar partida.';

  @override
  String get ruleSetupTitle => 'Preparación';

  @override
  String get ruleSetupBody =>
      'Dos jugadores. Cada uno recibe cuatro cartas boca abajo en fila.';

  @override
  String get ruleOpeningPeekTitle => 'Mirada inicial';

  @override
  String get ruleOpeningPeekBody =>
      'Antes de jugar, toca Revelar para ver tus dos cartas de la izquierda unos segundos. Recuérdalas: luego se vuelven a ocultar.';

  @override
  String get ruleYourTurnTitle => 'Tu turno';

  @override
  String get ruleYourTurnBody =>
      'Antes de robar, si la carta del descarte coincide con una que conoces, tócala para descartarla (tu turno sigue). Fallar = carta de penalización. Luego roba del mazo.';

  @override
  String get ruleAfterDrawTitle => 'Tras robar';

  @override
  String get ruleAfterDrawBody =>
      'Toca una de tus cartas para intercambiar (valor distinto) o hacer doble descarte (mismo valor), o toca la carta robada para tirarla. Luego termina tu turno.';

  @override
  String get ruleSpecialTitle => 'Cartas especiales';

  @override
  String get ruleSpecialBody =>
      'Al robar estas cartas puedes usar su poder. Después, la carta se tira.';

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
      'Cuando un jugador se queda sin cartas o alguien toca Terminar partida, se revelan y suman todas las cartas. As = 1, Jota = 11, Reina = 12. Gana el total más bajo; igual = empate.';

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
  String get sapphireFrostDeck => 'Dragón de Zafiro';

  @override
  String get sapphireFrostDeckDesc =>
      'Nudos celtas en zafiro y oro alrededor de dos dragones';

  @override
  String get imperialJadeDeck => 'Alto Victoriano';

  @override
  String get imperialJadeDeckDesc =>
      'Filigrana esmeralda en un marco victoriano dorado';

  @override
  String get royalCrimsonDeck => 'Carmesí Real';

  @override
  String get royalCrimsonDeckDesc =>
      'Filigrana dorada y figura coronada sobre carmesí';

  @override
  String get neonNightsDeck => 'Noches de Neón';

  @override
  String get neonNightsDeckDesc =>
      'Un atardecer synthwave sobre una cuadrícula de neón';

  @override
  String get gildedDeck => 'Oro de 24K';

  @override
  String get gildedDeckDesc =>
      'Oro macizo grabado con un diamante de talla brillante';

  @override
  String get rarityRare => 'Raro';

  @override
  String get rarityEpic => 'Épico';

  @override
  String get rarityLegendary => 'Legendario';

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
  String get cityToronto => 'Toronto';

  @override
  String get cityNewYork => 'Nueva York';

  @override
  String get cityTokyo => 'Tokio';

  @override
  String get prize => 'Premio';

  @override
  String get entryFee => 'Entrada';

  @override
  String get linkGoogleAccount => 'Vincular cuenta de Google';

  @override
  String get linkingGoogle => 'Vinculando…';

  @override
  String get linkAppleAccount => 'Vincular cuenta de Apple';

  @override
  String get linkGoogleSuccess =>
      'Cuenta de Google vinculada. Progreso guardado.';

  @override
  String get linkGoogleSwitched => 'Sesión iniciada con tu cuenta de Google.';

  @override
  String get linkAppleSuccess =>
      'Cuenta de Apple vinculada. Progreso guardado.';

  @override
  String get linkAppleSwitched => 'Sesión iniciada con tu cuenta de Apple.';

  @override
  String get saveProgressTitle => 'Guarda tu progreso';

  @override
  String get saveProgressBody =>
      'Vincula una cuenta de Google para conservar dinero, fichas y ranking si cambias de dispositivo.';

  @override
  String get saveProgressBodyIos =>
      'Vincula una cuenta de Apple o Google para conservar dinero, fichas y ranking si cambias de dispositivo.';

  @override
  String get googleAccountInUseTitle => 'Cuenta de Google en uso';

  @override
  String get appleAccountInUseTitle => 'Cuenta de Apple en uso';

  @override
  String googleAccountInUseBody(String username) {
    return 'Esta cuenta de Google ya pertenece a @$username. ¿Cambiar a esa cuenta? Se perderá el progreso de invitado en este dispositivo.';
  }

  @override
  String appleAccountInUseBody(String username) {
    return 'Esta cuenta de Apple ya pertenece a @$username. ¿Cambiar a esa cuenta? Se perderá el progreso de invitado en este dispositivo.';
  }

  @override
  String get switchToGoogleAccount => 'Cambiar de cuenta';

  @override
  String get dontAskAgain => 'No volver a preguntar';

  @override
  String get later => 'Más tarde';

  @override
  String get youQuit => 'Abandonaste';

  @override
  String get opponentQuit => 'El rival abandonó';

  @override
  String get matchResultQuit => 'ABANDONO';

  @override
  String get leaveMatchPenaltyMessage =>
      'Salir ahora cuenta como derrota: perderás tu apuesta y 15 puntos.';

  @override
  String get notEnoughMoneyTitle => 'Dinero insuficiente';

  @override
  String notEnoughMoneyMessage(int required, int money) {
    return 'La apuesta es $required pero tienes $money. Cambia fichas o compra más para la revancha.';
  }

  @override
  String get stakeCovered => 'Ya tienes suficiente: listo para la revancha.';

  @override
  String get exchangeChips => 'Cambiar fichas';

  @override
  String get buyMoney => 'Comprar dinero';

  @override
  String get rematchStarting => 'Cobrando apuestas…';

  @override
  String opponentCantAffordRematch(String name) {
    return '$name no puede cubrir la apuesta';
  }

  @override
  String get offlineReconnecting => 'Sin conexión · reconectando…';

  @override
  String get getMoreChips => 'Obtener fichas';

  @override
  String get notEnoughChipsTitle => 'Fichas insuficientes';

  @override
  String notEnoughChipsMessage(int required, int chips) {
    return 'La apuesta es $required fichas pero tienes $chips. Compra más fichas para la revancha.';
  }

  @override
  String get buyChips => 'Comprar fichas';

  @override
  String get tutLessonValuesTitle => 'Objetivo y valor de las cartas';

  @override
  String get tutLessonDealTitle => 'El reparto y primer vistazo';

  @override
  String get tutLessonSwapTitle => 'Robar e intercambiar';

  @override
  String get tutLessonThrowTitle => 'Tirar una carta';

  @override
  String get tutLessonDoubleTitle => 'Doble descarte';

  @override
  String get tutLessonMatchTitle => 'Igualar el descarte';

  @override
  String get tutLessonJackTitle => 'Jota: mirar';

  @override
  String get tutLessonQueenTitle => 'Reina: cambiar o barajar';

  @override
  String get tutLessonEndTitle => 'Final y puntuación';

  @override
  String get tutLessonTipsTitle => 'Consejos para ganar';

  @override
  String get tutValuesIntro =>
      'ShadowHand es un juego de memoria para dos. Cada jugador tiene cartas boca abajo. Al terminar la partida, cada uno suma sus cartas: gana el total más bajo.';

  @override
  String get tutValuesChart =>
      'Cada carta vale puntos. As = 1, cartas numéricas = su número, Jota = 11, Reina = 12, Rey rojo = 13. Las mejores: un Rey negro vale 0 y un Comodín vale −1.';

  @override
  String get tutValuesQuizLowest =>
      'Pregunta rápida: toca la carta que vale menos puntos.';

  @override
  String get tutValuesQuizLowestWrong =>
      'No exactamente. El Comodín vale −1, incluso menos que un As.';

  @override
  String get tutValuesQuizKing =>
      'Aquí hay dos Reyes. Toca el que vale 0 puntos.';

  @override
  String get tutValuesQuizKingWrong =>
      'Solo los Reyes negros (♠ ♣) valen 0. Los Reyes rojos (♥ ♦) valen 13: ¡la peor carta del mazo!';

  @override
  String get tutValuesDone =>
      '¡Perfecto! Tu objetivo: quedarte con cartas bajas y librarte de las altas.';

  @override
  String get tutDealIntro =>
      'Cada jugador recibe 4 cartas boca abajo en fila. Aún no sabes cuáles son, y tu rival tampoco.';

  @override
  String get tutDealReveal =>
      'Antes de empezar, puedes echar un vistazo. Toca Revelar.';

  @override
  String get tutDealMemorize =>
      'Tus dos cartas de la izquierda se muestran unos segundos. Recuérdalas: ¡un 2 y un 8!';

  @override
  String get tutDealQuiz =>
      'Vuelven a estar boca abajo. ¿Dónde está tu 2? Tócalo.';

  @override
  String get tutDealQuizWrong =>
      'El 2 era tu primera carta, a la izquierda del todo. ¡En este juego la memoria lo es todo!';

  @override
  String get tutDealDone =>
      '¡Correcto! Tus otras dos cartas siguen siendo un misterio: irás descubriendo más al jugar.';

  @override
  String get tutDrawPrompt => 'Es tu turno. Toca el mazo para robar una carta.';

  @override
  String get tutSwapIntro =>
      'Recuerdas tus dos primeras cartas: un 2 y un 9. Un 9 son muchos puntos: vamos a cambiarlo.';

  @override
  String get tutSwapPick =>
      'Robaste un 3. ¡Mejor que tu 9! Toca tu 9 (segunda carta) para intercambiarlos.';

  @override
  String get tutSwapPickWrong =>
      'Toca tu 9, la segunda carta desde la izquierda. Cambiar una carta que no conoces es una apuesta.';

  @override
  String get tutSwapDone =>
      'El 3 queda boca abajo donde estaba el 9, y el 9 va al descarte. Tu turno termina, y acabas de ahorrarte 6 puntos.';

  @override
  String get tutThrowPick =>
      'Uy, un Rey rojo, vale 13. ¡No lo quieres! Toca la carta robada para tirarla al descarte.';

  @override
  String get tutThrowWrong =>
      'No te quedes una mala carta. Toca la carta robada (abajo a la izquierda) para tirarla.';

  @override
  String get tutThrowDone =>
      '¡Tirada! Tus cartas no cambiaron y tu turno terminó. Tira cualquier carta que no mejore tu mano.';

  @override
  String get tutDoubleIntro => 'Recuerdas que tu primera carta es un 5.';

  @override
  String get tutDoublePick =>
      '¡Otro 5! Si la carta que robas tiene el mismo valor que una de las tuyas, toca tu carta: se descartan las dos.';

  @override
  String get tutDoubleWrong => 'Toca tu 5, la primera carta de la izquierda.';

  @override
  String get tutDoubleDone =>
      'Los dos 5 se fueron y tienes una carta menos. Menos cartas, menos puntos, y si te quedas sin cartas, la partida termina.';

  @override
  String get tutMatchIntro =>
      'Recuerdas que tu primera carta es un 7. Ahora juega tu rival…';

  @override
  String get tutMatchPick =>
      '¡Tu rival tiró un 7! En tu turno, antes de robar, puedes tocar una carta del mismo valor que la del descarte para librarte de ella. Toca tu 7.';

  @override
  String get tutMatchWrong => 'Toca tu 7, la primera carta de la izquierda.';

  @override
  String get tutMatchContinue =>
      '¡Descarte gratis! Igualar no termina tu turno: puedes volver a igualar y después robas igual. Toca el mazo.';

  @override
  String get tutMatchThrow =>
      'Un 8, no es gran cosa. Tócalo para tirarlo y terminar tu turno.';

  @override
  String get tutMatchGuess =>
      'En el siguiente turno, arriba hay un 4. Crees que tu carta del medio podría ser un 4… pero no estás seguro. Veamos qué pasa si fallas: tócala.';

  @override
  String get tutMatchPenalty =>
      'Fallaste: no era un 4. Recibes una carta de penalización boca abajo y la carta que tocaste se queda. ¡Iguala solo si estás seguro!';

  @override
  String get tutJackPeekButton =>
      '¡Una Jota! Al robar una Jota puedes mirar una carta, tuya o de tu rival. Toca Mirar.';

  @override
  String get tutJackPick =>
      'Ahora toca la carta que quieres ver. Espiemos la segunda carta de tu rival.';

  @override
  String get tutJackPickWrong =>
      'Toca la segunda carta de tu rival desde la izquierda.';

  @override
  String get tutJackReveal =>
      'Es una Reina: 12 puntos para él. Recuerda dónde está: se oculta en un momento.';

  @override
  String get tutJackDone =>
      'Tras mirar, la Jota se tira sola y tu turno termina. El poder es opcional: también puedes quedarte o tirar una Jota como cualquier carta.';

  @override
  String get tutQueenIntro =>
      'Recuerdas que tu segunda carta es un 10. Vamos a dársela a tu rival.';

  @override
  String get tutQueenButtons =>
      '¡Una Reina! Puedes elegir. Barajar mezcla las cartas de un jugador. Cambiar intercambia una de tus cartas por una suya. Toca Cambiar.';

  @override
  String get tutQueenButtonsWrong => 'En esta lección, toca Cambiar.';

  @override
  String get tutQueenPickYours =>
      'Primero toca la carta que quieres dar: tu 10, la segunda carta.';

  @override
  String get tutQueenPickYoursWrong =>
      'Toca tu 10, tu segunda carta desde la izquierda.';

  @override
  String get tutQueenPickTheirs =>
      'Ahora toca la carta del rival que quieres: su primera carta.';

  @override
  String get tutQueenPickTheirsWrong =>
      'Toca la primera carta de tu rival, a la izquierda.';

  @override
  String get tutQueenDone =>
      '¡Cambiadas! Tu 10 ahora es de tu rival. No ves la carta que recibiste, pero casi todas valen menos de 10: buen trato. La Reina se tira tras usarla.';

  @override
  String get tutQueenShuffle =>
      'Barajar es la otra opción: mezcla las cartas de tu rival y todo lo que recordaba deja de servir. También puedes barajar las tuyas.';

  @override
  String get tutEndIntro =>
      'La partida termina de dos formas: un jugador se queda sin cartas, o alguien toca Terminar partida.';

  @override
  String get tutEndPress =>
      '¿Crees que tu total es menor? Cualquier jugador puede tocar Terminar partida en cualquier momento. Pruébalo.';

  @override
  String get tutEndCount =>
      'Se revelan todas las cartas. Suma las tuyas: 3 + 2 + Rey negro + Comodín. ¿Cuál es tu total?';

  @override
  String get tutEndCountWrong =>
      'Recuerda: un Rey negro vale 0 y un Comodín −1. Así que 3 + 2 + 0 − 1 = 4.';

  @override
  String get tutEndWinner => 'Tu rival tiene 9 + 5 + 7 + 1 = 22. ¿Quién gana?';

  @override
  String get tutEndWinnerWrong => 'Gana el total más bajo: 4 gana a 22.';

  @override
  String get tutEndDone => '¡Ganas! Si los totales son iguales, es empate.';

  @override
  String get tutTipMemory =>
      'Consejo 1: recuérdalo todo. Cada carta que ves (al inicio, al cambiar, con una Jota) te da información. No la olvides.';

  @override
  String get tutTipKeepLow =>
      'Consejo 2: quédate los Reyes negros y los Comodines. Valen 0 y −1: nunca los cambies.';

  @override
  String get tutTipDiscard =>
      'Consejo 3: vigila el descarte. Cada carta que tira tu rival es una oportunidad de igualar gratis.';

  @override
  String get tutTipQueen =>
      'Consejo 4: usa bien las Reinas. Regala tu carta más alta, o Baraja para arruinar la memoria de tu rival.';

  @override
  String get tutTipEnd =>
      'Consejo 5: termina en el momento justo. Si crees que tu total es menor, toca Terminar partida antes de que tu rival te alcance.';

  @override
  String get tutChoiceYou => 'Tú';

  @override
  String get tutChoiceOpponent => 'Rival';

  @override
  String get tutChoiceTie => 'Empate';

  @override
  String get tutDeckLabel => 'Mazo';

  @override
  String get tutDiscardLabel => 'Descarte';

  @override
  String get tutDrawnLabel => 'Robada';

  @override
  String get tutAceLabel => 'As';

  @override
  String get tutNumberCardsLabel => '2 a 10';

  @override
  String get tutRedKingLabel => 'Rey rojo';

  @override
  String get tutTapHighlighted => 'Toca lo que brilla para continuar.';

  @override
  String tutLessonProgress(int current, int total) {
    return 'Lección $current de $total';
  }

  @override
  String get tutSkip => 'Saltar';

  @override
  String get tutLessonDone => '¡Lección completada!';

  @override
  String get tutReplay => 'Repetir';

  @override
  String get tutFinish => 'Terminar';

  @override
  String get tutNextLesson => 'Siguiente lección';

  @override
  String get tutCompleteTitle => '¡Estás listo!';

  @override
  String get tutCompleteBody =>
      'Ya conoces todas las reglas. Practica contra el robot y luego enfréntate a jugadores reales.';

  @override
  String get tutHubIntro =>
      'Aprende ShadowHand jugando. Cada lección corta te pone cartas en la mano y te enseña una regla.';

  @override
  String get tutStartAll => 'Empezar tutorial';

  @override
  String get tutContinue => 'Continuar tutorial';

  @override
  String get tutLessonsHeader => 'Lecciones';

  @override
  String get tutQuickRules => 'Reglas rápidas';

  @override
  String get tutQuickRulesSubtitle => 'Todas las reglas en 7 cartas';

  @override
  String get tutPromptTitle => '¿Nuevo en ShadowHand?';

  @override
  String get tutPromptBody =>
      'Aprende a jugar con un tutorial interactivo. Dura unos 3 minutos.';

  @override
  String get tutPromptLater => 'Ahora no';

  @override
  String get chat => 'Chat';

  @override
  String get chatHint => 'Escribe un mensaje…';

  @override
  String get chatEmpty => 'Aún no hay mensajes. ¡Saluda!';

  @override
  String get quickPhrases => 'Frases rápidas';

  @override
  String get phraseHello => '¡Hola!';

  @override
  String get phraseGoodLuck => 'Buena suerte';

  @override
  String get phraseWellPlayed => 'Bien jugado';

  @override
  String get phrasePlayFast => '¡Juega rápido!';

  @override
  String get phraseOops => 'Ups';

  @override
  String get phraseThanks => 'Gracias';

  @override
  String get phraseUnlucky => 'Mala carta';

  @override
  String get phraseHehe => 'Jeje';

  @override
  String get phraseGg => 'GG';

  @override
  String get micOn => 'Micro activado';

  @override
  String get micOff => 'Micro apagado';

  @override
  String get micPermissionDenied =>
      'El acceso al micrófono está desactivado. Actívalo en los ajustes del teléfono para hablar.';

  @override
  String get voiceOpponentTalking => 'Voz activa';

  @override
  String get muteOpponent => 'Silenciar jugador';

  @override
  String get unmuteOpponent => 'Quitar silencio';

  @override
  String opponentMutedToast(String name) {
    return '$name está silenciado';
  }

  @override
  String get reportPlayer => 'Denunciar jugador';

  @override
  String reportPlayerConfirm(String name) {
    return '¿Denunciar a $name por mal comportamiento?';
  }

  @override
  String get reportedToast => 'Gracias, revisaremos a este jugador';

  @override
  String get recentForm => 'Forma reciente';

  @override
  String get noRecentMatches => 'Aún no hay partidas';

  @override
  String get tableChatSettings => 'Chat de mesa';

  @override
  String get showOpponentChat => 'Mostrar chat del rival';

  @override
  String get voiceChatSetting => 'Chat de voz';

  @override
  String get errChatRateLimited =>
      'Más despacio, envías mensajes demasiado rápido';

  @override
  String get errChatInvalid => 'No se pudo enviar el mensaje';

  @override
  String get phraseNiceSwap => '¡Buen cambio!';

  @override
  String get phraseSharpMemory => '¡Qué memoria!';

  @override
  String get phraseStopPeeking => '¡Deja de espiar!';

  @override
  String get phraseGiveCardBack => '¡Devuélveme mi carta!';

  @override
  String get phraseBlackKingPlease => '¡Un Rey negro, por favor!';

  @override
  String get phraseLowTotal => 'Mi total es mínimo';

  @override
  String get phraseFoundJoker => '¡Encontré un Joker!';

  @override
  String get phraseKnowMyCards => 'Conozco todas mis cartas';

  @override
  String get phraseEndingNextTurn => '¡Termino en el próximo turno!';
}
