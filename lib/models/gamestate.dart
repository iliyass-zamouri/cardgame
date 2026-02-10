import 'package:shadow_hand/models/p_card.dart';
import 'package:shadow_hand/models/player.dart';
import 'package:flutter/material.dart';

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

  remoteThrowCard(PCard card, bool hand) {
    var remotePlayer = players[1];
    if (!hand) {
      int index = remotePlayer.cards.indexWhere((c) => c.tag == card.tag);
      remotePlayer.cards[index].isThrown = true;
      throwedCards.add(remotePlayer.cards[index]);
    } else {
      throwedCards.add(remotePlayer.handCard as PCard);
      remotePlayer.handCard = null;
    }
  }

  restock([List<dynamic>? remoteDeck, List<dynamic>? remoteThrowedCards]) {
    if (remoteDeck != null && remoteThrowedCards != null) {
      deck = remoteDeck.map((e) => PCard.fromTag(e)).toList();
      throwedCards = remoteThrowedCards.map((e) => PCard.fromTag(e)).toList();
    } else {
      if (deck.isEmpty) {
        PCard lastCard = throwedCards.removeAt(throwedCards.length - 1);
        deck = throwedCards.map((e) {
          e.isThrown = false;
          return e;
        }).toList();
        throwedCards = [lastCard];
        deck.shuffle();
      }
    }
  }

  nextTurn([bool remote = false, VoidCallback? callback]) {
    if (remote) {
      players[1].endTurn();
      currentPlayerIndex = 0;
      players[0].startTurn();
    } else {
      players[0].endTurn();
      currentPlayerIndex = 1;
      players[1].startTurn();
      callback!();
    }
  }
}

class GameActions {
  static const String init = 'init';
  static const String launch = 'launch';
  static const String draw = 'draw';
  static const String throwCard = 'throw';
  static const String swap = 'swap';
  static const String next = 'next';
  static const String restock = 'restock';
  static const String penalty = 'penalty';
  static const String end = 'end';
}
