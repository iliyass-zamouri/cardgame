import 'package:cardgame/app/auth_providers.dart';
import 'package:cardgame/l10n/l10n_ext.dart';
import 'package:cardgame/ui/flame/suit_shapes.dart';
import 'package:cardgame/ui/screens/tutorial/tutorial_lessons.dart';
import 'package:cardgame/ui/screens/tutorial/tutorial_progress_repository.dart';
import 'package:cardgame/ui/screens/tutorial/tutorial_screen.dart';
import 'package:cardgame/ui/theme/app_icons.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/theme/felt_chrome.dart';
import 'package:cardgame/ui/theme/game_icon.dart';
import 'package:cardgame/ui/widgets/playing_card_face.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lesson hub: hands-on tutorial lessons plus the one-page rules reference.
class HowToPlayScreen extends ConsumerStatefulWidget {
  const HowToPlayScreen({super.key, this.autoStart = false});

  /// Open straight into the first lesson (first-run prompt).
  final bool autoStart;

  @override
  ConsumerState<HowToPlayScreen> createState() => _HowToPlayScreenState();
}

class _HowToPlayScreenState extends ConsumerState<HowToPlayScreen> {
  final _lessons = tutorialLessons();
  late final _progress = ref.read(tutorialProgressRepositoryProvider);
  late Set<String> _completed = _progress.completed();

