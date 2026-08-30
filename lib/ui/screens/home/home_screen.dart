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
import 'package:cardgame/ui/flame/card_game_view.dart';
import 'package:cardgame/ui/screens/friends_screen.dart';
import 'package:cardgame/ui/screens/home/game_starter.dart';
import 'package:cardgame/ui/screens/how_to_play_screen.dart';
import 'package:cardgame/ui/theme/casino_chrome.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/widgets/currency_icon.dart';
import 'package:cardgame/ui/widgets/player_avatar.dart';
import 'package:cardgame/ui/widgets/suit_card_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<String?>(gameSessionProvider.select((state) => state.message), (
      previous,
      message,
    ) {
      if (message == null || message == previous) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          padding: EdgeInsets.zero,
          margin: const EdgeInsets.fromLTRB(8, 0, 8, 12),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          content: CasinoToast(
            message: localizeErrorCode(context.l10n, message),
            onClose: messenger.hideCurrentSnackBar,
          ),
        ),
      );
      ref.read(gameSessionProvider.notifier).clearMessage();
    });

    ref.listen<TableInviteNotification?>(
      gameSessionProvider.select((state) => state.incomingInvite),
      (previous, invite) {
        if (invite == null || invite == previous) return;
        final l10n = context.l10n;
        final notifier = ref.read(gameSessionProvider.notifier);

        showDialog<void>(
          context: context,
          barrierDismissible: true,
          builder: (dialogCtx) {
            return AlertDialog(
              backgroundColor: CasinoColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: CasinoColors.surfaceHi),
              ),
              title: Row(
                children: [
                  const Icon(
                    Icons.mark_email_unread_rounded,
                    color: CasinoColors.gold,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.privateTable,
                      style: const TextStyle(
                        color: CasinoColors.gold,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.tableInviteFrom(invite.inviterName, invite.roomId),
                    style: const TextStyle(
                      color: CasinoColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogCtx).pop();
                    notifier.dismissIncomingInvite();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: CasinoColors.textMuted,
                  ),
                  child: Text(l10n.ignore),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogCtx).pop();
                    notifier.acceptIncomingInvite(invite.roomId);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CasinoColors.raise,
                    foregroundColor: CasinoColors.text,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    l10n.joinTable,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            );
          },
        );
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

class MatchmakingWaiting extends ConsumerWidget {
  const MatchmakingWaiting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final notifier = ref.read(gameSessionProvider.notifier);

    return Scaffold(
      backgroundColor: CasinoColors.surfaceHi,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
      backgroundColor: CasinoColors.surfaceHi,
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                      content: CasinoToast(message: context.l10n.codeCopied),
                    ),
                  );
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: bothJoined ? 12 : 18),
                  decoration: BoxDecoration(
                    color: CasinoColors.bgElevated,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      SelectableText(
                        game.roomId,
                        style: TextStyle(
                          color: CasinoColors.text,
                          fontSize: bothJoined ? 26 : 36,
                          fontWeight: FontWeight.w800,
                          letterSpacing: bothJoined ? 6 : 8,
                        ),
                      ),
                      const SizedBox(height: 4),
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
                    icon:
                        youReady
                            ? Icons.hourglass_top_rounded
                            : Icons.check_rounded,
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
      decoration: BoxDecoration(
        color: CasinoColors.bgElevated.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CasinoColors.surfaceHi),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.people_alt_rounded,
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
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: CasinoColors.bgElevated,
                                  border: Border.all(
                                    color:
                                        friend.isOnline
                                            ? const Color(0xFF7ED50E)
                                            : Colors.white24,
                                    width: 1.2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.person_rounded,
                                  size: 18,
                                  color: CasinoColors.text,
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 9,
                                  height: 9,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:
                                        friend.isOnline
                                            ? const Color(0xFF7ED50E)
                                            : CasinoColors.textMuted,
                                    border: Border.all(
                                      color: CasinoColors.surface,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
                                  const Icon(
                                    Icons.check_rounded,
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
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: Colors.transparent,
                                    elevation: 0,
                                    behavior: SnackBarBehavior.floating,
                                    margin: const EdgeInsets.fromLTRB(
                                      8,
                                      0,
                                      8,
                                      12,
                                    ),
                                    duration: const Duration(seconds: 2),
                                    content: CasinoToast(
                                      message:
                                          '${l10n.inviteSent} (${friend.displayName})',
                                    ),
                                  ),
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
  });

  final String name;
  final bool connected;
  final bool ready;
  final bool isYou;

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
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: CasinoColors.bgElevated,
                  border: Border.all(
                    color: ready ? CasinoColors.gold : Colors.white24,
                    width: ready ? 2.5 : 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 32,
                  color: CasinoColors.text,
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        connected
                            ? const Color(0xFF7ED50E)
                            : CasinoColors.foldHi,
                    border: Border.all(color: CasinoColors.surfaceHi, width: 2),
                  ),
                ),
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
                    child: const Icon(
                      Icons.check,
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
          unawaited(ref.read(interstitialAdProvider).show());
        }
      },
    );

    final ended = ref.watch(
      gameSessionProvider.select(
        (state) => state.game?.status == GameStatus.ended,
      ),
    );
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const CasinoTableFrame(child: CardGameView()),
          const GameHud(),
          if (ended) const GameOverPanel(),
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
                        icon: Icons.flag_outlined,
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
                      icon: Icons.menu_rounded,
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
                top: height * 0.25 + 64,
                child: CasinoPlayerPill(
                  name: game.opponent?.displayName ?? l10n.waitingEllipsisShort,
                  connected: game.opponent?.connected ?? false,
                  active: playing && !game.isYourTurn,
                  points: opponentElo,
                  avatarId: 'default',
                ),
              ),
              Positioned(
                left: 12,
                top: height * 0.75 - 102,
                child: CasinoPlayerPill(
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
                    icon: Icons.visibility_rounded,
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
                    icon:
                        peekSelecting
                            ? Icons.close_rounded
                            : Icons.zoom_in_rounded,
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
                          icon: Icons.close_rounded,
                          tone: CasinoActionTone.fold,
                          expanded: false,
                          onPressed: notifier.cancelQueenMode,
                        )
                      else ...[
                        CasinoActionButton(
                          label: l10n.shuffle,
                          icon: Icons.shuffle_rounded,
                          tone: CasinoActionTone.raise,
                          expanded: false,
                          onPressed: notifier.enterQueenShufflePick,
                        ),
                        const SizedBox(height: 8),
                        CasinoActionButton(
                          label: l10n.replace,
                          icon: Icons.swap_horiz_rounded,
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

class GameOverPanel extends ConsumerWidget {
  const GameOverPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final game = ref.watch(gameSessionProvider.select((state) => state.game));
    if (game == null) return const SizedBox.shrink();
    final notifier = ref.read(gameSessionProvider.notifier);
    final youAvatarId =
        ref.watch(playerProfileProvider).asData?.value.avatarId ?? 'default';
    final yourTotal = game.you.total;
    final opponentTotal = game.opponent?.total;
    final youWin = opponentTotal != null && yourTotal < opponentTotal;
    final theyWin = opponentTotal != null && yourTotal > opponentTotal;
    final isDraw = opponentTotal != null && yourTotal == opponentTotal;
    final yourName = game.you.displayName;
    final opponentName = game.opponent?.displayName ?? l10n.opponent;
    final yourSeries = game.you.seriesWins;
    final opponentSeries = game.opponent?.seriesWins ?? 0;
    final rematchReady = game.you.rematchReady;
    final opponentRematchReady = game.opponent?.rematchReady ?? false;
    final headline =
        opponentTotal == null
            ? l10n.gameOver
            : youWin
            ? l10n.victory
            : theyWin
            ? l10n.defeat
            : l10n.draw;

    final youId = game.you.playerId ?? '';
    final ratings = game.result?.ratings;
    final youRating = _findRating(ratings, youId);

    final youXp =
        youRating?.pointsEarned ??
        _calculateXp(youWin, isDraw, yourTotal, opponentTotal);
    final youEloDelta = youRating?.eloDelta ?? _calculateElo(youWin, isDraw);

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 28),
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
        decoration: BoxDecoration(
          color: CasinoColors.surface.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: CasinoColors.borderGlow.withValues(alpha: 0.5),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x99000000),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _GameOverHeadline(label: headline, glow: youWin),
            const SizedBox(height: 4),
            Text(
              l10n.seriesScore(yourSeries, opponentSeries),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: CasinoColors.goldSoft,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: _ResultSeat(
                    name: yourName,
                    score: yourTotal,
                    connected: game.you.connected,
                    winner: youWin,
                    avatarId: youAvatarId,
                  ),
                ),
                Column(
                  children: [
                    if (game.potAmount > 0) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 8,
                        ),
                        decoration: BoxDecoration(
                          color: CasinoColors.surfaceHi,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              youWin
                                  ? '${game.potAmount}'
                                  : theyWin
                                  ? '${game.potAmount}'
                                  : '${game.potAmount} (${l10n.draw})',
                              style: TextStyle(
                                color:
                                    youWin
                                        ? CasinoColors.gold
                                        : theyWin
                                        ? CasinoColors.foldHi
                                        : CasinoColors.textMuted,
                                fontWeight: FontWeight.w800,
                                fontSize: 24,
                                height: 0.8,
                              ),
                            ),
                            const CashIcon(size: 24),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ] else
                      const SizedBox(height: 50),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        l10n.vs,
                        style: const TextStyle(
                          color: CasinoColors.goldSoft,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: _ResultSeat(
                    name: opponentName,
                    score: opponentTotal ?? 0,
                    connected: game.opponent?.connected ?? false,
                    winner: theyWin,
                    avatarId: 'default',
                    missing: opponentTotal == null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '+$youXp ${l10n.xp}',
                  style: const TextStyle(
                    color: CasinoColors.gold,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    '•',
                    style: TextStyle(
                      color: CasinoColors.textMuted,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${youEloDelta >= 0 ? '+$youEloDelta' : '$youEloDelta'} ${l10n.elo}',
                  style: TextStyle(
                    color:
                        youEloDelta >= 0
                            ? const Color(0xFF7ED50E)
                            : CasinoColors.foldHi,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            if (rematchReady && !opponentRematchReady) ...[
              const SizedBox(height: 16),
              const SuitCardLoader(height: 24),
              const SizedBox(height: 10),
              Text(
                l10n.waitingRematch,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: CasinoColors.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ] else if (!rematchReady && opponentRematchReady) ...[
              const SizedBox(height: 16),
              Text(
                l10n.opponentAskingRematch(opponentName),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: CasinoColors.goldSoft,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                CasinoActionButton(
                  label: l10n.leave,
                  icon: Icons.logout_rounded,
                  tone: CasinoActionTone.fold,
                  onPressed: notifier.leaveRoom,
                ),
                const SizedBox(width: 10),
                CasinoActionButton(
                  label: rematchReady ? l10n.waitingEllipsis : l10n.rematch,
                  icon: Icons.replay_rounded,
                  tone: CasinoActionTone.raise,
                  onPressed: rematchReady ? null : notifier.rematch,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GameOverHeadline extends StatefulWidget {
  const _GameOverHeadline({required this.label, required this.glow});

  final String label;
  final bool glow;

  @override
  State<_GameOverHeadline> createState() => _GameOverHeadlineState();
}

class _GameOverHeadlineState extends State<_GameOverHeadline>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _glow = Tween<double>(
      begin: 0.25,
      end: 0.85,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    if (widget.glow) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _GameOverHeadline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.glow && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.glow && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _displayLabel {
    final locale = Localizations.localeOf(context);
    return casinoButtonLabel(widget.label, locale);
  }

  @override
  Widget build(BuildContext context) {
    final displayFamily = CasinoFonts.displayFor(
      Localizations.localeOf(context),
    );
    final text = Text(
      _displayLabel,
      style: TextStyle(
        fontFamily: displayFamily,
        color: CasinoColors.gold,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.4,
      ),
    );

    if (!widget.glow) return text;

    return AnimatedBuilder(
      animation: _glow,
      builder: (context, child) {
        final intensity = _glow.value;
        return Text(
          _displayLabel,
          style: TextStyle(
            fontFamily: displayFamily,
            color: CasinoColors.gold,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
            shadows: [
              Shadow(
                color: CasinoColors.gold.withValues(alpha: intensity),
                blurRadius: 8 + intensity * 16,
              ),
              Shadow(
                color: CasinoColors.goldSoft.withValues(alpha: intensity * 0.7),
                blurRadius: 4 + intensity * 10,
              ),
              Shadow(
                color: CasinoColors.gold.withValues(alpha: intensity * 0.45),
                blurRadius: 22 + intensity * 18,
              ),
            ],
          ),
        );
      },
    );
  }
}

int _calculateXp(bool isWin, bool isDraw, int score, int? oppScore) {
  if (isDraw) return 8;
  if (!isWin) return 2;
  final diff = oppScore != null ? (oppScore - score).clamp(0, 100) : 0;
  final bonus = (diff * 1.5).round().clamp(0, 15);
  return 20 + bonus;
}

int _calculateElo(bool isWin, bool isDraw) {
  if (isDraw) return 0;
  return isWin ? 16 : -16;
}

PlayerResultRating? _findRating(List<PlayerResultRating>? ratings, String id) {
  if (ratings == null || id.isEmpty) return null;
  for (final r in ratings) {
    if (r.playerId == id) return r;
  }
  return null;
}

class _ResultSeat extends StatelessWidget {
  const _ResultSeat({
    required this.name,
    required this.score,
    required this.connected,
    required this.winner,
    this.avatarId,
    this.missing = false,
  });

  final String name;
  final int score;
  final bool connected;
  final bool winner;
  final String? avatarId;
  final bool missing;

  @override
  Widget build(BuildContext context) {
    const avatarSize = 52.0;
    final ring = winner ? CasinoColors.gold : Colors.white24;
    final l10n = context.l10n;

    return Opacity(
      opacity: missing ? 0.45 : 1,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: avatarSize,
            height: avatarSize,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                PlayerAvatar(
                  avatarId: avatarId ?? 'default',
                  size: avatarSize,
                  borderWidth: winner ? 0.5 : 0.0,
                  borderColor: ring,
                  showGlow: winner,
                  glowColor: CasinoColors.gold.withValues(alpha: 0.35),
                  statusDotColor:
                      connected ? const Color(0xFF7ED50E) : CasinoColors.foldHi,
                ),
                if (winner)
                  Positioned(
                    top: -20,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/crown.svg',
                        width: 36,
                        height: 38,
                        colorFilter: const ColorFilter.mode(
                          CasinoColors.gold,
                          BlendMode.srcIn,
                        ),
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
            style: TextStyle(
              color: winner ? CasinoColors.gold : CasinoColors.text,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                missing ? '—' : '$score',
                style: TextStyle(
                  color:
                      winner ? CasinoColors.goldSoft : CasinoColors.textMuted,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  height: 1,
                ),
              ),
              if (!missing) ...[
                const SizedBox(width: 3),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    l10n.points,
                    style: const TextStyle(
                      color: CasinoColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                      height: 1,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
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
                  icon: Icons.menu_book_rounded,
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
                  icon: Icons.info_outline_rounded,
                  label: l10n.roomInfo,
                  subtitle:
                      playing
                          ? l10n.roomCodePlaying(roomId, turn)
                          : l10n.codeRoomId(roomId),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                        content: CasinoToast(
                          message:
                              playing
                                  ? l10n.roomToastPlaying(roomId, turn)
                                  : l10n.roomToast(roomId),
                        ),
                      ),
                    );
                  },
                ),
                if (playing)
                  _GameMenuTile(
                    icon: Icons.flag_outlined,
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
                  icon: Icons.logout_rounded,
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

  final IconData icon;
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
              Icon(icon, size: 22, color: color),
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
              Icon(
                Icons.chevron_right_rounded,
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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
