import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/waiting_screen.dart';
import '../match/match_controller.dart';

class MatchmakingScreen extends ConsumerWidget {
  const MatchmakingScreen({super.key});

  static List<String> _searchTips(int stake) => [
        'Searching for an opponent at stake $stake...',
        'Earnings from private games are not included in league earnings.',
        'Lowest score wins the round.',
        'Hang tight — matching players with similar stakes.',
      ];

  static List<String> _opponentTips(int stake) => [
        'Waiting for your opponent to join...',
        'The match starts once both players are connected.',
        'Stake: $stake coins on the line.',
        'Lowest score wins the round.',
      ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final match = ref.watch(matchControllerProvider);
    final waitingForOpponent = match.phase == AppPhase.waitingForOpponent;

    ref.listen(matchControllerProvider, (prev, next) {
      if (prev?.phase == next.phase) return;
      if (next.phase == AppPhase.inGame || next.phase == AppPhase.result) {
        context.go('/match');
      } else if (next.phase == AppPhase.lobby) {
        context.go('/lobby');
      }
    });

    return WaitingScreen(
      tips: waitingForOpponent
          ? _opponentTips(match.stake)
          : _searchTips(match.stake),
      cancelLabel: waitingForOpponent ? 'Leave match' : 'Cancel search',
      onCancel: () {
        if (waitingForOpponent) {
          ref.read(matchControllerProvider.notifier).leaveMatch();
        } else {
          ref.read(matchControllerProvider.notifier).cancelQueue();
        }
        context.go('/lobby');
      },
    );
  }
}
