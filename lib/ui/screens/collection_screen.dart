import 'package:cardgame/app/auth_providers.dart';
import 'package:cardgame/app/player_profile_repository.dart';
import 'package:cardgame/data/avatars/avatar_catalog.dart';
import 'package:cardgame/data/decks/deck_catalog.dart';
import 'package:cardgame/l10n/l10n_ext.dart';
import 'package:cardgame/ui/screens/deck_preview_screen.dart';
import 'package:cardgame/ui/screens/marketplace_screen.dart';
import 'package:cardgame/ui/theme/app_icons.dart';
import 'package:cardgame/ui/theme/casino_chrome.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/theme/felt_chrome.dart';
import 'package:cardgame/ui/widgets/currency_icon.dart';
import 'package:cardgame/ui/widgets/deck_fan_preview.dart';
import 'package:cardgame/ui/widgets/deck_showcase_card.dart';
import 'package:cardgame/ui/widgets/player_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

/// The player's card decks and avatars: equip what they own, and jump to the
/// shop for the rest.
class CollectionScreen extends ConsumerStatefulWidget {
  const CollectionScreen({super.key});

  @override
  ConsumerState<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends ConsumerState<CollectionScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(playerProfileProvider.notifier).refreshInventory().ignore();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _openShop({required bool avatars}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder:
            (_) => MarketplaceScreen(
              initialTab:
                  avatars ? MarketplaceTab.avatars : MarketplaceTab.decks,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final profile =
        ref.watch(playerProfileProvider).value ?? PlayerProfile.empty;
    final ownedDecks = DeckCatalog.all.where((d) => profile.ownsDeck(d.id));
    final ownedAvatars = AvatarCatalog.all.where(
      (a) => profile.ownsAvatar(a.id),
    );

    return FeltScaffold(
      title: l10n.collection,
      actions: [
        FeltIconButton(
          icon: AppIcons.shoppingBag,
          tooltip: l10n.shop,
          onTap: () => _openShop(avatars: _tabs.index == 1),
        ),
      ],
      tabs: TabBar(
        controller: _tabs,
        tabs: [
          Tab(
            height: 44,
            child: _TabLabel(
              icon: AppIcons.style,
              label: l10n.collectionCards,
              count: l10n.ownedCount(ownedDecks.length, DeckCatalog.all.length),
            ),
          ),
          Tab(
            height: 44,
            child: _TabLabel(
              icon: AppIcons.face,
              label: l10n.collectionAvatars,
              count: l10n.ownedCount(
                ownedAvatars.length,
                AvatarCatalog.all.length,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: _EquippedShowcase(
              profile: profile,
              onShop: () => _openShop(avatars: _tabs.index == 1),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _DecksGrid(
                  profile: profile,
                  onShop: () => _openShop(avatars: false),
                ),
                _AvatarsGrid(
                  profile: profile,
                  onShop: () => _openShop(avatars: true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TabLabel extends StatelessWidget {
  const _TabLabel({
    required this.icon,
    required this.label,
    required this.count,
  });

  final List<List<dynamic>> icon;
  final String label;
  final String count;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(icon: icon, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        // Follows the tab's selected / unselected label colour.
        Opacity(
          opacity: 0.75,
          child: Text(
            count,
            maxLines: 1,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

/// What the player is using right now, with the main shop entry point.
class _EquippedShowcase extends StatelessWidget {
  const _EquippedShowcase({required this.profile, required this.onShop});

  final PlayerProfile profile;
  final VoidCallback onShop;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final avatar = AvatarCatalog.all.firstWhere(
      (a) => a.id == profile.avatarId,
      orElse: () => AvatarCatalog.defaultAvatar,
    );
    final deck = DeckCatalog.all.firstWhere(
      (d) => d.id == profile.deckId,
      orElse: () => DeckCatalog.defaultDeck,
    );

    return FeltPanel(
      highlighted: true,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              PlayerAvatar(
                avatarId: avatar.id,
                size: 62,
                borderWidth: 2.2,
                borderColor: CasinoColors.gold,
                showGlow: true,
                glowColor: CasinoColors.gold.withValues(alpha: 0.35),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      casinoButtonLabel(l10n.equipped, locale),
                      style: TextStyle(
                        fontFamily: CasinoFonts.displayFor(locale),
                        color: CasinoColors.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: locale.languageCode == 'ar' ? 0 : 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _ShowcaseLine(
                      icon: AppIcons.face,
                      text: l10n.avatarName(avatar),
                    ),
                    const SizedBox(height: 2),
                    _ShowcaseLine(
                      icon: AppIcons.style,
                      text: l10n.deckName(deck),
                    ),
                  ],
                ),
              ),
              DeckFanPreview(
                skinId: deck.skinId,
                cardWidth: 40,
                count: 3,
                spread: 12,
                heightPadding: 6,
              ),
            ],
          ),
          const SizedBox(height: 10),
          GoldButton(
            label: l10n.shop,
            compact: true,
            leading: const HugeIcon(icon: AppIcons.shoppingBag),
            onPressed: onShop,
          ),
        ],
      ),
    );
  }
}

class _ShowcaseLine extends StatelessWidget {
  const _ShowcaseLine({required this.icon, required this.text});

  final List<List<dynamic>> icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        HugeIcon(icon: icon, size: 13, color: CasinoColors.goldSoft),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: CasinoColors.text,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

/// Owned items first, catalog order otherwise.
List<T> _ownedFirst<T>(List<T> items, bool Function(T) owns) => [
  ...items.where(owns),
  ...items.where((item) => !owns(item)),
];

/// Grid followed by a "get more" shop banner.
class _CollectionGrid extends StatelessWidget {
  const _CollectionGrid({
    required this.delegate,
    required this.itemCount,
    required this.itemBuilder,
    required this.onShop,
  });

  final SliverGridDelegate delegate;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final VoidCallback onShop;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          sliver: SliverGrid(
            gridDelegate: delegate,
            delegate: SliverChildBuilderDelegate(
              itemBuilder,
              childCount: itemCount,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          sliver: SliverToBoxAdapter(
            child: LeatherButton(
              label: context.l10n.getMoreInShop,
              leading: const HugeIcon(icon: AppIcons.shoppingBag),
              onPressed: onShop,
            ),
          ),
        ),
      ],
    );
  }
}

class _DecksGrid extends ConsumerWidget {
  const _DecksGrid({required this.profile, required this.onShop});

  final PlayerProfile profile;
  final VoidCallback onShop;

  Future<void> _equip(
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final decks = _ownedFirst(DeckCatalog.all, (d) => profile.ownsDeck(d.id));

    return _CollectionGrid(
      onShop: onShop,
      itemCount: decks.length,
      delegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 14,
        childAspectRatio: 0.56,
      ),
      itemBuilder: (context, index) {
        final deck = decks[index];
        final owned = profile.ownsDeck(deck.id);
        final equipped = profile.deckId == deck.id;

        final Widget action;
        if (equipped) {
          action = const _EquippedPill();
        } else if (owned) {
          action = LeatherButton(
            label: l10n.equip,
            compact: true,
            onPressed: () => _equip(context, ref, deck),
          );
        } else {
          action = GoldButton(
            label: '${deck.chipPrice}',
            compact: true,
            leading: const ChipIcon(size: 16),
            onPressed: onShop,
          );
        }

        return DeckShowcaseCard(
          key: ValueKey('deck-${deck.id}'),
          deck: deck,
          owned: owned,
          equipped: equipped,
          locked: !owned,
          action: action,
          onPreview:
              owned
                  ? () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder:
                          (_) => DeckPreviewScreen(
                            title: l10n.deckName(deck),
                            backSkinId: deck.skinId,
                          ),
                    ),
                  )
                  : onShop,
        );
      },
    );
  }
}

class _AvatarsGrid extends ConsumerWidget {
  const _AvatarsGrid({required this.profile, required this.onShop});

  final PlayerProfile profile;
  final VoidCallback onShop;

  Future<void> _equip(
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
    final avatars = _ownedFirst(
      AvatarCatalog.all,
      (a) => profile.ownsAvatar(a.id),
    );

    return _CollectionGrid(
      onShop: onShop,
      itemCount: avatars.length,
      delegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.62,
      ),
      itemBuilder: (context, index) {
        final avatar = avatars[index];
        final owned = profile.ownsAvatar(avatar.id);
        final equipped = profile.avatarId == avatar.id;

        final Widget action;
        if (equipped) {
          action = const _EquippedPill(onIvory: true);
        } else if (owned) {
          action = _InkButton(
            label: l10n.equip,
            onPressed: () => _equip(context, ref, avatar),
          );
        } else {
          action = GoldButton(
            label: '${avatar.price}',
            compact: true,
            leading: CurrencyIcon(currency: avatar.currency, size: 14),
            onPressed: onShop,
          );
        }

        return IvoryCard(
          key: ValueKey('avatar-${avatar.id}'),
          highlighted: equipped,
          padding: const EdgeInsets.all(8),
          onTap: owned ? null : onShop,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Center(
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final size = c.biggest.shortestSide.clamp(40.0, 84.0);
                      final picture = PlayerAvatar(
                        avatarId: avatar.id,
                        size: size,
                        borderWidth: equipped ? 2.4 : 1.4,
                        borderColor:
                            equipped ? CasinoColors.gold : CardInk.goldLine,
                        showGlow: equipped,
                        glowColor: CasinoColors.gold.withValues(alpha: 0.35),
                      );
                      if (owned) return picture;
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Opacity(
                            opacity: 0.55,
                            child: ColorFiltered(
                              colorFilter: _greyscale,
                              child: picture,
                            ),
                          ),
                          const _LockBadge(),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.avatarName(avatar),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: CasinoFonts.displayOf(context),
                  color: CardInk.black,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              action,
            ],
          ),
        );
      },
    );
  }
}

const _greyscale = ColorFilter.matrix([
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0, 0, 0, 1, 0,
]);

class _EquippedPill extends StatelessWidget {
  const _EquippedPill({this.onIvory = false});

  final bool onIvory;

  @override
  Widget build(BuildContext context) {
    final color = onIvory ? const Color(0xFF9A7414) : CasinoColors.gold;
    return Container(
      height: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: color.withValues(alpha: 0.14),
        border: Border.all(color: color.withValues(alpha: 0.7)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HugeIcon(icon: AppIcons.check, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                context.l10n.equipped,
                maxLines: 1,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LockBadge extends StatelessWidget {
  const _LockBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: CardInk.black.withValues(alpha: 0.75),
        border: Border.all(color: CasinoColors.gold.withValues(alpha: 0.7)),
      ),
      child: HugeIcon(
        icon: AppIcons.lock,
        size: 16,
        color: CasinoColors.goldSoft,
      ),
    );
  }
}

class _InkButton extends StatelessWidget {
  const _InkButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return Pressable(
      onTap: onPressed,
      child: Container(
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: CardInk.black,
          border: Border.all(color: CasinoColors.gold.withValues(alpha: 0.6)),
        ),
        child: Text(
          casinoButtonLabel(label, locale),
          maxLines: 1,
          style: TextStyle(
            fontFamily: CasinoFonts.displayFor(locale),
            color: CasinoColors.gold,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: locale.languageCode == 'ar' ? 0 : 0.8,
          ),
        ),
      ),
    );
  }
}
