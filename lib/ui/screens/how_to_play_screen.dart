import 'package:cardgame/l10n/l10n_ext.dart';
import 'package:cardgame/ui/flame/card_game.dart';
import 'package:cardgame/ui/flame/suit_shapes.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:cardgame/ui/theme/felt_chrome.dart';

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
    final suit = SuitShape.values[_index % SuitShape.values.length];
    final ink = suitColor(suit);
    final displayFamily = CasinoFonts.displayFor(
      Localizations.localeOf(context),
    );
    return FeltScaffold(
      title: l10n.howToPlay,
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
                style: const TextStyle(
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
  static const _cardH = _cardW * 112 / 78;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: _cardW,
          height: _cardH,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            boxShadow: const [
              BoxShadow(
                color: Color(0x40000000),
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: CustomPaint(painter: _DeckCardPainter(example.tag)),
        ),
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
