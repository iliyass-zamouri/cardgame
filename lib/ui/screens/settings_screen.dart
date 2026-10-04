import 'dart:async';
import 'package:cardgame/app/auth_providers.dart';
import 'package:cardgame/app/locale_provider.dart';
import 'package:cardgame/app/player_profile_repository.dart';
import 'package:cardgame/app/push_providers.dart';
import 'package:cardgame/app/session_auth_status.dart';
import 'package:cardgame/core/monetization/purchases_config.dart';
import 'package:cardgame/core/monetization/purchases_providers.dart';
import 'package:cardgame/core/monetization/purchases_service.dart';
import 'package:cardgame/data/auth/guest_google_link.dart';
import 'package:cardgame/data/auth/legal_urls.dart';
import 'package:cardgame/data/profile/profile_api.dart';
import 'package:cardgame/l10n/l10n_ext.dart';
import 'package:cardgame/data/decks/deck_catalog.dart';
import 'package:cardgame/services/push_notification_api_service.dart';
import 'package:cardgame/ui/screens/auth/auth_provider_buttons.dart';
import 'package:cardgame/ui/screens/deck_preview_screen.dart';
import 'package:cardgame/ui/flame/suit_shapes.dart';
import 'package:cardgame/ui/screens/how_to_play_screen.dart';
import 'package:cardgame/ui/theme/casino_chrome.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/widgets/language_switcher.dart';
import 'package:cardgame/ui/widgets/player_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:cardgame/ui/theme/app_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cardgame/ui/theme/felt_chrome.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _linkingGoogle = false;
  bool _deletingAccount = false;

  Future<void> _launchLegalUrl(String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      CasinoToast.show(context, 'Could not open link', success: false);
    }
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    if (_deletingAccount) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: CasinoColors.surface,
            shape: feltDialogShape,
            title: const Text(
              'Delete Account',
              style: TextStyle(
                color: CasinoColors.text,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: const Text(
              'This permanently deletes your account and progress. This cannot be undone.',
              style: TextStyle(color: CasinoColors.textMuted),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: CasinoColors.textMuted),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: CasinoColors.foldHi),
                ),
              ),
            ],
          ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deletingAccount = true);
    try {
      final profile =
          ref.read(playerProfileProvider).value ?? PlayerProfile.empty;
      if (profile.playerId.isNotEmpty) {
        await ref
            .read(profileApiServiceProvider)
            .deleteAccount(
              playerId: profile.playerId,
              accessToken: profile.accessToken,
            );
      }
      await ref.read(sessionAuthProvider.notifier).signOut();
      if (!mounted) return;
      Navigator.of(this.context).pop();
    } catch (e) {
      if (!mounted) return;
      CasinoToast.show(this.context, 'Delete failed: $e', success: false);
    } finally {
      if (mounted) setState(() => _deletingAccount = false);
    }
  }

  Future<void> _linkGoogle() async {
    if (_linkingGoogle) return;
    setState(() => _linkingGoogle = true);
    final l10n = context.l10n;
    try {
      final result = await linkOrSignInWithGoogle(context: context, ref: ref);
      if (!mounted) return;
      if (result.outcome == GuestGoogleLinkOutcome.linked) {
        CasinoToast.show(context, l10n.linkGoogleSuccess);
      } else if (result.outcome == GuestGoogleLinkOutcome.switched) {
        CasinoToast.show(context, l10n.linkGoogleSwitched);
      } else if (result.outcome == GuestGoogleLinkOutcome.failed &&
          result.errorMessage != null) {
        CasinoToast.show(context, result.errorMessage!, success: false);
      }
    } finally {
      if (mounted) setState(() => _linkingGoogle = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final profile =
        ref.watch(playerProfileProvider).value ?? PlayerProfile.empty;
    final authStatus = ref.watch(sessionAuthProvider).value;
    final isGuest = authStatus == SessionAuthStatus.guest;
    final isPro =
        PurchasesConfig.enableProUpgrade ? ref.watch(isProProvider) : false;

    return FeltScaffold(
      title: l10n.settings,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          _ProfileCard(
            profile: profile,
            authStatus: authStatus,
            onEdit: () => showEditProfileDialog(context, profile),
          ),
          if (isGuest) ...[
            const SizedBox(height: 12),
            AuthProviderButton.google(
              label:
                  _linkingGoogle ? l10n.linkingGoogle : l10n.linkGoogleAccount,
              onPressed: _linkingGoogle ? null : _linkGoogle,
            ),
          ],
          if (PurchasesConfig.enableProUpgrade) ...[
            const SizedBox(height: 14),
            _ProCard(isPro: isPro),
          ],
          const SizedBox(height: 20),
          FeltTileGroup(
            children: [
              FeltTile(
                icon: AppIcons.menuBook,
                title: l10n.howToPlay,
                onTap:
                    () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => const HowToPlayScreen(),
                      ),
                    ),
              ),
              FeltTile(
                icon: AppIcons.style,
                title: l10n.deck,
                onTap:
                    () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder:
                            (context) => DeckPreviewScreen(
                              backSkinId: DeckCatalog.skinIdFor(profile.deckId),
                            ),
                      ),
                    ),
              ),
              const _LanguageTile(),
            ],
          ),
          const SizedBox(height: 20),
          const _NotifyPrefsGroup(),
          const SizedBox(height: 20),
          FeltTileGroup(
            children: [
              FeltTile(
                icon: AppIcons.restore,
                title: 'Restore Purchases',
                onTap: () async {
                  try {
                    final info =
                        await PurchasesService.instance.restorePurchases();
                    await ref.read(customerInfoProvider.notifier).refresh();
                    if (context.mounted) {
                      final hasPro =
                          info
                              ?.entitlements
                              .all[PurchasesConfig.entitlementPro]
                              ?.isActive ??
                          false;
                      CasinoToast.show(
                        context,
                        hasPro
                            ? 'Purchases restored. PRO active!'
                            : 'Purchases restored.',
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      CasinoToast.show(
                        context,
                        'Restore failed: $e',
                        success: false,
                      );
                    }
                  }
                },
              ),
              FeltTile(
                icon: AppIcons.shield,
                title: 'Privacy Policy',
                onTap: () => _launchLegalUrl(PRIVACY_URL),
              ),
              FeltTile(
                icon: AppIcons.menuBook,
                title: 'Terms of Service',
                onTap: () => _launchLegalUrl(TOS_URL),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FeltTileGroup(
            children: [
              FeltTile(
                icon: AppIcons.logout,
                title: l10n.signOut,
                destructive: true,
                onTap: () async {
                  await ref.read(sessionAuthProvider.notifier).signOut();
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
              FeltTile(
                icon: AppIcons.removeCircle,
                title: 'Delete Account',
                destructive: true,
                onTap: () => _confirmDeleteAccount(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.authStatus,
    required this.onEdit,
  });

  final PlayerProfile profile;
  final SessionAuthStatus? authStatus;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final authLabel = switch (authStatus) {
      SessionAuthStatus.guest => l10n.guest,
      SessionAuthStatus.google => l10n.google,
      _ => l10n.guest,
    };

    return FeltPanel(
      highlighted: true,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          PlayerAvatar(
            avatarId: profile.avatarId,
            size: 58,
            borderWidth: 1.8,
            borderColor: CasinoColors.gold,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name.isEmpty ? l10n.player : profile.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: CasinoFonts.displayFor(locale),
                    color: CasinoColors.gold,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '@${profile.username}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: CasinoColors.goldSoft,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: CasinoColors.gold.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Text(
                        authLabel,
                        style: const TextStyle(
                          color: CasinoColors.goldSoft,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          FeltIconButton(
            icon: AppIcons.edit,
            tooltip: l10n.editProfile,
            onTap: onEdit,
          ),
        ],
      ),
    );
  }
}

Future<void> showEditProfileDialog(
  BuildContext context,
  PlayerProfile current,
) {
  return showDialog<void>(
    context: context,
    builder: (context) => _EditProfileDialog(current: current),
  );
}

class _EditProfileDialog extends ConsumerStatefulWidget {
  const _EditProfileDialog({required this.current});

  final PlayerProfile current;

  @override
  ConsumerState<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends ConsumerState<_EditProfileDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.current.name);
    _usernameController = TextEditingController(text: widget.current.username);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim().toLowerCase();
    final l10n = context.l10n;

    if (name.isEmpty) return;

    if (username.isEmpty || !RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(username)) {
      setState(() {
        _error = l10n.usernameInvalidFormat;
      });
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final usernameChanged = username != widget.current.username.toLowerCase();

      if (usernameChanged) {
        final profileApi = ref.read(profileApiServiceProvider);
        final check = await profileApi.checkUsername(
          username: username,
          playerId: widget.current.playerId,
          accessToken: widget.current.accessToken,
        );
        if (!check.available) {
          if (mounted) {
            setState(() {
              _saving = false;
              _error = l10n.usernameTaken;
            });
          }
          return;
        }
      }

      await ref
          .read(playerProfileProvider.notifier)
          .updateProfile(name: name, username: username);

      if (mounted) {
        Navigator.of(context).pop();
        CasinoToast.show(context, l10n.profileUpdated);
      }
    } on ProfileApiException catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.code == 'username_taken' ? l10n.usernameTaken : e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AlertDialog(
      backgroundColor: CasinoColors.surface,
      shape: feltDialogShape,
      title: Text(
        l10n.editProfile,
        style: const TextStyle(
          color: CasinoColors.text,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.displayName,
              style: const TextStyle(
                color: CasinoColors.goldSoft,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: CasinoColors.text),
              decoration: InputDecoration(
                fillColor: CasinoColors.bgElevated,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.changeUsername,
              style: const TextStyle(
                color: CasinoColors.goldSoft,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _usernameController,
              style: const TextStyle(color: CasinoColors.text),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
                _LowerCaseFormatter(),
              ],
              decoration: InputDecoration(
                prefixText: '@ ',
                prefixStyle: const TextStyle(color: CasinoColors.goldSoft),
                fillColor: CasinoColors.bgElevated,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: const TextStyle(
                  color: CasinoColors.foldHi,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            l10n.cancel,
            style: const TextStyle(color: CasinoColors.textMuted),
          ),
        ),
        GoldButton(
          label: l10n.save,
          compact: true,
          onPressed: _saving ? null : _save,
        ),
      ],
    );
  }
}

class _LowerCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toLowerCase());
  }
}

class _ProCard extends ConsumerStatefulWidget {
  const _ProCard({required this.isPro});

  final bool isPro;

  @override
  ConsumerState<_ProCard> createState() => _ProCardState();
}

class _ProCardState extends ConsumerState<_ProCard> {
  bool _isLoading = false;

  Future<void> _upgradeToPro() async {
    setState(() => _isLoading = true);
    try {
      final info = await PurchasesService.instance.purchaseProduct(
        PurchasesConfig.proMonthly,
      );
      if (info != null) {
        await ref.read(customerInfoProvider.notifier).refresh();
        if (mounted) {
          CasinoToast.show(context, 'Welcome to ShadowHand PRO!');
        }
      }
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code != PurchasesErrorCode.purchaseCancelledError) {
        if (mounted) {
          CasinoToast.show(
            context,
            e.message ?? 'Purchase failed',
            success: false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CasinoToast.show(context, 'Subscription failed: $e', success: false);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isPro) {
      return const FeltPanel(
        highlighted: true,
        child: Row(
          children: [
            FeltMedallion(icon: AppIcons.premium, color: CasinoColors.gold),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ShadowHand PRO',
                    style: TextStyle(
                      fontFamily: CasinoFonts.display,
                      color: CasinoColors.gold,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Active • Ad-free experience enabled',
                    style: TextStyle(
                      color: CasinoColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return IvoryCard(
      suit: SuitShape.diamonds,
      padding: const EdgeInsets.fromLTRB(26, 16, 18, 16),
      child: Row(
        children: [
          const HugeIcon(icon: AppIcons.premium, color: CardInk.red, size: 30),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upgrade to PRO',
                  style: TextStyle(
                    fontFamily: CasinoFonts.display,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Ad-free play & exclusive perks',
                  style: TextStyle(color: Color(0xFF5A4A2A), fontSize: 12),
                ),
              ],
            ),
          ),
          GoldButton(
            label: _isLoading ? '…' : 'PRO',
            compact: true,
            onPressed: _isLoading ? null : _upgradeToPro,
          ),
        ],
      ),
    );
  }
}

class _LanguageTile extends ConsumerWidget {
  const _LanguageTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final current = LanguageSwitcher.optionFor(
      ref.watch(localeProvider).languageCode,
    );
    return FeltTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.32),
          border: Border.all(
            color: CasinoColors.goldSoft.withValues(alpha: 0.45),
          ),
        ),
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SvgPicture.asset(
              current.flagAsset,
              width: 22,
              height: 15,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
      title: l10n.language,
      subtitle: current.name,
      onTap: () => LanguageSwitcher.openPicker(context),
    );
  }
}

class _NotifyPrefsGroup extends ConsumerWidget {
  const _NotifyPrefsGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPrefs = ref.watch(notifyPrefsProvider);
    final prefs = asyncPrefs.value ?? const NotifyPrefs.allOn();
    final notifier = ref.read(notifyPrefsProvider.notifier);

    FeltTile toggle(
      List<List<dynamic>> icon,
      String title,
      bool value,
      ValueChanged<bool> onChanged,
    ) {
      return FeltTile(
        icon: icon,
        title: title,
        onTap: () => onChanged(!value),
        trailing: Switch.adaptive(
          value: value,
          activeThumbColor: CasinoColors.gold,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          onChanged: onChanged,
        ),
      );
    }

    return FeltTileGroup(
      header: 'Notifications',
      suit: SuitShape.hearts,
      children: [
        toggle(
          AppIcons.mail,
          'Table invites',
          prefs.invites,
          notifier.setInvites,
        ),
        toggle(AppIcons.people, 'Friends', prefs.social, notifier.setSocial),
        toggle(
          AppIcons.trendingUp,
          'Ranking',
          prefs.ranking,
          notifier.setRanking,
        ),
        toggle(
          AppIcons.stars,
          'News & offers',
          prefs.marketing,
          notifier.setMarketing,
        ),
      ],
    );
  }
}
