import 'dart:async';

import 'package:cardgame/app/auth_providers.dart';
import 'package:cardgame/data/auth/apple_sign_in_service.dart';
import 'package:cardgame/data/auth/guest_auth_service.dart';
import 'package:cardgame/data/auth/legal_urls.dart';
import 'package:cardgame/data/auth/guest_google_link.dart';
import 'package:cardgame/data/auth/server_identity.dart';
import 'package:cardgame/l10n/l10n_ext.dart';
import 'package:cardgame/services/analytics_service.dart';
import 'package:cardgame/ui/flame/card_back_skins.dart';
import 'package:cardgame/ui/screens/auth/auth_provider_buttons.dart';
import 'package:cardgame/ui/screens/home/home_menu_widgets.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/theme/wide_layout.dart';
import 'package:cardgame/ui/widgets/language_switcher.dart';
import 'package:cardgame/ui/widgets/suit_card_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class AuthenticationScreen extends ConsumerStatefulWidget {
  const AuthenticationScreen({super.key});

  @override
  ConsumerState<AuthenticationScreen> createState() =>
      _AuthenticationScreenState();
}

class _AuthenticationScreenState extends ConsumerState<AuthenticationScreen> {
  bool _guestLoading = false;
  bool _googleLoading = false;
  bool _appleLoading = false;
  String? _error;

  bool get _busy => _guestLoading || _googleLoading || _appleLoading;

  Future<void> _applyIdentity(ServerIdentity identity) async {
    await ref.read(playerProfileProvider.notifier).applyIdentity(identity);
  }

  Future<void> _enterGuest() async {
    if (_busy) return;
    setState(() {
      _guestLoading = true;
      _error = null;
    });
    try {
      final fingerprint =
          await ref.read(deviceIdentityServiceProvider).fingerprint();
      final identity = await ref
          .read(guestAuthServiceProvider)
          .authenticateGuest(
            deviceId: fingerprint.deviceId,
            platform: fingerprint.platform,
            model: fingerprint.model,
          );
      await _applyIdentity(identity);
      await ref.read(sessionAuthProvider.notifier).enterAsGuest();
    } on GuestAuthException catch (error) {
      unawaited(
        ref
            .read(analyticsServiceProvider)
            .logLoginFailed(method: 'guest', reason: error.toString()),
      );
      if (mounted) {
        setState(() => _error = context.l10n.guestSignInServerDown);
      }
      debugPrint('Guest auth failed: $error');
    } on Object catch (error) {
      unawaited(
        ref
            .read(analyticsServiceProvider)
            .logLoginFailed(method: 'guest', reason: error.toString()),
      );
      if (mounted) {
        setState(() => _error = context.l10n.guestSignInConnection);
      }
      debugPrint('Guest auth error: $error');
    } finally {
      if (mounted) setState(() => _guestLoading = false);
    }
  }

  Future<void> _enterGoogle() async {
    if (_busy) return;
    setState(() {
      _googleLoading = true;
      _error = null;
    });
    try {
      final result = await linkOrSignInWithGoogle(context: context, ref: ref);
      if (!mounted) return;
      if (result.outcome == GuestGoogleLinkOutcome.failed) {
        setState(() => _error = result.errorMessage);
      }
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _enterApple() async {
    if (_busy) return;
    setState(() {
      _appleLoading = true;
      _error = null;
    });
    try {
      final result = await linkOrSignInWithApple(context: context, ref: ref);
      if (!mounted) return;
      if (result.outcome == GuestGoogleLinkOutcome.failed) {
        setState(() => _error = result.errorMessage);
      }
    } finally {
      if (mounted) setState(() => _appleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    Widget logo(double height) => Image.asset(
      'assets/logo/text.png',
      height: height,
      fit: BoxFit.contain,
    );
    final tagline = Text(
      l10n.tagline,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: CasinoColors.goldSoft,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
      ),
    );
    final fan = LayoutBuilder(
      builder:
          (context, constraints) => HeroCardFan(
            deckSkinId: CardBackSkins.activeId,
            height: constraints.maxHeight.clamp(0.0, 240.0),
          ),
    );
    final signIn = [
      Text(
        l10n.signInToPlay,
        textAlign: TextAlign.center,
        style: TextStyle(color: CasinoColors.text, fontSize: 14),
      ),
      const SizedBox(height: 18),
      if (_error != null) ...[
        Text(
          _error!,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: CasinoColors.foldHi),
        ),
        const SizedBox(height: 16),
      ],
      if (AppleSignInService.isSupported) ...[
        AuthProviderButton.apple(
          label: _appleLoading ? l10n.signingIn : l10n.continueWithApple,
          onPressed: _busy ? null : _enterApple,
        ),
        const SizedBox(height: 14),
      ],
      AuthProviderButton.google(
        label: _googleLoading ? l10n.signingIn : l10n.continueWithGoogle,
        onPressed: _busy ? null : _enterGoogle,
      ),
      const SizedBox(height: 14),
      AuthProviderButton.guest(
        label: _guestLoading ? l10n.entering : l10n.playAsGuest,
        onPressed: _busy ? null : _enterGuest,
      ),
      const SizedBox(height: 28),
      if (_busy)
        const SuitCardLoader(height: 22)
      else
        const SizedBox(height: 22),
      Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const _LegalLink(label: 'Terms of Service', url: TOS_URL),
          Text(
            '·',
            style: TextStyle(color: CasinoColors.goldSoft),
          ),
          const _LegalLink(label: 'Privacy Policy', url: PRIVACY_URL),
        ],
      ),
    ];
    const languages = Align(
      alignment: AlignmentDirectional.topEnd,
      child: Padding(
        padding: EdgeInsets.only(top: 8),
        child: LanguageSwitcher(showLabel: true),
      ),
    );

    if (WideLayout.of(context)) {
      // The brand on one side, signing in on the other.
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              languages,
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              logo(130),
                              const SizedBox(height: 4),
                              tagline,
                              SizedBox(height: 260, child: fan),
                            ],
                          ),
                        ),
                        const SizedBox(width: 56),
                        SizedBox(
                          width: 380,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: signIn,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          children: [
            languages,
            const Spacer(),
            logo(110),
            const SizedBox(height: 4),
            tagline,
            Flexible(flex: 6, child: fan),
            ...signIn,
            const Spacer(flex: 1),
          ],
        ),
      ),
    );
  }
}

class _LegalLink extends StatelessWidget {
  const _LegalLink({required this.label, required this.url});

  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      ),
      style: TextButton.styleFrom(
        foregroundColor: CasinoColors.goldSoft,
        textStyle: const TextStyle(
          fontSize: 12,
          decoration: TextDecoration.underline,
        ),
      ),
      child: Text(label),
    );
  }
}
