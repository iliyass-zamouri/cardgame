import 'dart:convert';

import 'package:cardgame/data/app_review/app_review_models.dart';
import 'package:cardgame/data/auth/auth_headers.dart';
import 'package:http/http.dart' as http;

class AppReviewApiException implements Exception {
  AppReviewApiException(this.message, {this.statusCode, this.code});

  final String message;
  final int? statusCode;

  /// Server error code, e.g. `too_soon`, `review_not_found`.
  final String? code;

  @override
  String toString() => 'AppReviewApiException($statusCode, $code): $message';
}

/// Device facts sent with each call: the server keeps the latest per player
/// and picks the push language from [locale].
typedef AppReviewDevice =
    ({String platform, String? appVersion, String locale});

/// The rate-the-app prompt. The server decides when to show it and where a
/// rating goes; see server/app_review.js.
class AppReviewApi {
  AppReviewApi({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Future<AppReviewStatus> fetchStatus({
    required AppReviewTrigger trigger,
    required AppReviewDevice device,
    String? accessToken,
  }) async {
    final uri = Uri.parse('$baseUrl/app-review/status').replace(
      queryParameters: {
        'trigger': trigger.name,
        'platform': device.platform,
        if (device.appVersion != null) 'appVersion': device.appVersion!,
        'locale': device.locale,
      },
    );
    final response = await _client
        .get(uri, headers: authHeaders(accessToken))
        .timeout(const Duration(seconds: 8));
    return AppReviewStatus.fromJson(_decodeMap(response));
  }

  /// The prompt is on screen.
  Future<void> markShown(AppReviewTrigger trigger, {String? accessToken}) =>
      _post('/app-review/shown', {'trigger': trigger.name}, accessToken);

  /// Closed without rating.
  Future<void> markDismissed(AppReviewTrigger trigger, {String? accessToken}) =>
      _post('/app-review/dismiss', {'trigger': trigger.name}, accessToken);

  /// Opened from the rating push.
  Future<void> markPushOpened({String? accessToken}) =>
      _post('/app-review/push-opened', const {}, accessToken);

  Future<AppReviewRateResult> rate({
    required int stars,
    required AppReviewTrigger trigger,
    required AppReviewDevice device,
    String? accessToken,
  }) async {
    final body = await _post('/app-review/rate', {
      'stars': stars,
      'trigger': trigger.name,
      'platform': device.platform,
      'appVersion': device.appVersion,
      'locale': device.locale,
    }, accessToken);
    return AppReviewRateResult.fromJson(body);
  }

  Future<void> sendFeedback({
    required int reviewId,
    required List<AppReviewTag> tags,
    String? comment,
    String? accessToken,
  }) => _post('/app-review/$reviewId/feedback', {
    'tags': [for (final tag in tags) tag.name],
    if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
  }, accessToken);

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, Object?> body,
    String? accessToken,
  ) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl$path'),
          headers: authHeaders(accessToken),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 8));
    return _decodeMap(response);
  }

  Map<String, dynamic> _decodeMap(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      var message = 'Request failed';
      String? code;
      try {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic>) {
          message = body['message'] as String? ?? message;
          code = body['error'] as String?;
        }
      } catch (_) {}
      throw AppReviewApiException(
        message,
        statusCode: response.statusCode,
        code: code,
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw AppReviewApiException('Invalid JSON response');
    }
    return decoded;
  }
}
