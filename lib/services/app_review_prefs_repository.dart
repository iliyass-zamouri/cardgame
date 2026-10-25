import 'package:hive_flutter/hive_flutter.dart';

/// Keeps the app from asking the server about the rating prompt after every
/// win. The real rules (cooldowns, minimum matches) live on the server; this
/// only spaces out the automatic checks.
class AppReviewPrefsRepository {
  AppReviewPrefsRepository._({Box<dynamic>? box, int? memoryLastCheckMs})
    : _box = box,
      _memoryLastCheckMs = memoryLastCheckMs;

  static const boxName = 'app_review_prefs';
  static const _keyLastCheckMs = 'lastCheckMs';
  static const checkInterval = Duration(hours: 6);

  final Box<dynamic>? _box;
  int? _memoryLastCheckMs;

  static Future<AppReviewPrefsRepository> open() async {
    final box = await Hive.openBox<dynamic>(boxName);
    return AppReviewPrefsRepository._(box: box);
  }

  /// In-memory repo for tests (no Hive).
  factory AppReviewPrefsRepository.memory({int? lastCheckMs}) {
    return AppReviewPrefsRepository._(memoryLastCheckMs: lastCheckMs);
  }

  int? get lastCheckMs {
    if (_box == null) return _memoryLastCheckMs;
    final value = _box.get(_keyLastCheckMs);
    if (value is int) return value;
    if (value is num) return value.toInt();
    return null;
  }

  bool mayCheck(DateTime now) {
    final last = lastCheckMs;
    if (last == null) return true;
    return now.millisecondsSinceEpoch - last >= checkInterval.inMilliseconds;
  }

  Future<void> markChecked(DateTime now) async {
    final ms = now.millisecondsSinceEpoch;
    if (_box == null) {
      _memoryLastCheckMs = ms;
      return;
    }
    await _box.put(_keyLastCheckMs, ms);
  }
}
