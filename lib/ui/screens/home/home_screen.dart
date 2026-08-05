import 'package:cardgame/app/game_session_controller.dart';
import 'package:cardgame/domain/models/game_snapshot.dart';
import 'package:cardgame/domain/models/p_card.dart';
import 'package:cardgame/ui/screens/home/game_starter.dart';
import 'package:cardgame/ui/widgets/player_hand_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:playing_cards/playing_cards.dart';

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
                          ? ref
                              .read(gameSessionProvider.notifier)
                              .startGame
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: const Center(
        child: Stack(
          children: [
            Column(
              children: [
                OpponentHand(),
                Expanded(child: TableCenter()),
                LocalHand(),
              ],
            ),
            LocalHandCardOverlay(),
            RemoteHandCardOverlay(),
            GameHud(),
          ],
        ),
      ),
      floatingActionButton: const LaunchFab(),
    );
  }
}

class OpponentHand extends ConsumerWidget {
  const OpponentHand({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(
      gameSessionProvider.select(
        (state) => (
          state.game!.opponent?.cards ?? const <CardSnapshot>[],
          state.game!.isYourTurn,
        ),
      ),
    );
    return _HandFrame(
      child: PlayerHandView(
        cards: view.$1,
        isSelf: false,
        isTurn: !view.$2,
      ),
    );
  }
}

class LocalHand extends ConsumerWidget {
  const LocalHand({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(
      gameSessionProvider.select(
        (state) => (state.game!.you.cards, state.game!.isYourTurn),
      ),
    );
    return _HandFrame(
      child: PlayerHandView(
        cards: view.$1,
        isSelf: true,
        isTurn: view.$2,
        onTap: ref.read(gameSessionProvider.notifier).tapCard,
      ),
    );
  }
}

class _HandFrame extends StatelessWidget {
  final Widget child;

  const _HandFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.5,
        maxHeight: MediaQuery.sizeOf(context).height * 0.36,
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: child,
      ),
    );
  }
}

class TableCenter extends ConsumerWidget {
  const TableCenter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final table = ref.watch(
      gameSessionProvider.select(
        (state) => (
          state.game!.deckCount,
          state.game!.discardTop,
          state.game!.isYourTurn,
          state.game!.you.handCard,
        ),
      ),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        InkWell(
          onTap: table.$3 && table.$4 == null
              ? ref.read(gameSessionProvider.notifier).drawCard
              : null,
          child: SizedBox(
            width: 120,
            child: table.$1 == 0
                ? const SizedBox.shrink()
                : DecoratedBox(
                    decoration: shadowDecoration,
                    child: PlayingCardView(
                      card: PCard.fromTag('A1').card,
                      showBack: true,
                      style: PlayingCardViewStyle(
                        cardBackContentBuilder: (_) => const PCardPattern(),
                      ),
                    ),
                  ),
          ),
        ),
        SizedBox(
          width: 120,
          child: table.$2 == null
              ? const SizedBox.shrink()
              : PlayingCardView(card: table.$2!.card, showBack: false),
        ),
      ],
    );
  }
}

class LocalHandCardOverlay extends ConsumerWidget {
  const LocalHandCardOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final handCard = ref.watch(
      gameSessionProvider.select((state) => state.game!.you.handCard),
    );
    if (handCard == null) return const SizedBox.shrink();
    return Positioned(
      left: 4,
      bottom: 4,
      child: SizedBox(
        width: 120,
        child: InkWell(
          onTap: ref.read(gameSessionProvider.notifier).throwHandCard,
          child: DecoratedBox(
            decoration: shadowDecoration,
            child: PlayingCardView(card: handCard.card, showBack: false),
          ),
        ),
      ),
    );
  }
}

class RemoteHandCardOverlay extends ConsumerWidget {
  const RemoteHandCardOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasHand = ref.watch(
      gameSessionProvider.select(
        (state) => state.game!.opponent?.hasHandCard ?? false,
      ),
    );
    if (!hasHand) return const SizedBox.shrink();
    return Positioned(
      left: 4,
      top: 4,
      child: SizedBox(
        width: 40,
        child: DecoratedBox(
          decoration: shadowDecoration,
          child: PlayingCardView(
            card: PCard.fromTag('A1').card,
            showBack: true,
            style: PlayingCardViewStyle(
              cardBackContentBuilder: (_) => const PCardPattern(),
            ),
          ),
        ),
      ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            game.isYourTurn ? 'Your turn' : "Opponent's turn",
            style: const TextStyle(color: Colors.white),
          ),
          if (game.result case final result?)
            Text(
              'Score ${result.scores.join(' – ')}',
              style: const TextStyle(color: Colors.white),
            ),
          if (game.status == GameStatus.ended)
            FilledButton(
              onPressed: ref.read(gameSessionProvider.notifier).startGame,
              child: const Text('Play again'),
            )
          else
            TextButton(
              onPressed: ref.read(gameSessionProvider.notifier).endGame,
              child:
                  const Text('End game', style: TextStyle(color: Colors.white)),
            ),
          TextButton(
            onPressed: ref.read(gameSessionProvider.notifier).leaveRoom,
            child: const Text('Leave', style: TextStyle(color: Colors.white)),
          ),
        ],
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
