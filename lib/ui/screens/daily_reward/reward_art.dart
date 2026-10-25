import 'dart:math' as math;

import 'package:cardgame/data/avatars/avatar_catalog.dart';
import 'package:cardgame/data/daily_reward/daily_reward_models.dart';
import 'package:cardgame/data/decks/deck_catalog.dart';
import 'package:cardgame/l10n/l10n_ext.dart';
import 'package:cardgame/ui/theme/app_icons.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/theme/game_icon.dart';
import 'package:cardgame/ui/widgets/amount_format.dart';
import 'package:cardgame/ui/widgets/boost_badge.dart';
import 'package:cardgame/ui/widgets/currency_icon.dart';
import 'package:cardgame/ui/widgets/deck_fan_preview.dart';
import 'package:cardgame/ui/widgets/player_avatar.dart';
import 'package:flutter/material.dart';

/// The picture for one reward, drawn to fit a [size] square. Everything is
/// code-drawn like the rest of the table: coins, chips, the player's avatars
/// and card backs, a boost medallion, a freeze gem and a treasure chest.
class RewardArt extends StatelessWidget {
  const RewardArt({
    super.key,
    required this.reward,
    this.size = 40,
    this.chestOpen = 0,
  });

  final RewardItem reward;
  final double size;

  /// A chest's lid, 0 shut to 1 thrown open.
  final double chestOpen;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: switch (reward) {
        CurrencyReward(:final currency, :final amount) => CoinStack(
          currency: currency,
          amount: amount,
          size: size,
        ),
        AvatarReward(:final itemId) => Center(
          child: PlayerAvatar(
            avatarId: itemId,
            size: size * 0.92,
            borderWidth: math.max(1.5, size * 0.04),
            borderColor: CasinoColors.gold,
            showGlow: true,
          ),
        ),
        DeckReward(:final itemId) => _DeckArt(deckId: itemId, size: size),
        CoinBoostReward(:final preset?) => Center(
          child: BoostCoin(tier: preset.tier, size: size * 0.86),
        ),
        CoinBoostReward() => const CustomPaint(painter: _BoostPainter()),
        StreakFreezeReward() => const CustomPaint(painter: _FreezeGemPainter()),
        ChestReward() => CustomPaint(painter: ChestPainter(open: chestOpen)),
        UnknownReward() => _GiftMedallion(size: size),
      },
    );
  }
}

/// A small pile of coins or chips; bigger amounts stack higher.
class CoinStack extends StatelessWidget {
  const CoinStack({
    super.key,
    required this.currency,
    required this.amount,
    required this.size,
  });

  final CurrencyType currency;
  final int amount;
  final double size;

  int get _count => switch (currency) {
    CurrencyType.money => amount >= 300 ? 3 : (amount >= 100 ? 2 : 1),
    CurrencyType.chips => amount >= 3 ? 3 : amount,
  };

  @override
  Widget build(BuildContext context) {
    final coin = size * 0.66;
    final count = _count.clamp(1, 3);
    // Bottom-left, bottom-right, then one on top: a little pile.
    final spots = <Offset>[
      Offset(0, size - coin),
      Offset(size - coin, size - coin),
      Offset((size - coin) / 2, size - coin - coin * 0.42),
    ];
    if (count == 1) {
      return Center(child: CurrencyIcon(currency: currency, size: coin * 1.2));
    }
    return Stack(
      children: [
        for (var i = 0; i < count; i++)
          Positioned(
            left: count == 2 && i == 1 ? spots[2].dx : spots[i].dx,
            top: count == 2 && i == 1 ? spots[2].dy + coin * 0.2 : spots[i].dy,
            child: CurrencyIcon(currency: currency, size: coin),
          ),
      ],
    );
  }
}

/// Two of the deck's own card backs, fanned, glowing in the deck's rarity.
class _DeckArt extends StatelessWidget {
  const _DeckArt({required this.deckId, required this.size});

