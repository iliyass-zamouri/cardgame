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

/// HTTP client for Google id_token exchange.
class OAuthAuthService {
  OAuthAuthService({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Future<ServerIdentity> authenticateGoogle({
    required String idToken,
    String? deviceId,
  }) async {
    final uri = Uri.parse('$baseUrl/auth/google');
    final response = await _client
        .post(
          uri,
          headers: const {'content-type': 'application/json'},
          body: jsonEncode({
            'idToken': idToken,
            if (deviceId != null && deviceId.isNotEmpty) 'deviceId': deviceId,
          }),
        )
        .timeout(const Duration(seconds: 12));

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
