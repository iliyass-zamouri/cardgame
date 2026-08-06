import 'package:game_protocol/game_protocol.dart';
import 'package:test/test.dart';

void main() {
  test('snapshot parses hud hints', () {
    final snap = MatchSnapshotMessage.fromJson({
      'matchId': 'm1',
      'phase': 'playing',
      'localPlayerId': 'p1',
      'players': [],
      'deck': [],
      'throwedCards': ['A10'],
      'currentPlayerId': 'p1',
      'topDiscardValue': 10,
      'canAct': true,
      'revealSecondsLeft': 0,
    });
    expect(snap.topDiscardValue, 10);
    expect(snap.canAct, isTrue);
  });
}
