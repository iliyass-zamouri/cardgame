import 'package:hive_flutter/hive_flutter.dart';

/// Persists soft-prompt dismissal for push permission.
class PushPrefsRepository {
  PushPrefsRepository._(this._box, this._memorySoftPromptDone);

  static const boxName = 'push_prefs';
  static const _keySoftPromptDone = 'pushSoftPromptDone';

  final Box<dynamic>? _box;
  bool? _memorySoftPromptDone;

  static Future<PushPrefsRepository> open() async {
    final box = await Hive.openBox<dynamic>(boxName);
    return PushPrefsRepository._(box, null);
  }

  /// In-memory repo for tests (no Hive).
  factory PushPrefsRepository.memory({bool pushSoftPromptDone = true}) {
    return PushPrefsRepository._(null, pushSoftPromptDone);
  }

  bool get pushSoftPromptDone {
    if (_box == null) return _memorySoftPromptDone ?? false;
    return _box.get(_keySoftPromptDone, defaultValue: false) == true;
  }

  Future<void> setPushSoftPromptDone(bool value) async {
    if (_box == null) {
      _memorySoftPromptDone = value;
      return;
    }
    await _box.put(_keySoftPromptDone, value);
  }
}
