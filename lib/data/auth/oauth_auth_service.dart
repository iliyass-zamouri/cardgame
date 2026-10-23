import 'dart:convert';

import 'package:cardgame/data/auth/server_identity.dart';
import 'package:http/http.dart' as http;

class OAuthAuthException implements Exception {
  OAuthAuthException(this.message, {this.statusCode, this.code});

  final String message;
  final int? statusCode;
  final String? code;

  @override
  String toString() => 'OAuthAuthException($statusCode, $code): $message';
}

/// OAuth account already linked to a different player while a local guest exists.
class GoogleAccountInUseException implements Exception {
  GoogleAccountInUseException({
    required this.existingName,
    required this.existingUsername,
    this.guestPlayerId,
  });

  final String existingName;
  final String existingUsername;
  final String? guestPlayerId;

  @override
  String toString() =>
      'GoogleAccountInUseException(@$existingUsername, guest=$guestPlayerId)';
}

/// HTTP client for Google / Apple id token exchange.
class OAuthAuthService {
  OAuthAuthService({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Future<ServerIdentity> authenticateGoogle({
    required String idToken,
    String? deviceId,
    bool confirmSwitch = false,
  }) {
    return _exchange('/auth/google', {
      'idToken': idToken,
      if (deviceId != null && deviceId.isNotEmpty) 'deviceId': deviceId,
      if (confirmSwitch) 'confirmSwitch': true,
    });
  }

  /// [rawNonce] is the unhashed nonce whose sha256 Apple put in the token.
  Future<ServerIdentity> authenticateApple({
    required String identityToken,
    required String rawNonce,
    String? authorizationCode,
    String? fullName,
    String? deviceId,
    bool confirmSwitch = false,
  }) {
    return _exchange('/auth/apple', {
      'idToken': identityToken,
      'nonce': rawNonce,
      if (authorizationCode != null && authorizationCode.isNotEmpty)
        'authorizationCode': authorizationCode,
      if (fullName != null && fullName.isNotEmpty) 'fullName': fullName,
      if (deviceId != null && deviceId.isNotEmpty) 'deviceId': deviceId,
      if (confirmSwitch) 'confirmSwitch': true,
    });
  }

  Future<ServerIdentity> _exchange(String path, Map<String, Object> body) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _client
        .post(
          uri,
          headers: const {'content-type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode == 409) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> &&
            (decoded['error'] == 'google_account_in_use' ||
                decoded['error'] == 'account_in_use')) {
          throw GoogleAccountInUseException(
            existingName: decoded['existingName'] as String? ?? 'Player',
            existingUsername:
                decoded['existingUsername'] as String? ?? 'player',
            guestPlayerId: decoded['guestPlayerId'] as String?,
          );
        }
      } catch (error) {
        if (error is GoogleAccountInUseException) rethrow;
      }
      throw OAuthAuthException(
        'Account already in use',
        statusCode: 409,
        code: 'account_in_use',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String? code;
      var message = response.body.isEmpty ? 'OAuth auth failed' : response.body;
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          code = decoded['error'] as String?;
          message = decoded['message'] as String? ?? message;
        }
      } catch (_) {}
      throw OAuthAuthException(
        message,
        statusCode: response.statusCode,
        code: code,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw OAuthAuthException('Invalid OAuth auth response');
    }
    final identity = ServerIdentity.fromJson(decoded);
    if (identity.playerId.isEmpty) {
      throw OAuthAuthException('Missing playerId in OAuth auth response');
    }
    return identity;
  }
}
