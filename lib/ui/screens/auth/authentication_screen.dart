import 'dart:async';

import 'package:cardgame/app/auth_providers.dart';
import 'package:cardgame/data/auth/guest_auth_service.dart';
import 'package:cardgame/data/auth/guest_google_link.dart';
import 'package:cardgame/data/auth/server_identity.dart';
import 'package:cardgame/l10n/l10n_ext.dart';
import 'package:cardgame/services/analytics_service.dart';
import 'package:cardgame/ui/screens/auth/auth_provider_buttons.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/widgets/language_switcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthenticationScreen extends ConsumerStatefulWidget {
  const AuthenticationScreen({super.key});

  @override
  ConsumerState<AuthenticationScreen> createState() =>
      _AuthenticationScreenState();
}

class _AuthenticationScreenState extends ConsumerState<AuthenticationScreen> {
  bool _guestLoading = false;
  bool _googleLoading = false;
  String? _error;

  bool get _busy => _guestLoading || _googleLoading;

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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          children: [
            const Align(
              alignment: AlignmentDirectional.topEnd,
              child: Padding(
                padding: EdgeInsets.only(top: 8),
                child: LanguageSwitcher(showLabel: true),
              ),
            ),
            const Spacer(flex: 2),
            Image.asset(
              'assets/logo/text.png',
              height: 168,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 14),
            Text(
              l10n.signInToPlay,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Spacer(flex: 2),
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
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: CasinoColors.gold,
                ),
              )
            else
              const SizedBox(height: 22),
            const Spacer(flex: 1),
          ],
        ),
      ),
    );
  }
}
