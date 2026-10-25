import 'dart:async';

import 'package:cardgame/data/marketplace/marketplace_catalog.dart';
import 'package:cardgame/l10n/l10n_ext.dart';
import 'package:cardgame/ui/theme/app_icons.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/theme/felt_chrome.dart';
import 'package:cardgame/ui/theme/game_icon.dart';
import 'package:cardgame/ui/widgets/boost_badge.dart';
import 'package:flutter/material.dart';

/// "2d 4h" from a day out, "3:12:05" under it.
String shopTimeLeft(AppLocalizations l10n, Duration left) {
  final seconds = left.inSeconds < 0 ? 0 : left.inSeconds;
  if (seconds < 86400) return boostClock(seconds);
  return l10n.shopDaysHours(seconds ~/ 86400, seconds % 86400 ~/ 3600);
}

String shopBadgeLabel(AppLocalizations l10n, ShopBadge badge) =>
    switch (badge) {
      ShopBadge.isNew => l10n.shopBadgeNew,
      ShopBadge.hot => l10n.shopBadgeHot,
      ShopBadge.popular => l10n.shopBadgePopular,
      ShopBadge.bestValue => l10n.shopBadgeBestValue,
      ShopBadge.limited => l10n.shopBadgeLimited,
    };

GameIconData _badgeIcon(ShopBadge badge) => switch (badge) {
  ShopBadge.isNew => AppIcons.sparkles,
  ShopBadge.hot => AppIcons.fire,
  ShopBadge.popular => AppIcons.trophy,
  ShopBadge.bestValue => AppIcons.diamond,
  ShopBadge.limited => AppIcons.hourglass,
};

/// Rebuilds once a second while [until] is ahead, so countdowns tick.
class ShopTicker extends StatefulWidget {
  const ShopTicker({super.key, required this.until, required this.builder});

  final DateTime? until;
  final Widget Function(BuildContext context, DateTime now) builder;

  @override
  State<ShopTicker> createState() => _ShopTickerState();
}

class _ShopTickerState extends State<ShopTicker> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(ShopTicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.until != widget.until) _sync();
  }

  void _sync() {
    _timer?.cancel();
    _timer = null;
    final until = widget.until;
    if (until == null || !DateTime.now().isBefore(until)) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      if (!DateTime.now().isBefore(until)) _timer?.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, DateTime.now());
}

/// A small solid pill: an icon and a short label.
class ShopPill extends StatelessWidget {
  const ShopPill({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.ink = Colors.white,
  });

  final GameIconData icon;
  final String label;
  final Color color;
  final Color ink;

  static const _padStart = 5.0;
  static const _padEnd = 7.0;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: ink,
      fontSize: 9.5,
      fontWeight: FontWeight.w900,
      letterSpacing: 0.3,
      height: 1.1,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(
            text: label,
            style: DefaultTextStyle.of(context).style.merge(style),
          ),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          maxLines: 1,
        )..layout();
        // No room for the word: the icon alone still says Hot, New...
        final iconOnly =
            _padStart + 11 + 3 + painter.width + _padEnd > constraints.maxWidth;
        return Tooltip(
          message: iconOnly ? label : '',
          child: Container(
            padding:
                iconOnly
                    ? const EdgeInsets.all(3)
                    : const EdgeInsetsDirectional.fromSTEB(
                      _padStart,
                      3,
                      _padEnd,
                      3,
                    ),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(999),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x55000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GameIcon(icon: icon, size: 11, color: ink),
                if (!iconOnly) ...[
                  const SizedBox(width: 3),
                  Text(label, maxLines: 1, softWrap: false, style: style),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

const _saleRed = Color(0xFFD62F45);
const _saleRedDeep = Color(0xFF8E1426);
const _featuredInk = Color(0xFF3A2A06);

/// The red a card glows with while its sale runs.
const shopSaleGlow = Color(0xFFE5394F);

/// Featured and merchandising badge pills. Sales and bonuses have their own
/// bar ([ShopSaleBar], [ShopBonusBar]) next to the buy button.
class ShopPromoTags extends StatelessWidget {
  const ShopPromoTags({
    super.key,
    this.badge,
    this.featured = false,
    this.alignment = MainAxisAlignment.start,
  });

  final ShopBadge? badge;
  final bool featured;
  final MainAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pills = <Widget>[
      if (featured)
        ShopPill(
          icon: AppIcons.crown,
          label: l10n.shopFeatured.toUpperCase(),
          color: CasinoColors.gold,
          ink: _featuredInk,
        ),
      if (badge != null) ShopBadgePill(badge: badge!),
    ];
    if (pills.isEmpty) return const SizedBox.shrink();
    // One line, never wrapping over the art: pills shrink and ellipsize.
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: alignment,
      children: [
        for (final (i, pill) in pills.indexed) ...[
          if (i > 0) const SizedBox(width: 4),
          Flexible(child: pill),
        ],
      ],
    );
  }
}

/// One merchandising badge: Hot, New, Best value...
class ShopBadgePill extends StatelessWidget {
  const ShopBadgePill({super.key, required this.badge});

  final ShopBadge badge;

  @override
  Widget build(BuildContext context) {
    return ShopPill(
      icon: _badgeIcon(badge),
      label: shopBadgeLabel(context.l10n, badge).toUpperCase(),
      color: const Color(0xFF1F2A3A),
      ink: CasinoColors.goldSoft,
    );
  }
}

/// A red price-tag strip that sits on top of a buy button while a sale runs:
/// the discount, the normal price struck through, and the time left. Gone
/// once the sale ends.
class ShopSaleBar extends StatelessWidget {
  const ShopSaleBar({
    super.key,
    required this.price,
    required this.currencyIcon,
  });

  final ShopPrice price;
  final Widget currencyIcon;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ShopTicker(
      until: price.saleEndsAt,
      builder: (context, now) {
        if (!price.onSaleAt(now)) return const SizedBox.shrink();
        return _PromoStrip(
          lead: l10n.shopSaleOff(price.percentOff),
          struck: '${price.basePrice}',
          struckIcon: currencyIcon,
          timeLeft: shopTimeLeft(l10n, price.saleEndsAt!.difference(now)),
        );
      },
    );
  }
}

