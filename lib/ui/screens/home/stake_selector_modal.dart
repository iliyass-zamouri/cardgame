import 'dart:math' as math;

import 'package:cardgame/app/auth_providers.dart';
import 'package:cardgame/app/game_session_controller.dart';
import 'package:cardgame/data/avatars/avatar_catalog.dart';
import 'package:cardgame/l10n/l10n_ext.dart';
import 'package:cardgame/ui/flame/suit_shapes.dart';
import 'package:cardgame/ui/screens/marketplace_screen.dart';
import 'package:cardgame/ui/theme/app_icons.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/theme/felt_chrome.dart';
import 'package:cardgame/ui/widgets/currency_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

class PotOption {
  const PotOption({
    required this.id,
    required this.assetPath,
    required this.pool,
    required this.nameBuilder,
    this.currency = CurrencyType.money,
  });

  final String id;
  final String assetPath;
  final int pool;
  final String Function(AppLocalizations l10n) nameBuilder;

  /// Balance the entry is paid in and the pot is won in.
  final CurrencyType currency;

  int get entryStake => pool ~/ 2;

  bool canAfford({required int money, required int chips}) =>
      (currency == CurrencyType.chips ? chips : money) >= entryStake;
}

/// City art is 16:9; it sits uncropped in the card's picture window.
const double _artAspect = 16 / 9;

/// Portrait playing-card proportions for each pot.
const double _cardAspect = 0.66;
const double _viewportFraction = 0.72;

/// Pot cards are laid out at this design width and scaled to fit.
const double _designCardWidth = 240;

/// Each pot tier reads as a higher card: 10♣ · J♦ · Q♥ · K♠ · A♠, then the
/// chip tables as the remaining aces: A♥ · A♦ · A♣.
const _tierRanks = ['10', 'J', 'Q', 'K', 'A', 'A', 'A', 'A'];
const _tierSuits = [
  SuitShape.clubs,
  SuitShape.diamonds,
  SuitShape.hearts,
  SuitShape.spades,
  SuitShape.spades,
  SuitShape.hearts,
  SuitShape.diamonds,
  SuitShape.clubs,
];

/// Chip colour per city, in pot order: London green, Paris blue, Moscow red,
/// Cairo black, Marrakech white, Toronto teal, New York violet, Tokyo pink.
const _tierChipColors = [
  Color(0xFF2E7D32),
  Color(0xFF2F6DB5),
  Color(0xFFC62828),
  Color(0xFF1E1E22),
  Color(0xFFF3EFE6),
  Color(0xFF1F8A8A),
  Color(0xFF6A3FA0),
  Color(0xFFD6336C),
];

/// Light chips (white) take dark details so the value and spots stay legible.
bool _isLightChip(Color color) => color.computeLuminance() > 0.5;

/// Decoded width for pot art, sized to what the card window actually paints
/// so the raster cache never holds full-resolution bitmaps.
int _potCacheWidth(BuildContext context) {
  final mq = MediaQuery.of(context);
  final px = mq.size.width * _viewportFraction * 0.8 * mq.devicePixelRatio;
  return px.round().clamp(320, 1280);
}

ImageProvider _potImage(String assetPath, int cacheWidth) =>
    ResizeImage(AssetImage(assetPath), width: cacheWidth);

