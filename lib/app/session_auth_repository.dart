import 'package:cardgame/app/session_auth_status.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Persists only session gate (signed out vs in-app).
class SessionAuthRepository {
  SessionAuthRepository._(this._box, this._memory);

  static const boxName = 'session_auth';
  static const _keyStatus = 'status';

  final Box<dynamic>? _box;
  SessionAuthStatus? _memory;

  static Future<SessionAuthRepository> open() async {
    final box = await Hive.openBox<dynamic>(boxName);
    return SessionAuthRepository._(box, null);
  }

  /// In-memory repo for tests (no Hive).
  factory SessionAuthRepository.memory([
    SessionAuthStatus initial = SessionAuthStatus.signedOut,
  ]) {
    return SessionAuthRepository._(null, initial);
  }

  SessionAuthStatus load() {
    if (_memory != null) return _memory!;
    return SessionAuthStatus.fromStorage(_box!.get(_keyStatus) as String?);
  }

  Future<void> save(SessionAuthStatus status) async {
    if (_box == null) {
      _memory = status;
      return;
    }
    await _box.put(_keyStatus, status.storageValue);
  }
}
