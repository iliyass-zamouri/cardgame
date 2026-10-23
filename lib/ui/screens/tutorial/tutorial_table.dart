import 'dart:math' as math;

import 'package:cardgame/l10n/l10n_ext.dart';
import 'package:cardgame/ui/screens/tutorial/tutorial_controller.dart';
import 'package:cardgame/ui/theme/app_icons.dart';
import 'package:cardgame/ui/theme/casino_chrome.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/theme/felt_chrome.dart';
import 'package:cardgame/ui/widgets/playing_card_face.dart';
import 'package:flutter/material.dart';

/// Mini table laid out like the real board: opponent row on top, deck and
/// discard in the middle, your row below, drawn card bottom-left and the
/// action buttons bottom-right.
class TutorialTable extends StatelessWidget {
  const TutorialTable({
    super.key,
    required this.board,
    required this.expect,
    required this.onTap,
  });

  final TutorialBoard board;

  /// The target that glows (the one the coach asks for).
  final TutorialTarget? expect;
  final ValueChanged<TutorialTarget> onTap;

  @override
  Widget build(BuildContext context) {
    if (board.valueChart) return const _ValueChart();
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxCards = math.max(
          4,
          math.max(board.you.length, board.opponent.length),
        );
        // Your row: up to 4 cards per row, sized by width and height.
        final byWidth = (constraints.maxWidth - 24 - (maxCards - 1) * 8) /
            maxCards;
        final byHeight = constraints.maxHeight * 0.19 / PlayingCardFace.aspect;
        final youW = math.min(76.0, math.min(byWidth, byHeight));
        final oppW = youW * 0.72;
        final tableW = youW * 0.95;
        return Column(
          children: [
            if (board.opponent.isNotEmpty) ...[
              _SeatLabel(context.l10n.tutChoiceOpponent),
              const SizedBox(height: 4),
              _CardRow(
                keyPrefix: 'opp',
                cards: board.opponent,
                width: oppW,
                targetFor: TutorialTarget.opponentCard,
                expect: expect,
                onTap: onTap,
              ),
            ],
            const Spacer(),
            if (board.showTable)
              Row(
                textDirection: TextDirection.ltr,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Labeled(
                    label: context.l10n.tutDeckLabel,
                    child: _Tappable(
                      key: const ValueKey('tut-deck'),
                      target: const TutorialTarget.deck(),
                      expect: expect,
                      onTap: onTap,
                      child: PlayingCardFace(
                        tag: null,
                        faceUp: false,
                        width: tableW,
                      ),
                    ),
                  ),
                  SizedBox(width: youW * 0.7),
                  _Labeled(
                    label: context.l10n.tutDiscardLabel,
                    child: _SwapIn(
                      id: board.discardTop ?? 'empty',
                      child:
                          board.discardTop == null
                              ? _EmptySlot(width: tableW)
                              : PlayingCardFace(
                                tag: board.discardTop,
                                width: tableW,
                              ),
                    ),
                  ),
                ],
              ),
            const Spacer(),
            if (board.you.isNotEmpty) ...[
              _CardRow(
                keyPrefix: 'you',
                cards: board.you,
                width: youW,
                targetFor: TutorialTarget.yourCard,
                expect: expect,
                onTap: onTap,
              ),
              const SizedBox(height: 4),
              _SeatLabel(context.l10n.tutChoiceYou),
            ],
            const SizedBox(height: 10),
            SizedBox(
              height: math.max(youW * PlayingCardFace.aspect, 56) + 18,
              child: Row(
                textDirection: TextDirection.ltr,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (board.drawnCard != null)
                    _Labeled(
                      label: context.l10n.tutDrawnLabel,
                      child: _SwapIn(
                        id: board.drawnCard!,
                        child: _Tappable(
                          key: const ValueKey('tut-drawn'),
                          target: const TutorialTarget.drawnCard(),
                          expect: expect,
                          onTap: onTap,
                          child: PlayingCardFace(
                            tag: board.drawnCard,
                            width: youW,
                          ),
                        ),
                      ),
                    ),
                  const Spacer(),
                  _ActionButtons(
                    actions: board.actions,
                    expect: expect,
                    onTap: onTap,
                  ),
                ],
              ),
            ),
            if (board.choices.isNotEmpty) ...[
              const SizedBox(height: 10),
              _Choices(choices: board.choices, onTap: onTap),
            ],
          ],
        );
      },
    );
  }
}

class _CardRow extends StatelessWidget {
  const _CardRow({
    required this.keyPrefix,
    required this.cards,
    required this.width,
    required this.targetFor,
    required this.expect,
    required this.onTap,
  });

  final String keyPrefix;
  final List<TutorialCard> cards;
  final double width;
  final TutorialTarget Function(int index) targetFor;
  final TutorialTarget? expect;
  final ValueChanged<TutorialTarget> onTap;

  @override
  Widget build(BuildContext context) {
    // The board grows extra (penalty) cards on a new row, 4 per row.
    return Wrap(
      // The Flame board is always left-to-right, even in Arabic.
      textDirection: TextDirection.ltr,
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < cards.length; i++)
          _Tappable(
            key: ValueKey('tut-$keyPrefix-$i'),
            target: targetFor(i),
            expect: expect,
            onTap: onTap,
            child: _SwapIn(
              id: '${cards[i].tag}-${cards[i].faceUp}',
              child: PlayingCardFace(
                tag: cards[i].tag,
                faceUp: cards[i].faceUp,
                width: width,
              ),
            ),
          ),
      ],
    );
  }
}

