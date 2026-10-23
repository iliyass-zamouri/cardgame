import 'dart:convert';

import 'package:cardgame/data/auth/auth_headers.dart';
import 'package:http/http.dart' as http;

/// Fetches STUN/TURN servers (with short-lived TURN credentials) for voice.
class VoiceApi {
  VoiceApi({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  static const fallbackIceServers = [
    {
      'urls': ['stun:stun.l.google.com:19302'],
    },
  ];

  Future<List<Map<String, dynamic>>> fetchIceServers({
    String? accessToken,
  }) async {
    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl/voice/ice'),
            headers: authHeaders(accessToken),
          )
          .timeout(const Duration(seconds: 6));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return fallbackIceServers;
      }
      final body = jsonDecode(response.body);
      final servers = body is Map ? body['iceServers'] : null;
      if (servers is! List || servers.isEmpty) return fallbackIceServers;
      return servers
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return fallbackIceServers;
    }
  }
}
