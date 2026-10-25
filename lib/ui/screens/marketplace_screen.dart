import 'dart:math' as math;

import 'package:cardgame/ads/rewarded_ad_service.dart';
import 'package:cardgame/app/auth_providers.dart';
import 'package:cardgame/app/marketplace_providers.dart';
import 'package:cardgame/app/navigation_providers.dart';
import 'package:cardgame/app/player_profile_repository.dart';
import 'package:cardgame/core/monetization/purchases_config.dart';
import 'package:cardgame/core/monetization/purchases_service.dart';
import 'package:cardgame/data/avatars/avatar_catalog.dart';
import 'package:cardgame/data/decks/deck_catalog.dart';
import 'package:cardgame/data/marketplace/marketplace_api.dart';
import 'package:cardgame/data/marketplace/marketplace_catalog.dart';
import 'package:cardgame/l10n/l10n_ext.dart';
import 'package:cardgame/services/notification_deeplink.dart';
import 'package:cardgame/services/sfx_service.dart';
import 'package:cardgame/ui/flame/suit_shapes.dart';
import 'package:cardgame/ui/screens/deck_preview_screen.dart';
import 'package:cardgame/ui/theme/casino_chrome.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/widgets/currency_icon.dart';
import 'package:cardgame/ui/widgets/deck_showcase_card.dart';
import 'package:cardgame/ui/widgets/greyed_out.dart';
import 'package:cardgame/ui/widgets/hud_counter.dart';
import 'package:cardgame/ui/widgets/player_avatar.dart';
import 'package:cardgame/ui/widgets/shop_promo.dart';
import 'package:cardgame/ui/widgets/suit_card_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:cardgame/ui/theme/game_icon.dart';
import 'package:cardgame/ui/theme/app_icons.dart';
import 'package:cardgame/ui/theme/felt_chrome.dart';

/// Marketplace tabs, in display order.
enum MarketplaceTab { decks, avatars, exchange }

class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key, this.initialTab = MarketplaceTab.decks});

  final MarketplaceTab initialTab;

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
      length: MarketplaceTab.values.length,
      vsync: this,
      initialIndex: widget.initialTab.index,
    );
    // Retries a failed rewarded ad load each time the marketplace opens.
    ref.read(rewardedAdProvider).preload();
    // Refresh inventory and prices when entering marketplace
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(playerProfileProvider.notifier).refreshInventory();
      ref.read(marketplaceCatalogProvider.notifier).refresh();
    });
  }

  /// A banner link to another shop tab switches tabs; anything else leaves
  /// the shop for that screen.
  void _openBannerLink(String route) {
    final nav = resolveNotificationNav({'route': route});
    if (nav == null) return;
    if (nav.destination == NotificationDestination.shop) {
      _tabController.animateTo((nav.shopTab ?? MarketplaceTab.decks).index);
      return;
    }
    ref.read(notificationNavigatorProvider).navigate(nav);
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
    final banner = ref.watch(marketplaceCatalogProvider).banner;

    return FeltScaffold(
      title: l10n.shop,
      // The highlighted Shop nav tab already says where you are.
      showTitle: false,
      // Grids add columns rather than stretch, so they can run wider.
      maxBodyWidth: 1000,
      trailing: _HeaderBalances(
        money: profile.money,
        chips: profile.chips,
        // The counters' "+" means "get more": that's the Exchange tab.
        onTap: () => _tabController.animateTo(MarketplaceTab.exchange.index),
      ),
      tabs: TabBar(
        controller: _tabController,
        tabs: [
          Tab(
            height: 40,
            child: _ShopTabLabel(
              icon: const GameIcon(icon: AppIcons.decks, size: 16),
              label: l10n.deckShop,
            ),
          ),
          Tab(
            height: 40,
            child: _ShopTabLabel(
              icon: const GameIcon(icon: AppIcons.avatars, size: 16),
              label: l10n.avatarShop,
            ),
          ),
          Tab(
            height: 40,
            child: _ShopTabLabel(
              icon: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ChipIcon(size: 14),
                  SizedBox(width: 2),
                  CashIcon(size: 14),
                ],
              ),
              label: l10n.exchange,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: Text(
                  'Virtual currency only. No real-money cash-out.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: CasinoColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (banner != null)
                ShopTicker(
                  until: banner.endsAt,
                  builder:
                      (context, now) =>
                          banner.liveAt(now)
                              ? Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  6,
                                  16,
                                  4,
                                ),
                                child: ShopBannerCard(
                                  banner: banner,
                                  onTap:
                                      banner.deeplink == null
                                          ? null
                                          : () => _openBannerLink(
                                            banner.deeplink!,
                                          ),
                                ),
                              )
                              : const SizedBox.shrink(),
                ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _DecksTab(
                      profile: profile,
                      onBusy: (busy) => setState(() => _isLoading = busy),
                    ),
                    _AvatarsTab(
                      profile: profile,
                      onBusy: (busy) => setState(() => _isLoading = busy),
                    ),
                    _ExchangeTab(
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
              child: const Center(child: SuitCardLoader(height: 32)),
            ),
        ],
      ),
    );
  }
}

