import 'package:cardgame/ui/flame/suit_shapes.dart';
import 'package:cardgame/ui/screens/tutorial/tutorial_controller.dart';

/// Scripted lessons for the interactive tutorial.
///
/// Every outcome mirrors `OfflineGameRoom` (see
/// `test/tutorial_lessons_test.dart`): swap, double discard, discard match,
/// penalty draw, Jack peek, Queen replace and scoring.
///
/// Tags: A = clubs, B = diamonds, C = hearts, D = spades; 14 = Joker.
List<TutorialLesson> tutorialLessons() => [
  _values,
  _deal,
  _swap,
  _throw,
  _double,
  _match,
  _jack,
  _queen,
  _ending,
  _tips,
];

TutorialCard _down(String tag) => TutorialCard(tag);
TutorialCard _up(String tag) => TutorialCard(tag, faceUp: true);

List<TutorialCard> _hidden(List<String> tags) => [for (final t in tags) _down(t)];
List<TutorialCard> _shown(List<String> tags) => [for (final t in tags) _up(t)];

const _opponent = ['A1', 'D12', 'B4', 'A9'];

final _values = TutorialLesson(
  id: 'values',
  title: (l) => l.tutLessonValuesTitle,
  suit: SuitShape.hearts,
  steps: [
    TutorialStep(
      board: const TutorialBoard(valueChart: true),
      coach: (l) => l.tutValuesIntro,
    ),
    TutorialStep(
      board: const TutorialBoard(valueChart: true),
      coach: (l) => l.tutValuesChart,
    ),
    TutorialStep(
      board: TutorialBoard(
        you: _shown(['C9', 'A14', 'B13', 'D1']),
        showTable: false,
      ),
      coach: (l) => l.tutValuesQuizLowest,
      expect: const TutorialTarget.yourCard(1),
      wrongHint: (l) => l.tutValuesQuizLowestWrong,
    ),
    TutorialStep(
      board: TutorialBoard(
        you: _shown(['C13', 'B5', 'D13', 'C12']),
        showTable: false,
      ),
      coach: (l) => l.tutValuesQuizKing,
      expect: const TutorialTarget.yourCard(2),
      wrongHint: (l) => l.tutValuesQuizKingWrong,
    ),
    TutorialStep(
      board: const TutorialBoard(valueChart: true),
      coach: (l) => l.tutValuesDone,
    ),
  ],
);

final _deal = TutorialLesson(
  id: 'deal',
  title: (l) => l.tutLessonDealTitle,
  suit: SuitShape.spades,
  steps: [
    TutorialStep(
      board: TutorialBoard(
        you: _hidden(['C2', 'D8', 'B6', 'A10']),
        opponent: _hidden(_opponent),
      ),
      coach: (l) => l.tutDealIntro,
    ),
    TutorialStep(
      board: TutorialBoard(
        you: _hidden(['C2', 'D8', 'B6', 'A10']),
        opponent: _hidden(_opponent),
        actions: const [TutorialAction.reveal],
      ),
      coach: (l) => l.tutDealReveal,
      expect: const TutorialTarget.action(TutorialAction.reveal),
    ),
    TutorialStep(
      board: TutorialBoard(
        you: [_up('C2'), _up('D8'), _down('B6'), _down('A10')],
        opponent: _hidden(_opponent),
      ),
      coach: (l) => l.tutDealMemorize,
      autoAdvance: const Duration(seconds: 4),
    ),
    TutorialStep(
      board: TutorialBoard(
        you: _hidden(['C2', 'D8', 'B6', 'A10']),
        opponent: _hidden(_opponent),
      ),
      coach: (l) => l.tutDealQuiz,
      expect: const TutorialTarget.yourCard(0),
      wrongHint: (l) => l.tutDealQuizWrong,
    ),
    TutorialStep(
      board: TutorialBoard(
        you: [_up('C2'), _down('D8'), _down('B6'), _down('A10')],
        opponent: _hidden(_opponent),
      ),
      coach: (l) => l.tutDealDone,
    ),
  ],
);

