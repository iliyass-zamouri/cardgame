import 'package:cardgame/app/auth_providers.dart';
import 'package:cardgame/app/player_profile_repository.dart';
import 'package:cardgame/data/avatars/avatar_catalog.dart';
import 'package:cardgame/data/marketplace/marketplace_api.dart';
import 'package:cardgame/l10n/app_localizations.dart';
import 'package:cardgame/ui/screens/marketplace_screen.dart';
import 'package:cardgame/ui/theme/casino_chrome.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/widgets/currency_icon.dart';
import 'package:cardgame/ui/widgets/player_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showAvatarSelectionModal(
  BuildContext context, {
  required String currentAvatarId,
  required int playerLevel,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder:
        (context) => AvatarSelectionModal(
          currentAvatarId: currentAvatarId,
          playerLevel: playerLevel,
        ),
  );
}

class AvatarSelectionModal extends ConsumerStatefulWidget {
  const AvatarSelectionModal({
    super.key,
    required this.currentAvatarId,
    required this.playerLevel,
  });

  final String currentAvatarId;
  final int playerLevel;

  @override
  ConsumerState<AvatarSelectionModal> createState() =>
      _AvatarSelectionModalState();
}

class _AvatarSelectionModalState extends ConsumerState<AvatarSelectionModal> {
  late String _selectedAvatarId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedAvatarId = widget.currentAvatarId;
  }

  String _getAvatarName(AvatarItem avatar, AppLocalizations l10n) {
    switch (avatar.nameKey) {
      case 'defaultAvatar':
        return l10n.defaultAvatar;
      case 'blueAvatar':
        return l10n.blueAvatar;
      case 'redAvatar':
        return l10n.redAvatar;
      case 'bronzeAvatar':
        return l10n.bronzeAvatar;
      case 'silverAvatar':
        return l10n.silverAvatar;
      case 'jokerGirlAvatar':
        return l10n.jokerGirlAvatar;
      case 'violetJokerGirlAvatar':
        return l10n.violetJokerGirlAvatar;
      case 'violetQueenAvatar':
        return l10n.violetQueenAvatar;
      case 'queenOfHeartAvatar':
        return l10n.queenOfHeartAvatar;
      case 'goldenKingAvatar':
        return l10n.goldenKingAvatar;
      case 'queenAvatar':
        return l10n.queenAvatar;
      case 'kingAvatar':
        return l10n.kingAvatar;
      default:
        return avatar.id;
    }
  }

  Future<void> _equipAvatar(AvatarItem avatar) async {
    if (_selectedAvatarId == avatar.id) return;

    setState(() {
      _selectedAvatarId = avatar.id;
      _isSaving = true;
    });

    try {
      await ref.read(playerProfileProvider.notifier).updateAvatar(avatar.id);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _promptBuyAvatar(
    AvatarItem avatar,
    PlayerProfile profile,
    AppLocalizations l10n,
  ) async {
    final avatarName = _getAvatarName(avatar, l10n);
    final canAfford =
        avatar.currency == CurrencyType.money
            ? profile.money >= avatar.price
            : profile.chips >= avatar.price;

    final result = await showDialog<bool>(
      context: context,
      builder:
          (dialogCtx) => AlertDialog(
            backgroundColor: CasinoColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: CasinoColors.gold, width: 1.5),
            ),
            title: Text(
              avatarName,
              style: const TextStyle(
                color: CasinoColors.gold,
                fontWeight: FontWeight.w800,
                fontFamily: CasinoFonts.display,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PlayerAvatar(avatarId: avatar.id, size: 72),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${l10n.price}: ',
                      style: const TextStyle(
                        color: CasinoColors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    CurrencyIcon(currency: avatar.currency, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${avatar.price}',
                      style: const TextStyle(
                        color: CasinoColors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(false),
                child: Text(
                  l10n.cancel,
                  style: const TextStyle(color: CasinoColors.textMuted),
                ),
              ),
              if (canAfford)
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CasinoColors.raise,
                    foregroundColor: CasinoColors.text,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${l10n.buy} (',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      CurrencyIcon(currency: avatar.currency, size: 14),
                      const SizedBox(width: 2),
                      Text(
                        '${avatar.price})',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                )
              else
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogCtx).pop(false);
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder:
                            (_) => const MarketplaceScreen(initialTabIndex: 0),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CasinoColors.check,
                    foregroundColor: CasinoColors.text,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    l10n.marketplace,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
            ],
          ),
    );

    if (result == true && mounted) {
      setState(() => _isSaving = true);
      try {
        await ref
            .read(playerProfileProvider.notifier)
            .buyItem(
              itemType: 'avatar',
              itemId: avatar.id,
              currency: avatar.currency.name,
              price: avatar.price,
            );
        await ref.read(playerProfileProvider.notifier).updateAvatar(avatar.id);
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSaving = false);
          CasinoToast.show(
            context,
            e is MarketplaceApiException ? e.message : l10n.purchaseFailed,
            success: false,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profile =
        ref.watch(playerProfileProvider).value ?? PlayerProfile.empty;
    final avatars = AvatarCatalog.all;

    return Container(
      decoration: const BoxDecoration(
        color: CasinoColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: CasinoColors.gold, width: 1.5)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.customizeAvatar,
                style: const TextStyle(
                  color: CasinoColors.gold,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  fontFamily: CasinoFonts.display,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: CasinoColors.textMuted,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Flexible(
            child: GridView.builder(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
                childAspectRatio: 0.78,
              ),
              itemCount: avatars.length,
              itemBuilder: (context, index) {
                final avatar = avatars[index];
                final isOwned = profile.ownsAvatar(avatar.id);
                final isEquipped = _selectedAvatarId == avatar.id;
                final avatarName = _getAvatarName(avatar, l10n);

                return _AvatarGridTile(
                  avatar: avatar,
                  name: avatarName,
                  isOwned: isOwned,
                  isEquipped: isEquipped,
                  onTap: () {
                    if (isOwned) {
                      _equipAvatar(avatar);
                    } else {
                      _promptBuyAvatar(avatar, profile, l10n);
                    }
                  },
                );
              },
            ),
          ),
          if (_isSaving) ...[
            const SizedBox(height: 12),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: CasinoColors.gold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AvatarGridTile extends StatelessWidget {
  const _AvatarGridTile({
    required this.avatar,
    required this.name,
    required this.isOwned,
    required this.isEquipped,
    required this.onTap,
  });

  final AvatarItem avatar;
  final String name;
  final bool isOwned;
  final bool isEquipped;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            color:
                isEquipped
                    ? CasinoColors.gold.withValues(alpha: 0.12)
                    : CasinoColors.bgElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  isEquipped
                      ? CasinoColors.gold
                      : isOwned
                      ? Colors.white12
                      : Colors.white10,
              width: isEquipped ? 2 : 1,
            ),
            boxShadow:
                isEquipped
                    ? [
                      const BoxShadow(
                        color: Color(0x33F5A623),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ]
                    : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: isOwned ? 1.0 : 0.45,
                    child: PlayerAvatar(avatarId: avatar.id, size: 56),
                  ),
                  if (!isOwned)
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black38,
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        color: Colors.white70,
                        size: 24,
                      ),
                    ),
                  if (isEquipped)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: CasinoColors.gold,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 12,
                          color: CasinoColors.bg,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:
                      isEquipped
                          ? CasinoColors.gold
                          : isOwned
                          ? CasinoColors.text
                          : CasinoColors.textMuted,
                  fontSize: 12,
                  fontWeight: isEquipped ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              if (isEquipped)
                Text(
                  l10n.equipped,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: CasinoColors.goldSoft,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                )
              else if (isOwned)
                Text(
                  l10n.equip,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: CasinoColors.raiseHi,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CurrencyIcon(currency: avatar.currency, size: 10),
                    const SizedBox(width: 2),
                    Text(
                      '${avatar.price}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: CasinoColors.goldSoft,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
