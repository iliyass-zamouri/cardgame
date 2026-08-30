import 'package:cardgame/ads/interstitial_ad_service.dart';
import 'package:cardgame/app/auth_providers.dart';
import 'package:cardgame/app/game_session_controller.dart';
import 'package:cardgame/l10n/app_localizations.dart';
import 'package:cardgame/l10n/l10n_ext.dart';
import 'package:cardgame/ui/screens/marketplace_screen.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/widgets/currency_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PotOption {
  const PotOption({
    required this.id,
    required this.assetPath,
    required this.pool,
    required this.nameBuilder,
  });

  final String id;
  final String assetPath;
  final int pool;
  final String Function(AppLocalizations l10n) nameBuilder;

  int get entryStake => pool ~/ 2;
}

Future<void> showStakeSelectorModal(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const StakeSelectorModal(),
  );
}

class StakeSelectorModal extends ConsumerWidget {
  const StakeSelectorModal({super.key});

  static const List<int> stakePools = [20, 50, 100, 200, 500];

  static final List<PotOption> potOptions = [
    PotOption(
      id: 'london',
      assetPath: 'assets/pots/london.png',
      pool: 20,
      nameBuilder: (l10n) => l10n.cityLondon,
    ),
    PotOption(
      id: 'paris',
      assetPath: 'assets/pots/paris.png',
      pool: 50,
      nameBuilder: (l10n) => l10n.cityParis,
    ),
    PotOption(
      id: 'moscow',
      assetPath: 'assets/pots/moscow.png',
      pool: 100,
      nameBuilder: (l10n) => l10n.cityMoscow,
    ),
    PotOption(
      id: 'cairo',
      assetPath: 'assets/pots/cairo.png',
      pool: 200,
      nameBuilder: (l10n) => l10n.cityCairo,
    ),
    PotOption(
      id: 'marrakech',
      assetPath: 'assets/pots/marrakech.png',
      pool: 500,
      nameBuilder: (l10n) => l10n.cityMarrakech,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final profile = ref.watch(playerProfileProvider).value;
    final playerMoney = profile?.money ?? 0;
    final playerChips = profile?.chips ?? 0;
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.85;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: CasinoColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Colors.white12, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: mediaQuery.viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.selectMatchStake,
                    style: TextStyle(
                      color: CasinoColors.text,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      fontFamily: CasinoFonts.displayOf(context),
                      letterSpacing: 0.8,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: CasinoColors.textMuted,
                      size: 20,
                    ),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: CasinoColors.bgElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const CashIcon(size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '$playerMoney',
                          style: const TextStyle(
                            color: CasinoColors.text,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const ChipIcon(size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '$playerChips',
                          style: const TextStyle(
                            color: CasinoColors.goldSoft,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const MarketplaceScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: CasinoColors.gold.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: CasinoColors.gold.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          l10n.marketplace,
                          style: const TextStyle(
                            color: CasinoColors.gold,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: potOptions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final option = potOptions[index];
                    final canAfford = playerMoney >= option.entryStake;
                    final cityName = option.nameBuilder(l10n);

                    return _PotBannerCard(
                      option: option,
                      cityName: cityName,
                      canAfford: canAfford,
                      onTap: () async {
                        if (canAfford) {
                          final adService = ref.read(interstitialAdProvider);
                          final sessionNotifier = ref.read(
                            gameSessionProvider.notifier,
                          );
                          Navigator.of(context).pop();
                          await adService.show();
                          sessionNotifier.findMatch(stakePool: option.pool);
                        } else {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const MarketplaceScreen(),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PotBannerCard extends StatelessWidget {
  const _PotBannerCard({
    required this.option,
    required this.cityName,
    required this.canAfford,
    required this.onTap,
  });

  final PotOption option;
  final String cityName;
  final bool canAfford;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      height: 94,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              canAfford
                  ? CasinoColors.gold.withValues(alpha: 0.32)
                  : Colors.white10,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Banner Background
            Image.asset(
              option.assetPath,
              fit: BoxFit.cover,
              errorBuilder:
                  (_, __, ___) => Container(color: CasinoColors.bgElevated),
            ),
            // Minimalist dark scrim: transparent on left, dark on right & dark extended from bottom
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomRight,
                  end: Alignment.topLeft,
                  colors: [
                    Colors.black.withValues(alpha: canAfford ? 0.94 : 0.97),
                    Colors.black.withValues(alpha: canAfford ? 0.72 : 0.86),
                    Colors.black.withValues(alpha: canAfford ? 0.35 : 0.55),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.40, 0.70, 1.0],
                ),
              ),
            ),
            // Bottom baseline darkness for text legibility across entire width
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: canAfford ? 0.75 : 0.88),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.45],
                ),
              ),
            ),
            // Card Content & Tap Target
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                splashColor: CasinoColors.gold.withValues(alpha: 0.12),
                highlightColor: Colors.white.withValues(alpha: 0.05),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              cityName.toUpperCase(),
                              style: TextStyle(
                                fontFamily: CasinoFonts.displayOf(context),
                                color:
                                    canAfford
                                        ? CasinoColors.goldSoft
                                        : CasinoColors.textMuted,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Text(
                                  '${l10n.prize}: ${option.pool} ',
                                  style: TextStyle(
                                    color:
                                        canAfford
                                            ? CasinoColors.text
                                            : CasinoColors.textMuted,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const CashIcon(size: 14),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Text(
                                  '${l10n.entryFee}: ${option.entryStake} ',
                                  style: const TextStyle(
                                    color: CasinoColors.textMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const CashIcon(size: 11),
                                Text(
                                  ' · ${l10n.winnerTakesAll}',
                                  style: TextStyle(
                                    color: CasinoColors.textMuted.withValues(
                                      alpha: 0.75,
                                    ),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color:
                              canAfford
                                  ? CasinoColors.raise
                                  : Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                canAfford
                                    ? CasinoColors.raiseHi.withValues(
                                      alpha: 0.6,
                                    )
                                    : CasinoColors.gold.withValues(alpha: 0.35),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!canAfford) ...[
                              const CashIcon(size: 12),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              canAfford ? l10n.play : l10n.getMoreMoney,
                              style: TextStyle(
                                color:
                                    canAfford
                                        ? Colors.white
                                        : CasinoColors.gold,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                                letterSpacing: 0.5,
                              ),
                            ),
                            if (canAfford) ...[
                              const SizedBox(width: 2),
                              const Icon(
                                Icons.play_arrow_rounded,
                                size: 15,
                                color: Colors.white,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
