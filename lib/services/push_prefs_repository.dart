import 'package:hive_flutter/hive_flutter.dart';

/// Persists soft-prompt dismissal for push permission.
class PushPrefsRepository {
  PushPrefsRepository._(this._box);

  static const boxName = 'push_prefs';
  static const _keySoftPromptDone = 'pushSoftPromptDone';

  final Box<dynamic> _box;

  static Future<PushPrefsRepository> open() async {
    final box = await Hive.openBox<dynamic>(boxName);
    return PushPrefsRepository._(box);
  }

  bool get pushSoftPromptDone =>
      _box.get(_keySoftPromptDone, defaultValue: false) == true;

  Future<void> setPushSoftPromptDone(bool value) async {
    await _box.put(_keySoftPromptDone, value);
  }
}
