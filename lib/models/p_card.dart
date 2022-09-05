import 'package:playing_cards/playing_cards.dart';

class PCard {
  final PlayingCard card;
  final int gameValue;
  final int cardValue;
  bool isCardShown;
  bool cardSeen;
  bool isThrown;
  PCard(
      {required this.card,
      required this.gameValue,
      required this.cardValue,
      this.isCardShown = false,
      this.isThrown = false,
      this.cardSeen = false});

  bool checkImportance(int cardsLeft) {
    if (cardsLeft != 1) {
      return gameValue < 1;
    }
    return false;
  }
}

class PCardMain {
  static List<PCard> getDeck() {
    List<PCard> cards = [];
    for (int i = 1; i < 14; i++) {
      cards.add(PCard(
          card: PlayingCard(Suit.clubs, getCardValueByIndex(i)),
          gameValue: getCardGameValue(i, Suit.clubs),
          cardValue: i));
      cards.add(PCard(
          card: PlayingCard(Suit.diamonds, getCardValueByIndex(i)),
          gameValue: getCardGameValue(i, Suit.diamonds),
          cardValue: i));
      cards.add(PCard(
          card: PlayingCard(Suit.hearts, getCardValueByIndex(i)),
          gameValue: getCardGameValue(i, Suit.hearts),
          cardValue: i));
      cards.add(PCard(
          card: PlayingCard(Suit.spades, getCardValueByIndex(i)),
          gameValue: getCardGameValue(i, Suit.spades),
          cardValue: i));
    }
    cards.add(PCard(
        card: PlayingCard(Suit.diamonds, CardValue.joker_1),
        gameValue: -1,
        cardValue: 14));
    cards.add(PCard(
        card: PlayingCard(Suit.spades, CardValue.joker_2),
        gameValue: -1,
        cardValue: 14));

    return cards;
  }

  static getCardGameValue(int index, Suit suit) {
    if (index == 13 && suit == Suit.spades) {
      return 0;
    }
    if (index == 13 && suit == Suit.clubs) {
      return 0;
    }
    return index;
  }

  static CardValue getCardValueByIndex(int index) {
    switch (index) {
      case 1:
        return CardValue.ace;
      case 2:
        return CardValue.two;
      case 3:
        return CardValue.three;
      case 4:
        return CardValue.four;
      case 5:
        return CardValue.five;
      case 6:
        return CardValue.six;
      case 7:
        return CardValue.seven;
      case 8:
        return CardValue.eight;
      case 9:
        return CardValue.nine;
      case 10:
        return CardValue.ten;
      case 11:
        return CardValue.jack;
      case 12:
        return CardValue.queen;
      default:
        return CardValue.king;
    }
  }
}
