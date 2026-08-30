import 'package:flutter/foundation.dart';

abstract final class PurchasesConfig {
  static const entitlementPro = 'hailsom_technologies_inc_pro';

  static const chips1 = 'chips_1';
  static const chips5 = 'chips_5';
  static const chips10 = 'chips_10';
  static const chips25 = 'chips_25';
  static const chips50 = 'chips_50';

  static const cash1000 = 'cash_1000';
  static const cash5000 = 'cash_5000';
  static const cash10000 = 'cash_10000';
  static const cash25000 = 'cash_25000';

  // Legacy aliases
  static const gems100 = 'gems_100';
  static const gems500 = 'gems_500';
  static const gems1200 = 'gems_1200';
  static const coins1000 = 'coins_1000';
  static const coins5000 = 'coins_5000';

  static const proMonthly = 'pro_monthly';

  static const consumableProductIds = [
    chips1,
    chips5,
    chips10,
    chips25,
    chips50,
    cash1000,
    cash5000,
    cash10000,
    cash25000,
    gems100,
    gems500,
    gems1200,
    coins1000,
    coins5000,
  ];

  static const allProductIds = [...consumableProductIds, proMonthly];

  static String? apiKey() {
    const fromDefine = String.fromEnvironment('REVENUECAT_API_KEY');
    if (fromDefine.isNotEmpty) return fromDefine;

    if (!kIsWeb) {
      if (defaultTargetPlatform == TargetPlatform.android) {
        const androidKey = String.fromEnvironment('REVENUECAT_GOOGLE_API_KEY');
        if (androidKey.isNotEmpty) return androidKey;
      } else if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        const iosKey = String.fromEnvironment('REVENUECAT_APPLE_API_KEY');
        if (iosKey.isNotEmpty) return iosKey;
      }
    }

    return null;
  }

  static bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);
}
