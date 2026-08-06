import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/camo_colors.dart';
import '../../core/widgets/camo_toast.dart';
import '../../core/widgets/waiting_screen.dart';
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

  static List<String> _waitingTips(int stake) => [
        'Waiting for your opponent to join...',
        'The match starts once both players are connected.',
        'Stake: $stake coins on the line.',
        'Lowest score wins the round.',
      ];

  static List<String> _rematchTips(int stake) => [
        'Waiting for your opponent to accept rematch...',
        'Both players must be ready to play again.',
        'Stake: $stake coins.',
      ];

  @override
  void initState() {
    super.initState();
    _game = ShadowHandGame(
      onAction: (action) =>
          ref.read(matchControllerProvider.notifier).sendCardAction(action),
      onRematch: () {
        final c = ref.read(matchControllerProvider.notifier);
        c.rematchJoin();
        c.rematchReady(true);
      },
      onLobby: _goLobby,
    );
  }

  void _goLobby() {
    ref.read(matchControllerProvider.notifier).backToLobby();
    if (mounted) context.go('/lobby');
  }

  @override
  Widget build(BuildContext context) {
    final match = ref.watch(matchControllerProvider);
    final waiting = match.shouldShowMatchWaiting;

    ref.listen(matchControllerProvider, (prev, next) {
      if (!next.shouldShowMatchWaiting) {
        _game.applyMatchState(
          snapshot: next.snapshot,
          phase: next.phase,
        );
      }
      if (next.error != null && next.error != _lastError) {
        _lastError = next.error;
        showCamoToast(context, next.error!, error: true);
      }
    });

    if (!waiting) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _game.applyMatchState(
          snapshot: match.snapshot,
          phase: match.phase,
        );
      });
    }

    if (waiting) {
      final isRematchWait =
          match.phase == AppPhase.result && match.rematch != null;
      return WaitingScreen(
        tips: isRematchWait ? _rematchTips(match.stake) : _waitingTips(match.stake),
        cancelLabel: isRematchWait ? 'Back to lobby' : 'Leave match',
        onCancel: _goLobby,
      );
    }

    return Scaffold(
      backgroundColor: CamoColors.background,
      body: GameWidget(game: _game),
    );
  }
}
