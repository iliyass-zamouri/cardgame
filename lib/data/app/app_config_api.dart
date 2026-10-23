import 'dart:convert';

import 'package:cardgame/data/app/app_theme_config.dart';
import 'package:cardgame/data/app/home_menu_config.dart';
import 'package:http/http.dart' as http;

class AppConfig {
  const AppConfig({
    this.minAndroidVersionCode = 0,
    this.minIosBuildNumber = 0,
    this.homeMenu,
    this.theme,
  });

  final int minAndroidVersionCode;
  final int minIosBuildNumber;

  /// Null when the server predates the dynamic home menu.
  final HomeMenuConfig? homeMenu;

  /// Null when the server predates colour themes.
  final AppThemeConfig? theme;

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      minAndroidVersionCode:
          (json['minAndroidVersionCode'] as num?)?.toInt() ?? 0,
      minIosBuildNumber: (json['minIosBuildNumber'] as num?)?.toInt() ?? 0,
      homeMenu: switch (json['homeMenu']) {
        final Map<String, dynamic> menu => HomeMenuConfig.fromJson(menu),
        _ => null,
      },
      theme: switch (json['theme']) {
        final Map<String, dynamic> theme => AppThemeConfig.tryFromJson(theme),
        _ => null,
      },
    );
  }
}

class AppConfigApi {
  AppConfigApi({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Future<AppConfig> fetch() async {
    final uri = Uri.parse('$baseUrl/app/config');
    final response = await _client.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('app/config failed: ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid app/config response');
    }
    return AppConfig.fromJson(decoded);
  }
}
