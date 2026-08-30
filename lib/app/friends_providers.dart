import 'dart:async';
import 'package:cardgame/app/auth_providers.dart';
import 'package:cardgame/data/auth/auth_config.dart';
import 'package:cardgame/data/friends/friends_api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final friendsApiServiceProvider = Provider<FriendsApi>((ref) {
  return FriendsApi(baseUrl: httpBaseUrl);
});

/// Friends data notifier providing friends, incoming, outgoing requests.
final friendsDataProvider =
    AsyncNotifierProvider<FriendsDataNotifier, FriendsData>(
      FriendsDataNotifier.new,
    );

class FriendsDataNotifier extends AsyncNotifier<FriendsData> {
  FriendsApi get _api => ref.read(friendsApiServiceProvider);

  @override
  Future<FriendsData> build() async {
    final profile = await ref.watch(playerProfileProvider.future);
    if (profile.isEmpty) {
      return const FriendsData(
        friends: [],
        incomingRequests: [],
        outgoingRequests: [],
      );
    }
    final data = await _api.getFriends(playerId: profile.playerId);
    // Sync online friend count
    ref.read(connectedFriendsCountProvider.notifier).setCount(data.onlineCount);
    return data;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final profile = await ref.read(playerProfileProvider.future);
      if (profile.isEmpty) {
        return const FriendsData(
          friends: [],
          incomingRequests: [],
          outgoingRequests: [],
        );
      }
      final data = await _api.getFriends(playerId: profile.playerId);
      ref
          .read(connectedFriendsCountProvider.notifier)
          .setCount(data.onlineCount);
      return data;
    });
  }

  Future<void> sendRequest({
    String? targetPlayerId,
    String? targetUsername,
  }) async {
    final profile = await ref.read(playerProfileProvider.future);
    if (profile.isEmpty) return;

    await _api.sendFriendRequest(
      playerId: profile.playerId,
      targetPlayerId: targetPlayerId,
      targetUsername: targetUsername,
    );
    await refresh();
  }

  Future<void> acceptRequest({String? requesterId, String? requestId}) async {
    final profile = await ref.read(playerProfileProvider.future);
    if (profile.isEmpty) return;

    await _api.acceptFriendRequest(
      playerId: profile.playerId,
      requesterId: requesterId,
      requestId: requestId,
    );
    await refresh();
  }

  Future<void> declineRequest({String? requesterId, String? requestId}) async {
    final profile = await ref.read(playerProfileProvider.future);
    if (profile.isEmpty) return;

    await _api.declineFriendRequest(
      playerId: profile.playerId,
      requesterId: requesterId,
      requestId: requestId,
    );
    await refresh();
  }

  Future<void> cancelRequest({
    String? targetPlayerId,
    String? requestId,
  }) async {
    final profile = await ref.read(playerProfileProvider.future);
    if (profile.isEmpty) return;

    await _api.cancelFriendRequest(
      playerId: profile.playerId,
      targetPlayerId: targetPlayerId,
      requestId: requestId,
    );
    await refresh();
  }

  Future<void> removeFriend({String? friendId, String? friendshipId}) async {
    final profile = await ref.read(playerProfileProvider.future);
    if (profile.isEmpty) return;

    await _api.removeFriend(
      playerId: profile.playerId,
      friendId: friendId,
      friendshipId: friendshipId,
    );
    await refresh();
  }
}

/// Player search state
class PlayerSearchState {
  const PlayerSearchState({
    this.query = '',
    this.results = const [],
    this.isLoading = false,
    this.error,
  });

  final String query;
  final List<SearchedPlayerItem> results;
  final bool isLoading;
  final String? error;

  PlayerSearchState copyWith({
    String? query,
    List<SearchedPlayerItem>? results,
    bool? isLoading,
    String? error,
  }) {
    return PlayerSearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final playerSearchProvider =
    NotifierProvider<PlayerSearchNotifier, PlayerSearchState>(
      PlayerSearchNotifier.new,
    );

class PlayerSearchNotifier extends Notifier<PlayerSearchState> {
  Timer? _debounceTimer;

  @override
  PlayerSearchState build() {
    ref.onDispose(() => _debounceTimer?.cancel());
    return const PlayerSearchState();
  }

  void onQueryChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      state = const PlayerSearchState();
      return;
    }

    state = state.copyWith(query: query, isLoading: true, error: null);
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _executeSearch(query.trim());
    });
  }

  Future<void> _executeSearch(String query) async {
    try {
      final profile = ref.read(playerProfileProvider).value;
      final api = ref.read(friendsApiServiceProvider);
      final results = await api.searchPlayers(
        query: query,
        playerId: profile?.playerId,
      );
      state = state.copyWith(results: results, isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(
        results: [],
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> sendRequestToUser(SearchedPlayerItem player) async {
    final profile = ref.read(playerProfileProvider).value;
    if (profile == null || profile.isEmpty) return;

    try {
      final api = ref.read(friendsApiServiceProvider);
      final res = await api.sendFriendRequest(
        playerId: profile.playerId,
        targetPlayerId: player.playerId,
      );
      final newStatus =
          res['status'] == 'accepted'
              ? FriendshipRelationship.accepted
              : FriendshipRelationship.pendingSent;

      // Update in search results
      final updatedResults =
          state.results.map((item) {
            if (item.playerId == player.playerId) {
              return item.copyWith(
                relationship: newStatus,
                friendshipId:
                    res['requestId'] as String? ??
                    res['friendshipId'] as String?,
              );
            }
            return item;
          }).toList();

      state = state.copyWith(results: updatedResults);
      // Also refresh friends data
      unawaited(ref.read(friendsDataProvider.notifier).refresh());
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> acceptUserRequest(SearchedPlayerItem player) async {
    final profile = ref.read(playerProfileProvider).value;
    if (profile == null || profile.isEmpty) return;

    try {
      final api = ref.read(friendsApiServiceProvider);
      await api.acceptFriendRequest(
        playerId: profile.playerId,
        requesterId: player.playerId,
      );

      final updatedResults =
          state.results.map((item) {
            if (item.playerId == player.playerId) {
              return item.copyWith(
                relationship: FriendshipRelationship.accepted,
              );
            }
            return item;
          }).toList();

      state = state.copyWith(results: updatedResults);
      unawaited(ref.read(friendsDataProvider.notifier).refresh());
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void clear() {
    _debounceTimer?.cancel();
    state = const PlayerSearchState();
  }
}

/// Number of connected/online friends.
final connectedFriendsCountProvider =
    NotifierProvider<ConnectedFriendsCountNotifier, int>(
      ConnectedFriendsCountNotifier.new,
    );

class ConnectedFriendsCountNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setCount(int count) => state = count;
}