  final String deckId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final deck = DeckCatalog.getById(deckId);
    final glow = deckRarityColor(deck.rarity) ?? CasinoColors.gold;
    final height = size * 0.96;
    final width = height * 78 / 112;
    Widget back(double angle, Offset shift) => Transform.translate(
      offset: shift,
      child: Transform.rotate(
        angle: angle,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(width * 0.1),
            boxShadow: [
              BoxShadow(
                color: glow.withValues(alpha: 0.55),
                blurRadius: size * 0.18,
              ),
              const BoxShadow(
                color: Color(0x66000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: DeckBackPreview(skinId: deck.skinId),
        ),
      ),
    );
    return Stack(
      alignment: Alignment.center,
      children: [
        back(-0.2, Offset(-size * 0.1, 0)),
        back(0.12, Offset(size * 0.1, -size * 0.02)),
      ],
    );
  }
}

/// Gold medallion with a lightning bolt: the Coin Boost.
class _BoostPainter extends CustomPainter {
  const _BoostPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final c = size.center(Offset.zero);
    final r = s * 0.46;
    final disc = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c + Offset(0, s * 0.03),
      r,
      Paint()..color = const Color(0xFF7A3E06),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF1B0), Color(0xFFFFB627), Color(0xFFE0690B)],
        ).createShader(disc),
    );
    canvas.drawCircle(
      c,
      r * 0.8,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.4),
          colors: [Color(0xFFFFE38A), Color(0xFFF7941D)],
        ).createShader(disc),
    );
    canvas.drawCircle(
      c,
      r * 0.8,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.8, r * 0.07)
        ..color = const Color(0xFFB85A07),
    );
    // Bolt, traced in a unit square and centred on the disc.
    final bolt =
        Path()
          ..moveTo(0.58, 0.08)
          ..lineTo(0.27, 0.56)
          ..lineTo(0.47, 0.56)
          ..lineTo(0.39, 0.92)
          ..lineTo(0.74, 0.42)
          ..lineTo(0.54, 0.42)
          ..lineTo(0.64, 0.08)
          ..close();
    final box = r * 1.15;
    canvas.save();
    canvas.translate(c.dx - box / 2, c.dy - box / 2);
    canvas.scale(box);
    canvas.drawPath(
      bolt.shift(const Offset(0.02, 0.03)),
      Paint()..color = const Color(0x55000000),
    );
    canvas.drawPath(bolt, Paint()..color = Colors.white);
    canvas.drawPath(
      bolt,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.035
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFFB85A07),
    );
    canvas.restore();
    // Shine on the rim.
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r * 0.9),
      math.pi * 1.1,
      math.pi * 0.35,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(0.8, r * 0.08)
        ..color = Colors.white.withValues(alpha: 0.75),
    );
  }

  @override
  bool shouldRepaint(covariant _BoostPainter oldDelegate) => false;
}

/// Faceted ice-blue gem holding a snowflake: the Streak Freeze.
class _FreezeGemPainter extends CustomPainter {
  const _FreezeGemPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final c = size.center(Offset.zero);
    final r = s * 0.47;
    final hex = Path();
    for (var i = 0; i < 6; i++) {
      final a = -math.pi / 2 + i * math.pi / 3;
      final p = c + Offset(math.cos(a) * r, math.sin(a) * r);
      if (i == 0) {
        hex.moveTo(p.dx, p.dy);
      } else {
        hex.lineTo(p.dx, p.dy);
      }
    }
    hex.close();
    final bounds = hex.getBounds();
    canvas.drawPath(
      hex.shift(Offset(0, s * 0.03)),
      Paint()..color = const Color(0xFF0B3A6E),
    );
    canvas.drawPath(
      hex,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE9FBFF), Color(0xFF7FD6FF), Color(0xFF2B7BD9)],
          stops: [0, 0.45, 1],
        ).createShader(bounds),
    );
    // Facets: lines from the centre to every other corner.
    final facet =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(0.6, r * 0.03)
          ..color = Colors.white.withValues(alpha: 0.35);
    for (var i = 0; i < 6; i += 2) {
      final a = -math.pi / 2 + i * math.pi / 3;
      canvas.drawLine(c, c + Offset(math.cos(a) * r, math.sin(a) * r), facet);
    }
    canvas.drawPath(
      hex,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.8, r * 0.06)
        ..color = Colors.white.withValues(alpha: 0.85),
    );
    // Snowflake: six spokes with a pair of branches each.
    final flake =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = math.max(1, r * 0.08)
          ..color = Colors.white;
    final arm = r * 0.55;
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3;
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(c, c + dir * arm, flake);
      final mid = c + dir * arm * 0.6;
      for (final turn in [-0.7, 0.7]) {
        final b = Offset(math.cos(a + turn), math.sin(a + turn));
        canvas.drawLine(mid, mid + b * arm * 0.32, flake);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FreezeGemPainter oldDelegate) => false;
}

