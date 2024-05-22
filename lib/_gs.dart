// import 'dart:math';

// import 'package:flutter/material.dart';
// import 'package:cardgame/models/p_card.dart';
// import 'package:cardgame/models/player.dart';
// import 'package:cardgame/models/gamestate.dart';
// import 'package:playing_cards/playing_cards.dart';

// class GameViewModel extends ChangeNotifier {
//   final GameState _gameState;

//   GameViewModel()
//       : _gameState = GameState(
//           deck: _generateDeck(),
//           throwedCards: [],
//           players: [Player(cards: [], isMainPlayer: true), Player(cards: [])],
//           currentPlayerIndex: 0,
//         ) {
//     _dealInitialCards();
//     _startGame();
//   }

//   GameState get gameState => _gameState;

//   Player get mainPlayer => _gameState.players[0];

//   Player get robotPlayer => _gameState.players[1];

//   newGame() {
//     _gameState.deck = _generateDeck();
//     _gameState.throwedCards = [];
//     _gameState.revealed = false;
//     _gameState.players = [
//       Player(cards: [], isMainPlayer: true),
//       Player(cards: []),
//     ];
//     _gameState.currentPlayerIndex = 0;
//     _dealInitialCards();
//     _startGame();
//     notifyListeners();
//   }

//   endGame() {
//     _gameState.players.map((p) {
//       p.total = 0;
//       return p;
//     });
//     for (PCard element in _gameState.players[0].cards) {
//       if (!element.isThrown) {
//         _gameState.players[0].total += element.gameValue;
//       }
//     }
//     for (PCard element in _gameState.players[1].cards) {
//       if (!element.isThrown) {
//         _gameState.players[1].total += element.gameValue;
//       }
//     }
//     _gameState.result =
//         "P1> ${_gameState.players[0].total} P2> ${_gameState.players[1].total}";
//     _gameState.revealed = true;
//     notifyListeners();
//     return true;
//   }

//   _startGame() {
//     if (_randomChoice()) {
//       _gameState.players[0].startGame();
//     } else {
//       _gameState.players[1].startGame();
//     }
//     notifyListeners();
//   }

//   bool _randomChoice() {
//     Random random = Random();
//     int randomNumber = random.nextInt(10);
//     return randomNumber > 5;
//   }

//   int _randomIndex(int lenght) {
//     Random random = Random();
//     int rnd = random.nextInt(lenght - 1);
//     return rnd;
//   }

//   static List<PCard> _generateDeck() {
//     List<PCard> deck = _getDeck();
//     deck.shuffle();
//     return deck;
//   }

//   static List<PCard> _getDeck() {
//     List<PCard> cards = [];
//     for (int i = 1; i < 14; i++) {
//       cards.add(PCard(
//           tag: "A$i",
//           card: PlayingCard(Suit.clubs, _getCardValueByIndex(i)),
//           gameValue: _getCardGameValue(i, Suit.clubs),
//           cardValue: i));
//       cards.add(PCard(
//           tag: "B$i",
//           card: PlayingCard(Suit.diamonds, _getCardValueByIndex(i)),
//           gameValue: _getCardGameValue(i, Suit.diamonds),
//           cardValue: i));
//       cards.add(PCard(
//           tag: "C$i",
//           card: PlayingCard(Suit.hearts, _getCardValueByIndex(i)),
//           gameValue: _getCardGameValue(i, Suit.hearts),
//           cardValue: i));
//       cards.add(PCard(
//           tag: "D$i",
//           card: PlayingCard(Suit.spades, _getCardValueByIndex(i)),
//           gameValue: _getCardGameValue(i, Suit.spades),
//           cardValue: i));
//     }
//     cards.add(PCard(
//         tag: "A14",
//         card: PlayingCard(Suit.diamonds, CardValue.joker_1),
//         gameValue: -1,
//         cardValue: 14));
//     cards.add(PCard(
//         tag: "B14",
//         card: PlayingCard(Suit.spades, CardValue.joker_2),
//         gameValue: -1,
//         cardValue: 14));

//     return cards;
//   }

//   static _getCardGameValue(int index, Suit suit) {
//     if (index == 13 && suit == Suit.spades) {
//       return 0;
//     }
//     if (index == 13 && suit == Suit.clubs) {
//       return 0;
//     }
//     return index;
//   }

//   static CardValue _getCardValueByIndex(int index) {
//     switch (index) {
//       case 1:
//         return CardValue.ace;
//       case 2:
//         return CardValue.two;
//       case 3:
//         return CardValue.three;
//       case 4:
//         return CardValue.four;
//       case 5:
//         return CardValue.five;
//       case 6:
//         return CardValue.six;
//       case 7:
//         return CardValue.seven;
//       case 8:
//         return CardValue.eight;
//       case 9:
//         return CardValue.nine;
//       case 10:
//         return CardValue.ten;
//       case 11:
//         return CardValue.jack;
//       case 12:
//         return CardValue.queen;
//       default:
//         return CardValue.king;
//     }
//   }

//   void _dealInitialCards() {
//     for (int i = 0; i < 4; i++) {
//       for (Player player in _gameState.players) {
//         player.cards.add(_gameState.deck.removeLast());
//       }
//     }
//   }

