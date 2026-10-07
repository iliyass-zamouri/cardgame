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
import 'package:cardgame/ui/theme/pot_card_style.dart';
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
    this.artAlignment = Alignment.center,
  });

  final String id;
  final String assetPath;
  final int pool;
  final String Function(AppLocalizations l10n) nameBuilder;

  /// Balance the entry is paid in and the pot is won in.
  final CurrencyType currency;

  /// Where the 16:9 art is anchored in the narrower card window, so the
  /// city's landmark survives the side crop.
  final Alignment artAlignment;

  int get entryStake => pool ~/ 2;

  bool canAfford({required int money, required int chips}) =>
      (currency == CurrencyType.chips ? chips : money) >= entryStake;
}

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
  // Art ships at 1024px wide; decoding larger only wastes memory.
  return px.round().clamp(320, 1024);
}

ImageProvider _potImage(String assetPath, int cacheWidth) =>
    ResizeImage(AssetImage(assetPath), width: cacheWidth);

/// Pot art bundled with the app. Cities without art are never requested
/// from the bundle; their card shows the city emblem instead.
Set<String>? _shippedPotArt;

Future<Set<String>> _loadShippedPotArt() async {
  final cached = _shippedPotArt;
  if (cached != null) return cached;
  try {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    return _shippedPotArt =
        manifest
            .listAssets()
            .where((path) => path.startsWith('assets/pots/'))
            .toSet();
  } catch (_) {
    return const {};
  }
}

Future<void> showStakeSelectorModal(BuildContext context) async {
  final shipped = await _loadShippedPotArt();
  if (!context.mounted) return;
  // Start decoding the art before the route transition so the first frame
  // of the page doesn't stall on image decode.
  final cacheWidth = _potCacheWidth(context);
  for (final option in StakeSelectorScreen.potOptions) {
    if (!shipped.contains(option.assetPath)) continue;
    precacheImage(
      _potImage(option.assetPath, cacheWidth),
      context,
      onError: (_, __) {},
    );
  }
  await Navigator.of(context).push<void>(
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
      artAlignment: const Alignment(-0.85, 0),
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
      artAlignment: const Alignment(0.55, 0),
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
      artAlignment: const Alignment(0.7, 0),
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

  /// Art paths in the bundle; null until the manifest is read.
  Set<String>? _shippedArt = _shippedPotArt;

  @override
  void initState() {
    super.initState();
    if (_shippedArt == null) {
      _loadShippedPotArt().then((shipped) {
        if (mounted) setState(() => _shippedArt = shipped);
      });
    }
  }

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
                                  image:
                                      _shippedArt?.contains(option.assetPath) ??
                                              false
                                          ? _potImage(
                                            option.assetPath,
                                            cacheWidth,
                                          )
                                          : null,
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

  /// City art, or null when the app doesn't ship any for this city.
  final ImageProvider? image;
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

/// Ivory card face laid out at [_designCardWidth]: city art in a shaped
/// window, the city name on a ribbon, then the pot value and entry fee, all
/// dressed in the city's own [PotCardStyle].
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

  /// City art, or null when the app doesn't ship any for this city.
  final ImageProvider? image;
  final String cityName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final style = PotCardStyle.forCity(option.id);
    final corner = _CornerIndex(rank: rank, suit: suit, color: style.ink);
    final spaced = locale.languageCode != 'ar';

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [style.paper, style.paperShade],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: PotCornerPainter(style))),
          // Inner trim frame line.
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: style.trim, width: 1.2),
              ),
            ),
          ),
          Positioned(top: 13, left: 11, child: corner),
          Positioned(
            bottom: 13,
            right: 11,
            child: Transform.rotate(angle: math.pi, child: corner),
          ),
          // City art window.
          Positioned(
            top: 18,
            left: 36,
            right: 36,
            height: 122,
            child: CustomPaint(
              foregroundPainter: PotWindowFramePainter(style),
              child: ClipPath(
                clipper: PotWindowClipper(style.window),
                child:
                    image == null
                        ? _CitySign(style: style)
                        : Image(
                          image: image!,
                          fit: BoxFit.cover,
                          alignment: option.artAlignment,
                          gaplessPlayback: true,
                          errorBuilder: (_, __, ___) => _CitySign(style: style),
                        ),
              ),
            ),
          ),
          // City name ribbon.
          Positioned(
            top: 150,
            left: 12,
            right: 12,
            height: 36,
            child: CustomPaint(
              painter: PotRibbonPainter(style, tail: true),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      casinoButtonLabel(cityName, locale),
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: CasinoFonts.displayFor(locale),
                        color: style.onRibbon,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: spaced ? 1.4 : 0,
                        shadows: [
                          style.onRibbon.computeLuminance() > 0.5
                              ? const Shadow(
                                color: Color(0x66000000),
                                blurRadius: 2,
                              )
                              : const Shadow(
                                color: Color(0x80FFF4CC),
                                offset: Offset(0, 1),
                              ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 196,
            left: 34,
            right: 34,
            height: 18,
            child: _OrnamentDivider(style: style),
          ),
          Positioned(
            top: 228,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Text(
                  casinoButtonLabel(l10n.pot, locale),
                  style: TextStyle(
                    fontFamily: CasinoFonts.displayFor(locale),
                    color: style.ink.withValues(alpha: 0.85),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: spaced ? 2.4 : 0,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${option.pool}',
                        style: TextStyle(
                          fontFamily: CasinoFonts.display,
                          color: style.ink,
                          fontSize: 50,
                          fontWeight: FontWeight.w800,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(width: 6),
                      CurrencyIcon(currency: option.currency, size: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Entry fee tag.
          Positioned(
            bottom: 26,
            left: 0,
            right: 0,
            child: Center(
              child: CustomPaint(
                painter: PotRibbonPainter(style),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 5, 16, 5),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${l10n.entryFee} ${option.entryStake}',
                        style: TextStyle(
                          fontFamily: CasinoFonts.uiFor(locale),
                          color: style.onRibbon,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 5),
                      CurrencyIcon(currency: option.currency, size: 16),
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

/// Stand-in for missing city art: the city's colours and emblem.
class _CitySign extends StatelessWidget {
  const _CitySign({required this.style});

  final PotCardStyle style;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          radius: 0.9,
          colors: [Color.lerp(style.ink, Colors.white, 0.18)!, style.inkDeep],
        ),
      ),
      child: Center(
        child: Container(
          width: 74,
          height: 74,
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: style.paper,
            border: Border.all(color: style.trim, width: 2),
            boxShadow: const [
              BoxShadow(color: Color(0x66000000), blurRadius: 8),
            ],
          ),
          child: CustomPaint(painter: PotEmblemPainter(style)),
        ),
      ),
    );
  }
}

class _CornerIndex extends StatelessWidget {
  const _CornerIndex({
    required this.rank,
    required this.suit,
    required this.color,
  });

  final String rank;
  final SuitShape suit;
  final Color color;

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
              color: color,
              fontSize: rank.length > 1 ? 17 : 22,
              fontWeight: FontWeight.w800,
              height: 1,
              letterSpacing: rank.length > 1 ? -1.5 : 0,
            ),
          ),
          const SizedBox(height: 3),
          SuitGlyph(suit: suit, size: 14, color: color),
        ],
      ),
    );
  }
}