final _swap = TutorialLesson(
  id: 'swap',
  title: (l) => l.tutLessonSwapTitle,
  suit: SuitShape.hearts,
  steps: [
    TutorialStep(
      board: TutorialBoard(
        you: [_up('C2'), _up('D9'), _down('B6'), _down('A10')],
        opponent: _hidden(_opponent),
        discardTop: 'C4',
      ),
      coach: (l) => l.tutSwapIntro,
    ),
    TutorialStep(
      board: TutorialBoard(
        you: _hidden(['C2', 'D9', 'B6', 'A10']),
        opponent: _hidden(_opponent),
        discardTop: 'C4',
      ),
      coach: (l) => l.tutDrawPrompt,
      expect: const TutorialTarget.deck(),
    ),
    TutorialStep(
      board: TutorialBoard(
        you: _hidden(['C2', 'D9', 'B6', 'A10']),
        opponent: _hidden(_opponent),
        discardTop: 'C4',
        drawnCard: 'D3',
      ),
      coach: (l) => l.tutSwapPick,
      expect: const TutorialTarget.yourCard(1),
      wrongHint: (l) => l.tutSwapPickWrong,
    ),
    TutorialStep(
      board: TutorialBoard(
        you: _hidden(['C2', 'D3', 'B6', 'A10']),
        opponent: _hidden(_opponent),
        discardTop: 'D9',
      ),
      coach: (l) => l.tutSwapDone,
    ),
  ],
);

final _throw = TutorialLesson(
  id: 'throw',
  title: (l) => l.tutLessonThrowTitle,
  suit: SuitShape.clubs,
  steps: [
    TutorialStep(
      board: TutorialBoard(
        you: _hidden(['C2', 'D3', 'B6', 'A10']),
        opponent: _hidden(_opponent),
        discardTop: 'D9',
      ),
      coach: (l) => l.tutDrawPrompt,
      expect: const TutorialTarget.deck(),
    ),
    TutorialStep(
      board: TutorialBoard(
        you: _hidden(['C2', 'D3', 'B6', 'A10']),
        opponent: _hidden(_opponent),
        discardTop: 'D9',
        drawnCard: 'B13',
      ),
      coach: (l) => l.tutThrowPick,
      expect: const TutorialTarget.drawnCard(),
      wrongHint: (l) => l.tutThrowWrong,
    ),
    TutorialStep(
      board: TutorialBoard(
        you: _hidden(['C2', 'D3', 'B6', 'A10']),
        opponent: _hidden(_opponent),
        discardTop: 'B13',
      ),
      coach: (l) => l.tutThrowDone,
    ),
  ],
);

final _double = TutorialLesson(
  id: 'double',
  title: (l) => l.tutLessonDoubleTitle,
  suit: SuitShape.diamonds,
  steps: [
    TutorialStep(
      board: TutorialBoard(
        you: [_up('C5'), _down('A3'), _down('B6'), _down('A10')],
        opponent: _hidden(_opponent),
        discardTop: 'D9',
      ),
      coach: (l) => l.tutDoubleIntro,
    ),
    TutorialStep(
      board: TutorialBoard(
        you: _hidden(['C5', 'A3', 'B6', 'A10']),
        opponent: _hidden(_opponent),
        discardTop: 'D9',
      ),
      coach: (l) => l.tutDrawPrompt,
      expect: const TutorialTarget.deck(),
    ),
    TutorialStep(
      board: TutorialBoard(
        you: _hidden(['C5', 'A3', 'B6', 'A10']),
        opponent: _hidden(_opponent),
        discardTop: 'D9',
        drawnCard: 'D5',
      ),
      coach: (l) => l.tutDoublePick,
      expect: const TutorialTarget.yourCard(0),
      wrongHint: (l) => l.tutDoubleWrong,
    ),
    TutorialStep(
      board: TutorialBoard(
        you: _hidden(['A3', 'B6', 'A10']),
        opponent: _hidden(_opponent),
        discardTop: 'D5',
      ),
      coach: (l) => l.tutDoubleDone,
    ),
  ],
);

final _match = TutorialLesson(
  id: 'match',
  title: (l) => l.tutLessonMatchTitle,
  suit: SuitShape.spades,
  steps: [
    TutorialStep(
      board: TutorialBoard(
        you: [_up('C7'), _down('A3'), _down('B6'), _down('A10')],
        opponent: _hidden(_opponent),
        discardTop: 'B2',
      ),
      coach: (l) => l.tutMatchIntro,
    ),
    TutorialStep(
      board: TutorialBoard(
        you: _hidden(['C7', 'A3', 'B6', 'A10']),
        opponent: _hidden(_opponent),
        discardTop: 'D7',
      ),
      coach: (l) => l.tutMatchPick,
      expect: const TutorialTarget.yourCard(0),
      wrongHint: (l) => l.tutMatchWrong,
    ),
    TutorialStep(
      board: TutorialBoard(
        you: _hidden(['A3', 'B6', 'A10']),
        opponent: _hidden(_opponent),
        discardTop: 'C7',
      ),
      coach: (l) => l.tutMatchContinue,
      expect: const TutorialTarget.deck(),
    ),
    TutorialStep(
      board: TutorialBoard(
        you: _hidden(['A3', 'B6', 'A10']),
        opponent: _hidden(_opponent),
        discardTop: 'C7',
        drawnCard: 'B8',
      ),
      coach: (l) => l.tutMatchThrow,
      expect: const TutorialTarget.drawnCard(),
      wrongHint: (l) => l.tutThrowWrong,
    ),
    TutorialStep(
      board: TutorialBoard(
        you: _hidden(['A3', 'B6', 'A10']),
        opponent: _hidden(_opponent),
        discardTop: 'C4',
      ),
      coach: (l) => l.tutMatchGuess,
      expect: const TutorialTarget.yourCard(1),
    ),
    TutorialStep(
      board: TutorialBoard(
        you: _hidden(['A3', 'B6', 'A10', 'D11']),
        opponent: _hidden(_opponent),
        discardTop: 'C4',
      ),
      coach: (l) => l.tutMatchPenalty,
    ),
  ],
);

