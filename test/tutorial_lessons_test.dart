import 'dart:async';

import 'package:cardgame/data/auth/server_identity.dart';
import 'package:cardgame/domain/offline/card_utils.dart';
import 'package:cardgame/domain/offline/game_room.dart';
import 'package:cardgame/l10n/app_localizations.dart';
import 'package:cardgame/ui/screens/tutorial/tutorial_controller.dart';
import 'package:cardgame/ui/screens/tutorial/tutorial_lessons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

final _lessons = {for (final l in tutorialLessons()) l.id: l};

TutorialLesson _lesson(String id) => _lessons[id]!;

List<String> _tags(List<TutorialCard> cards) => [for (final c in cards) c.tag];

/// Room with a rigged table; p1 to play, both openings done.
class _Rigged {
  _Rigged({
    required List<String> you,
    required List<String> opponent,
    List<String> deck = const [],
    List<String> discard = const [],
  }) {
    room = OfflineGameRoom(
      'TUT',
      random: () => 0,
      scheduler: (duration, callback) {
        pending.add(callback);
        return Timer(Duration.zero, () {});
      },
    );
    room
      ..addPlayer('p1')
      ..addPlayer('p2')
      ..start('p1');
    room.players[0].cards = [...you];
    room.players[1].cards = [...opponent];
    // Deck draws from the end.
    room.deck = [...deck.reversed];
    room.discard = [...discard];
    room.turnIndex = 0;
    for (final player in room.players) {
      player.launch = 'ended';
    }
  }

  late final OfflineGameRoom room;
  final pending = <void Function()>[];

  List<String> get you => room.players[0].cards;
  List<String> get opponent => room.players[1].cards;
  String get discardTop => room.discard.last;

  void fireTimers() {
    final callbacks = [...pending];
    pending.clear();
    for (final callback in callbacks) {
      callback();
    }
  }
}

/// Plays a lesson with the expected taps. Timed steps run on [tick].
Future<void> _playThrough(
  TutorialController controller,
  Future<void> Function(Duration) tick,
) async {
  var guard = 0;
  while (!controller.completed) {
    expect(guard++, lessThan(50), reason: 'lesson ${controller.lesson.id}');
    final step = controller.step;
    if (step.expect != null) {
      expect(controller.tap(step.expect!), TutorialTapResult.advanced);
    } else if (step.autoAdvance != null) {
      await tick(step.autoAdvance!);
    } else {
      controller.next();
    }
  }
}

