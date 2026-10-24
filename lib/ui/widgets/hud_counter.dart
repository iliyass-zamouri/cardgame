import 'dart:math' as math;

import 'package:cardgame/data/avatars/avatar_catalog.dart';
import 'package:cardgame/ui/theme/app_icons.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/theme/felt_chrome.dart';
import 'package:cardgame/ui/theme/game_icon.dart';
import 'package:cardgame/ui/widgets/amount_format.dart';
import 'package:cardgame/ui/widgets/counting_amount.dart';
import 'package:cardgame/ui/widgets/currency_icon.dart';
import 'package:flutter/material.dart';

/// The top bar's money or chip counter: the coin overlapping a recessed
/// track, the amount, and a gold "+" at the end. A rise (a reward landing, a
/// pot won) counts up with a little bump. [lit] rims it in glowing gold, for
/// the moment a reward lands in it.
class HudCounter extends StatefulWidget {
  const HudCounter({
    super.key,
    required this.currency,
    required this.value,
    this.lit = false,
  });

  final CurrencyType currency;
  final int value;
  final bool lit;

  static const height = 36.0;

  @override
  State<HudCounter> createState() => _HudCounterState();
}

class _HudCounterState extends State<HudCounter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bump = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void didUpdateWidget(HudCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value > oldWidget.value &&
        !MediaQuery.disableAnimationsOf(context)) {
      _bump.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _bump.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final gold = CasinoColors.gold;
    final counter = SizedBox(
      height: HudCounter.height,
      child: Stack(
        alignment: AlignmentDirectional.centerStart,
        children: [
          Container(
            height: 30,
            margin: const EdgeInsetsDirectional.only(start: 14),
            padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 3, 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.7),
                  Colors.black.withValues(alpha: 0.4),
                ],
              ),
              border: Border.all(
                color: gold.withValues(alpha: widget.lit ? 0.95 : 0.4),
                width: widget.lit ? 1.4 : 1,
              ),
              boxShadow:
                  widget.lit
                      ? [
                        BoxShadow(
                          color: gold.withValues(alpha: 0.55),
                          blurRadius: 14,
                          spreadRadius: 1,
                        ),
                      ]
                      : null,
            ),
            child: Row(
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: CountingAmount(
                      value: widget.value,
                      builder:
                          (context, shown) => Text(
                            compactAmount(shown),
                            maxLines: 1,
                            style: TextStyle(
                              fontFamily: CasinoFonts.displayFor(locale),
                              color:
                                  widget.lit
                                      ? CasinoColors.goldHi
                                      : CasinoColors.goldSoft,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              height: 1.2,
                            ),
                          ),
                    ),
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        CasinoColors.goldHi,
                        CasinoColors.gold,
                        CasinoColors.goldLo,
                      ],
                    ),
                    border: Border.all(color: const Color(0xFF7A5A0E)),
                  ),
                  child: const GameIcon(
                    icon: AppIcons.add,
                    size: 16,
                    color: CardInk.black,
                  ),
                ),
              ],
            ),
          ),
          CurrencyIcon(currency: widget.currency, size: 30),
        ],
      ),
    );
    return AnimatedBuilder(
      animation: _bump,
      builder:
          (context, child) => Transform.scale(
            scale: 1 + 0.08 * math.sin(_bump.value * math.pi),
            child: child,
          ),
      child: counter,
    );
  }
}
