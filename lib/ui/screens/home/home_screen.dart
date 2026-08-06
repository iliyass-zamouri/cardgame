import 'package:cardgame/app/game_session_controller.dart';
import 'package:cardgame/domain/models/game_snapshot.dart';
import 'package:cardgame/ui/flame/card_game_view.dart';
import 'package:cardgame/ui/screens/home/game_starter.dart';
import 'package:cardgame/ui/screens/how_to_play_screen.dart';
import 'package:cardgame/ui/theme/casino_chrome.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
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
            message: message,
            onClose: messenger.hideCurrentSnackBar,
          ),
        ),
      );
      ref.read(gameSessionProvider.notifier).clearMessage();
    });

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
                  'Finding opponent',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: CasinoColors.gold,
                    fontSize: 26,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Hang tight — matching you with a player.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: CasinoColors.textMuted, fontSize: 14),
                ),
                const SizedBox(height: 36),
                CasinoActionButton(
                  label: 'Cancel',
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
    final notifier = ref.read(gameSessionProvider.notifier);
    final bothJoined = game.ready;
    final youReady = game.you.lobbyReady;
    final opponentReady = game.opponent?.lobbyReady ?? false;
    final yourName = game.you.displayName;
    final opponentName = game.opponent?.displayName ?? 'Waiting…';

    return Scaffold(
      backgroundColor: CasinoColors.surfaceHi,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 1),
              Text(
                'Private table',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: CasinoColors.gold,
                  fontSize: 26,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                bothJoined
                    ? (youReady && !opponentReady
                        ? 'Waiting for $opponentName…'
                        : !youReady && opponentReady
                        ? '$opponentName is ready'
                        : 'Both players joined')
                    : 'Share this code with a friend',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:
                      bothJoined
                          ? CasinoColors.raiseHi
                          : CasinoColors.textMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              if (bothJoined && youReady && !opponentReady) ...[
                const SizedBox(height: 20),
                const Center(child: SuitCardLoader(height: 24)),
              ],
              const SizedBox(height: 28),
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
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'VS',
                        style: TextStyle(
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
                const SizedBox(height: 28),
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
                      content: CasinoToast(message: 'Code copied'),
                    ),
                  );
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: bothJoined ? 14 : 22),
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
                          fontSize: bothJoined ? 28 : 40,
                          fontWeight: FontWeight.w800,
                          letterSpacing: bothJoined ? 8 : 10,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Tap to copy',
                        style: TextStyle(
                          color: CasinoColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(flex: 2),
              Row(
                children: [
                  CasinoActionButton(
                    label: youReady ? 'Waiting…' : 'Ready',
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
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: notifier.leaveRoom,
                  style: TextButton.styleFrom(
                    foregroundColor: CasinoColors.textMuted,
                  ),
                  child: const Text('Leave room'),
                ),
              ),
            ],
          ),
        ),
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
          isYou ? 'You' : (ready ? 'Ready' : 'Not ready'),
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

