import 'package:cardgame/data/avatars/avatar_catalog.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:flutter/material.dart';
import 'package:cardgame/ui/theme/game_icon.dart';
import 'package:cardgame/ui/theme/app_icons.dart';

/// Decode widths for avatar art. A few fixed steps, rather than the exact
/// pixel size, so one avatar shown at several sizes shares cached images.
const _decodeSteps = [128, 256];

int? _decodeWidth(double size, double devicePixelRatio) {
  final pixels = size * devicePixelRatio;
  for (final step in _decodeSteps) {
    if (pixels <= step) return step;
  }
  // Large avatars decode at the source size.
  return null;
}

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
          // Sources are 512px; most avatars show at 30-60pt, so decoding
          // full size cost up to 16x the time and memory per avatar.
          cacheWidth: _decodeWidth(
            size,
            MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.0,
          ),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: GameIcon(
                icon: AppIcons.person,
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
                child: GameIcon(
                  icon: AppIcons.edit,
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