/// Wraps a tappable spot; glows when it is the expected target.
class _Tappable extends StatelessWidget {
  const _Tappable({
    super.key,
    required this.target,
    required this.expect,
    required this.onTap,
    required this.child,
  });

  final TutorialTarget target;
  final TutorialTarget? expect;
  final ValueChanged<TutorialTarget> onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(target),
      child: _Glow(active: expect == target, child: child),
    );
  }
}

class _Glow extends StatefulWidget {
  const _Glow({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<_Glow> createState() => _GlowState();
}

class _GlowState extends State<_Glow> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(_Glow oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    if (widget.active && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!widget.active && _pulse.isAnimating) {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;
    return AnimatedBuilder(
      animation: _pulse,
      child: widget.child,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_pulse.value);
        return Transform.translate(
          offset: Offset(0, -4 * t),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: CasinoColors.gold.withValues(alpha: 0.45 + 0.4 * t),
                  blurRadius: 10 + 10 * t,
                  spreadRadius: 1 + 3 * t,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
    );
  }
}

/// Pops a card in when [id] changes (draw, flip, swap, discard).
class _SwapIn extends StatelessWidget {
  const _SwapIn({required this.id, required this.child});

  final String id;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutBack,
      transitionBuilder:
          (child, animation) => ScaleTransition(
            scale: Tween(begin: 0.6, end: 1.0).animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          ),
      layoutBuilder:
          (current, previous) => Stack(
            alignment: Alignment.center,
            children: [...previous, if (current != null) current],
          ),
      child: KeyedSubtree(key: ValueKey(id), child: child),
    );
  }
}

class _EmptySlot extends StatelessWidget {
  const _EmptySlot({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: width * PlayingCardFace.aspect,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(width * 0.09),
        border: Border.all(color: CasinoColors.gold.withValues(alpha: 0.35)),
      ),
    );
  }
}

class _Labeled extends StatelessWidget {
  const _Labeled({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [child, const SizedBox(height: 4), _SeatLabel(label)],
    );
  }
}

class _SeatLabel extends StatelessWidget {
  const _SeatLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: CasinoColors.goldSoft,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.actions,
    required this.expect,
    required this.onTap,
  });

  final List<TutorialAction> actions;
  final TutorialTarget? expect;
  final ValueChanged<TutorialTarget> onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final action in actions) ...[
          if (action != actions.first) const SizedBox(height: 8),
          _Glow(
            active: expect == TutorialTarget.action(action),
            child: CasinoActionButton(
              label: switch (action) {
                TutorialAction.reveal => l10n.reveal,
                TutorialAction.peek => l10n.peek,
                TutorialAction.shuffle => l10n.shuffle,
                TutorialAction.replace => l10n.replace,
                TutorialAction.endGame => l10n.endGame,
              },
              icon: switch (action) {
                TutorialAction.reveal => AppIcons.visibility,
                TutorialAction.peek => AppIcons.zoomIn,
                TutorialAction.shuffle => AppIcons.shuffle,
                TutorialAction.replace => AppIcons.swapHoriz,
                TutorialAction.endGame => AppIcons.flag,
              },
              tone:
                  action == TutorialAction.endGame
                      ? CasinoActionTone.fold
                      : CasinoActionTone.raise,
              expanded: false,
              height: 46,
              onPressed: () => onTap(TutorialTarget.action(action)),
            ),
          ),
        ],
      ],
    );
  }
}

class _Choices extends StatelessWidget {
  const _Choices({required this.choices, required this.onTap});

  final List<TutorialText> choices;
  final ValueChanged<TutorialTarget> onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < choices.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: GoldButton(
              label: choices[i](context.l10n),
              compact: true,
              onPressed: () => onTap(TutorialTarget.choice(i)),
            ),
          ),
        ],
      ],
    );
  }
}

/// Every card value, with the board art.
class _ValueChart extends StatelessWidget {
  const _ValueChart();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final entries = <(String, String, String)>[
      ('C1', l10n.tutAceLabel, '1'),
      ('B7', l10n.tutNumberCardsLabel, '2–10'),
      ('A11', l10n.ruleJackLabel, '11'),
      ('C12', l10n.ruleQueenLabel, '12'),
      ('B13', l10n.tutRedKingLabel, '13'),
      ('D13', l10n.ruleBlackKingLabel, '0'),
      ('A14', l10n.ruleJokerLabel, '−1'),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileW = (constraints.maxWidth - 12) / 2;
        final cardW = math.min(
          46.0,
          (constraints.maxHeight / 4 - 10) / PlayingCardFace.aspect,
        );
        return SingleChildScrollView(
          child: Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              for (final (tag, label, value) in entries)
                SizedBox(
                  width: tileW,
                  child: IvoryCard(
                    radius: 12,
                    padding: const EdgeInsets.all(8),
                    highlighted: value == '0' || value == '−1',
                    child: Row(
                      children: [
                        PlayingCardFace(tag: tag, width: cardW),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            label,
                            style: const TextStyle(
                              color: Color(0xFF3D3020),
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                        Text(
                          value,
                          style: TextStyle(
                            fontFamily: CasinoFonts.display,
                            color:
                                value == '13' ? CardInk.red : CardInk.black,
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
