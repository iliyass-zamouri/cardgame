import 'dart:math' as math;

import 'package:cardgame/data/decks/deck_catalog.dart';
import 'package:cardgame/l10n/l10n_ext.dart';
import 'package:cardgame/ui/theme/app_icons.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/widgets/deck_fan_preview.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// Collectible-style deck card: a frame in the deck's rarity colour, the
/// deck fanned under a spotlight, then name, blurb and an action (shop or
/// collection).
class DeckShowcaseCard extends StatelessWidget {
  const DeckShowcaseCard({
    super.key,
    required this.deck,
    required this.owned,
    required this.equipped,
    required this.action,
    required this.onPreview,
    this.locked = false,
  });

  final DeckItem deck;
  final bool owned;
  final bool equipped;
  final Widget action;
  final VoidCallback onPreview;

  /// Collection view of a deck not owned yet: dimmed art behind a lock.
  final bool locked;

  /// Standard decks get an antique-gold frame.
  static const _standardFrame = Color(0xFFB08A3E);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final rarityColor = deckRarityColor(deck.rarity);
    final frame = rarityColor ?? _standardFrame;
    final rarity = l10n.deckRarity(deck.rarity);

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(frame, Colors.white, 0.45)!,
            frame,
            Color.lerp(frame, Colors.black, 0.45)!,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: frame.withValues(alpha: equipped ? 0.55 : 0.3),
            blurRadius: equipped ? 18 : 12,
            spreadRadius: -2,
          ),
          const BoxShadow(
            color: Color(0x99000000),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF3A2416), CasinoColors.leatherDeep],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Showcase: tap to see every card of the deck.
              Expanded(
                child: GestureDetector(
                  onTap: onPreview,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: const Alignment(0, -0.1),
                            radius: 0.85,
                            colors: [
                              Color.lerp(const Color(0xFF2A8A59), frame, 0.25)!,
                              CasinoColors.feltDeep,
                              const Color(0xFF0A2618),
                            ],
                            stops: const [0, 0.6, 1],
                          ),
                        ),
                      ),
                      CustomPaint(painter: _RaysPainter(frame)),
                      Center(
                        child: FittedBox(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(8, 26, 8, 8),
                            child: Opacity(
                              opacity: locked ? 0.4 : 1,
                              child: DeckFanPreview(
                                skinId: deck.skinId,
                                cardWidth: 64,
                                count: 3,
                                spread: 20,
                                heightPadding: 10,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (rarity != null)
                        PositionedDirectional(
                          top: 8,
                          start: 8,
                          child: _RarityBadge(label: rarity, color: frame),
                        ),
                      PositionedDirectional(
                        top: 8,
                        end: 8,
                        child:
                            equipped
                                ? const _StatusDot(
                                  icon: AppIcons.check,
                                  color: CasinoColors.gold,
                                )
                                : owned
                                ? const _StatusDot(
                                  icon: AppIcons.checkCircle,
                                  color: Color(0xFF6FD08C),
                                )
                                : _StatusDot(
                                  icon:
                                      locked
                                          ? AppIcons.lock
                                          : AppIcons.visibility,
                                  color: CasinoColors.goldSoft,
                                ),
                      ),
                    ],
                  ),
                ),
              ),
              // Gold rule between showcase and details.
              Container(
                height: 1.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      frame.withValues(alpha: 0),
                      frame,
                      frame.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        casinoButtonLabel(l10n.deckName(deck), locale),
                        maxLines: 1,
                        style: TextStyle(
                          fontFamily: CasinoFonts.displayFor(locale),
                          color: CasinoColors.gold,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          letterSpacing: locale.languageCode == 'ar' ? 0 : 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    SizedBox(
                      height: 30,
                      child: Text(
                        l10n.deckDescription(deck),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: CasinoColors.textMuted,
                          fontWeight: FontWeight.w600,
                          fontSize: 10.5,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    action,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small round marker in the showcase corner: equipped, owned or preview.
class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.icon, required this.color});

  final List<List<dynamic>> icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.55),
        border: Border.all(color: color.withValues(alpha: 0.8)),
      ),
      child: HugeIcon(icon: icon, size: 14, color: color),
    );
  }
}

/// Soft spotlight rays fanning out from behind the deck.
class _RaysPainter extends CustomPainter {
  const _RaysPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height * 0.55);
    final radius = size.longestSide;
    const rays = 14;
    final paint =
        Paint()
          ..shader = RadialGradient(
            colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: centre, radius: radius * 0.7));
    for (var i = 0; i < rays; i++) {
      final start = i * 2 * math.pi / rays;
      final path =
          Path()
            ..moveTo(centre.dx, centre.dy)
            ..arcTo(
              Rect.fromCircle(center: centre, radius: radius),
              start,
              math.pi / rays,
              false,
            )
            ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RaysPainter old) => old.color != color;
}

/// Small gem-cut pill naming a deck's rarity.
class _RarityBadge extends StatelessWidget {
  const _RarityBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(color, Colors.white, 0.25)!, color],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const HugeIcon(
            icon: AppIcons.diamond,
            size: 12,
            color: Color(0xFF17171C),
          ),
          const SizedBox(width: 4),
          Text(
            casinoButtonLabel(label, locale),
            style: const TextStyle(
              color: Color(0xFF17171C),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