/// Money and chip counters for the header's end, matching the home top bar.
class _HeaderBalances extends StatelessWidget {
  const _HeaderBalances({
    required this.money,
    required this.chips,
    required this.onTap,
  });

  final int money;
  final int chips;
  final VoidCallback onTap;

  static const _counterWidth = 104.0;

  @override
  Widget build(BuildContext context) {
    Widget counter(CurrencyType currency, int value) => SizedBox(
      width: _counterWidth,
      child: Pressable(
        onTap: onTap,
        child: HudCounter(currency: currency, value: value),
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        counter(CurrencyType.money, money),
        const SizedBox(width: 6),
        counter(CurrencyType.chips, chips),
      ],
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
  Future<void> _buyIapPack(IapPackOffer pack, String title) async {
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
        CasinoToast.show(context, 'Purchased $title!');
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

  Future<void> _showConversionModal() =>
      CurrencyConversionModal.show(context, onBusy: widget.onBusy);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final catalog = ref.watch(marketplaceCatalogProvider);
    final packs = catalog.featuredFirst(
      catalog.packs,
      'iap',
      (pack) => pack.productId,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      children: [
        // Rate banner + exchange action: the rate sits right next to
        // the button that uses it, instead of a floating button that
        // covers the pack list.
        FeltPanel(
          padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
          child: Row(
            children: [
              // The rate scales down beside the button on narrow screens.
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Row(
                    children: [
                      const ChipIcon(size: 22),
                      Text(
                        '  1  =  ',
                        style: TextStyle(
                          fontFamily: CasinoFonts.display,
                          color: CasinoColors.gold,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const CashIcon(size: 22),
                      Text(
                        '  ${formatShopAmount(catalog.moneyPerChip)}',
                        maxLines: 1,
                        style: TextStyle(
                          fontFamily: CasinoFonts.display,
                          color: CasinoColors.gold,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GoldButton(
                label: l10n.exchange,
                compact: true,
                leading: const GameIcon(icon: AppIcons.swap, size: 18),
                onPressed: _showConversionModal,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Rewarded Ad Free Money Card: a daily cap of 0 turns ads off.
        if (catalog.adDailyCap > 0) ...[
          IvoryCard(
            suit: SuitShape.hearts,
            highlighted: true,
            padding: const EdgeInsets.fromLTRB(26, 14, 16, 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1E7A45).withValues(alpha: 0.12),
                    border: Border.all(
                      color: const Color(0xFF1E7A45).withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Center(
                    child: GameIcon(
                      icon: AppIcons.playCircle,
                      color: Color(0xFF1E7A45),
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.watchAdForMoney,
                        style: const TextStyle(
                          fontFamily: CasinoFonts.display,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            '+${catalog.adRewardMoney} ',
                            style: const TextStyle(
                              color: Color(0xFF5A4A2A),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const CashIcon(size: 14),
                          Flexible(
                            child: Text(
                              ' ${l10n.freeStashBonus}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF5A4A2A),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ValueListenableBuilder<bool>(
                  valueListenable: ref.watch(rewardedAdProvider).ready,
                  builder:
                      (context, ready, _) => GreyedOut(
                        enabled: ready,
                        child: GoldButton(
                          label: l10n.claim,
                          compact: true,
                          onPressed: ready ? _watchAdForMoney : null,
                        ),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
        ],

        // Real Money Store Packs
        const FeltSectionHeader(label: 'Store Packs', suit: SuitShape.diamonds),
        for (final (i, pack) in packs.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _IapPackCard(
              pack: pack,
              title: _packTitle(context, pack),
              stack: i + 1,
              featured:
                  catalog.featured?.matches('iap', pack.productId) ?? false,
              onBuy: () => _buyIapPack(pack, _packTitle(context, pack)),
            ),
          ),
      ],
    );
  }
}

/// Store price labels for the packs this build knows. A pack the server
/// adds later shows a plain Buy button.
const _storePriceLabels = {
  PurchasesConfig.chips1: '\$0.99',
  PurchasesConfig.chips5: '\$3.99',
  PurchasesConfig.chips10: '\$8.99',
  PurchasesConfig.chips25: '\$19.99',
  PurchasesConfig.chips50: '\$34.99',
};

String _packTitle(BuildContext context, IapPackOffer pack) {
  final l10n = context.l10n;
  return pack.currency == CurrencyType.chips
      ? l10n.shopChipPack(pack.amount)
      : l10n.shopCashPack(pack.amount);
}

/// "1,000", "25,000".
String formatShopAmount(int value) {
  final digits = value.abs().toString();
  final out = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
    out.write(digits[i]);
  }
  return out.toString();
}

class _IapPackCard extends StatelessWidget {
  const _IapPackCard({
    required this.pack,
    required this.title,
    required this.stack,
    required this.onBuy,
    this.featured = false,
  });

  final IapPackOffer pack;
  final String title;
  final bool featured;

  /// Chips drawn in the stack; bigger packs show taller stacks.
  final int stack;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final row = Row(
      children: [
        _ChipStack(count: stack),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShopPromoTags(badge: pack.badge, featured: featured),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: CasinoFonts.display,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 2),
              ShopTicker(
                until: pack.bonusEndsAt,
                builder: (context, now) {
                  final bonus = pack.bonusAt(now);
                  return Row(
                    children: [
                      Text(
                        '+${formatShopAmount(pack.amount + bonus)} ',
                        style: const TextStyle(
                          color: Color(0xFF5A4A2A),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      CurrencyIcon(currency: pack.currency, size: 14),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        GoldButton(
          label: _storePriceLabels[pack.productId] ?? l10n.buy,
          compact: true,
          onPressed: onBuy,
        ),
      ],
    );
    return IvoryCard(
      highlighted: featured,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child:
          pack.bonusAt(DateTime.now()) > 0
              ? Column(
                children: [
                  row,
                  const SizedBox(height: 10),
                  ShopBonusBar(pack: pack),
                ],
              )
              : row,
    );
  }
}

/// A short tower of poker chips, one per [count].
class _ChipStack extends StatelessWidget {
  const _ChipStack({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    const chip = 34.0;
    const step = 6.0;
    final n = count.clamp(1, 5);
    return SizedBox(
      width: chip + 6,
      height: chip + step * 4,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          for (var i = 0; i < n; i++)
            Positioned(bottom: i * step, child: const ChipIcon(size: chip)),
        ],
      ),
    );
  }
}

/// Chips <-> money exchange sheet, at the shop's current rate.
class CurrencyConversionModal extends ConsumerStatefulWidget {
  const CurrencyConversionModal({
    super.key,
    this.onBusy,
    this.initialChipsToConvert = 1,
  });

  final void Function(bool)? onBusy;

  /// Pre-filled chips → money amount, e.g. enough to cover a stake.
  final int initialChipsToConvert;

  static Future<void> show(
    BuildContext context, {
    void Function(bool)? onBusy,
    int initialChipsToConvert = 1,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => CurrencyConversionModal(
            onBusy: onBusy,
            initialChipsToConvert: initialChipsToConvert,
          ),
    );
  }

  @override
  ConsumerState<CurrencyConversionModal> createState() =>
      _CurrencyConversionModalState();
}

class _CurrencyConversionModalState
    extends ConsumerState<CurrencyConversionModal> {
  late int _chipsToConvert = math.max(1, widget.initialChipsToConvert);
  int _moneyChipsToBuy = 1;

  int get _rate => ref.read(marketplaceCatalogProvider).moneyPerChip;

  /// A refused exchange because the rate moved: show the new rate.
  void _showExchangeError(Object e) {
    final l10n = context.l10n;
    if (isShopChangedError(e)) {
      ref.read(marketplaceCatalogProvider.notifier).refresh();
      CasinoToast.show(context, l10n.shopPriceChanged, success: false);
      return;
    }
    CasinoToast.show(
      context,
      e is MarketplaceApiException ? e.message : l10n.exchangeFailed,
      success: false,
    );
  }

  Future<void> _convertChipsToMoney(PlayerProfile profile) async {
    final l10n = context.l10n;
    final rate = _rate;
    if (profile.chips < _chipsToConvert) {
      CasinoToast.show(context, l10n.insufficientChips, success: false);
      return;
    }

    widget.onBusy?.call(true);
    try {
      await ref
          .read(playerProfileProvider.notifier)
          .exchangeCurrency(
            direction: 'chips_to_money',
            amount: _chipsToConvert,
            expectedRate: rate,
          );
      if (mounted) {
        Navigator.of(context).pop();
        CasinoToast.show(
          context,
          '${l10n.exchangedSuccess}: +${_chipsToConvert * rate} 💵',
        );
      }
    } catch (e) {
      if (mounted) _showExchangeError(e);
    } finally {
      if (mounted) widget.onBusy?.call(false);
    }
  }

  Future<void> _convertMoneyToChips(PlayerProfile profile) async {
    final l10n = context.l10n;
    final rate = _rate;
    final cost = _moneyChipsToBuy * rate;
    if (profile.money < cost) {
      CasinoToast.show(context, l10n.insufficientMoney, success: false);
      return;
    }

    widget.onBusy?.call(true);
    try {
      await ref
          .read(playerProfileProvider.notifier)
          .exchangeCurrency(
            direction: 'money_to_chips',
            amount: _moneyChipsToBuy,
            expectedRate: rate,
          );
      if (mounted) {
        Navigator.of(context).pop();
        CasinoToast.show(
          context,
          '${l10n.exchangedSuccess}: +$_moneyChipsToBuy 🪙',
        );
      }
    } catch (e) {
      if (mounted) _showExchangeError(e);
    } finally {
      if (mounted) widget.onBusy?.call(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final profile =
        ref.watch(playerProfileProvider).value ?? PlayerProfile.empty;
    final rate = ref.watch(marketplaceCatalogProvider).moneyPerChip;

    return Container(
      padding: EdgeInsets.only(
        top: 14,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [CasinoColors.leather, CasinoColors.leatherDeep],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: CasinoColors.gold.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  GameIcon(
                    icon: AppIcons.swap,
                    color: CasinoColors.gold,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      casinoButtonLabel(
                        l10n.exchange,
                        Localizations.localeOf(context),
                      ),
                      style: TextStyle(
                        color: CasinoColors.gold,
                        fontWeight: FontWeight.w800,
                        fontFamily: CasinoFonts.displayOf(context),
                        fontSize: 18,
                        letterSpacing: 1.2,
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
              const SizedBox(height: 12),
              // Current balances bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: feltPanelDecoration(radius: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Row(
                      children: [
                        const CashIcon(size: 18),
                        const SizedBox(width: 6),
                        Text(
                          '${profile.money}',
                          style: TextStyle(
                            color: CasinoColors.text,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 1,
                      height: 20,
                      color: CasinoColors.gold.withValues(alpha: 0.25),
                    ),
                    Row(
                      children: [
                        const ChipIcon(size: 18),
                        const SizedBox(width: 6),
                        Text(
                          '${profile.chips}',
                          style: TextStyle(
                            color: CasinoColors.goldSoft,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Chips -> Money
              _ExchangeCard(
                title: l10n.chipsToMoney,
                sourceCurrency: CurrencyType.chips,
                targetCurrency: CurrencyType.money,
                amount: _chipsToConvert,
                targetAmount: _chipsToConvert * rate,
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
              const SizedBox(height: 12),

              // Money -> Chips
              _ExchangeCard(
                title: l10n.moneyToChips,
                sourceCurrency: CurrencyType.money,
                targetCurrency: CurrencyType.chips,
                amount: _moneyChipsToBuy * rate,
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
                canAfford: profile.money >= (_moneyChipsToBuy * rate),
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
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final arrow = GameIcon(
      icon: AppIcons.arrowForward,
      color: CasinoColors.gold,
      size: 20,
    );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: feltPanelDecoration(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: CasinoFonts.displayOf(context),
              color: CasinoColors.goldSoft,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FeltIconButton(
                icon: AppIcons.remove,
                size: 34,
                onTap: onDecrement,
              ),
              const SizedBox(width: 10),
              CurrencyIcon(currency: sourceCurrency, size: 20),
              const SizedBox(width: 6),
              Text(
                '$amount',
                style: TextStyle(
                  color: CasinoColors.text,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 10),
              FeltIconButton(icon: AppIcons.add, size: 34, onTap: onIncrement),
              const Spacer(),
              rtl ? Transform.flip(flipX: true, child: arrow) : arrow,
              const Spacer(),
              CurrencyIcon(currency: targetCurrency, size: 20),
              const SizedBox(width: 6),
              Text(
                '$targetAmount',
                style: TextStyle(
                  color: CasinoColors.gold,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GoldButton(
            label: actionLabel,
            height: 44,
            onPressed: canAfford ? onAction : null,
          ),
        ],
      ),
    );
  }
}

/// The toast for a refused purchase. When the shop changed under the
/// player, the new prices are fetched so the next tap is right.
String _purchaseErrorText(BuildContext context, WidgetRef ref, Object e) {
  final l10n = context.l10n;
  if (isShopChangedError(e)) {
    ref.read(marketplaceCatalogProvider.notifier).refresh();
    return l10n.shopPriceChanged;
  }
  return e is MarketplaceApiException ? e.message : l10n.purchaseFailed;
}

class _AvatarsTab extends ConsumerWidget {
  const _AvatarsTab({required this.profile, required this.onBusy});

  final PlayerProfile profile;
  final void Function(bool) onBusy;

  Future<void> _buyAvatar(
    BuildContext context,
    WidgetRef ref,
    ShopAvatar entry,
  ) async {
    final l10n = context.l10n;
    final avatar = entry.item;
    final price = entry.price.priceAt(DateTime.now());
    final canAfford =
        avatar.currency == CurrencyType.money
            ? profile.money >= price
            : profile.chips >= price;

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
            price: price,
          );
      SfxService.instance.buy();
      if (context.mounted) {
        CasinoToast.show(
          context,
          '${l10n.unlocked}! ${l10n.avatarName(avatar)}',
        );
      }
    } catch (e) {
      if (context.mounted) {
        CasinoToast.show(
          context,
          _purchaseErrorText(context, ref, e),
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
      CasinoToast.show(context, '${l10n.equipped}: ${l10n.avatarName(avatar)}');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final catalog = ref.watch(marketplaceCatalogProvider);
    final avatars = [
      ...catalog.featuredFirst(catalog.avatars, 'avatar', (a) => a.item.id),
      // Owned avatars that left the shop can still be equipped here.
      for (final avatar in AvatarCatalog.all)
        if (profile.ownsAvatar(avatar.id) && catalog.avatar(avatar.id) == null)
          ShopAvatar(
            item: avatar,
            price: ShopPrice(
              basePrice: avatar.price,
              currency: avatar.currency,
            ),
          ),
    ];
    final now = DateTime.now();

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      // Two columns on every phone, more as the window widens.
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        crossAxisSpacing: 12,
        mainAxisSpacing: 14,
        childAspectRatio: 0.62,
      ),
      itemCount: avatars.length,
      itemBuilder: (context, index) {
        final entry = avatars[index];
        final avatar = entry.item;
        final isOwned = profile.ownsAvatar(avatar.id);
        final isEquipped = profile.avatarId == avatar.id;
        final isFeatured =
            catalog.featured?.matches('avatar', avatar.id) ?? false;
        final name = l10n.avatarName(avatar);

        final Widget action;
        if (isEquipped) {
          action = _EquippedPill(label: l10n.equipped, compact: true);
        } else if (isOwned) {
          action = _InkButton(
            label: l10n.equip,
            onPressed: () => _equipAvatar(context, ref, avatar),
          );
        } else {
          final buy = GoldButton(
            label: '${entry.price.priceAt(now)} · ${l10n.buy}',
            compact: true,
            leading: CurrencyIcon(currency: avatar.currency, size: 14),
            onPressed: () => _buyAvatar(context, ref, entry),
          );
          action =
              entry.price.onSaleAt(now)
                  ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ShopSaleBar(
                        price: entry.price,
                        currencyIcon: CurrencyIcon(
                          currency: avatar.currency,
                          size: 12,
                        ),
                      ),
                      const SizedBox(height: 5),
                      buy,
                    ],
                  )
                  : buy;
        }

        final badge = isOwned ? null : entry.price.badge;
        return ShopSaleGlow(
          price: isOwned ? null : entry.price,
          child: IvoryCard(
            highlighted: isEquipped || (isFeatured && !isOwned),
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _CardBadge(
                      label:
                          avatar.requiredLevel <= 1
                              ? 'FREE'
                              : 'LV. ${avatar.requiredLevel}',
                      color: const Color(0xFF5A4A2A),
                    ),
                    const Spacer(),
                    if (isEquipped)
                      const _CardBadge(label: 'ACTIVE', color: Color(0xFF9A7414))
                    else if (isOwned)
                      const _CardBadge(label: 'OWNED', color: Color(0xFF1E7A45))
                    else if (badge != null)
                      Flexible(flex: 6, child: ShopBadgePill(badge: badge))
                    else if (avatar.isPremium)
                      const _CardBadge(label: 'CHIPS', color: CardInk.red),
                  ],
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Center(
                        child: LayoutBuilder(
                          builder:
                              (context, c) => PlayerAvatar(
                                avatarId: avatar.id,
                                size: c.biggest.shortestSide.clamp(60.0, 124.0),
                                borderWidth: isEquipped ? 2.4 : 1.6,
                                borderColor:
                                    isEquipped
                                        ? CasinoColors.gold
                                        : CardInk.goldLine,
                                showGlow: isEquipped,
                                glowColor: CasinoColors.gold.withValues(
                                  alpha: 0.35,
                                ),
                              ),
                        ),
                      ),
                      if (isFeatured && !isOwned)
                        const Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: ShopPromoTags(
                            featured: true,
                            alignment: MainAxisAlignment.center,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: CasinoFonts.displayOf(context),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                action,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Tiny outlined label used on ivory cards (level, owned, active...).
class _CardBadge extends StatelessWidget {
  const _CardBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Dark ink button for secondary actions on ivory cards.
class _InkButton extends StatelessWidget {
  const _InkButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onPressed,
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: CardInk.black,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: CasinoColors.gold.withValues(alpha: 0.6)),
        ),
        child: Center(
          child: Text(
            casinoButtonLabel(label, Localizations.localeOf(context)),
            style: TextStyle(
              color: CasinoColors.gold,
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
    );
  }
}

/// Non-interactive "Equipped" state shown in place of an action button.
class _EquippedPill extends StatelessWidget {
  const _EquippedPill({
    required this.label,
    this.compact = false,
    this.onIvory = true,
  });

  final String label;
  final bool compact;

  /// Dark-gold ink on ivory cards; bright gold on leather panels.
  final bool onIvory;

  @override
  Widget build(BuildContext context) {
    final ink = onIvory ? const Color(0xFF9A7414) : CasinoColors.gold;
    return Container(
      height: compact ? 36 : 48,
      decoration: BoxDecoration(
        color: CasinoColors.gold.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(compact ? 11 : 14),
        border: Border.all(color: CasinoColors.gold.withValues(alpha: 0.8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GameIcon(
            icon: AppIcons.checkCircle,
            size: compact ? 14 : 18,
            color: ink,
          ),
          const SizedBox(width: 6),
          Text(
            casinoButtonLabel(label, Localizations.localeOf(context)),
            style: TextStyle(
              color: ink,
              fontWeight: FontWeight.w900,
              fontSize: compact ? 12 : 15,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _DecksTab extends ConsumerWidget {
  const _DecksTab({required this.profile, required this.onBusy});

  final PlayerProfile profile;
  final void Function(bool) onBusy;

  Future<void> _equipDeck(
    BuildContext context,
    WidgetRef ref,
    DeckItem deck,
  ) async {
    final l10n = context.l10n;
    await ref.read(playerProfileProvider.notifier).updateDeck(deck.id);
    if (context.mounted) {
      CasinoToast.show(context, '${l10n.equipped}: ${l10n.deckName(deck)}');
    }
  }

  Future<void> _buyDeck(
    BuildContext context,
    WidgetRef ref,
    ShopDeck entry,
  ) async {
    final l10n = context.l10n;
    final deck = entry.item;
    final price = entry.price.priceAt(DateTime.now());
    if (profile.chips < price) {
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
            price: price,
          );
      SfxService.instance.buy();
      if (context.mounted) {
        CasinoToast.show(context, '${l10n.unlocked}! ${l10n.deckName(deck)}');
      }
    } catch (e) {
      if (context.mounted) {
        CasinoToast.show(
          context,
          _purchaseErrorText(context, ref, e),
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
    final catalog = ref.watch(marketplaceCatalogProvider);
    final decks = [
      ...catalog.featuredFirst(catalog.decks, 'deck', (d) => d.item.id),
      // Owned decks that left the shop can still be equipped here.
      for (final deck in DeckCatalog.all)
        if (profile.ownsDeck(deck.id) && catalog.deck(deck.id) == null)
          ShopDeck(
            item: deck,
            price: ShopPrice(
              basePrice: deck.chipPrice,
              currency: CurrencyType.chips,
            ),
          ),
    ];
    final now = DateTime.now();

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      // Two columns on every phone, more as the window widens.
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        crossAxisSpacing: 12,
        mainAxisSpacing: 14,
        childAspectRatio: 0.56,
      ),
      itemCount: decks.length,
      itemBuilder: (context, index) {
        final entry = decks[index];
        final deck = entry.item;
        final isOwned = profile.ownsDeck(deck.id);
        final isEquipped = profile.deckId == deck.id;
        final isFeatured = catalog.featured?.matches('deck', deck.id) ?? false;

        final Widget action;
        if (isEquipped) {
          action = _EquippedPill(
            label: l10n.equipped,
            compact: true,
            onIvory: false,
          );
        } else if (isOwned) {
          action = LeatherButton(
            label: l10n.equip,
            compact: true,
            onPressed: () => _equipDeck(context, ref, deck),
          );
        } else {
          final buy = GoldButton(
            label: '${entry.price.priceAt(now)} · ${l10n.buy}',
            compact: true,
            leading: const ChipIcon(size: 16),
            onPressed: () => _buyDeck(context, ref, entry),
          );
          action =
              entry.price.onSaleAt(now)
                  ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ShopSaleBar(
                        price: entry.price,
                        currencyIcon: const ChipIcon(size: 12),
                      ),
                      const SizedBox(height: 5),
                      buy,
                    ],
                  )
                  : buy;
        }

        return ShopSaleGlow(
          price: isOwned ? null : entry.price,
          radius: 20,
          child: DeckShowcaseCard(
            key: ValueKey('shop-deck-${deck.id}'),
            deck: deck,
            owned: isOwned,
            equipped: isEquipped,
            action: action,
            showcaseTag:
                isOwned
                    ? null
                    : ShopPromoTags(
                      badge: entry.price.badge,
                      featured: isFeatured,
                      alignment: MainAxisAlignment.center,
                    ),
            onPreview:
                () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder:
                        (context) => DeckPreviewScreen(
                          title: l10n.deckName(deck),
                          backSkinId: deck.skinId,
                        ),
                  ),
                ),
          ),
        );
      },
    );
  }
}

class _ShopTabLabel extends StatelessWidget {
  const _ShopTabLabel({required this.icon, required this.label});

  final Widget icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [icon, const SizedBox(width: 6), Text(label)],
      ),
    );
  }
}
