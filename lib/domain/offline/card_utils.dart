List<String> createDeck() {
  final deck = <String>[];
  for (final suit in const ['A', 'B', 'C', 'D']) {
    for (var value = 1; value <= 13; value += 1) {
      deck.add('$suit$value');
    }
  }
  deck.addAll(const ['A14', 'B14']);
  return deck;
}

List<String> shuffle(List<String> cards, double Function() random) {
  final result = List<String>.from(cards);
  for (var index = result.length - 1; index > 0; index -= 1) {
    final other = (random() * (index + 1)).floor();
    final tmp = result[index];
    result[index] = result[other];
    result[other] = tmp;
  }
  return result;
}

int cardValue(String tag) => int.parse(tag.substring(1));

int gameValue(String tag) {
  final value = cardValue(tag);
  if (value == 14) return -1;
  if (value == 13 && (tag[0] == 'A' || tag[0] == 'D')) return 0;
  return value;
}
