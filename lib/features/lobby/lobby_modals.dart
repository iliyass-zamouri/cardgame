import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/camo_colors.dart';
import '../../core/constants/camo_spacing.dart';
import '../../core/constants/camo_typography.dart';
import '../../core/widgets/camo_buttons.dart';
import '../../core/widgets/camo_modal.dart';
import '../../core/widgets/camo_stake_selector.dart';
import '../match/match_controller.dart';

Future<void> showQuickMatchModal(BuildContext context, WidgetRef ref) async {
  final findMatch = await showCamoModal<bool>(
    context: context,
    child: Consumer(
      builder: (context, ref, _) {
        final match = ref.watch(matchControllerProvider);
        return CamoModalContent(
          title: 'Quick Match',
          body: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Pick stake. Lowest score wins.',
                style: CamoTypography.bodyLg(CamoColors.onSurfaceVariant),
              ),
              const SizedBox(height: CamoSpacing.lg),
              CamoStakeSelector(
                stakes: const [50, 100, 250, 500],
                selected: match.stake,
                onSelected: (s) =>
                    ref.read(matchControllerProvider.notifier).setStake(s),
              ),
              const SizedBox(height: CamoSpacing.lg),
              CamoStartButton(
                label: 'FIND MATCH',
                expandWidth: true,
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        );
      },
    ),
  );

  // Queue only after dialog route fully dismissed — avoids go_router
  // sliding WaitingScreen over a half-closed modal (no crash logs).
  if (findMatch == true && context.mounted) {
    ref.read(matchControllerProvider.notifier).queue();
  }
}

Future<void> showPrivateRoomModal(BuildContext context, WidgetRef ref) async {
  final create = await showCamoModal<bool>(
    context: context,
    child: CamoModalContent(
      title: 'Private Room',
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Create a room and share the code with friends.',
            style: CamoTypography.bodyLg(CamoColors.onSurfaceVariant),
          ),
          const SizedBox(height: CamoSpacing.lg),
          CamoMenuButton(
            label: 'Create Room',
            icon: Icons.lock_outline_rounded,
            primary: true,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    ),
  );

  if (create == true && context.mounted) {
    ref.read(matchControllerProvider.notifier).createRoom();
  }
}

Future<void> showJoinRoomModal(BuildContext context, WidgetRef ref) async {
  final codeCtrl = TextEditingController();
  try {
    final code = await showCamoModal<String>(
      context: context,
      child: CamoModalContent(
        title: 'Join Room',
        body: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: codeCtrl,
              style: CamoTypography.displaySm(CamoColors.onSurface),
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'ROOM CODE',
                hintStyle: CamoTypography.bodyLg(CamoColors.onSurfaceVariant),
                filled: true,
                fillColor: CamoColors.surfaceVariant.withValues(alpha: 0.35),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(CamoSpacing.sm),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: CamoSpacing.lg),
            CamoMenuButton(
              label: 'Join',
              primary: true,
              onPressed: () {
                final value = codeCtrl.text.trim();
                if (value.isEmpty) return;
                Navigator.of(context).pop(value);
              },
            ),
          ],
        ),
      ),
    );

    if (code != null && code.isNotEmpty && context.mounted) {
      ref.read(matchControllerProvider.notifier).joinRoom(code);
    }
  } finally {
    codeCtrl.dispose();
  }
}

enum LobbyMode { quickMatch, privateRoom, joinRoom }

Future<void> openLobbyModeSheet(
  BuildContext context,
  WidgetRef ref,
  LobbyMode mode,
) {
  return switch (mode) {
    LobbyMode.quickMatch => showQuickMatchModal(context, ref),
    LobbyMode.privateRoom => showPrivateRoomModal(context, ref),
    LobbyMode.joinRoom => showJoinRoomModal(context, ref),
  };
}
