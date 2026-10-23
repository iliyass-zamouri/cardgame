import 'package:cardgame/app/auth_providers.dart';
import 'package:cardgame/data/auth/auth_config.dart';
import 'package:cardgame/data/ranking/ranking_api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final rankingApiProvider = Provider<RankingApi>((ref) {
  return RankingApi(baseUrl: httpBaseUrl);
});

// Ranks and history only move when a match ends; the session controller
// invalidates them then. They watch [playerAuthProvider] rather than the whole
// profile so balance or cosmetic updates don't refetch them.

final leaderboardProvider = FutureProvider.autoDispose<List<RankingEntry>>((
  ref,
) async {
  final auth = ref.watch(playerAuthProvider);
  return ref
      .watch(rankingApiProvider)
      .fetchLeaderboard(accessToken: auth.accessToken);
});

final myRankProvider = FutureProvider.autoDispose<RankingEntry?>((ref) async {
  final playerId = ref.watch(playerAuthProvider).playerId;
  if (playerId.isEmpty) return null;
  return ref.watch(playerRankByIdProvider(playerId).future);
});

final playerRankByIdProvider = FutureProvider.autoDispose
    .family<RankingEntry?, String>((ref, playerId) async {
      if (playerId.isEmpty) return null;
      final auth = ref.watch(playerAuthProvider);
      return ref
          .watch(rankingApiProvider)
          .fetchPlayerRank(playerId, accessToken: auth.accessToken);
    });

final matchHistoryProvider = FutureProvider.autoDispose<List<MatchHistoryItem>>(
  (ref) async {
    final auth = ref.watch(playerAuthProvider);
    if (auth.playerId.isEmpty) return const [];
    return ref
        .watch(rankingApiProvider)
        .fetchMatchHistory(
          playerId: auth.playerId,
          accessToken: auth.accessToken,
        );
  },
);

/// Match history of any player (own or another player's profile).
final playerMatchesProvider = FutureProvider.autoDispose
    .family<List<MatchHistoryItem>, String>((ref, playerId) async {
      if (playerId.isEmpty) return const [];
      final auth = ref.watch(playerAuthProvider);
      return ref
          .watch(rankingApiProvider)
          .fetchMatchHistory(playerId: playerId, accessToken: auth.accessToken);
    });
