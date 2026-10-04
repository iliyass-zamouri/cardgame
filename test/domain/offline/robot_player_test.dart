import 'package:cardgame/domain/offline/game_room.dart';
import 'package:cardgame/domain/offline/robot_player.dart';
import 'package:flutter_test/flutter_test.dart';

/// Room on the robot's turn, both hands revealed, with fixed cards.
OfflineGameRoom robotTurnRoom({
  required List<String> robotCards,
  required List<String> humanCards,
}) {
  final room = OfflineGameRoom('ROBOT01', random: () => 0.25)
    ..addPlayer('human')
    ..addPlayer('robot');
  room.start('human');
  for (final player in room.players) {
    player.launch = 'ended';
  }
  room.turnIndex = 1;
  room.discard
    ..clear()
    ..add('C9');
  room.players[0].cards = humanCards;
  room.players[1].cards = robotCards;
  return room;
}

/// Runs one robot turn decision synchronously.
void runTurn(RobotPlayer robot, List<void Function()> pending) {
  robot.onRoomChanged();
  final callbacks = List.of(pending);
  pending.clear();
  for (final callback in callbacks) {
    callback();
  }
}

RobotPlayer robotFor(
  OfflineGameRoom room,
  List<void Function()> pending, {
  int callMinTurns = 2,
}) {
  return RobotPlayer(
    room: room,
    clientId: 'robot',
    callMinTurns: callMinTurns,
    schedule: (_, callback) => pending.add(callback),
  );
}

void main() {
  test('robot calls the match when it is certain to win', () {
    final room = robotTurnRoom(
      robotCards: ['A1', 'B2'],
      humanCards: ['C10', 'D5'],
    );
    final pending = <void Function()>[];
    final robot = robotFor(room, pending, callMinTurns: 0);

    runTurn(robot, pending);

    expect(room.status, 'ended');
    expect(room.result!['winnerIndex'], 1);
    expect(room.result!['reason'], 'call');
    expect(room.result!['scores'], [15, 3]);
    robot.dispose();
    room.dispose();
  });

  test('robot does not call when it would tie or lose', () {
    final room = robotTurnRoom(
      robotCards: ['A3', 'B4'],
      humanCards: ['C2', 'D5'],
    );
    final pending = <void Function()>[];
    final robot = robotFor(room, pending, callMinTurns: 0);

    runTurn(robot, pending);

    expect(room.status, 'playing');
    robot.dispose();
    room.dispose();
  });

  test('robot waits callMinTurns before calling', () {
    final room = robotTurnRoom(
      robotCards: ['A1', 'B2'],
      humanCards: ['C10', 'D5'],
    );
    final pending = <void Function()>[];
    final robot = robotFor(room, pending, callMinTurns: 1);

    runTurn(robot, pending);
    expect(room.status, 'playing');

    // Finish the robot's draw, then hand the turn back to it.
    for (final callback in List.of(pending)) {
      callback();
    }
    pending.clear();
    room.players[1].cards = ['A1', 'B2'];
    room.players[0].cards = ['C10', 'D5'];
    room.turnIndex = 1;
    runTurn(robot, pending);

    expect(room.status, 'ended');
    expect(room.result!['reason'], 'call');
    robot.dispose();
    room.dispose();
  });

  test('call is rejected after drawing or out of turn', () {
    final room = robotTurnRoom(robotCards: ['A1'], humanCards: ['C10']);

    expect(() => room.call('human'), throwsA(anything));
    room.draw('robot');
    expect(() => room.call('robot'), throwsA(anything));
    room.dispose();
  });
}
