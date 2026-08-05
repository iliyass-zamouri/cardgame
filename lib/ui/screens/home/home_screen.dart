import 'package:cardgame/app/game_session_controller.dart';
import 'package:cardgame/domain/models/game_snapshot.dart';
import 'package:cardgame/ui/flame/card_game_view.dart';
import 'package:cardgame/ui/screens/home/game_starter.dart';
import 'package:flutter/cupertino.dart';
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
    return Scaffold(
      backgroundColor: Colors.black54,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              margin: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Room',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      game.roomId,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 6,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      game.ready
                          ? 'Two players connected'
                          : 'Waiting for opponent…',
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: game.ready
                          ? ref.read(gameSessionProvider.notifier).startGame
                          : null,
                      child: const Text('Start game'),
                    ),
                    TextButton(
                      onPressed:
                          ref.read(gameSessionProvider.notifier).leaveRoom,
                      child: const Text('Leave room'),
                    ),
                  ],
                ),
              ),
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
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(child: CardGameView()),
          GameHud(),
        ],
      ),
      floatingActionButton: LaunchFab(),
    );
  }
}

class GameHud extends ConsumerWidget {
  const GameHud({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(
      gameSessionProvider.select((state) => state.game!),
    );
    return Positioned(
      top: 4,
      right: 4,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Text(
                  game.isYourTurn ? 'Your turn' : "Opponent's turn",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            if (game.result case final result?)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Score ${result.scores.join(' – ')}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            if (game.status == GameStatus.ended)
              FilledButton(
                onPressed: ref.read(gameSessionProvider.notifier).startGame,
                child: const Text('Play again'),
              )
            else
              TextButton(
                onPressed: ref.read(gameSessionProvider.notifier).endGame,
                child: const Text(
                  'End game',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            TextButton(
              onPressed: ref.read(gameSessionProvider.notifier).leaveRoom,
              child:
                  const Text('Leave', style: TextStyle(color: Colors.white)),
            ),
          ],
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
    return FloatingActionButton(
      onPressed: ref.read(gameSessionProvider.notifier).launch,
      child: const Icon(CupertinoIcons.eye),
    );
  }
}
