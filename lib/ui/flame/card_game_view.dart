import 'package:cardgame/app/game_session_controller.dart';
import 'package:cardgame/domain/models/game_snapshot.dart';
import 'package:cardgame/l10n/l10n_ext.dart';
import 'package:cardgame/ui/flame/card_game.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
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
    _game.onJackPeek = (side, cardIndex) {
      session.jackPeek(side: side, cardIndex: cardIndex);
    };
    _game.onQueenShuffle = (side) {
      session.queenShuffle(side: side);
    };
    _game.onQueenReplaceSelect = (side, cardIndex) {
      session.selectReplaceCard(side: side, cardIndex: cardIndex);
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final snapshot = ref.watch(
      gameSessionProvider.select((state) => state.game),
    );
    final peekSelecting = ref.watch(
      gameSessionProvider.select((state) => state.peekSelecting),
    );
    final queenMode = ref.watch(
      gameSessionProvider.select((state) => state.queenMode),
    );
    final replaceSide = ref.watch(
      gameSessionProvider.select((state) => state.replaceFirstSide),
    );
    final replaceIndex = ref.watch(
      gameSessionProvider.select((state) => state.replaceFirstIndex),
    );

    _game.setUiStrings(
      hintPeek: l10n.hintPeek,
      hintShufflePick: l10n.hintShufflePick,
      hintReplaceFirst: l10n.hintReplaceFirst,
      hintReplaceSecond: l10n.hintReplaceSecond,
      shuffleLabel: l10n.shuffle,
      textDirection: Directionality.of(context),
      fontFamily: CasinoFonts.uiFor(locale),
    );

    _game.peekSelecting = peekSelecting;
    _game.queenMode = queenMode;
    _game.setReplaceSelection(side: replaceSide, index: replaceIndex);

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
