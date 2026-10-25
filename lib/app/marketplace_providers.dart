import 'dart:async';
import 'dart:convert';

import 'package:cardgame/app/auth_providers.dart';
import 'package:cardgame/data/marketplace/marketplace_api.dart';
import 'package:cardgame/data/marketplace/marketplace_catalog.dart';
import 'package:cardgame/trailer/trailer_mode.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Caches the last served catalog, so the shop shows current prices on its
/// first frame and offline.
class MarketplaceCatalogRepository {
  MarketplaceCatalogRepository._(this._box);

  static const boxName = 'marketplace_catalog';
  static const _keyJson = 'json';
  static const _keyReceivedAt = 'receivedAtMs';

  final Box<dynamic>? _box;
  String? _memoryJson;
  int? _memoryReceivedAt;

  static Future<MarketplaceCatalogRepository> open() async {
    return MarketplaceCatalogRepository._(await Hive.openBox<dynamic>(boxName));
  }

  /// In-memory repo for tests (no Hive).
  factory MarketplaceCatalogRepository.memory() =>
      MarketplaceCatalogRepository._(null);

  MarketplaceCatalog? read() {
    final raw = _box?.get(_keyJson) ?? _memoryJson;
    final receivedAt = _box?.get(_keyReceivedAt) ?? _memoryReceivedAt;
    if (raw is! String || receivedAt is! int) return null;
    try {
      return MarketplaceCatalog.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
        receivedAt: DateTime.fromMillisecondsSinceEpoch(receivedAt),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> write(Map<String, dynamic> json, DateTime receivedAt) async {
    final raw = jsonEncode(json);
    if (_box == null) {
      _memoryJson = raw;
      _memoryReceivedAt = receivedAt.millisecondsSinceEpoch;
      return;
    }
    await _box.put(_keyJson, raw);
    await _box.put(_keyReceivedAt, receivedAt.millisecondsSinceEpoch);
  }
}

final marketplaceCatalogRepositoryProvider =
    Provider<MarketplaceCatalogRepository>(
      (ref) => MarketplaceCatalogRepository.memory(),
    );

/// The shop's prices and promotions: the cached copy at once, then the
/// server's. Refetches when a sale, bonus or banner starts or ends.
class MarketplaceCatalogController extends Notifier<MarketplaceCatalog> {
  static const _maxTimer = Duration(hours: 12);

  Timer? _changeTimer;

  @override
  MarketplaceCatalog build() {
    ref.onDispose(() => _changeTimer?.cancel());
    // Capture builds run offline and keep the bundled shop.
    if (!TrailerMode.enabled) Future.microtask(refresh);
    return ref.read(marketplaceCatalogRepositoryProvider).read() ??
        MarketplaceCatalog.bundled;
  }

  Future<void> refresh() async {
    try {
      final json = await ref.read(marketplaceApiServiceProvider).getCatalog();
      final receivedAt = DateTime.now();
      final next = MarketplaceCatalog.fromJson(json, receivedAt: receivedAt);
      if (!ref.mounted) return;
      state = next;
      _scheduleChange(next.nextChangeAt);
      await ref
          .read(marketplaceCatalogRepositoryProvider)
          .write(json, receivedAt);
    } catch (e) {
      debugPrint('Shop catalog refresh skipped: $e');
    }
  }

  void _scheduleChange(DateTime? at) {
    _changeTimer?.cancel();
    if (at == null) return;
    var wait = at.difference(DateTime.now()) + const Duration(seconds: 1);
    if (wait.isNegative) wait = const Duration(seconds: 1);
    if (wait > _maxTimer) wait = _maxTimer;
    _changeTimer = Timer(wait, refresh);
  }
}

final marketplaceCatalogProvider =
    NotifierProvider<MarketplaceCatalogController, MarketplaceCatalog>(
      MarketplaceCatalogController.new,
    );

/// True when the server refused because the shop changed under the player:
/// a price, the exchange rate, or the item left the shop.
bool isShopChangedError(Object error) =>
    error is MarketplaceApiException &&
    const {
      'price_changed',
      'rate_changed',
      'item_unavailable',
    }.contains(error.code);
