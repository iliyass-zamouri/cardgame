import 'package:cardgame/data/auth/auth_config.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInCancelledException implements Exception {
  @override
  String toString() => 'GoogleSignInCancelledException';
}

class GoogleSignInFailedException implements Exception {
  GoogleSignInFailedException(this.message);

  final String message;

  @override
  String toString() => 'GoogleSignInFailedException: $message';
}

/// Native Google Sign-In → ID token for server verification (google_sign_in 7.x).
class GoogleSignInService {
  GoogleSignInService({String? serverClientId})
    : _serverClientId = _nonEmpty(serverClientId) ?? googleServerClientId;

  final String? _serverClientId;
  bool _initialized = false;

  static String? _nonEmpty(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    final serverClientId = _serverClientId;
    if (serverClientId == null || serverClientId.isEmpty) {
      throw GoogleSignInFailedException(
        'GOOGLE_SERVER_CLIENT_ID missing (Web client ID via --dart-define).',
      );
    }
    // Web GIS requires clientId; native uses serverClientId for idToken aud.
    await GoogleSignIn.instance.initialize(
      clientId: kIsWeb ? serverClientId : null,
      serverClientId: serverClientId,
    );
    _initialized = true;
  }

  /// Returns a Google ID token, or throws on cancel / failure.
  Future<String> signInIdToken() async {
    await _ensureInitialized();
    try {
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw GoogleSignInFailedException(
          'Missing Google idToken. Use a Web OAuth client as '
          'GOOGLE_SERVER_CLIENT_ID.',
        );
      }
      return idToken;
    } on GoogleSignInFailedException {
      rethrow;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw GoogleSignInCancelledException();
      }
      throw GoogleSignInFailedException(
        'Google sign-in failed (${error.code.name}): ${error.description ?? ''}',
      );
    } on PlatformException catch (error) {
      final details = '${error.message ?? ''} ${error.details ?? ''}'.trim();
      if (details.contains('ApiException: 10') ||
          details.contains(': 10:') ||
          details.contains('28444') ||
          error.code.contains('28444')) {
        throw GoogleSignInFailedException(
          'Google Android setup incomplete (error 10/28444). Android OAuth '
          'client SHA-1 mismatch or package mismatch.',
        );
      }
      throw GoogleSignInFailedException(
        'Google sign-in failed (${error.code}): $details',
      );
    }
  }

  Future<void> signOut() async {
    try {
      if (!_initialized) return;
      await GoogleSignIn.instance.signOut();
    } on Object {
      // Best-effort.
    }
  }
}