/// The store-pack twin of [ShopSaleBar]: the extra amount and time left.
class ShopBonusBar extends StatelessWidget {
  const ShopBonusBar({super.key, required this.pack});

  final IapPackOffer pack;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ShopTicker(
      until: pack.bonusEndsAt,
      builder: (context, now) {
        final bonus = pack.bonusAt(now);
        if (bonus == 0) return const SizedBox.shrink();
        return _PromoStrip(
          icon: AppIcons.gift,
          lead: l10n.shopPackBonus(bonus).toUpperCase(),
          timeLeft: shopTimeLeft(l10n, pack.bonusEndsAt!.difference(now)),
        );
      },
    );
  }
}

/// Red strip: a white lead tag, an optional struck price, the countdown at
/// the end. It measures itself: when the card is too narrow the struck
/// price goes first, then the whole strip scales down, so it never overflows.
class _PromoStrip extends StatelessWidget {
  const _PromoStrip({
    required this.lead,
    required this.timeLeft,
    this.icon,
    this.struck,
    this.struckIcon,
  });

  final String lead;
  final String timeLeft;
  final GameIconData? icon;
  final String? struck;
  final Widget? struckIcon;

  static const _height = 26.0;
  static const _pad = EdgeInsetsDirectional.fromSTEB(3, 3, 8, 3);
  static const _tagPad = 5.0;
  static const _gap = 6.0;
  static const _iconSize = 12.0;
  static const _text = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.w900,
    fontSize: 11.5,
    height: 1.1,
    fontFeatures: [FontFeature.tabularFigures()],
  );
  static final _struckStyle = TextStyle(
    color: Colors.white.withValues(alpha: 0.8),
    decoration: TextDecoration.lineThrough,
    decorationColor: Colors.white,
    decorationThickness: 2,
    fontSize: 11.5,
    fontWeight: FontWeight.w800,
    height: 1.1,
  );

  double _width(BuildContext context, String text, TextStyle style) {
    final painter = TextPainter(
      // Measure with the inherited font, as the Text will render.
      text: TextSpan(
        text: text,
        style: DefaultTextStyle.of(context).style.merge(style),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    return painter.width;
  }

  @override
  Widget build(BuildContext context) {
    final tag = Container(
      height: _height - 6,
      padding: const EdgeInsets.symmetric(horizontal: _tagPad),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            GameIcon(icon: icon!, size: _iconSize, color: _saleRedDeep),
            const SizedBox(width: 3),
          ],
          Text(lead, style: _text.copyWith(color: _saleRedDeep)),
        ],
      ),
    );
    Widget timer({required bool icon}) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon) ...[
          const GameIcon(
            icon: AppIcons.timer,
            size: _iconSize,
            color: Colors.white,
          ),
          const SizedBox(width: 2),
        ],
        Text(timeLeft, style: _text),
      ],
    );
    final struckPrice =
        struck == null
            ? null
            : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (struckIcon != null) ...[
                  struckIcon!,
                  const SizedBox(width: 3),
                ],
                Text(struck!, style: _struckStyle),
              ],
            );

    return Container(
      height: _height,
      padding: _pad,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_saleRed, _saleRedDeep],
        ),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFFF8A98), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tagWidth =
              _width(context, lead, _text) +
              _tagPad * 2 +
              (icon == null ? 0 : _iconSize + 3);
          final max = constraints.maxWidth;
          const timerIconWidth = _iconSize + 2;
          final timeWidth = _width(context, timeLeft, _text);
          final struckWidth =
              struck == null
                  ? 0.0
                  : _gap + 15 + _width(context, struck!, _struckStyle);
          // Tight cards give up the timer icon first, then the struck price.
          final bare = tagWidth + _gap + timeWidth;
          final withStruck = bare + struckWidth;
          final showStruck = struckPrice != null && withStruck <= max;
          final showTimerIcon =
              bare + timerIconWidth + (showStruck ? struckWidth : 0) <= max;
          final fits = bare <= max;
          final row = Row(
            mainAxisSize: fits ? MainAxisSize.max : MainAxisSize.min,
            children: [
              tag,
              if (showStruck) ...[const SizedBox(width: _gap), struckPrice],
              if (fits) const Spacer() else const SizedBox(width: _gap),
              timer(icon: showTimerIcon),
            ],
          );
          if (fits) return row;
          // Too narrow even without the struck price: scale it all down.
          return FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: row,
          );
        },
      ),
    );
  }
}

