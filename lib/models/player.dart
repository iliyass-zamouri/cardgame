import 'package:cardgame/models/p_card.dart';

class Player {
  List<PCard> cards;
  PCard? handCard;
  int? revealCardIndex;
  bool gameStarter;
  String launchReveal;
  int total;
  bool turn;
  bool isMainPlayer;

  Player(
      {required this.cards,
      this.launchReveal = 'NOT_LAUNCHED',
      this.gameStarter = false,
      this.total = 0,
      this.turn = false,
      this.isMainPlayer = false});

  startGame() {
    gameStarter = true;
    turn = true;
  }

  isMyTurn() {
    return turn;
  }

  startTurn() {
    turn = true;
  }

  void endTurn() {
    turn = false;
    if (cards.length >= 2) {
      if (cards[0].isThrown && cards[1].isThrown) {
        cards.removeAt(1);
        cards.removeAt(0);
      }
    }
    if (cards.length >= 4) {
      if (cards[2].isThrown && cards[3].isThrown) {
        cards.removeAt(3);
        cards.removeAt(2);
      }
    }
  }

  reveal(index) {
    cards[index].isCardShown = true;
  }

  unreveal(index) {
    cards[index].isCardShown = false;
  }

  startLaunchReveal() {
    launchReveal = "LAUNCHED";
    cards[2].isCardShown = true;
    cards[3].isCardShown = true;
    if (!isMainPlayer) {
      cards[2].cardSeen = true;
      cards[3].cardSeen = true;
    }
  }

  launchRevealEnded() {
    return launchReveal == "ENDED";
  }

  launchRevealNotStarted() {
    return launchReveal == "NOT_LAUNCHED";
  }

  endLaunchReveal() {
    launchReveal = 'ENDED';
    cards[2].isCardShown = false;
    cards[3].isCardShown = false;
  }

  // from Map
  factory Player.fromMap(Map<String, dynamic> map,
      [bool isMainPlayer = false]) {
    return Player(
      cards: List<PCard>.from(map['cards'].map((x) => PCard.fromTag(x))),
      launchReveal: map['launchReveal'],
      gameStarter: map['gameStarter'],
      total: map['total'],
      turn: map['turn'],
      isMainPlayer: isMainPlayer,
    );
  }

  // to Map

  Map<String, dynamic> toMap() {
    return {
      'cards': cards.map((x) => x.tag).toList(),
      'launchReveal': launchReveal,
      'gameStarter': gameStarter,
      'total': total,
      'turn': turn,
      'isMainPlayer': isMainPlayer,
    };
  }
}
