import 'package:hive_flutter/hive_flutter.dart';

/// Cooldown / dismissal prefs for the guest→Google link nudge.
class GuestLinkPrefsRepository {
  GuestLinkPrefsRepository._({
    Box<dynamic>? box,
    bool? memoryDontAsk,
    int? memoryLastShownMs,
  }) : _box = box,
       _memoryDontAsk = memoryDontAsk,
       _memoryLastShownMs = memoryLastShownMs;

  static const boxName = 'guest_link_prefs';
  static const _keyLastShownMs = 'lastShownMs';
  static const _keyDontAskAgain = 'dontAskAgain';
  static const cooldown = Duration(days: 3);

  final Box<dynamic>? _box;
  bool? _memoryDontAsk;
  int? _memoryLastShownMs;

  static Future<GuestLinkPrefsRepository> open() async {
    final box = await Hive.openBox<dynamic>(boxName);
    return GuestLinkPrefsRepository._(box: box);
  }

  /// In-memory repo for tests (no Hive). Defaults to not nudging.
  factory GuestLinkPrefsRepository.memory({bool dontAskAgain = true}) {
    return GuestLinkPrefsRepository._(
      memoryDontAsk: dontAskAgain,
      memoryLastShownMs: DateTime.now().millisecondsSinceEpoch,
    );
  }

  bool get dontAskAgain {
    if (_box == null) return _memoryDontAsk ?? false;
    return _box.get(_keyDontAskAgain, defaultValue: false) == true;
  }

  int? get lastShownMs {
    if (_box == null) return _memoryLastShownMs;
    final value = _box.get(_keyLastShownMs);
    if (value is int) return value;
    if (value is num) return value.toInt();
    return null;
  }

  bool get shouldShowNudge {
    if (dontAskAgain) return false;
    final last = lastShownMs;
    if (last == null) return true;
    final elapsed = DateTime.now().millisecondsSinceEpoch - last;
    return elapsed >= cooldown.inMilliseconds;
  }

  Future<void> markShown() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_box == null) {
      _memoryLastShownMs = now;
      return;
    }
    await _box.put(_keyLastShownMs, now);
  }

  Future<void> setDontAskAgain(bool value) async {
    if (_box == null) {
      _memoryDontAsk = value;
      if (value) await markShown();
      return;
    }
    await _box.put(_keyDontAskAgain, value);
    if (value) {
      await markShown();
    }
  }

  /// Stop nudging after successful link / switch.
  Future<void> clearAfterLinked() async {
    await setDontAskAgain(true);
  }
}
