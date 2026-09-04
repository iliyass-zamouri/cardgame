import 'package:cardgame/app/friends_providers.dart';
import 'package:cardgame/data/friends/friends_api.dart';
import 'package:cardgame/l10n/l10n_ext.dart';
import 'package:cardgame/ui/screens/profile/player_profile_screen.dart';
import 'package:cardgame/ui/theme/casino_chrome.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/widgets/player_avatar.dart';
import 'package:cardgame/ui/widgets/suit_card_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final friendsAsync = ref.watch(friendsDataProvider);
    final incomingCount = friendsAsync.value?.incomingRequests.length ?? 0;

    return Scaffold(
      backgroundColor: CasinoColors.bg,
      appBar: AppBar(
        backgroundColor: CasinoColors.surface,
        foregroundColor: CasinoColors.text,
        elevation: 0,
        title: Text(
          l10n.friends,
          style: const TextStyle(
            color: CasinoColors.gold,
            fontWeight: FontWeight.w800,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: CasinoColors.gold,
          indicatorWeight: 3,
          labelColor: CasinoColors.gold,
          unselectedLabelColor: CasinoColors.textMuted,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          tabs: [
            Tab(text: l10n.friends),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.requests),
                  if (incomingCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: CasinoColors.raise,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$incomingCount',
                        style: const TextStyle(
                          color: CasinoColors.text,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(text: l10n.addFriend),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _FriendsListTab(onGoToAdd: () => _tabController.animateTo(2)),
          const _FriendRequestsTab(),
          const _SearchPlayersTab(),
        ],
      ),
    );
  }
}

class _FriendsListTab extends ConsumerWidget {
  const _FriendsListTab({required this.onGoToAdd});

  final VoidCallback onGoToAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final friendsAsync = ref.watch(friendsDataProvider);

    return friendsAsync.when(
      loading: () => const Center(child: SuitCardLoader(height: 32)),
      error:
          (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    err.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: CasinoColors.foldHi),
                  ),
                  const SizedBox(height: 12),
                  CasinoActionButton(
                    label: l10n.retryConnection,
                    tone: CasinoActionTone.raise,
                    expanded: false,
                    onPressed:
                        () => ref.read(friendsDataProvider.notifier).refresh(),
                  ),
                ],
              ),
            ),
          ),
      data: (data) {
        if (data.friends.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.people_outline_rounded,
                    size: 64,
                    color: CasinoColors.gold.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noFriendsYet,
                    style: const TextStyle(
                      color: CasinoColors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.noFriendsHint,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: CasinoColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 24),
                  CasinoActionButton(
                    label: l10n.addFriend,
                    icon: Icons.person_add_rounded,
                    tone: CasinoActionTone.raise,
                    expanded: false,
                    onPressed: onGoToAdd,
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          color: CasinoColors.gold,
          backgroundColor: CasinoColors.surface,
          onRefresh: () => ref.read(friendsDataProvider.notifier).refresh(),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: data.friends.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final friend = data.friends[index];
              return _FriendCard(friend: friend);
            },
          ),
        );
      },
    );
  }
}

class _FriendCard extends ConsumerWidget {
  const _FriendCard({required this.friend});

