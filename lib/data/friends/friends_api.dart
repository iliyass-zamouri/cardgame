import 'dart:convert';
import 'package:http/http.dart' as http;

class FriendsApiException implements Exception {
  FriendsApiException(this.message, {this.statusCode, this.code});

  final String message;
  final int? statusCode;
  final String? code;

  @override
  String toString() => 'FriendsApiException($statusCode, $code): $message';
}

enum FriendshipRelationship {
  none,
  self,
  pendingSent,
  pendingReceived,
  accepted;

  static FriendshipRelationship fromString(String? val) {
    switch (val) {
      case 'self':
        return FriendshipRelationship.self;
      case 'pending_sent':
        return FriendshipRelationship.pendingSent;
      case 'pending_received':
        return FriendshipRelationship.pendingReceived;
      case 'accepted':
        return FriendshipRelationship.accepted;
      case 'none':
      default:
        return FriendshipRelationship.none;
    }
  }
}

class FriendItem {
  const FriendItem({
    required this.friendshipId,
    required this.playerId,
    required this.name,
    required this.username,
    required this.elo,
    required this.totalPoints,
    required this.wins,
    required this.losses,
    required this.draws,
    required this.isOnline,
    this.since,
  });

  final String friendshipId;
  final String playerId;
  final String name;
  final String username;
  final int elo;
  final int totalPoints;
  final int wins;
  final int losses;
  final int draws;
  final bool isOnline;
  final String? since;

  String get displayName => name.trim().isNotEmpty ? name.trim() : username;

  factory FriendItem.fromJson(Map<String, dynamic> json) {
    return FriendItem(
      friendshipId: json['friendshipId'] as String? ?? '',
      playerId: json['playerId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      elo: (json['elo'] as num?)?.toInt() ?? 1000,
      totalPoints: (json['totalPoints'] as num?)?.toInt() ?? 0,
      wins: (json['wins'] as num?)?.toInt() ?? 0,
      losses: (json['losses'] as num?)?.toInt() ?? 0,
      draws: (json['draws'] as num?)?.toInt() ?? 0,
      isOnline: json['isOnline'] == true,
      since: json['since'] as String?,
    );
  }
}

class FriendRequestItem {
  const FriendRequestItem({
    required this.requestId,
    required this.playerId,
    required this.name,
    required this.username,
    required this.elo,
    required this.totalPoints,
    required this.wins,
    required this.losses,
    required this.draws,
    required this.isOnline,
    this.createdAt,
  });

  final String requestId;
  final String playerId;
  final String name;
  final String username;
  final int elo;
  final int totalPoints;
  final int wins;
  final int losses;
  final int draws;
  final bool isOnline;
  final String? createdAt;

  String get displayName => name.trim().isNotEmpty ? name.trim() : username;

  factory FriendRequestItem.fromJson(Map<String, dynamic> json) {
    return FriendRequestItem(
      requestId: json['requestId'] as String? ?? '',
      playerId: json['playerId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      elo: (json['elo'] as num?)?.toInt() ?? 1000,
      totalPoints: (json['totalPoints'] as num?)?.toInt() ?? 0,
      wins: (json['wins'] as num?)?.toInt() ?? 0,
      losses: (json['losses'] as num?)?.toInt() ?? 0,
      draws: (json['draws'] as num?)?.toInt() ?? 0,
      isOnline: json['isOnline'] == true,
      createdAt: json['createdAt'] as String?,
    );
  }
}

class SearchedPlayerItem {
  const SearchedPlayerItem({
    required this.playerId,
    required this.name,
    required this.username,
    required this.elo,
    required this.totalPoints,
    required this.wins,
    required this.losses,
    required this.draws,
    required this.relationship,
    this.friendshipId,
    required this.isOnline,
  });

  final String playerId;
  final String name;
  final String username;
  final int elo;
  final int totalPoints;
  final int wins;
  final int losses;
  final int draws;
  final FriendshipRelationship relationship;
  final String? friendshipId;
  final bool isOnline;

  String get displayName => name.trim().isNotEmpty ? name.trim() : username;

  SearchedPlayerItem copyWith({
    FriendshipRelationship? relationship,
    String? friendshipId,
  }) {
    return SearchedPlayerItem(
      playerId: playerId,
      name: name,
      username: username,
      elo: elo,
      totalPoints: totalPoints,
      wins: wins,
      losses: losses,
      draws: draws,
      relationship: relationship ?? this.relationship,
      friendshipId: friendshipId ?? this.friendshipId,
      isOnline: isOnline,
    );
  }

  factory SearchedPlayerItem.fromJson(Map<String, dynamic> json) {
    return SearchedPlayerItem(
      playerId: json['playerId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      elo: (json['elo'] as num?)?.toInt() ?? 1000,
      totalPoints: (json['totalPoints'] as num?)?.toInt() ?? 0,
      wins: (json['wins'] as num?)?.toInt() ?? 0,
      losses: (json['losses'] as num?)?.toInt() ?? 0,
      draws: (json['draws'] as num?)?.toInt() ?? 0,
      relationship: FriendshipRelationship.fromString(
        json['relationship'] as String?,
      ),
      friendshipId: json['friendshipId'] as String?,
      isOnline: json['isOnline'] == true,
    );
  }
}

class FriendsData {
  const FriendsData({
    required this.friends,
    required this.incomingRequests,
    required this.outgoingRequests,
  });

