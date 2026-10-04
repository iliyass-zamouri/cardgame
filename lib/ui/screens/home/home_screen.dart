import 'dart:async';

import 'package:cardgame/ads/interstitial_ad_service.dart';
import 'package:cardgame/app/auth_providers.dart';
import 'package:cardgame/app/friends_providers.dart';
import 'package:cardgame/app/game_session_controller.dart';
import 'package:cardgame/app/game_session_state.dart';
import 'package:cardgame/app/ranking_providers.dart';
import 'package:cardgame/data/friends/friends_api.dart';
import 'package:cardgame/domain/models/game_snapshot.dart';
import 'package:cardgame/l10n/l10n_ext.dart';
import 'package:cardgame/services/sfx_service.dart';
import 'package:cardgame/ui/flame/card_back_skins.dart';
import 'package:cardgame/ui/flame/card_game_view.dart';
import 'package:cardgame/ui/flame/suit_shapes.dart';
import 'package:cardgame/ui/screens/friends_screen.dart';
import 'package:cardgame/ui/screens/home/game_over_panel.dart';
import 'package:cardgame/ui/screens/home/game_starter.dart';
import 'package:cardgame/ui/screens/home/home_menu_widgets.dart';
import 'package:cardgame/ui/screens/how_to_play_screen.dart';
import 'package:cardgame/ui/theme/casino_chrome.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/theme/city_theme.dart';
import 'package:cardgame/ui/theme/felt_chrome.dart';
import 'package:cardgame/ui/widgets/currency_icon.dart';
import 'package:cardgame/ui/widgets/player_avatar.dart';
import 'package:cardgame/ui/widgets/suit_card_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:cardgame/ui/theme/app_icons.dart';

export 'package:cardgame/ui/screens/home/game_over_panel.dart'
    show GameOverPanel;

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<String?>(gameSessionProvider.select((state) => state.message), (
      previous,
      message,
    ) {
      if (message == null || message == previous) return;
      CasinoToast.show(
        context,
        localizeErrorCode(context.l10n, message),
        success: false,
      );
      ref.read(gameSessionProvider.notifier).clearMessage();
    });

    ref.listen<GameStatus?>(
      gameSessionProvider.select((state) => state.game?.status),
      (previous, next) {
        if (next == GameStatus.playing && previous != GameStatus.playing) {
          unawaited(SfxService.instance.playMatchStart());
        }
      },
    );

    ref.listen<TableInviteNotification?>(
      gameSessionProvider.select((state) => state.incomingInvite),
      (previous, invite) {
        if (invite == null || invite == previous) return;
        final l10n = context.l10n;
        final notifier = ref.read(gameSessionProvider.notifier);

        CasinoToast.show(
          context,
          l10n.tableInviteFrom(invite.inviterName, invite.roomId),
          actionLabel: l10n.joinTable,
          onAction: () => notifier.acceptIncomingInvite(invite.roomId),
          onDismiss: notifier.dismissIncomingInvite,
        );
      },
    );

    ref.listen<FriendAlertNotification?>(
      gameSessionProvider.select((state) => state.friendAlert),
      (previous, alert) {
        if (alert == null || alert == previous) return;
        final l10n = context.l10n;
        final session = ref.read(gameSessionProvider.notifier);
        if (alert.kind == 'accepted') {
          CasinoToast.show(
            context,
            l10n.friendRequestAcceptedBy(alert.playerName),
          );
        } else {
          CasinoToast.show(
            context,
            l10n.friendRequestFrom(alert.playerName),
            actionLabel: l10n.accept,
            onAction: () async {
              try {
                await ref
                    .read(friendsDataProvider.notifier)
                    .acceptRequest(
                      requesterId: alert.playerId,
                      requestId: alert.requestId,
                    );
                if (context.mounted) {
                  CasinoToast.show(context, l10n.friendRequestAccepted);
                }
              } catch (_) {
                // Request may already be gone; friends list refresh still runs.
              }
            },
          );
        }
        session.clearFriendAlert();
      },
    );

    final session = ref.watch(gameSessionProvider);
    final game = session.game;
    if (session.searchingMatch && game == null) {
      return const MatchmakingWaiting();
    }
    if (game == null) return const StartGameWidget();
    if (game.status == GameStatus.waiting) {
      return WaitingRoom(game: game);
    }
    return const GameBoard();
  }
}