void main() {
  group('controller', () {
    testWidgets('every lesson can be completed', (tester) async {
      expect(_lessons, hasLength(10));
      for (final lesson in _lessons.values) {
        final controller = TutorialController(lesson);
        await _playThrough(controller, tester.pump);
        expect(controller.completed, isTrue, reason: lesson.id);
        controller.dispose();
      }
    });

    test('a wrong tap explains instead of advancing', () {
      final controller = TutorialController(_lesson('swap'));
      controller.next(); // intro
      expect(controller.step.expect, const TutorialTarget.deck());

      expect(
        controller.tap(const TutorialTarget.yourCard(0)),
        TutorialTapResult.wrong,
      );
      expect(controller.stepIndex, 1);
      expect(controller.hint, isNotNull);
      expect(controller.wrongTaps, 1);

      controller.tap(const TutorialTarget.deck());
      expect(controller.stepIndex, 2);
      expect(controller.hint, isNull);
      controller.dispose();
    });

    test('Next does nothing while a tap is expected', () {
      final controller = TutorialController(_lesson('throw'));
      controller.next();
      expect(controller.stepIndex, 0);
      controller.dispose();
    });

    test('restart goes back to the first step', () {
      final controller = TutorialController(_lesson('values'));
      controller
        ..next()
        ..next();
      controller.restart();
      expect(controller.stepIndex, 0);
      expect(controller.completed, isFalse);
      controller.dispose();
    });
  });

  // The scripted boards must match what the real engine does.
  group('lessons match the game rules', () {
    test('values quiz answers', () {
      final lowest = _lesson('values').steps[2];
      final quizCards = _tags(lowest.board.you);
      final values = quizCards.map(gameValue).toList();
      final min = values.reduce((a, b) => a < b ? a : b);
      expect(lowest.expect!.index, values.indexOf(min));

      final king = _lesson('values').steps[3];
      expect(gameValue(_tags(king.board.you)[king.expect!.index]), 0);
      expect(gameValue('C13'), 13);
      expect(gameValue('B13'), 13);
    });

    test('opening reveal shows the two left cards', () {
      final room = OfflineGameRoom('TUT', random: () => 0)
        ..addPlayer('p1')
        ..addPlayer('p2')
        ..start('p1')
        ..launch('p1');
      final cards =
          (room.snapshotFor('p1')['you'] as Map)['cards'] as List<dynamic>;
      expect([for (final c in cards) c['visible']], [true, true, false, false]);

      final memorize = _lesson('deal').steps[2].board.you;
      expect([for (final c in memorize) c.faceUp], [true, true, false, false]);
    });

    test('draw & swap', () {
      final lesson = _lesson('swap');
      final t = _Rigged(
        you: _tags(lesson.steps[1].board.you),
        opponent: _tags(lesson.steps[1].board.opponent),
        deck: [lesson.steps[2].board.drawnCard!],
        discard: [lesson.steps[1].board.discardTop!],
      );
      t.room
        ..draw('p1')
        ..tapCard('p1', lesson.steps[2].expect!.index);
      expect(t.you, _tags(lesson.steps.last.board.you));
      expect(t.discardTop, lesson.steps.last.board.discardTop);
      expect(t.room.turnIndex, 1);
    });

    test('throw the drawn card', () {
      final lesson = _lesson('throw');
      final t = _Rigged(
        you: _tags(lesson.steps[0].board.you),
        opponent: _tags(lesson.steps[0].board.opponent),
        deck: [lesson.steps[1].board.drawnCard!],
        discard: [lesson.steps[0].board.discardTop!],
      );
      t.room
        ..draw('p1')
        ..throwHand('p1');
      expect(t.you, _tags(lesson.steps.last.board.you));
      expect(t.discardTop, lesson.steps.last.board.discardTop);
      expect(t.room.turnIndex, 1);
    });

    test('double discard', () {
      final lesson = _lesson('double');
      final t = _Rigged(
        you: _tags(lesson.steps[1].board.you),
        opponent: _tags(lesson.steps[1].board.opponent),
        deck: [lesson.steps[2].board.drawnCard!],
        discard: [lesson.steps[1].board.discardTop!],
      );
      t.room
        ..draw('p1')
        ..tapCard('p1', lesson.steps[2].expect!.index);
      expect(t.you, _tags(lesson.steps.last.board.you));
      expect(t.discardTop, lesson.steps.last.board.discardTop);
    });

    test('match the discard keeps the turn; a wrong guess costs a card', () {
      final lesson = _lesson('match');
      final matchStep = lesson.steps[1];
      final t = _Rigged(
        you: _tags(matchStep.board.you),
        opponent: _tags(matchStep.board.opponent),
        deck: [lesson.steps[3].board.drawnCard!],
        discard: ['B2', matchStep.board.discardTop!],
      );
      t.room.tapCard('p1', matchStep.expect!.index);
      expect(t.you, _tags(lesson.steps[2].board.you));
      expect(t.discardTop, lesson.steps[2].board.discardTop);
      expect(t.room.turnIndex, 0, reason: 'matching does not end the turn');

      final guessStep = lesson.steps[4];
      final penalty = _Rigged(
        you: _tags(guessStep.board.you),
        opponent: _tags(guessStep.board.opponent),
        deck: [lesson.steps.last.board.you.last.tag],
        discard: [guessStep.board.discardTop!],
      );
      penalty.room.tapCard('p1', guessStep.expect!.index);
      expect(penalty.you, _tags(lesson.steps.last.board.you));
      expect(penalty.discardTop, guessStep.board.discardTop);
    });

    test('Jack peek reveals the card, then the Jack is thrown', () {
      final lesson = _lesson('jack');
      final pick = lesson.steps[2];
      final t = _Rigged(
        you: _tags(pick.board.you),
        opponent: _tags(pick.board.opponent),
        deck: [pick.board.drawnCard!],
        discard: [pick.board.discardTop!],
      );
      t.room
        ..draw('p1')
        ..jackPeek('p1', side: 'opponent', cardIndex: pick.expect!.index);
      final opponent =
          (t.room.snapshotFor('p1')['opponent'] as Map)['cards'] as List;
      final revealed = lesson.steps[3].board.opponent;
      for (var i = 0; i < revealed.length; i++) {
        expect(opponent[i]['visible'], revealed[i].faceUp);
      }
      t.fireTimers();
      expect(t.discardTop, lesson.steps.last.board.discardTop);
      expect(t.room.turnIndex, 1);
    });

    test('Queen replace swaps one card each, then the Queen is thrown', () {
      final lesson = _lesson('queen');
      final draw = lesson.steps[1];
      final t = _Rigged(
        you: _tags(draw.board.you),
        opponent: _tags(draw.board.opponent),
        deck: [lesson.steps[2].board.drawnCard!],
        discard: [draw.board.discardTop!],
      );
      t.room
        ..draw('p1')
        ..queenReplace(
          'p1',
          youIndex: lesson.steps[3].expect!.index,
          opponentIndex: lesson.steps[4].expect!.index,
        );
      t.fireTimers();
      final done = lesson.steps[5].board;
      expect(t.you, _tags(done.you));
      expect(t.opponent, _tags(done.opponent));
      expect(t.discardTop, done.discardTop);
    });

    test('End game scores the hands; lowest wins', () {
      final lesson = _lesson('ending');
      final count = lesson.steps[2];
      final t = _Rigged(
        you: _tags(count.board.you),
        opponent: _tags(count.board.opponent),
        discard: [count.board.discardTop!],
      );
      t.room.end('p1');
      final scores = t.room.result!['scores'] as List<int>;
      final en = lookupAppLocalizations(const Locale('en'));
      expect('${scores[0]}', count.board.choices[count.expect!.index](en));
      expect(scores, [4, 22]);
      expect(t.room.result!['winnerIndex'], 0);
    });
  });

  test('server identity carries the tutorial flag', () {
    expect(
      ServerIdentity.fromJson({'playerId': 'p', 'tutorialDone': true})
          .tutorialDone,
      isTrue,
    );
    expect(ServerIdentity.fromJson({'playerId': 'p'}).tutorialDone, isFalse);
  });
}
