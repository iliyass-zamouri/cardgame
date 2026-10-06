import 'package:cardgame/app/auth_providers.dart';
import 'package:cardgame/l10n/l10n_ext.dart';
import 'package:cardgame/ui/screens/marketplace_screen.dart';
import 'package:cardgame/ui/theme/app_icons.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/theme/felt_chrome.dart';
import 'package:cardgame/ui/widgets/currency_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

/// Money per chip on the server exchange (`MONEY_PER_CHIP`).
const _moneyPerChip = 1000;

/// Shown when the player can't cover a stake (e.g. a rematch): offers to
/// exchange chips for money or open the store. Resolves to true once the
/// balance covers [required].
class InsufficientFundsSheet extends ConsumerWidget {
  const InsufficientFundsSheet({super.key, required this.required});

  final int required;

  static Future<bool> show(
    BuildContext context, {
    required int required,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InsufficientFundsSheet(required: required),
    );
    if (!context.mounted) return false;
    final container = ProviderScope.containerOf(context, listen: false);
    final money = container.read(playerProfileProvider).value?.money ?? 0;
    return money >= required;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final profile = ref.watch(playerProfileProvider).value;
    final money = profile?.money ?? 0;
    final chips = profile?.chips ?? 0;
    final shortfall = (required - money).clamp(0, required);
    final chipsNeeded = (shortfall / _moneyPerChip).ceil().clamp(1, 1 << 30);
    final covered = money >= required;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [CasinoColors.leather, CasinoColors.leatherDeep],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: CasinoColors.gold, width: 1.5)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const CashIcon(size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.notEnoughMoneyTitle,
                    style: TextStyle(
                      color: CasinoColors.gold,
                      fontWeight: FontWeight.w800,
                      fontFamily: CasinoFonts.displayOf(context),
                      fontSize: 18,
                    ),
                  ),
                ),
                FeltIconButton(
                  icon: AppIcons.close,
                  size: 36,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              covered
                  ? l10n.stakeCovered
                  : l10n.notEnoughMoneyMessage(required, money),
              style: const TextStyle(color: CasinoColors.text, fontSize: 14),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: feltPanelDecoration(radius: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _Balance(icon: const CashIcon(size: 18), value: money),
                  _Balance(icon: const ChipIcon(size: 18), value: chips),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (covered)
              GoldButton(
                label: l10n.rematch,
                onPressed: () => Navigator.of(context).pop(),
              )
            else ...[
              GoldButton(
                label: l10n.exchangeChips,
                leading: const HugeIcon(icon: AppIcons.swapHoriz),
                onPressed:
                    chips > 0
                        ? () => CurrencyConversionModal.show(
                          context,
                          initialChipsToConvert: chipsNeeded.clamp(1, chips),
                        )
                        : null,
              ),
              const SizedBox(height: 10),
              LeatherButton(
                label: l10n.buyMoney,
                leading: const HugeIcon(icon: AppIcons.shoppingBag),
                onPressed:
                    () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const MarketplaceScreen(),
                      ),
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Balance extends StatelessWidget {
  const _Balance({required this.icon, required this.value});

  final Widget icon;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        icon,
        const SizedBox(width: 6),
        Text(
          '$value',
          style: const TextStyle(
            color: CasinoColors.text,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}
