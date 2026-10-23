import 'dart:async';

import 'package:cardgame/app/home_menu_providers.dart';
import 'package:cardgame/data/app/app_theme_config.dart';
import 'package:cardgame/trailer/trailer_mode.dart';
import 'package:cardgame/ui/theme/app_theme.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Caches the last served theme so the first frame already has the right look.
class ThemeRepository {
  ThemeRepository._(this._box, this._memory);

  static const boxName = 'app_theme';
  static const _keyConfig = 'config';

  final Box<dynamic>? _box;
  AppThemeConfig? _memory;

  static Future<ThemeRepository> open() async {
    final box = await Hive.openBox<dynamic>(boxName);
    return ThemeRepository._(box, null);
  }

  /// In-memory repo for tests (no Hive).
  factory ThemeRepository.memory([AppThemeConfig? initial]) {
    return ThemeRepository._(null, initial);
  }

  AppThemeConfig? read() {
    if (_box == null) return _memory;
    final raw = _box.get(_keyConfig);
    return raw is Map ? AppThemeConfig.tryFromJson(raw) : null;
  }

  Future<void> write(AppThemeConfig config) async {
    if (_box == null) {
      _memory = config;
      return;
    }
    await _box.put(_keyConfig, config.toJson());
  }
}

final themeRepositoryProvider = Provider<ThemeRepository>(
  (ref) => ThemeRepository.memory(),
);

/// `--dart-define=APP_THEME=halloween` previews a theme without the server.
const _themeDefine = String.fromEnvironment('APP_THEME');

/// The theme to start with, before /app/config answers: the dev define, else
/// the cached choice, else casino. Capture builds always stay on casino.
AppTheme initialTheme(ThemeRepository repo) {
  if (TrailerMode.enabled) return AppTheme.casino;
  final define = AppThemeId.values.asNameMap()[_themeDefine];
  if (define != null) return AppTheme.of(define);
  final cached = repo.read();
  if (cached == null) return AppTheme.casino;
  return AppTheme.of(cached.id, animated: cached.animated);
}

/// Active colour theme: the cached one right away, then the server's once
/// /app/config answers, and again whenever the app resumes so a live switch
/// reaches apps that are already open.
class ThemeController extends Notifier<AppTheme> {
  static const _resumeGap = Duration(seconds: 60);

  AppLifecycleListener? _lifecycle;
  DateTime? _lastFetch;

  /// A dev define or capture build fixes the look for the whole run.
  bool get _fixed => TrailerMode.enabled || _themeDefine.isNotEmpty;

  @override
  AppTheme build() {
    final theme = initialTheme(ref.read(themeRepositoryProvider));
    AppTheme.activate(theme);
    if (!_fixed) {
      Future.microtask(refresh);
      _listenForResume();
    }
    ref.onDispose(() {
      _lifecycle?.dispose();
      _lifecycle = null;
    });
    return theme;
  }

  Future<void> refresh() async {
    if (_fixed) return;
    _lastFetch = DateTime.now();
    try {
      final config = (await ref.read(appConfigApiProvider).fetch()).theme;
      if (config == null || !ref.mounted) return;
      final next = AppTheme.of(config.id, animated: config.animated);
      if (next == state) return;
      AppTheme.activate(next);
      state = next;
      await ref.read(themeRepositoryProvider).write(config);
    } catch (e) {
      debugPrint('Theme refresh skipped: $e');
    }
  }

  void _listenForResume() {
    try {
      _lifecycle = AppLifecycleListener(
        onResume: () {
          final last = _lastFetch;
          if (last == null || DateTime.now().difference(last) > _resumeGap) {
            unawaited(refresh());
          }
        },
      );
    } catch (_) {
      // No widgets binding (plain unit tests): the start-up check still runs.
    }
  }
}

final themeProvider = NotifierProvider<ThemeController, AppTheme>(
  ThemeController.new,
);
