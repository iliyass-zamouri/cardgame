import 'package:cardgame/app/auth_providers.dart';
import 'package:cardgame/app/game_session_controller.dart';
import 'package:cardgame/l10n/l10n_ext.dart';
import 'package:cardgame/ui/screens/marketplace_screen.dart';
import 'package:cardgame/ui/theme/app_icons.dart';
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

/// Art is 16:9; cards show it uncropped.
const double _artAspect = 16 / 9;
const double _viewportFraction = 0.84;

/// Decoded width for pot art, sized to what the card actually paints so the
/// raster cache never holds full-resolution bitmaps.
int _potCacheWidth(BuildContext context) {
  final mq = MediaQuery.of(context);
  final px = mq.size.width * _viewportFraction * mq.devicePixelRatio;
  return px.round().clamp(320, 1280);
}

ImageProvider _potImage(String assetPath, int cacheWidth) =>
    ResizeImage(AssetImage(assetPath), width: cacheWidth);

Future<void> showStakeSelectorModal(BuildContext context) {
  // Start decoding the art before the route transition so the first frame
  // of the page doesn't stall on image decode.
  final cacheWidth = _potCacheWidth(context);
  for (final option in StakeSelectorScreen.potOptions) {
    precacheImage(_potImage(option.assetPath, cacheWidth), context);
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
  ];

  @override
  ConsumerState<StakeSelectorScreen> createState() =>
      _StakeSelectorScreenState();
}

class _StakeSelectorScreenState extends ConsumerState<StakeSelectorScreen> {
  final PageController _pageController = PageController(
    viewportFraction: _viewportFraction,
  );