//   void tapCard(BuildContext ctx, PCard tapped) {
//     var currentPlayer = _gameState.players[_gameState.currentPlayerIndex];
//     if (currentPlayer.isMyTurn() && launchedRevealed()) {
//       // checking if there is throwned cards and no card in hand
//       if (_gameState.throwedCards.isNotEmpty &&
//           currentPlayer.handCard == null) {
//         // checking if the card value of the last throwned card is same as clicked card
//         if (_gameState.throwedCards.last.cardValue == tapped.cardValue) {
//           // Throwing the card
//           currentPlayer.cards[currentPlayer.cards.indexOf(tapped)].isThrown =
//               true;
//           // adding it to the throwned cards
//           _gameState.throwedCards.add(tapped);
//         } else {
//           // giving the player a penalty for not getting it right
//           // by adding a card to he's playing cards
//           currentPlayer.cards.add(_gameState.deck.removeAt(0));
//         }
//       } else if (currentPlayer.handCard != null) {
//         if (currentPlayer.handCard!.cardValue == tapped.cardValue) {
//           // checking if the hand card and the tapped card has same value
//           currentPlayer.cards[currentPlayer.cards.indexOf(tapped)].isThrown =
//               true;
//           _gameState.throwedCards
//               .add(currentPlayer.cards[currentPlayer.cards.indexOf(tapped)]);
//           _gameState.throwedCards.add(currentPlayer.handCard as PCard);
//         } else {
//           // switching the hand card with tapped card
//           _gameState.throwedCards
//               .add(currentPlayer.cards[currentPlayer.cards.indexOf(tapped)]);
//           currentPlayer.cards[currentPlayer.cards.indexOf(tapped)] =
//               currentPlayer.handCard as PCard;
//         }
//         currentPlayer.handCard = null;
//         _nextTurn();
//       }
//     } else {
//       showInSnackBar(
//           ctx,
//           launchedRevealed()
//               ? "It's not your turn"
//               : "Reveal your cards first");
//     }
//   }

//   void drawCard(BuildContext ctx, [bool isRobot = false]) {
//     var currentPlayer = _gameState.players[_gameState.currentPlayerIndex];
//     if (isRobot) {
//       currentPlayer.handCard = _gameState.deck.removeAt(0);
//       currentPlayer.handCard!.cardSeen = true;
//       _gameState.players[_gameState.currentPlayerIndex] = currentPlayer;
//       notifyListeners();
//       return;
//     }
//     if (_gameState.deck.isNotEmpty) {
//       if (currentPlayer.isMyTurn() && launchedRevealed()) {
//         // get a card
//         currentPlayer.handCard = _gameState.deck.removeAt(0);
//         if (currentPlayer.handCard!.cardValue == 11) {
//           //snackBarJackAction();
//         }
//         if (currentPlayer.handCard!.cardValue == 12) {
//           // snackBarQueenAction();
//         }
//       } else {
//         showInSnackBar(ctx,
//             launchedRevealed() ? "It's not your turn" : "Reveal Cards first");
//       }
//       _gameState.players[_gameState.currentPlayerIndex] = currentPlayer;
//       notifyListeners();
//     }
//   }

//   showInSnackBar(BuildContext ctx, String message) {
//     ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
//       content: Text(message),
//       duration: const Duration(milliseconds: 500),
//     ));
//   }

//   throwHandCard() {
//     if (_gameState.players[_gameState.currentPlayerIndex].handCard == null) {
//       return;
//     }
//     _gameState.throwedCards.add(
//         _gameState.players[_gameState.currentPlayerIndex].handCard as PCard);
//     _gameState.players[_gameState.currentPlayerIndex].handCard = null;
//     _nextTurn();
//   }

//   void _nextTurn() {
//     if (_checkEnd()) return;
//     _gameState.players[_gameState.currentPlayerIndex].endTurn();
//     int nextPlayerIndex =
//         (_gameState.currentPlayerIndex + 1) % _gameState.players.length;
//     _gameState.currentPlayerIndex = nextPlayerIndex;
//     _gameState.players[nextPlayerIndex].startTurn();
//     notifyListeners();
//   }

//   bool launchedRevealed() {
//     return _gameState.players
//             .indexWhere((element) => element.launchRevealEnded()) !=
//         -1;
//   }

//   _reStock() {
//     if (_gameState.deck.isEmpty) {
//       PCard lastCard =
//           _gameState.throwedCards.removeAt(_gameState.throwedCards.length - 1);
//       _gameState.deck = _gameState.throwedCards.map((e) {
//         e.isThrown = false;
//         return e;
//       }).toList();
//       _gameState.throwedCards = [lastCard];
//       _gameState.deck.shuffle();
//       notifyListeners();
//     }
//   }

//   _checkEnd() {
//     // check wheather a player has fished already to stop the game
//     if (_gameState.players[0].gameStarter) {
//       if (_gameState.players[1].isMyTurn()) {
//         if (_gameState.players[0].cards.isEmpty ||
//             _gameState.players[1].cards.isEmpty) {
//           return endGame();
//         }
//       } else {
//         if (_gameState.players[0].cards.isNotEmpty) {
//           return endGame();
//         }
//       }
//     } else if (_gameState.players[1].gameStarter) {
//       if (_gameState.players[0].isMyTurn()) {
//         if (_gameState.players[0].cards.isEmpty ||
//             _gameState.players[1].cards.isEmpty) {
//           return endGame();
//         }
//       } else {
//         if (_gameState.players[1].cards.isEmpty) {
//           return endGame();
//         }
//       }
//     }
//     return false;
//   }
// }
