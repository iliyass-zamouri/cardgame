import 'package:hive_flutter/hive_flutter.dart';

/// Cooldown / dismissal prefs for the guest→Google link nudge.
class GuestLinkPrefsRepository {
  GuestLinkPrefsRepository._(this._box);

  static const boxName = 'guest_link_prefs';
  static const _keyLastShownMs = 'lastShownMs';
  static const _keyDontAskAgain = 'dontAskAgain';
  static const cooldown = Duration(days: 3);

  final Box<dynamic> _box;

  static Future<GuestLinkPrefsRepository> open() async {
    final box = await Hive.openBox<dynamic>(boxName);
    return GuestLinkPrefsRepository._(box);
  }

  bool get dontAskAgain =>
      _box.get(_keyDontAskAgain, defaultValue: false) == true;

  int? get lastShownMs {
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
    await _box.put(_keyLastShownMs, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> setDontAskAgain(bool value) async {
    await _box.put(_keyDontAskAgain, value);
    if (value) {
      await markShown();
    }
  }

  /// Stop nudging after successful link / switch.
  Future<void> clearAfterLinked() async {
    await _box.put(_keyDontAskAgain, true);
    await markShown();
  }
}