  /// Selection lives in a notifier so swiping only rebuilds the dots and the
  /// bottom action panel, never the carousel itself.
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
    _pageController.animateToPage(
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
    final options = StakeSelectorScreen.potOptions;
    final cacheWidth = _potCacheWidth(context);

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
              child: Column(
                children: [
                  _BalanceStrip(
                    playerMoney: playerMoney,
                    playerChips: playerChips,
                    marketplaceLabel: l10n.marketplace,
                    onMarketplace: _openMarketplace,
                  ),
                  const SizedBox(height: 8),
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
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const dotsHeight = 34.0;
                  // Fit the 16:9 card to whichever axis is tighter so
                  // landscape / short screens never overflow.
                  final byWidth =
                      constraints.maxWidth * _viewportFraction / _artAspect;
                  final carouselHeight = (byWidth + 8).clamp(
                    0.0,
                    (constraints.maxHeight - dotsHeight).clamp(0.0, 1e9),
                  );
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: carouselHeight,
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: options.length,
                          onPageChanged: (index) => _selected.value = index,
                          itemBuilder: (context, index) {
                            final option = options[index];
                            return _CarouselItem(
                              controller: _pageController,
                              index: index,
                              child: Center(
                                child: AspectRatio(
                                  aspectRatio: _artAspect,
                                  child: _PotArtCard(
                                    option: option,
                                    image: _potImage(
                                      option.assetPath,
                                      cacheWidth,
                                    ),
                                    cityName: option.nameBuilder(l10n),
                                    canAfford: playerMoney >= option.entryStake,
                                    onTap: () => _snapTo(index),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(
                        height: dotsHeight,
                        child: ValueListenableBuilder<int>(
                          valueListenable: _selected,
                          builder:
                              (context, selected, _) => _PageDots(
                                count: options.length,
                                selected: selected,
                                onTap: _snapTo,
                              ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            ValueListenableBuilder<int>(
              valueListenable: _selected,
              builder: (context, selected, _) {
                final option = options[selected];
                final canAfford = playerMoney >= option.entryStake;
                return _ActionPanel(
                  option: option,
                  canAfford: canAfford,
                  playLabel: canAfford ? l10n.play : l10n.getMoreMoney,
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

/// Scales/dims side cards from the page offset. Only the transform is
/// recomputed per scroll frame; [child] sits behind a RepaintBoundary and is
/// never rebuilt or repainted while swiping.
class _CarouselItem extends StatelessWidget {
  const _CarouselItem({
    required this.controller,
    required this.index,
    required this.child,
  });

  final PageController controller;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: RepaintBoundary(child: child),
      ),
      builder: (context, child) {
        var page = index.toDouble();
        if (controller.hasClients && controller.position.haveDimensions) {
          page = controller.page ?? page;
        }
        final t = (1 - (index - page).abs()).clamp(0.0, 1.0);
        return Transform.scale(scale: 0.9 + 0.1 * t, child: child);
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

/// Full-bleed city art with a light HUD. Deliberately cheap to paint: no blur
/// shadows, one gradient scrim, static border.
class _PotArtCard extends StatelessWidget {
  const _PotArtCard({
    required this.option,
    required this.image,
    required this.cityName,
    required this.canAfford,
    required this.onTap,
  });

  final PotOption option;
  final ImageProvider image;
  final String cityName;
  final bool canAfford;
  final VoidCallback onTap;

  int get _tier {
    const pools = StakeSelectorScreen.stakePools;
    final i = pools.indexOf(option.pool);
    return i < 0 ? 1 : i + 1;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final accent = canAfford ? CasinoColors.gold : CasinoColors.textMuted;
    const radius = BorderRadius.all(Radius.circular(18));

    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(
            color:
                canAfford
                    ? CasinoColors.gold.withValues(alpha: 0.7)
                    : Colors.white12,
            width: 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image(
                image: image,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                color: canAfford ? null : const Color(0x73000000),
                colorBlendMode: canAfford ? null : BlendMode.darken,
                errorBuilder:
                    (_, __, ___) =>
                        const ColoredBox(color: CasinoColors.bgElevated),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x99000000),
                      Color(0x00000000),
                      Color(0x00000000),
                      Color(0xE6000000),
                    ],
                    stops: [0.0, 0.3, 0.5, 1.0],
                  ),
                ),
              ),
              // HUD is laid out at a minimum design size and scaled down
              // on small (e.g. landscape) cards instead of overflowing.
              LayoutBuilder(
                builder: (context, c) {
                  final w = c.maxWidth < 300 ? 300.0 : c.maxWidth;
                  return FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SizedBox(
                      width: w,
                      height: w / _artAspect,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                _CityBadge(name: cityName, accent: accent),
                                const Spacer(),
                                if (canAfford)
                                  _TierPips(tier: _tier)
                                else
                                  const _LockedChip(),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              l10n.pot.toUpperCase(),
                              style: TextStyle(
                                fontFamily: CasinoFonts.displayOf(context),
                                color: accent,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2.4,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${option.pool}',
                                  style: TextStyle(
                                    color:
                                        canAfford
                                            ? CasinoColors.text
                                            : CasinoColors.textMuted,
                                    fontSize: 34,
                                    fontWeight: FontWeight.w900,
                                    height: 1,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 4),
                                  child: CashIcon(size: 22),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CityBadge extends StatelessWidget {
  const _CityBadge({required this.name, required this.accent});

  final String name;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.65)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: AppIcons.flag, size: 12, color: accent),
          const SizedBox(width: 6),
          Text(
            name.toUpperCase(),
            style: TextStyle(
              fontFamily: CasinoFonts.displayOf(context),
              color: accent,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _TierPips extends StatelessWidget {
  const _TierPips({required this.tier});

  final int tier;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (i) {
          return Container(
            margin: EdgeInsets.only(left: i == 0 ? 0 : 3),
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < tier ? CasinoColors.gold : Colors.white24,
            ),
          );
        }),
      ),
    );
  }
}

class _LockedChip extends StatelessWidget {
  const _LockedChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0x99000000),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: AppIcons.lock,
            size: 11,
            color: CasinoColors.textMuted,
          ),
          SizedBox(width: 4),
          Text(
            'LOCKED',
            style: TextStyle(
              color: CasinoColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final int count;
  final int selected;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final on = i == selected;
        return GestureDetector(
          onTap: () => onTap(i),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: on ? 22 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: on ? CasinoColors.gold : Colors.white24,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Details + primary CTA for the centred pot.
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
    final fg = canAfford ? CasinoColors.goldSoft : CasinoColors.textMuted;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: CasinoColors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              HugeIcon(icon: AppIcons.trophy, size: 14, color: fg),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.winnerTakesAll.toUpperCase(),
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
                '${l10n.entryFee} ',
                style: TextStyle(
                  color: fg.withValues(alpha: 0.85),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${option.entryStake}',
                style: TextStyle(
                  color: fg,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 4),
              const CashIcon(size: 14),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors:
                      canAfford
                          ? const [CasinoColors.raise, CasinoColors.raiseHi]
                          : const [CasinoColors.gold, CasinoColors.goldSoft],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: onPlay,
                  borderRadius: BorderRadius.circular(14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (canAfford) ...[
                        const HugeIcon(
                          icon: AppIcons.bolt,
                          size: 18,
                          color: CasinoColors.text,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        playLabel.toUpperCase(),
                        style: TextStyle(
                          color:
                              canAfford ? CasinoColors.text : CasinoColors.bg,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
