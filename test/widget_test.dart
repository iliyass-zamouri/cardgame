import 'package:flutter_test/flutter_test.dart';
import 'package:game_protocol/game_protocol.dart';

void main() {
  test('protocol events include card.action', () {
    expect(ProtocolEvents.all.contains(ProtocolEvents.cardAction), isTrue);
  });

  test('wire envelope encode/decode', () {
    const env = WireEnvelope(
      event: ProtocolEvents.matchQueue,
      payload: {'stake': 100},
    );
    final again = WireEnvelope.decode(env.encode());
    expect(again.event, ProtocolEvents.matchQueue);
    expect(again.payload['stake'], 100);
  });

  test('card rules value helper parity', () {
    int cardValue(String tag) => int.parse(tag.substring(1));
    expect(cardValue('A10'), 10);
    expect(cardValue('C1'), 1);
  });
}
