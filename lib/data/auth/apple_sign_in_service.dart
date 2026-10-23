import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/services.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AppleSignInCancelledException implements Exception {
  @override
  String toString() => 'AppleSignInCancelledException';
}

class AppleSignInFailedException implements Exception {
  AppleSignInFailedException(this.message);

  final String message;

  @override
  String toString() => 'AppleSignInFailedException: $message';
}

/// Native Sign in with Apple result for server verification.
class AppleSignInCredential {
  const AppleSignInCredential({
    required this.identityToken,
    required this.rawNonce,
    this.authorizationCode,
    this.fullName,
  });

  final String identityToken;

  /// Apple's token carries sha256(rawNonce); the server checks it.
  final String rawNonce;

  /// One-time code the server exchanges for a refresh token, which it
  /// revokes when the account is deleted.
  final String? authorizationCode;

  /// Only present the first time the user authorizes the app.
  final String? fullName;
}

/// Native Sign in with Apple → identity token for server verification.
class AppleSignInService {
  /// Native flow only. Android/web would need a Services ID + redirect.
  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Future<AppleSignInCredential> signIn() async {
    final rawNonce = _generateNonce();
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: sha256.convert(utf8.encode(rawNonce)).toString(),
      );
      final identityToken = credential.identityToken;
      if (identityToken == null || identityToken.isEmpty) {
        throw AppleSignInFailedException('Missing Apple identityToken.');
      }
      final fullName = [credential.givenName, credential.familyName]
          .whereType<String>()
          .map((part) => part.trim())
          .where((part) => part.isNotEmpty)
          .join(' ');
      return AppleSignInCredential(
        identityToken: identityToken,
        rawNonce: rawNonce,
        authorizationCode: credential.authorizationCode,
        fullName: fullName.isEmpty ? null : fullName,
      );
    } on AppleSignInFailedException {
      rethrow;
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) {
        throw AppleSignInCancelledException();
      }
      throw AppleSignInFailedException(
        'Apple sign-in failed (${error.code.name}): ${error.message}',
      );
    } on SignInWithAppleException catch (error) {
      throw AppleSignInFailedException('Apple sign-in failed: $error');
    } on PlatformException catch (error) {
      throw AppleSignInFailedException(
        'Apple sign-in failed (${error.code}): ${error.message ?? ''}',
      );
    }
  }

  static String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }
}
