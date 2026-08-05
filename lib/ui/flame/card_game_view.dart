import 'package:cardgame/app/game_session_controller.dart';
import 'package:cardgame/domain/models/game_snapshot.dart';
import 'package:cardgame/ui/flame/card_game.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CardGameView extends ConsumerStatefulWidget {
  const CardGameView({super.key});

  @override
  ConsumerState<CardGameView> createState() => _CardGameViewState();
}

class _CardGameViewState extends ConsumerState<CardGameView> {
  late final CardGame _game;

  @override
  void initState() {
    super.initState();
    _game = CardGame();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = ref.read(gameSessionProvider.notifier);
    _game.onTapCard = session.tapCard;
    _game.onDraw = session.drawCard;
    _game.onThrowHand = session.throwHandCard;
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(
      gameSessionProvider.select((state) => state.game),
    );

    if (snapshot != null &&
        (snapshot.status == GameStatus.playing ||
            snapshot.status == GameStatus.ended)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _game.applySnapshot(snapshot);
      });
    }

    return GameWidget(game: _game);
  }
}
