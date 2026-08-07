import 'package:cardgame/ads/interstitial_ad_service.dart';
import 'package:cardgame/app/auth_providers.dart';
import 'package:cardgame/app/game_session_controller.dart';
import 'package:cardgame/app/game_session_state.dart';
import 'package:cardgame/app/player_profile_repository.dart';
import 'package:cardgame/app/session_auth_status.dart';
import 'package:cardgame/l10n/l10n_ext.dart';
import 'package:cardgame/ui/screens/deck_preview_screen.dart';
import 'package:cardgame/ui/screens/how_to_play_screen.dart';
import 'package:cardgame/ui/screens/ranking/global_ranking_screen.dart';
import 'package:cardgame/ui/theme/casino_chrome.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/widgets/language_switcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

class StartGameWidget extends ConsumerWidget {
  const StartGameWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final connection = ref.watch(
      gameSessionProvider.select((state) => state.connection),
    );
    final connected = connection == ConnectionStatus.connected;
    final profile =
        ref.watch(playerProfileProvider).value ?? PlayerProfile.empty;
    final authStatus = ref.watch(sessionAuthProvider).value;
    final authLabel = switch (authStatus) {
      SessionAuthStatus.guest => l10n.guest,
      SessionAuthStatus.google => l10n.google,
      _ => l10n.guest,
    };
    final displayName = profile.isEmpty ? l10n.player : profile.name;
    final notifier = ref.read(gameSessionProvider.notifier);

    return Scaffold(
      backgroundColor: CasinoColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 12, 28, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TopBar(
                name: displayName,
                authLabel: authLabel,
                connected: connected,
                connection: connection,
              ),
              const SizedBox(height: 10),
              const Align(
                alignment: AlignmentDirectional.centerEnd,
                child: LanguageSwitcher(),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxHeight < 480;
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              'assets/logo.svg',
                              height: compact ? 110 : 160,
                              fit: BoxFit.contain,
                            ),
                            Text(
                              l10n.tagline,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: CasinoColors.textMuted,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: compact ? 20 : 36),
                            Center(
                              child: CasinoActionButton(
                                label: l10n.findMatch,
                                icon: Icons.bolt_rounded,
                                tone: CasinoActionTone.raise,
                                expanded: false,
                                height: 58,
                                onPressed:
                                    connected
                                        ? () async {
                                          await ref
                                              .read(interstitialAdProvider)
                                              .show();
                                          notifier.findMatch();
                                        }
                                        : null,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: CasinoActionButton(
                                label: l10n.createRoom,
                                icon: Icons.add_home_rounded,
                                tone: CasinoActionTone.check,
                                expanded: false,
                                height: 58,
                                onPressed:
                                    connected ? notifier.createRoom : null,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: CasinoActionButton(
                                label: l10n.joinRoom,
                                icon: Icons.login_rounded,
                                tone: CasinoActionTone.gold,
                                expanded: false,
                                height: 58,
                                onPressed:
                                    connected
                                        ? () => _showJoinRoomDialog(context)
                                        : null,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: CasinoActionButton(
                                label: l10n.playVsRobot,
                                icon: Icons.smart_toy_rounded,
                                tone: CasinoActionTone.check,
                                expanded: false,
                                height: 58,
                                onPressed:
                                    () => notifier.playVsRobot(
                                      robotName: l10n.robotName,
                                    ),
                              ),
                            ),
                            if (connection ==
                                ConnectionStatus.disconnected) ...[
                              const SizedBox(height: 16),
                              Center(
                                child: TextButton.icon(
                                  onPressed: notifier.connect,
                                  icon: const Icon(
                                    Icons.refresh_rounded,
                                    size: 18,
                                  ),
                                  label: Text(l10n.retryConnection),
                                  style: TextButton.styleFrom(
                                    foregroundColor: CasinoColors.goldSoft,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed:
                          () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (context) => const HowToPlayScreen(),
                            ),
                          ),
                      style: TextButton.styleFrom(
                        foregroundColor: CasinoColors.textMuted,
                        visualDensity: VisualDensity.compact,
                      ),
                      child: Text(l10n.howToPlay),
                    ),
                    const Text(
                      '·',
                      style: TextStyle(color: CasinoColors.textMuted),
                    ),
                    TextButton(
                      onPressed:
                          () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (context) => const GlobalRankingScreen(),
                            ),
                          ),
                      style: TextButton.styleFrom(
                        foregroundColor: CasinoColors.textMuted,
                        visualDensity: VisualDensity.compact,
                      ),
                      child: Text(l10n.globalRanking),
                    ),
                    const Text(
                      '·',
                      style: TextStyle(color: CasinoColors.textMuted),
                    ),
                    TextButton(
                      onPressed:
                          () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (context) => const DeckPreviewScreen(),
                            ),
                          ),
                      style: TextButton.styleFrom(
                        foregroundColor: CasinoColors.textMuted,
                        visualDensity: VisualDensity.compact,
                      ),
                      child: Text(l10n.deck),
                    ),
                    const Text(
                      '·',
                      style: TextStyle(color: CasinoColors.textMuted),
                    ),
                    TextButton(
                      onPressed: () async {
                        await ref.read(sessionAuthProvider.notifier).signOut();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: CasinoColors.textMuted,
                        visualDensity: VisualDensity.compact,
                      ),
                      child: Text(l10n.signOut),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showJoinRoomDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => const _JoinRoomDialog(),
  );
}

class _JoinRoomDialog extends ConsumerStatefulWidget {
  const _JoinRoomDialog();