  final FriendItem friend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return Material(
      color: CasinoColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap:
            () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder:
                    (_) => PlayerProfileScreen(targetPlayerId: friend.playerId),
              ),
            ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: CasinoColors.surfaceHi),
          ),
          child: Row(
            children: [
              _PlayerAvatar(
                avatarId: friend.avatarId,
                isOnline: friend.isOnline,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            friend.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: CasinoColors.text,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: CasinoColors.bgElevated,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${friend.elo} ${l10n.elo}',
                            style: const TextStyle(
                              color: CasinoColors.goldSoft,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${friend.username}',
                      style: const TextStyle(
                        color: CasinoColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.recordWinsLossesDraws(
                        friend.wins,
                        friend.losses,
                        friend.draws,
                      ),
                      style: const TextStyle(
                        color: CasinoColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: CasinoColors.textMuted,
                ),
                color: CasinoColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (val) async {
                  if (val == 'remove') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder:
                          (ctx) => AlertDialog(
                            backgroundColor: CasinoColors.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            title: Text(
                              l10n.removeFriend,
                              style: const TextStyle(
                                color: CasinoColors.text,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            content: Text(
                              l10n.removeFriendConfirm(friend.displayName),
                              style: const TextStyle(
                                color: CasinoColors.textMuted,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: Text(
                                  l10n.cancel,
                                  style: const TextStyle(
                                    color: CasinoColors.textMuted,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: Text(
                                  l10n.removeFriend,
                                  style: const TextStyle(
                                    color: CasinoColors.foldHi,
                                  ),
                                ),
                              ),
                            ],
                          ),
                    );
                    if (confirm == true) {
                      await ref
                          .read(friendsDataProvider.notifier)
                          .removeFriend(
                            friendId: friend.playerId,
                            friendshipId: friend.friendshipId,
                          );
                    }
                  }
                },
                itemBuilder:
                    (ctx) => [
                      PopupMenuItem(
                        value: 'remove',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.person_remove_rounded,
                              color: CasinoColors.foldHi,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.removeFriend,
                              style: const TextStyle(
                                color: CasinoColors.foldHi,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FriendRequestsTab extends ConsumerWidget {
  const _FriendRequestsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final friendsAsync = ref.watch(friendsDataProvider);

    return friendsAsync.when(
      loading: () => const Center(child: SuitCardLoader(height: 32)),
      error:
          (err, _) => Center(
            child: Text(
              err.toString(),
              style: const TextStyle(color: CasinoColors.foldHi),
            ),
          ),
      data: (data) {
        final incoming = data.incomingRequests;
        final outgoing = data.outgoingRequests;

        if (incoming.isEmpty && outgoing.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.mail_outline_rounded,
                    size: 56,
                    color: CasinoColors.gold.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noRequests,
                    style: const TextStyle(
                      color: CasinoColors.textMuted,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          color: CasinoColors.gold,
          backgroundColor: CasinoColors.surface,
          onRefresh: () => ref.read(friendsDataProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              if (incoming.isNotEmpty) ...[
                Text(
                  l10n.incomingRequests.toUpperCase(),
                  style: const TextStyle(
                    color: CasinoColors.goldSoft,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                ...incoming.map((req) => _IncomingRequestCard(request: req)),
                const SizedBox(height: 24),
              ],
              if (outgoing.isNotEmpty) ...[
                Text(
                  l10n.outgoingRequests.toUpperCase(),
                  style: const TextStyle(
                    color: CasinoColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                ...outgoing.map((req) => _OutgoingRequestCard(request: req)),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _IncomingRequestCard extends ConsumerWidget {
  const _IncomingRequestCard({required this.request});

  final FriendRequestItem request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CasinoColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CasinoColors.surfaceHi),
      ),
      child: Row(
        children: [
          _PlayerAvatar(
            avatarId: request.avatarId,
            isOnline: request.isOnline,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: CasinoColors.text,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                Text(
                  '@${request.username}',
                  style: const TextStyle(
                    color: CasinoColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: CasinoColors.foldHi),
            tooltip: l10n.decline,
            onPressed: () {
              ref
                  .read(friendsDataProvider.notifier)
                  .declineRequest(
                    requesterId: request.playerId,
                    requestId: request.requestId,
                  );
            },
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(
              Icons.check_circle_rounded,
              color: CasinoColors.raiseHi,
              size: 28,
            ),
            tooltip: l10n.accept,
            onPressed: () {
              ref
                  .read(friendsDataProvider.notifier)
                  .acceptRequest(
                    requesterId: request.playerId,
                    requestId: request.requestId,
                  );
            },
          ),
        ],
      ),
    );
  }
}

class _OutgoingRequestCard extends ConsumerWidget {
  const _OutgoingRequestCard({required this.request});

  final FriendRequestItem request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CasinoColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CasinoColors.surfaceHi),
      ),
      child: Row(
        children: [
          _PlayerAvatar(
            avatarId: request.avatarId,
            isOnline: request.isOnline,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: CasinoColors.text,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                Text(
                  '@${request.username}',
                  style: const TextStyle(
                    color: CasinoColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(friendsDataProvider.notifier)
                  .cancelRequest(
                    targetPlayerId: request.playerId,
                    requestId: request.requestId,
                  );
            },
            child: Text(
              l10n.cancel,
              style: const TextStyle(
                color: CasinoColors.textMuted,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchPlayersTab extends ConsumerStatefulWidget {
  const _SearchPlayersTab();

  @override
  ConsumerState<_SearchPlayersTab> createState() => _SearchPlayersTabState();
}

class _SearchPlayersTabState extends ConsumerState<_SearchPlayersTab> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final searchState = ref.watch(playerSearchProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            style: const TextStyle(color: CasinoColors.text),
            decoration: InputDecoration(
              hintText: l10n.searchByUsername,
              hintStyle: const TextStyle(color: CasinoColors.textMuted),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: CasinoColors.goldSoft,
              ),
              suffixIcon:
                  _searchController.text.isNotEmpty
                      ? IconButton(
                        icon: const Icon(
                          Icons.clear_rounded,
                          color: CasinoColors.textMuted,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(playerSearchProvider.notifier).clear();
                        },
                      )
                      : null,
              fillColor: CasinoColors.surface,
              filled: true,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: CasinoColors.surfaceHi),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: CasinoColors.gold,
                  width: 1.5,
                ),
              ),
            ),
            onChanged: (val) {
              ref.read(playerSearchProvider.notifier).onQueryChanged(val);
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Builder(
              builder: (context) {
                if (searchState.isLoading) {
                  return const Center(child: SuitCardLoader(height: 32));
                }
                if (searchState.error != null) {
                  return Center(
                    child: Text(
                      searchState.error!,
                      style: const TextStyle(color: CasinoColors.foldHi),
                    ),
                  );
                }
                if (searchState.query.isNotEmpty &&
                    searchState.results.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.noPlayersFound,
                      style: const TextStyle(
                        color: CasinoColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                  );
                }
                if (searchState.results.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.searchByUsername,
                      style: const TextStyle(
                        color: CasinoColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: searchState.results.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = searchState.results[index];
                    return _SearchResultCard(player: item);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchResultCard extends ConsumerWidget {
  const _SearchResultCard({required this.player});

  final SearchedPlayerItem player;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    Widget actionButton;
    switch (player.relationship) {
      case FriendshipRelationship.self:
        actionButton = Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: CasinoColors.bgElevated,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            l10n.youTag,
            style: const TextStyle(
              color: CasinoColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
        break;
      case FriendshipRelationship.accepted:
        actionButton = Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: CasinoColors.raise.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: CasinoColors.raiseHi.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_rounded,
                color: CasinoColors.raiseHi,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                l10n.alreadyFriends,
                style: const TextStyle(
                  color: CasinoColors.raiseHi,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
        break;
      case FriendshipRelationship.pendingSent:
        actionButton = Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: CasinoColors.bgElevated,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            l10n.requestSent,
            style: const TextStyle(
              color: CasinoColors.goldSoft,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
        break;
      case FriendshipRelationship.pendingReceived:
        actionButton = CasinoActionButton(
          label: l10n.accept,
          icon: Icons.check_rounded,
          tone: CasinoActionTone.raise,
          expanded: false,
          height: 38,
          onPressed: () {
            ref.read(playerSearchProvider.notifier).acceptUserRequest(player);
          },
        );
        break;
      case FriendshipRelationship.none:
        actionButton = CasinoActionButton(
          label: l10n.addFriend,
          icon: Icons.person_add_rounded,
          tone: CasinoActionTone.gold,
          expanded: false,
          height: 38,
          onPressed: () {
            ref.read(playerSearchProvider.notifier).sendRequestToUser(player);
          },
        );
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CasinoColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CasinoColors.surfaceHi),
      ),
      child: Row(
        children: [
          _PlayerAvatar(
            avatarId: player.avatarId,
            isOnline: player.isOnline,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        player.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: CasinoColors.text,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: CasinoColors.bgElevated,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${player.elo} ${l10n.elo}',
                        style: const TextStyle(
                          color: CasinoColors.goldSoft,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  '@${player.username}',
                  style: const TextStyle(
                    color: CasinoColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          actionButton,
        ],
      ),
    );
  }
}

class _PlayerAvatar extends StatelessWidget {
  const _PlayerAvatar({required this.isOnline, this.avatarId = 'default'});

  final bool isOnline;
  final String avatarId;

  @override
  Widget build(BuildContext context) {
    return PlayerAvatar(
      avatarId: avatarId,
      size: 44,
      statusDotColor: isOnline ? const Color(0xFF7ED50E) : CasinoColors.foldHi,
    );
  }
}
