import 'dart:convert';
import 'package:http/http.dart' as http;

class ProfileApiException implements Exception {
  ProfileApiException(this.message, {this.statusCode, this.code});

  final String message;
  final int? statusCode;
  final String? code;

  @override
  String toString() => 'ProfileApiException($statusCode, $code): $message';
}

class UsernameAvailability {
  const UsernameAvailability({
    required this.available,
    this.username,
    this.reason,
    this.isCurrent = false,
  });

  final bool available;
  final String? username;
  final String? reason;
  final bool isCurrent;

  factory UsernameAvailability.fromJson(Map<String, dynamic> json) {
    return UsernameAvailability(
      available: json['available'] == true,
      username: json['username'] as String?,
      reason: json['reason'] as String?,
      isCurrent: json['isCurrent'] == true,
    );
  }
}

class ProfileApi {
  ProfileApi({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Future<UsernameAvailability> checkUsername({
    required String username,
    String? playerId,
  }) async {
    final params = <String, String>{'username': username};
    if (playerId != null && playerId.isNotEmpty) {
      params['playerId'] = playerId;
    }
    final uri = Uri.parse(
      '$baseUrl/player/check-username',
    ).replace(queryParameters: params);
    final response = await _client.get(uri).timeout(const Duration(seconds: 8));
    final body = _decodeMap(response);
    return UsernameAvailability.fromJson(body);
  }

  Future<Map<String, dynamic>> updateProfile({
    required String playerId,
    String? name,
    String? username,
    String? avatarId,
    String? deckId,
  }) async {
    final uri = Uri.parse('$baseUrl/player/profile');
    final response = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'playerId': playerId,
            if (name != null) 'name': name,
            if (username != null) 'username': username,
            if (avatarId != null) 'avatarId': avatarId,
            if (deckId != null) 'deckId': deckId,
          }),
        )
        .timeout(const Duration(seconds: 8));
    return _decodeMap(response);
  }

  Map<String, dynamic> _decodeMap(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String msg = 'Request failed';
      String? code;
      try {
        final errJson = jsonDecode(response.body);
        if (errJson is Map) {
          msg = errJson['message'] as String? ?? msg;
          code = errJson['error'] as String?;
        }
      } catch (_) {}
      throw ProfileApiException(
        msg,
        statusCode: response.statusCode,
        code: code,
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw ProfileApiException('Invalid JSON response');
    }
    return decoded;
  }
}
