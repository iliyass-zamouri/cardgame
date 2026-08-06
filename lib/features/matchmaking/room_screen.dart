import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/dependency_injection.dart';
import '../../core/constants/camo_colors.dart';
import '../../core/constants/camo_spacing.dart';
import '../../core/constants/camo_typography.dart';
import '../../core/widgets/camo_buttons.dart';
import '../../core/widgets/camo_scaffold.dart';
import '../match/match_controller.dart';

class RoomScreen extends ConsumerWidget {
  const RoomScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final match = ref.watch(matchControllerProvider);
    final session = ref.watch(sessionProvider);
    final room = match.room;

    ref.listen(matchControllerProvider, (prev, next) {
      if (next.phase == AppPhase.inGame) context.go('/match');
      if (next.phase == AppPhase.lobby) context.go('/lobby');
    });

    final isHost = room?.hostPlayerId == session.playerId;

    return CamoScaffold(
      title: 'Private Room',
      onBack: () {
        ref.read(matchControllerProvider.notifier).leaveRoom();
        context.go('/lobby');
      },
      body: Padding(
        padding: const EdgeInsets.all(CamoSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CamoPanel(
              child: Row(
                children: [
                  Text(
                    room?.code ?? match.roomCode ?? '------',
                    style: CamoTypography.displaySm(CamoColors.secondary),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      final code = room?.code ?? match.roomCode;
                      if (code != null) {
                        Clipboard.setData(ClipboardData(text: code));
                      }
                    },
                    icon: const Icon(Icons.copy, color: CamoColors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: CamoSpacing.lg),
            Text('MEMBERS', style: CamoTypography.labelCaps(CamoColors.primary)),
            const SizedBox(height: CamoSpacing.sm),
            ...(room?.members ?? []).map(
              (m) => Padding(
                padding: const EdgeInsets.only(bottom: CamoSpacing.sm),
                child: CamoPanel(
                  child: Row(
                    children: [
                      Text(
                        m.name,
                        style: CamoTypography.headlineMd(CamoColors.onSurface),
                      ),
                      if (m.isHost) ...[
                        const SizedBox(width: CamoSpacing.sm),
                        Text(
                          'HOST',
                          style: CamoTypography.labelCaps(CamoColors.tertiary),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const Spacer(),
            if (isHost)
              CamoStartButton(
                label: 'START',
                expandWidth: true,
                enabled: (room?.members.length ?? 0) >= 2,
                onPressed: () {
                  ref.read(matchControllerProvider.notifier).startRoom();
                },
              ),
          ],
        ),
      ),
    );
  }
}
