import 'dart:convert';
import 'package:http/http.dart' as http;

class MarketplaceApiException implements Exception {
  MarketplaceApiException(this.message, {this.statusCode, this.code});

  final String message;
  final int? statusCode;
  final String? code;

  @override
  String toString() => 'MarketplaceApiException($statusCode, $code): $message';
}

class PlayerInventory {
  const PlayerInventory({
    required this.playerId,
    required this.money,
    required this.chips,
    required this.ownedAvatars,
    required this.ownedDecks,
  });

  final String playerId;
  final int money;
  final int chips;
  final List<String> ownedAvatars;
  final List<String> ownedDecks;

  factory PlayerInventory.fromJson(Map<String, dynamic> json) {
    return PlayerInventory(
      playerId: json['playerId'] as String? ?? '',
      money: (json['money'] as num?)?.toInt() ?? 0,
      chips: (json['chips'] as num?)?.toInt() ?? 0,
      ownedAvatars: (json['ownedAvatars'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['default'],
      ownedDecks: (json['ownedDecks'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['default'],
    );
  }
}

class MarketplaceApi {
  MarketplaceApi({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Future<PlayerInventory> getInventory(String playerId) async {
    final uri = Uri.parse('$baseUrl/marketplace/inventory')
        .replace(queryParameters: {'playerId': playerId});
    final response = await _client.get(uri).timeout(const Duration(seconds: 8));
    final body = _decodeMap(response);
    return PlayerInventory.fromJson(body);
  }

  Future<Map<String, dynamic>> exchange({
    required String playerId,
    required String direction,
    required int amount,
  }) async {
    final uri = Uri.parse('$baseUrl/marketplace/exchange');
    final response = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'playerId': playerId,
            'direction': direction,
            'amount': amount,
          }),
        )
        .timeout(const Duration(seconds: 8));
    return _decodeMap(response);
  }

  Future<Map<String, dynamic>> buyItem({
    required String playerId,
    required String itemType,
    required String itemId,
    required String currency,
    required int price,
  }) async {
    final uri = Uri.parse('$baseUrl/marketplace/buy');
    final response = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'playerId': playerId,
            'itemType': itemType,
            'itemId': itemId,
            'currency': currency,
            'price': price,
          }),
        )
        .timeout(const Duration(seconds: 8));
    return _decodeMap(response);
  }

  Future<Map<String, dynamic>> claimAdReward(String playerId) async {
    final uri = Uri.parse('$baseUrl/marketplace/claim-ad-reward');
    final response = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'playerId': playerId}),
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
      throw MarketplaceApiException(
        msg,
        statusCode: response.statusCode,
        code: code,
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw MarketplaceApiException('Invalid JSON response');
    }
    return decoded;
  }
}
