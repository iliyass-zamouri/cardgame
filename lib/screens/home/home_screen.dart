import 'dart:developer';
import 'package:cardgame/GameState_VM.dart';
import 'package:cardgame/models/p_card.dart';
import 'package:cardgame/models/player.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:playing_cards/playing_cards.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late double widthSize;

  late GameViewModel _gameViewModel;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // design purposes
    widthSize = MediaQuery.of(context).size.width;

    _gameViewModel = Provider.of<GameViewModel>(context);

    final gameState = _gameViewModel.gameState;

    inspect(gameState);

    if (gameState.deck.isEmpty && gameState.players.isEmpty) {
      return const StartGameWidget();
    }

    // robot: player 2
    // if (_gameViewModel.launchedRevealed()) {
    //   playSecondPlayer(_gameViewModel.remotePlayer);
    // }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          gameState.result,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          if (gameState.revealed)
            TextButton(
                onPressed: () {
                  _gameViewModel.newGame();
                },
                child: const Text(
                  "New Game",
                  style: TextStyle(color: Colors.white),
                ))
          else
            TextButton(
                onPressed: () {
                  _gameViewModel.endGame();
                },
                child: const Text(
                  "End Game",
                  style: TextStyle(color: Colors.white),
                )),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.4),
          child: Stack(
            children: [
              Column(
                children: [
                  PlayerHandView(
                    player: _gameViewModel.remotePlayer,
                    revealAll: gameState.revealed,
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        InkWell(
                          onLongPress: () =>
                              showCardsBottomSheet("Game", gameState.deck),
                          onTap: () {
                            _gameViewModel.drawCard(context);
                          },
                          child: SizedBox(
                            width: 120,
                            child: gameState.deck.isEmpty
                                ? Container()
                                : PlayingCardView(
                                    card: gameState.deck.first.card,
                                    showBack: true,
                                  ),
                          ),
                        ),
                        SizedBox(
                          width: 120,
                          child: gameState.throwedCards.isEmpty
                              ? Container()
                              : InkWell(
                                  onLongPress: () => showCardsBottomSheet(
                                      "Throwed", gameState.throwedCards),
                                  child: PlayingCardView(
                                    card: gameState.throwedCards.last.card,
                                    showBack: false,
                                  ),
                                ),
                        )
                      ],
                    ),
                  ),
                  PlayerHandView(
                    player: _gameViewModel.mainPlayer,
                    revealAll: gameState.revealed,
                    onTap: (e) {
                      _gameViewModel.tapCard(context, e);
                    },
                  ),
                ],
              ),
              if (_gameViewModel.mainPlayer.handCard != null) ...[
                Positioned(
                  left: 4,
                  bottom: 4,
                  child: SizedBox(
                    width: 120,
                    child: InkWell(
                      onTap: () {
                        _gameViewModel.throwHandCard();
                      },
                      child: PlayingCardView(
                        card: _gameViewModel.mainPlayer.handCard!.card,
                        showBack: false,
                      ),
                    ),
                  ),
                ),
              ],
              if (_gameViewModel.remotePlayer.handCard != null)
                Positioned(
                  left: 4,
                  top: 4,
                  child: SizedBox(
                    width: 40,
                    child: PlayingCardView(
                      card: _gameViewModel.remotePlayer.handCard!.card,
                      showBack: true,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton:
          _gameViewModel.mainPlayer.launchReveal == 'NOT_LAUNCHED'
              ? FloatingActionButton(
                  onPressed: () {
                    _gameViewModel.launch();
                  },
                  child: const Icon(CupertinoIcons.eye),
                )
              : const SizedBox.shrink(),
    );
  }

  showInSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(milliseconds: 500),
    ));
  }

  snackBarJackAction() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text("Check a hidden card!"),
      action: SnackBarAction(
        label: "Reveal",
        onPressed: () {},
      ),
      duration: const Duration(seconds: 2),
    ));
  }

  snackBarQueenAction() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text("Switch or Shuffle"),
      action: SnackBarAction(
        label: "Choose",
        onPressed: () {},
      ),
      duration: const Duration(seconds: 2),
    ));
  }

  // playSecondPlayer(Player secondPlayer) {
  //   if (secondPlayer.isMyTurn()) {
  //     checkInitialThrow(secondPlayer);
  //     _gameViewModel.drawCard(context, true);
  //     Timer(const Duration(seconds: 1), () {
  //       if (!checkSpecialCards(secondPlayer)) {
  //         checkPossibleThrow(secondPlayer);
  //       }
  //       _gameViewModel.throwHandCard();
  //     });
  //   }
  // }

  checkSpecialCards(Player secondPlayer) {
    // check if the card is the jack
    if (secondPlayer.handCard!.cardValue == 11) {
      // going through the cards
      for (int i = 0; i < secondPlayer.cards.length; i++) {
        // if the card is unseened
        if (!secondPlayer.cards[i].cardSeen) {
          // see the card
          secondPlayer.cards[i].cardSeen = true;
          // return true (Ability used)
          return true;
        }
      }
      // going through opponent's cards
      for (int i = 0; i < _gameViewModel.mainPlayer.cards.length; i++) {
        // check for unseened cards
        if (!_gameViewModel.mainPlayer.cards[i].cardSeen) {
          // see the card
          _gameViewModel.mainPlayer.cards[i].cardSeen = true;
          // return true (Ability used)
          return true;
        }
      }
    }
    // check if the card is the queen
    if (secondPlayer.handCard!.cardValue == 12) {
      // going through opponent's cards
      for (int i = 0; i < _gameViewModel.mainPlayer.cards.length; i++) {
        // check if card is seen
        if (_gameViewModel.mainPlayer.cards[i].cardSeen) {
          // going through my cards
          for (int j = 0; j < secondPlayer.cards.length; j++) {
            // check for possible switch
            if (_gameViewModel.mainPlayer.cards[i].gameValue <
                    secondPlayer.cards[j].gameValue &&
                secondPlayer.cards[j].cardSeen &&
                !secondPlayer.cards[j].isThrown) {
              // switching cards
              PCard mainCard = _gameViewModel.mainPlayer.cards[i];
              _gameViewModel.mainPlayer.cards[i] = secondPlayer.cards[j];
              secondPlayer.cards[j] = mainCard;
              return true;
            }
          }
        }
      }
      // random choice to shuffle or to switch
      // if (randomChoice()) {
      //   // choosing a random oponent's card
      //   int rndIndex = randomIndex(mainPlayer.cards.length);
      //   PCard mainCard = mainPlayer.cards[rndIndex];
      //   // going throught my cards
      //   for (int j = 0; j < secondPlayer.cards.length; j++) {
      //     if (secondPlayer.cards[j].cardSeen &&
      //         secondPlayer.cards[j].gameValue > 6) {
      //       mainPlayer.cards[rndIndex] = secondPlayer.cards[j];
      //       secondPlayer.cards[rndIndex] = mainCard;
      //       return true;
      //     }
      //   }
      // } else {
      //   // shuffle openent's cards
      //   if (randomChoice()) {
      //     mainPlayer.cards.shuffle();
      //     return true;
      //   }
      // }
    }
    return false;
  }

  checkPossibleThrow(Player secondPlayer) {
    for (int i = 0; i < secondPlayer.cards.length; i++) {
      // checking if the card is seen and it's not that important
      // and isn't already thrown
      if (secondPlayer.cards[i].cardSeen &&
          !secondPlayer.cards[i].checkImportance(secondPlayer.cards.length) &&
          !secondPlayer.cards[i].isThrown) {
        // checking if the hand is less than seen card
        if (secondPlayer.cards[i].gameValue >
            secondPlayer.handCard!.gameValue) {
          _gameViewModel.gameState.throwedCards.add(secondPlayer.cards[i]);
          secondPlayer.cards[i] = secondPlayer.handCard as PCard;
          secondPlayer.handCard = null;
          break;
          // checking if the card has same number as the last throwned card
        } else if (secondPlayer.cards[i].cardValue ==
            secondPlayer.handCard!.cardValue) {
          _gameViewModel.gameState.throwedCards.add(secondPlayer.cards[i]);
          secondPlayer.cards[i].isThrown = true;
          _gameViewModel.gameState.throwedCards
              .add(secondPlayer.handCard as PCard);
          secondPlayer.handCard = null;
          break;
        }
      } else if (!secondPlayer.cards[i].cardSeen &&
          !secondPlayer.cards[i].isThrown) {
        _gameViewModel.gameState.throwedCards.add(secondPlayer.cards[i]);
        secondPlayer.cards[i] = secondPlayer.handCard as PCard;
        secondPlayer.handCard = null;
        break;
      }
    }
    return;
  }

  checkInitialThrow(Player secondPlayer) {
    if (_gameViewModel.gameState.throwedCards.isNotEmpty) {
      for (int i = 0; i < secondPlayer.cards.length; i++) {
        // checking if the card is seen and it's not that important
        // and isn't already thrown
        if (secondPlayer.cards[i].cardSeen &&
            !secondPlayer.cards[i].checkImportance(secondPlayer.cards.length) &&
            !secondPlayer.cards[i].isThrown) {
          // checking if the card has same number as the last throwned card
          if (secondPlayer.cards[i].cardValue ==
              _gameViewModel.gameState.throwedCards.last.cardValue) {
            _gameViewModel.gameState.throwedCards.add(secondPlayer.cards[i]);
            secondPlayer.cards[i].isThrown = true;
          }
        }
      }
    }
  }

  showCardsBottomSheet(String title, List<PCard> cards) {
    return showModalBottomSheet(
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (BuildContext context, setState) {
            return ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
              child: Container(
                color: Colors.black,
                child: Column(children: [
                  Container(
                    margin: const EdgeInsets.only(left: 20, top: 40),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "$title Cards (${cards.length})",
                          style: const TextStyle(
                              fontSize: 18, color: Colors.white),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.clear,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Flexible(
                          child: SizedBox(
                            width: 140,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 120,
                                  child: GridView.count(
                                      crossAxisCount: 4,
                                      children: cards
                                          .map((e) => FittedBox(
                                                child: SizedBox(
                                                  width: widthSize * 0.14,
                                                  child: PlayingCardView(
                                                    card: e.card,
                                                    showBack: false,
                                                  ),
                                                ),
                                              ))
                                          .toList()),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            );
          });
        });
  }
}

class PlayerHandView extends StatelessWidget {
  final Player player;
  final bool revealAll;
  final Function(PCard)? onTap;
  const PlayerHandView(
      {Key? key, required this.player, required this.revealAll, this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        width: 220,
        decoration: player.isMyTurn()
            ? BoxDecoration(
                gradient: LinearGradient(
                    begin: player.isMainPlayer
                        ? Alignment.bottomCenter
                        : Alignment.topCenter,
                    end: player.isMainPlayer
                        ? Alignment.topCenter
                        : Alignment.bottomCenter,
                    colors: const [
                    Colors.blue,
                    Colors.transparent,
                    Colors.transparent,
                    Colors.transparent,
                  ]))
            : const BoxDecoration(),
        child: Center(
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            reverse: !player.isMainPlayer,
            children: player.cards
                .map(
                  (e) => e.isThrown
                      ? Container()
                      : InkWell(
                          onTap: () => onTap!(e),
                          child: FittedBox(
                            child: SizedBox(
                              width: 140,
                              child: e.isThrown
                                  ? Container()
                                  : PlayingCardView(
                                      card: e.card,
                                      showBack: false,
                                      // showBack: player.isMainPlayer
                                      //     ? (revealAll ? false : !e.isCardShown)
                                      //     : !revealAll,
                                    ),
                            ),
                          ),
                        ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class StartGameWidget extends StatefulWidget {
  const StartGameWidget({Key? key}) : super(key: key);

  @override
  State<StartGameWidget> createState() => _StartGameWidgetState();
}

class _StartGameWidgetState extends State<StartGameWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const Text(
              "Card Game",
              style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<GameViewModel>().newGame();
              },
              child: const Text("New Game",
                  style: TextStyle(fontSize: 20, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
