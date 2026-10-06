import 'dart:async';

import 'package:cardgame/app/auth_providers.dart';
import 'package:cardgame/app/friends_providers.dart';
import 'package:cardgame/app/game_session_controller.dart';
import 'package:cardgame/app/game_session_state.dart';
import 'package:cardgame/app/player_profile_repository.dart';
import 'package:cardgame/app/push_providers.dart';
import 'package:cardgame/app/session_auth_status.dart';
import 'package:cardgame/data/auth/guest_google_link.dart';
import 'package:cardgame/l10n/l10n_ext.dart';
import 'package:cardgame/services/analytics_service.dart';
import 'package:cardgame/ui/flame/suit_shapes.dart';
import 'package:cardgame/ui/screens/friends_screen.dart';
import 'package:cardgame/ui/screens/home/home_menu_widgets.dart';
import 'package:cardgame/ui/screens/home/stake_selector_modal.dart';
import 'package:cardgame/ui/screens/how_to_play_screen.dart';
import 'package:cardgame/ui/screens/marketplace_screen.dart';
import 'package:cardgame/ui/screens/notifications/notifications_panel.dart';
import 'package:cardgame/ui/screens/profile/player_profile_screen.dart';
import 'package:cardgame/ui/screens/ranking/global_ranking_screen.dart';
import 'package:cardgame/ui/screens/settings_screen.dart';
import 'package:cardgame/ui/theme/casino_chrome.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/theme/felt_chrome.dart';
import 'package:cardgame/ui/widgets/currency_icon.dart';
import 'package:cardgame/ui/widgets/player_avatar.dart';
import 'package:cardgame/ui/widgets/suit_card_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:cardgame/ui/theme/app_icons.dart';
import 'package:cardgame/trailer/trailer_mode.dart';

class StartGameWidget extends ConsumerStatefulWidget {
  const StartGameWidget({super.key});

  @override
  ConsumerState<StartGameWidget> createState() => _StartGameWidgetState();
}