/// Trim rule with the city emblem in the middle.
class _OrnamentDivider extends StatelessWidget {
  const _OrnamentDivider({required this.style});

  final PotCardStyle style;

  @override
  Widget build(BuildContext context) {
    final line = Expanded(child: Container(height: 1.2, color: style.trim));
    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: CustomPaint(
            size: const Size.square(18),
            painter: PotEmblemPainter(style),
          ),
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

/// Poker chips, one per pot tier, shown like carousel dots: a window of
/// [_ChipRail.visible] chips follows the selection, the chip just past each
/// edge peeks in small and faded, and the rest are hidden. The selected chip
/// lifts off the felt.
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

  static const visible = 5;
  static const _slot = 60.0;

  /// Room at each end for the peeking neighbour.
  static const _peek = 26.0;
  static const _duration = Duration(milliseconds: 260);

  @override
  Widget build(BuildContext context) {
    final shown = math.min(visible, options.length);
    // Keep the selection centred, but never scroll past either end.
    final first = (selected - shown ~/ 2).clamp(0, options.length - shown);
    final width = shown * _slot + 2 * _peek;

    return SizedBox(
      height: 70,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: width,
          height: 70,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i < options.length; i++)
                _chipAt(i, i - first, shown),
            ],
          ),
        ),
      ),
    );
  }

  /// Chip [i] at [slot] positions from the window's first chip.
  Widget _chipAt(int i, int slot, int shown) {
    final inWindow = slot >= 0 && slot < shown;
    // Distance past the window edge: 1 = peeking neighbour, 2+ = hidden.
    final beyond = slot < 0 ? -slot : slot - shown + 1;
    final double center =
        inWindow
            ? _peek + (slot + 0.5) * _slot
            : slot < 0
            ? _peek + (slot + 0.5) * _slot * 0.45
            : _peek + shown * _slot + (beyond - 0.5) * _slot * 0.45;
    final affordable = options[i].canAfford(
      money: playerMoney,
      chips: playerChips,
    );
    final double opacity =
        inWindow
            ? (affordable ? 1 : 0.45)
            : beyond == 1
            ? 0.35
            : 0;

    return AnimatedPositioned(
      key: ValueKey(options[i].id),
      duration: _duration,
      curve: Curves.easeOutCubic,
      left: center - _slot / 2,
      top: 0,
      width: _slot,
      height: 70,
      child: IgnorePointer(
        ignoring: opacity == 0,
        child: Center(
          child: Pressable(
            onTap: () => onTap(i),
            child: AnimatedScale(
              duration: _duration,
              curve: Curves.easeOutCubic,
              scale: inWindow ? 1 : 0.5,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                offset: Offset(0, i == selected ? -0.18 : 0.06),
                child: AnimatedOpacity(
                  duration: _duration,
                  opacity: opacity,
                  // Own layer: Impeller can't fold opacity into the chip's
                  // shadows/text ops (SetInheritedOpacity validation error).
                  child: RepaintBoundary(
                    child: _PokerChip(
                      value: options[i].pool,
                      color: _tierChipColors[i % _tierChipColors.length],
                      selected: i == selected,
                    ),
                  ),
                ),
              ),
            ),
          ),
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