  final List<FriendItem> friends;
  final List<FriendRequestItem> incomingRequests;
  final List<FriendRequestItem> outgoingRequests;

  int get onlineCount => friends.where((f) => f.isOnline).length;
}

class FriendsApi {
  FriendsApi({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Future<FriendsData> getFriends({required String playerId}) async {
    final uri = Uri.parse(
      '$baseUrl/friends',
    ).replace(queryParameters: {'playerId': playerId});
    final response = await _client.get(uri).timeout(const Duration(seconds: 8));
    final body = _decodeMap(response);

    final friendsList =
        (body['friends'] as List? ?? [])
            .whereType<Map>()
            .map((e) => FriendItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();

    final incomingList =
        (body['incomingRequests'] as List? ?? [])
            .whereType<Map>()
            .map(
              (e) => FriendRequestItem.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList();

    final outgoingList =
        (body['outgoingRequests'] as List? ?? [])
            .whereType<Map>()
            .map(
              (e) => FriendRequestItem.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList();

    return FriendsData(
      friends: friendsList,
      incomingRequests: incomingList,
      outgoingRequests: outgoingList,
    );
  }

  Future<List<SearchedPlayerItem>> searchPlayers({
    required String query,
    String? playerId,
    int limit = 20,
  }) async {
    final params = <String, String>{'query': query, 'limit': '$limit'};
    if (playerId != null && playerId.isNotEmpty) {
      params['playerId'] = playerId;
    }
    final uri = Uri.parse(
      '$baseUrl/friends/search',
    ).replace(queryParameters: params);
    final response = await _client.get(uri).timeout(const Duration(seconds: 8));
    final body = _decodeMap(response);
    final players =
        (body['players'] as List? ?? [])
            .whereType<Map>()
            .map(
              (e) => SearchedPlayerItem.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList();
    return players;
  }

  Future<Map<String, dynamic>> sendFriendRequest({
    required String playerId,
    String? targetPlayerId,
    String? targetUsername,
  }) async {
    final uri = Uri.parse('$baseUrl/friends/request');
    final response = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'playerId': playerId,
            if (targetPlayerId != null) 'targetPlayerId': targetPlayerId,
            if (targetUsername != null) 'targetUsername': targetUsername,
          }),
        )
        .timeout(const Duration(seconds: 8));
    return _decodeMap(response);
  }

  Future<void> acceptFriendRequest({
    required String playerId,
    String? requesterId,
    String? requestId,
  }) async {
    final uri = Uri.parse('$baseUrl/friends/accept');
    final response = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'playerId': playerId,
            if (requesterId != null) 'requesterId': requesterId,
            if (requestId != null) 'requestId': requestId,
          }),
        )
        .timeout(const Duration(seconds: 8));
    _decodeMap(response);
  }

  Future<void> declineFriendRequest({
    required String playerId,
    String? requesterId,
    String? requestId,
  }) async {
    final uri = Uri.parse('$baseUrl/friends/decline');
    final response = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'playerId': playerId,
            if (requesterId != null) 'requesterId': requesterId,
            if (requestId != null) 'requestId': requestId,
          }),
        )
        .timeout(const Duration(seconds: 8));
    _decodeMap(response);
  }

  Future<void> cancelFriendRequest({
    required String playerId,
    String? targetPlayerId,
    String? requestId,
  }) async {
    final uri = Uri.parse('$baseUrl/friends/cancel');
    final response = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'playerId': playerId,
            if (targetPlayerId != null) 'targetPlayerId': targetPlayerId,
            if (requestId != null) 'requestId': requestId,
          }),
        )
        .timeout(const Duration(seconds: 8));
    _decodeMap(response);
  }

  Future<void> removeFriend({
    required String playerId,
    String? friendId,
    String? friendshipId,
  }) async {
    final uri = Uri.parse('$baseUrl/friends/remove');
    final response = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'playerId': playerId,
            if (friendId != null) 'friendId': friendId,
            if (friendshipId != null) 'friendshipId': friendshipId,
          }),
        )
        .timeout(const Duration(seconds: 8));
    _decodeMap(response);
  }

  Map<String, dynamic> _decodeMap(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String msg = 'Request failed';
      String? code;
      try {
        final errJson = jsonDecode(response.body);
        if (errJson is Map) {
          msg = errJson['message'] as String? ?? msg;
          code = errJson['error'] as String?;
        }
      } catch (_) {}
      throw FriendsApiException(
        msg,
        statusCode: response.statusCode,
        code: code,
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw FriendsApiException('Invalid JSON response');
    }
    return decoded;
  }
}
