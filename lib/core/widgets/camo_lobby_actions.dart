import 'package:flutter/material.dart';

import '../constants/camo_colors.dart';
import '../constants/camo_typography.dart';

class CamoLobbyFloatingBar extends StatelessWidget {
  const CamoLobbyFloatingBar({
    super.key,
    required this.onFriends,
    required this.onShop,
    required this.onPlay,
    this.centerLabel = 'PLAY',
  });

  final VoidCallback onFriends;
  final VoidCallback onShop;
  final VoidCallback onPlay;
  final String centerLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Row(
        children: [
          _FlatIcon(icon: Icons.group_rounded, onTap: onFriends),
          const SizedBox(width: 8),
          _ChestIcon(onTap: onShop),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: onPlay,
              child: Container(
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFFB74D), Color(0xFFFF9800)],
                  ),
                  borderRadius: BorderRadius.circular(21),
                  border: Border.all(color: const Color(0xFFE65100), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF9800).withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  centerLabel.toUpperCase(),
                  style: CamoTypography.labelCaps(CamoColors.white).copyWith(
                    fontSize: 12,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _RingIcon(icon: Icons.sports_esports_rounded, onTap: onPlay),
          const SizedBox(width: 8),
          _RingIcon(icon: Icons.settings_rounded, onTap: () {}),
        ],
      ),
    );
  }
}

class _FlatIcon extends StatelessWidget {
  const _FlatIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 32,
        height: 32,
        child: Icon(icon, color: CamoColors.white, size: 26),
      ),
    );
  }
}

class _ChestIcon extends StatelessWidget {
  const _ChestIcon({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: const SizedBox(
        width: 32,
        height: 32,
        child: Icon(Icons.redeem_rounded, color: CamoColors.secondary, size: 28),
      ),
    );
  }
}

class _RingIcon extends StatelessWidget {
  const _RingIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: CamoColors.white.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Icon(icon, color: CamoColors.white, size: 18),
      ),
    );
  }
}

class CamoModeCard extends StatelessWidget {
  const CamoModeCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.footerColor,
    required this.onTap,
    required this.illustration,
    this.subtitleColor,
    this.titleColor,
    this.height = 190,
  });

  final String title;
  final String subtitle;
  final Color color;
  final Color footerColor;
  final VoidCallback onTap;
  final Widget illustration;
  final Color? subtitleColor;
  final Color? titleColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          height: height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.lerp(color, Colors.white, 0.15)!,
                  color,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: CamoColors.white.withValues(alpha: 0.22),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
                      child: illustration,
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    color: footerColor,
                    child: Text(
                      title.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: CamoTypography.displaySm(
                        titleColor ?? subtitleColor ?? const Color(0xFF3D2200),
                      ).copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        height: 1,
                        shadows: titleColor == null || titleColor == CamoColors.white
                            ? [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  offset: const Offset(0, 1),
                                  blurRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CamoModeCardDice extends StatelessWidget {
  const CamoModeCardDice({super.key, this.colors, this.size = 22});

  final List<Color>? colors;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = colors ??
        [
          const Color(0xFFE53935),
          CamoColors.secondary,
          CamoColors.primaryContainer,
          CamoColors.tertiary,
        ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < palette.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Transform.rotate(
              angle: (i - 1.5) * 0.15,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: palette[i],
                  borderRadius: BorderRadius.circular(size * 0.22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.45),
                    width: 1.2,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: size * 0.2,
                    height: size * 0.2,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Large decorative number for quick-match card.
class CamoModeCardHeroNumber extends StatelessWidget {
  const CamoModeCardHeroNumber({super.key, required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: CamoTypography.gameTitle(CamoColors.purpleMid).copyWith(
            fontSize: 52,
            height: 1,
            shadows: const [
              Shadow(
                color: Color(0x33000000),
                offset: Offset(0, 2),
                blurRadius: 0,
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const CamoModeCardDice(size: 22),
      ],
    );
  }
}

/// Icon illustration for friends/private card.
class CamoModeCardIcons extends StatelessWidget {
  const CamoModeCardIcons({
    super.key,
    this.primary = Icons.person_rounded,
    this.secondary = Icons.favorite_rounded,
  });

  final IconData primary;
  final IconData secondary;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(secondary, size: 26, color: Colors.white.withValues(alpha: 0.9)),
        const SizedBox(height: 4),
        Icon(primary, size: 38, color: Colors.white.withValues(alpha: 0.88)),
        const SizedBox(height: 8),
        const CamoModeCardDice(
          size: 20,
          colors: [
            Color(0xFF1976D2),
            Color(0xFFE53935),
            CamoColors.secondary,
            CamoColors.tertiary,
          ],
        ),
      ],
    );
  }
}

/// Join-room card illustration.
class CamoModeCardJoinArt extends StatelessWidget {
  const CamoModeCardJoinArt({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.vpn_key_rounded,
          size: 40,
          color: const Color(0xFF455A64).withValues(alpha: 0.85),
        ),
        const SizedBox(height: 8),
        const CamoModeCardDice(
          size: 20,
          colors: [
            Color(0xFF78909C),
            Color(0xFFE53935),
            CamoColors.secondary,
            CamoColors.primaryContainer,
          ],
        ),
      ],
    );
  }
}
