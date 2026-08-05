import 'package:cardgame/app/game_session_controller.dart';
import 'package:cardgame/domain/models/game_snapshot.dart';
import 'package:cardgame/ui/flame/card_game_view.dart';
import 'package:cardgame/ui/screens/home/game_starter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<String?>(
      gameSessionProvider.select((state) => state.message),
      (previous, message) {
        if (message == null || message == previous) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 2),
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
    final theme = Theme.of(context);
    final notifier = ref.read(gameSessionProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Room code', style: theme.textTheme.bodyMedium),
                const SizedBox(height: 8),
                SelectableText(
                  game.roomId,
                  style: theme.textTheme.displaySmall?.copyWith(
                    letterSpacing: 6,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  game.ready
                      ? 'Two players connected'
                      : 'Waiting for opponent…',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: game.ready ? notifier.startGame : null,
                  child: const Text('Start game'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: notifier.leaveRoom,
                  child: const Text('Leave room'),
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
        children: [
          const Positioned.fill(child: CardGameView()),
          const GameHud(),
          if (ended) const GameOverPanel(),
        ],
      ),
      floatingActionButton: const LaunchFab(),
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
    final ended = game.status == GameStatus.ended;

    return SafeArea(
      minimum: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _HudButton(
                  icon: Icons.close,
                  tooltip: 'Leave room',
                  onPressed: () => _confirm(
                    context,
                    title: 'Leave room?',
                    message: 'You will drop out of this game.',
                    confirmLabel: 'Leave',
                    onConfirm: notifier.leaveRoom,
                  ),
                ),
                if (playing) ...[
                  const SizedBox(width: 8),
                  _HudButton(
                    icon: Icons.flag_outlined,
                    tooltip: 'End game',
                    onPressed: () => _confirm(
                      context,
                      title: 'End game?',
                      message: 'Cards get revealed and scores are counted.',
                      confirmLabel: 'End game',
                      onConfirm: notifier.endGame,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: PlayerBadge(
              name: 'Player 2',
              active: playing && !game.isYourTurn,
              total: ended ? game.opponent?.total : null,
              offline: game.opponent?.connected == false,
              nameOnLeft: true,
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: PlayerBadge(
              name: 'You',
              active: playing && game.isYourTurn,
              total: ended ? game.you.total : null,
              nameOnLeft: false,
            ),
          ),
        ],
      ),
    );
  }
}

/// Avatar with the name beside it, outlined while it is that player's turn.
class PlayerBadge extends StatelessWidget {
  const PlayerBadge({
    super.key,
    required this.name,
    required this.active,
    required this.nameOnLeft,
    this.total,
    this.offline = false,
  });

  final String name;
  final bool active;

  /// Puts the name plate left of the avatar, so badges anchored to the right
  /// edge keep their text on screen.
  final bool nameOnLeft;
  final int? total;
  final bool offline;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = total == null ? name : '$name · $total';

    final avatar = Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: active ? scheme.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: CircleAvatar(
        radius: 17,
        backgroundColor: scheme.surfaceContainerHighest,
        child: Icon(Icons.person, size: 20, color: scheme.onSurface),
      ),
    );

    final plate = DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Text(
          offline ? '$label · offline' : label,
          style: const TextStyle(fontSize: 11, color: Colors.white),
        ),
      ),
    );

    return Opacity(
      opacity: offline ? 0.5 : 1,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: nameOnLeft
            ? [plate, const SizedBox(width: 6), avatar]
            : [avatar, const SizedBox(width: 6), plate],
      ),
    );
  }
}

class _HudButton extends StatelessWidget {
  const _HudButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      onPressed: onPressed,
      iconSize: 20,
      style: IconButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.black54,
        minimumSize: const Size(38, 38),
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
    final theme = Theme.of(context);
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
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(headline, style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                opponentTotal == null
                    ? 'Your score $yourTotal'
                    : 'You $yourTotal — Player 2 $opponentTotal',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: notifier.startGame,
                child: const Text('Play again'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: notifier.leaveRoom,
                child: const Text('Leave'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LaunchFab extends ConsumerWidget {
  const LaunchFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canLaunch = ref.watch(
      gameSessionProvider.select(
        (state) =>
            state.game?.status == GameStatus.playing &&
            state.game?.you.launch == LaunchStatus.notLaunched,
      ),
    );
    if (!canLaunch) return const SizedBox.shrink();
    return FloatingActionButton.extended(
      onPressed: ref.read(gameSessionProvider.notifier).launch,
      icon: const Icon(Icons.visibility_outlined),
      label: const Text('Reveal'),
    );
  }
}

Future<void> _confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required VoidCallback onConfirm,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  if (confirmed ?? false) onConfirm();
}
