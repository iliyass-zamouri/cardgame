import 'package:cardgame/data/ranking/ranking_api.dart';
import 'package:cardgame/l10n/l10n_ext.dart';
import 'package:cardgame/ui/flame/suit_shapes.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/theme/felt_chrome.dart';
import 'package:cardgame/ui/widgets/match_history_stake.dart';
import 'package:flutter/material.dart';

/// One ranked match: result card, opponent, pot, Elo, and XP.
class MatchHistoryCard extends StatelessWidget {
  const MatchHistoryCard({super.key, required this.item});

  final MatchHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isWin = item.result.toLowerCase() == 'win';
    final isLoss = item.result.toLowerCase() == 'loss';

    final (resultLabel, resultInk, suit) =
        isWin
            ? (l10n.matchResultWin, const Color(0xFF1E7A45), SuitShape.spades)
            : isLoss
            ? (l10n.matchResultLoss, CardInk.red, SuitShape.hearts)
            : (l10n.matchResultDraw, const Color(0xFF6B5A3A), SuitShape.clubs);

    final eloSign =
        item.eloDelta >= 0 ? '+${item.eloDelta}' : '${item.eloDelta}';
    final eloColor =
        isWin
            ? CasinoColors.raiseHi
            : (isLoss ? CasinoColors.foldHi : CasinoColors.goldSoft);

    return FeltPanel(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [CardInk.ivory, CardInk.ivoryShade],
              ),
              border: Border.all(color: resultInk.withValues(alpha: 0.6)),
            ),
            padding: const EdgeInsets.all(4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SuitGlyph(suit: suit, size: 16, color: resultInk),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    item.quit ? l10n.matchResultQuit : resultLabel,
                    style: TextStyle(
                      color: resultInk,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l10n.vs} ${item.opponentName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: CasinoColors.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  l10n.matchScoreLine(item.cardTotal, item.opponentCardTotal),
                  style: const TextStyle(
                    color: CasinoColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                MatchHistoryStakeLine(item: item),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$eloSign ${l10n.elo}',
                style: TextStyle(
                  color: eloColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${item.pointsEarned >= 0 ? '+' : ''}${item.pointsEarned} ${l10n.xp}',
                style: const TextStyle(
                  color: CasinoColors.goldSoft,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
