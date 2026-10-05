import 'dart:io';

/// Marketing-capture build: `--dart-define=TRAILER_SHOT=<shot>`.
///
/// When set, a scripted director plays the real app (offline vs Robot) so
/// gameplay can be screen-recorded for store videos. Never set in shipping
/// builds; everything trailer-only compiles away when empty.
abstract final class TrailerMode {
  static const shot = String.fromEnvironment('TRAILER_SHOT');
  static const enabled = shot != '';

  /// Stake pool shown on offline tables so takes can feature each city.
  static int stakePool = 0;

  /// Written from the host so one build can record every take, e.g.
  /// `shot=match stake=1000`. iOS simulator: `<data container>/Documents/`.
  static List<String> get _configPaths => [
    '${Directory.systemTemp.parent.path}/Documents/trailer.txt',
    '${Platform.environment['HOME'] ?? ''}/Documents/trailer.txt',
  ];

  /// Shot config: the device file wins over the compile-time [shot].
  static Future<Map<String, String>> loadConfig() async {
    final config = <String, String>{'shot': shot};
    for (final path in _configPaths) {
      try {
        final file = File(path);
        if (!await file.exists()) continue;
        for (final pair in (await file.readAsString()).split(RegExp(r'\s+'))) {
          final i = pair.indexOf('=');
          if (i > 0) config[pair.substring(0, i)] = pair.substring(i + 1);
        }
        break;
      } catch (_) {}
    }
    return config;
  }
}
