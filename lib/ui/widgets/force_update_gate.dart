import 'dart:io';

import 'package:cardgame/data/app/app_config_api.dart';
import 'package:cardgame/data/auth/auth_config.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Android-only force-update check against GET /app/config.
Future<void> checkForceUpdate(BuildContext context) async {
  if (kIsWeb || !Platform.isAndroid) return;
  try {
    final info = await PackageInfo.fromPlatform();
    final buildNumber = int.tryParse(info.buildNumber) ?? 0;
    final config = await AppConfigApi(baseUrl: httpBaseUrl).fetch();
    if (buildNumber >= config.minAndroidVersionCode) return;
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => PopScope(
            canPop: false,
            child: AlertDialog(
              backgroundColor: CasinoColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text(
                'Update required',
                style: TextStyle(
                  color: CasinoColors.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: const Text(
                'A newer version of the app is required to continue.',
                style: TextStyle(color: CasinoColors.textMuted),
              ),
              actions: [
                TextButton(
                  onPressed: () => SystemNavigator.pop(),
                  child: const Text(
                    'Exit',
                    style: TextStyle(color: CasinoColors.foldHi),
                  ),
                ),
              ],
            ),
          ),
    );
  } catch (e) {
    debugPrint('Force update check skipped: $e');
  }
}
