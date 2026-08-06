import 'dart:convert';

import 'package:cardgame/data/auth/server_identity.dart';
import 'package:http/http.dart' as http;

class GuestAuthException implements Exception {
  GuestAuthException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'GuestAuthException($statusCode): $message';
}

/// HTTP client for guest account lookup / creation.
class GuestAuthService {
  GuestAuthService({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Future<ServerIdentity> authenticateGuest({
    required String deviceId,
    String? platform,
    String? model,
  }) async {
    final uri = Uri.parse('$baseUrl/auth/guest');
    final response = await _client
        .post(
          uri,
          headers: const {'content-type': 'application/json'},
          body: jsonEncode({
            'deviceId': deviceId,
            if (platform != null) 'platform': platform,
            if (model != null) 'model': model,
          }),
        )
        .timeout(const Duration(seconds: 8));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GuestAuthException(
        response.body.isEmpty ? 'Guest auth failed' : response.body,
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw GuestAuthException('Invalid guest auth response');
    }
    final identity = ServerIdentity.fromJson(decoded);
    if (identity.playerId.isEmpty) {
      throw GuestAuthException('Missing playerId in guest auth response');
    }
    return identity;
  }
}