Future<void> showStakeSelectorModal(BuildContext context) {
  // Start decoding the art before the route transition so the first frame
  // of the page doesn't stall on image decode.
  final cacheWidth = _potCacheWidth(context);
  for (final option in StakeSelectorScreen.potOptions) {
    precacheImage(
      _potImage(option.assetPath, cacheWidth),
      context,
      // Missing art falls back to plain felt in the card window.
      onError: (_, __) {},
    );
  }
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
      assetPath: 'assets/pots/london.webp',
      pool: 20,
      nameBuilder: (l10n) => l10n.cityLondon,
    ),
    PotOption(
      id: 'paris',
      assetPath: 'assets/pots/paris.webp',
      pool: 50,
      nameBuilder: (l10n) => l10n.cityParis,
    ),
    PotOption(
      id: 'moscow',
      assetPath: 'assets/pots/moscow.webp',
      pool: 100,
      nameBuilder: (l10n) => l10n.cityMoscow,
    ),
    PotOption(
      id: 'cairo',
      assetPath: 'assets/pots/cairo.webp',
      pool: 200,
      nameBuilder: (l10n) => l10n.cityCairo,
    ),
    PotOption(
      id: 'marrakech',
      assetPath: 'assets/pots/marrakech.webp',
      pool: 500,
      nameBuilder: (l10n) => l10n.cityMarrakech,
    ),
    // Chip tables: entry 1 · 5 · 25 chips (1 chip = 1000 money).
    PotOption(
      id: 'toronto',
      assetPath: 'assets/pots/toronto.webp',
      pool: 2,
      currency: CurrencyType.chips,
      nameBuilder: (l10n) => l10n.cityToronto,
    ),
    PotOption(
      id: 'new_york',
      assetPath: 'assets/pots/new_york.webp',
      pool: 10,
      currency: CurrencyType.chips,
      nameBuilder: (l10n) => l10n.cityNewYork,
    ),
    PotOption(
      id: 'tokyo',
      assetPath: 'assets/pots/tokyo.webp',
      pool: 50,
      currency: CurrencyType.chips,
      nameBuilder: (l10n) => l10n.cityTokyo,
    ),
  ];

  @override
  ConsumerState<StakeSelectorScreen> createState() =>
      _StakeSelectorScreenState();
}

class _StakeSelectorScreenState extends ConsumerState<StakeSelectorScreen> {
  final PageController _pageController = PageController(
    viewportFraction: _viewportFraction,
  );

  /// Selection lives in a notifier so swiping only rebuilds the chip rail and
  /// the bottom action panel, never the carousel itself.
  final ValueNotifier<int> _selected = ValueNotifier<int>(0);

  @override
  void dispose() {
    _pageController.dispose();
    _selected.dispose();
    super.dispose();
  }

