import 'dart:convert';
import 'package:cardgame/data/auth/auth_headers.dart';
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
    this.adRewardMoney = 50,
    required this.ownedAvatars,
    required this.ownedDecks,
  });

  final String playerId;
  final int money;
  final int chips;
  final int adRewardMoney;
  final List<String> ownedAvatars;
  final List<String> ownedDecks;

  factory PlayerInventory.fromJson(Map<String, dynamic> json) {
    return PlayerInventory(
      playerId: json['playerId'] as String? ?? '',
      money: (json['money'] as num?)?.toInt() ?? 0,
      chips: (json['chips'] as num?)?.toInt() ?? 0,
      adRewardMoney: (json['adRewardMoney'] as num?)?.toInt() ?? 50,
      ownedAvatars:
          (json['ownedAvatars'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['default'],
      ownedDecks:
          (json['ownedDecks'] as List<dynamic>?)
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

  Future<PlayerInventory> getInventory(
    String playerId, {
    String? accessToken,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/marketplace/inventory',
    ).replace(queryParameters: {'playerId': playerId});
    final response = await _client
        .get(uri, headers: authHeaders(accessToken))
        .timeout(const Duration(seconds: 8));
    final body = _decodeMap(response);
    return PlayerInventory.fromJson(body);
  }

  /// The shop's prices and promotions. Public: no sign-in needed.
  Future<Map<String, dynamic>> getCatalog() async {
    final uri = Uri.parse('$baseUrl/marketplace/catalog');
    final response = await _client.get(uri).timeout(const Duration(seconds: 8));
    return _decodeMap(response);
  }

  /// [expectedRate] is the money-per-chip rate the player saw. The server
  /// refuses with `rate_changed` when it has moved since.
  Future<Map<String, dynamic>> exchange({
    required String playerId,
    required String direction,
    required int amount,
    int? expectedRate,
    String? accessToken,
  }) async {
    final uri = Uri.parse('$baseUrl/marketplace/exchange');
    final response = await _client
        .post(
          uri,
          headers: authHeaders(accessToken),
          body: jsonEncode({
            'playerId': playerId,
            'direction': direction,
            'amount': amount,
            if (expectedRate != null) 'expectedRate': expectedRate,
          }),
        )
        .timeout(const Duration(seconds: 8));
    return _decodeMap(response);
  }

  /// Charges the server's price. It refuses with `price_changed` when
  /// [price] in [currency] is no longer what the item costs.
  Future<Map<String, dynamic>> buyItem({
    required String playerId,
    required String itemType,
    required String itemId,
    required String currency,
    required int price,
    String? accessToken,
  }) async {
    final uri = Uri.parse('$baseUrl/marketplace/buy');
    final response = await _client
        .post(
          uri,
          headers: authHeaders(accessToken),
          body: jsonEncode({
            'playerId': playerId,
            'itemType': itemType,
            'itemId': itemId,
            'expectedCurrency': currency,
            'expectedPrice': price,
          }),
        )
        .timeout(const Duration(seconds: 8));
    return _decodeMap(response);
  }

  Future<Map<String, dynamic>> claimAdReward(
    String playerId, {
    String? accessToken,
  }) async {
    final uri = Uri.parse('$baseUrl/marketplace/claim-ad-reward');
    final response = await _client
        .post(
          uri,
          headers: authHeaders(accessToken),
          body: jsonEncode({'playerId': playerId}),
        )
        .timeout(const Duration(seconds: 8));
    return _decodeMap(response);
  }

  Future<Map<String, dynamic>> verifyIap({
    required String playerId,
    required String productId,
    required String transactionId,
    String? accessToken,
  }) async {
    final uri = Uri.parse('$baseUrl/economy/iap/verify');
    final response = await _client
        .post(
          uri,
          headers: authHeaders(accessToken),
          body: jsonEncode({
            'playerId': playerId,
            'productId': productId,
            'transactionId': transactionId,
          }),
        )
        .timeout(const Duration(seconds: 10));
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
