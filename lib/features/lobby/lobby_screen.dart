import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/dependency_injection.dart';
import '../../core/constants/camo_colors.dart';
import '../../core/constants/camo_spacing.dart';
import '../../core/constants/camo_typography.dart';
import '../../core/widgets/camo_buttons.dart';
import '../../core/widgets/camo_lobby_actions.dart';
import '../../core/widgets/camo_lobby_header.dart';
import '../../core/widgets/camo_scaffold.dart';
import '../../core/widgets/camo_stake_selector.dart';
import '../../core/widgets/camo_toast.dart';
import '../../core/widgets/game_background.dart';
import '../match/match_controller.dart';

class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({super.key});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  final _codeCtrl = TextEditingController();
  final _pageCtrl = PageController(viewportFraction: 0.72);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(matchControllerProvider.notifier).connect();
    });
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final match = ref.watch(matchControllerProvider);

    ref.listen(matchControllerProvider, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        showCamoToast(context, next.error!, error: true);
      }
      if (next.phase == AppPhase.inGame || next.phase == AppPhase.result) {
        context.go('/match');
      } else if (next.phase == AppPhase.matchmaking) {
        context.go('/matchmaking');
      } else if (next.phase == AppPhase.room) {
        context.go('/room');
      }
    });

    return Scaffold(
      backgroundColor: CamoColors.background,
      body: GameBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  CamoSpacing.lg,
                  CamoSpacing.sm,
                  CamoSpacing.lg,
                  CamoSpacing.md,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CamoLobbyProfile(
                        displayName: session.displayName ?? 'Guest',
                        progressLabel: 'STAKE ${match.stake}',
                      ),
                    ),
                    CamoLobbyCurrencyStack(
                      coins: session.coins,
                      onShopTap: () => context.push('/shop'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageCtrl,
                  children: [
                    CamoModeCard(
                      title: '1 on 1',
                      subtitle: 'Quick Match',
                      color: const Color(0xFFFFD54F),
                      accent: const Color(0xFF3D2200),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${match.stake}',
                            style: CamoTypography.gameTitle(
                              CamoColors.purpleMid,
                            ).copyWith(fontSize: 72, height: 1),
                          ),
                          const SizedBox(height: CamoSpacing.lg),
                          CamoStakeSelector(
                            stakes: const [50, 100, 250, 500],
                            selected: match.stake,
                            onSelected: (s) => ref
                                .read(matchControllerProvider.notifier)
                                .setStake(s),
                          ),
                        ],
                      ),
                    ),
                    CamoModeCard(
                      title: 'Private Room',
                      subtitle: 'Play with Friends',
                      color: const Color(0xFF5BB8FF),
                      accent: CamoColors.white,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            size: 64,
                            color: CamoColors.white.withValues(alpha: 0.9),
                          ),
                          const SizedBox(height: CamoSpacing.lg),
                          CamoMenuButton(
                            label: 'Create Room',
                            primary: true,
                            onPressed: () => ref
                                .read(matchControllerProvider.notifier)
                                .createRoom(),
                          ),
                        ],
                      ),
                    ),
                    CamoModeCard(
                      title: 'Join Room',
                      subtitle: 'Enter Code',
                      color: const Color(0xFFE8E8E8),
                      accent: const Color(0xFF333333),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CamoPanel(
                            opaque: false,
                            child: TextField(
                              controller: _codeCtrl,
                              style: CamoTypography.displaySm(
                                CamoColors.onSurface,
                              ),
                              textAlign: TextAlign.center,
                              textCapitalization:
                                  TextCapitalization.characters,
                              decoration: InputDecoration(
                                hintText: 'CODE',
                                hintStyle: CamoTypography.displaySm(
                                  CamoColors.onSurfaceVariant,
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: CamoSpacing.md),
                          CamoMenuButton(
                            label: 'Join',
                            primary: true,
                            onPressed: () => ref
                                .read(matchControllerProvider.notifier)
                                .joinRoom(_codeCtrl.text.trim()),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (match.error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: CamoSpacing.xl,
                  ),
                  child: Text(
                    match.error!,
                    textAlign: TextAlign.center,
                    style: CamoTypography.bodyLg(CamoColors.danger),
                  ),
                ),
              CamoLobbyFloatingBar(
                onFriends: () => context.push('/friends'),
                onShop: () => context.push('/shop'),
                onPlay: () =>
                    ref.read(matchControllerProvider.notifier).queue(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
