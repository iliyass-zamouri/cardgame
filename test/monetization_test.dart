import 'dart:convert';
import 'package:cardgame/core/monetization/purchases_config.dart';
import 'package:cardgame/data/marketplace/marketplace_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('PurchasesConfig', () {
    test('contains exact product and entitlement IDs', () {
      expect(PurchasesConfig.entitlementPro, 'hailsom_technologies_inc_pro');
      expect(
        PurchasesConfig.consumableProductIds,
        containsAll([
          'chips_1',
          'chips_5',
          'chips_10',
          'chips_25',
          'chips_50',
          'cash_1000',
          'cash_5000',
          'cash_10000',
        ]),
      );
      expect(PurchasesConfig.proMonthly, 'pro_monthly');
    });
  });

  group('MarketplaceApi.verifyIap', () {
    test('posts to /economy/iap/verify and decodes response', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/economy/iap/verify');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['playerId'], 'player-1');
        expect(body['productId'], 'gems_100');
        expect(body['transactionId'], 'tx-12345');

        return http.Response(
          jsonEncode({
            'playerId': 'player-1',
            'productId': 'gems_100',
            'transactionId': 'tx-12345',
            'money': 500,
            'chips': 101,
            'alreadyRedeemed': false,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = MarketplaceApi(
        baseUrl: 'http://localhost:8080',
        client: mockClient,
      );
      final result = await api.verifyIap(
        playerId: 'player-1',
        productId: 'gems_100',
        transactionId: 'tx-12345',
      );

      expect(result['chips'], 101);
      expect(result['alreadyRedeemed'], false);
    });
  });
}
