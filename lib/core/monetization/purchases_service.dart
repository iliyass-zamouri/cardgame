import 'dart:async';
import 'package:cardgame/core/monetization/purchases_config.dart';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PurchasesService {
  PurchasesService._();
  static final PurchasesService instance = PurchasesService._();

  bool _isConfigured = false;
  bool get isConfigured => _isConfigured;

  Future<void> configure({String? appUserId}) async {
    if (!PurchasesConfig.isSupported) {
      debugPrint('[PurchasesService] Unsupported platform, skipping init');
      return;
    }

    if (_isConfigured) return;

    final key = PurchasesConfig.apiKey();
    if (key == null || key.isEmpty) {
      debugPrint(
        '[PurchasesService] No RevenueCat API key provided. Pass --dart-define=REVENUECAT_GOOGLE_API_KEY=goog_... or REVENUECAT_APPLE_API_KEY=appl_...',
      );
      return;
    }

    final configuration = PurchasesConfiguration(key)..appUserID = appUserId;

    try {
      await Purchases.configure(configuration);
      _isConfigured = true;
      debugPrint('[PurchasesService] Configured successfully');
    } catch (e) {
      debugPrint('[PurchasesService] Configuration failed: $e');
    }
  }

  Future<void> logIn(String appUserId) async {
    if (!_isConfigured) return;
    try {
      await Purchases.logIn(appUserId);
    } catch (e) {
      debugPrint('[PurchasesService] logIn failed: $e');
    }
  }

  Future<void> logOut() async {
    if (!_isConfigured) return;
    try {
      final isAnonymous = await Purchases.isAnonymous;
      if (!isAnonymous) {
        await Purchases.logOut();
      }
    } catch (e) {
      debugPrint('[PurchasesService] logOut failed: $e');
    }
  }

  Future<CustomerInfo?> getCustomerInfo() async {
    if (!_isConfigured) return null;
    try {
      return await Purchases.getCustomerInfo();
    } catch (e) {
      debugPrint('[PurchasesService] getCustomerInfo failed: $e');
      return null;
    }
  }

  Future<bool> isPro() async {
    final info = await getCustomerInfo();
    if (info == null) return false;
    return info.entitlements.all[PurchasesConfig.entitlementPro]?.isActive ??
        false;
  }

  Future<Offerings?> getOfferings() async {
    if (!_isConfigured) return null;
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      debugPrint('[PurchasesService] getOfferings failed: $e');
      return null;
    }
  }

  Future<List<StoreProduct>> getProducts(List<String> productIds) async {
    if (!_isConfigured) return [];
    try {
      return await Purchases.getProducts(productIds);
    } catch (e) {
      debugPrint('[PurchasesService] getProducts failed: $e');
      return [];
    }
  }

  Future<CustomerInfo?> purchaseStoreProduct(StoreProduct product) async {
    if (!_isConfigured) return null;
    try {
      return await Purchases.purchaseStoreProduct(product);
    } catch (e) {
      debugPrint('[PurchasesService] purchaseStoreProduct failed: $e');
      rethrow;
    }
  }

  Future<CustomerInfo?> purchasePackage(Package package) async {
    if (!_isConfigured) return null;
    try {
      return await Purchases.purchasePackage(package);
    } catch (e) {
      debugPrint('[PurchasesService] purchasePackage failed: $e');
      rethrow;
    }
  }

  Future<CustomerInfo?> purchaseProduct(String productId) async {
    if (!_isConfigured) return null;
    final products = await getProducts([productId]);
    if (products.isEmpty) {
      throw Exception('Product $productId not found');
    }
    return purchaseStoreProduct(products.first);
  }

  Future<CustomerInfo?> restorePurchases() async {
    if (!_isConfigured) return null;
    try {
      return await Purchases.restorePurchases();
    } catch (e) {
      debugPrint('[PurchasesService] restorePurchases failed: $e');
      rethrow;
    }
  }
}
