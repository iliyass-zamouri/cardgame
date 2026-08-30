import 'package:cardgame/data/avatars/avatar_catalog.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:flutter/material.dart';

class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({
    super.key,
    this.avatarId,
    this.size = 48,
    this.borderWidth = 0,
    this.borderColor,
    this.showGlow = false,
    this.glowColor = const Color(0x44F5A623),
    this.statusDotColor,
    this.showEditBadge = false,
    this.onTap,
  });

  final String? avatarId;
  final double size;
  final double borderWidth;
  final Color? borderColor;
  final bool showGlow;
  final Color glowColor;
  final Color? statusDotColor;
  final bool showEditBadge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final assetPath = AvatarCatalog.getAssetPath(avatarId);
    final dotSize = (size * 0.28).clamp(8.0, 16.0);

    Widget avatarCore = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: CasinoColors.bgElevated,
        border:
            borderWidth > 0 && borderColor != null
                ? Border.all(color: borderColor!, width: borderWidth)
                : null,
        boxShadow:
            showGlow
                ? [BoxShadow(color: glowColor, blurRadius: 12, spreadRadius: 1)]
                : null,
      ),
      child: ClipOval(
        child: Image.asset(
          assetPath,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Icon(
                Icons.person_rounded,
                size: size * 0.55,
                color: CasinoColors.goldSoft,
              ),
            );
          },
        ),
      ),
    );

    if (statusDotColor != null || showEditBadge) {
      avatarCore = Stack(
        clipBehavior: Clip.none,
        children: [
          avatarCore,
          if (statusDotColor != null)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusDotColor,
                  border: Border.all(
                    color: CasinoColors.surfaceHi,
                    width: (dotSize * 0.16).clamp(1.5, 2.5),
                  ),
                ),
              ),
            ),
          if (showEditBadge)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: CasinoColors.gold,
                  border: Border.all(color: CasinoColors.surface, width: 1.5),
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  size: 11,
                  color: CasinoColors.bg,
                ),
              ),
            ),
        ],
      );
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: avatarCore,
      );
    }

    return avatarCore;
  }
}
