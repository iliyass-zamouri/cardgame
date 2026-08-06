import 'package:cardgame/app/game_session_controller.dart';
import 'package:cardgame/domain/models/game_snapshot.dart';
import 'package:cardgame/ui/flame/card_game_view.dart';
import 'package:cardgame/ui/screens/home/game_starter.dart';
import 'package:cardgame/ui/theme/casino_chrome.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
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
    if (game == null) return const StartGameWidget();
    if (game.status == GameStatus.waiting) {
      return WaitingRoom(game: game);
    }
    return const GameBoard();
  }
}

class WaitingRoom extends ConsumerWidget {
  final GameSnapshot game;

  const WaitingRoom({super.key, required this.game});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(gameSessionProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CasinoPill(
                  borderColor: CasinoColors.borderGlow,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.meeting_room_outlined,
                        size: 18,
                        color: CasinoColors.gold,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ROOM ${game.roomId}',
                        style: const TextStyle(
                          color: CasinoColors.gold,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Copy code',
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: game.roomId),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 16),
                        color: CasinoColors.textMuted,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                SelectableText(
                  game.roomId,
                  style: const TextStyle(
                    color: CasinoColors.text,
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 8,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  game.ready
                      ? 'Two players connected'
                      : 'Waiting for opponent…',
                  style: TextStyle(
                    color:
                        game.ready
                            ? CasinoColors.raiseHi
                            : CasinoColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 28),
                CasinoActionButton(
                  label: 'Start game',
                  tone: CasinoActionTone.raise,
                  expanded: false,
                  onPressed: game.ready ? notifier.startGame : null,
                ),
                const SizedBox(height: 12),
                CasinoActionButton(
                  label: 'Leave room',
                  tone: CasinoActionTone.fold,
                  expanded: false,
                  onPressed: notifier.leaveRoom,
                ),
              ],
            ),
          ),
        ),
      ),
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
                    youName: 'You',
                    opponentName: 'Player 2',
                    youConnected: game.you.connected,
                    opponentConnected: game.opponent?.connected ?? false,
                    yourTurn: playing && game.isYourTurn,
                    opponentTurn: playing && !game.isYourTurn,
                    onMenuPressed:
                        () => _confirm(
                          context,
                          title: 'Leave room?',
                          message: 'You will drop out of this game.',
                          confirmLabel: 'Leave',
                          tone: CasinoActionTone.fold,
                          onConfirm: notifier.leaveRoom,
                        ),
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
                  if (playing) const SizedBox(width: 8),
                  CasinoCircleButton(
                    icon: Icons.info_outline,
                    tooltip: 'Room info',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                          content: CasinoToast(
                            message:
                                'Room ${game.roomId} · '
                                '${game.isYourTurn ? "Your turn" : "Opponent turn"}',
                          ),
                        ),
                      );
                    },
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
            else if (playing &&
                !game.bothRevealed &&
                game.you.launch != LaunchStatus.notLaunched)
              const Positioned(
                left: 24,
                right: 24,
                bottom: 20,
                child: Text(
                  'Waiting for opponent to see their cards…',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: CasinoColors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    shadows: [Shadow(color: Color(0xCC000000), blurRadius: 6)],
                  ),
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
    final headline =
        opponentTotal == null
            ? 'Game over'
            : youWin
            ? 'You win'
            : theyWin
            ? 'Player 2 wins'
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
            Text(
              headline.toUpperCase(),
              style: const TextStyle(
                fontFamily: CasinoFonts.display,
                color: CasinoColors.gold,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: _ResultSeat(
                    name: 'You',
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
                    name: 'Player 2',
                    score: opponentTotal ?? 0,
                    connected: game.opponent?.connected ?? false,
                    winner: theyWin,
                    missing: opponentTotal == null,
                  ),
                ),
              ],
            ),
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
                  label: 'Play again',
                  icon: Icons.replay_rounded,
                  tone: CasinoActionTone.raise,
                  onPressed: notifier.startGame,
                ),
              ],
            ),
          ],
        ),
      ),
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
            style: TextStyle(
              color: winner ? CasinoColors.gold : CasinoColors.text,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            missing ? '—' : '$score',
            style: TextStyle(
              color: winner ? CasinoColors.goldSoft : CasinoColors.textMuted,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ],
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
