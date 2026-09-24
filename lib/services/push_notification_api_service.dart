import 'dart:convert';

import 'package:http/http.dart' as http;

class NotifyPrefs {
  const NotifyPrefs({
    required this.invites,
    required this.social,
    required this.ranking,
    required this.marketing,
  });

  const NotifyPrefs.allOn()
      : invites = true,
        social = true,
        ranking = true,
        marketing = true;

  factory NotifyPrefs.fromJson(Map<String, dynamic> json) {
    return NotifyPrefs(
      invites: json['invites'] as bool? ?? true,
      social: json['social'] as bool? ?? true,
      ranking: json['ranking'] as bool? ?? true,
      marketing: json['marketing'] as bool? ?? true,
    );
  }

  final bool invites;
  final bool social;
  final bool ranking;
  final bool marketing;

  NotifyPrefs copyWith({
    bool? invites,
    bool? social,
    bool? ranking,
    bool? marketing,
  }) {
    return NotifyPrefs(
      invites: invites ?? this.invites,
      social: social ?? this.social,
      ranking: ranking ?? this.ranking,
      marketing: marketing ?? this.marketing,
    );
  }

  Map<String, dynamic> toJson() => {
        'invites': invites,
        'social': social,
        'ranking': ranking,
        'marketing': marketing,
      };
}

class PlayerNotification {
  const PlayerNotification({
    required this.id,
    required this.type,
    required this.category,
    required this.title,
    required this.body,
    required this.data,
    required this.read,
    required this.createdAt,
  });

  factory PlayerNotification.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    return PlayerNotification(
      id: (json['id'] as num).toInt(),
      type: json['type'] as String? ?? 'unknown',
      category: json['category'] as String? ?? 'marketing',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      data: rawData is Map<String, dynamic>
          ? rawData
          : const <String, dynamic>{},
      read: json['read'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  final int id;
  final String type;
  final String category;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool read;
  final DateTime createdAt;

  PlayerNotification copyWith({bool? read}) {
    return PlayerNotification(
      id: id,
      type: type,
      category: category,
      title: title,
      body: body,
      data: data,
      read: read ?? this.read,
      createdAt: createdAt,
    );
  }
}

class NotificationsInbox {
  const NotificationsInbox({
    required this.notifications,
    required this.total,
    required this.unreadCount,
  });

  const NotificationsInbox.empty()
      : notifications = const [],
        total = 0,
        unreadCount = 0;

  factory NotificationsInbox.fromJson(Map<String, dynamic> json) {
    final raw = json['notifications'];
    final list = raw is List
        ? raw
            .whereType<Map<String, dynamic>>()
            .map(PlayerNotification.fromJson)
            .toList()
        : <PlayerNotification>[];
    return NotificationsInbox(
      notifications: list,
      total: (json['total'] as num?)?.toInt() ?? list.length,
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
    );
  }

  final List<PlayerNotification> notifications;
  final int total;
  final int unreadCount;
}

class PushApiException implements Exception {
  PushApiException(this.message, {this.statusCode, this.code});

  final String message;
  final int? statusCode;
  final String? code;

  @override
  String toString() => 'PushApiException($statusCode): $message';
}

class PushNotificationApiService {
  PushNotificationApiService({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Future<void> registerDevice({
    required String playerId,
    required String token,
    required String platform,
  }) async {
    await _postJson('/devices/register', {
      'playerId': playerId,
      'token': token,
      'platform': platform,
    });
  }

  Future<void> unregisterDevice({
    required String token,
    String? playerId,
  }) async {
    await _postJson('/devices/unregister', {
      'token': token,
      if (playerId != null && playerId.isNotEmpty) 'playerId': playerId,
    });
  }

  Future<NotifyPrefs> getNotifyPrefs(String playerId) async {
    final uri = Uri.parse(
      '$baseUrl/players/${Uri.encodeComponent(playerId)}/notify-prefs',
    );
    final response = await _client.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode == 404) {
      throw PushApiException(
        'Player not found',
        statusCode: 404,
        code: 'not_found',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PushApiException(
        response.body.isEmpty ? 'Prefs fetch failed' : response.body,
        statusCode: response.statusCode,
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw PushApiException('Invalid prefs response');
    }
    return NotifyPrefs.fromJson(decoded);
  }

  Future<NotifyPrefs> updateNotifyPrefs({
    required String playerId,
    bool? invites,
    bool? social,
    bool? ranking,
    bool? marketing,
  }) async {
    final body = <String, dynamic>{
      if (invites != null) 'invites': invites,
      if (social != null) 'social': social,
      if (ranking != null) 'ranking': ranking,
      if (marketing != null) 'marketing': marketing,
    };
    final decoded = await _postJson(
      '/players/${Uri.encodeComponent(playerId)}/notify-prefs',
      body,
    );
    return NotifyPrefs.fromJson(decoded);
  }

  Future<NotificationsInbox> listNotifications(
    String playerId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/players/${Uri.encodeComponent(playerId)}/notifications',
    ).replace(
      queryParameters: {
        'limit': '$limit',
        'offset': '$offset',
      },
    );
    final response = await _client.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode == 404) {
      throw PushApiException(
        'Player not found',
        statusCode: 404,
        code: 'not_found',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PushApiException(
        response.body.isEmpty ? 'Notifications fetch failed' : response.body,
        statusCode: response.statusCode,
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw PushApiException('Invalid notifications response');
    }
    return NotificationsInbox.fromJson(decoded);
  }

  Future<({int total, int unreadCount})> markNotificationsRead({
    required String playerId,
    List<int>? ids,
    bool all = false,
  }) async {
    final decoded = await _postJson(
      '/players/${Uri.encodeComponent(playerId)}/notifications/read',
      {
        if (all) 'all': true,
        if (ids != null) 'ids': ids,
      },
    );
    return (
      total: (decoded['total'] as num?)?.toInt() ?? 0,
      unreadCount: (decoded['unreadCount'] as num?)?.toInt() ?? 0,
    );
  }

  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _client
        .post(
          uri,
          headers: const {'content-type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 8));

    Map<String, dynamic>? decoded;
    if (response.body.isNotEmpty) {
      final raw = jsonDecode(response.body);
      if (raw is Map<String, dynamic>) decoded = raw;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PushApiException(
        decoded?['message'] as String? ??
            (response.body.isEmpty ? 'Request failed' : response.body),
        statusCode: response.statusCode,
        code: decoded?['error'] as String?,
      );
    }
    return decoded ?? <String, dynamic>{};
  }
}
