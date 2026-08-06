import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

/// Stable install-scoped id for guest account matching (`local:<uuid-v4>`).
class DeviceIdentityService {
  DeviceIdentityService();

  static const boxName = 'device_identity';
  static const _keyGuestDeviceId = 'guestDeviceId';

  Future<DeviceFingerprint> fingerprint() async {
    final deviceId = await _stableGuestDeviceId();

    if (kIsWeb) {
      return DeviceFingerprint(deviceId: deviceId, platform: 'web');
    }

    // Avoid dart:io so this file works on web.
    return DeviceFingerprint(
      deviceId: deviceId,
      platform: defaultTargetPlatform.name.toLowerCase(),
    );
  }

  Future<String> deviceId() async => (await fingerprint()).deviceId;

  Future<String> _stableGuestDeviceId() async {
    final box = await Hive.openBox<dynamic>(boxName);
    final existing = box.get(_keyGuestDeviceId);
    if (existing is String && existing.trim().isNotEmpty) {
      return existing.trim();
    }
    final id = 'local:${const Uuid().v4()}';
    await box.put(_keyGuestDeviceId, id);
    return id;
  }
}

class DeviceFingerprint {
  const DeviceFingerprint({
    required this.deviceId,
    required this.platform,
    this.model,
  });

  final String deviceId;
  final String platform;
  final String? model;
}
