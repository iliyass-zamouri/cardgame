import 'package:cardgame/ads/interstitial_ad_service.dart';
import 'package:cardgame/app/auth_providers.dart';
import 'package:cardgame/app/game_session_controller.dart';
import 'package:cardgame/l10n/app_localizations.dart';
import 'package:cardgame/l10n/l10n_ext.dart';
import 'package:cardgame/ui/screens/marketplace_screen.dart';
import 'package:cardgame/ui/theme/app_icons.dart';
import 'package:cardgame/ui/theme/casino_chrome.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/widgets/currency_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

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
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(builder: (_) => const StakeSelectorScreen()),
  );
}

class StakeSelectorScreen extends ConsumerStatefulWidget {
  const StakeSelectorScreen({super.key});

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
  ConsumerState<StakeSelectorScreen> createState() =>
      _StakeSelectorScreenState();
}

class _StakeSelectorScreenState extends ConsumerState<StakeSelectorScreen> {
  /// Card height + vertical gap so wheel snaps like a year picker.
  static const double _cardHeight = 148;
  static const double _itemExtent = 164;

  late final FixedExtentScrollController _wheelController;
  int _selectedIndex = 0;
  bool _didInitIndex = false;

  @override
  void initState() {
    super.initState();
    _wheelController = FixedExtentScrollController(initialItem: 0);
  }

  @override
  void dispose() {
    _wheelController.dispose();
    super.dispose();
  }

  void _ensureInitialIndex(int playerMoney) {
    if (_didInitIndex) return;
    _didInitIndex = true;
    final idx = StakeSelectorScreen.potOptions.indexWhere(
      (o) => playerMoney >= o.entryStake,
    );
    final initial = idx >= 0 ? idx : 0;
    if (initial == 0) {
      _selectedIndex = 0;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _wheelController.jumpToItem(initial);
      setState(() => _selectedIndex = initial);
    });
  }

  Future<void> _onPlay(PotOption option, bool canAfford) async {
    if (canAfford) {
      final adService = ref.read(interstitialAdProvider);
      final sessionNotifier = ref.read(gameSessionProvider.notifier);
      Navigator.of(context).pop();
      await adService.show();
      sessionNotifier.findMatch(stakePool: option.pool);
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const MarketplaceScreen()),
      );
    }
  }

  void _openMarketplace() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const MarketplaceScreen()));
  }

  void _snapTo(int index) {
    _wheelController.animateToItem(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final profile = ref.watch(playerProfileProvider).value;
    final playerMoney = profile?.money ?? 0;
    final playerChips = profile?.chips ?? 0;
    _ensureInitialIndex(playerMoney);

    final options = StakeSelectorScreen.potOptions;
    final selected = options[_selectedIndex.clamp(0, options.length - 1)];
    final canAfford = playerMoney >= selected.entryStake;

    return Scaffold(
      backgroundColor: CasinoColors.bg,
      appBar: AppBar(
        backgroundColor: CasinoColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const HugeIcon(
            icon: AppIcons.arrowBack,
            color: CasinoColors.text,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.selectMatchStake,
          style: TextStyle(
            color: CasinoColors.gold,
            fontWeight: FontWeight.w800,
            fontFamily: CasinoFonts.displayOf(context),
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: _BalanceStrip(
                playerMoney: playerMoney,
                playerChips: playerChips,
                marketplaceLabel: l10n.marketplace,
                onMarketplace: _openMarketplace,
              ),
            ),
            Expanded(
              child: ListWheelScrollView.useDelegate(
                controller: _wheelController,
                itemExtent: _itemExtent,
                physics: const FixedExtentScrollPhysics(),
                diameterRatio: 2.2,
                perspective: 0.002,
                useMagnifier: true,
                magnification: 1.08,
                overAndUnderCenterOpacity: 0.4,
                onSelectedItemChanged: (index) {
                  setState(() => _selectedIndex = index);
                },
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: options.length,
                  builder: (context, index) {
                    final option = options[index];
                    final affordable = playerMoney >= option.entryStake;
                    final selected = index == _selectedIndex;
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 7,
                      ),
                      child: _PotBannerCard(
                        option: option,
                        cityName: option.nameBuilder(l10n),
                        canAfford: affordable,
                        selected: selected,
                        height: _cardHeight,
                        onTap: () => _snapTo(index),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Center(
                child: SizedBox(
                  width: 160,
                  child: Row(
                    children: [
                      CasinoActionButton(
                        label: canAfford ? l10n.play : l10n.getMoreMoney,
                        icon: canAfford ? AppIcons.bolt : null,
                        tone: CasinoActionTone.raise,
                        height: 58,
                        onPressed: () => _onPlay(selected, canAfford),
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

class _BalanceStrip extends StatelessWidget {
  const _BalanceStrip({
    required this.playerMoney,
    required this.playerChips,
    required this.marketplaceLabel,
    required this.onMarketplace,
  });

  final int playerMoney;
  final int playerChips;
  final String marketplaceLabel;
  final VoidCallback onMarketplace;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
            onTap: onMarketplace,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: CasinoColors.gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: CasinoColors.gold.withValues(alpha: 0.35),
                ),
              ),
              child: Text(
                marketplaceLabel,
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
    );
  }
}

/// City pot banner adapted for wheel selection (no per-row Play CTA).
class _PotBannerCard extends StatelessWidget {
  const _PotBannerCard({
    required this.option,
    required this.cityName,
    required this.canAfford,
    required this.selected,
    required this.height,
    required this.onTap,
  });

  final PotOption option;
  final String cityName;
  final bool canAfford;
  final bool selected;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final borderColor =
        selected
            ? CasinoColors.gold.withValues(alpha: canAfford ? 0.75 : 0.4)
            : canAfford
            ? CasinoColors.gold.withValues(alpha: 0.32)
            : Colors.white10;

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: selected ? 2 : 1),
        boxShadow:
            selected
                ? [
                  BoxShadow(
                    color: CasinoColors.gold.withValues(alpha: 0.18),
                    blurRadius: 16,
                    spreadRadius: 0,
                  ),
                ]
                : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(selected ? 14 : 15),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              option.assetPath,
              fit: BoxFit.cover,
              errorBuilder:
                  (_, __, ___) => Container(color: CasinoColors.bgElevated),
            ),
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
                          fontSize: selected ? 15 : 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${l10n.prize}: ${option.pool} ',
                            style: TextStyle(
                              color:
                                  canAfford
                                      ? CasinoColors.text
                                      : CasinoColors.textMuted,
                              fontSize: selected ? 18 : 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          CashIcon(size: selected ? 16 : 14),
                        ],
                      ),
                      const SizedBox(height: 4),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
