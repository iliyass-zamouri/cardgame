import 'package:cardgame/app/game_session_controller.dart';
import 'package:cardgame/domain/models/game_snapshot.dart';
import 'package:cardgame/ui/flame/card_game_view.dart';
import 'package:cardgame/ui/screens/home/game_starter.dart';
import 'package:cardgame/ui/theme/casino_chrome.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<String?>(
      gameSessionProvider.select((state) => state.message),
      (previous, message) {
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
      },
    );

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
                    color: game.ready
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
      gameSessionProvider
          .select((state) => state.game?.status == GameStatus.ended),
    );
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const CasinoTableFrame(
            child: CardGameView(),
          ),
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
    final game = ref.watch(
      gameSessionProvider.select((state) => state.game),
    );
    if (game == null) return const SizedBox.shrink();
    final notifier = ref.read(gameSessionProvider.notifier);
    final playing = game.status == GameStatus.playing;
    final canReveal =
        playing && game.you.launch == LaunchStatus.notLaunched;

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight;
          // Flame hands sit at ~20% (opponent) and ~75% (you); badge sits
          // just under the first card row (cardHeight/2 ≈ 56).
          final opponentTop = h * 0.20 + 62;
          final youTop = h * 0.75 + 62;

          return SizedBox.expand(
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                  child: Row(
                    children: [
                      CasinoCircleButton(
                        icon: Icons.menu,
                        tooltip: 'Leave room',
                        onPressed: () => _confirm(
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
                          onPressed: () => _confirm(
                            context,
                            title: 'End game?',
                            message:
                                'Cards get revealed and scores are counted.',
                            confirmLabel: 'End game',
                            tone: CasinoActionTone.check,
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
                Positioned(
                  top: opponentTop,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: CasinoTurnBadge(
                      name: 'Player 2',
                      nameAbove: true,
                      active: playing && !game.isYourTurn,
                      offline: game.opponent?.connected == false,
                    ),
                  ),
                ),
                Positioned(
                  top: youTop,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: CasinoTurnBadge(
                      active: playing && game.isYourTurn,
                    ),
                  ),
                ),
                if (playing)
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: CasinoActionButton(
                      label: canReveal ? 'Reveal' : 'Wait',
                      icon: canReveal
                          ? Icons.visibility_rounded
                          : Icons.hourglass_top_rounded,
                      tone: CasinoActionTone.raise,
                      expanded: false,
                      onPressed: canReveal ? notifier.launch : null,
                    ),
                  ),
              ],
            ),
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
    final game = ref.watch(gameSessionProvider.select((state) => state.game));
    if (game == null) return const SizedBox.shrink();
    final notifier = ref.read(gameSessionProvider.notifier);
    final yourTotal = game.you.total;
    final opponentTotal = game.opponent?.total;
    final headline = opponentTotal == null
        ? 'Game over'
        : yourTotal < opponentTotal
            ? 'You win'
            : yourTotal > opponentTotal
                ? 'Player 2 wins'
                : 'Draw';

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 28),
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
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
                color: CasinoColors.gold,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              opponentTotal == null
                  ? 'Your score $yourTotal'
                  : 'You $yourTotal — Player 2 $opponentTotal',
              style: const TextStyle(color: CasinoColors.textMuted),
            ),
            const SizedBox(height: 20),
            CasinoActionButton(
              label: 'Play again',
              tone: CasinoActionTone.raise,
              expanded: false,
              onPressed: notifier.startGame,
            ),
            const SizedBox(height: 10),
            CasinoActionButton(
              label: 'Leave',
              tone: CasinoActionTone.fold,
              expanded: false,
              onPressed: notifier.leaveRoom,
            ),
          ],
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
    builder: (context) => AlertDialog(
      backgroundColor: CasinoColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