/// Wooden treasure chest with gold bands. [open] lifts the lid and lets the
/// gold light out.
class ChestPainter extends CustomPainter {
  const ChestPainter({this.open = 0});

  final double open;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final left = (size.width - s) / 2 + s * 0.08;
    final width = s * 0.84;
    final bodyTop = size.height / 2 - s * 0.02 + s * 0.08;
    final bodyBottom = size.height / 2 + s * 0.4;
    final body = RRect.fromLTRBR(
      left,
      bodyTop,
      left + width,
      bodyBottom,
      Radius.circular(s * 0.06),
    );

    const wood = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFA8693A), Color(0xFF6E4024), Color(0xFF4A2A17)],
    );
    const goldBand = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFEAA0), Color(0xFFF5C542), Color(0xFFB8860B)],
    );

    // Light escaping the open chest, behind the lid.
    if (open > 0) {
      final glowCentre = Offset(size.width / 2, bodyTop);
      canvas.drawCircle(
        glowCentre,
        s * (0.35 + 0.25 * open),
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFFFF4C2).withValues(alpha: 0.95 * open),
              const Color(0xFFF5C542).withValues(alpha: 0.4 * open),
              const Color(0xFFF5C542).withValues(alpha: 0),
            ],
            stops: const [0, 0.45, 1],
          ).createShader(Rect.fromCircle(center: glowCentre, radius: s * 0.6)),
      );
    }

    // Shadow under the chest.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, bodyBottom + s * 0.03),
        width: width * 0.9,
        height: s * 0.08,
      ),
      Paint()..color = const Color(0x55000000),
    );
    canvas.drawRRect(body, Paint()..shader = wood.createShader(body.outerRect));
    // Planks.
    final plank =
        Paint()
          ..strokeWidth = math.max(0.6, s * 0.012)
          ..color = const Color(0x33000000);
    for (final f in [0.38, 0.68]) {
      final y = bodyTop + (bodyBottom - bodyTop) * f;
      canvas.drawLine(
        Offset(left + s * 0.04, y),
        Offset(left + width - s * 0.04, y),
        plank,
      );
    }
    // Gold bands down the sides and along the top edge.
    final bandWidth = s * 0.09;
    for (final x in [left + width * 0.18, left + width * 0.82 - bandWidth]) {
      final band = Rect.fromLTWH(x, bodyTop, bandWidth, bodyBottom - bodyTop);
      canvas.drawRect(band, Paint()..shader = goldBand.createShader(band));
    }
    final rim = Rect.fromLTWH(left, bodyTop, width, s * 0.06);
    canvas.drawRect(rim, Paint()..shader = goldBand.createShader(rim));

    // Lid: an arched top hinged at the back, tipping up as it opens.
    final lidHeight = s * 0.3;
    final lidRect = Rect.fromLTWH(
      left,
      bodyTop - lidHeight,
      width,
      lidHeight + s * 0.02,
    );
    canvas.save();
    final hinge = Offset(size.width / 2, bodyTop - lidHeight * 0.1);
    canvas.translate(hinge.dx, hinge.dy - s * 0.12 * open);
    canvas.rotate(-0.5 * open);
    canvas.translate(-hinge.dx, -hinge.dy);
    final lid =
        Path()
          ..moveTo(lidRect.left, lidRect.bottom)
          ..lineTo(lidRect.left, lidRect.top + lidHeight * 0.45)
          ..quadraticBezierTo(
            lidRect.left,
            lidRect.top,
            lidRect.center.dx,
            lidRect.top,
          )
          ..quadraticBezierTo(
            lidRect.right,
            lidRect.top,
            lidRect.right,
            lidRect.top + lidHeight * 0.45,
          )
          ..lineTo(lidRect.right, lidRect.bottom)
          ..close();
    canvas.drawPath(lid, Paint()..shader = wood.createShader(lidRect));
    for (final x in [left + width * 0.18, left + width * 0.82 - bandWidth]) {
      final band = Rect.fromLTWH(x, lidRect.top, bandWidth, lidRect.height);
      canvas.save();
      canvas.clipPath(lid);
      canvas.drawRect(band, Paint()..shader = goldBand.createShader(band));
      canvas.restore();
    }
    canvas.drawPath(
      lid,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.8, s * 0.02)
        ..color = const Color(0xFF3A2010),
    );
    canvas.restore();

    // Lock plate with a keyhole, over the seam.
    final plate = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, bodyTop + s * 0.07),
        width: s * 0.17,
        height: s * 0.2,
      ),
      Radius.circular(s * 0.03),
    );
    canvas.drawRRect(
      plate,
      Paint()..shader = goldBand.createShader(plate.outerRect),
    );
    canvas.drawCircle(
      plate.center.translate(0, -s * 0.02),
      s * 0.025,
      Paint()..color = const Color(0xFF3A2010),
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: plate.center.translate(0, s * 0.03),
        width: s * 0.016,
        height: s * 0.06,
      ),
      Paint()..color = const Color(0xFF3A2010),
    );
    canvas.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.8, s * 0.02)
        ..color = const Color(0xFF3A2010),
    );
  }

  @override
  bool shouldRepaint(covariant ChestPainter oldDelegate) =>
      oldDelegate.open != open;
}

