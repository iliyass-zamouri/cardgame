import 'package:cardgame/core/monetization/purchases_config.dart';
import 'package:cardgame/core/monetization/purchases_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

final purchasesServiceProvider = Provider<PurchasesService>((ref) {
  return PurchasesService.instance;
});

class CustomerInfoNotifier extends AsyncNotifier<CustomerInfo?> {
  @override
  Future<CustomerInfo?> build() async {
    final service = ref.read(purchasesServiceProvider);
    return service.getCustomerInfo();
  }

  Future<void> refresh() async {
    final service = ref.read(purchasesServiceProvider);
    final info = await service.getCustomerInfo();
    state = AsyncData(info);
  }

  void setCustomerInfo(CustomerInfo info) {
    state = AsyncData(info);
  }
}

final customerInfoProvider =
    AsyncNotifierProvider<CustomerInfoNotifier, CustomerInfo?>(
      CustomerInfoNotifier.new,
    );

final isProProvider = Provider<bool>((ref) {
  final customerInfo = ref.watch(customerInfoProvider).value;
  if (customerInfo == null) return false;
  return customerInfo
          .entitlements
          .all[PurchasesConfig.entitlementPro]
          ?.isActive ??
      false;
});

final offeringsProvider = FutureProvider<Offerings?>((ref) async {
  final service = ref.read(purchasesServiceProvider);
  return service.getOfferings();
});