  @override
  ConsumerState<_JoinRoomDialog> createState() => _JoinRoomDialogState();
}

class _JoinRoomDialogState extends ConsumerState<_JoinRoomDialog> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _join() {
    final code = _controller.text.trim().toUpperCase();
    if (code.isEmpty) return;
    Navigator.of(context).pop();
    ref.read(gameSessionProvider.notifier).joinRoom(code);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      backgroundColor: CasinoColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        l10n.joinRoomTitle,
        style: const TextStyle(
          color: CasinoColors.text,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.joinRoomHint,
            style: const TextStyle(color: CasinoColors.textMuted, fontSize: 14),
          ),
          const SizedBox(height: 18),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (context, value, _) {
              return TextField(
                controller: _controller,
                focusNode: _focusNode,
                textAlign: TextAlign.center,
                textCapitalization: TextCapitalization.characters,
                maxLength: 6,
                autofocus: true,
                style: const TextStyle(
                  color: CasinoColors.text,
                  letterSpacing: 8,
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                ),
                inputFormatters: [UpperCaseFormatter()],
                decoration: InputDecoration(
                  hintText: l10n.codeHint,
                  counterText: '',
                  fillColor: CasinoColors.bgElevated,
                  filled: true,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: CasinoColors.borderGlow,
                      width: 1.4,
                    ),
                  ),
                ),
                onSubmitted: (_) {
                  if (value.text.trim().isNotEmpty) _join();
                },
              );
            },
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        SizedBox(
          width: double.infinity,
          child: Row(
            children: [
              CasinoActionButton(
                label: l10n.cancel,
                tone: CasinoActionTone.fold,
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 8),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _controller,
                builder: (context, value, _) {
                  return CasinoActionButton(
                    label: l10n.join,
                    tone: CasinoActionTone.raise,
                    onPressed: value.text.trim().isEmpty ? null : _join,
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.name,
    required this.authLabel,
    required this.connected,
    required this.connection,
  });

  final String name;
  final String authLabel;
  final bool connected;
  final ConnectionStatus connection;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final statusColor = switch (connection) {
      ConnectionStatus.connected => const Color(0xFF7ED50E),
      ConnectionStatus.connecting => CasinoColors.gold,
      ConnectionStatus.disconnected => CasinoColors.foldHi,
    };
    final statusLabel = switch (connection) {
      ConnectionStatus.connected => l10n.online,
      ConnectionStatus.connecting => l10n.connecting,
      ConnectionStatus.disconnected => l10n.offline,
    };

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: CasinoColors.bgElevated,
          ),
          child: const Icon(
            Icons.person_rounded,
            size: 20,
            color: CasinoColors.textMuted,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: CasinoColors.text,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              Text(
                authLabel,
                style: const TextStyle(
                  color: CasinoColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: CasinoColors.bgElevated.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                statusLabel,
                style: TextStyle(
                  color: connected ? CasinoColors.text : CasinoColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