class GameBoard extends ConsumerWidget {
  const GameBoard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    return SafeArea(
      child: SizedBox.expand(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CasinoMenuPlayersPill(
                    youName: game.you.displayName,
                    opponentName: game.opponent?.displayName ?? 'Waiting…',
                    youConnected: game.you.connected,
                    opponentConnected: game.opponent?.connected ?? false,
                    yourTurn: playing && game.isYourTurn,
                    opponentTurn: playing && !game.isYourTurn,
                  ),
                  const Spacer(),
                  if (playing)
                    CasinoCircleButton(
                      icon: Icons.flag_outlined,
                      tooltip: 'End game',
                      onPressed:
                          () => _confirm(
                            context,
                            title: 'End game?',
                            message:
                                'Cards get revealed and scores are counted.',
                            confirmLabel: 'End game',
                            tone: CasinoActionTone.fold,
                            onConfirm: notifier.endGame,
                          ),
                    ),
                  if (playing) const SizedBox(width: 4),
                  CasinoCircleButton(
                    icon: Icons.menu_rounded,
                    tooltip: 'Menu',
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
            if (playing && canReveal)
              Positioned(
                right: 16,
                bottom: 16,
                child: CasinoActionButton(
                  label: 'Reveal',
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
                  label: peekSelecting ? 'Cancel' : 'Peek',
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
                        label: 'Cancel',
                        icon: Icons.close_rounded,
                        tone: CasinoActionTone.fold,
                        expanded: false,
                        onPressed: notifier.cancelQueenMode,
                      )
                    else ...[
                      CasinoActionButton(
                        label: 'Shuffle',
                        icon: Icons.shuffle_rounded,
                        tone: CasinoActionTone.raise,
                        expanded: false,
                        onPressed: notifier.enterQueenShufflePick,
                      ),
                      const SizedBox(height: 8),
                      CasinoActionButton(
                        label: 'Replace',
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
              const Positioned(
                left: 24,
                right: 24,
                bottom: 20,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SuitCardLoader(height: 22),
                    SizedBox(height: 8),
                    Text(
                      'Waiting for opponent to see their cards…',
                      textAlign: TextAlign.center,
                      style: TextStyle(
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
        ),
      ),
    );
  }
}

class GameOverPanel extends ConsumerWidget {
  const GameOverPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameSessionProvider.select((state) => state.game));
    if (game == null) return const SizedBox.shrink();
    final notifier = ref.read(gameSessionProvider.notifier);
    final yourTotal = game.you.total;
    final opponentTotal = game.opponent?.total;
    final youWin = opponentTotal != null && yourTotal < opponentTotal;
    final theyWin = opponentTotal != null && yourTotal > opponentTotal;
    final yourName = game.you.displayName;
    final opponentName = game.opponent?.displayName ?? 'Opponent';
    final yourSeries = game.you.seriesWins;
    final opponentSeries = game.opponent?.seriesWins ?? 0;
    final rematchReady = game.you.rematchReady;
    final opponentRematchReady = game.opponent?.rematchReady ?? false;
    final headline =
        opponentTotal == null
            ? 'Game over'
            : youWin
            ? 'Victory'
            : theyWin
            ? 'Defeat'
            : 'Draw';

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
              'SERIES  $yourSeries – $opponentSeries',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: CasinoColors.goldSoft,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _ResultSeat(
                    name: yourName,
                    score: yourTotal,
                    connected: game.you.connected,
                    winner: youWin,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'VS',
                    style: TextStyle(
                      color: CasinoColors.goldSoft,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Expanded(
                  child: _ResultSeat(
                    name: opponentName,
                    score: opponentTotal ?? 0,
                    connected: game.opponent?.connected ?? false,
                    winner: theyWin,
                    missing: opponentTotal == null,
                  ),
                ),
              ],
            ),
            if (rematchReady && !opponentRematchReady) ...[
              const SizedBox(height: 16),
              const SuitCardLoader(height: 24),
              const SizedBox(height: 10),
              const Text(
                'Waiting for opponent to rematch…',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: CasinoColors.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ] else if (!rematchReady && opponentRematchReady) ...[
              const SizedBox(height: 16),
              Text(
                '$opponentName is asking for a rematch',
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
                  label: 'Leave',
                  icon: Icons.logout_rounded,
                  tone: CasinoActionTone.fold,
                  onPressed: notifier.leaveRoom,
                ),
                const SizedBox(width: 10),
                CasinoActionButton(
                  label: rematchReady ? 'Waiting…' : 'Rematch',
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

  @override
  Widget build(BuildContext context) {
    final text = Text(
      widget.label.toUpperCase(),
      style: const TextStyle(
        fontFamily: CasinoFonts.display,
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
          widget.label.toUpperCase(),
          style: TextStyle(
            fontFamily: CasinoFonts.display,
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

class _ResultSeat extends StatelessWidget {
  const _ResultSeat({
    required this.name,
    required this.score,
    required this.connected,
    required this.winner,
    this.missing = false,
  });

  final String name;
  final int score;
  final bool connected;
  final bool winner;
  final bool missing;

  @override
  Widget build(BuildContext context) {
    const avatarSize = 52.0;
    final ring = winner ? CasinoColors.gold : Colors.white24;

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
                Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: CasinoColors.bgElevated,
                    border: Border.all(color: ring, width: winner ? 2.5 : 1.5),
                    boxShadow:
                        winner
                            ? [
                              BoxShadow(
                                color: CasinoColors.gold.withValues(
                                  alpha: 0.35,
                                ),
                                blurRadius: 12,
                              ),
                            ]
                            : null,
                  ),
                  child: Icon(
                    Icons.person,
                    size: avatarSize * 0.5,
                    color: CasinoColors.text.withValues(alpha: 0.9),
                  ),
                ),
                Positioned(
                  right: -1,
                  bottom: -1,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          connected
                              ? const Color(0xFF7ED50E)
                              : CasinoColors.foldHi,
                      border: Border.all(color: CasinoColors.surface, width: 2),
                    ),
                  ),
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
                const Padding(
                  padding: EdgeInsets.only(bottom: 2),
                  child: Text(
                    'pts',
                    style: TextStyle(
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
                  label: 'How to play',
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
                  label: 'Room info',
                  subtitle:
                      playing
                          ? '$roomId · ${isYourTurn ? 'Your turn' : 'Opponent turn'}'
                          : 'Code $roomId',
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
                                  ? 'Room $roomId · '
                                      '${isYourTurn ? "Your turn" : "Opponent turn"}'
                                  : 'Room $roomId',
                        ),
                      ),
                    );
                  },
                ),
                if (playing)
                  _GameMenuTile(
                    icon: Icons.flag_outlined,
                    label: 'End game',
                    destructive: true,
                    onTap: () async {
                      Navigator.of(sheetContext).pop();
                      await _confirm(
                        context,
                        title: 'End game?',
                        message: 'Cards get revealed and scores are counted.',
                        confirmLabel: 'End game',
                        tone: CasinoActionTone.fold,
                        onConfirm: onEndGame,
                      );
                    },
                  ),
                _GameMenuTile(
                  icon: Icons.logout_rounded,
                  label: 'Leave room',
                  destructive: true,
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await _confirm(
                      context,
                      title: 'Leave room?',
                      message: 'You will drop out of this game.',
                      confirmLabel: 'Leave',
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
                    label: 'Cancel',
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
