import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/dependency_injection.dart';
import '../../core/constants/camo_colors.dart';
import '../../core/constants/camo_typography.dart';
import '../../core/widgets/camo_lobby_actions.dart';
import '../../core/widgets/camo_lobby_header.dart';
import '../../core/widgets/camo_toast.dart';
import '../../core/widgets/game_background.dart';
import '../match/match_controller.dart';
import 'lobby_modals.dart';

class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({super.key});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  late final PageController _pageCtrl;
  int _page = 0;

  static const _modes = [
    LobbyMode.quickMatch,
    LobbyMode.privateRoom,
    LobbyMode.joinRoom,
  ];

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(viewportFraction: 0.58);
    _pageCtrl.addListener(() {
      final p = _pageCtrl.page?.round() ?? 0;
      if (p != _page) setState(() => _page = p);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(matchControllerProvider.notifier).connect();
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _openMode(LobbyMode mode) =>
      openLobbyModeSheet(context, ref, mode);

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final match = ref.watch(matchControllerProvider);
    final size = MediaQuery.sizeOf(context);
    final cardHeight = (size.height * 0.28).clamp(165.0, 195.0);

    ref.listen(matchControllerProvider, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        showCamoToast(context, next.error!, error: true);
      }
      if (prev?.phase == next.phase) return;

      final path = switch (next.phase) {
        AppPhase.inGame || AppPhase.result => '/match',
        AppPhase.matchmaking || AppPhase.waitingForOpponent => '/matchmaking',
        AppPhase.room => '/room',
        _ => null,
      };
      if (path == null) return;

      // Drop leftover dialogs only — leave GoRouter pages alone.
      final nav = Navigator.of(context, rootNavigator: true);
      nav.popUntil((route) => route is! PopupRoute);
      context.go(path);
    });

    return Scaffold(
      backgroundColor: CamoColors.background,
      body: GameBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CamoLobbyProfile(
                        displayName: session.displayName ?? 'Guest',
                        starCurrent: session.coins.clamp(0, 15),
                      ),
                    ),
                    CamoLobbyCurrencyStack(
                      coins: session.coins,
                      gems: 30,
                      onShopTap: () => context.push('/shop'),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 3),
              SizedBox(
                height: cardHeight,
                child: PageView(
                  controller: _pageCtrl,
                  padEnds: true,
                  children: [
                    CamoModeCard(
                      height: cardHeight,
                      title: '1 on 1',
                      subtitle: 'Quick Match',
                      color: const Color(0xFFFFD54F),
                      footerColor: const Color(0xFFF9A825),
                      titleColor: const Color(0xFF3D2200),
                      onTap: () => _openMode(LobbyMode.quickMatch),
                      illustration: CamoModeCardHeroNumber(
                        value: '${match.stake}',
                      ),
                    ),
                    CamoModeCard(
                      height: cardHeight,
                      title: 'Private',
                      subtitle: 'Play with Friends',
                      color: const Color(0xFF64B5F6),
                      footerColor: const Color(0xFF1976D2),
                      titleColor: CamoColors.white,
                      onTap: () => _openMode(LobbyMode.privateRoom),
                      illustration: const CamoModeCardIcons(),
                    ),
                    CamoModeCard(
                      height: cardHeight,
                      title: 'Join Room',
                      subtitle: 'Enter Code',
                      color: const Color(0xFFECEFF1),
                      footerColor: const Color(0xFFB0BEC5),
                      titleColor: const Color(0xFF263238),
                      onTap: () => _openMode(LobbyMode.joinRoom),
                      illustration: const CamoModeCardJoinArt(),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 4),
              if (match.error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    match.error!,
                    textAlign: TextAlign.center,
                    style: CamoTypography.bodyLg(CamoColors.danger),
                  ),
                ),
              CamoLobbyFloatingBar(
                onFriends: () => context.push('/friends'),
                onShop: () => context.push('/shop'),
                onPlay: () => _openMode(_modes[_page.clamp(0, _modes.length - 1)]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
