import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Persists in-app language (`en` / `fr` / `ar`).
class LocaleRepository {
  LocaleRepository._(this._box, this._memory);

  static const boxName = 'locale_prefs';
  static const _keyLanguage = 'languageCode';
  static const supportedCodes = {'en', 'fr', 'ar'};

  final Box<dynamic>? _box;
  String? _memory;

  static Future<LocaleRepository> open() async {
    final box = await Hive.openBox<dynamic>(boxName);
    return LocaleRepository._(box, null);
  }

  factory LocaleRepository.memory([String? initial]) {
    return LocaleRepository._(null, initial);
  }

  /// Stored code, or null if never chosen (use device default).
  String? loadCode() {
    if (_memory != null) return _memory;
    final raw = _box!.get(_keyLanguage) as String?;
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

  static Locale resolveInitial({
    required String? storedCode,
    required List<Locale> deviceLocales,
  }) {
    if (storedCode != null && supportedCodes.contains(storedCode)) {
      return Locale(storedCode);
    }
    for (final locale in deviceLocales) {
      if (supportedCodes.contains(locale.languageCode)) {
        return Locale(locale.languageCode);
      }
    }
    return const Locale('en');
  }
}
