import 'package:cardgame/app/auth_providers.dart';
import 'package:cardgame/app/player_profile_repository.dart';
import 'package:cardgame/data/auth/auth_config.dart';
import 'package:cardgame/data/ranking/ranking_api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final rankingApiProvider = Provider<RankingApi>((ref) {
  return RankingApi(baseUrl: httpBaseUrl);
});

final leaderboardProvider = FutureProvider.autoDispose<List<RankingEntry>>((
  ref,
) async {
  return ref.watch(rankingApiProvider).fetchLeaderboard();
});

final myRankProvider = FutureProvider.autoDispose<RankingEntry?>((ref) async {
  final profile = ref.watch(playerProfileProvider).value ?? PlayerProfile.empty;
  if (profile.playerId.isEmpty) return null;
  return ref.watch(playerRankByIdProvider(profile.playerId).future);
});

final playerRankByIdProvider = FutureProvider.autoDispose
    .family<RankingEntry?, String>((ref, playerId) async {
      if (playerId.isEmpty) return null;
      return ref.watch(rankingApiProvider).fetchPlayerRank(playerId);
    });

final matchHistoryProvider = FutureProvider.autoDispose<List<MatchHistoryItem>>(
  (ref) async {
    final profile =
        ref.watch(playerProfileProvider).value ?? PlayerProfile.empty;
    if (profile.playerId.isEmpty) return const [];
    return ref
        .watch(rankingApiProvider)
        .fetchMatchHistory(playerId: profile.playerId);
  },
);
