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
import 'package:cardgame/ui/screens/friends_screen.dart';
import 'package:cardgame/ui/screens/home/stake_selector_modal.dart';
import 'package:cardgame/ui/screens/how_to_play_screen.dart';
import 'package:cardgame/ui/screens/marketplace_screen.dart';
import 'package:cardgame/ui/screens/notifications/notifications_panel.dart';
import 'package:cardgame/ui/screens/profile/player_profile_screen.dart';
import 'package:cardgame/ui/screens/ranking/global_ranking_screen.dart';
import 'package:cardgame/ui/screens/settings_screen.dart';
import 'package:cardgame/ui/theme/casino_chrome.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/widgets/currency_icon.dart';
import 'package:cardgame/ui/widgets/player_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:cardgame/ui/theme/app_icons.dart';

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
    if (_softPromptChecked || !mounted) return;
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
      backgroundColor: CasinoColors.bg,
      body: SafeArea(
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
                connected: connected,
                connection: connection,
                unreadNotifications: unread,
                onProfile:
                    () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => const PlayerProfileScreen(),
                      ),
                    ),
                onMarketplace:
                    () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => const MarketplaceScreen(),
                      ),
                    ),
                onNotifications: () => showNotificationsPanel(context, ref),
                onSettings:
                    () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => const SettingsScreen(),
                      ),
                    ),
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
                            Image.asset(
                              'assets/logo/text.png',
                              width: compact ? 260 : 320,
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
                            SizedBox(height: compact ? 40 : 60),
                            Center(
                              child: CasinoActionButton(
                                label: l10n.findMatch,
                                icon: AppIcons.bolt,
                                tone: CasinoActionTone.raise,
                                expanded: false,
                                height: 58,
                                onPressed:
                                    connected
                                        ? () => showStakeSelectorModal(context)
                                        : null,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: CasinoActionButton(
                                label: l10n.createRoom,
                                icon: AppIcons.addHome,
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
                                icon: AppIcons.login,
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
                              child: TextButton.icon(
                                onPressed:
                                    () => Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder:
                                            (context) =>
                                                const GlobalRankingScreen(),
                                      ),
                                    ),
                                icon: const HugeIcon(icon: AppIcons.trendingUp, size: 24,
                                ),
                                label: Text(l10n.globalRanking),
                                style: TextButton.styleFrom(
                                  foregroundColor: CasinoColors.textMuted,
                                ),
                              ),
                            ),
                            Center(
                              child: TextButton.icon(
                                onPressed:
                                    () => Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder:
                                            (context) =>
                                                const MarketplaceScreen(),
                                      ),
                                    ),
                                icon: const HugeIcon(icon: AppIcons.style, size: 24),
                                label: Text(l10n.marketplace),
                                style: TextButton.styleFrom(
                                  foregroundColor: CasinoColors.textMuted,
                                ),
                              ),
                            ),
                            Center(
                              child: TextButton.icon(
                                onPressed:
                                    () => Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder:
                                            (context) => const FriendsScreen(),
                                      ),
                                    ),
                                icon: Badge.count(
                                  count: connectedFriendsCount,
                                  isLabelVisible: connectedFriendsCount > 0,
                                  backgroundColor: CasinoColors.gold,
                                  textColor: CasinoColors.bg,
                                  textStyle: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  child: const HugeIcon(icon: AppIcons.people, size: 24,
                                  ),
                                ),
                                label: Text(l10n.friends),
                                style: TextButton.styleFrom(
                                  foregroundColor: CasinoColors.textMuted,
                                ),
                              ),
                            ),
                            if (connection ==
                                ConnectionStatus.disconnected) ...[
                              const SizedBox(height: 16),
                              Center(
                                child: TextButton.icon(
                                  onPressed: notifier.connect,
                                  icon: const HugeIcon(icon: AppIcons.refresh, size: 24,
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
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
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
                          () => notifier.playVsRobot(robotName: l10n.robotName),
                      style: TextButton.styleFrom(
                        foregroundColor: CasinoColors.textMuted,
                        visualDensity: VisualDensity.compact,
                      ),
                      child: Text(l10n.playVsRobot),
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
    required this.username,
    required this.avatarId,
    required this.money,
    required this.chips,
    required this.connected,
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
  final bool connected;
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

    final iconBtnStyle = IconButton.styleFrom(
      padding: EdgeInsets.zero,
      minimumSize: const Size(32, 32),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );

    return Row(
      children: [
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onProfile,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                child: Row(
                  children: [
                    PlayerAvatar(avatarId: avatarId, size: 34),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: CasinoColors.text,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 3),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
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
        const SizedBox(width: 4),
        // Currency pills / Marketplace button
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onMarketplace,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                color: CasinoColors.bgElevated.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: CasinoColors.gold.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CashIcon(size: 18),
                  const SizedBox(width: 3),
                  Text(
                    '$money',
                    style: const TextStyle(
                      color: CasinoColors.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const ChipIcon(size: 18),
                  const SizedBox(width: 3),
                  Text(
                    '$chips',
                    style: const TextStyle(
                      color: CasinoColors.goldSoft,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 2),
        IconButton(
          tooltip: 'Notifications',
          onPressed: onNotifications,
          style: iconBtnStyle,
          icon: Badge(
            isLabelVisible: unreadNotifications > 0,
            label: Text('$unreadNotifications'),
            backgroundColor: CasinoColors.gold,
            textColor: CasinoColors.bg,
            child: const HugeIcon(icon: AppIcons.notifications, color: CasinoColors.textMuted,
              size: 22,
            ),
          ),
        ),
        IconButton(
          tooltip: l10n.settings,
          onPressed: onSettings,
          style: iconBtnStyle,
          icon: const HugeIcon(icon: AppIcons.settings, color: CasinoColors.textMuted,
            size: 22,
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
