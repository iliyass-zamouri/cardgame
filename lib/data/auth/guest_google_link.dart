import 'dart:async';

import 'package:cardgame/app/auth_providers.dart';
import 'package:cardgame/data/auth/apple_sign_in_service.dart';
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

enum OAuthLinkProvider { google, apple }

/// Shared guest→Google (or cold Google) sign-in with conflict confirm.
Future<GuestGoogleLinkResult> linkOrSignInWithGoogle({
  required BuildContext context,
  required WidgetRef ref,
  bool confirmSwitch = false,
}) {
  return linkOrSignInWithProvider(
    provider: OAuthLinkProvider.google,
    context: context,
    ref: ref,
    confirmSwitch: confirmSwitch,
  );
}

/// Shared guest→Apple (or cold Apple) sign-in with conflict confirm.
Future<GuestGoogleLinkResult> linkOrSignInWithApple({
  required BuildContext context,
  required WidgetRef ref,
  bool confirmSwitch = false,
}) {
  return linkOrSignInWithProvider(
    provider: OAuthLinkProvider.apple,
    context: context,
    ref: ref,
    confirmSwitch: confirmSwitch,
  );
}

Future<GuestGoogleLinkResult> linkOrSignInWithProvider({
  required OAuthLinkProvider provider,
  required BuildContext context,
  required WidgetRef ref,
  bool confirmSwitch = false,
}) async {
  final l10n = context.l10n;
  final isApple = provider == OAuthLinkProvider.apple;
  final method = provider.name;
  final genericFailure =
      isApple ? l10n.appleSignInFailed : l10n.googleSignInFailed;

  void logFailure(String reason) {
    unawaited(
      ref
          .read(analyticsServiceProvider)
          .logLoginFailed(method: method, reason: reason),
    );
  }

  try {
    final fingerprint =
        await ref.read(deviceIdentityServiceProvider).fingerprint();
    final oauth = ref.read(oauthAuthServiceProvider);

    final Future<ServerIdentity> Function({required bool switchConfirmed})
    exchange;
    if (isApple) {
      final credential = await ref.read(appleSignInServiceProvider).signIn();
      exchange =
          ({required bool switchConfirmed}) => oauth.authenticateApple(
            identityToken: credential.identityToken,
            rawNonce: credential.rawNonce,
            authorizationCode: credential.authorizationCode,
            fullName: credential.fullName,
            deviceId: fingerprint.deviceId,
            confirmSwitch: switchConfirmed,
          );
    } else {
      final idToken =
          await ref.read(googleSignInServiceProvider).signInIdToken();
      exchange =
          ({required bool switchConfirmed}) => oauth.authenticateGoogle(
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
              isApple
                  ? l10n.appleAccountInUseTitle
                  : l10n.googleAccountInUseTitle,
              style: const TextStyle(color: CasinoColors.gold),
            ),
            content: Text(
              isApple
                  ? l10n.appleAccountInUseBody(conflict.existingUsername)
                  : l10n.googleAccountInUseBody(conflict.existingUsername),
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
    final session = ref.read(sessionAuthProvider.notifier);
    if (isApple) {
      await session.enterWithApple();
    } else {
      await session.enterWithGoogle();
    }
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
    logFailure('cancelled');
    return const GuestGoogleLinkResult(
      outcome: GuestGoogleLinkOutcome.cancelled,
    );
  } on AppleSignInCancelledException {
    logFailure('cancelled');
    return const GuestGoogleLinkResult(
      outcome: GuestGoogleLinkOutcome.cancelled,
    );
  } on GoogleSignInFailedException catch (error) {
    logFailure(error.message);
    return GuestGoogleLinkResult(
      outcome: GuestGoogleLinkOutcome.failed,
      errorMessage: error.message,
    );
  } on AppleSignInFailedException catch (error) {
    logFailure(error.message);
    return GuestGoogleLinkResult(
      outcome: GuestGoogleLinkOutcome.failed,
      errorMessage: genericFailure,
    );
  } on OAuthAuthException catch (error) {
    logFailure(error.toString());
    return GuestGoogleLinkResult(
      outcome: GuestGoogleLinkOutcome.failed,
      errorMessage: genericFailure,
    );
  } on Object catch (error) {
    logFailure(error.toString());
    debugPrint('$method link/sign-in error: $error');
    return GuestGoogleLinkResult(
      outcome: GuestGoogleLinkOutcome.failed,
      errorMessage: genericFailure,
    );
  }
}