/// A soft red glow around a card while its sale runs.
class ShopSaleGlow extends StatelessWidget {
  const ShopSaleGlow({
    super.key,
    required this.price,
    required this.child,
    this.radius = 18,
  });

  final ShopPrice? price;
  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final sale = price;
    if (sale == null || sale.saleEndsAt == null) return child;
    return ShopTicker(
      until: sale.saleEndsAt,
      builder: (context, now) {
        if (!sale.onSaleAt(now)) return child;
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              BoxShadow(
                color: shopSaleGlow.withValues(alpha: 0.85),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: child,
        );
      },
    );
  }
}

/// The admin's promo banner across the top of the shop.
class ShopBannerCard extends StatelessWidget {
  const ShopBannerCard({super.key, required this.banner, this.onTap});

  final ShopBanner banner;
  final VoidCallback? onTap;

  static (Color, Color, Color) _colors(ShopBannerStyle style) =>
      switch (style) {
        ShopBannerStyle.gold => (
          const Color(0xFF4A3508),
          const Color(0xFF2A1D03),
          const Color(0xFFF5C542),
        ),
        ShopBannerStyle.ruby => (
          const Color(0xFF6E1324),
          const Color(0xFF3A0812),
          const Color(0xFFFFB3BE),
        ),
        ShopBannerStyle.emerald => (
          const Color(0xFF0E5A3A),
          const Color(0xFF05301E),
          const Color(0xFF8FEAC4),
        ),
        ShopBannerStyle.sapphire => (
          const Color(0xFF173E85),
          const Color(0xFF0A1F47),
          const Color(0xFFB7D0FF),
        ),
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final language = Localizations.localeOf(context).languageCode;
    final title = ShopBanner.pick(banner.title, language) ?? '';
    final subtitle = ShopBanner.pick(banner.subtitle, language);
    final (top, bottom, ink) = _colors(banner.style);
    final card = Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [top, bottom],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ink.withValues(alpha: 0.55), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          GameIcon(icon: AppIcons.sparkles, size: 22, color: ink),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: CasinoFonts.displayOf(context),
                    color: ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                if (subtitle != null && subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ink.withValues(alpha: 0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (banner.endsAt != null)
                  ShopTicker(
                    until: banner.endsAt,
                    builder:
                        (context, now) => Text(
                          l10n.shopEndsIn(
                            shopTimeLeft(l10n, banner.endsAt!.difference(now)),
                          ),
                          style: TextStyle(
                            color: ink.withValues(alpha: 0.75),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                  ),
              ],
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: ink.withValues(alpha: 0.5)),
              ),
              child: Text(
                casinoButtonLabel(
                  l10n.shopOpen,
                  Localizations.localeOf(context),
                ),
                style: TextStyle(
                  color: ink,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ],
        ],
      ),
    );
    return onTap == null ? card : Pressable(onTap: onTap!, child: card);
  }
}
