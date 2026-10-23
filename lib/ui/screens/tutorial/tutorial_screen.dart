import 'dart:math' as math;

import 'package:cardgame/l10n/l10n_ext.dart';
import 'package:cardgame/ui/screens/tutorial/tutorial_controller.dart';
import 'package:cardgame/ui/screens/tutorial/tutorial_table.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/theme/felt_chrome.dart';
import 'package:flutter/material.dart';

/// Plays [lessons] from [startIndex] onward, one hands-on lesson at a time.
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({
    super.key,
    required this.lessons,
    this.startIndex = 0,
    this.onLessonCompleted,
    this.onFinished,
  });

  final List<TutorialLesson> lessons;
  final int startIndex;
  final ValueChanged<String>? onLessonCompleted;

  /// Called once the last lesson is done.
  final VoidCallback? onFinished;

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  late int _lessonIndex = widget.startIndex;
  late TutorialController _controller = _controllerFor(_lessonIndex);
  bool _finished = false;

  TutorialController _controllerFor(int index) =>
      TutorialController(widget.lessons[index])..addListener(_onChange);

  void _onChange() {
    if (_controller.completed) {
      widget.onLessonCompleted?.call(_controller.lesson.id);
    }
    setState(() {});
  }

  void _goToLesson(int index) {
    _controller
      ..removeListener(_onChange)
      ..dispose();
    setState(() {
      _lessonIndex = index;
      _controller = _controllerFor(index);
    });
  }

  void _nextLesson() {
    if (_lessonIndex >= widget.lessons.length - 1) {
      widget.onFinished?.call();
      setState(() => _finished = true);
      return;
    }
    _goToLesson(_lessonIndex + 1);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onChange)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lesson = _controller.lesson;
    return FeltScaffold(
      title: l10n.howToPlay,
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child:
              _finished
                  ? _FinishedCard(onDone: () => Navigator.of(context).pop())
                  : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _LessonHeader(
                        title: lesson.title(l10n),
                        index: _lessonIndex,
                        total: widget.lessons.length,
                        stepIndex: _controller.stepIndex,
                        stepCount: lesson.steps.length,
                        completed: _controller.completed,
                      ),
                      const SizedBox(height: 10),
                      _CoachBubble(
                        text: _controller.step.coach(l10n),
                        hint: _controller.hint?.call(l10n),
                        shake: _controller.wrongTaps,
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            TutorialTable(
                              board: _controller.step.board,
                              expect:
                                  _controller.completed
                                      ? null
                                      : _controller.step.expect,
                              onTap: _controller.tap,
                            ),
                            if (_controller.completed)
                              _LessonDoneOverlay(
                                isLast:
                                    _lessonIndex >= widget.lessons.length - 1,
                                onReplay: _controller.restart,
                                onNext: _nextLesson,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _BottomBar(
                        controller: _controller,
                        onSkip: _nextLesson,
                      ),
                    ],
                  ),
        ),
      ),
    );
  }
}

class _LessonHeader extends StatelessWidget {
  const _LessonHeader({
    required this.title,
    required this.index,
    required this.total,
    required this.stepIndex,
    required this.stepCount,
    required this.completed,
  });

  final String title;
  final int index;
  final int total;
  final int stepIndex;
  final int stepCount;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final progress = completed ? 1.0 : stepIndex / stepCount;
    return Column(
      children: [
        Text(
          context.l10n.tutLessonProgress(index + 1, total),
          style: TextStyle(
            color: CasinoColors.goldSoft,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: CasinoColors.text,
            fontFamily: CasinoFonts.displayFor(Localizations.localeOf(context)),
            fontWeight: FontWeight.w800,
            fontSize: 21,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: progress),
            duration: const Duration(milliseconds: 250),
            builder:
                (context, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 5,
                  backgroundColor: CasinoColors.gold.withValues(alpha: 0.18),
                  color: CasinoColors.gold,
                ),
          ),
        ),
      ],
    );
  }
}

class _CoachBubble extends StatelessWidget {
  const _CoachBubble({
    required this.text,
    required this.hint,
    required this.shake,
  });

  final String text;
  final String? hint;

  /// Changes on every wrong tap to replay the shake.
  final int shake;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(shake),
      tween: Tween(begin: shake == 0 ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 420),
      builder:
          (context, t, child) => Transform.translate(
            offset: Offset(math.sin(t * math.pi * 6) * 8 * (1 - t), 0),
            child: child,
          ),
      child: IvoryCard(
        radius: 16,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                text,
                style: const TextStyle(
                  color: Color(0xFF3D3020),
                  fontSize: 15.5,
                  height: 1.4,
                ),
              ),
              if (hint != null) ...[
                const SizedBox(height: 8),
                Text(
                  hint!,
                  style: const TextStyle(
                    color: CardInk.red,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.controller, required this.onSkip});

  final TutorialController controller;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (controller.completed) return const SizedBox(height: 48);
    return Row(
      children: [
        Expanded(child: LeatherButton(label: l10n.tutSkip, onPressed: onSkip)),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: GoldButton(
            label: l10n.next,
            // Steps that need a tap on the table keep Next disabled.
            onPressed: controller.step.waitsForNext ? controller.next : null,
          ),
        ),
      ],
    );
  }
}

class _LessonDoneOverlay extends StatelessWidget {
  const _LessonDoneOverlay({
    required this.isLast,
    required this.onReplay,
    required this.onNext,
  });

  final bool isLast;
  final VoidCallback onReplay;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ColoredBox(
      color: const Color(0x99000000),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: IvoryCard(
            radius: 20,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: CasinoColors.success,
                  size: 44,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.tutLessonDone,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: CardInk.black,
                    fontFamily: CasinoFonts.displayFor(
                      Localizations.localeOf(context),
                    ),
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: LeatherButton(
                        label: l10n.tutReplay,
                        onPressed: onReplay,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: GoldButton(
                        label: isLast ? l10n.tutFinish : l10n.tutNextLesson,
                        onPressed: onNext,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FinishedCard extends StatelessWidget {
  const _FinishedCard({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: IvoryCard(
        radius: 20,
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events_rounded,
              color: CasinoColors.gold,
              size: 56,
            ),
            const SizedBox(height: 10),
            Text(
              l10n.tutCompleteTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: CardInk.black,
                fontFamily: CasinoFonts.displayFor(
                  Localizations.localeOf(context),
                ),
                fontWeight: FontWeight.w800,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.tutCompleteBody,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF3D3020),
                fontSize: 15.5,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            GoldButton(label: l10n.gotIt, onPressed: onDone),
          ],
        ),
      ),
    );
  }
}
