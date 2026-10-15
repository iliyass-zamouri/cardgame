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
  String get home => 'Início';

  @override
  String get shop => 'Loja';

  @override
  String get collection => 'Coleção';

  @override
  String get collectionCards => 'Cartas';

  @override
  String get collectionAvatars => 'Avatares';

  @override
  String ownedCount(int owned, int total) {
    return '$owned/$total adquiridos';
  }

  @override
  String get getMoreInShop => 'Ganhe mais na Loja';

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
      'Termine com o menor total. A partida acaba quando um jogador fica sem cartas ou alguém toca em Encerrar partida.';

  @override
  String get ruleSetupTitle => 'Preparação';

  @override
  String get ruleSetupBody =>
      'Dois jogadores. Cada um recebe quatro cartas viradas para baixo, em fila.';

  @override
  String get ruleOpeningPeekTitle => 'Espiada inicial';

  @override
  String get ruleOpeningPeekBody =>
      'Antes de jogar, toque em Revelar para ver suas duas cartas da esquerda por alguns segundos. Memorize — depois elas viram de novo.';

  @override
  String get ruleYourTurnTitle => 'Sua vez';

  @override
  String get ruleYourTurnBody =>
      'Antes de comprar, se o topo do descarte combina com uma carta que você conhece, toque nela para descartá-la (sua vez continua). Errou = carta de penalidade. Depois compre do baralho.';

  @override
  String get ruleAfterDrawTitle => 'Após comprar';

  @override
  String get ruleAfterDrawBody =>
      'Toque numa das suas cartas para trocar (valor diferente) ou fazer descarte duplo (mesmo valor), ou toque na carta comprada para jogá-la fora. Sua vez termina.';

  @override
  String get ruleSpecialTitle => 'Cartas especiais';

  @override
  String get ruleSpecialBody =>
      'Ao comprar estas cartas, você pode usar o poder delas. Depois, a carta é jogada fora.';

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
      'Quando um jogador fica sem cartas ou alguém toca em Encerrar partida, todas as cartas são reveladas e somadas. Ás = 1, Valete = 11, Dama = 12. Menor total vence; igual = empate.';

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
  String get colWins => 'V';

  @override
  String get colLosses => 'D';

  @override
  String get colDraws => 'E';

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
  String get sapphireFrostDeck => 'Dragão de Safira';

  @override
  String get sapphireFrostDeckDesc =>
      'Nós celtas em safira e ouro em torno de dois dragões';

  @override
  String get imperialJadeDeck => 'Alto Vitoriano';

  @override
  String get imperialJadeDeckDesc =>
      'Filigrana esmeralda numa moldura vitoriana dourada';

  @override
  String get royalCrimsonDeck => 'Carmesim Real';

  @override
  String get royalCrimsonDeckDesc =>
      'Filigrana dourada e figura coroada sobre carmesim';

  @override
  String get neonNightsDeck => 'Noites de Neon';

  @override
  String get neonNightsDeckDesc =>
      'Um pôr do sol synthwave sobre uma grade de neon';

  @override
  String get gildedDeck => 'Ouro 24K';

  @override
  String get gildedDeckDesc => 'Ouro maciço gravado com um diamante lapidado';

  @override
  String get rarityRare => 'Raro';

  @override
  String get rarityEpic => 'Épico';

  @override
  String get rarityLegendary => 'Lendário';

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
  String get cityToronto => 'Toronto';

  @override
  String get cityNewYork => 'Nova York';

  @override
  String get cityTokyo => 'Tóquio';

  @override
  String get prize => 'Prêmio';

  @override
  String get entryFee => 'Taxa de entrada';

  @override
  String get linkGoogleAccount => 'Vincular conta Google';

  @override
  String get linkingGoogle => 'Vinculando…';

  @override
  String get linkGoogleSuccess => 'Conta Google vinculada. Progresso salvo.';

  @override
  String get linkGoogleSwitched => 'Entrou com sua conta Google.';

  @override
  String get saveProgressTitle => 'Salve seu progresso';

  @override
  String get saveProgressBody =>
      'Vincule uma conta Google para manter dinheiro, fichas e ranking se trocar de dispositivo.';

  @override
  String get googleAccountInUseTitle => 'Conta Google em uso';

  @override
  String googleAccountInUseBody(String username) {
    return 'Esta conta Google já pertence a @$username. Mudar para essa conta? O progresso de convidado neste dispositivo será perdido.';
  }

  @override
  String get switchToGoogleAccount => 'Trocar de conta';

  @override
  String get dontAskAgain => 'Não perguntar de novo';

  @override
  String get later => 'Depois';

  @override
  String get youQuit => 'Você desistiu';

  @override
  String get opponentQuit => 'O adversário desistiu';

  @override
  String get matchResultQuit => 'DESISTÊNCIA';

  @override
  String get leaveMatchPenaltyMessage =>
      'Sair agora conta como derrota: você perderá sua aposta e 15 pontos.';

  @override
  String get notEnoughMoneyTitle => 'Dinheiro insuficiente';

  @override
  String notEnoughMoneyMessage(int required, int money) {
    return 'A aposta é $required, mas você tem $money. Troque fichas ou compre mais para a revanche.';
  }

  @override
  String get stakeCovered => 'Saldo suficiente — pronto para a revanche.';

  @override
  String get exchangeChips => 'Trocar fichas';

  @override
  String get buyMoney => 'Comprar dinheiro';

  @override
  String get rematchStarting => 'Cobrando apostas…';

  @override
  String opponentCantAffordRematch(String name) {
    return '$name não pode cobrir a aposta';
  }

  @override
  String get offlineReconnecting => 'Offline · reconectando…';

  @override
  String get getMoreChips => 'Obter fichas';

  @override
  String get notEnoughChipsTitle => 'Fichas insuficientes';

  @override
  String notEnoughChipsMessage(int required, int chips) {
    return 'A aposta é $required fichas, mas você tem $chips. Compre mais fichas para a revanche.';
  }

  @override
  String get buyChips => 'Comprar fichas';

  @override
  String get tutLessonValuesTitle => 'Objetivo e valor das cartas';

  @override
  String get tutLessonDealTitle => 'A distribuição e primeira olhada';

  @override
  String get tutLessonSwapTitle => 'Comprar e trocar';

  @override
  String get tutLessonThrowTitle => 'Jogar uma carta fora';

  @override
  String get tutLessonDoubleTitle => 'Descarte duplo';

  @override
  String get tutLessonMatchTitle => 'Igualar o descarte';

  @override
  String get tutLessonJackTitle => 'Valete: espiar';

  @override
  String get tutLessonQueenTitle => 'Dama: trocar ou embaralhar';

  @override
  String get tutLessonEndTitle => 'Fim e pontuação';

  @override
  String get tutLessonTipsTitle => 'Dicas para vencer';

  @override
  String get tutValuesIntro =>
      'ShadowHand é um jogo de memória para dois. Cada jogador tem cartas viradas para baixo. No fim da partida, todos somam suas cartas — o menor total vence.';

  @override
  String get tutValuesChart =>
      'Cada carta vale pontos. Ás = 1, cartas numéricas = seu número, Valete = 11, Dama = 12, Rei vermelho = 13. As melhores: um Rei preto vale 0 e um Coringa vale −1!';

  @override
  String get tutValuesQuizLowest =>
      'Teste rápido: toque na carta que vale menos pontos.';

  @override
  String get tutValuesQuizLowestWrong =>
      'Quase. O Coringa vale −1 — menos até que um Ás.';

  @override
  String get tutValuesQuizKing =>
      'Aqui há dois Reis. Toque no que vale 0 pontos.';

  @override
  String get tutValuesQuizKingWrong =>
      'Só os Reis pretos (♠ ♣) valem 0. Os Reis vermelhos (♥ ♦) valem 13 — a pior carta do baralho!';

  @override
  String get tutValuesDone =>
      'Perfeito! Seu objetivo: ficar com cartas baixas e se livrar das altas.';

  @override
  String get tutDealIntro =>
      'Cada jogador recebe 4 cartas viradas para baixo, em fila. Você ainda não sabe quais são — nem seu adversário.';

  @override
  String get tutDealReveal =>
      'Antes de começar, você pode dar uma olhada rápida. Toque em Revelar.';

  @override
  String get tutDealMemorize =>
      'Suas duas cartas da esquerda aparecem por alguns segundos. Memorize: um 2 e um 8!';

  @override
  String get tutDealQuiz =>
      'Elas estão viradas de novo. Onde está o seu 2? Toque nele.';

  @override
  String get tutDealQuizWrong =>
      'O 2 era sua primeira carta, bem à esquerda. Neste jogo, memória é tudo!';

  @override
  String get tutDealDone =>
      'Isso! Suas outras duas cartas continuam um mistério — você vai descobrir mais jogando.';

  @override
  String get tutDrawPrompt =>
      'É a sua vez. Toque no baralho para comprar uma carta.';

  @override
  String get tutSwapIntro =>
      'Você lembra das suas duas primeiras cartas: um 2 e um 9. Um 9 custa muitos pontos — vamos trocá-lo.';

  @override
  String get tutSwapPick =>
      'Você comprou um 3. Melhor que o seu 9! Toque no seu 9 (segunda carta) para trocar.';

  @override
  String get tutSwapPickWrong =>
      'Toque no seu 9 — a segunda carta a partir da esquerda. Trocar uma carta desconhecida é uma aposta.';

  @override
  String get tutSwapDone =>
      'O 3 fica virado no lugar do 9, e o 9 vai para o descarte. Sua vez acaba — e você economizou 6 pontos.';

  @override
  String get tutThrowPick =>
      'Ai — um Rei vermelho, vale 13. Você não quer! Toque na carta comprada para jogá-la no descarte.';

  @override
  String get tutThrowWrong =>
      'Não fique com uma carta ruim. Toque na carta comprada (embaixo à esquerda) para jogá-la fora.';

  @override
  String get tutThrowDone =>
      'Jogada fora! Suas cartas não mudaram e sua vez acabou. Jogue fora qualquer carta que não melhore sua mão.';

  @override
  String get tutDoubleIntro => 'Você lembra que sua primeira carta é um 5.';

  @override
  String get tutDoublePick =>
      'Outro 5! Quando a carta comprada tem o mesmo valor de uma das suas, toque na sua carta: as duas são descartadas.';

  @override
  String get tutDoubleWrong => 'Toque no seu 5 — a primeira carta à esquerda.';

  @override
  String get tutDoubleDone =>
      'Os dois 5 saíram e você tem uma carta a menos. Menos cartas, menos pontos — e se suas cartas acabarem, a partida termina.';

  @override
  String get tutMatchIntro =>
      'Você lembra que sua primeira carta é um 7. Agora é a vez do adversário…';

  @override
  String get tutMatchPick =>
      'Seu adversário jogou um 7! Na sua vez, antes de comprar, você pode tocar numa carta do mesmo valor que o topo do descarte para se livrar dela. Toque no seu 7.';

  @override
  String get tutMatchWrong => 'Toque no seu 7 — a primeira carta à esquerda.';

  @override
  String get tutMatchContinue =>
      'Descarte grátis! Igualar não encerra sua vez: você pode igualar de novo e depois ainda compra. Toque no baralho.';

  @override
  String get tutMatchThrow =>
      'Um 8 — nada bom. Toque nele para jogá-lo fora e encerrar sua vez.';

  @override
  String get tutMatchGuess =>
      'Na rodada seguinte, o topo é um 4. Você acha que sua carta do meio pode ser um 4… mas não tem certeza. Vamos ver o que acontece se errar: toque nela.';

  @override
  String get tutMatchPenalty =>
      'Errou — não era um 4. Você recebe uma carta de penalidade virada para baixo, e a carta tocada fica. Só iguale quando tiver certeza!';

  @override
  String get tutJackPeekButton =>
      'Um Valete! Ao comprar um Valete você pode espiar uma carta — sua ou do adversário. Toque em Espiar.';

  @override
  String get tutJackPick =>
      'Agora toque na carta que quer ver. Vamos espiar a segunda carta do adversário.';

  @override
  String get tutJackPickWrong =>
      'Toque na segunda carta do adversário a partir da esquerda.';

  @override
  String get tutJackReveal =>
      'É uma Dama — 12 pontos para ele. Lembre onde ela está: vai se esconder já já.';

  @override
  String get tutJackDone =>
      'Depois de espiar, o Valete é jogado fora automaticamente e sua vez acaba. O poder é opcional: você também pode ficar ou jogar fora um Valete como qualquer carta.';

  @override
  String get tutQueenIntro =>
      'Você lembra que sua segunda carta é um 10. Vamos dá-la ao adversário.';

  @override
  String get tutQueenButtons =>
      'Uma Dama! Você pode escolher. Embaralhar mistura as cartas de um jogador. Trocar troca uma carta sua por uma dele. Toque em Trocar.';

  @override
  String get tutQueenButtonsWrong => 'Nesta lição, toque em Trocar.';

  @override
  String get tutQueenPickYours =>
      'Primeiro toque na carta que quer dar: seu 10, a segunda carta.';

  @override
  String get tutQueenPickYoursWrong =>
      'Toque no seu 10 — sua segunda carta a partir da esquerda.';

  @override
  String get tutQueenPickTheirs =>
      'Agora toque na carta do adversário que quer pegar: a primeira dele.';

  @override
  String get tutQueenPickTheirsWrong =>
      'Toque na primeira carta do adversário, à esquerda.';

  @override
  String get tutQueenDone =>
      'Trocadas! Seu 10 agora é do adversário. Você não vê a carta recebida, mas a maioria vale menos que 10 — bom negócio. A Dama é jogada fora após o uso.';

  @override
  String get tutQueenShuffle =>
      'Embaralhar é a outra opção: misture as cartas do adversário e tudo o que ele memorizou deixa de valer. Você também pode embaralhar as suas.';

  @override
  String get tutEndIntro =>
      'A partida termina de duas formas: um jogador fica sem cartas, ou alguém toca em Encerrar partida.';

  @override
  String get tutEndPress =>
      'Acha que seu total é menor? Qualquer jogador pode tocar em Encerrar partida a qualquer momento. Experimente.';

  @override
  String get tutEndCount =>
      'Todas as cartas são reveladas. Some as suas: 3 + 2 + Rei preto + Coringa. Qual é o seu total?';

  @override
  String get tutEndCountWrong =>
      'Lembre: Rei preto vale 0 e Coringa vale −1. Então 3 + 2 + 0 − 1 = 4.';

  @override
  String get tutEndWinner =>
      'Seu adversário tem 9 + 5 + 7 + 1 = 22. Quem vence?';

  @override
  String get tutEndWinnerWrong => 'O menor total vence: 4 ganha de 22.';

  @override
  String get tutEndDone => 'Você venceu! Se os totais forem iguais, é empate.';

  @override
  String get tutTipMemory =>
      'Dica 1 — Memorize tudo. Cada carta que você vê — no início, ao trocar, com um Valete — é informação. Guarde-a.';

  @override
  String get tutTipKeepLow =>
      'Dica 2 — Fique com Reis pretos e Coringas. Valem 0 e −1: nunca os troque.';

  @override
  String get tutTipDiscard =>
      'Dica 3 — Observe o descarte. Cada carta que o adversário joga é uma chance de igualar de graça.';

  @override
  String get tutTipQueen =>
      'Dica 4 — Use bem as Damas. Dê sua carta mais alta, ou Embaralhe para destruir a memória do adversário.';

  @override
  String get tutTipEnd =>
      'Dica 5 — Encerre na hora certa. Se acha que seu total é menor, toque em Encerrar partida antes que o adversário alcance você.';

  @override
  String get tutChoiceYou => 'Você';

  @override
  String get tutChoiceOpponent => 'Adversário';

  @override
  String get tutChoiceTie => 'Empate';

  @override
  String get tutDeckLabel => 'Baralho';

  @override
  String get tutDiscardLabel => 'Descarte';

  @override
  String get tutDrawnLabel => 'Comprada';

  @override
  String get tutAceLabel => 'Ás';

  @override
  String get tutNumberCardsLabel => '2 a 10';

  @override
  String get tutRedKingLabel => 'Rei vermelho';

  @override
  String get tutTapHighlighted => 'Toque no que está brilhando para continuar.';

  @override
  String tutLessonProgress(int current, int total) {
    return 'Lição $current de $total';
  }

  @override
  String get tutSkip => 'Pular';

  @override
  String get tutLessonDone => 'Lição concluída!';

  @override
  String get tutReplay => 'Repetir';

  @override
  String get tutFinish => 'Concluir';

  @override
  String get tutNextLesson => 'Próxima lição';

  @override
  String get tutCompleteTitle => 'Você está pronto!';

  @override
  String get tutCompleteBody =>
      'Você conhece todas as regras. Treine contra o robô e depois enfrente jogadores reais.';

  @override
  String get tutHubIntro =>
      'Aprenda ShadowHand jogando. Cada lição curta coloca cartas na sua mão e ensina uma regra.';

  @override
  String get tutStartAll => 'Começar tutorial';

  @override
  String get tutContinue => 'Continuar tutorial';

  @override
  String get tutLessonsHeader => 'Lições';

  @override
  String get tutQuickRules => 'Regras rápidas';

  @override
  String get tutQuickRulesSubtitle => 'Todas as regras em 7 cartas';

  @override
  String get tutPromptTitle => 'Novo no ShadowHand?';

  @override
  String get tutPromptBody =>
      'Aprenda a jogar com um tutorial interativo. Leva cerca de 3 minutos.';

  @override
  String get tutPromptLater => 'Agora não';
}
