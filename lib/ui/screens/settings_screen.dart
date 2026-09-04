import 'dart:async';
import 'package:cardgame/app/auth_providers.dart';
import 'package:cardgame/app/locale_provider.dart';
import 'package:cardgame/app/player_profile_repository.dart';
import 'package:cardgame/app/session_auth_status.dart';
import 'package:cardgame/core/monetization/purchases_config.dart';
import 'package:cardgame/core/monetization/purchases_providers.dart';
import 'package:cardgame/core/monetization/purchases_service.dart';
import 'package:cardgame/data/profile/profile_api.dart';
import 'package:cardgame/l10n/l10n_ext.dart';
import 'package:cardgame/data/decks/deck_catalog.dart';
import 'package:cardgame/ui/screens/deck_preview_screen.dart';
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

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final profile =
        ref.watch(playerProfileProvider).value ?? PlayerProfile.empty;
    final authStatus = ref.watch(sessionAuthProvider).value;
    final isPro = ref.watch(isProProvider);

    return Scaffold(
      backgroundColor: CasinoColors.bg,
      appBar: AppBar(
        backgroundColor: CasinoColors.surface,
        foregroundColor: CasinoColors.text,
        title: Text(
          l10n.settings,
          style: const TextStyle(
            color: CasinoColors.gold,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          _ProfileCard(
            profile: profile,
            authStatus: authStatus,
            onEdit: () => showEditProfileDialog(context, profile),
          ),
          const SizedBox(height: 16),
          _ProCard(isPro: isPro),
          const SizedBox(height: 16),
          _SettingsTile(
            icon: Icons.menu_book_rounded,
            label: l10n.howToPlay,
            onTap:
                () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const HowToPlayScreen(),
                  ),
                ),
          ),
          const SizedBox(height: 10),
          _SettingsTile(
            icon: Icons.style_rounded,
            label: l10n.deck,
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
          const SizedBox(height: 10),
          const _LanguageCard(),
          const SizedBox(height: 10),
          _SettingsTile(
            icon: Icons.restore_rounded,
            label: 'Restore Purchases',
            onTap: () async {
              try {
                final info = await PurchasesService.instance.restorePurchases();
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
          const SizedBox(height: 10),
          _SettingsTile(
            icon: Icons.logout_rounded,
            label: l10n.signOut,
            destructive: true,
            onTap: () async {
              await ref.read(sessionAuthProvider.notifier).signOut();
              if (context.mounted) Navigator.of(context).pop();
            },
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
    final authLabel = switch (authStatus) {
      SessionAuthStatus.guest => l10n.guest,
      SessionAuthStatus.google => l10n.google,
      _ => l10n.guest,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CasinoColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CasinoColors.surfaceHi),
      ),
      child: Row(
        children: [
          PlayerAvatar(avatarId: profile.avatarId, size: 52),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        profile.name.isEmpty ? l10n.player : profile.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: CasinoColors.text,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: CasinoColors.bgElevated,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        authLabel,
                        style: const TextStyle(
                          color: CasinoColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '@${profile.username}',
                  style: const TextStyle(
                    color: CasinoColors.goldSoft,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: l10n.editProfile,
            onPressed: onEdit,
            icon: const Icon(
              Icons.edit_rounded,
              color: CasinoColors.gold,
              size: 20,
            ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
        CasinoActionButton(
          label: l10n.save,
          tone: CasinoActionTone.raise,
          expanded: false,
          height: 40,
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
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2A2006), Color(0xFF1C1605)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: CasinoColors.gold.withValues(alpha: 0.6)),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.workspace_premium_rounded,
              color: CasinoColors.gold,
              size: 32,
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ShadowHand PRO',
                    style: TextStyle(
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CasinoColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CasinoColors.gold.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: CasinoColors.gold.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.star_rounded,
                color: CasinoColors.gold,
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upgrade to PRO',
                  style: TextStyle(
                    color: CasinoColors.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Ad-free play & exclusive perks',
                  style: TextStyle(color: CasinoColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _upgradeToPro,
            style: ElevatedButton.styleFrom(
              backgroundColor: CasinoColors.gold,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child:
                _isLoading
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                    : const Text(
                      'PRO',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}

class _LanguageCard extends ConsumerWidget {
  const _LanguageCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final current = LanguageSwitcher.optionFor(
      ref.watch(localeProvider).languageCode,
    );
    return Material(
      color: CasinoColors.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => LanguageSwitcher.openPicker(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: CasinoColors.surfaceHi),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: SvgPicture.asset(
                  current.flagAsset,
                  width: 28,
                  height: 20,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.language,
                      style: const TextStyle(
                        color: CasinoColors.text,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      current.name,
                      style: const TextStyle(
                        color: CasinoColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.public_rounded,
                color: CasinoColors.goldSoft,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? CasinoColors.foldHi : CasinoColors.text;
    final iconColor = destructive ? CasinoColors.foldHi : CasinoColors.goldSoft;
    return Material(
      color: CasinoColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: CasinoColors.surfaceHi),
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: CasinoColors.textMuted.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
