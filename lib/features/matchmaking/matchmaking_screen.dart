import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/camo_colors.dart';
import '../../core/constants/camo_spacing.dart';
import '../../core/constants/camo_typography.dart';
import '../../core/widgets/camo_buttons.dart';
import '../../core/widgets/camo_scaffold.dart';
import '../../core/widgets/game_background.dart';
import '../match/match_controller.dart';

class MatchmakingScreen extends ConsumerWidget {
  const MatchmakingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final match = ref.watch(matchControllerProvider);

    ref.listen(matchControllerProvider, (prev, next) {
      if (next.phase == AppPhase.inGame) context.go('/match');
      if (next.phase == AppPhase.lobby) context.go('/lobby');
    });

    return CamoScaffold(
      title: 'Matchmaking',
      onBack: () => ref.read(matchControllerProvider.notifier).cancelQueue(),
      body: GameBackground(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(CamoSpacing.xl),
            child: CamoPanel(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              const CircularProgressIndicator(color: CamoColors.secondary),
              const SizedBox(height: CamoSpacing.lg),
              Text(
                'SEARCHING STAKE ${match.stake}',
                style: CamoTypography.labelCaps(CamoColors.secondary),
              ),
              const SizedBox(height: CamoSpacing.lg),
              CamoMenuButton(
                label: 'Cancel',
                onPressed: () {
                  ref.read(matchControllerProvider.notifier).cancelQueue();
                  context.go('/lobby');
                },
              ),
            ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
