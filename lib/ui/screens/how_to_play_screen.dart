import 'package:cardgame/l10n/l10n_ext.dart';
import 'package:cardgame/ui/flame/card_game.dart';
import 'package:cardgame/ui/theme/casino_chrome.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class HowToPlayScreen extends StatefulWidget {
  const HowToPlayScreen({super.key});

  @override
  State<HowToPlayScreen> createState() => _HowToPlayScreenState();
}

class _HowToPlayScreenState extends State<HowToPlayScreen> {
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
    final displayFamily = CasinoFonts.displayFor(
      Localizations.localeOf(context),
    );
    return Scaffold(
      backgroundColor: CasinoColors.bg,
      appBar: AppBar(
        backgroundColor: CasinoColors.surface,
        foregroundColor: CasinoColors.text,
        title: Text(
          l10n.howToPlay,
          style: const TextStyle(
            color: CasinoColors.gold,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.stepOf(_index + 1, steps.length),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: CasinoColors.textMuted,
                  fontSize: 13,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < steps.length; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: i == _index ? 18 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color:
                            i == _index
                                ? CasinoColors.gold
                                : i < _index
                                ? CasinoColors.gold.withValues(alpha: 0.45)
                                : CasinoColors.surfaceHi,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 36),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: KeyedSubtree(
                    key: ValueKey(_index),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: CasinoColors.surfaceHi,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: CasinoColors.gold.withValues(
                                    alpha: 0.7,
                                  ),
                                  width: 1.4,
                                ),
                              ),
                              child: Text(
                                '${_index + 1}',
                                style: const TextStyle(
                                  color: CasinoColors.gold,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                step.title,
                                style: TextStyle(
                                  color: CasinoColors.text,
                                  fontFamily: displayFamily,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 26,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        Text(
                          step.body,
                          style: const TextStyle(
                            color: CasinoColors.textMuted,
                            fontSize: 17,
                            height: 1.45,
                          ),
                        ),
                        if (step.examples != null) ...[
                          const SizedBox(height: 20),
                          Expanded(
                            child: ListView.separated(
                              itemCount: step.examples!.length,
                              separatorBuilder:
                                  (_, _) => const SizedBox(height: 16),
                              itemBuilder: (context, i) {
                                final example = step.examples![i];
                                return _SpecialCardRow(example: example);
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  if (_index > 0) ...[
                    CasinoActionButton(
                      label: l10n.back,
                      tone: CasinoActionTone.check,
                      onPressed: _back,
                    ),
                    const SizedBox(width: 12),
                  ],
                  CasinoActionButton(
                    label: _isLast(steps.length) ? l10n.gotIt : l10n.next,
                    tone: CasinoActionTone.raise,
                    onPressed: () => _next(steps.length),
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

  static const _cardW = 72.0;
  static const _cardH = _cardW * 112 / 78;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: _cardW,
          height: _cardH,
          child: CustomPaint(painter: _DeckCardPainter(example.tag)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                example.label,
                style: const TextStyle(
                  color: CasinoColors.gold,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                example.description,
                style: const TextStyle(
                  color: CasinoColors.textMuted,
                  fontSize: 15,
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

/// Same face art as [DeckPreviewScreen] / the board.
class _DeckCardPainter extends CustomPainter {
  const _DeckCardPainter(this.tag);

  final String tag;

  @override
  void paint(Canvas canvas, Size size) {
    PlayingCardComponent(
      cardIndex: 0,
      tag: tag,
      visible: true,
      sizeOverride: Vector2(size.width, size.height),
    ).render(canvas);
  }

  @override
  bool shouldRepaint(_DeckCardPainter oldDelegate) => oldDelegate.tag != tag;
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