final _jack = TutorialLesson(
  id: 'jack',
  title: (l) => l.tutLessonJackTitle,
  suit: SuitShape.hearts,
  steps: [
    TutorialStep(
      board: TutorialBoard(
        you: _hidden(['C2', 'D3', 'B6', 'A10']),
        opponent: _hidden(_opponent),
        discardTop: 'D7',
      ),
      coach: (l) => l.tutDrawPrompt,
      expect: const TutorialTarget.deck(),
    ),
    TutorialStep(
      board: TutorialBoard(
        you: _hidden(['C2', 'D3', 'B6', 'A10']),
        opponent: _hidden(_opponent),
        discardTop: 'D7',
        drawnCard: 'C11',
        actions: const [TutorialAction.peek],
      ),
      coach: (l) => l.tutJackPeekButton,
      expect: const TutorialTarget.action(TutorialAction.peek),
    ),
    TutorialStep(
      board: TutorialBoard(
        you: _hidden(['C2', 'D3', 'B6', 'A10']),
        opponent: _hidden(_opponent),
        discardTop: 'D7',
        drawnCard: 'C11',
      ),
      coach: (l) => l.tutJackPick,
      expect: const TutorialTarget.opponentCard(1),
      wrongHint: (l) => l.tutJackPickWrong,
    ),
    TutorialStep(
      board: TutorialBoard(
        you: _hidden(['C2', 'D3', 'B6', 'A10']),
        opponent: [_down('A1'), _up('D12'), _down('B4'), _down('A9')],
        discardTop: 'D7',
        drawnCard: 'C11',
      ),
      coach: (l) => l.tutJackReveal,
      autoAdvance: const Duration(milliseconds: 3500),
    ),
    TutorialStep(
      board: TutorialBoard(
        you: _hidden(['C2', 'D3', 'B6', 'A10']),
        opponent: _hidden(_opponent),
        discardTop: 'C11',
      ),
      coach: (l) => l.tutJackDone,
    ),
  ],
);

final _queen = TutorialLesson(
  id: 'queen',
  title: (l) => l.tutLessonQueenTitle,
  suit: SuitShape.diamonds,
  steps: [
    TutorialStep(
      board: TutorialBoard(
        you: [_down('C2'), _up('D10'), _down('B6'), _down('A10')],
        opponent: _hidden(_opponent),
        discardTop: 'C11',
      ),
      coach: (l) => l.tutQueenIntro,
    ),
    TutorialStep(
      board: TutorialBoard(
        you: _hidden(['C2', 'D10', 'B6', 'A10']),
        opponent: _hidden(_opponent),
        discardTop: 'C11',
      ),
      coach: (l) => l.tutDrawPrompt,
      expect: const TutorialTarget.deck(),
    ),
    TutorialStep(
      board: TutorialBoard(
        you: _hidden(['C2', 'D10', 'B6', 'A10']),
        opponent: _hidden(_opponent),
        discardTop: 'C11',
        drawnCard: 'B12',
        actions: const [TutorialAction.shuffle, TutorialAction.replace],
      ),
      coach: (l) => l.tutQueenButtons,
      expect: const TutorialTarget.action(TutorialAction.replace),
      wrongHint: (l) => l.tutQueenButtonsWrong,
    ),
    TutorialStep(
      board: TutorialBoard(
        you: _hidden(['C2', 'D10', 'B6', 'A10']),
        opponent: _hidden(_opponent),
        discardTop: 'C11',
        drawnCard: 'B12',
      ),
      coach: (l) => l.tutQueenPickYours,
      expect: const TutorialTarget.yourCard(1),
      wrongHint: (l) => l.tutQueenPickYoursWrong,
    ),
    TutorialStep(
      board: TutorialBoard(
        you: _hidden(['C2', 'D10', 'B6', 'A10']),
        opponent: _hidden(_opponent),
        discardTop: 'C11',
        drawnCard: 'B12',
      ),
      coach: (l) => l.tutQueenPickTheirs,
      expect: const TutorialTarget.opponentCard(0),
      wrongHint: (l) => l.tutQueenPickTheirsWrong,
    ),
    TutorialStep(
      board: TutorialBoard(
        you: _hidden(['C2', 'A1', 'B6', 'A10']),
        opponent: _hidden(['D10', 'D12', 'B4', 'A9']),
        discardTop: 'B12',
      ),
      coach: (l) => l.tutQueenDone,
    ),
    TutorialStep(
      board: TutorialBoard(
        you: _hidden(['C2', 'A1', 'B6', 'A10']),
        opponent: _hidden(['D10', 'D12', 'B4', 'A9']),
        discardTop: 'B12',
      ),
      coach: (l) => l.tutQueenShuffle,
    ),
  ],
);

