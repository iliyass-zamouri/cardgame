import 'dart:async';

import 'package:cardgame/app/auth_providers.dart';
import 'package:cardgame/data/auth/google_sign_in_service.dart';
import 'package:cardgame/data/auth/oauth_auth_service.dart';
import 'package:cardgame/data/auth/server_identity.dart';
import 'package:cardgame/l10n/l10n_ext.dart';
import 'package:cardgame/services/analytics_service.dart';
import 'package:cardgame/services/guest_link_prefs_repository.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum GuestGoogleLinkOutcome {
  linked,
  switched,
  cancelled,
  failed,
}

class GuestGoogleLinkResult {
  const GuestGoogleLinkResult({
    required this.outcome,
    this.errorMessage,
    this.linkedFromGuest = false,
  });

  final GuestGoogleLinkOutcome outcome;
  final String? errorMessage;
  final bool linkedFromGuest;

  bool get isSuccess =>
      outcome == GuestGoogleLinkOutcome.linked ||
      outcome == GuestGoogleLinkOutcome.switched;
}

final guestLinkPrefsRepositoryProvider = Provider<GuestLinkPrefsRepository>((
  ref,
) {
  throw UnimplementedError(
    'guestLinkPrefsRepositoryProvider must be overridden in main()',
  );
});

/// Shared guest→Google (or cold Google) sign-in with conflict confirm.
Future<GuestGoogleLinkResult> linkOrSignInWithGoogle({
  required BuildContext context,
  required WidgetRef ref,
  bool confirmSwitch = false,
}) async {
  final l10n = context.l10n;
  try {
    final idToken =
        await ref.read(googleSignInServiceProvider).signInIdToken();
    final fingerprint =
        await ref.read(deviceIdentityServiceProvider).fingerprint();

    Future<ServerIdentity> exchange({required bool switchConfirmed}) {
      return ref.read(oauthAuthServiceProvider).authenticateGoogle(
            idToken: idToken,
            deviceId: fingerprint.deviceId,
            confirmSwitch: switchConfirmed,
          );
    }

    ServerIdentity identity;
    var switched = false;
    try {
      identity = await exchange(switchConfirmed: confirmSwitch);
    } on GoogleAccountInUseException catch (conflict) {
      if (!context.mounted) {
        return const GuestGoogleLinkResult(
          outcome: GuestGoogleLinkOutcome.cancelled,
        );
      }
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: CasinoColors.surface,
            title: Text(
              l10n.googleAccountInUseTitle,
              style: const TextStyle(color: CasinoColors.gold),
            ),
            content: Text(
              l10n.googleAccountInUseBody(conflict.existingUsername),
              style: const TextStyle(color: CasinoColors.text),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(
                  l10n.switchToGoogleAccount,
                  style: const TextStyle(color: CasinoColors.gold),
                ),
              ),
            ],
          );
        },
      );
      if (confirmed != true) {
        return const GuestGoogleLinkResult(
          outcome: GuestGoogleLinkOutcome.cancelled,
        );
      }
      identity = await exchange(switchConfirmed: true);
      switched = true;
    }

    await ref.read(playerProfileProvider.notifier).applyIdentity(identity);
    await ref.read(sessionAuthProvider.notifier).enterWithGoogle();
    try {
      await ref.read(guestLinkPrefsRepositoryProvider).clearAfterLinked();
    } on Object {
      // Best-effort when provider not overridden (tests).
    }

    return GuestGoogleLinkResult(
      outcome:
          switched
              ? GuestGoogleLinkOutcome.switched
              : GuestGoogleLinkOutcome.linked,
      linkedFromGuest: identity.linkedFromGuest,
    );
  } on GoogleSignInCancelledException {
    unawaited(
      ref
          .read(analyticsServiceProvider)
          .logLoginFailed(method: 'google', reason: 'cancelled'),
    );
    return const GuestGoogleLinkResult(
      outcome: GuestGoogleLinkOutcome.cancelled,
    );
  } on GoogleSignInFailedException catch (error) {
    unawaited(
      ref
          .read(analyticsServiceProvider)
          .logLoginFailed(method: 'google', reason: error.message),
    );
    return GuestGoogleLinkResult(
      outcome: GuestGoogleLinkOutcome.failed,
      errorMessage: error.message,
    );
  } on OAuthAuthException catch (error) {
    unawaited(
      ref
          .read(analyticsServiceProvider)
          .logLoginFailed(method: 'google', reason: error.toString()),
    );
    return GuestGoogleLinkResult(
      outcome: GuestGoogleLinkOutcome.failed,
      errorMessage: l10n.googleSignInFailed,
    );
  } on Object catch (error) {
    unawaited(
      ref
          .read(analyticsServiceProvider)
          .logLoginFailed(method: 'google', reason: error.toString()),
    );
    debugPrint('Google link/sign-in error: $error');
    return GuestGoogleLinkResult(
      outcome: GuestGoogleLinkOutcome.failed,
      errorMessage: l10n.googleSignInFailed,
    );
  }
}
