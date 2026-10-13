import 'package:cardgame/data/avatars/avatar_catalog.dart';
import 'package:cardgame/data/ranking/ranking_api.dart';
import 'package:cardgame/l10n/l10n_ext.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/theme/city_theme.dart';
import 'package:cardgame/ui/widgets/currency_icon.dart';
import 'package:flutter/material.dart';

/// City name for the pot this match was played at, or null when unstaked.
String? matchPotCityName(AppLocalizations l10n, MatchHistoryItem item) {
  final city = CityTheme.forStake(
    item.potAmount,
    chips: item.stakeCurrency == 'chips',
  );
  if (city == null) return null;
  return switch (city.id) {
    'london' => l10n.cityLondon,
    'paris' => l10n.cityParis,
    'moscow' => l10n.cityMoscow,
    'cairo' => l10n.cityCairo,
    'marrakech' => l10n.cityMarrakech,
    'toronto' => l10n.cityToronto,
    'new_york' => l10n.cityNewYork,
    'tokyo' => l10n.cityTokyo,
    _ => null,
  };
}

/// City pot and the signed coin or chip result. Hidden when nothing was staked.
class MatchHistoryStakeLine extends StatelessWidget {
  const MatchHistoryStakeLine({super.key, required this.item});

  final MatchHistoryItem item;

  @override
  Widget build(BuildContext context) {
    if (item.stakePerPlayer <= 0) return const SizedBox.shrink();
    final city = matchPotCityName(context.l10n, item);
    final delta = item.balanceDelta;
    final color =
        delta > 0
            ? const Color(0xFF5DCF8A)
            : delta < 0
            ? const Color(0xFFE07070)
            : CasinoColors.textMuted;
    final sign = delta > 0 ? '+' : '';
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          if (city != null) ...[
            Flexible(
              child: Text(
                city,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: CasinoColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            '$sign$delta',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 4),
          CurrencyIcon(
            currency:
                item.stakeCurrency == 'chips'
                    ? CurrencyType.chips
                    : CurrencyType.money,
            size: 14,
          ),
        ],
      ),
    );
  }
}
