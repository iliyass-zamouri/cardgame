import 'package:cardgame/ads/rewarded_ad_service.dart';
import 'package:cardgame/app/auth_providers.dart';
import 'package:cardgame/app/player_profile_repository.dart';
import 'package:cardgame/core/monetization/purchases_config.dart';
import 'package:cardgame/core/monetization/purchases_service.dart';
import 'package:cardgame/data/avatars/avatar_catalog.dart';
import 'package:cardgame/data/decks/deck_catalog.dart';
import 'package:cardgame/data/marketplace/marketplace_api.dart';
import 'package:cardgame/l10n/l10n_ext.dart';
import 'package:cardgame/services/sfx_service.dart';
import 'package:cardgame/ui/flame/card_back_skins.dart';
import 'package:cardgame/ui/screens/deck_preview_screen.dart';
import 'package:cardgame/ui/theme/casino_chrome.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/widgets/currency_icon.dart';
import 'package:cardgame/ui/widgets/player_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    // Refresh inventory when entering marketplace
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(playerProfileProvider.notifier).refreshInventory();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final profile =
        ref.watch(playerProfileProvider).value ?? PlayerProfile.empty;

    return Scaffold(
      backgroundColor: CasinoColors.bg,
      appBar: AppBar(
        backgroundColor: CasinoColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: CasinoColors.text,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.marketplace,
          style: const TextStyle(
            color: CasinoColors.gold,
            fontWeight: FontWeight.w800,
            fontFamily: CasinoFonts.display,
            fontSize: 20,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: CasinoColors.gold,
          indicatorWeight: 3,
          labelColor: CasinoColors.gold,
          unselectedLabelColor: CasinoColors.textMuted,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
          tabs: [
            Tab(
              icon: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ChipIcon(size: 14),
                  SizedBox(width: 4),
                  CashIcon(size: 14),
                ],
              ),
              text: l10n.exchange,
            ),
            Tab(
              icon: const Icon(Icons.face_rounded, size: 20),
              text: l10n.avatarShop,
            ),
            Tab(
              icon: const Icon(Icons.style_rounded, size: 20),
              text: l10n.deckShop,
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _BalancesHeader(money: profile.money, chips: profile.chips),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _ExchangeTab(
                      profile: profile,
                      onBusy: (busy) => setState(() => _isLoading = busy),
                    ),
                    _AvatarsTab(
                      profile: profile,
                      onBusy: (busy) => setState(() => _isLoading = busy),
                    ),
                    _DecksTab(
                      profile: profile,
                      onBusy: (busy) => setState(() => _isLoading = busy),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: CasinoColors.gold),
              ),
            ),
        ],
      ),
    );
  }
}

class _BalancesHeader extends StatelessWidget {
  const _BalancesHeader({required this.money, required this.chips});