  @override
  void initState() {
    super.initState();
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _play(0);
      });
    }
  }

  Future<void> _markCompleted(String lessonId) async {
    if (_completed.contains(lessonId)) return;
    setState(() => _completed = {..._completed, lessonId});
    await _progress.markCompleted(lessonId);
  }

  void _play(int startIndex) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder:
            (_) => TutorialScreen(
              lessons: _lessons,
              startIndex: startIndex,
              onLessonCompleted: _markCompleted,
              onFinished:
                  () =>
                      ref
                          .read(playerProfileProvider.notifier)
                          .markTutorialDone()
                          .ignore(),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final nextIndex = _lessons.indexWhere((l) => !_completed.contains(l.id));
    return FeltScaffold(
      title: l10n.howToPlay,
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            FeltTileGroup(
              children: [
                FeltTile(
                  icon: AppIcons.rules,
                  title: l10n.tutQuickRules,
                  subtitle: l10n.tutQuickRulesSubtitle,
                  onTap:
                      () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const QuickRulesScreen(),
                        ),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            IvoryCard(
              radius: 18,
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.tutHubIntro,
                    style: const TextStyle(
                      color: Color(0xFF3D3020),
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  GoldButton(
                    label:
                        _completed.isEmpty || nextIndex < 0
                            ? l10n.tutStartAll
                            : l10n.tutContinue,
                    onPressed: () => _play(nextIndex < 0 ? 0 : nextIndex),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            FeltTileGroup(
              header: l10n.tutLessonsHeader,
              suit: SuitShape.hearts,
              children: [
                for (var i = 0; i < _lessons.length; i++)
                  FeltTile(
                    key: ValueKey('lesson-${_lessons[i].id}'),
                    leading: _LessonBadge(
                      number: i + 1,
                      suit: _lessons[i].suit,
                      done: _completed.contains(_lessons[i].id),
                    ),
                    title: _lessons[i].title(l10n),
                    onTap: () => _play(i),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonBadge extends StatelessWidget {
  const _LessonBadge({
    required this.number,
    required this.suit,
    required this.done,
  });

  final int number;
  final SuitShape suit;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? CasinoColors.success : CardInk.ivory,
        border: Border.all(color: CasinoColors.gold, width: 1.5),
      ),
      child:
          done
              ? const GameIcon(
                icon: AppIcons.check,
                color: Colors.white,
                size: 22,
              )
              : Text(
                '$number',
                style: TextStyle(
                  fontFamily: CasinoFonts.display,
                  color: suitColor(suit),
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
    );
  }
}

/// All the rules as a short card-by-card reference.
class QuickRulesScreen extends StatefulWidget {
  const QuickRulesScreen({super.key});

  @override
  State<QuickRulesScreen> createState() => _QuickRulesScreenState();
}

class _QuickRulesScreenState extends State<QuickRulesScreen> {
  int _index = 0;

  List<_RuleStep> _steps(AppLocalizations l10n) => [
    _RuleStep(title: l10n.ruleGoalTitle, body: l10n.ruleGoalBody),
    _RuleStep(title: l10n.ruleSetupTitle, body: l10n.ruleSetupBody),
    _RuleStep(title: l10n.ruleOpeningPeekTitle, body: l10n.ruleOpeningPeekBody),
    _RuleStep(title: l10n.ruleYourTurnTitle, body: l10n.ruleYourTurnBody),
    _RuleStep(title: l10n.ruleAfterDrawTitle, body: l10n.ruleAfterDrawBody),
    _RuleStep(
      title: l10n.ruleSpecialTitle,
      body: l10n.ruleSpecialBody,
      examples: [
        _CardExample(
          tag: 'C11',
          label: l10n.ruleJackLabel,
          description: l10n.ruleJackDesc,
        ),
        _CardExample(
          tag: 'C12',
          label: l10n.ruleQueenLabel,
          description: l10n.ruleQueenDesc,
        ),
      ],
    ),
    _RuleStep(
      title: l10n.ruleScoringTitle,
      body: l10n.ruleScoringBody,
      examples: [
        _CardExample(
          tag: 'A14',
          label: l10n.ruleJokerLabel,
          description: l10n.ruleJokerDesc,
        ),
        _CardExample(
          tag: 'A13',
          label: l10n.ruleBlackKingLabel,
          description: l10n.ruleBlackKingDesc,
        ),
      ],
    ),
  ];

  bool _isLast(int total) => _index >= total - 1;

  void _next(int total) {
    if (_isLast(total)) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _index++);
  }

  void _back() {
    if (_index == 0) return;
    setState(() => _index--);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final steps = _steps(l10n);
    if (_index >= steps.length) _index = steps.length - 1;
    final step = steps[_index];
    final suit = SuitShape.values[_index % SuitShape.values.length];
    final ink = suitColor(suit);
    final displayFamily = CasinoFonts.displayFor(
      Localizations.localeOf(context),
    );
    return FeltScaffold(
      title: l10n.tutQuickRules,
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.stepOf(_index + 1, steps.length),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: CasinoColors.goldSoft,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 10),
              // Progress as a row of suit pips.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < steps.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    AnimatedScale(
                      duration: const Duration(milliseconds: 200),
                      scale: i == _index ? 1.4 : 1,
                      child: SuitGlyph(
                        suit: SuitShape.values[i % SuitShape.values.length],
                        size: 11,
                        color:
                            i <= _index
                                ? CasinoColors.gold
                                : CasinoColors.gold.withValues(alpha: 0.25),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 18),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  layoutBuilder:
                      (current, previous) => Stack(
                        fit: StackFit.expand,
                        children: [...previous, if (current != null) current],
                      ),
                  child: IvoryCard(
                    key: ValueKey(_index),
                    radius: 20,
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Step number as the card's corner rank.
                            Column(
                              children: [
                                Text(
                                  '${_index + 1}',
                                  style: TextStyle(
                                    fontFamily: CasinoFonts.display,
                                    color: ink,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 30,
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                SuitGlyph(suit: suit, size: 18),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  step.title,
                                  style: TextStyle(
                                    color: CardInk.black,
                                    fontFamily: displayFamily,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 24,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          height: 1,
                          color: CardInk.goldLine.withValues(alpha: 0.6),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          step.body,
                          style: const TextStyle(
                            color: Color(0xFF3D3020),
                            fontSize: 16.5,
                            height: 1.45,
                          ),
                        ),
                        if (step.examples != null) ...[
                          const SizedBox(height: 18),
                          Expanded(
                            child: ListView.separated(
                              itemCount: step.examples!.length,
                              separatorBuilder:
                                  (_, _) => const SizedBox(height: 14),
                              itemBuilder: (context, i) {
                                final example = step.examples![i];
                                return _SpecialCardRow(example: example);
                              },
                            ),
                          ),
                        ] else
                          const Spacer(),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (_index > 0) ...[
                    Expanded(
                      child: LeatherButton(label: l10n.back, onPressed: _back),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: GoldButton(
                      label: _isLast(steps.length) ? l10n.gotIt : l10n.next,
                      onPressed: () => _next(steps.length),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpecialCardRow extends StatelessWidget {
  const _SpecialCardRow({required this.example});

  final _CardExample example;

  static const _cardW = 64.0;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        PlayingCardFace(tag: example.tag, width: _cardW),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                example.label,
                style: TextStyle(
                  fontFamily: CasinoFonts.displayOf(context),
                  color: CardInk.red,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                example.description,
                style: const TextStyle(
                  color: Color(0xFF3D3020),
                  fontSize: 14.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RuleStep {
  const _RuleStep({required this.title, required this.body, this.examples});

  final String title;
  final String body;
  final List<_CardExample>? examples;
}

class _CardExample {
  const _CardExample({
    required this.tag,
    required this.label,
    required this.description,
  });

  final String tag;
  final String label;
  final String description;
}