class _StartGameWidgetState extends ConsumerState<StartGameWidget> {
  bool _softPromptChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeSoftPrompts());
  }

  Future<void> _maybeSoftPrompts() async {
    if (_softPromptChecked || !mounted || TrailerMode.enabled) return;
    _softPromptChecked = true;

    final showedPush = await _maybeSoftPushPrompt();
    if (!mounted) return;
    if (showedPush) return;
    await _maybeGuestLinkPrompt();
  }

  /// Returns true if the push dialog was shown this visit.
  Future<bool> _maybeSoftPushPrompt() async {
    final prefs = ref.read(pushPrefsRepositoryProvider);
    if (prefs.pushSoftPromptDone) return false;

    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return false;

    final allow = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: CasinoColors.surface,
          title: const Text(
            'Stay in the loop',
            style: TextStyle(color: CasinoColors.gold),
          ),
          content: const Text(
            'Get notified for friend requests and table invites even when you are away.',
            style: TextStyle(color: CasinoColors.text),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Later'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Allow'),
            ),
          ],
        );
      },
    );

    await prefs.setPushSoftPromptDone(true);
    if (allow == true) {
      unawaited(
        ref.read(analyticsServiceProvider).pushPermission(result: 'granted'),
      );
      await ref
          .read(pushNotificationServiceProvider)
          .requestPermissionAndRegister();
    } else {
      unawaited(
        ref.read(analyticsServiceProvider).pushPermission(result: 'later'),
      );
    }
    return true;
  }

  Future<void> _maybeGuestLinkPrompt() async {
    final auth = ref.read(sessionAuthProvider).value;
    if (auth != SessionAuthStatus.guest) return;

    final prefs = ref.read(guestLinkPrefsRepositoryProvider);
    if (!prefs.shouldShowNudge) return;

    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    if (ref.read(sessionAuthProvider).value != SessionAuthStatus.guest) {
      return;
    }

    final l10n = context.l10n;
    final action = await showDialog<_GuestLinkPromptAction>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: CasinoColors.surface,
          title: Text(
            l10n.saveProgressTitle,
            style: const TextStyle(color: CasinoColors.gold),
          ),
          content: Text(
            l10n.saveProgressBody,
            style: const TextStyle(color: CasinoColors.text),
          ),
          actions: [
            TextButton(
              onPressed:
                  () => Navigator.of(
                    dialogContext,
                  ).pop(_GuestLinkPromptAction.dontAsk),
              child: Text(l10n.dontAskAgain),
            ),
            TextButton(
              onPressed:
                  () => Navigator.of(
                    dialogContext,
                  ).pop(_GuestLinkPromptAction.later),
              child: Text(l10n.later),
            ),
            TextButton(
              onPressed:
                  () => Navigator.of(
                    dialogContext,
                  ).pop(_GuestLinkPromptAction.link),
              child: Text(
                l10n.linkGoogleAccount,
                style: const TextStyle(color: CasinoColors.gold),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted || action == null) return;

    switch (action) {
      case _GuestLinkPromptAction.later:
        await prefs.markShown();
      case _GuestLinkPromptAction.dontAsk:
        await prefs.setDontAskAgain(true);
      case _GuestLinkPromptAction.link:
        await prefs.markShown();
        if (!mounted) return;
        final result = await linkOrSignInWithGoogle(context: context, ref: ref);
        if (!mounted) return;
        if (result.outcome == GuestGoogleLinkOutcome.linked) {
          CasinoToast.show(context, l10n.linkGoogleSuccess);
        } else if (result.outcome == GuestGoogleLinkOutcome.switched) {
          CasinoToast.show(context, l10n.linkGoogleSwitched);
        } else if (result.outcome == GuestGoogleLinkOutcome.failed &&
            result.errorMessage != null) {
          CasinoToast.show(context, result.errorMessage!, success: false);
        }
    }
  }

  void _push(Widget screen) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (context) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final connection = ref.watch(
      gameSessionProvider.select((state) => state.connection),
    );
    final connected = connection == ConnectionStatus.connected;
    final profile =
        ref.watch(playerProfileProvider).value ?? PlayerProfile.empty;
    final displayName = profile.isEmpty ? l10n.player : profile.name;
    final connectedFriendsCount = ref.watch(connectedFriendsCountProvider);
    final unread = ref.watch(notificationsUnreadCountProvider);
    final notifier = ref.read(gameSessionProvider.notifier);

    return Scaffold(
      backgroundColor: CasinoColors.feltDeep,
      body: FeltTableBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TopBar(
                  name: displayName,
                  username: profile.username,
                  avatarId: profile.avatarId,
                  money: profile.money,
                  chips: profile.chips,
                  connection: connection,
                  unreadNotifications: unread,
                  onProfile: () => _push(const PlayerProfileScreen()),
                  onMarketplace: () => _push(const MarketplaceScreen()),
                  onNotifications: () => showNotificationsPanel(context, ref),
                  onSettings: () => _push(const SettingsScreen()),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  child:
                      connected
                          ? const SizedBox(width: double.infinity)
                          : _ConnectionBanner(connection: connection),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final height = constraints.maxHeight;
                      final compact = height < 560;
                      final logoWidth = compact ? 220.0 : 280.0;
                      final modeHeight = compact ? 116.0 : 132.0;
                      // Hero fan takes whatever the fixed content leaves.
                      final fixedHeight =
                          logoWidth / 3 + 18 + 92 + 14 + modeHeight + 18;
                      final heroHeight = (height - fixedHeight).clamp(
                        0.0,
                        220.0,
                      );
                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: height),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              DealIn(
                                from: const Offset(0, -0.3),
                                child: Image.asset(
                                  'assets/logo/text.png',
                                  width: logoWidth,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              Text(
                                l10n.tagline,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: CasinoColors.goldSoft,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              if (heroHeight >= 100)
                                HeroCardFan(
                                  deckSkinId: profile.deckId,
                                  height: heroHeight,
                                )
                              else
                                const SizedBox(height: 20),
                              DealIn(
                                delay: const Duration(milliseconds: 150),
                                child: PrimaryPlayCard(
                                  title: l10n.findMatch,
                                  subtitle: l10n.winnerTakesAll,
                                  icon: AppIcons.bolt,
                                  onTap:
                                      connected
                                          ? () =>
                                              showStakeSelectorModal(context)
                                          : null,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: DealIn(
                                      delay: const Duration(milliseconds: 260),
                                      from: const Offset(0.4, 0.6),
                                      rotation: -0.25,
                                      child: ModePlayingCard(
                                        label: l10n.createRoom,
                                        suit: SuitShape.hearts,
                                        icon: AppIcons.addHome,
                                        height: modeHeight,
                                        onTap:
                                            connected
                                                ? notifier.createRoom
                                                : null,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: DealIn(
                                      delay: const Duration(milliseconds: 340),
                                      from: const Offset(0, 0.6),
                                      child: ModePlayingCard(
                                        label: l10n.joinRoom,
                                        suit: SuitShape.diamonds,
                                        icon: AppIcons.login,
                                        height: modeHeight,
                                        onTap:
                                            connected
                                                ? () =>
                                                    _showJoinRoomDialog(context)
                                                : null,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: DealIn(
                                      delay: const Duration(milliseconds: 420),
                                      from: const Offset(-0.4, 0.6),
                                      rotation: 0.25,
                                      child: ModePlayingCard(
                                        label: l10n.playVsRobot,
                                        suit: SuitShape.clubs,
                                        icon: AppIcons.game,
                                        height: modeHeight,
                                        onTap:
                                            () => notifier.playVsRobot(
                                              robotName: l10n.robotName,
                                            ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                TableRailDock(
                  items: [
                    RailDockItem(
                      icon: AppIcons.trophy,
                      label: l10n.leaderboard,
                      onTap: () => _push(const GlobalRankingScreen()),
                    ),
                    RailDockItem(
                      icon: AppIcons.shoppingBag,
                      label: l10n.marketplace,
                      onTap: () => _push(const MarketplaceScreen()),
                    ),
                    RailDockItem(
                      icon: AppIcons.people,
                      label: l10n.friends,
                      badge: connectedFriendsCount,
                      onTap: () => _push(const FriendsScreen()),
                    ),
                    RailDockItem(
                      icon: AppIcons.menuBook,
                      label: l10n.howToPlay,
                      onTap: () => _push(const HowToPlayScreen()),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _GuestLinkPromptAction { later, dontAsk, link }

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
      shape: feltDialogShape,
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
    required this.username,
    required this.avatarId,
    required this.money,
    required this.chips,
    required this.connection,
    required this.unreadNotifications,
    required this.onProfile,
    required this.onMarketplace,
    required this.onNotifications,
    required this.onSettings,
  });

  final String name;
  final String username;
  final String avatarId;
  final int money;
  final int chips;
  final ConnectionStatus connection;
  final int unreadNotifications;
  final VoidCallback onProfile;
  final VoidCallback onMarketplace;
  final VoidCallback onNotifications;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final statusColor = switch (connection) {
      ConnectionStatus.connected => const Color(0xFF7ED50E),
      ConnectionStatus.connecting => CasinoColors.gold,
      ConnectionStatus.disconnected => CasinoColors.foldHi,
    };

    return Row(
      children: [
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: onProfile,
              child: Ink(
                padding: const EdgeInsetsDirectional.fromSTEB(3, 3, 12, 3),
                decoration: _hudDecoration(),
                child: Row(
                  children: [
                    PlayerAvatar(
                      avatarId: avatarId,
                      size: 38,
                      borderWidth: 1.6,
                      borderColor: CasinoColors.gold,
                      statusDotColor: statusColor,
                    ),
                    const SizedBox(width: 8),
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
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                          if (username.isNotEmpty)
                            Text(
                              '@$username',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: CasinoColors.goldSoft,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onMarketplace,
            child: Ink(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 9),
              decoration: _hudDecoration(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CashIcon(size: 20),
                  const SizedBox(width: 3),
                  Text(
                    '$money',
                    style: const TextStyle(
                      color: CasinoColors.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const ChipIcon(size: 20),
                  const SizedBox(width: 3),
                  Text(
                    '$chips',
                    style: const TextStyle(
                      color: CasinoColors.goldSoft,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        _HudIconButton(
          icon: AppIcons.notifications,
          tooltip: 'Notifications',
          badge: unreadNotifications,
          onTap: onNotifications,
        ),
        const SizedBox(width: 6),
        _HudIconButton(
          icon: AppIcons.settings,
          tooltip: l10n.settings,
          onTap: onSettings,
        ),
      ],
    );
  }
}

BoxDecoration _hudDecoration({BoxShape shape = BoxShape.rectangle}) =>
    BoxDecoration(
      color: Colors.black.withValues(alpha: 0.38),
      shape: shape,
      borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(24),
      border: Border.all(color: CasinoColors.gold.withValues(alpha: 0.28)),
    );

class _HudIconButton extends StatelessWidget {
  const _HudIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.badge = 0,
  });

  final List<List<dynamic>> icon;
  final String tooltip;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Ink(
            width: 44,
            height: 44,
            decoration: _hudDecoration(shape: BoxShape.circle),
            child: Center(
              child: Badge(
                isLabelVisible: badge > 0,
                label: Text('$badge'),
                backgroundColor: CasinoColors.gold,
                textColor: CasinoColors.bg,
                child: HugeIcon(
                  icon: icon,
                  color: CasinoColors.goldSoft,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown under the top bar while the socket is down or reconnecting.
/// Reconnecting is automatic (periodic check + backoff), so no retry button.
class _ConnectionBanner extends StatelessWidget {
  const _ConnectionBanner({required this.connection});

  final ConnectionStatus connection;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final offline = connection == ConnectionStatus.disconnected;
    final accent = offline ? CasinoColors.foldHi : CasinoColors.gold;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsetsDirectional.fromSTEB(14, 2, 4, 2),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            const SuitCardLoader(height: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                offline ? l10n.offlineReconnecting : l10n.connecting,
                style: const TextStyle(
                  color: CasinoColors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
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
