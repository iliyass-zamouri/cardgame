import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:game_protocol/game_protocol.dart';

import '../features/match/match_controller.dart';
import 'components/action_buttons.dart';
import 'components/corner_hand_card.dart';
import 'components/deck_discard_row.dart';
import 'components/game_hud.dart';
import 'components/game_result_overlay.dart';
import 'components/player_hand_grid.dart';
import 'components/table_background.dart';
import 'layout/table_layout.dart';

typedef CardActionCallback = void Function(CardActionMessage action);

class ShadowHandGame extends FlameGame {
  ShadowHandGame({
    required this.onAction,
    required this.onRematch,
    required this.onLobby,
  });

  final CardActionCallback onAction;
  final VoidCallback onRematch;
  final VoidCallback onLobby;

  MatchSnapshotMessage? _snapshot;
  AppPhase _phase = AppPhase.inGame;
  TableLayout? _layout;
  bool _loaded = false;

  late final TableBackgroundComponent background;
  late final PlayerHandGridComponent remoteHand;
  late final PlayerHandGridComponent localHand;
  late final DeckDiscardRowComponent deckDiscard;
  late final CornerHandCardComponent localCornerHand;
  late final CornerHandCardComponent remoteCornerHand;
  late final GameHudComponent hud;
  late final ActionButtonsComponent actions;
  late final GameResultOverlayComponent resultOverlay;

  MatchSnapshotMessage? get snapshot => _snapshot;

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    background = TableBackgroundComponent()..priority = 0;
    remoteHand = PlayerHandGridComponent(
      isLocal: false,
      onCardTap: (_, {required fromHand}) {},
    )..priority = 1;
    localHand = PlayerHandGridComponent(
      isLocal: true,
      onCardTap: _onLocalCardTap,
    )..priority = 1;
    deckDiscard = DeckDiscardRowComponent(
      onDraw: () =>
          onAction(const CardActionMessage(type: WireCardActionType.draw)),
    )..priority = 1;
    localCornerHand = CornerHandCardComponent(
      isLocal: true,
      onTap: () => onAction(
        const CardActionMessage(type: WireCardActionType.throwCard, hand: true),
      ),
    )..priority = 2;
    remoteCornerHand = CornerHandCardComponent(
      isLocal: false,
      onTap: null,
    )..priority = 2;
    hud = GameHudComponent()..priority = 10;
    actions = ActionButtonsComponent(
      onReveal: () =>
          onAction(const CardActionMessage(type: WireCardActionType.launch)),
      onCallGame: () =>
          onAction(const CardActionMessage(type: WireCardActionType.end)),
    )..priority = 11;
    resultOverlay = GameResultOverlayComponent(
      onRematch: onRematch,
      onLobby: onLobby,
    )..priority = 100;

    await addAll([
      background,
      remoteHand,
      localHand,
      deckDiscard,
      localCornerHand,
      remoteCornerHand,
      hud,
      actions,
      resultOverlay,
    ]);

    _loaded = true;
    if (size.x > 0 && size.y > 0) {
      _layout = TableLayout(size);
    }
    _dispatch();
  }

  void applySnapshot(MatchSnapshotMessage? snapshot) {
    applyMatchState(snapshot: snapshot, phase: _phase);
  }

  void applyMatchState({
    required MatchSnapshotMessage? snapshot,
    required AppPhase phase,
  }) {
    final sw = Stopwatch()..start();
    _snapshot = snapshot;
    _phase = phase;
    if (!_loaded) return;
    if (size.x > 0 && size.y > 0) {
      _layout = TableLayout(size);
    }
    _dispatch();
    sw.stop();
    if (sw.elapsedMilliseconds > 12) {
      debugPrint(
        '[flame.perf] applyMatchState ${sw.elapsedMilliseconds}ms phase=${phase.name} snap=${snapshot?.phase.name}',
      );
    }
  }

  void _onLocalCardTap(WireCard card, {required bool fromHand}) {
    final local = _localPlayer;
    final hasHand =
        local?.handCard != null && local!.handCard!.tag != 'XX';
    onAction(
      CardActionMessage(
        type: WireCardActionType.throwCard,
        cardTag: card.tag,
        hand: hasHand,
      ),
    );
  }

  WirePlayerState? get _localPlayer {
    final snap = _snapshot;
    if (snap == null) return null;
    for (final p in snap.players) {
      if (p.id == snap.localPlayerId) return p;
    }
    return null;
  }

  WirePlayerState? get _remotePlayer {
    final snap = _snapshot;
    if (snap == null) return null;
    for (final p in snap.players) {
      if (p.id != snap.localPlayerId) return p;
    }
    return null;
  }

  void _dispatch() {
    final sw = Stopwatch()..start();
    if (!_loaded) return;
    final snap = _snapshot;
    final layout = _layout;
    if (layout == null) return;

    background.size = layout.size;

    final canAct = snap?.canAct ?? false;

    remoteHand.apply(
      player: _remotePlayer,
      canAct: false,
      layout: layout,
    );
    localHand.apply(
      player: _localPlayer,
      canAct: canAct,
      layout: layout,
    );
    deckDiscard.apply(snapshot: snap, layout: layout);

    localCornerHand.apply(
      handCard: _localPlayer?.handCard,
      canAct: canAct,
      layout: layout,
    );
    remoteCornerHand.apply(
      handCard: _remotePlayer?.handCard,
      canAct: false,
      layout: layout,
    );

    hud
      ..size = layout.size
      ..apply(snapshot: snap, layout: layout);

    actions
      ..size = layout.size
      ..apply(snapshot: snap, local: _localPlayer, layout: layout);

    resultOverlay
      ..size = layout.size
      ..apply(
        snapshot: snap,
        visible: _phase == AppPhase.result,
      );
    sw.stop();
    if (sw.elapsedMilliseconds > 8) {
      debugPrint(
        '[flame.perf] dispatch ${sw.elapsedMilliseconds}ms cards='
        '${_localPlayer?.cards.length ?? 0}/${_remotePlayer?.cards.length ?? 0}',
      );
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (!_loaded) return;
    _layout = TableLayout(size);
    _dispatch();
  }
}
