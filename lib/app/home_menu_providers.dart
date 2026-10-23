import 'package:cardgame/data/app/app_config_api.dart';
import 'package:cardgame/data/app/home_menu_config.dart';
import 'package:cardgame/data/auth/auth_config.dart';
import 'package:cardgame/trailer/trailer_mode.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Caches the last served [HomeMenuConfig] so the home screen renders the
/// right menu on its first frame, before /app/config answers.
class HomeMenuRepository {
  HomeMenuRepository._(this._box, this._memory);

  static const boxName = 'home_menu';
  static const _keyConfig = 'config';

  final Box<dynamic>? _box;
  HomeMenuConfig _memory;

  static Future<HomeMenuRepository> open() async {
    final box = await Hive.openBox<dynamic>(boxName);
    return HomeMenuRepository._(box, HomeMenuConfig.fallback);
  }

  /// In-memory repo for tests (no Hive).
  factory HomeMenuRepository.memory([
    HomeMenuConfig initial = HomeMenuConfig.fallback,
  ]) {
    return HomeMenuRepository._(null, initial);
  }

  HomeMenuConfig read() {
    if (_box == null) return _memory;
    final raw = _box.get(_keyConfig);
    return raw is Map ? HomeMenuConfig.fromJson(raw) : HomeMenuConfig.fallback;
  }

  Future<void> write(HomeMenuConfig config) async {
    if (_box == null) {
      _memory = config;
      return;
    }
    await _box.put(_keyConfig, config.toJson());
  }
}

final homeMenuRepositoryProvider = Provider<HomeMenuRepository>(
  (ref) => HomeMenuRepository.memory(),
);

final appConfigApiProvider = Provider<AppConfigApi>(
  (ref) => AppConfigApi(baseUrl: httpBaseUrl),
);

/// Home menu layout: the cached config right away, then the server's once
/// /app/config answers. Only notifies listeners when the layout changes.
class HomeMenuController extends Notifier<HomeMenuConfig> {
  @override
  HomeMenuConfig build() {
    // Capture builds run offline and must keep the stock menu.
    if (!TrailerMode.enabled) Future.microtask(refresh);
    return ref.read(homeMenuRepositoryProvider).read();
  }

  Future<void> refresh() async {
    try {
      final next = (await ref.read(appConfigApiProvider).fetch()).homeMenu;
      if (next == null || !ref.mounted || next == state) return;
      state = next;
      await ref.read(homeMenuRepositoryProvider).write(next);
    } catch (e) {
      debugPrint('Home menu refresh skipped: $e');
    }
  }
}

final homeMenuProvider = NotifierProvider<HomeMenuController, HomeMenuConfig>(
  HomeMenuController.new,
);
