import 'package:cardgame/ads/rewarded_ad_service.dart';
import 'package:cardgame/app/auth_providers.dart';
import 'package:cardgame/app/player_profile_repository.dart';
import 'package:cardgame/data/avatars/avatar_catalog.dart';
import 'package:cardgame/data/decks/deck_catalog.dart';
import 'package:cardgame/data/marketplace/marketplace_api.dart';
import 'package:cardgame/l10n/l10n_ext.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/widgets/currency_icon.dart';
import 'package:cardgame/ui/widgets/player_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  int _chipsToConvert = 1;
  int _moneyChipsToBuy = 1;

  Future<void> _convertChipsToMoney() async {
    final l10n = context.l10n;
    if (widget.profile.chips < _chipsToConvert) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.insufficientChips)));
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${l10n.exchangedSuccess}: +${_chipsToConvert * 1000} 💵',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is MarketplaceApiException ? e.message : l10n.exchangeFailed,
            ),
          ),
        );
      }
    } finally {
      if (mounted) widget.onBusy(false);
    }
  }

  Future<void> _convertMoneyToChips() async {
    final l10n = context.l10n;
    final cost = _moneyChipsToBuy * 1000;
    if (widget.profile.money < cost) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.insufficientMoney)));
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.exchangedSuccess}: +$_moneyChipsToBuy 🪙'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is MarketplaceApiException ? e.message : l10n.exchangeFailed,
            ),
          ),
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
        await ref.read(playerProfileProvider.notifier).claimAdReward();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.adRewardEarned}: +50 💵')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.adNotAvailable)));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.adNotAvailable)));
      }
    } finally {
      if (mounted) widget.onBusy(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Rate banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: CasinoColors.gold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: CasinoColors.gold.withValues(alpha: 0.3)),
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
                        const Text(
                          '+50 ',
                          style: TextStyle(
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
        const SizedBox(height: 20),

        // Exchange Chips -> Money
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
          onAction: _convertChipsToMoney,
          actionLabel: l10n.convert,
          canAfford: widget.profile.chips >= _chipsToConvert,
        ),
        const SizedBox(height: 16),

        // Exchange Money -> Chips
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
          onAction: _convertMoneyToChips,
          actionLabel: l10n.convert,
          canAfford: widget.profile.money >= (_moneyChipsToBuy * 1000),
        ),
      ],
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            avatar.currency == CurrencyType.money
                ? l10n.insufficientMoney
                : l10n.insufficientChips,
          ),
        ),
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${l10n.unlocked}! ${_getAvatarName(context, avatar.nameKey)}',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is MarketplaceApiException ? e.message : l10n.purchaseFailed,
            ),
          ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${l10n.equipped}: ${_getAvatarName(context, avatar.nameKey)}',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final avatars = AvatarCatalog.all;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.76,
      ),
      itemCount: avatars.length,
      itemBuilder: (context, index) {
        final avatar = avatars[index];
        final isOwned = profile.ownsAvatar(avatar.id);
        final isEquipped = profile.avatarId == avatar.id;
        final name = _getAvatarName(context, avatar.nameKey);

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: CasinoColors.bgElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  isEquipped
                      ? CasinoColors.gold
                      : isOwned
                      ? Colors.white24
                      : Colors.white10,
              width: isEquipped ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              PlayerAvatar(avatarId: avatar.id, size: 68),
              Text(
                name,
                style: const TextStyle(
                  color: CasinoColors.text,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              if (!isOwned)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: CasinoColors.surfaceHi,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CurrencyIcon(currency: avatar.currency, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${avatar.price}',
                        style: TextStyle(
                          color:
                              avatar.isPremium
                                  ? CasinoColors.goldSoft
                                  : CasinoColors.text,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              if (isEquipped)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: CasinoColors.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      l10n.equipped,
                      style: const TextStyle(
                        color: CasinoColors.gold,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                )
              else if (isOwned)
                ElevatedButton(
                  onPressed: () => _equipAvatar(context, ref, avatar),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CasinoColors.check,
                    foregroundColor: CasinoColors.text,
                    minimumSize: const Size.fromHeight(36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
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
                    backgroundColor: CasinoColors.raise,
                    foregroundColor: CasinoColors.text,
                    minimumSize: const Size.fromHeight(36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    l10n.buy,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
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

class _DecksTab extends ConsumerWidget {
  const _DecksTab({required this.profile, required this.onBusy});

  final PlayerProfile profile;
  final void Function(bool) onBusy;

  String _getDeckName(BuildContext context, String nameKey) {
    final l10n = context.l10n;
    switch (nameKey) {
      case 'classicDeck':
        return l10n.classicDeck;
      case 'goldLuxuryDeck':
        return l10n.goldLuxuryDeck;
      case 'shadowNeonDeck':
        return l10n.shadowNeonDeck;
      default:
        return nameKey;
    }
  }

  Future<void> _buyDeck(
    BuildContext context,
    WidgetRef ref,
    DeckItem deck,
  ) async {
    final l10n = context.l10n;
    if (profile.chips < deck.chipPrice) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.insufficientChips)));
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${l10n.unlocked}! ${_getDeckName(context, deck.nameKey)}',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is MarketplaceApiException ? e.message : l10n.purchaseFailed,
            ),
          ),
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
        final name = _getDeckName(context, deck.nameKey);

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CasinoColors.bgElevated,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color:
                  isOwned
                      ? CasinoColors.gold.withValues(alpha: 0.4)
                      : Colors.white10,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: CasinoColors.surfaceHi,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                child: Center(
                  child: Text(
                    deck.previewCardTags.firstOrNull ?? '🃏',
                    style: const TextStyle(
                      color: CasinoColors.gold,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: CasinoColors.text,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      deck.rarity.name.toUpperCase(),
                      style: const TextStyle(
                        color: CasinoColors.goldSoft,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              if (isOwned)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: CasinoColors.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    l10n.owned,
                    style: const TextStyle(
                      color: CasinoColors.gold,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                )
              else
                ElevatedButton(
                  onPressed: () => _buyDeck(context, ref, deck),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CasinoColors.raise,
                    foregroundColor: CasinoColors.text,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const ChipIcon(size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${deck.chipPrice} · ${l10n.buy}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
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
