import 'dart:convert';

import 'package:cardgame/data/auth/auth_headers.dart';
import 'package:cardgame/data/boost/boost_models.dart';
import 'package:http/http.dart' as http;

class BoostApiException implements Exception {
  BoostApiException(this.message, {this.statusCode, this.code, this.state});

  final String message;
  final int? statusCode;

  /// Server error code: `boost_conflict` or `boost_not_found`.
  final String? code;

  /// The boosts as they stand, sent with a conflict.
  final BoostState? state;

  bool get isConflict => code == 'boost_conflict';

  @override
  String toString() => 'BoostApiException($statusCode, $code): $message';
}

/// Coin Boosts: the one running and the ones waiting to be activated.
class BoostApi {
  BoostApi({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Future<BoostState> fetch({String? accessToken}) async {
    final response = await _client
        .get(Uri.parse('$baseUrl/boosts'), headers: authHeaders(accessToken))
        .timeout(const Duration(seconds: 8));
    return BoostState.fromJson(_decodeMap(response));
  }

  Future<BoostActivation> activate({
    required String itemId,
    String? accessToken,
  }) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/boosts/activate'),
          headers: authHeaders(accessToken),
          body: jsonEncode({'itemId': itemId}),
        )
        .timeout(const Duration(seconds: 10));
    return BoostActivation.fromJson(_decodeMap(response));
  }

  Map<String, dynamic> _decodeMap(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      var message = 'Request failed';
      String? code;
      BoostState? state;
      try {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic>) {
          message = body['message'] as String? ?? message;
          code = body['error'] as String?;
          final boosts = body['boosts'];
          if (boosts is Map) {
            state = BoostState.fromJson(Map<String, dynamic>.from(boosts));
          }
        }
      } catch (_) {}
      throw BoostApiException(
        message,
        statusCode: response.statusCode,
        code: code,
        state: state,
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw BoostApiException('Invalid JSON response');
    }
    return decoded;
  }
}
