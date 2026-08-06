import 'package:game_protocol/game_protocol.dart';
import 'package:test/test.dart';

void main() {
  test('envelope roundtrip', () {
    final raw = WireEnvelope(
      event: ProtocolEvents.matchQueue,
      payload: const MatchQueueMessage(playerId: 'p1', stake: 50).toJson(),
    ).encode();
    final decoded = WireEnvelope.decode(raw);
    expect(decoded.event, ProtocolEvents.matchQueue);
    expect(MatchQueueMessage.fromJson(decoded.payload).playerId, 'p1');
  });

  test('all events non-empty unique', () {
    expect(ProtocolEvents.all.length, greaterThan(10));
    expect(ProtocolEvents.all.length, ProtocolEvents.all.toSet().length);
  });
}
