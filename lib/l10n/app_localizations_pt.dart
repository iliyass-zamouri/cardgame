// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'ShadowHand';

  @override
  String authError(String error) {
    return 'Erro de auth: $error';
  }

  @override
  String get signInToPlay => 'Entre para jogar online';

  @override
  String get continueWithGoogle => 'Continuar com Google';

  @override
  String get signingIn => 'Entrando…';

  @override
  String get playAsGuest => 'Jogar como convidado';

  @override
  String get entering => 'Entrando…';

  @override
  String get guestSignInServerDown =>
      'Falha no acesso de convidado. O servidor está ligado?';

  @override
  String get guestSignInConnection =>
      'Falha no acesso de convidado. Verifique a conexão.';

  @override
  String get googleSignInFailed => 'Falha no login com Google. Tente de novo.';

  @override
  String get tagline => 'Dois jogadores. Uma mesa.';

  @override
  String get findMatch => 'Buscar partida';

  @override
  String get createRoom => 'Criar sala';

  @override
  String get joinRoom => 'Entrar';

  @override
  String get playVsRobot => 'Treinar vs Robô';

  @override
  String get robotName => 'Robô';

  @override
  String get retryConnection => 'Tentar conexão de novo';

  @override
  String get howToPlay => 'Como jogar';

  @override
  String get deck => 'Baralho';

  @override
  String get settings => 'Configurações';

  @override
  String get language => 'Idioma';

  @override
  String get changeLanguage => 'Mudar idioma';

  @override
  String get signOut => 'Sair';

  @override
  String get guest => 'Convidado';

  @override
  String get google => 'Google';

  @override
  String get player => 'Jogador';

  @override
  String get online => 'Online';

  @override
  String get connecting => 'Conectando';

  @override
  String get offline => 'Offline';

  @override
  String get joinRoomTitle => 'Entrar na sala';

  @override
  String get joinRoomHint => 'Digite o código de 6 letras do seu amigo.';

  @override
  String get codeHint => 'CÓDIGO';

  @override
  String get cancel => 'Cancelar';

  @override
  String get join => 'Entrar';

  @override
  String get findingOpponent => 'Procurando oponente';

  @override
  String get matchmakingHint => 'Aguarde — emparelhando você com um jogador.';

  @override
  String get privateTable => 'Mesa privada';

  @override
  String get shareCodeWithFriend => 'Compartilhe este código com um amigo';

  @override
  String waitingForOpponentNamed(String name) {
    return 'Aguardando $name…';
  }

  @override
  String opponentIsReady(String name) {
    return '$name está pronto';
  }

  @override
  String get bothPlayersJoined => 'Ambos os jogadores entraram';

  @override
  String get codeCopied => 'Código copiado';

  @override
  String get tapToCopy => 'Toque para copiar';

  @override
  String get ready => 'Pronto';

  @override
  String get waitingEllipsis => 'Aguardando…';

  @override
  String get leaveRoom => 'Sair da sala';

  @override
  String get vs => 'VS';

  @override
  String get you => 'Você';

  @override
  String get notReady => 'Não pronto';

  @override
  String get waitingEllipsisShort => 'Aguardando…';

  @override
  String get endGame => 'Encerrar partida';

  @override
  String get menu => 'Menu';

  @override
  String get endGameTitle => 'Encerrar partida?';

  @override
  String get endGameMessage => 'As cartas são reveladas e os pontos contados.';

  @override
  String get reveal => 'Revelar';

  @override
  String get peek => 'Espiar';

  @override
  String get shuffle => 'Embaralhar';

  @override
  String get replace => 'Trocar';

  @override
  String get waitingOpponentReveal => 'Aguardando o oponente ver as cartas…';

  @override
  String get gameOver => 'Fim de jogo';

  @override
  String get victory => 'Vitória';

  @override
  String get defeat => 'Derrota';

  @override
  String get draw => 'Empate';

  @override
  String seriesScore(int yours, int theirs) {
    return 'SÉRIE  $yours – $theirs';
  }

  @override
  String get opponent => 'Oponente';

  @override
  String get waitingRematch => 'Aguardando revanche do oponente…';

  @override
  String opponentAskingRematch(String name) {
    return '$name pede uma revanche';
  }

  @override
  String get leave => 'Sair';

  @override
  String get rematch => 'Revanche';

  @override
  String get points => 'pts';

  @override
  String get roomInfo => 'Info da sala';

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
  String get yourTurn => 'Sua vez';

  @override
  String get opponentTurn => 'Vez do oponente';

  @override
  String get leaveRoomTitle => 'Sair da sala?';

  @override
  String get leaveRoomMessage => 'Você sairá desta partida.';

  @override
  String stepOf(int current, int total) {
    return 'Passo $current de $total';
  }

  @override
  String get back => 'Voltar';

  @override
  String get next => 'Próximo';

  @override
  String get gotIt => 'Entendi';

  @override
  String get ruleGoalTitle => 'Objetivo';

  @override
  String get ruleGoalBody =>
      'Esvazie suas quatro cartas, ou tenha a menor pontuação no fim. O menor total vence.';

  @override
  String get ruleSetupTitle => 'Preparação';

  @override
  String get ruleSetupBody =>
      'Dois jogadores. Cada um recebe quatro cartas viradas para baixo.';

  @override
  String get ruleOpeningPeekTitle => 'Espiada inicial';

  @override
  String get ruleOpeningPeekBody =>
      'Antes de jogar, ambos espiam duas de suas cartas (fileira de baixo) por alguns segundos. Memorize — depois elas viram de novo.';

  @override
  String get ruleYourTurnTitle => 'Sua vez';

  @override
  String get ruleYourTurnBody =>
      'Compre do baralho, ou se o descarte corresponder a uma carta que você conhece, toque nela para descartar (sua vez continua). Erro = carta de penalidade na sua área.';

  @override
  String get ruleAfterDrawTitle => 'Após comprar';

  @override
  String get ruleAfterDrawBody =>
      'Toque em uma de suas cartas para trocar (valor diferente) ou descarte duplo (mesmo valor), ou jogue a carta comprada no descarte. Depois sua vez acaba.';

  @override
  String get ruleSpecialTitle => 'Cartas especiais';

  @override
  String get ruleSpecialBody =>
      'Esses valores ativam uma habilidade ao comprá-los. Após a habilidade, a carta é descartada.';

  @override
  String get ruleJackLabel => 'Valete';

  @override
  String get ruleJackDesc =>
      'Espie uma carta — sua ou do oponente — depois o Valete é descartado.';

  @override
  String get ruleQueenLabel => 'Dama';

  @override
  String get ruleQueenDesc =>
      'Embaralhe uma mão, ou troque uma sua com uma do oponente, depois a Dama é descartada.';

  @override
  String get ruleScoringTitle => 'Pontuação';

  @override
  String get ruleScoringBody =>
      'Quando alguém esvazia a área (ou o jogo acaba), some as cartas restantes. Menor total vence; igual = empate.';

  @override
  String get ruleJokerLabel => 'Curinga';

  @override
  String get ruleJokerDesc => 'Conta como −1 ponto.';

  @override
  String get ruleBlackKingLabel => 'Rei preto';

  @override
  String get ruleBlackKingDesc =>
      'Rei de paus ou espadas = 0. Reis vermelhos valem 13.';

  @override
  String get hintPeek => 'Toque em qualquer carta para espiar…';

  @override
  String get hintShufflePick => 'Toque em Embaralhar acima de uma mão…';

  @override
  String get hintReplaceFirst => 'Toque em uma carta de cada mão…';

  @override
  String get hintReplaceSecond => 'Toque em uma carta da outra mão…';

  @override
  String get errConnectionLost => 'Conexão perdida';

  @override
  String get errEnterRoomCode => 'Digite um código de sala';

  @override
  String get errServerNotConnected => 'Servidor não conectado';

  @override
  String get errCommandFailed => 'Comando falhou';

  @override
  String get errRoomFull => 'A sala já tem dois jogadores';

  @override
  String get errWaitingForPlayer => 'Dois jogadores necessários';

  @override
  String get errAlreadyStarted => 'Partida já começou';

  @override
  String get errNotEnded => 'A partida não acabou';

  @override
  String get errAlreadyLaunched => 'Cartas já reveladas';

  @override
  String get errAlreadyDrew => 'Descarte ou troque a carta comprada primeiro';

  @override
  String get errDeckEmpty => 'Nenhuma carta disponível';

  @override
  String get errNoJack => 'Espiar exige um Valete comprado';

  @override
  String get errPeekUsed => 'Espiada do Valete já usada';

  @override
  String get errInvalidSide => 'Lado inválido';

  @override
  String get errInvalidCard => 'Índice de carta inválido';

  @override
  String get errCannotShuffle => 'Cartas insuficientes para embaralhar';

  @override
  String get errDrawFirst => 'Compre uma carta primeiro';

  @override
  String get errNoHandCard => 'Compre uma carta primeiro';

  @override
  String get errNotInRoom => 'Entre numa sala primeiro';

  @override
  String get errNotYourTurn => 'Não é a sua vez';

  @override
  String get errRevealFirst => 'Ambos devem revelar primeiro';

  @override
  String get errNotPlaying => 'A partida não está em andamento';

  @override
  String get errPeekInProgress => 'Aguarde a espiada terminar';

  @override
  String get errQueenInProgress => 'Aguarde a habilidade da Dama terminar';

  @override
  String get errNoQueen => 'A habilidade da Dama exige uma Dama comprada';

  @override
  String get errQueenUsed => 'Habilidade da Dama já usada';

  @override
  String get errInvalidCommand => 'Tipo de comando obrigatório';

  @override
  String get errRoomNotFound => 'Sala não encontrada';

  @override
  String get errUnknownCommand => 'Comando desconhecido';

  @override
  String get errTooManyCommands => 'Comandos demais';

  @override
  String get globalRanking => 'Ranking global';

  @override
  String get marketplace => 'Loja';

  @override
  String get comingSoon => 'Em breve';

  @override
  String get marketplaceComingSoonBody =>
      'Skins de cartas e extras aparecerão aqui.';

  @override
  String get leaderboard => 'Classificação';

  @override
  String get matchHistory => 'Histórico';

  @override
  String get elo => 'Elo';

  @override
  String get rankingEmpty =>
      'Ainda sem jogadores ranqueados. Jogue uma partida aleatória!';

  @override
  String get matchHistoryEmpty => 'Ainda sem partidas ranqueadas.';

  @override
  String get rankingLoadError =>
      'Não foi possível carregar o ranking. O servidor está ligado?';

  @override
  String get matchResultWin => 'VITÓRIA';

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
    return 'Você $myScore · Op $oppScore';
  }

  @override
  String get friends => 'Amigos';

  @override
  String get friendsComingSoonBody =>
      'Conecte-se com amigos e convide-os para partidas em breve.';

  @override
  String get requests => 'Pedidos';

  @override
  String get addFriend => 'Adicionar amigo';

  @override
  String get searchByUsername => 'Buscar por @usuário ou nome...';

  @override
  String get noFriendsYet => 'Nenhum amigo adicionado ainda.';

  @override
  String get noFriendsHint =>
      'Busque usuários na aba Adicionar amigo para conectar!';

  @override
  String get noRequests => 'Nenhum pedido de amizade pendente.';

  @override
  String get incomingRequests => 'Pedidos recebidos';

  @override
  String get outgoingRequests => 'Pedidos enviados';

  @override
  String get accept => 'Aceitar';

  @override
  String get decline => 'Recusar';

  @override
  String get removeFriend => 'Remover amigo';

  @override
  String removeFriendConfirm(String name) {
    return 'Tem certeza de que quer remover $name dos amigos?';
  }

  @override
  String get friendRequestSent => 'Pedido de amizade enviado!';

  @override
  String get friendRequestAccepted => 'Pedido de amizade aceito!';

  @override
  String friendRequestFrom(String name) {
    return '$name enviou um pedido de amizade';
  }

  @override
  String friendRequestAcceptedBy(String name) {
    return '$name aceitou seu pedido de amizade';
  }

  @override
  String get friendRemoved => 'Amigo removido.';

  @override
  String get requestSent => 'Enviado';

  @override
  String get youTag => 'Você';

  @override
  String get alreadyFriends => 'Amigos';

  @override
  String get changeUsername => 'Alterar usuário';

  @override
  String get usernameHint => 'usuario_unico';

  @override
  String get usernameAvailable => 'Usuário disponível';

  @override
  String get usernameTaken => 'Usuário já está em uso';

  @override
  String get usernameInvalidFormat => '3-20 caracteres: minúsculas, números, _';

  @override
  String get save => 'Salvar';

  @override
  String get displayName => 'Nome de exibição';

  @override
  String get editProfile => 'Editar perfil';

  @override
  String get profileUpdated => 'Perfil atualizado com sucesso!';

  @override
  String get searching => 'Buscando...';

  @override
  String get noPlayersFound => 'Nenhum jogador encontrado na busca.';

  @override
  String get profile => 'Perfil';

  @override
  String level(int lvl) {
    return 'Nível $lvl';
  }

  @override
  String levelNumber(int lvl) {
    return 'Nível $lvl';
  }

  @override
  String get xp => 'XP';

  @override
  String get winRate => 'Taxa de vitórias';

  @override
  String get matchesPlayed => 'Partidas';

  @override
  String get totalXp => 'XP total';

  @override
  String get copiedToClipboard => 'Copiado para a área de transferência';

  @override
  String get rankTitleNovice => 'Novato';

  @override
  String get rankTitleCardShark => 'Tubarão das cartas';

  @override
  String get rankTitleHighRoller => 'Grande apostador';

  @override
  String get rankTitleTableMaster => 'Mestre da mesa';

  @override
  String get rankTitleGrandAce => 'Grande ás';

  @override
  String get rankTitleShadowLegend => 'Lenda das sombras';

  @override
  String get inviteFriends => 'Convidar amigos';

  @override
  String get invite => 'Convidar';

  @override
  String get invited => 'Convidado';

  @override
  String get inviteSent => 'Convite enviado!';

  @override
  String tableInviteFrom(String name, String code) {
    return '$name convidou você para a mesa privada $code';
  }

  @override
  String get joinTable => 'Entrar na mesa';

  @override
  String get ignore => 'Ignorar';

  @override
  String get noFriendsToInvite => 'Nenhum amigo adicionado para convidar.';

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
    return 'Desbloqueia no nível $lvl';
  }

  @override
  String get defaultAvatar => 'Padrão';

  @override
  String get blueAvatar => 'Safira';

  @override
  String get redAvatar => 'Rubi';

  @override
  String get bronzeAvatar => 'Bronze';

  @override
  String get silverAvatar => 'Prata';

  @override
  String get jokerGirlAvatar => 'Joker Girl';

  @override
  String get violetJokerGirlAvatar => 'Joker violeta';

  @override
  String get violetQueenAvatar => 'Rainha violeta';

  @override
  String get queenOfHeartAvatar => 'Rainha de copas';

  @override
  String get goldenKingAvatar => 'Rei dourado';

  @override
  String get queenAvatar => 'Rainha';

  @override
  String get kingAvatar => 'Rei';

  @override
  String get money => 'Dinheiro';

  @override
  String get chips => 'Fichas';

  @override
  String get exchange => 'Troca';

  @override
  String get avatarShop => 'Avatares';

  @override
  String get deckShop => 'Baralhos';

  @override
  String get selectMatchStake => 'Escolher aposta';

  @override
  String get stake => 'Aposta';

  @override
  String get pot => 'Pote';

  @override
  String get winnerTakesAll => 'O vencedor leva tudo';

  @override
  String get getMoreMoney => 'Obter dinheiro';

  @override
  String get insufficientChips => 'Fichas insuficientes';

  @override
  String get insufficientMoney => 'Dinheiro insuficiente';

  @override
  String get exchangedSuccess => 'Troca bem-sucedida';

  @override
  String get exchangeFailed => 'Falha na troca';

  @override
  String get watchAdForMoney => 'Assistir anúncio';

  @override
  String get freeStashBonus => 'Bônus de dinheiro grátis';

  @override
  String get adRewardEarned => 'Recompensa recebida!';

  @override
  String get adNotAvailable => 'Anúncio indisponível, tente mais tarde';

  @override
  String get chipsToMoney => 'Converter fichas em dinheiro';

  @override
  String get moneyToChips => 'Converter dinheiro em fichas';

  @override
  String get convert => 'Converter';

  @override
  String get claim => 'Resgatar';

  @override
  String get buy => 'Comprar';

  @override
  String get owned => 'Possuído';

  @override
  String get unlocked => 'Desbloqueado';

  @override
  String get purchaseFailed => 'Falha na compra';

  @override
  String get classicDeck => 'Azul clássico';

  @override
  String get classicDeckDesc => 'Cartas padrão de cassino';

  @override
  String get onyxBlackDeck => 'Ônix preto';

  @override
  String get onyxBlackDeckDesc => 'Verso de obsidiana com filigrana dourada';

  @override
  String get price => 'Preço';

  @override
  String get play => 'Jogar';

  @override
  String get cityLondon => 'Londres';

  @override
  String get cityParis => 'Paris';

  @override
  String get cityMoscow => 'Moscou';

  @override
  String get cityCairo => 'Cairo';

  @override
  String get cityMarrakech => 'Marrakech';

  @override
  String get prize => 'Prêmio';

  @override
  String get entryFee => 'Taxa de entrada';
}
