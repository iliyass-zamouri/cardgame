import 'dart:async';
import 'dart:math';
import 'package:cardgame/models/p_card.dart';
import 'package:cardgame/models/player.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:playing_cards/playing_cards.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

String result = "";
bool revealAll = true;

late double widthSize;
List<PCard> gameCards = [];
List<PCard> gameThrowedCards = [];

Player mainPlayer = Player(cards: []);
Player secondPlayer = Player(cards: []);

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    startNewGame();
  }

  startNewGame() {
    // hiding cards
    revealAll = false;
    // removing results
    result = "";

    // initiating new deck
    gameCards = [];
    // removing the throwed cards
    gameThrowedCards = [];

    // initiating the players
    mainPlayer = Player(cards: []);
    secondPlayer = Player(cards: []);

    // getting new deck
    gameCards = PCardMain.getDeck();
    // sheffling the cards
    gameCards.shuffle();
    // distribusting the cards to players
    for (int i = 0; i < 4; i++) {
      mainPlayer.cards.add(gameCards.removeAt(i));
      secondPlayer.cards.add(gameCards.removeAt(i));
    }

    // choosing the game starter
    if (randomChoice()) {
      mainPlayer.startGame();
    } else {
      secondPlayer.startGame();
    }
  }

  endGame() {
    mainPlayer.total = 0;
    secondPlayer.total = 0;
    for (PCard element in mainPlayer.cards) {
      if (!element.isThrown) {
        mainPlayer.total += element.gameValue;
      }
    }
    for (PCard element in secondPlayer.cards) {
      if (!element.isThrown) {
        secondPlayer.total += element.gameValue;
      }
    }
    setState(() {
      result = "P1> ${mainPlayer.total} | P2> ${secondPlayer.total}";
      revealAll = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // design purposes
    widthSize = MediaQuery.of(context).size.width;
    // robot: player 2
    if (launchRevealed()) {
      playSecondPlayer();
    }
    // shuffle throwed cards back to the game cards except the last one
    if (gameCards.isEmpty) {
      PCard lastCard = gameThrowedCards.removeAt(gameThrowedCards.length - 1);
      gameCards = gameThrowedCards;
      gameThrowedCards = [lastCard];
      gameCards.shuffle();
    }
    // check wheather a player has fished already to stop the game
    if (mainPlayer.gameStarter) {
      if (secondPlayer.isMyTurn()) {
        if (mainPlayer.cards.isEmpty || secondPlayer.cards.isEmpty) {
          endGame();
        }
      } else {
        if (mainPlayer.cards.isNotEmpty) {
          endGame();
        }
      }
    } else if (secondPlayer.gameStarter) {
      if (mainPlayer.isMyTurn()) {
        if (mainPlayer.cards.isEmpty || secondPlayer.cards.isEmpty) {
          endGame();
        }
      } else {
        if (secondPlayer.cards.isEmpty) {
          endGame();
        }
      }
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          result,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          if (!revealAll)
            TextButton(
                onPressed: () {
                  endGame();
                },
                child: const Text(
                  "End Game",
                  style: TextStyle(color: Colors.white),
                )),
          if (revealAll)
            TextButton(
                onPressed: () {
                  startNewGame();
                  setState(() {});
                },
                child: const Text(
                  "New Game",
                  style: TextStyle(color: Colors.white),
                )),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Flexible(
                child: Container(
                  decoration: secondPlayer.isMyTurn()
                      ? const BoxDecoration(
                          gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                              Colors.blue,
                              Colors.transparent,
                              Colors.transparent,
                              Colors.transparent,
                            ]))
                      : const BoxDecoration(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: widthSize * 0.5,
                        child: GridView.count(
                            crossAxisCount: 2,
                            children: secondPlayer.cards
                                .map((e) => e.isThrown
                                    ? Container()
                                    : InkWell(
                                        onTap: () {},
                                        child: FittedBox(
                                          child: SizedBox(
                                            width: widthSize * 0.14,
                                            child: e.isThrown
                                                ? Container()
                                                : PlayingCardView(
                                                    card: e.card,
                                                    // showBack: !e.cardSeen,
                                                    showBack: !revealAll,
                                                  ),
                                          ),
                                        ),
                                      ))
                                .toList()),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    InkWell(
                      onLongPress: () =>
                          showCardsBottomSheet("Game", gameCards),
                      onTap: () {
                        if (mainPlayer.isMyTurn() && launchRevealed()) {
                          // get a card
                          mainPlayer.handCard = gameCards.removeAt(0);
                          if (mainPlayer.handCard!.cardValue == 11) {
                            snackBarJackAction();
                          }
                          if (mainPlayer.handCard!.cardValue == 12) {
                            snackBarQueenAction();
                          }
                          setState(() {});
                        } else {
                          showInSnackBar(launchRevealed()
                              ? "It's not your turn"
                              : "Reveal Cards first");
                        }
                      },
                      child: SizedBox(
                        width: widthSize * 0.15,
                        child: PlayingCardView(
                          card: PlayingCard(Suit.diamonds, CardValue.ace),
                          showBack: true,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: widthSize * 0.15,
                      child: gameThrowedCards.isNotEmpty
                          ? InkWell(
                              onLongPress: () => showCardsBottomSheet(
                                  "Throwed", gameThrowedCards),
                              child: PlayingCardView(
                                card: gameThrowedCards.last.card,
                                showBack: false,
                              ),
                            )
                          : Container(),
                    )
                  ],
                ),
              ),
              Flexible(
                child: Container(
                  width: widthSize,
                  decoration: mainPlayer.isMyTurn()
                      ? const BoxDecoration(
                          gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                              Colors.blue,
                              Colors.transparent,
                              Colors.transparent,
                              Colors.transparent,
                            ]))
                      : const BoxDecoration(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      SizedBox(
                        width: widthSize * 0.5,
                        child: GridView.count(
                            crossAxisCount: 2,
                            children: mainPlayer.cards
                                .map((e) => e.isThrown
                                    ? Container()
                                    : InkWell(
                                        onTap: () {
                                          if (mainPlayer.isMyTurn() &&
                                              launchRevealed()) {
                                            // checking if there is throwned cards and no card in hand
                                            if (gameThrowedCards.isNotEmpty &&
                                                mainPlayer.handCard == null) {
                                              // checking if the card value of the last throwned card is same as clicked card
                                              if (gameThrowedCards
                                                      .last.cardValue ==
                                                  e.cardValue) {
                                                // Throwing the card
                                                mainPlayer
                                                    .cards[mainPlayer.cards
                                                        .indexOf(e)]
                                                    .isThrown = true;
                                                // adding it to the throwned cards
                                                gameThrowedCards.add(e);
                                              } else {
                                                // giving the player a penalty for not getting it right
                                                // by adding a card to he's playing cards
                                                mainPlayer.cards
                                                    .add(gameCards.removeAt(0));
                                              }
                                            } else if (mainPlayer.handCard !=
                                                null) {
                                              if (mainPlayer
                                                      .handCard!.cardValue ==
                                                  e.cardValue) {
                                                // checking if the hand card and the tapped card has same value
                                                mainPlayer
                                                    .cards[mainPlayer.cards
                                                        .indexOf(e)]
                                                    .isThrown = true;
                                                gameThrowedCards.add(
                                                    mainPlayer.cards[mainPlayer
                                                        .cards
                                                        .indexOf(e)]);
                                                gameThrowedCards.add(mainPlayer
                                                    .handCard as PCard);
                                              } else {
                                                // switching the hand card with tapped card
                                                gameThrowedCards.add(
                                                    mainPlayer.cards[mainPlayer
                                                        .cards
                                                        .indexOf(e)]);
                                                mainPlayer.cards[mainPlayer
                                                        .cards
                                                        .indexOf(e)] =
                                                    mainPlayer.handCard
                                                        as PCard;
                                              }
                                              mainPlayer.handCard = null;
                                              mainPlayer.endTurn();
                                              secondPlayer.startTurn();
                                            }
                                            setState(() {});
                                          } else {
                                            showInSnackBar(launchRevealed()
                                                ? "It's not your turn"
                                                : "Reveal your cards first");
                                          }
                                        },
                                        child: FittedBox(
                                          child: SizedBox(
                                            width: widthSize * 0.14,
                                            child: e.isThrown
                                                ? Container()
                                                : PlayingCardView(
                                                    card: e.card,
                                                    // showBack: false,
                                                    showBack: revealAll
                                                        ? false
                                                        : !e.isCardShown,
                                                  ),
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
          if (mainPlayer.handCard != null) ...[
            Positioned(
              left: 4,
              bottom: 4,
              child: SizedBox(
                width: widthSize * 0.2,
                child: InkWell(
                  onTap: () {
                    gameThrowedCards.add(mainPlayer.handCard as PCard);
                    mainPlayer.handCard = null;
                    mainPlayer.endTurn();
                    secondPlayer.startTurn();
                    setState(() {});
                  },
                  child: PlayingCardView(
                    card: mainPlayer.handCard!.card,
                    showBack: false,
                  ),
                ),
              ),
            ),
          ],
          if (secondPlayer.handCard != null)
            Positioned(
              left: 4,
              top: 4,
              child: SizedBox(
                width: widthSize * 0.2,
                child: PlayingCardView(
                  card: secondPlayer.handCard!.card,
                  showBack: true,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: mainPlayer.launchReveal == 'NOT_LAUNCHED'
          ? FloatingActionButton(
              onPressed: () {
                mainPlayer.startLaunchReveal();
                secondPlayer.startLaunchReveal();
                setState(() {});
                Timer(const Duration(seconds: 5), () {
                  mainPlayer.endLaunchReveal();
                  secondPlayer.endLaunchReveal();
                  setState(() {});
                });
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
        onPressed: () => showJackBottomSheet(context),
      ),
      duration: const Duration(seconds: 2),
    ));
  }

  snackBarQueenAction() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text("Switch or Shuffle"),
      action: SnackBarAction(
        label: "Choose",
        onPressed: () => showQueenSwitchBottomSheet(context),
      ),
      duration: const Duration(seconds: 2),
    ));
  }

  bool randomChoice() {
    Random random = Random();
    int randomNumber = random.nextInt(10);
    return randomNumber > 5;
  }

  int randomIndex(int lenght) {
    Random random = Random();
    int rnd = random.nextInt(lenght - 1);
    return rnd;
  }

  playSecondPlayer() {
    if (secondPlayer.isMyTurn()) {
      checkInitialThrow();
      getACardFromDeck();
      Timer(const Duration(seconds: 1), () {
        if (!checkSpecialCards()) {
          checkPossibleThrow();
        }
        if (secondPlayer.handCard != null) {
          gameThrowedCards.add(secondPlayer.handCard as PCard);
          secondPlayer.handCard = null;
        }
        secondPlayer.endTurn();
        mainPlayer.startTurn();
        setState(() {});
      });
    }
  }

  checkSpecialCards() {
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
      //  // going through opponent's cards
      //  for (int i = 0; i < mainPlayer.cards.length; i++) {
      //   // check for unseened cards
      //   if (!mainPlayer.cards[i].cardSeen) {
      //     // see the card
      //     mainPlayer.cards[i].cardSeen = true;
      // return true (Ability used)
      //     return true;
      //   }
      // }
    }
    // check if the card is the queen
    if (secondPlayer.handCard!.cardValue == 12) {
      // going through opponent's cards
      for (int i = 0; i < mainPlayer.cards.length; i++) {
        // check if card is seen
        if (mainPlayer.cards[i].cardSeen) {
          // going through my cards
          for (int j = 0; j < secondPlayer.cards.length; j++) {
            // check for possible switch
            if (mainPlayer.cards[i].gameValue <
                    secondPlayer.cards[j].gameValue &&
                secondPlayer.cards[j].cardSeen) {
              // switching cards
              PCard mainCard = mainPlayer.cards[i];
              mainPlayer.cards[i] = secondPlayer.cards[j];
              secondPlayer.cards[j] = mainCard;
              return true;
            }
          }
        }
      }
      // random choice to shuffle or to switch
      if (randomChoice()) {
        // choosing a random oponent's card
        int rndIndex = randomIndex(mainPlayer.cards.length);
        PCard mainCard = mainPlayer.cards[rndIndex];
        // going throught my cards
        for (int j = 0; j < secondPlayer.cards.length; j++) {
          if (secondPlayer.cards[j].cardSeen &&
              secondPlayer.cards[j].gameValue > 6) {
            mainPlayer.cards[rndIndex] = secondPlayer.cards[j];
            secondPlayer.cards[rndIndex] = mainCard;
            return true;
          }
        }
      } else {
        // shuffle openent's cards
        if (randomChoice()) {
          mainPlayer.cards.shuffle();
          return true;
        }
      }
    }
    return false;
  }

  getACardFromDeck() {
    secondPlayer.handCard = gameCards.removeAt(0);
    secondPlayer.handCard!.cardSeen = true;
  }

  checkPossibleThrow() {
    for (int i = 0; i < secondPlayer.cards.length; i++) {
      // checking if the card is seen and it's not that important
      // and isn't already thrown
      if (secondPlayer.cards[i].cardSeen &&
          !secondPlayer.cards[i].checkImportance(secondPlayer.cards.length) &&
          !secondPlayer.cards[i].isThrown) {
        // checking if the hand is less than seen card
        if (secondPlayer.cards[i].gameValue >
            secondPlayer.handCard!.gameValue) {
          gameThrowedCards.add(secondPlayer.cards[i]);
          secondPlayer.cards[i] = secondPlayer.handCard as PCard;
          secondPlayer.handCard = null;
          break;
          // checking if the card has same number as the last throwned card
        } else if (secondPlayer.cards[i].cardValue ==
            secondPlayer.handCard!.cardValue) {
          gameThrowedCards.add(secondPlayer.cards[i]);
          secondPlayer.cards[i].isThrown = true;
          gameThrowedCards.add(secondPlayer.handCard as PCard);
          secondPlayer.handCard = null;
          break;
        }
      } else if (!secondPlayer.cards[i].cardSeen &&
          !secondPlayer.cards[i].isThrown) {
        gameThrowedCards.add(secondPlayer.cards[i]);
        secondPlayer.cards[i] = secondPlayer.handCard as PCard;
        secondPlayer.handCard = null;
        break;
      }
    }
    return;
  }

  checkInitialThrow() {
    if (gameThrowedCards.isNotEmpty) {
      for (int i = 0; i < secondPlayer.cards.length; i++) {
        // checking if the card is seen and it's not that important
        // and isn't already thrown
        if (secondPlayer.cards[i].cardSeen &&
            !secondPlayer.cards[i].checkImportance(secondPlayer.cards.length) &&
            !secondPlayer.cards[i].isThrown) {
          // checking if the card has same number as the last throwned card
          if (secondPlayer.cards[i].cardValue ==
              gameThrowedCards.last.cardValue) {
            gameThrowedCards.add(secondPlayer.cards[i]);
            secondPlayer.cards[i].isThrown = true;
          }
        }
      }
    }
  }

  bool launchRevealed() {
    return mainPlayer.launchRevealEnded() && secondPlayer.launchRevealEnded();
  }

  Future<void> showJackBottomSheet(BuildContext context) {
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
                        const Text(
                          "See a card",
                          style: TextStyle(fontSize: 18, color: Colors.white),
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
                        const Text(
                          "Opponent's card",
                          style: TextStyle(fontSize: 15, color: Colors.white),
                        ),
                        Flexible(
                          child: SizedBox(
                            width: widthSize,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: widthSize * 0.5,
                                  child: GridView.count(
                                      crossAxisCount: 2,
                                      children: secondPlayer.cards
                                          .map((e) => e.isThrown
                                              ? Container()
                                              : InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      secondPlayer
                                                          .cards[secondPlayer
                                                              .cards
                                                              .indexOf(e)]
                                                          .isCardShown = true;
                                                    });
                                                    Timer(
                                                        const Duration(
                                                            seconds: 1), () {
                                                      setState(() {
                                                        secondPlayer
                                                            .cards[secondPlayer
                                                                .cards
                                                                .indexOf(e)]
                                                            .isCardShown = false;
                                                      });
                                                      Navigator.of(context)
                                                          .pop(true);
                                                    });
                                                  },
                                                  child: FittedBox(
                                                    child: SizedBox(
                                                      width: widthSize * 0.14,
                                                      child: e.isThrown
                                                          ? Container()
                                                          : PlayingCardView(
                                                              card: e.card,
                                                              showBack: !e
                                                                  .isCardShown,
                                                            ),
                                                    ),
                                                  ),
                                                ))
                                          .toList()),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Text(
                          'Your cards',
                          style: TextStyle(fontSize: 15, color: Colors.white),
                        ),
                        Flexible(
                          child: SizedBox(
                            width: widthSize,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: widthSize * 0.5,
                                  child: GridView.count(
                                      crossAxisCount: 2,
                                      children: mainPlayer.cards
                                          .map((e) => e.isThrown
                                              ? Container()
                                              : InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      mainPlayer
                                                          .cards[mainPlayer
                                                              .cards
                                                              .indexOf(e)]
                                                          .isCardShown = true;
                                                    });
                                                    Timer(
                                                        const Duration(
                                                            seconds: 1), () {
                                                      setState(() {
                                                        mainPlayer
                                                            .cards[mainPlayer
                                                                .cards
                                                                .indexOf(e)]
                                                            .isCardShown = false;
                                                      });
                                                      Navigator.of(context)
                                                          .pop(true);
                                                    });
                                                  },
                                                  child: FittedBox(
                                                    child: SizedBox(
                                                      width: widthSize * 0.14,
                                                      child: e.isThrown
                                                          ? Container()
                                                          : PlayingCardView(
                                                              card: e.card,
                                                              showBack: !e
                                                                  .isCardShown,
                                                            ),
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
                  )
                ]),
              ),
            );
          });
        }).then((value) {
      if (value != null) {
        if (value) {
          gameThrowedCards.add(mainPlayer.handCard as PCard);
          mainPlayer.handCard = null;
          mainPlayer.endTurn();
          secondPlayer.startTurn();
          setState(() {});
        }
      }
    });
  }

  Future<void> showQueenSwitchBottomSheet(BuildContext context) {
    int mainSelectedIndex = -1;
    int secondSelectedIndex = -1;
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
                        const Text(
                          "Switch 2 cards",
                          style: TextStyle(fontSize: 18, color: Colors.white),
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
                        const Text(
                          "Opponent's card",
                          style: TextStyle(fontSize: 15, color: Colors.white),
                        ),
                        Flexible(
                          child: SizedBox(
                            width: widthSize,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: widthSize * 0.5,
                                  child: GridView.count(
                                      crossAxisCount: 2,
                                      children: secondPlayer.cards
                                          .map((e) => e.isThrown
                                              ? Container()
                                              : Container(
                                                  color: secondPlayer.cards
                                                              .indexOf(e) ==
                                                          secondSelectedIndex
                                                      ? Colors.blue
                                                      : Colors.transparent,
                                                  child: InkWell(
                                                    onTap: () {
                                                      setState(() {
                                                        secondSelectedIndex =
                                                            secondPlayer.cards
                                                                .indexOf(e);
                                                      });
                                                    },
                                                    child: FittedBox(
                                                      child: SizedBox(
                                                        width: widthSize * 0.14,
                                                        child: PlayingCardView(
                                                          card: e.card,
                                                          showBack:
                                                              !e.isCardShown,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ))
                                          .toList()),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Text(
                          'Your cards',
                          style: TextStyle(fontSize: 15, color: Colors.white),
                        ),
                        Flexible(
                          child: SizedBox(
                            width: widthSize,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: widthSize * 0.5,
                                  child: GridView.count(
                                      crossAxisCount: 2,
                                      children: mainPlayer.cards
                                          .map((e) => e.isThrown
                                              ? Container()
                                              : Container(
                                                  color: mainPlayer.cards
                                                              .indexOf(e) ==
                                                          mainSelectedIndex
                                                      ? Colors.blue
                                                      : Colors.transparent,
                                                  child: InkWell(
                                                    onTap: () {
                                                      setState(() {
                                                        mainSelectedIndex =
                                                            mainPlayer.cards
                                                                .indexOf(e);
                                                      });
                                                    },
                                                    child: FittedBox(
                                                      child: SizedBox(
                                                        width: widthSize * 0.14,
                                                        child: PlayingCardView(
                                                          card: e.card,
                                                          showBack:
                                                              !e.isCardShown,
                                                        ),
                                                      ),
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
                  Container(
                    color: Colors.red[700],
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                            onPressed: () {
                              if (mainSelectedIndex != -1 &&
                                  secondSelectedIndex != -1) {
                                PCard mainCard =
                                    mainPlayer.cards[mainSelectedIndex];
                                mainPlayer.cards[mainSelectedIndex] =
                                    secondPlayer.cards[secondSelectedIndex];
                                secondPlayer.cards[secondSelectedIndex] =
                                    mainCard;
                                Navigator.of(context).pop(true);
                              } else {
                                Navigator.of(context).pop(true);
                              }
                            },
                            icon: const Icon(Icons.check),
                            label: const Text("Done"))
                      ],
                    ),
                  )
                ]),
              ),
            );
          });
        }).then((value) {
      if (value != null) {
        if (value) {
          gameThrowedCards.add(mainPlayer.handCard as PCard);
          mainPlayer.handCard = null;
          mainPlayer.endTurn();
          secondPlayer.startTurn();
          setState(() {});
        }
      }
    });
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
                            width: widthSize,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: widthSize * 0.8,
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
