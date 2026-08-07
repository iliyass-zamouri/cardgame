import 'dart:async';

import 'package:cardgame/domain/offline/game_room.dart';
import 'package:cardgame/domain/offline/game_rule_error.dart';
import 'package:flutter_test/flutter_test.dart';

OfflineGameRoom startedRoom({
  int peekDurationMs = 3500,
  int queenShuffleDurationMs = 1200,
  int queenReplaceDurationMs = 1400,
}) {
  final room = OfflineGameRoom(
    'TEST01',
    random: () => 0.25,
    peekDurationMs: peekDurationMs,
    queenShuffleDurationMs: queenShuffleDurationMs,
    queenReplaceDurationMs: queenReplaceDurationMs,
  );
  room.addPlayer('p1');
  room.addPlayer('p2');
  room.start('p1');
  return room;
}

void endLaunches(OfflineGameRoom room) {
  for (final player in room.players) {
    player.launch = 'ended';
  }
}

void main() {
  test('server owns deal and hides private cards', () {
    final room = startedRoom();
    final p1 = room.snapshotFor('p1');
    final p2 = room.snapshotFor('p2');

    expect(p1['deckCount'], 46);
    expect((p1['you'] as Map)['cards'], hasLength(4));
    expect(
      ((p1['you'] as Map)['cards'] as List).every((c) => c['tag'] == null),
      isTrue,
    );
    expect(
      ((p2['opponent'] as Map)['cards'] as List).every((c) => c['tag'] == null),
      isTrue,
    );
  });

  test('snapshot includes displayName from addPlayer', () {
    final room = OfflineGameRoom('NAMES1');
    room.addPlayer('p1', playerId: 'guest-1', displayName: 'Lucky Ace');
    room.addPlayer('p2', playerId: 'google-2', displayName: 'Sharp King');
    final snap = room.snapshotFor('p1');
    expect((snap['you'] as Map)['displayName'], 'Lucky Ace');
    expect((snap['you'] as Map)['playerId'], 'guest-1');
    expect((snap['opponent'] as Map)['displayName'], 'Sharp King');
    expect((snap['opponent'] as Map)['playerId'], 'google-2');
  });

  test('rejects command from player without turn', () {
    final room = startedRoom();
    endLaunches(room);
    final wrongPlayer = room.players[1 - room.turnIndex!].id;

    expect(
      () => room.draw(wrongPlayer),
      throwsA(
        isA<GameRuleError>().having((e) => e.code, 'code', 'not_your_turn'),
      ),
    );
  });

  test('draw changes authoritative snapshot exactly once', () {
    final room = startedRoom();
    endLaunches(room);
    final playerId = room.players[room.turnIndex!].id;
    final before = room.snapshotFor(playerId);

    room.draw(playerId);
    final after = room.snapshotFor(playerId);

    expect(after['deckCount'], (before['deckCount'] as int) - 1);
    expect((after['you'] as Map)['hasHandCard'], isTrue);
    expect((after['you'] as Map)['handCard'], isA<String>());
  });

  test('matching hand and drawn cards both land on discard', () {
    final room = startedRoom();
    endLaunches(room);
    final player = room.players[room.turnIndex!];
    final spectatorId = room.players[1 - room.turnIndex!].id;
    player.cards = ['A5', 'B8'];
    player.handCard = 'D5';

    room.tapCard(player.id, 0);
    final snapshot = room.snapshotFor(player.id);
    final spectator = room.snapshotFor(spectatorId);

    expect(snapshot['discardRecent'], ['A5', 'D5']);
    expect(snapshot['discardTop'], 'D5');
    expect((snapshot['you'] as Map)['cards'], hasLength(1));
    expect((snapshot['you'] as Map)['handCard'], isNull);
    expect(snapshot['lastAction'], {
      'actor': 'you',
      'type': 'doubleDiscard',
      'cardIndex': 0,
      'cardTag': 'A5',
      'drawnTag': 'D5',
    });
    expect(spectator['lastAction'], {
      'actor': 'opponent',
      'type': 'doubleDiscard',
      'cardIndex': 0,
      'cardTag': 'A5',
      'drawnTag': 'D5',
    });
  });

  test('mismatched cards leave only swapped card on discard', () {
    final room = startedRoom();
    endLaunches(room);
    final player = room.players[room.turnIndex!];
    player.cards = ['A5', 'B8'];
    player.handCard = 'D9';

    room.tapCard(player.id, 0);
    final snapshot = room.snapshotFor(player.id);

    expect(snapshot['discardTop'], 'A5');
    expect((snapshot['you'] as Map)['cards'], hasLength(2));
    expect((snapshot['you'] as Map)['hasHandCard'], isFalse);
    expect(snapshot['discardSource'], 'hand');
    expect(snapshot['lastAction'], {
      'actor': 'you',
      'type': 'swap',
      'cardIndex': 0,
      'cardTag': 'A5',
      'drawnTag': null,
    });
  });

  test('discard match records lastAction', () {
    final room = startedRoom();
    endLaunches(room);
    final player = room.players[room.turnIndex!];
    room.discard = ['C5'];
    player.cards = ['A5', 'B8'];
    player.handCard = null;

    room.tapCard(player.id, 0);
    final snapshot = room.snapshotFor(player.id);

    expect(snapshot['discardTop'], 'A5');
    expect((snapshot['you'] as Map)['cards'], hasLength(1));
    expect((snapshot['lastAction'] as Map)['type'], 'discardMatch');
  });

  test('penalty miss records lastAction', () {
    final room = startedRoom();
    endLaunches(room);
    final player = room.players[room.turnIndex!];
    room.discard = ['C9'];
    player.cards = ['A5', 'B8'];
    player.handCard = null;
    final beforeCount = player.cards.length;

    room.tapCard(player.id, 1);
    final snapshot = room.snapshotFor(player.id);

    expect((snapshot['you'] as Map)['cards'], hasLength(beforeCount + 1));
    expect((snapshot['lastAction'] as Map)['type'], 'penaltyDraw');
  });

  test('throw records lastAction', () {
    final room = startedRoom();
    endLaunches(room);
    final player = room.players[room.turnIndex!];
    player.handCard = 'D7';

    room.throwHand(player.id);
    final snapshot = room.snapshotFor(player.id);

    expect(snapshot['discardTop'], 'D7');
    expect((snapshot['you'] as Map)['hasHandCard'], isFalse);
    expect(snapshot['discardSource'], 'drawn');
    expect((snapshot['lastAction'] as Map)['type'], 'throw');
  });

  test('end computes scores and reveals cards', () {
    final room = startedRoom();
    room.players[0].cards = ['A5'];
    room.players[1].cards = ['B6'];

    room.end('p1');
    final snapshot = room.snapshotFor('p1');

    expect(snapshot['status'], 'ended');
    expect((snapshot['result'] as Map)['scores'], [5, 6]);
    expect((snapshot['result'] as Map)['winnerIndex'], 0);
    expect(((snapshot['you'] as Map)['cards'] as List).first['tag'], 'A5');
    expect(((snapshot['opponent'] as Map)['cards'] as List).first['tag'], 'B6');
  });

  test('drawing a Jack enables private peek for drawer only', () {
    final room = startedRoom();
    endLaunches(room);
    final player = room.players[room.turnIndex!];
    final spectatorId = room.players[1 - room.turnIndex!].id;
    room.deck.add('A11');

    room.draw(player.id);
    final snapshot = room.snapshotFor(player.id);
    final spectator = room.snapshotFor(spectatorId);

    expect((snapshot['you'] as Map)['handCard'], 'A11');
    expect((snapshot['you'] as Map)['jackPeekAvailable'], isTrue);
    expect((spectator['you'] as Map)['jackPeekAvailable'], isFalse);
  });

  test('jack peek reveals own card privately', () {
    final room = startedRoom();
    endLaunches(room);
    final player = room.players[room.turnIndex!];
    final spectatorId = room.players[1 - room.turnIndex!].id;
    player.cards = ['A5', 'B8'];
    player.handCard = 'C11';
    player.jackPeekAvailable = true;

    room.jackPeek(player.id, side: 'you', cardIndex: 1);
    final snapshot = room.snapshotFor(player.id);
    final spectator = room.snapshotFor(spectatorId);

    expect(((snapshot['you'] as Map)['cards'] as List)[1]['visible'], isTrue);
    expect(((snapshot['you'] as Map)['cards'] as List)[1]['tag'], 'B8');
    expect(
      ((spectator['opponent'] as Map)['cards'] as List)[1]['visible'],
      isFalse,
    );
  });

  test('jack peek auto-throws Jack when peek ends', () async {
    final room = startedRoom(peekDurationMs: 20);
    endLaunches(room);
    final player = room.players[room.turnIndex!];
    player.cards = ['A5', 'B8'];
    player.handCard = 'C11';
    player.jackPeekAvailable = true;

    room.jackPeek(player.id, side: 'you', cardIndex: 0);
    expect((room.snapshotFor(player.id)['you'] as Map)['hasHandCard'], isTrue);

    await Future<void>.delayed(const Duration(milliseconds: 50));

    final snapshot = room.snapshotFor(player.id);
    expect((snapshot['you'] as Map)['hasHandCard'], isFalse);
    expect(snapshot['discardTop'], 'C11');
    expect((snapshot['lastAction'] as Map)['type'], 'throw');
    room.dispose();
  });

  test('queen replace swaps and auto-throws', () async {
    final room = startedRoom(queenReplaceDurationMs: 20);
    endLaunches(room);
    final player = room.players[room.turnIndex!];
    final opponent = room.players[1 - room.turnIndex!];
    player.cards = ['A5', 'B8'];
    opponent.cards = ['C3', 'D7'];
    player.handCard = 'B12';
    player.queenAbilityAvailable = true;

    room.queenReplace(player.id, youIndex: 0, opponentIndex: 1);
    expect(player.cards[0], 'D7');
    expect(opponent.cards[1], 'A5');

    await Future<void>.delayed(const Duration(milliseconds: 50));
    final after = room.snapshotFor(player.id);
    expect((after['you'] as Map)['hasHandCard'], isFalse);
    expect(after['discardTop'], 'B12');
    room.dispose();
  });

  test('queen ability rejects without Queen and during lock', () {
    final room = startedRoom();
    endLaunches(room);
    final player = room.players[room.turnIndex!];
    player.cards = ['A5', 'B8', 'C3'];
    player.handCard = 'D9';
    player.queenAbilityAvailable = false;

    expect(
      () => room.queenShuffle(player.id, side: 'you'),
      throwsA(isA<GameRuleError>().having((e) => e.code, 'code', 'no_queen')),
    );

    player.handCard = 'C12';
    player.queenAbilityAvailable = true;
    room.queenShuffle(player.id, side: 'you');
    expect(
      () => room.queenReplace(player.id, youIndex: 0, opponentIndex: 0),
      throwsA(
        isA<GameRuleError>().having((e) => e.code, 'code', 'queen_in_progress'),
      ),
    );
    room.dispose();
  });
}
