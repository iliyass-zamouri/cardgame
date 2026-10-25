import 'dart:convert';

import 'package:cardgame/data/auth/auth_headers.dart';
import 'package:cardgame/data/daily_reward/daily_reward_models.dart';
import 'package:http/http.dart' as http;

class DailyRewardApiException implements Exception {
  DailyRewardApiException(
    this.message, {
    this.statusCode,
    this.code,
    this.details = const {},
  });

  final String message;
  final int? statusCode;

  /// Server error code, e.g. `streak_broken`, `insufficient_funds`.
  final String? code;

  /// Extra fields the server sent with the error (e.g. the rescue price).
  final Map<String, dynamic> details;

  @override
  String toString() => 'DailyRewardApiException($statusCode, $code): $message';
}

/// The 7-day streak. The player always comes from the session token; the
/// app only reports its timezone offset, so the server owns the day.
class DailyRewardApi {
  DailyRewardApi({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Future<DailyRewardStatus> fetchStatus({
    required int tzOffsetMinutes,
    String? accessToken,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/daily-reward',
    ).replace(queryParameters: {'tzOffset': '$tzOffsetMinutes'});
    final response = await _client
        .get(uri, headers: authHeaders(accessToken))
        .timeout(const Duration(seconds: 8));
    return DailyRewardStatus.fromJson(_decodeMap(response));
  }

  Future<DailyClaimResult> claim({
    required int tzOffsetMinutes,
    bool boosted = false,
    StreakChoice? choice,
    String? accessToken,
  }) async {
    final uri = Uri.parse('$baseUrl/daily-reward/claim');
    final response = await _client
        .post(
          uri,
          headers: authHeaders(accessToken),
          body: jsonEncode({
            'tzOffsetMinutes': tzOffsetMinutes,
            'boosted': boosted,
            if (choice != null) 'streakChoice': choice.name,
            // Boosts wait in the player's boosts until activated.
            'boostInventory': true,
          }),
        )
        .timeout(const Duration(seconds: 10));
    return DailyClaimResult.fromJson(_decodeMap(response));
  }

  Future<DailyClaimResult> claimComeback({
    required int tzOffsetMinutes,
    String? accessToken,
  }) async {
    final uri = Uri.parse('$baseUrl/daily-reward/comeback/claim');
    final response = await _client
        .post(
          uri,
          headers: authHeaders(accessToken),
          body: jsonEncode({
            'tzOffsetMinutes': tzOffsetMinutes,
            'boostInventory': true,
          }),
        )
        .timeout(const Duration(seconds: 10));
    return DailyClaimResult.fromJson(_decodeMap(response));
  }

  Map<String, dynamic> _decodeMap(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      var message = 'Request failed';
      String? code;
      var details = const <String, dynamic>{};
      try {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic>) {
          message = body['message'] as String? ?? message;
          code = body['error'] as String?;
          details = body;
        }
      } catch (_) {}
      throw DailyRewardApiException(
        message,
        statusCode: response.statusCode,
        code: code,
        details: details,
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw DailyRewardApiException('Invalid JSON response');
    }
    return decoded;
  }
}
