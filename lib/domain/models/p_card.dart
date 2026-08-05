import 'package:playing_cards/playing_cards.dart';

/// Immutable rendering metadata. Game rules and deck state live on the server.
class PCard {
  static final Map<String, PCard> _cache = {};

  final String tag;
  final PlayingCard card;

  PCard._({required this.tag, required this.card});

  factory PCard.fromTag(String tag) {
    return _cache.putIfAbsent(tag, () {
      if (!RegExp(r'^[A-D](?:[1-9]|1[0-4])$').hasMatch(tag)) {
        throw FormatException('Invalid card tag: $tag');
      }
      final suitCode = tag[0];
      final value = int.parse(tag.substring(1));
      final suit = switch (suitCode) {
        'A' => Suit.clubs,
        'B' => Suit.diamonds,
        'C' => Suit.hearts,
        'D' => Suit.spades,
        _ => throw FormatException('Invalid suit: $suitCode'),
      };
      final cardValue = switch (value) {
        1 => CardValue.ace,
        2 => CardValue.two,
        3 => CardValue.three,
        4 => CardValue.four,
        5 => CardValue.five,
        6 => CardValue.six,
        7 => CardValue.seven,
        8 => CardValue.eight,
        9 => CardValue.nine,
        10 => CardValue.ten,
        11 => CardValue.jack,
        12 => CardValue.queen,
        13 => CardValue.king,
        14 => suitCode == 'A' ? CardValue.joker_1 : CardValue.joker_2,
        _ => throw FormatException('Invalid card value: $value'),
      };
      return PCard._(
        tag: tag,
        card: PlayingCard(suit, cardValue),
      );
    });
  }
}