class MatchmakingWaiting extends ConsumerStatefulWidget {
  const MatchmakingWaiting({super.key});

  @override
  ConsumerState<MatchmakingWaiting> createState() => _MatchmakingWaitingState();
}

class _MatchmakingWaitingState extends ConsumerState<MatchmakingWaiting> {
  @override
  void initState() {
    super.initState();
    unawaited(SfxService.instance.startSearch());
    // Show interstitial while queue search runs in background.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(ref.read(interstitialAdProvider).show());
    });
  }

  @override
  void dispose() {
    unawaited(SfxService.instance.stopSearch());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final notifier = ref.read(gameSessionProvider.notifier);
    final deckId =
        ref.watch(playerProfileProvider).value?.deckId ??
        CardBackSkins.activeId;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                HeroCardFan(deckSkinId: deckId, height: 200),
                const SizedBox(height: 12),
                const SuitCardLoader(height: 32),
                const SizedBox(height: 20),
                Text(
                  l10n.findingOpponent,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: CasinoColors.gold,
                    fontSize: 26,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.matchmakingHint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: CasinoColors.textMuted,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 36),
                CasinoActionButton(
                  label: l10n.cancel,
                  tone: CasinoActionTone.fold,
                  expanded: false,
                  onPressed: notifier.cancelFindMatch,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class WaitingRoom extends ConsumerWidget {
  final GameSnapshot game;

  const WaitingRoom({super.key, required this.game});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final notifier = ref.read(gameSessionProvider.notifier);
    final bothJoined = game.ready;
    final youReady = game.you.lobbyReady;
    final opponentReady = game.opponent?.lobbyReady ?? false;
    final yourName = game.you.displayName;
    final opponentName =
        game.opponent?.displayName ?? l10n.waitingEllipsisShort;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (bothJoined) const Spacer(flex: 1),
              Text(
                l10n.privateTable,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: CasinoColors.gold,
                  fontSize: 24,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                bothJoined
                    ? (youReady && !opponentReady
                        ? l10n.waitingForOpponentNamed(opponentName)
                        : !youReady && opponentReady
                        ? l10n.opponentIsReady(opponentName)
                        : l10n.bothPlayersJoined)
                    : l10n.shareCodeWithFriend,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:
                      bothJoined
                          ? CasinoColors.raiseHi
                          : CasinoColors.textMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              if (bothJoined && youReady && !opponentReady) ...[
                const SizedBox(height: 16),
                const Center(child: SuitCardLoader(height: 24)),
              ],
              const SizedBox(height: 16),
              if (bothJoined) ...[
                Row(
                  children: [
                    Expanded(
                      child: _LobbySeat(
                        name: yourName,
                        connected: game.you.connected,
                        ready: youReady,
                        isYou: true,
                        avatarId: game.you.avatarId,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        l10n.vs,
                        style: const TextStyle(
                          color: CasinoColors.goldSoft,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _LobbySeat(
                        name: opponentName,
                        connected: game.opponent?.connected ?? false,
                        ready: opponentReady,
                        isYou: false,
                        avatarId: game.opponent?.avatarId ?? 'default',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
              GestureDetector(
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: game.roomId));
                  if (!context.mounted) return;
                  CasinoToast.show(context, context.l10n.codeCopied);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: bothJoined ? 12 : 18,
                    horizontal: 12,
                  ),
                  decoration: feltPanelDecoration(highlighted: true),
                  child: Column(
                    children: [
                      Semantics(
                        label: game.roomId,
                        child: _RoomCodeCards(
                          code: game.roomId,
                          cardHeight: bothJoined ? 52 : 68,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.tapToCopy,
                        style: const TextStyle(
                          color: CasinoColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!bothJoined) ...[
                const SizedBox(height: 16),
                Expanded(child: _InviteFriendsSection(roomId: game.roomId)),
                const SizedBox(height: 12),
              ] else ...[
                const Spacer(flex: 2),
              ],
              Row(
                children: [
                  CasinoActionButton(
                    label: youReady ? l10n.waitingEllipsis : l10n.ready,
                    icon: youReady ? AppIcons.hourglass : AppIcons.check,
                    tone: CasinoActionTone.raise,
                    onPressed:
                        bothJoined && !youReady ? notifier.readyUp : null,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: notifier.leaveRoom,
                  style: TextButton.styleFrom(
                    foregroundColor: CasinoColors.textMuted,
                  ),
                  child: Text(l10n.leaveRoom),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InviteFriendsSection extends ConsumerWidget {
  const _InviteFriendsSection({required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final friendsAsync = ref.watch(friendsDataProvider);
    final sentInviteIds = ref.watch(
      gameSessionProvider.select((s) => s.sentInvitePlayerIds),
    );

    return Container(
      decoration: feltPanelDecoration(),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const HugeIcon(
                icon: AppIcons.people,
                size: 16,
                color: CasinoColors.gold,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.inviteFriends,
                style: const TextStyle(
                  color: CasinoColors.gold,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              friendsAsync.when(
                data: (data) {
                  final online = data.onlineCount;
                  if (online == 0) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7ED50E).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF7ED50E).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF7ED50E),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '$online ${l10n.online}',
                          style: const TextStyle(
                            color: Color(0xFF7ED50E),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: friendsAsync.when(
              loading: () => const Center(child: SuitCardLoader(height: 20)),
              error:
                  (_, __) => Center(
                    child: Text(
                      l10n.rankingLoadError,
                      style: const TextStyle(
                        color: CasinoColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ),
              data: (data) {
                if (data.friends.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.noFriendsToInvite,
                          style: const TextStyle(
                            color: CasinoColors.textMuted,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const FriendsScreen(),
                              ),
                            );
                          },
                          child: Text(
                            l10n.addFriend,
                            style: const TextStyle(
                              color: CasinoColors.gold,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final sortedFriends = List<FriendItem>.from(data.friends)
                  ..sort((a, b) {
                    if (a.isOnline && !b.isOnline) return -1;
                    if (!a.isOnline && b.isOnline) return 1;
                    return a.displayName.compareTo(b.displayName);
                  });

                return ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: sortedFriends.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final friend = sortedFriends[index];
                    final isInvited = sentInviteIds.contains(friend.playerId);

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: CasinoColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: CasinoColors.surfaceHi),
                      ),
                      child: Row(
                        children: [
                          PlayerAvatar(
                            avatarId: friend.avatarId,
                            size: 34,
                            borderWidth: 1.2,
                            borderColor:
                                friend.isOnline
                                    ? const Color(0xFF7ED50E)
                                    : Colors.white24,
                            statusDotColor:
                                friend.isOnline
                                    ? const Color(0xFF7ED50E)
                                    : CasinoColors.textMuted,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  friend.displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: CasinoColors.text,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (friend.username.isNotEmpty)
                                  Text(
                                    '@${friend.username}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: CasinoColors.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isInvited)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: CasinoColors.gold.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: CasinoColors.gold.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const HugeIcon(
                                    icon: AppIcons.check,
                                    size: 14,
                                    color: CasinoColors.gold,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    l10n.invited,
                                    style: const TextStyle(
                                      color: CasinoColors.gold,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    friend.isOnline
                                        ? CasinoColors.raise
                                        : CasinoColors.surfaceHi,
                                foregroundColor: CasinoColors.text,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                              onPressed: () {
                                ref
                                    .read(gameSessionProvider.notifier)
                                    .sendTableInvite(
                                      targetPlayerId: friend.playerId,
                                      roomId: roomId,
                                    );
                                CasinoToast.show(
                                  context,
                                  '${l10n.inviteSent} (${friend.displayName})',
                                  duration: const Duration(seconds: 2),
                                );
                              },
                              child: Text(
                                l10n.invite,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
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

class _LobbySeat extends StatelessWidget {
  const _LobbySeat({
    required this.name,
    required this.connected,
    required this.ready,
    required this.isYou,
    this.avatarId = 'default',
  });

  final String name;
  final bool connected;
  final bool ready;
  final bool isYou;
  final String avatarId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 64,
          height: 64,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              PlayerAvatar(
                avatarId: avatarId,
                size: 64,
                borderWidth: ready ? 2.5 : 1.5,
                borderColor: ready ? CasinoColors.gold : Colors.white24,
                statusDotColor:
                    connected ? const Color(0xFF7ED50E) : CasinoColors.foldHi,
              ),
              if (ready)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: CasinoColors.raise,
                    ),
                    child: const HugeIcon(
                      icon: AppIcons.check,
                      size: 14,
                      color: CasinoColors.text,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ready ? CasinoColors.gold : CasinoColors.text,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          isYou ? l10n.you : (ready ? l10n.ready : l10n.notReady),
          style: const TextStyle(
            color: CasinoColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class GameBoard extends ConsumerStatefulWidget {
  const GameBoard({super.key});

  @override
  ConsumerState<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends ConsumerState<GameBoard> {
  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(
      gameSessionProvider.select(
        (state) => state.game?.status == GameStatus.ended,
      ),
      (previous, ended) {
        if (ended && previous != true) {
          SfxService.instance.cancelScheduledChangeTurn();
          unawaited(ref.read(interstitialAdProvider).show());
          ref.read(playerProfileProvider.notifier).refreshInventory().ignore();
          final game = ref.read(gameSessionProvider).game;
          final oppTotal = game?.opponent?.total;
          if (game != null && oppTotal != null) {
            if (game.you.total < oppTotal) {
              SfxService.instance.win();
            } else if (game.you.total > oppTotal) {
              SfxService.instance.lose();
            }
          }
        }
      },
    );

    ref.listen<bool?>(
      gameSessionProvider.select((state) {
        final game = state.game;
        if (game == null || game.status != GameStatus.playing) return null;
        return game.isYourTurn;
      }),
      (previous, next) {
        // Only cue when turn comes back to the local player.
        if (previous != false || next != true) return;
        SfxService.instance.scheduleChangeTurn();
      },
    );

    ref.listen<LaunchStatus?>(
      gameSessionProvider.select((state) => state.game?.you.launch),
      (previous, next) {
        if (next == LaunchStatus.launched &&
            previous == LaunchStatus.notLaunched) {
          SfxService.instance.reveal();
        }
      },
    );

    final ended = ref.watch(
      gameSessionProvider.select(
        (state) => state.game?.status == GameStatus.ended,
      ),
    );
    final city = ref.watch(
      gameSessionProvider.select(
        (state) => CityTheme.forStake(state.game?.stakePool ?? 0),
      ),
    );
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CasinoTableFrame(city: city, child: const CardGameView()),
          // No live blur over the board: it repaints every frame.
          const CasinoGlassScope(blur: false, child: GameHud()),
          if (ended)
            const CasinoGlassScope(blur: false, child: GameOverPanel()),
        ],
      ),
    );
  }
}

class GameHud extends ConsumerWidget {
  const GameHud({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final game = ref.watch(gameSessionProvider.select((state) => state.game));
    if (game == null) return const SizedBox.shrink();
    final notifier = ref.read(gameSessionProvider.notifier);
    final playing = game.status == GameStatus.playing;
    final canReveal = playing && game.you.launch == LaunchStatus.notLaunched;
    final peekSelecting = ref.watch(
      gameSessionProvider.select((state) => state.peekSelecting),
    );
    final queenMode = ref.watch(
      gameSessionProvider.select((state) => state.queenMode),
    );
    final canPeek = game.canJackPeek;
    final canQueen = game.canQueenAbility;
    final city = CityTheme.forStake(game.stakePool);
    final accent = city?.accent;
    final queenPicking = queenMode != QueenMode.none;
    final youId = game.you.playerId ?? '';
    final opponentId = game.opponent?.playerId ?? '';
    final youAvatarId =
        ref.watch(playerProfileProvider).asData?.value.avatarId ?? 'default';
    final youElo =
        youId.isEmpty
            ? null
            : ref.watch(playerRankByIdProvider(youId)).asData?.value?.elo;
    final opponentElo =
        opponentId.isEmpty
            ? null
            : ref.watch(playerRankByIdProvider(opponentId)).asData?.value?.elo;

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final height = constraints.maxHeight;
          return Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (game.potAmount > 0)
                      CasinoGlass(
                        shape: const StadiumBorder(),
                        rimColor: accent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          shape: const CircleBorder(),
                          elevation: 0,
                          child: Row(
                            children: [
                              Text(
                                '${l10n.prize}:',
                                style: const TextStyle(
                                  color: CasinoColors.text,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '${game.potAmount}',
                                style: const TextStyle(
                                  color: CasinoColors.gold,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const CashIcon(size: 22),
                            ],
                          ),
                        ),
                      ),
                    const Spacer(),
                    if (playing)
                      CasinoCircleButton(
                        rimColor: accent,
                        icon: AppIcons.flag,
                        tooltip: l10n.endGame,
                        onPressed:
                            () => _confirm(
                              context,
                              title: l10n.endGameTitle,
                              message: l10n.endGameMessage,
                              confirmLabel: l10n.endGame,
                              tone: CasinoActionTone.fold,
                              onConfirm: notifier.endGame,
                            ),
                      ),
                    if (playing) const SizedBox(width: 4),
                    CasinoCircleButton(
                      rimColor: accent,
                      icon: AppIcons.menu,
                      tooltip: l10n.menu,
                      onPressed:
                          () => _showGameMenu(
                            context,
                            roomId: game.roomId,
                            playing: playing,
                            isYourTurn: game.isYourTurn,
                            onEndGame: notifier.endGame,
                            onLeaveRoom: notifier.leaveRoom,
                          ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 12,
                top: height * 0.25 + 54,
                child: CasinoPlayerPill(
                  accent: accent,
                  name: game.opponent?.displayName ?? l10n.waitingEllipsisShort,
                  connected: game.opponent?.connected ?? false,
                  active: playing && !game.isYourTurn,
                  points: opponentElo,
                  avatarId: 'default',
                ),
              ),
              Positioned(
                left: 12,
                bottom: height * 0.25 + 80,
                child: CasinoPlayerPill(
                  accent: accent,
                  name: game.you.displayName,
                  connected: game.you.connected,
                  active: playing && game.isYourTurn,
                  points: youElo,
                  avatarId: youAvatarId,
                ),
              ),
              if (playing && canReveal)
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: CasinoActionButton(
                    label: l10n.reveal,
                    icon: AppIcons.visibility,
                    tone: CasinoActionTone.raise,
                    expanded: false,
                    onPressed: notifier.launch,
                  ),
                )
              else if (playing && canPeek)
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: CasinoActionButton(
                    label: peekSelecting ? l10n.cancel : l10n.peek,
                    icon: peekSelecting ? AppIcons.close : AppIcons.zoomIn,
                    tone: CasinoActionTone.raise,
                    expanded: false,
                    onPressed: notifier.togglePeekSelecting,
                  ),
                )
              else if (playing && canQueen)
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (queenPicking)
                        CasinoActionButton(
                          label: l10n.cancel,
                          icon: AppIcons.close,
                          tone: CasinoActionTone.fold,
                          expanded: false,
                          onPressed: notifier.cancelQueenMode,
                        )
                      else ...[
                        CasinoActionButton(
                          label: l10n.shuffle,
                          icon: AppIcons.shuffle,
                          tone: CasinoActionTone.raise,
                          expanded: false,
                          onPressed: notifier.enterQueenShufflePick,
                        ),
                        const SizedBox(height: 8),
                        CasinoActionButton(
                          label: l10n.replace,
                          icon: AppIcons.swapHoriz,
                          tone: CasinoActionTone.raise,
                          expanded: false,
                          onPressed: notifier.enterQueenReplacePick,
                        ),
                      ],
                    ],
                  ),
                )
              else if (playing &&
                  !game.bothRevealed &&
                  game.you.launch != LaunchStatus.notLaunched)
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 60,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SuitCardLoader(height: 22),
                      const SizedBox(height: 8),
                      Text(
                        l10n.waitingOpponentReveal,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: CasinoColors.textMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          shadows: [
                            Shadow(color: Color(0xCC000000), blurRadius: 6),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

Future<void> _showGameMenu(
  BuildContext context, {
  required String roomId,
  required bool playing,
  required bool isYourTurn,
  required VoidCallback onEndGame,
  required VoidCallback onLeaveRoom,
}) {
  final l10n = context.l10n;
  final turn = isYourTurn ? l10n.yourTurn : l10n.opponentTurn;
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: CasinoGlass(
            borderRadius: BorderRadius.circular(22),
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                _GameMenuTile(
                  icon: AppIcons.menuBook,
                  label: l10n.howToPlay,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const HowToPlayScreen(),
                      ),
                    );
                  },
                ),
                _GameMenuTile(
                  icon: AppIcons.info,
                  label: l10n.roomInfo,
                  subtitle:
                      playing
                          ? l10n.roomCodePlaying(roomId, turn)
                          : l10n.codeRoomId(roomId),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    CasinoToast.show(
                      context,
                      playing
                          ? l10n.roomToastPlaying(roomId, turn)
                          : l10n.roomToast(roomId),
                    );
                  },
                ),
                if (playing)
                  _GameMenuTile(
                    icon: AppIcons.flag,
                    label: l10n.endGame,
                    destructive: true,
                    onTap: () async {
                      Navigator.of(sheetContext).pop();
                      await _confirm(
                        context,
                        title: l10n.endGameTitle,
                        message: l10n.endGameMessage,
                        confirmLabel: l10n.endGame,
                        tone: CasinoActionTone.fold,
                        onConfirm: onEndGame,
                      );
                    },
                  ),
                _GameMenuTile(
                  icon: AppIcons.logout,
                  label: l10n.leaveRoom,
                  destructive: true,
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await _confirm(
                      context,
                      title: l10n.leaveRoomTitle,
                      message: l10n.leaveRoomMessage,
                      confirmLabel: l10n.leave,
                      tone: CasinoActionTone.fold,
                      onConfirm: onLeaveRoom,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _GameMenuTile extends StatelessWidget {
  const _GameMenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.destructive = false,
  });

  final List<List<dynamic>> icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? CasinoColors.foldHi : CasinoColors.text;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              HugeIcon(icon: icon, size: 22, color: color),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: CasinoColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              HugeIcon(
                icon: AppIcons.chevronRight,
                size: 20,
                color: CasinoColors.textMuted.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required VoidCallback onConfirm,
  CasinoActionTone tone = CasinoActionTone.raise,
}) async {
  final l10n = context.l10n;
  final confirmed = await showDialog<bool>(
    context: context,
    builder:
        (context) => AlertDialog(
          backgroundColor: CasinoColors.surface,
          shape: feltDialogShape,
          title: Text(
            title,
            style: const TextStyle(
              color: CasinoColors.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(color: CasinoColors.textMuted),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            SizedBox(
              width: double.infinity,
              child: Row(
                children: [
                  CasinoActionButton(
                    label: l10n.cancel,
                    tone: CasinoActionTone.check,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                  const SizedBox(width: 8),
                  CasinoActionButton(
                    label: confirmLabel,
                    tone: tone,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ],
              ),
            ),
          ],
        ),
  );
  if (confirmed ?? false) onConfirm();
}

/// Room code dealt out as a row of small ivory playing cards.
class _RoomCodeCards extends StatelessWidget {
  const _RoomCodeCards({required this.code, required this.cardHeight});

  final String code;
  final double cardHeight;

  @override
  Widget build(BuildContext context) {
    final chars = code.split('');
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 6.0;
        final maxW =
            (constraints.maxWidth - gap * (chars.length - 1)) / chars.length;
        final w = (cardHeight * 0.72).clamp(0.0, maxW);
        final h = w / 0.72;
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < chars.length; i++) ...[
                if (i > 0) const SizedBox(width: gap),
                Transform.rotate(
                  angle: (i - (chars.length - 1) / 2) * 0.03,
                  child: _CodeCard(
                    char: chars[i],
                    suit: SuitShape.values[i % 4],
                    width: w,
                    height: h,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _CodeCard extends StatelessWidget {
  const _CodeCard({
    required this.char,
    required this.suit,
    required this.width,
    required this.height,
  });

  final String char;
  final SuitShape suit;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final color = suitColor(suit);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(width * 0.14),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [CardInk.ivory, CardInk.ivoryShade],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: width * 0.1,
            left: width * 0.1,
            child: SuitGlyph(suit: suit, size: width * 0.2),
          ),
          Center(
            child: Text(
              char,
              style: TextStyle(
                fontFamily: CasinoFonts.display,
                color: color,
                fontSize: height * 0.42,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
