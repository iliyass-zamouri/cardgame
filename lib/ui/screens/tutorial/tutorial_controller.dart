import 'dart:async';

import 'package:cardgame/l10n/l10n_ext.dart';
import 'package:cardgame/ui/flame/suit_shapes.dart';
import 'package:flutter/foundation.dart';

/// Localized text resolved at build time.
typedef TutorialText = String Function(AppLocalizations l10n);

/// HUD buttons a tutorial step can show (same labels as the real table).
enum TutorialAction { reveal, peek, shuffle, replace, endGame }

enum TutorialTargetKind { deck, drawnCard, yourCard, opponentCard, action, choice }

/// Something the player can tap on the tutorial table.
@immutable
class TutorialTarget {
  const TutorialTarget._(this.kind, {this.index = 0, this.action});

  const TutorialTarget.deck() : this._(TutorialTargetKind.deck);
  const TutorialTarget.drawnCard() : this._(TutorialTargetKind.drawnCard);
  const TutorialTarget.yourCard(int index)
    : this._(TutorialTargetKind.yourCard, index: index);
  const TutorialTarget.opponentCard(int index)
    : this._(TutorialTargetKind.opponentCard, index: index);
  const TutorialTarget.action(TutorialAction action)
    : this._(TutorialTargetKind.action, action: action);
  const TutorialTarget.choice(int index)
    : this._(TutorialTargetKind.choice, index: index);

  final TutorialTargetKind kind;
  final int index;
  final TutorialAction? action;

  @override
  bool operator ==(Object other) =>
      other is TutorialTarget &&
      other.kind == kind &&
      other.index == index &&
      other.action == action;

  @override
  int get hashCode => Object.hash(kind, index, action);

  @override
  String toString() => 'TutorialTarget($kind, $index, $action)';
}

@immutable
class TutorialCard {
  const TutorialCard(this.tag, {this.faceUp = false});

  /// Card tag in the engine format (`C7`, `A14`…), see `card_utils.dart`.
  final String tag;
  final bool faceUp;
}

/// Snapshot of the mini table for one step.
@immutable
class TutorialBoard {
  const TutorialBoard({
    this.you = const [],
    this.opponent = const [],
    this.discardTop,
    this.drawnCard,
    this.actions = const [],
    this.choices = const [],
    this.showTable = true,
    this.valueChart = false,
  });

  final List<TutorialCard> you;
  final List<TutorialCard> opponent;
  final String? discardTop;

  /// Card you just drew (face up, tap it to throw).
  final String? drawnCard;
  final List<TutorialAction> actions;

  /// Quiz answers shown as buttons under the table.
  final List<TutorialText> choices;

  /// Deck and discard pile visible.
  final bool showTable;

  /// Show the card value chart instead of the table.
  final bool valueChart;
}

@immutable
class TutorialStep {
  const TutorialStep({
    required this.board,
    required this.coach,
    this.expect,
    this.wrongHint,
    this.autoAdvance,
  });

  final TutorialBoard board;
  final TutorialText coach;

  /// What the player must tap; `null` means the step waits for "Next"
  /// (or [autoAdvance]).
  final TutorialTarget? expect;

  /// Shown when the player taps something else.
  final TutorialText? wrongHint;

  /// Timed steps (opening peek, Jack peek) move on by themselves.
  final Duration? autoAdvance;

  bool get waitsForNext => expect == null && autoAdvance == null;
}

@immutable
class TutorialLesson {
  const TutorialLesson({
    required this.id,
    required this.title,
    required this.suit,
    required this.steps,
  });

  final String id;
  final TutorialText title;
  final SuitShape suit;
  final List<TutorialStep> steps;
}

enum TutorialTapResult { advanced, wrong, ignored }

/// Plays one [TutorialLesson] step by step.
class TutorialController extends ChangeNotifier {
  TutorialController(this.lesson) {
    _armTimer();
  }

  final TutorialLesson lesson;

  int _stepIndex = 0;
  bool _completed = false;
  TutorialText? _hint;
  int _wrongTaps = 0;
  Timer? _timer;

  int get stepIndex => _stepIndex;
  TutorialStep get step => lesson.steps[_stepIndex];
  bool get completed => _completed;

  /// Correction shown after a wrong tap; cleared on the next step.
  TutorialText? get hint => _hint;

  /// Bumped on each wrong tap so the table can replay its shake.
  int get wrongTaps => _wrongTaps;

  bool get isLastStep => _stepIndex >= lesson.steps.length - 1;

  TutorialTapResult tap(TutorialTarget target) {
    if (_completed) return TutorialTapResult.ignored;
    final expected = step.expect;
    if (expected == null) return TutorialTapResult.ignored;
    if (expected == target) {
      _advance();
      return TutorialTapResult.advanced;
    }
    _hint = step.wrongHint ?? (l10n) => l10n.tutTapHighlighted;
    _wrongTaps += 1;
    notifyListeners();
    return TutorialTapResult.wrong;
  }

  /// "Next" on steps that don't expect a tap.
  void next() {
    if (_completed || !step.waitsForNext) return;
    _advance();
  }

  void restart() {
    _timer?.cancel();
    _stepIndex = 0;
    _completed = false;
    _hint = null;
    _armTimer();
    notifyListeners();
  }

  void _advance() {
    _timer?.cancel();
    _hint = null;
    if (isLastStep) {
      _completed = true;
    } else {
      _stepIndex += 1;
      _armTimer();
    }
    notifyListeners();
  }

  void _armTimer() {
    final delay = step.autoAdvance;
    if (delay == null) return;
    _timer = Timer(delay, _advance);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
