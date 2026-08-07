import 'dart:async';
import 'dart:convert';

import 'package:cardgame/data/offline/offline_game_socket.dart';
import 'package:cardgame/domain/offline/game_room.dart';
import 'package:cardgame/domain/offline/robot_player.dart';
import 'package:flutter_test/flutter_test.dart';

OfflineGameRoom testRoom(void Function(OfflineGameRoom) onChange) {
  return OfflineGameRoom(
    'OFFLINE',
    onChange: onChange,
    launchDurationMs: 20,
    peekDurationMs: 20,
    queenShuffleDurationMs: 20,
    queenReplaceDurationMs: 20,
  );
}

void main() {
  test('offline socket emits connected then playing snapshot', () async {
    final events = <Map<String, dynamic>>[];
    final socket = OfflineGameSocket(
      humanDisplayName: 'Human',
      humanPlayerId: 'guest-1',
      robotDisplayName: 'Robot',
      roomFactory: testRoom,
      robotFactory:
          (room) => RobotPlayer(
            room: room,
            clientId: kOfflineRobotId,
            launchDelayMs: 5,
            thinkMinMs: 5,
            thinkMaxMs: 5,
          ),
    );
    final sub = socket.stream.listen((raw) {
      events.add(jsonDecode(raw) as Map<String, dynamic>);
    });
    addTearDown(() {
      sub.cancel();
      socket.close();
    });

    await Future<void>.delayed(Duration.zero);

    expect(events, isNotEmpty);
    expect(events.first['type'], 'connected');
    expect(events.first['clientId'], kOfflineHumanId);

    final snapshot = events.firstWhere((e) => e['type'] == 'snapshot');
    expect(snapshot['status'], 'playing');
    expect(snapshot['matchType'], 'offline');
    expect(snapshot['ready'], isTrue);
    expect((snapshot['you'] as Map)['displayName'], 'Human');
    expect((snapshot['opponent'] as Map)['displayName'], 'Robot');
    expect(snapshot['deckCount'], 46);
  });

  test('human draw updates snapshot after both launch', () async {
    final bothEnded = Completer<void>();
    final snapshots = <Map<String, dynamic>>[];

    final socket = OfflineGameSocket(
      humanDisplayName: 'Human',
      roomFactory: testRoom,
      robotFactory:
          (room) => RobotPlayer(
            room: room,
            clientId: kOfflineRobotId,
            launchDelayMs: 1,
            thinkMinMs: 10000,
            thinkMaxMs: 10000,
          ),
    );

    final sub = socket.stream.listen((raw) {
      final msg = jsonDecode(raw) as Map<String, dynamic>;
      if (msg['type'] != 'snapshot') return;
      snapshots.add(msg);
      final you = msg['you'] as Map?;
      final opp = msg['opponent'] as Map?;
      if (you?['launch'] == 'ended' &&
          opp?['launch'] == 'ended' &&
          !bothEnded.isCompleted) {
        bothEnded.complete();
      }
    });
    addTearDown(() {
      sub.cancel();
      socket.close();
    });

    await Future<void>.delayed(Duration.zero);
    socket.send(jsonEncode({'type': 'launch'}));
    await bothEnded.future.timeout(const Duration(seconds: 3));

    final room = socket.room;
    room.turnIndex = room.players.indexWhere((p) => p.id == kOfflineHumanId);

    final beforeDeck = snapshots.last['deckCount'] as int;
    socket.send(jsonEncode({'type': 'draw'}));
    await Future<void>.delayed(const Duration(milliseconds: 20));

    final after = snapshots.last;
    expect(after['deckCount'], beforeDeck - 1);
    expect((after['you'] as Map)['hasHandCard'], isTrue);
  });

  test('robot eventually ends turn without rule errors', () async {
    final errors = <String>[];
    final turnEnded = Completer<void>();

    final socket = OfflineGameSocket(
      humanDisplayName: 'Human',
      roomFactory: testRoom,
      robotFactory:
          (room) => RobotPlayer(
            room: room,
            clientId: kOfflineRobotId,
            launchDelayMs: 1,
            thinkMinMs: 5,
            thinkMaxMs: 10,
            actionDelayMs: 20,
          ),
    );

    final room = socket.room;
    room.turnIndex = room.players.indexWhere((p) => p.id == kOfflineRobotId);

    final sub = socket.stream.listen((raw) {
      final msg = jsonDecode(raw) as Map<String, dynamic>;
      if (msg['type'] == 'error') {
        errors.add(msg['code'] as String? ?? 'unknown');
      }
      if (msg['type'] == 'snapshot') {
        final you = msg['you'] as Map?;
        final opp = msg['opponent'] as Map?;
        if (you?['launch'] == 'ended' &&
            opp?['launch'] == 'ended' &&
            msg['turn'] == 'you' &&
            !turnEnded.isCompleted) {
          turnEnded.complete();
        }
      }
    });
    addTearDown(() {
      sub.cancel();
      socket.close();
    });

    await Future<void>.delayed(Duration.zero);
    socket.send(jsonEncode({'type': 'launch'}));
    await turnEnded.future.timeout(const Duration(seconds: 5));
    expect(errors, isEmpty);
  });
}