final _ending = TutorialLesson(
  id: 'ending',
  title: (l) => l.tutLessonEndTitle,
  suit: SuitShape.clubs,
  steps: [
    TutorialStep(
      board: TutorialBoard(
        you: _hidden(['C3', 'B2', 'D13', 'A14']),
        opponent: _hidden(['C9', 'B5', 'D7', 'A1']),
        discardTop: 'C4',
      ),
      coach: (l) => l.tutEndIntro,
    ),
    TutorialStep(
      board: TutorialBoard(
        you: _hidden(['C3', 'B2', 'D13', 'A14']),
        opponent: _hidden(['C9', 'B5', 'D7', 'A1']),
        discardTop: 'C4',
        actions: const [TutorialAction.endGame],
      ),
      coach: (l) => l.tutEndPress,
      expect: const TutorialTarget.action(TutorialAction.endGame),
    ),
    TutorialStep(
      board: TutorialBoard(
        you: _shown(['C3', 'B2', 'D13', 'A14']),
        opponent: _shown(['C9', 'B5', 'D7', 'A1']),
        discardTop: 'C4',
        choices: [(_) => '4', (_) => '6', (_) => '18'],
      ),
      coach: (l) => l.tutEndCount,
      expect: const TutorialTarget.choice(0),
      wrongHint: (l) => l.tutEndCountWrong,
    ),
    TutorialStep(
      board: TutorialBoard(
        you: _shown(['C3', 'B2', 'D13', 'A14']),
        opponent: _shown(['C9', 'B5', 'D7', 'A1']),
        discardTop: 'C4',
        choices: [
          (l) => l.tutChoiceYou,
          (l) => l.tutChoiceOpponent,
          (l) => l.tutChoiceTie,
        ],
      ),
      coach: (l) => l.tutEndWinner,
      expect: const TutorialTarget.choice(0),
      wrongHint: (l) => l.tutEndWinnerWrong,
    ),
    TutorialStep(
      board: TutorialBoard(
        you: _shown(['C3', 'B2', 'D13', 'A14']),
        opponent: _shown(['C9', 'B5', 'D7', 'A1']),
        discardTop: 'C4',
      ),
      coach: (l) => l.tutEndDone,
    ),
  ],
);

final _tips = TutorialLesson(
  id: 'tips',
  title: (l) => l.tutLessonTipsTitle,
  suit: SuitShape.spades,
  steps: [
    TutorialStep(
      board: TutorialBoard(
        you: [_up('C2'), _down('D3'), _up('B6'), _down('A10')],
        opponent: _hidden(_opponent),
        discardTop: 'D7',
      ),
      coach: (l) => l.tutTipMemory,
    ),
    TutorialStep(
      board: TutorialBoard(
        you: _shown(['D13', 'A14', 'A13', 'B14']),
        showTable: false,
      ),
      coach: (l) => l.tutTipKeepLow,
    ),
    TutorialStep(
      board: TutorialBoard(
        you: _hidden(['C2', 'D3', 'B6', 'A10']),
        opponent: _hidden(_opponent),
        discardTop: 'D7',
      ),
      coach: (l) => l.tutTipDiscard,
    ),
    TutorialStep(
      board: TutorialBoard(
        you: _hidden(['C2', 'D3', 'B6', 'A10']),
        opponent: _hidden(_opponent),
        discardTop: 'D7',
        drawnCard: 'C12',
      ),
      coach: (l) => l.tutTipQueen,
    ),
    TutorialStep(
      board: TutorialBoard(
        you: _hidden(['C2', 'D3', 'B6', 'A10']),
        opponent: _hidden(_opponent),
        discardTop: 'D7',
        actions: const [TutorialAction.endGame],
      ),
      coach: (l) => l.tutTipEnd,
    ),
  ],
);