  void _onPlay(PotOption option, bool canAfford) {
    if (canAfford) {
      final sessionNotifier = ref.read(gameSessionProvider.notifier);
      Navigator.of(context).pop();
      // Queue match first; MatchmakingWaiting shows the interstitial while searching.
      sessionNotifier.findMatch(
        stakePool: option.pool,
        stakeCurrency: option.currency,
      );
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
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final profile = ref.watch(playerProfileProvider).value;
    final playerMoney = profile?.money ?? 0;
    final playerChips = profile?.chips ?? 0;
    final options = StakeSelectorScreen.potOptions;
    final cacheWidth = _potCacheWidth(context);

    return FeltScaffold(
      title: l10n.selectMatchStake,
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: _BalanceStrip(
                playerMoney: playerMoney,
                playerChips: playerChips,
                marketplaceLabel: l10n.marketplace,
                onMarketplace: _openMarketplace,
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Fit the portrait card to whichever axis is tighter so
                  // short screens never overflow.
                  final byWidth = constraints.maxWidth * _viewportFraction - 16;
                  final byHeight = (constraints.maxHeight - 28) * _cardAspect;
                  final cardWidth = math.max(0.0, math.min(byWidth, byHeight));
                  return Center(
                    child: SizedBox(
                      height: cardWidth / _cardAspect + 24,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: options.length,
                        onPageChanged: (index) {
                          HapticFeedback.selectionClick();
                          _selected.value = index;
                        },
                        itemBuilder: (context, index) {
                          final option = options[index];
                          return _CarouselItem(
                            controller: _pageController,
                            index: index,
                            selected: _selected,
                            child: Center(
                              child: SizedBox(
                                width: cardWidth,
                                height: cardWidth / _cardAspect,
                                child: _PotPlayingCard(
                                  option: option,
                                  tier: index,
                                  image: _potImage(
                                    option.assetPath,
                                    cacheWidth,
                                  ),
                                  cityName: option.nameBuilder(l10n),
                                  canAfford: option.canAfford(
                                    money: playerMoney,
                                    chips: playerChips,
                                  ),
                                  onTap: () => _snapTo(index),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            ValueListenableBuilder<int>(
              valueListenable: _selected,
              builder:
                  (context, selected, _) => _ChipRail(
                    options: options,
                    selected: selected,
                    playerMoney: playerMoney,
                    playerChips: playerChips,
                    onTap: _snapTo,
                  ),
            ),
            ValueListenableBuilder<int>(
              valueListenable: _selected,
              builder: (context, selected, _) {
                final option = options[selected];
                final canAfford = option.canAfford(
                  money: playerMoney,
                  chips: playerChips,
                );
                return _ActionPanel(
                  option: option,
                  canAfford: canAfford,
                  playLabel:
                      canAfford
                          ? l10n.play
                          : option.currency == CurrencyType.chips
                          ? l10n.getMoreChips
                          : l10n.getMoreMoney,
                  onPlay: () => _onPlay(option, canAfford),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Fans side cards away from the centre like a hand being spread. Only the
/// transform is recomputed per scroll frame; [child] sits behind a
/// RepaintBoundary and is never rebuilt while swiping.
class _CarouselItem extends StatelessWidget {
  const _CarouselItem({
    required this.controller,
    required this.index,
    required this.selected,
    required this.child,
  });

  final PageController controller;
  final int index;
  final ValueNotifier<int> selected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      child: RepaintBoundary(child: child),
      builder: (context, child) {
        var page = index.toDouble();
        if (controller.hasClients && controller.position.haveDimensions) {
          page = controller.page ?? page;
        }
        final offset = (index - page).clamp(-1.5, 1.5);
        final t = (1 - offset.abs()).clamp(0.0, 1.0);
        final rtl = Directionality.of(context) == TextDirection.rtl;
        return Transform.translate(
          offset: Offset(0, 18 * (1 - t)),
          child: Transform.rotate(
            angle: offset * 0.09 * (rtl ? -1 : 1),
            child: Transform.scale(
              scale: 0.86 + 0.14 * t,
              child: Opacity(opacity: 0.55 + 0.45 * t, child: child),
            ),
          ),
        );
      },
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
    return Column(
      children: [
        Container(
          padding: const EdgeInsetsDirectional.fromSTEB(14, 6, 6, 6),
          decoration: feltPanelDecoration(),
          child: Row(
            children: [
              const CashIcon(size: 20),
              const SizedBox(width: 6),
              Text(
                '$playerMoney',
                style: const TextStyle(
                  color: CasinoColors.text,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 16),
              const ChipIcon(size: 20),
              const SizedBox(width: 6),
              Text(
                '$playerChips',
                style: const TextStyle(
                  color: CasinoColors.goldSoft,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onMarketplace,
                  borderRadius: BorderRadius.circular(12),
                  child: Ink(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: CasinoColors.gold.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: CasinoColors.gold.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const HugeIcon(
                          icon: AppIcons.shoppingBag,
                          size: 15,
                          color: CasinoColors.gold,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          marketplaceLabel,
                          style: const TextStyle(
                            color: CasinoColors.gold,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
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
        const SizedBox(height: 6),
        const Text(
          'Virtual currency only. No real-money cash-out.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: CasinoColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// A pot table shown as an ivory playing card: tier rank in the corners,
/// city art in a framed window, and the pot value as the card's face.
class _PotPlayingCard extends StatelessWidget {
  const _PotPlayingCard({
    required this.option,
    required this.tier,
    required this.image,
    required this.cityName,
    required this.canAfford,
    required this.onTap,
  });

  final PotOption option;
  final int tier;
  final ImageProvider image;
  final String cityName;
  final bool canAfford;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rank = _tierRanks[tier.clamp(0, _tierRanks.length - 1)];
    final suit = _tierSuits[tier.clamp(0, _tierSuits.length - 1)];
    const radius = BorderRadius.all(Radius.circular(16));

    return GestureDetector(
      onTap: onTap,
      child: Semantics(
        button: true,
        label: '$cityName ${option.pool}',
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              const BoxShadow(
                color: Color(0x8C000000),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
              if (canAfford)
                BoxShadow(
                  color: CasinoColors.gold.withValues(alpha: 0.18),
                  blurRadius: 24,
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: FittedBox(
              child: SizedBox(
                width: _designCardWidth,
                height: _designCardWidth / _cardAspect,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: _CardFace(
                        option: option,
                        rank: rank,
                        suit: suit,
                        image: image,
                        cityName: cityName,
                      ),
                    ),
                    if (!canAfford) const Positioned.fill(child: _LockedVeil()),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardFace extends StatelessWidget {
  const _CardFace({
    required this.option,
    required this.rank,
    required this.suit,
    required this.image,
    required this.cityName,
  });

  final PotOption option;
  final String rank;
  final SuitShape suit;
  final ImageProvider image;
  final String cityName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final ink = suitColor(suit);
    final corner = _CornerIndex(rank: rank, suit: suit);

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [CardInk.ivory, CardInk.ivoryShade],
        ),
      ),
      child: Stack(
        children: [
          // Inner gold frame line.
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: CardInk.goldLine.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
          Positioned(top: 12, left: 12, child: corner),
          Positioned(
            bottom: 12,
            right: 12,
            child: Transform.rotate(angle: math.pi, child: corner),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 24, 40, 22),
            child: Column(
              children: [
                // City art window.
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: CardInk.goldLine, width: 1.5),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: AspectRatio(
                    aspectRatio: _artAspect,
                    child: Image(
                      image: image,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      errorBuilder:
                          (_, __, ___) =>
                              const ColoredBox(color: CasinoColors.feltDeep),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    casinoButtonLabel(cityName, locale),
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: CasinoFonts.displayFor(locale),
                      color: CardInk.black,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: locale.languageCode == 'ar' ? 0 : 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                _SuitDivider(suit: suit),
                const Spacer(),
                Text(
                  casinoButtonLabel(l10n.pot, locale),
                  style: TextStyle(
                    fontFamily: CasinoFonts.displayFor(locale),
                    color: ink.withValues(alpha: 0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: locale.languageCode == 'ar' ? 0 : 2.4,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '${option.pool}',
                      style: TextStyle(
                        fontFamily: CasinoFonts.display,
                        color: ink,
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(width: 6),
                    CurrencyIcon(currency: option.currency, size: 30),
                  ],
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${l10n.entryFee} ${option.entryStake}',
                      style: const TextStyle(
                        color: Color(0xFF5A4A2A),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    CurrencyIcon(currency: option.currency, size: 14),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CornerIndex extends StatelessWidget {
  const _CornerIndex({required this.rank, required this.suit});

  final String rank;
  final SuitShape suit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            rank,
            style: TextStyle(
              fontFamily: CasinoFonts.display,
              color: suitColor(suit),
              fontSize: rank.length > 1 ? 17 : 21,
              fontWeight: FontWeight.w800,
              height: 1,
              letterSpacing: rank.length > 1 ? -1.5 : 0,
            ),
          ),
          const SizedBox(height: 3),
          SuitGlyph(suit: suit, size: 14),
        ],
      ),
    );
  }
}

class _SuitDivider extends StatelessWidget {
  const _SuitDivider({required this.suit});

  final SuitShape suit;

  @override
  Widget build(BuildContext context) {
    final line = Expanded(
      child: Container(
        height: 1,
        color: CardInk.goldLine.withValues(alpha: 0.6),
      ),
    );
    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: SuitGlyph(suit: suit, size: 12),
        ),
        line,
      ],
    );
  }
}

/// Dims a pot the player can't afford and stamps it with a lock seal.
class _LockedVeil extends StatelessWidget {
  const _LockedVeil();

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return ColoredBox(
      color: const Color(0x8C0A1711),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [CasinoColors.leather, CasinoColors.leatherDeep],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: CasinoColors.gold.withValues(alpha: 0.6)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const HugeIcon(
                icon: AppIcons.lock,
                size: 18,
                color: CasinoColors.gold,
              ),
              const SizedBox(width: 8),
              Text(
                casinoButtonLabel(context.l10n.locked, locale),
                style: TextStyle(
                  color: CasinoColors.goldSoft,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: locale.languageCode == 'ar' ? 0 : 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Row of poker chips, one per pot tier; the selected chip lifts off the felt.
class _ChipRail extends StatelessWidget {
  const _ChipRail({
    required this.options,
    required this.selected,
    required this.playerMoney,
    required this.playerChips,
    required this.onTap,
  });

  final List<PotOption> options;
  final int selected;
  final int playerMoney;
  final int playerChips;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    // Shrinks the rail on narrow screens so every pot's chip stays visible.
    return SizedBox(
      height: 70,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < options.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Pressable(
                  onTap: () => onTap(i),
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutBack,
                    offset: Offset(0, i == selected ? -0.18 : 0.06),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity:
                          options[i].canAfford(
                                money: playerMoney,
                                chips: playerChips,
                              )
                              ? 1
                              : 0.45,
                      child: _PokerChip(
                        value: options[i].pool,
                        color: _tierChipColors[i % _tierChipColors.length],
                        selected: i == selected,
                      ),
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

class _PokerChip extends StatelessWidget {
  const _PokerChip({
    required this.value,
    required this.color,
    required this.selected,
  });

  final int value;
  final Color color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    const size = 50.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          const BoxShadow(
            color: Color(0x99000000),
            blurRadius: 6,
            offset: Offset(0, 4),
          ),
          if (selected)
            BoxShadow(
              color: CasinoColors.gold.withValues(alpha: 0.55),
              blurRadius: 14,
              spreadRadius: 1,
            ),
        ],
      ),
      child: CustomPaint(
        painter: _PokerChipPainter(color: color, selected: selected),
        child: Center(
          child: Text(
            '$value',
            style: TextStyle(
              color: _isLightChip(color) ? CardInk.black : Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              shadows:
                  _isLightChip(color)
                      ? null
                      : const [Shadow(color: Color(0x99000000), blurRadius: 2)],
            ),
          ),
        ),
      ),
    );
  }
}

class _PokerChipPainter extends CustomPainter {
  _PokerChipPainter({required this.color, required this.selected});

  final Color color;
  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    // Ivory details on dark chips, dark details on the white chip.
    final detail =
        _isLightChip(color) ? const Color(0xFF1E1E22) : CardInk.ivory;
    canvas.drawCircle(c, r, Paint()..color = color);

    // Edge spots: six blocks around the rim.
    final spot =
        Paint()
          ..color = detail
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.22;
    final rimRect = Rect.fromCircle(center: c, radius: r * 0.86);
    for (var i = 0; i < 6; i++) {
      canvas.drawArc(rimRect, i * math.pi / 3, math.pi / 9, false, spot);
    }

    // Inner dashed ring and centre inlay.
    final ring =
        Paint()
          ..color = detail.withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;
    final innerRect = Rect.fromCircle(center: c, radius: r * 0.62);
    for (var i = 0; i < 16; i++) {
      canvas.drawArc(innerRect, i * math.pi / 8, math.pi / 14, false, ring);
    }
    canvas.drawCircle(
      c,
      r * 0.52,
      Paint()
        ..color =
            Color.lerp(color, Colors.black, _isLightChip(color) ? 0.08 : 0.25)!,
    );
    canvas.drawCircle(
      c,
      r - 0.75,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 2 : 1.5
        ..color = selected ? CasinoColors.gold : Colors.black45,
    );
  }

  @override
  bool shouldRepaint(covariant _PokerChipPainter old) =>
      old.color != color || old.selected != selected;
}

/// Leather rail with the payout summary and the main call to action.
class _ActionPanel extends StatelessWidget {
  const _ActionPanel({
    required this.option,
    required this.canAfford,
    required this.playLabel,
    required this.onPlay,
  });

  final PotOption option;
  final bool canAfford;
  final String playLabel;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [CasinoColors.leather, CasinoColors.leatherDeep],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: CasinoColors.gold.withValues(alpha: 0.35)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const HugeIcon(
                icon: AppIcons.trophy,
                size: 16,
                color: CasinoColors.goldSoft,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  casinoButtonLabel(l10n.winnerTakesAll, locale),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: CasinoColors.text,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Text(
                '${option.pool}',
                style: const TextStyle(
                  color: CasinoColors.gold,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 4),
              CurrencyIcon(currency: option.currency, size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Pressable(
            onTap: onPlay,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient:
                    canAfford
                        ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFFFE08A),
                            CasinoColors.gold,
                            Color(0xFFC8961E),
                          ],
                        )
                        : null,
                color: canAfford ? null : Colors.black.withValues(alpha: 0.3),
                border: Border.all(
                  color:
                      canAfford
                          ? const Color(0xFF7A5A0E).withValues(alpha: 0.5)
                          : CasinoColors.gold.withValues(alpha: 0.6),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          canAfford
                              ? CardInk.black
                              : CasinoColors.gold.withValues(alpha: 0.15),
                    ),
                    child: HugeIcon(
                      icon: canAfford ? AppIcons.bolt : AppIcons.shoppingBag,
                      size: 20,
                      color: CasinoColors.gold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      casinoButtonLabel(playLabel, locale),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: CasinoFonts.displayFor(locale),
                        color: canAfford ? CardInk.black : CasinoColors.gold,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: locale.languageCode == 'ar' ? 0 : 1.4,
                      ),
                    ),
                  ),
                  // Entry fee chip balances the leading icon.
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(
                        alpha: canAfford ? 0.12 : 0.3,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${option.entryStake}',
                          style: TextStyle(
                            color:
                                canAfford ? CardInk.black : CasinoColors.text,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 4),
                        CurrencyIcon(currency: option.currency, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
