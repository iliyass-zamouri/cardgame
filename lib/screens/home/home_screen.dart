import 'dart:developer';
import 'package:shadow_hand/GameState_VM.dart';
import 'package:shadow_hand/models/p_card.dart';
import 'package:shadow_hand/models/player.dart';
import 'package:shadow_hand/screens/home/game_starter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:patterns_canvas/patterns_canvas.dart';
import 'package:playing_cards/playing_cards.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  final int userId;
  final String username;
  final int totalPoints;
  final int wins;
  final int losses;
  final int currentStreak;

  const HomeScreen({
    Key? key,
    required this.userId,
    required this.username,
    required this.totalPoints,
    required this.wins,
    required this.losses,
    required this.currentStreak,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late double widthSize;
  late GameViewModel _gameViewModel;
  String? _roomCode;

  @override
  void initState() {
    super.initState();
    
    // Listen for room code changes from GameViewModel
    _gameViewModel = Provider.of<GameViewModel>(context, listen: false);
    _gameViewModel.roomCodeNotifier.addListener(_onRoomCodeChanged);
  }

  @override
  void dispose() {
    _gameViewModel.roomCodeNotifier.removeListener(_onRoomCodeChanged);
    super.dispose();
  }

  void _onRoomCodeChanged() {
    if (mounted) {
      setState(() {
        _roomCode = _gameViewModel.roomCodeNotifier.value;
      });
    }
  }

  Widget _buildRoomCodeOverlay() {
    return Positioned(
      top: 50,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Room Code',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    _gameViewModel.setRoomCode(null);
                  },
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              _roomCode ?? '',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Share this code with your friend',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // Copy room code to clipboard
                    // TODO: Implement clipboard functionality
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    _gameViewModel.setRoomCode(null);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // design purposes
    widthSize = MediaQuery.of(context).size.width;

    _gameViewModel = Provider.of<GameViewModel>(context);

    final gameState = _gameViewModel.gameState;

    inspect(gameState);

    if (gameState.deck.isEmpty && gameState.players.isEmpty) {
      return StartGameWidget(
        userId: widget.userId,
        username: widget.username,
        totalPoints: widget.totalPoints,
      );
    }

    // robot: player 2
    // if (_gameViewModel.launchedRevealed()) {
    //   playSecondPlayer(_gameViewModel.remotePlayer);
    // }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Stack(
          children: [
            Column(
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.4,
                      maxHeight: MediaQuery.of(context).size.height * 0.4),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: PlayerHandView(
                      player: _gameViewModel.remotePlayer,
                      revealAll: gameState.revealed,
                    ),
                  ),
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
                              : DecoratedBox(
                                  decoration: shadowDecoration,
                                  child: PlayingCardView(
                                    card: gameState.deck.first.card,
                                    style: PlayingCardViewStyle(
                                        cardBackContentBuilder: (context) {
                                      return const PCardPattern();
                                    }),
                                    showBack: true,
                                  ),
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
                ConstrainedBox(
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.4,
                      maxHeight: MediaQuery.of(context).size.height * 0.4),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: PlayerHandView(
                      player: _gameViewModel.mainPlayer,
                      revealAll: gameState.revealed,
                      onTap: (e) {
                        _gameViewModel.tapCard(context, e);
                      },
                    ),
                  ),
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
                    child: DecoratedBox(
                      decoration: shadowDecoration,
                      child: PlayingCardView(
                        card: _gameViewModel.mainPlayer.handCard!.card,
                        showBack: false,
                        style: PlayingCardViewStyle(
                            cardBackContentBuilder: (context) {
                          return const PCardPattern();
                        }),
                      ),
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
                  child: DecoratedBox(
                    decoration: shadowDecoration,
                    child: PlayingCardView(
                      card: _gameViewModel.remotePlayer.handCard!.card,
                      showBack: true,
                      style: PlayingCardViewStyle(
                          cardBackContentBuilder: (context) {
                        return const PCardPattern();
                      }),
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 4,
              right: 4,
              child: Column(
                children: [
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
            ),
            // Room code overlay
            if (_roomCode != null) _buildRoomCodeOverlay(),
          ],
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
                                                    style: PlayingCardViewStyle(
                                                        cardBackContentBuilder:
                                                            (context) {
                                                      return const PCardPattern();
                                                    }),
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
    return Container(
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
                    Colors.white,
                    Color.fromARGB(0, 255, 255, 255),
                    Color.fromARGB(0, 255, 255, 255),
                    Color.fromARGB(0, 255, 255, 255),
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
                                  : DecoratedBox(
                                      decoration: shadowDecoration,
                                      child: PlayingCardView(
                                        card: e.card,
                                        // showBack: false,
                                        showBack: player.isMainPlayer
                                            ? (revealAll
                                                ? false
                                                : !e.isCardShown)
                                            : !revealAll,
                                        style: PlayingCardViewStyle(
                                            cardBackContentBuilder: (context) {
                                          return const PCardPattern();
                                        }),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                )
                .toList(),
          ),
        ),
      );
  }
}

const shadowDecoration = BoxDecoration(
  boxShadow: [
    BoxShadow(
      color: Color.fromRGBO(50, 50, 93, 0.25),
      offset: Offset(0, 30),
      blurRadius: 60,
      spreadRadius: -12,
    ),
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.3),
      offset: Offset(0, 18),
      blurRadius: 36,
      spreadRadius: -18,
    ),
  ],
);

class PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Pattern pattern = DiagonalStripesThick(
        bgColor: Colors.white, fgColor: Colors.red.shade900);
    pattern.paintOnCanvas(canvas, size);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class PCardPattern extends StatelessWidget {
  const PCardPattern({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.red.shade900, width: 4),
          borderRadius: BorderRadius.circular(10),
        ),
        child: ClipRRect(
          child: CustomPaint(
            painter: PatternPainter(),
          ),
        ));
  }
}
