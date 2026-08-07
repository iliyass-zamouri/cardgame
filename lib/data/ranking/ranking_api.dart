/// Models and HTTP client for global ranking + match history.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

class RankingException implements Exception {
  RankingException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'RankingException($statusCode): $message';
}

class RankingEntry {
  const RankingEntry({
    required this.rank,
    required this.playerId,
    required this.name,
    required this.username,
    required this.elo,
    required this.totalPoints,
    required this.wins,
    required this.losses,
    required this.draws,
  });

  final int rank;
  final String playerId;
  final String? name;
  final String? username;
  final int elo;
  final int totalPoints;
  final int wins;
  final int losses;
  final int draws;

  String get displayName {
    final n = name?.trim();
    if (n != null && n.isNotEmpty) return n;
    final u = username?.trim();
    if (u != null && u.isNotEmpty) return u;
    return playerId;
  }

  factory RankingEntry.fromJson(Map<String, dynamic> json) {
    return RankingEntry(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      playerId: json['playerId'] as String? ?? '',
      name: json['name'] as String?,
      username: json['username'] as String?,
      elo: (json['elo'] as num?)?.toInt() ?? 0,
      totalPoints: (json['totalPoints'] as num?)?.toInt() ?? 0,
      wins: (json['wins'] as num?)?.toInt() ?? 0,
      losses: (json['losses'] as num?)?.toInt() ?? 0,
      draws: (json['draws'] as num?)?.toInt() ?? 0,
    );
  }
}

class MatchHistoryItem {
  const MatchHistoryItem({
    required this.matchId,
    required this.createdAt,
    required this.result,
    required this.cardTotal,
    required this.opponentName,
    required this.opponentCardTotal,
    required this.pointsEarned,
    required this.eloDelta,
    required this.eloAfter,
  });

  final String matchId;
  final DateTime? createdAt;
  final String result;
  final int cardTotal;
  final String opponentName;
  final int opponentCardTotal;
  final int pointsEarned;
  final int eloDelta;
  final int eloAfter;

  factory MatchHistoryItem.fromJson(Map<String, dynamic> json) {
    DateTime? createdAt;
    final raw = json['createdAt'];
    if (raw is String) {
      createdAt = DateTime.tryParse(raw);
    }
    return MatchHistoryItem(
      matchId: json['matchId'] as String? ?? '',
      createdAt: createdAt,
      result: json['result'] as String? ?? '',
      cardTotal: (json['cardTotal'] as num?)?.toInt() ?? 0,
      opponentName: json['opponentName'] as String? ?? 'Opponent',
      opponentCardTotal: (json['opponentCardTotal'] as num?)?.toInt() ?? 0,
      pointsEarned: (json['pointsEarned'] as num?)?.toInt() ?? 0,
      eloDelta: (json['eloDelta'] as num?)?.toInt() ?? 0,
      eloAfter: (json['eloAfter'] as num?)?.toInt() ?? 0,
    );
  }
}

class RankingApi {
  RankingApi({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Future<List<RankingEntry>> fetchLeaderboard({
    int limit = 50,
    int offset = 0,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/ranking',
    ).replace(queryParameters: {'limit': '$limit', 'offset': '$offset'});
    final response = await _client.get(uri).timeout(const Duration(seconds: 8));
    final body = _decodeMap(response);
    final entries = body['entries'];
    if (entries is! List) {
      throw RankingException('Invalid ranking response');
    }
    return entries
        .whereType<Map>()
        .map((e) => RankingEntry.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<RankingEntry?> fetchPlayerRank(String playerId) async {
    final uri = Uri.parse(
      '$baseUrl/ranking/player',
    ).replace(queryParameters: {'playerId': playerId});
    final response = await _client.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode == 404) return null;
    final body = _decodeMap(response);
    return RankingEntry.fromJson(body);
  }

  Future<List<MatchHistoryItem>> fetchMatchHistory({
    required String playerId,
    int limit = 20,
    int offset = 0,
  }) async {
    final uri = Uri.parse('$baseUrl/matches').replace(
      queryParameters: {
        'playerId': playerId,
        'limit': '$limit',
        'offset': '$offset',
      },
    );
    final response = await _client.get(uri).timeout(const Duration(seconds: 8));
    final body = _decodeMap(response);
    final matches = body['matches'];
    if (matches is! List) {
      throw RankingException('Invalid matches response');
    }
    return matches
        .whereType<Map>()
        .map((e) => MatchHistoryItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Map<String, dynamic> _decodeMap(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw RankingException(
        response.body.isEmpty ? 'Request failed' : response.body,
        statusCode: response.statusCode,
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw RankingException('Invalid JSON response');
    }
    return decoded;
  }
}
