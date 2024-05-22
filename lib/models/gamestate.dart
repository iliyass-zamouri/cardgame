import 'package:cardgame/models/p_card.dart';
import 'package:cardgame/models/player.dart';

class GameState {
  List<PCard> deck;
  List<PCard> throwedCards;
  List<Player> players;
  int currentPlayerIndex;
  bool revealed;
  String result;

  GameState({
    required this.deck,
    required this.throwedCards,
    required this.players,
    required this.currentPlayerIndex,
    this.revealed = false,
    this.result = "",
  });

  bool launchedRevealed() {
    return players.indexWhere((element) => element.launchRevealEnded()) != -1 &&
        players.indexWhere((element) => element.launchRevealNotStarted()) == -1;
  }

  bool remoteLaunchedRevealed() {
    return players[1].launchRevealEnded() ||
        !players[1].launchRevealNotStarted();
  }
}

class GameActions {
  static const String init = 'init';
  static const String launch = 'launch';
  static const String draw = 'draw';
  static const String throwCard = 'throw';
  static const String swap = 'swap';
  static const String next = 'next';
  static const String end = 'end';
}
