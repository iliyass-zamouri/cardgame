import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_protocol/game_protocol.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/camo_colors.dart';
import '../../core/constants/camo_spacing.dart';
import '../../core/constants/camo_typography.dart';
import '../../core/widgets/camo_buttons.dart';
import '../../core/widgets/camo_scaffold.dart';
import '../../core/widgets/camo_toast.dart';
import '../../core/widgets/game_background.dart';
import '../../game/shadow_hand_game.dart';
import 'match_controller.dart';

class MatchScreen extends ConsumerStatefulWidget {
  const MatchScreen({super.key});

  @override
  ConsumerState<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends ConsumerState<MatchScreen> {
  late final ShadowHandGame _game;
  String? _lastError;

  @override
  void initState() {
    super.initState();
    _game = ShadowHandGame(
      onAction: (action) {
        ref.read(matchControllerProvider.notifier).sendCardAction(action);
      },
    );
  }

  String _valueLabel(int? value) {
    if (value == null) return '--';
    const faces = {1: 'A', 11: 'J', 12: 'Q', 13: 'K'};
    return faces[value] ?? '$value';
  }

  @override
  Widget build(BuildContext context) {
    final match = ref.watch(matchControllerProvider);
    final snap = match.snapshot;

    ref.listen(matchControllerProvider, (prev, next) {
      _game.applySnapshot(next.snapshot);
      if (next.error != null && next.error != _lastError) {
        _lastError = next.error;
        showCamoToast(context, next.error!, error: true);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _game.applySnapshot(snap);
    });

    WirePlayerState? local;
    if (snap != null) {
      for (final p in snap.players) {
        if (p.id == snap.localPlayerId) {
          local = p;
          break;
        }
      }
    }
    final isReveal = snap?.phase == WireMatchPhase.reveal;
    final isResult = match.phase == AppPhase.result;

    return Scaffold(
      backgroundColor: CamoColors.background,
      body: GameBackground(
        child: Stack(
          fit: StackFit.expand,
          children: [
            GameWidget(game: _game),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(CamoSpacing.hudMargin),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          (snap?.phase.name ?? 'MATCH').toUpperCase(),
                          style: CamoTypography.labelCaps(CamoColors.timer),
                        ),
                        const SizedBox(width: CamoSpacing.md),
                        if (snap?.topDiscardValue != null)
                          Text(
                            'TOP ${_valueLabel(snap!.topDiscardValue)}',
                            style: CamoTypography.labelCaps(CamoColors.primary),
                          ),
                        const Spacer(),
                        if (isReveal)
                          Text(
                            '${snap?.revealSecondsLeft ?? 0}s',
                            style: CamoTypography.labelCaps(CamoColors.secondary),
                          )
                        else
                          Text(
                            snap?.canAct == true ? 'YOUR TURN' : 'WAIT',
                            style: CamoTypography.labelCaps(
                              snap?.canAct == true
                                  ? CamoColors.tertiary
                                  : CamoColors.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    if (isReveal)
                      CamoStartButton(
                        label: local?.launchReveal == 'NOT_LAUNCHED'
                            ? 'REVEAL'
                            : 'PEEKING...',
                        enabled: local?.launchReveal == 'NOT_LAUNCHED',
                        onPressed: () {
                          ref.read(matchControllerProvider.notifier).sendCardAction(
                                const CardActionMessage(
                                  type: WireCardActionType.launch,
                                ),
                              );
                        },
                      ),
                    if (snap?.phase == WireMatchPhase.playing &&
                        snap?.canAct == true)
                      CamoStartButton(
                        label: 'CALL GAME',
                        onPressed: () {
                          ref.read(matchControllerProvider.notifier).sendCardAction(
                                const CardActionMessage(
                                  type: WireCardActionType.end,
                                ),
                              );
                        },
                      ),
                  ],
                ),
              ),
            ),
            if (isResult)
              Container(
                color: Colors.black.withValues(alpha: 0.65),
                child: Center(
                  child: CamoPanel(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 340),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            snap?.outcome == 'draw'
                                ? 'DRAW'
                                : (snap?.winnerId == snap?.localPlayerId
                                    ? 'VICTORY'
                                    : 'DEFEAT'),
                            style:
                                CamoTypography.displayLg(CamoColors.secondary),
                          ),
                          const SizedBox(height: CamoSpacing.md),
                          ...(snap?.players ?? []).map(
                            (p) => Text(
                              '${p.displayName ?? p.id}: ${p.total}',
                              style:
                                  CamoTypography.bodyLg(CamoColors.onSurface),
                            ),
                          ),
                          const SizedBox(height: CamoSpacing.lg),
                          CamoStartButton(
                            label: 'REMATCH',
                            expandWidth: true,
                            onPressed: () {
                              ref
                                  .read(matchControllerProvider.notifier)
                                  .rematchJoin();
                              ref
                                  .read(matchControllerProvider.notifier)
                                  .rematchReady(true);
                            },
                          ),
                          const SizedBox(height: CamoSpacing.md),
                          CamoMenuButton(
                            label: 'Lobby',
                            onPressed: () {
                              ref
                                  .read(matchControllerProvider.notifier)
                                  .backToLobby();
                              context.go('/lobby');
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
