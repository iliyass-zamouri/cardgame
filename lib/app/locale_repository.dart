import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Persists in-app language override (`en` / `fr` / `es` / `pt` / `ar`).
///
/// No saved preference → match system language; unsupported → English.
class LocaleRepository {
  LocaleRepository._(this._box, this._memory);

  static const boxName = 'locale_prefs';
  static const _keyLanguage = 'languageCode';
  static const supportedCodes = {'en', 'fr', 'es', 'pt', 'ar'};

  final Box<dynamic>? _box;
  String? _memory;

  static Future<LocaleRepository> open() async {
    final box = await Hive.openBox<dynamic>(boxName);
    return LocaleRepository._(box, null);
  }

  factory LocaleRepository.memory([String? initial]) {
    return LocaleRepository._(null, initial);
  }

  /// Stored override, or null if never chosen (follow system).
  String? loadCode() {
    if (_box == null) return _memory;
    final raw = _box.get(_keyLanguage) as String?;
    if (raw == null || !supportedCodes.contains(raw)) return null;
    return raw;
  }

  Future<void> saveCode(String code) async {
    assert(supportedCodes.contains(code));
    if (_box == null) {
      _memory = code;
      return;
    }
    await _box.put(_keyLanguage, code);
  }

  /// Prefer explicit user pick, else first supported system locale, else `en`.
  static Locale resolve({
    required String? storedCode,
    required List<Locale> deviceLocales,
  }) {
    if (storedCode != null && supportedCodes.contains(storedCode)) {
      return Locale(storedCode);
    }
    return fromDeviceLocales(deviceLocales);
  }

  /// First device locale whose language we support, else English.
  static Locale fromDeviceLocales(List<Locale> deviceLocales) {
    for (final locale in deviceLocales) {
      final code = locale.languageCode.toLowerCase();
      if (supportedCodes.contains(code)) {
        return Locale(code);
      }
    }
    return const Locale('en');
  }

  /// Kept for older call sites / tests.
  static Locale resolveInitial({
    required String? storedCode,
    required List<Locale> deviceLocales,
  }) => resolve(storedCode: storedCode, deviceLocales: deviceLocales);
}