class _GiftMedallion extends StatelessWidget {
  const _GiftMedallion({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: size * 0.9,
        height: size * 0.9,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              CasinoColors.goldHi,
              CasinoColors.gold,
              CasinoColors.goldLo,
            ],
          ),
          border: Border.all(color: const Color(0xFF7A5A0E)),
        ),
        child: Center(
          child: GameIcon(
            icon: AppIcons.gift,
            size: size * 0.5,
            color: const Color(0xFF4A3708),
          ),
        ),
      ),
    );
  }
}

/// "1h", "4h", "1h 30m", "45m".
String boostDuration(int minutes) {
  if (minutes < 60) return '${minutes}m';
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  return rest == 0 ? '${hours}h' : '${hours}h ${rest}m';
}

bool _knownAvatar(String id) =>
    AvatarCatalog.all.any((avatar) => avatar.id == id);

bool _knownDeck(String id) => DeckCatalog.all.any((deck) => deck.id == id);

/// A chest's name in the player's language, from the admin's titles.
String chestName(
  AppLocalizations l10n,
  String chestId,
  Map<String, DailyChest> chests,
  String languageCode,
) =>
    localizedTitle(chests[chestId]?.titles ?? const {}, languageCode) ??
    l10n.dailyMysteryChest;

/// Short caption under a reward on a day card: "200", "Sapphire Dragon",
/// "4h", "×1".
String rewardCaption(
  AppLocalizations l10n,
  RewardItem reward, {
  Map<String, DailyChest> chests = const {},
  String languageCode = 'en',
}) {
  return switch (reward) {
    CurrencyReward(:final amount) => compactAmount(amount),
    AvatarReward(:final itemId) =>
      _knownAvatar(itemId)
          ? l10n.avatarName(AvatarCatalog.getById(itemId))
          : l10n.dailyMysteryGift,
    DeckReward(:final itemId) =>
      _knownDeck(itemId)
          ? l10n.deckName(DeckCatalog.getById(itemId))
          : l10n.dailyMysteryGift,
    CoinBoostReward(:final minutes, :final preset?) =>
      '+${preset.percent}% · ${boostDuration(minutes)}',
    CoinBoostReward(:final minutes) => boostDuration(minutes),
    StreakFreezeReward(:final quantity) => '×$quantity',
    ChestReward(:final chestId) => chestName(
      l10n,
      chestId,
      chests,
      languageCode,
    ),
    UnknownReward() => l10n.dailyMysteryGift,
  };
}

/// Full name of a reward for the reveal and for screen readers.
String rewardTitle(
  AppLocalizations l10n,
  RewardItem reward, {
  Map<String, DailyChest> chests = const {},
  String languageCode = 'en',
}) {
  return switch (reward) {
    CurrencyReward(:final currency, :final amount) =>
      '${groupedAmount(amount)} ${currency == CurrencyType.chips ? l10n.chips : l10n.money}',
    CoinBoostReward(:final minutes, :final preset) =>
      '${preset?.nameFor(languageCode) ?? l10n.dailyCoinBoost}${preset == null ? '' : ' +${preset.percent}%'} · ${boostDuration(minutes)}',
    StreakFreezeReward(:final quantity) =>
      '${l10n.dailyStreakFreeze} ×$quantity',
    _ => rewardCaption(
      l10n,
      reward,
      chests: chests,
      languageCode: languageCode,
    ),
  };
}
