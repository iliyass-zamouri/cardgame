import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:math';
import 'package:shadow_hand/socket_service.dart';
import 'package:flutter/material.dart';
import 'package:shadow_hand/models/p_card.dart';
import 'package:shadow_hand/models/player.dart';
import 'package:shadow_hand/models/gamestate.dart';

class GameViewModel extends ChangeNotifier {
  final GameState _gameState;
  final SocketService _socketService;
  final ValueNotifier<String?> roomCodeNotifier = ValueNotifier<String?>(null);

  GameViewModel()
      : _gameState = GameState(
          deck: [],
          throwedCards: [],
          players: [],
          currentPlayerIndex: 0,
        ),
        _socketService = SocketService() {
    // _dealInitialCards();
    // _startGame();
    _listenToSocket();
  }

  GameState get gameState => _gameState;

  Player get mainPlayer => _gameState.players.isNotEmpty ? _gameState.players[0] : Player.main();

  Player get remotePlayer => _gameState.players.length > 1 ? _gameState.players[1] : Player.remote();

  void _listenToSocket() {
    _socketService.stream.listen((message) {
      Map<String, dynamic> data = jsonDecode(message);
      switch (data['action']) {
        case GameActions.init:
          _remoteNewGame(data['deck'], data['throwedCards'], data['players'],
              data['currentPlayerIndex']);
          break;
        case GameActions.launch:
          _launchRemote();
          break;
        case GameActions.throwCard:
          _remoteThrowCard(PCard.fromTag(data['card']), data['hand']);
          break;
        case GameActions.draw:
          _remoteDrawCard();
          break;
        case GameActions.swap:
          _remoteSwapCard(
              PCard.fromTag(data['oldCard']), PCard.fromTag(data['newCard']));
          break;
        case GameActions.next:
          _nextTurn(true);
          break;
        case GameActions.penalty:
          _remotePenalty();
          break;
        case GameActions.restock:
          _reStock(data['deck'], data['throwedCards']);
          break;
        case GameActions.end:
          dev.log('Game Ended');
          endGame(true);
          break;
      }
    });
  }

  void sendAction(String action, [Map<String, dynamic>? payload]) {
    Map<String, dynamic> data = {'action': action, ...?payload};
    _socketService.send(jsonEncode(data));
  }

  newGame() {
    _gameState.deck = PCard.generateDeck();
    _gameState.throwedCards = [];
    _gameState.revealed = false;
    _gameState.players = [];
    _gameState.currentPlayerIndex = 0;
    notifyListeners();
  }

  void setRoomCode(String? roomCode) {
    roomCodeNotifier.value = roomCode;
  }

  void _remoteNewGame(List<dynamic> deck, List<dynamic> throwedCards,
      List<dynamic> players, int currentPlayerIndex) {
    _gameState.deck = deck.map((e) => PCard.fromTag(e)).toList();
    _gameState.throwedCards =
        throwedCards.map((e) => PCard.fromTag(e)).toList();
    _gameState.players = [
      Player.fromMap(players[1], true),
      Player.fromMap(players[0]),
    ];
    _gameState.currentPlayerIndex = currentPlayerIndex;
    _gameState.revealed = false;
    notifyListeners();
  }

  endGame([bool remote = false]) {
    _gameState.players.map((p) {
      p.total = 0;
      return p;
    });
    for (PCard element in _gameState.players[0].cards) {
      if (!element.isThrown) {
        _gameState.players[0].total += element.gameValue;
      }
    }
    for (PCard element in _gameState.players[1].cards) {
      if (!element.isThrown) {
        _gameState.players[1].total += element.gameValue;
      }
    }
    _gameState.result =
        "P1> ${_gameState.players[0].total} P2> ${_gameState.players[1].total}";
    _gameState.revealed = true;
    if (!remote) {
      sendAction(GameActions.end);
    }
    notifyListeners();
    return true;
  }

  _startGame() {
    if (_randomChoice()) {
      _gameState.players[0].startGame();
    } else {
      _gameState.players[1].startGame();
    }
    notifyListeners();
  }

  // TODO: to be removed
  bool _randomChoice() {
    Random random = Random();
    int randomNumber = random.nextInt(10);
    return randomNumber > 5;
  }

  void _dealInitialCards() {
    for (int i = 0; i < 4; i++) {
      for (Player player in _gameState.players) {
        player.cards.add(_gameState.deck.removeLast());
      }
    }
  }

  launch() {
    _gameState.players[0].startLaunchReveal();
    sendAction(GameActions.launch);
    Timer(const Duration(seconds: 5), () {
      _gameState.players[0].endLaunchReveal();
      notifyListeners();
    });
    notifyListeners();
  }

  _launchRemote() {
    dev.log('Remote Launched Reveal');
    _gameState.players[1].endLaunchReveal();
    notifyListeners();
  }

  _remotePenalty() {
    _gameState.players[1].cards.add(_gameState.deck.removeAt(0));
    notifyListeners();
  }

