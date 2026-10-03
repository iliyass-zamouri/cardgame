import 'dart:convert';

import 'package:http/http.dart' as http;

class AppConfig {
  const AppConfig({
    this.minAndroidVersionCode = 0,
    this.minIosBuildNumber = 0,
  });

  final int minAndroidVersionCode;
  final int minIosBuildNumber;

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      minAndroidVersionCode:
          (json['minAndroidVersionCode'] as num?)?.toInt() ?? 0,
      minIosBuildNumber: (json['minIosBuildNumber'] as num?)?.toInt() ?? 0,
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
