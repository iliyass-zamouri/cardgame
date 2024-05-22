import 'package:playing_cards/playing_cards.dart';

class PCard {
  final String tag;
  final PlayingCard card;
  final int gameValue;
  final int cardValue;
  bool isThrown;
  bool cardSeen;

  bool isCardShown;

  PCard({
    required this.tag,
    required this.card,
    required this.gameValue,
    required this.cardValue,
    this.isThrown = false,
    this.cardSeen = false,
    this.isCardShown = false,
  });

  static PCard fromTag(String tag) {
    final suitCode = tag[0];
    final valueCode = tag.substring(1);

    final suit = getSuitFromCode(suitCode);
    final cardValue = int.parse(valueCode);

    return PCard(
      tag: tag,
      card: PlayingCard(suit, getValueByIndex(cardValue, suitCode)),
      gameValue: getGameValue(cardValue, suit),
      cardValue: cardValue,
    );
  }

  static Suit getSuitFromCode(String code) {
    switch (code) {
      case 'A':
        return Suit.clubs;
      case 'B':
        return Suit.diamonds;
      case 'C':
        return Suit.hearts;
      case 'D':
        return Suit.spades;
      default:
        throw ArgumentError('Invalid suit code: $code');
    }
  }

  static CardValue getValueByIndex(int index, [String letter = 'A']) {
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
      case 13:
        return CardValue.king;
      case 14:
        return letter == 'A'
            ? CardValue.joker_1
            : CardValue.joker_2; // Assuming jokers have a special value
      default:
        throw ArgumentError('Invalid card value index: $index');
    }
  }

  static int getGameValue(int index, Suit suit) {
    if (index == 13 && suit == Suit.spades) {
      return 0;
    }
    if (index == 13 && suit == Suit.clubs) {
      return 0;
    }
    return index;
  }

  bool checkImportance(int cardsLeft) {
    if (cardsLeft != 1) {
      return gameValue < 1;
    }
    return false;
  }

  static List<PCard> generateDeck() {
    List<PCard> deck = PCard.getDeck();
    deck.shuffle();
    return deck;
  }

  static List<PCard> getDeck() {
    List<PCard> cards = [];
    for (int i = 1; i < 14; i++) {
      cards.add(PCard(
          tag: "A$i",
          card: PlayingCard(Suit.clubs, PCard.getValueByIndex(i)),
          gameValue: PCard.getGameValue(i, Suit.clubs),
          cardValue: i));
      cards.add(PCard(
          tag: "B$i",
          card: PlayingCard(Suit.diamonds, PCard.getValueByIndex(i)),
          gameValue: PCard.getGameValue(i, Suit.diamonds),
          cardValue: i));
      cards.add(PCard(
          tag: "C$i",
          card: PlayingCard(Suit.hearts, PCard.getValueByIndex(i)),
          gameValue: PCard.getGameValue(i, Suit.hearts),
          cardValue: i));
      cards.add(PCard(
          tag: "D$i",
          card: PlayingCard(Suit.spades, PCard.getValueByIndex(i)),
          gameValue: PCard.getGameValue(i, Suit.spades),
          cardValue: i));
    }
    cards.add(PCard(
        tag: "A14",
        card: PlayingCard(Suit.diamonds, CardValue.joker_1),
        gameValue: -1,
        cardValue: 14));
    cards.add(PCard(
        tag: "B14",
        card: PlayingCard(Suit.spades, CardValue.joker_2),
        gameValue: -1,
        cardValue: 14));

    return cards;
  }

  Map<String, dynamic> toJson() {
    return {
      'tag': tag,
      'card': {
        'suit': card.suit.index,
        'value': card.value.index,
      },
      'gameValue': gameValue,
      'cardValue': cardValue,
      'isThrown': isThrown,
      'cardSeen': cardSeen,
    };
  }

  static PCard fromJson(Map<String, dynamic> json) {
    return PCard(
      tag: json['tag'],
      card: PlayingCard(
        Suit.values[json['card']['suit']],
        CardValue.values[json['card']['value']],
      ),
      gameValue: json['gameValue'],
      cardValue: json['cardValue'],
      isThrown: json['isThrown'],
      cardSeen: json['cardSeen'],
    );
  }
}
