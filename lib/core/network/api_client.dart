import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/server_config.dart';

class ApiClient {
  ApiClient(this.config, {http.Client? client}) : _client = client ?? http.Client();

  final ServerConfig config;
  final http.Client _client;
  String? _token;

  void setToken(String? token) => _token = token;

  Map<String, String> get _headers => {
        'content-type': 'application/json',
        if (_token != null) 'authorization': 'Bearer $_token',
      };

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    String? idempotencyKey,
  }) async {
    final res = await _client.post(
      Uri.parse('${config.httpUrl}$path'),
      headers: {
        ..._headers,
        if (idempotencyKey != null) 'idempotency-key': idempotencyKey,
      },
      body: jsonEncode(body ?? {}),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> get(String path) async {
    final res = await _client.get(
      Uri.parse('${config.httpUrl}$path'),
      headers: _headers,
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final res = await _client.delete(
      Uri.parse('${config.httpUrl}$path'),
      headers: _headers,
    );
    return _decode(res);
  }

  Map<String, dynamic> _decode(http.Response res) {
    final body = res.body.isEmpty ? <String, dynamic>{} : jsonDecode(res.body);
    if (body is! Map) {
      throw StateError('Unexpected response');
    }
    final map = Map<String, dynamic>.from(body);
    if (res.statusCode >= 400) {
      throw ApiException(res.statusCode, map['message']?.toString() ?? 'error');
    }
    return map;
  }
}

class ApiException implements Exception {
  ApiException(this.status, this.message);
  final int status;
  final String message;

  @override
  String toString() => 'ApiException($status): $message';
}