  final int money;
  final int chips;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: CasinoColors.surfaceHi,
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Row(
            children: [
              const CashIcon(size: 24),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.money,
                    style: const TextStyle(
                      color: CasinoColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '$money',
                    style: const TextStyle(
                      color: CasinoColors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(width: 1, height: 32, color: Colors.white12),
          Row(
            children: [
              const ChipIcon(size: 24),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.chips,
                    style: const TextStyle(
                      color: CasinoColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '$chips',
                    style: const TextStyle(
                      color: CasinoColors.goldSoft,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExchangeTab extends ConsumerStatefulWidget {
  const _ExchangeTab({required this.profile, required this.onBusy});

  final PlayerProfile profile;
  final void Function(bool) onBusy;

  @override
  ConsumerState<_ExchangeTab> createState() => _ExchangeTabState();
}

class _ExchangeTabState extends ConsumerState<_ExchangeTab> {
  Future<void> _buyIapPack(_IapPackItem pack) async {
    widget.onBusy(true);
    try {
      final customerInfo = await PurchasesService.instance.purchaseProduct(
        pack.productId,
      );
      if (customerInfo == null) {
        throw Exception('Purchase did not complete');
      }

      String txId =
          'rc_${DateTime.now().millisecondsSinceEpoch}_${widget.profile.playerId}';
      try {
        final txs =
            customerInfo.nonSubscriptionTransactions
                .where((tx) => tx.productIdentifier == pack.productId)
                .toList();
        if (txs.isNotEmpty) {
          txId = txs.last.transactionIdentifier;
        }
      } catch (_) {}

      await ref
          .read(playerProfileProvider.notifier)
          .redeemIapPurchase(productId: pack.productId, transactionId: txId);

      SfxService.instance.buy();
      if (mounted) {
        CasinoToast.show(context, 'Purchased ${pack.title}!');
      }
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code != PurchasesErrorCode.purchaseCancelledError) {
        if (mounted) {
          CasinoToast.show(
            context,
            e.message ?? 'Purchase failed',
            success: false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CasinoToast.show(
          context,
          e is MarketplaceApiException ? e.message : 'Purchase failed: $e',
          success: false,
        );
      }
    } finally {
      if (mounted) widget.onBusy(false);
    }
  }

  Future<void> _watchAdForMoney() async {
    final l10n = context.l10n;
    widget.onBusy(true);
    try {
      final adService = ref.read(rewardedAdProvider);
      final result = await adService.show();
      if (result == RewardedShowResult.rewarded) {
        final reward =
            await ref.read(playerProfileProvider.notifier).claimAdReward();
        if (mounted) {
          CasinoToast.show(context, '${l10n.adRewardEarned}: +$reward 💵');
        }
      } else {
        if (mounted) {
          CasinoToast.show(context, l10n.adNotAvailable, success: false);
        }
      }
    } catch (e) {
      if (mounted) {
        CasinoToast.show(context, l10n.adNotAvailable, success: false);
      }
    } finally {
      if (mounted) widget.onBusy(false);
    }
  }

  Future<void> _showConversionModal() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CurrencyConversionModal(onBusy: widget.onBusy),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
          children: [
            // Rate banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: CasinoColors.gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: CasinoColors.gold.withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChipIcon(size: 18),
                  SizedBox(width: 6),
                  Text(
                    '1  =  ',
                    style: TextStyle(
                      color: CasinoColors.gold,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  CashIcon(size: 18),
                  SizedBox(width: 6),
                  Text(
                    '1,000',
                    style: TextStyle(
                      color: CasinoColors.gold,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Rewarded Ad Free Money Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CasinoColors.bgElevated,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7ED50E).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.play_circle_fill_rounded,
                        color: Color(0xFF7ED50E),
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.watchAdForMoney,
                          style: const TextStyle(
                            color: CasinoColors.text,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              '+${widget.profile.adRewardMoney} ',
                              style: const TextStyle(
                                color: CasinoColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                            const CashIcon(size: 13),
                            Text(
                              ' ${l10n.freeStashBonus}',
                              style: const TextStyle(
                                color: CasinoColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _watchAdForMoney,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7ED50E),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                    child: Text(
                      l10n.claim,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Real Money Store Packs
            const Row(
              children: [
                Icon(
                  Icons.shopping_bag_rounded,
                  color: CasinoColors.gold,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Store Packs',
                  style: TextStyle(
                    color: CasinoColors.gold,
                    fontWeight: FontWeight.w800,
                    fontFamily: CasinoFonts.display,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._iapPacks.map(
              (pack) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _IapPackCard(pack: pack, onBuy: () => _buyIapPack(pack)),
              ),
            ),
          ],
        ),
        Positioned(
          bottom: 20,
          left: 20,
          child: FloatingActionButton.extended(
            onPressed: _showConversionModal,
            backgroundColor: CasinoColors.gold,
            foregroundColor: Colors.black,
            elevation: 6,
            icon: const Icon(Icons.swap_horiz_rounded, size: 24),
            label: Text(
              l10n.exchange,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _IapPackItem {
  const _IapPackItem({
    required this.productId,
    required this.title,
    required this.currency,
    required this.amount,
    required this.priceUsd,
    required this.icon,
  });

  final String productId;
  final String title;
  final CurrencyType currency;
  final int amount;
  final String priceUsd;
  final IconData icon;
}

const _iapPacks = [
  _IapPackItem(
    productId: PurchasesConfig.chips1,
    title: '1 Chip',
    currency: CurrencyType.chips,
    amount: 1,
    priceUsd: '\$0.99',
    icon: Icons.stars_rounded,
  ),
  _IapPackItem(
    productId: PurchasesConfig.chips5,
    title: '5 Chips',
    currency: CurrencyType.chips,
    amount: 5,
    priceUsd: '\$3.99',
    icon: Icons.military_tech_rounded,
  ),
  _IapPackItem(
    productId: PurchasesConfig.chips10,
    title: '10 Chips',
    currency: CurrencyType.chips,
    amount: 10,
    priceUsd: '\$8.99',
    icon: Icons.diamond_rounded,
  ),
  _IapPackItem(
    productId: PurchasesConfig.chips25,
    title: '25 Chips',
    currency: CurrencyType.chips,
    amount: 25,
    priceUsd: '\$19.99',
    icon: Icons.workspace_premium_rounded,
  ),
  _IapPackItem(
    productId: PurchasesConfig.chips50,
    title: '50 Chips',
    currency: CurrencyType.chips,
    amount: 50,
    priceUsd: '\$34.99',
    icon: Icons.shield_rounded,
  ),
];

class _IapPackCard extends StatelessWidget {
  const _IapPackCard({required this.pack, required this.onBuy});

  final _IapPackItem pack;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CasinoColors.bgElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: CasinoColors.gold.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(pack.icon, color: CasinoColors.gold, size: 24),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pack.title,
                  style: const TextStyle(
                    color: CasinoColors.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '+${pack.amount} ',
                      style: const TextStyle(
                        color: CasinoColors.goldSoft,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    CurrencyIcon(currency: pack.currency, size: 13),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onBuy,
            style: ElevatedButton.styleFrom(
              backgroundColor: CasinoColors.gold,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: Text(
              pack.priceUsd,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrencyConversionModal extends ConsumerStatefulWidget {
  const _CurrencyConversionModal({required this.onBusy});

  final void Function(bool) onBusy;

  @override
  ConsumerState<_CurrencyConversionModal> createState() =>
      _CurrencyConversionModalState();
}

class _CurrencyConversionModalState
    extends ConsumerState<_CurrencyConversionModal> {
  int _chipsToConvert = 1;
  int _moneyChipsToBuy = 1;

  Future<void> _convertChipsToMoney(PlayerProfile profile) async {
    final l10n = context.l10n;
    if (profile.chips < _chipsToConvert) {
      CasinoToast.show(context, l10n.insufficientChips, success: false);
      return;
    }

    widget.onBusy(true);
    try {
      await ref
          .read(playerProfileProvider.notifier)
          .exchangeCurrency(
            direction: 'chips_to_money',
            amount: _chipsToConvert,
          );
      if (mounted) {
        Navigator.of(context).pop();
        CasinoToast.show(
          context,
          '${l10n.exchangedSuccess}: +${_chipsToConvert * 1000} 💵',
        );
      }
    } catch (e) {
      if (mounted) {
        CasinoToast.show(
          context,
          e is MarketplaceApiException ? e.message : l10n.exchangeFailed,
          success: false,
        );
      }
    } finally {
      if (mounted) widget.onBusy(false);
    }
  }

  Future<void> _convertMoneyToChips(PlayerProfile profile) async {
    final l10n = context.l10n;
    final cost = _moneyChipsToBuy * 1000;
    if (profile.money < cost) {
      CasinoToast.show(context, l10n.insufficientMoney, success: false);
      return;
    }

    widget.onBusy(true);
    try {
      await ref
          .read(playerProfileProvider.notifier)
          .exchangeCurrency(
            direction: 'money_to_chips',
            amount: _moneyChipsToBuy,
          );
      if (mounted) {
        Navigator.of(context).pop();
        CasinoToast.show(
          context,
          '${l10n.exchangedSuccess}: +$_moneyChipsToBuy 🪙',
        );
      }
    } catch (e) {
      if (mounted) {
        CasinoToast.show(
          context,
          e is MarketplaceApiException ? e.message : l10n.exchangeFailed,
          success: false,
        );
      }
    } finally {
      if (mounted) widget.onBusy(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final profile =
        ref.watch(playerProfileProvider).value ?? PlayerProfile.empty;

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      decoration: const BoxDecoration(
        color: CasinoColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: CasinoColors.gold, width: 1.5)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.swap_horiz_rounded,
                        color: CasinoColors.gold,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.exchange,
                        style: const TextStyle(
                          color: CasinoColors.gold,
                          fontWeight: FontWeight.w800,
                          fontFamily: CasinoFonts.display,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: CasinoColors.textMuted,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Current balances bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: CasinoColors.bgElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Row(
                      children: [
                        const CashIcon(size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '${profile.money}',
                          style: const TextStyle(
                            color: CasinoColors.text,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Container(width: 1, height: 20, color: Colors.white12),
                    Row(
                      children: [
                        const ChipIcon(size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '${profile.chips}',
                          style: const TextStyle(
                            color: CasinoColors.goldSoft,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Chips -> Money
              _ExchangeCard(
                title: l10n.chipsToMoney,
                sourceCurrency: CurrencyType.chips,
                targetCurrency: CurrencyType.money,
                amount: _chipsToConvert,
                targetAmount: _chipsToConvert * 1000,
                onDecrement: () {
                  if (_chipsToConvert > 1) {
                    setState(() => _chipsToConvert--);
                  }
                },
                onIncrement: () {
                  setState(() => _chipsToConvert++);
                },
                onAction: () => _convertChipsToMoney(profile),
                actionLabel: l10n.convert,
                canAfford: profile.chips >= _chipsToConvert,
              ),
              const SizedBox(height: 14),

              // Money -> Chips
              _ExchangeCard(
                title: l10n.moneyToChips,
                sourceCurrency: CurrencyType.money,
                targetCurrency: CurrencyType.chips,
                amount: _moneyChipsToBuy * 1000,
                targetAmount: _moneyChipsToBuy,
                onDecrement: () {
                  if (_moneyChipsToBuy > 1) {
                    setState(() => _moneyChipsToBuy--);
                  }
                },
                onIncrement: () {
                  setState(() => _moneyChipsToBuy++);
                },
                onAction: () => _convertMoneyToChips(profile),
                actionLabel: l10n.convert,
                canAfford: profile.money >= (_moneyChipsToBuy * 1000),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExchangeCard extends StatelessWidget {
  const _ExchangeCard({
    required this.title,
    required this.sourceCurrency,
    required this.targetCurrency,
    required this.amount,
    required this.targetAmount,
    required this.onDecrement,
    required this.onIncrement,
    required this.onAction,
    required this.actionLabel,
    required this.canAfford,
  });

  final String title;
  final CurrencyType sourceCurrency;
  final CurrencyType targetCurrency;
  final int amount;
  final int targetAmount;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final VoidCallback onAction;
  final String actionLabel;
  final bool canAfford;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: CasinoColors.bgElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: CasinoColors.goldSoft,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline_rounded,
                      color: CasinoColors.gold,
                    ),
                    onPressed: onDecrement,
                  ),
                  CurrencyIcon(currency: sourceCurrency, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '$amount',
                    style: const TextStyle(
                      color: CasinoColors.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle_outline_rounded,
                      color: CasinoColors.gold,
                    ),
                    onPressed: onIncrement,
                  ),
                ],
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: CasinoColors.textMuted,
                size: 20,
              ),
              Row(
                children: [
                  CurrencyIcon(currency: targetCurrency, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '$targetAmount',
                    style: const TextStyle(
                      color: CasinoColors.gold,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: canAfford ? onAction : null,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  canAfford ? CasinoColors.raise : Colors.grey.shade800,
              foregroundColor: CasinoColors.text,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              actionLabel,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarsTab extends ConsumerWidget {
  const _AvatarsTab({required this.profile, required this.onBusy});

  final PlayerProfile profile;
  final void Function(bool) onBusy;

  String _getAvatarName(BuildContext context, String nameKey) {
    final l10n = context.l10n;
    switch (nameKey) {
      case 'defaultAvatar':
        return l10n.defaultAvatar;
      case 'blueAvatar':
        return l10n.blueAvatar;
      case 'redAvatar':
        return l10n.redAvatar;
      case 'bronzeAvatar':
        return l10n.bronzeAvatar;
      case 'silverAvatar':
        return l10n.silverAvatar;
      case 'jokerGirlAvatar':
        return l10n.jokerGirlAvatar;
      case 'violetJokerGirlAvatar':
        return l10n.violetJokerGirlAvatar;
      case 'violetQueenAvatar':
        return l10n.violetQueenAvatar;
      case 'queenOfHeartAvatar':
        return l10n.queenOfHeartAvatar;
      case 'goldenKingAvatar':
        return l10n.goldenKingAvatar;
      case 'queenAvatar':
        return l10n.queenAvatar;
      case 'kingAvatar':
        return l10n.kingAvatar;
      default:
        return nameKey;
    }
  }

  Future<void> _buyAvatar(
    BuildContext context,
    WidgetRef ref,
    AvatarItem avatar,
  ) async {
    final l10n = context.l10n;
    final canAfford =
        avatar.currency == CurrencyType.money
            ? profile.money >= avatar.price
            : profile.chips >= avatar.price;

    if (!canAfford) {
      CasinoToast.show(
        context,
        avatar.currency == CurrencyType.money
            ? l10n.insufficientMoney
            : l10n.insufficientChips,
        success: false,
      );
      return;
    }

    onBusy(true);
    try {
      await ref
          .read(playerProfileProvider.notifier)
          .buyItem(
            itemType: 'avatar',
            itemId: avatar.id,
            currency: avatar.currency.name,
            price: avatar.price,
          );
      SfxService.instance.buy();
      if (context.mounted) {
        CasinoToast.show(
          context,
          '${l10n.unlocked}! ${_getAvatarName(context, avatar.nameKey)}',
        );
      }
    } catch (e) {
      if (context.mounted) {
        CasinoToast.show(
          context,
          e is MarketplaceApiException ? e.message : l10n.purchaseFailed,
          success: false,
        );
      }
    } finally {
      onBusy(false);
    }
  }

  Future<void> _equipAvatar(
    BuildContext context,
    WidgetRef ref,
    AvatarItem avatar,
  ) async {
    final l10n = context.l10n;
    await ref.read(playerProfileProvider.notifier).updateAvatar(avatar.id);
    if (context.mounted) {
      CasinoToast.show(
        context,
        '${l10n.equipped}: ${_getAvatarName(context, avatar.nameKey)}',
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final avatars = AvatarCatalog.all;

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.65,
      ),
      itemCount: avatars.length,
      itemBuilder: (context, index) {
        final avatar = avatars[index];
        final isOwned = profile.ownsAvatar(avatar.id);
        final isEquipped = profile.avatarId == avatar.id;
        final name = _getAvatarName(context, avatar.nameKey);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: CasinoColors.bgElevated,
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                if (isEquipped) ...[
                  CasinoColors.gold.withValues(alpha: 0.18),
                  CasinoColors.bgElevated,
                ] else if (isOwned) ...[
                  CasinoColors.check.withValues(alpha: 0.08),
                  CasinoColors.bgElevated,
                ] else if (avatar.isPremium) ...[
                  CasinoColors.goldSoft.withValues(alpha: 0.06),
                  CasinoColors.bgElevated,
                ] else ...[
                  CasinoColors.surfaceHi,
                  CasinoColors.bgElevated,
                ],
              ],
            ),
            border: Border.all(
              color:
                  isEquipped
                      ? CasinoColors.gold
                      : isOwned
                      ? CasinoColors.gold.withValues(alpha: 0.35)
                      : avatar.isPremium
                      ? CasinoColors.goldSoft.withValues(alpha: 0.25)
                      : Colors.white12,
              width: isEquipped ? 2 : 1,
            ),
            boxShadow: [
              if (isEquipped)
                BoxShadow(
                  color: CasinoColors.gold.withValues(alpha: 0.22),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top badge row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: CasinoColors.surface.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Text(
                      avatar.requiredLevel <= 1
                          ? 'FREE'
                          : 'LV. ${avatar.requiredLevel}',
                      style: const TextStyle(
                        color: CasinoColors.goldSoft,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  if (isEquipped)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: CasinoColors.gold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: CasinoColors.gold),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 10,
                            color: CasinoColors.gold,
                          ),
                          SizedBox(width: 3),
                          Text(
                            'ACTIVE',
                            style: TextStyle(
                              color: CasinoColors.gold,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (isOwned)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: CasinoColors.check.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: CasinoColors.check.withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Text(
                        'OWNED',
                        style: TextStyle(
                          color: CasinoColors.check,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    )
                  else if (avatar.isPremium)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: CasinoColors.goldSoft.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: CasinoColors.goldSoft.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Text(
                        'CHIPS',
                        style: TextStyle(
                          color: CasinoColors.goldSoft,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 14),
                ],
              ),

              // Avatar preview
              PlayerAvatar(
                avatarId: avatar.id,
                size: 124,
                borderWidth: isEquipped ? 2 : 1.5,
                borderColor:
                    isEquipped
                        ? CasinoColors.gold
                        : isOwned
                        ? CasinoColors.gold.withValues(alpha: 0.4)
                        : Colors.white12,
                showGlow: isEquipped || avatar.isPremium,
                glowColor:
                    isEquipped
                        ? CasinoColors.gold.withValues(alpha: 0.35)
                        : CasinoColors.goldSoft.withValues(alpha: 0.18),
              ),

              // Title and Price
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isEquipped ? CasinoColors.gold : CasinoColors.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 3),
                  if (!isOwned)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: CasinoColors.surfaceHi,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CurrencyIcon(currency: avatar.currency, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            '${avatar.price}',
                            style: TextStyle(
                              color:
                                  avatar.isPremium
                                      ? CasinoColors.goldSoft
                                      : CasinoColors.text,
                              fontWeight: FontWeight.w800,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              // Bottom Action button
              if (isEquipped)
                Container(
                  width: double.infinity,
                  height: 34,
                  decoration: BoxDecoration(
                    color: CasinoColors.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: CasinoColors.gold.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: CasinoColors.gold,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n.equipped,
                          style: const TextStyle(
                            color: CasinoColors.gold,
                            fontWeight: FontWeight.w800,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (isOwned)
                ElevatedButton(
                  onPressed: () => _equipAvatar(context, ref, avatar),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CasinoColors.check,
                    foregroundColor: CasinoColors.text,
                    minimumSize: const Size.fromHeight(34),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    l10n.equip,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                )
              else
                ElevatedButton(
                  onPressed: () => _buyAvatar(context, ref, avatar),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        avatar.isPremium
                            ? CasinoColors.gold
                            : CasinoColors.raise,
                    foregroundColor:
                        avatar.isPremium ? CasinoColors.bg : CasinoColors.text,
                    minimumSize: const Size.fromHeight(34),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CurrencyIcon(currency: avatar.currency, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '${avatar.price} · ${l10n.buy}',
                        style: TextStyle(
                          color:
                              avatar.isPremium
                                  ? CasinoColors.bg
                                  : CasinoColors.text,
                          fontWeight: FontWeight.w800,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _DecksTab extends ConsumerWidget {
  const _DecksTab({required this.profile, required this.onBusy});

  final PlayerProfile profile;
  final void Function(bool) onBusy;

  String _getDeckName(BuildContext context, String nameKey) {
    final l10n = context.l10n;
    switch (nameKey) {
      case 'classicDeck':
        return l10n.classicDeck;
      case 'onyxBlackDeck':
        return l10n.onyxBlackDeck;
      default:
        return nameKey;
    }
  }

  String _getDeckDesc(BuildContext context, String descriptionKey) {
    final l10n = context.l10n;
    switch (descriptionKey) {
      case 'classicDeckDesc':
        return l10n.classicDeckDesc;
      case 'onyxBlackDeckDesc':
        return l10n.onyxBlackDeckDesc;
      default:
        return descriptionKey;
    }
  }

  Future<void> _equipDeck(
    BuildContext context,
    WidgetRef ref,
    DeckItem deck,
  ) async {
    final l10n = context.l10n;
    await ref.read(playerProfileProvider.notifier).updateDeck(deck.id);
    if (context.mounted) {
      CasinoToast.show(
        context,
        '${l10n.equipped}: ${_getDeckName(context, deck.nameKey)}',
      );
    }
  }

  Future<void> _buyDeck(
    BuildContext context,
    WidgetRef ref,
    DeckItem deck,
  ) async {
    final l10n = context.l10n;
    if (profile.chips < deck.chipPrice) {
      CasinoToast.show(context, l10n.insufficientChips, success: false);
      return;
    }

    onBusy(true);
    try {
      await ref
          .read(playerProfileProvider.notifier)
          .buyItem(
            itemType: 'deck',
            itemId: deck.id,
            currency: 'chips',
            price: deck.chipPrice,
          );
      SfxService.instance.buy();
      if (context.mounted) {
        CasinoToast.show(
          context,
          '${l10n.unlocked}! ${_getDeckName(context, deck.nameKey)}',
        );
      }
    } catch (e) {
      if (context.mounted) {
        CasinoToast.show(
          context,
          e is MarketplaceApiException ? e.message : l10n.purchaseFailed,
          success: false,
        );
      }
    } finally {
      onBusy(false);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final decks = DeckCatalog.all;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: decks.length,
      itemBuilder: (context, index) {
        final deck = decks[index];
        final isOwned = profile.ownsDeck(deck.id);
        final isEquipped = profile.deckId == deck.id;
        final name = _getDeckName(context, deck.nameKey);
        final desc = _getDeckDesc(context, deck.descriptionKey);

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap:
                  () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder:
                          (context) => DeckPreviewScreen(
                            title: name,
                            backSkinId: deck.skinId,
                          ),
                    ),
                  ),
              borderRadius: BorderRadius.circular(22),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                decoration: BoxDecoration(
                  color: CasinoColors.bgElevated,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color:
                        isEquipped
                            ? CasinoColors.gold
                            : CasinoColors.gold.withValues(alpha: 0.35),
                    width: isEquipped ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    _DeckFan(skinId: deck.skinId),
                    const SizedBox(height: 18),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: CasinoColors.text,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      desc,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: CasinoColors.textMuted,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (isEquipped)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: CasinoColors.gold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: CasinoColors.gold.withValues(alpha: 0.45),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: CasinoColors.gold,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              l10n.equipped,
                              style: const TextStyle(
                                color: CasinoColors.gold,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (isOwned)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _equipDeck(context, ref, deck),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: CasinoColors.check,
                            foregroundColor: CasinoColors.text,
                            minimumSize: const Size.fromHeight(48),
                            elevation: 0,
                            shape: const StadiumBorder(),
                          ),
                          child: Text(
                            l10n.equip,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _buyDeck(context, ref, deck),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: CasinoColors.gold,
                            foregroundColor: CasinoColors.bg,
                            minimumSize: const Size.fromHeight(48),
                            elevation: 0,
                            shape: const StadiumBorder(),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const ChipIcon(size: 18),
                              const SizedBox(width: 8),
                              Text(
                                '${deck.chipPrice} · ${l10n.buy}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DeckFan extends StatelessWidget {
  const _DeckFan({required this.skinId});

  final String skinId;

  static const _count = 5;
  static const _cardWidth = 108.0;
  static const _cardHeight = _cardWidth * 112 / 78;
  static const _spread = 16.0;
  static const _tilt = 0.06;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _cardHeight + 16,
      width: _cardWidth + _spread * (_count - 1),
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (var i = 0; i < _count; i++)
            Transform.translate(
              offset: Offset((i - (_count - 1) / 2) * _spread, 0),
              child: Transform.rotate(
                angle: (i - (_count - 1) / 2) * _tilt,
                child: Container(
                  width: _cardWidth,
                  height: _cardHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.42),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _DeckBackPreview(skinId: skinId),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DeckBackPreview extends StatelessWidget {
  const _DeckBackPreview({required this.skinId});

  final String skinId;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DeckBackPreviewPainter(skinId),
      child: const SizedBox.expand(),
    );
  }
}

class _DeckBackPreviewPainter extends CustomPainter {
  _DeckBackPreviewPainter(this.skinId);

  final String skinId;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.width * 0.1),
    );
    canvas.save();
    canvas.clipRRect(rect);
    canvas.scale(size.width);
    CardBackSkins.byId(skinId).paintUnit(canvas, size.height / size.width);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DeckBackPreviewPainter oldDelegate) =>
      oldDelegate.skinId != skinId;
}