  void tapCard(BuildContext ctx, PCard tapped) {
    var currentPlayer = _gameState.players[0];
    if (currentPlayer.isMyTurn() && _gameState.launchedRevealed()) {
      if (_gameState.throwedCards.isNotEmpty &&
          currentPlayer.handCard == null) {
        if (_gameState.throwedCards.last.cardValue == tapped.cardValue) {
          currentPlayer.cards[currentPlayer.cards.indexOf(tapped)].isThrown =
              true;
          _gameState.throwedCards.add(tapped);
          sendAction(GameActions.throwCard, {
            'card': tapped.tag,
            'hand': false,
          });
        } else {
          currentPlayer.cards.add(_gameState.deck.removeAt(0));
          sendAction(GameActions.penalty);
        }
      } else if (currentPlayer.handCard != null) {
        if (currentPlayer.handCard!.cardValue == tapped.cardValue) {
          // throw player card
          currentPlayer.cards[currentPlayer.cards.indexOf(tapped)].isThrown =
              true;
          _gameState.throwedCards
              .add(currentPlayer.cards[currentPlayer.cards.indexOf(tapped)]);
          sendAction(GameActions.throwCard, {
            'card': tapped.tag,
            'hand': false,
          });
          // throw hand card
          _gameState.throwedCards.add(currentPlayer.handCard as PCard);
          sendAction(GameActions.throwCard,
              {'card': currentPlayer.handCard!.tag, 'hand': true});
        } else {
          // throw player card
          _gameState.throwedCards
              .add(currentPlayer.cards[currentPlayer.cards.indexOf(tapped)]);
          // swap with hand card
          currentPlayer.cards[currentPlayer.cards.indexOf(tapped)] =
              currentPlayer.handCard as PCard;
          sendAction(GameActions.swap,
              {'oldCard': tapped.tag, 'newCard': currentPlayer.handCard!.tag});
        }
        currentPlayer.handCard = null;
        _nextTurn();
      }
    } else {
      showInSnackBar(
          ctx,
          _gameState.launchedRevealed()
              ? "It's not your turn"
              : "Reveal your cards first");
    }
    notifyListeners();
  }

  void _remoteSwapCard(PCard oldCard, PCard newCard) {
    var remotePlayer = _gameState.players[1];
    int oldCardIndex =
        remotePlayer.cards.indexWhere((c) => c.tag == oldCard.tag);
    if (oldCardIndex != -1) {
      remotePlayer.cards[oldCardIndex] = newCard;
      _gameState.throwedCards.add(oldCard);
      remotePlayer.handCard = null;
      notifyListeners();
    }
  }

  void drawCard(BuildContext ctx) {
    var currentPlayer = _gameState.players[0];
    if (_gameState.deck.isNotEmpty && currentPlayer.handCard == null) {
      if (currentPlayer.isMyTurn() && _gameState.launchedRevealed()) {
        currentPlayer.handCard = _gameState.deck.removeAt(0);
        if (currentPlayer.handCard!.cardValue == 11) {
          //snackBarJackAction();
        }
        if (currentPlayer.handCard!.cardValue == 12) {
          // snackBarQueenAction();
        }
        sendAction(GameActions.draw);
      } else {
        showInSnackBar(
            ctx,
            _gameState.launchedRevealed()
                ? "It's not your turn"
                : _gameState.remoteLaunchedRevealed()
                    ? "Reveal Cards first"
                    : "Wait for remote player to reveal his cards");
      }
      _gameState.players[0] = currentPlayer;
      notifyListeners();
    }
  }

  showInSnackBar(BuildContext ctx, String message) {
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(milliseconds: 500),
    ));
  }

  throwHandCard() {
    if (mainPlayer.handCard == null) {
      return;
    }
    _gameState.throwedCards.add(_gameState.players[0].handCard as PCard);
    _gameState.players[0].handCard = null;
    sendAction(GameActions.throwCard,
        {'card': _gameState.throwedCards.last.tag, 'hand': true});
    _nextTurn();
  }

  _nextTurn([bool remote = false]) {
    _gameState.nextTurn(remote, () {
      sendAction(GameActions.next);
      _checkRestock();
    });
    notifyListeners();
  }

  _checkRestock() {
    if (_gameState.deck.isEmpty) {
      _gameState.restock();
      sendAction(GameActions.restock, {
        'deck': _gameState.deck.map((e) => e.tag).toList(),
        'throwedCards': _gameState.throwedCards.map((e) => e.tag).toList(),
      });
    }
  }

  _reStock([List<dynamic>? deck, List<dynamic>? throwedCards]) {
    _gameState.restock();
    notifyListeners();
  }

  _checkEnd() {
    if (_gameState.players[0].gameStarter) {
      if (_gameState.players[1].isMyTurn()) {
        if (_gameState.players[0].cards.isEmpty ||
            _gameState.players[1].cards.isEmpty) {
          return endGame();
        }
      } else {
        if (_gameState.players[0].cards.isNotEmpty) {
          return endGame();
        }
      }
    } else if (_gameState.players[1].gameStarter) {
      if (_gameState.players[0].isMyTurn()) {
        if (_gameState.players[0].cards.isEmpty ||
            _gameState.players[1].cards.isEmpty) {
          return endGame();
        }
      } else {
        if (_gameState.players[1].cards.isEmpty) {
          return endGame();
        }
      }
    }
    return false;
  }

  void _remoteThrowCard(PCard card, bool hand) {
    _gameState.remoteThrowCard(card, hand);
    notifyListeners();
  }

  void _remoteDrawCard() {
    _gameState.players[1].drawCard(_gameState.deck.removeAt(0));
    notifyListeners();
  }
}
