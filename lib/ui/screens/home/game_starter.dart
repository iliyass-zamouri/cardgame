import 'dart:async';

import 'package:cardgame/app/auth_providers.dart';
import 'package:cardgame/app/friends_providers.dart';
import 'package:cardgame/app/game_session_controller.dart';
import 'package:cardgame/app/game_session_state.dart';
import 'package:cardgame/app/player_profile_repository.dart';
import 'package:cardgame/app/push_providers.dart';
import 'package:cardgame/app/ranking_providers.dart';
import 'package:cardgame/app/session_auth_status.dart';
import 'package:cardgame/data/auth/guest_google_link.dart';
import 'package:cardgame/l10n/l10n_ext.dart';
import 'package:cardgame/services/analytics_service.dart';
import 'package:cardgame/ui/flame/suit_shapes.dart';
import 'package:cardgame/ui/screens/friends_screen.dart';
import 'package:cardgame/ui/screens/home/home_menu_widgets.dart';
import 'package:cardgame/ui/screens/home/nav_art.dart';
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
import 'package:cardgame/ui/widgets/country_flag.dart';
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
        child: Column(
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
              onLeague: () => _push(const GlobalRankingScreen()),
              onMarketplace: () => _push(const MarketplaceScreen()),
              onNotifications: () => showNotificationsPanel(context, ref),
              onSettings: () => _push(const SettingsScreen()),
            ),
            Expanded(
              child: SafeArea(
                top: false,
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                                                ? () => showStakeSelectorModal(
                                                  context,
                                                )
                                                : null,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: DealIn(
                                            delay: const Duration(
                                              milliseconds: 260,
                                            ),
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
                                            delay: const Duration(
                                              milliseconds: 340,
                                            ),
                                            from: const Offset(0, 0.6),
                                            child: ModePlayingCard(
                                              label: l10n.joinRoom,
                                              suit: SuitShape.diamonds,
                                              icon: AppIcons.login,
                                              height: modeHeight,
                                              onTap:
                                                  connected
                                                      ? () =>
                                                          _showJoinRoomDialog(
                                                            context,
                                                          )
                                                      : null,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: DealIn(
                                            delay: const Duration(
                                              milliseconds: 420,
                                            ),
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
                    ],
                  ),
                ),
              ),
            ),
            HomeNavBar(
              items: [
                RailDockItem(
                  art: NavArt.shop,
                  label: l10n.shop,
                  onTap: () => _push(const MarketplaceScreen()),
                ),
                RailDockItem(
                  art: NavArt.friends,
                  label: l10n.friends,
                  badge: connectedFriendsCount,
                  onTap: () => _push(const FriendsScreen()),
                ),
                RailDockItem(
                  art: NavArt.home,
                  label: l10n.home,
                  selected: true,
                  onTap: () {},
                ),
                RailDockItem(
                  art: NavArt.ranking,
                  label: l10n.leaderboard,
                  onTap: () => _push(const GlobalRankingScreen()),
                ),
                RailDockItem(
                  art: NavArt.rules,
                  label: l10n.howToPlay,
                  onTap: () => _push(const HowToPlayScreen()),
                ),
              ],
            ),
          ],
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

/// Leather rail across the top of the table: purse, alerts, profile, league.
class _TopBar extends ConsumerWidget {
  const _TopBar({
    required this.name,
    required this.username,
    required this.avatarId,
    required this.money,
    required this.chips,
    required this.connection,
    required this.unreadNotifications,
    required this.onProfile,
    required this.onLeague,
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
  final VoidCallback onLeague;
  final VoidCallback onMarketplace;
  final VoidCallback onNotifications;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    // Rank 0 means the player has no ranked games yet.
    final ranked = ref.watch(myRankProvider).asData?.value;
    final myRank = (ranked?.rank ?? 0) > 0 ? ranked : null;
    final statusColor = switch (connection) {
      ConnectionStatus.connected => const Color(0xFF7ED50E),
      ConnectionStatus.connecting => CasinoColors.gold,
      ConnectionStatus.disconnected => CasinoColors.foldHi,
    };
    const radius = BorderRadius.vertical(bottom: Radius.circular(24));

    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      CasinoColors.leatherDeep,
                      CasinoColors.leather.withValues(alpha: 0.97),
                      const Color(0xFF3A2416),
                    ],
                  ),
                ),
              ),
            ),
            // Gold trim along the rail's lower edge.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 2,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      CasinoColors.gold.withValues(alpha: 0.1),
                      CasinoColors.gold,
                      CasinoColors.gold.withValues(alpha: 0.1),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                MediaQuery.paddingOf(context).top + 8,
                12,
                12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _ResourcePill(
                          icon: const CashIcon(size: 30),
                          value: money,
                          onTap: onMarketplace,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ResourcePill(
                          icon: const ChipIcon(size: 30),
                          value: chips,
                          onTap: onMarketplace,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _RailIconButton(
                        icon: AppIcons.notifications,
                        tooltip: 'Notifications',
                        badge: unreadNotifications,
                        onTap: onNotifications,
                      ),
                      const SizedBox(width: 6),
                      _RailIconButton(
                        icon: AppIcons.settings,
                        tooltip: l10n.settings,
                        onTap: onSettings,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 62,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 3,
                          child: _ProfileCard(
                            name: name,
                            username: username,
                            avatarId: avatarId,
                            statusColor: statusColor,
                            countryCode: myRank?.countryCode,
                            elo: myRank?.elo,
                            onTap: onProfile,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: _LeagueCard(
                            rank: myRank?.rank,
                            onTap: onLeague,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 1234 -> 1234, 12500 -> 12.5K, 1020000 -> 1.02M.
String _compactAmount(int value) {
  String trim(String s) =>
      s.contains('.') ? s.replaceFirst(RegExp(r'\.?0+$'), '') : s;
  if (value >= 1000000) {
    return '${trim((value / 1000000).toStringAsFixed(2))}M';
  }
  if (value >= 10000) return '${trim((value / 1000).toStringAsFixed(1))}K';
  return '$value';
}

const _goldGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFFFFE08A), CasinoColors.gold, Color(0xFFC8961E)],
);

/// Currency counter: coin overlapping a recessed track, gold "+" at the end.
class _ResourcePill extends StatelessWidget {
  const _ResourcePill({
    required this.icon,
    required this.value,
    required this.onTap,
  });

  final Widget icon;
  final int value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return Pressable(
      onTap: onTap,
      child: SizedBox(
        height: 36,
        child: Stack(
          alignment: AlignmentDirectional.centerStart,
          children: [
            Container(
              height: 30,
              margin: const EdgeInsetsDirectional.only(start: 14),
              padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 3, 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.black.withValues(alpha: 0.4),
                  ],
                ),
                border: Border.all(
                  color: CasinoColors.gold.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _compactAmount(value),
                        maxLines: 1,
                        style: TextStyle(
                          fontFamily: CasinoFonts.displayFor(locale),
                          color: CasinoColors.goldSoft,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: _goldGradient,
                      border: Border.all(color: const Color(0xFF7A5A0E)),
                    ),
                    child: const HugeIcon(
                      icon: HugeIcons.strokeRoundedAdd01,
                      size: 16,
                      strokeWidth: 2.6,
                      color: CardInk.black,
                    ),
                  ),
                ],
              ),
            ),
            icon,
          ],
        ),
      ),
    );
  }
}

/// Round leather button with a gold rim, like the in-game HUD buttons.
class _RailIconButton extends StatelessWidget {
  const _RailIconButton({
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
      child: Pressable(
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF4A2C1B), CasinoColors.leatherDeep],
                  ),
                  border: Border.all(
                    color: CasinoColors.gold.withValues(alpha: 0.6),
                  ),
                ),
                alignment: Alignment.center,
                child: HugeIcon(
                  icon: icon,
                  color: CasinoColors.goldSoft,
                  size: 19,
                ),
              ),
              if (badge > 0)
                PositionedDirectional(
                  top: -5,
                  end: -5,
                  child: CountBadge(
                    count: badge,
                    color: CasinoColors.foldHi,
                    borderColor: CasinoColors.goldSoft,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Avatar, name, country and rating on a recessed felt inlay.
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.name,
    required this.username,
    required this.avatarId,
    required this.statusColor,
    required this.countryCode,
    required this.elo,
    required this.onTap,
  });

  final String name;
  final String username;
  final String avatarId;
  final Color statusColor;
  final String? countryCode;
  final int? elo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasFlag = flagEmoji(countryCode).isNotEmpty;
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(6, 4, 8, 4),
        decoration: feltPanelDecoration(radius: 14, highlighted: true),
        child: Row(
          children: [
            PlayerAvatar(
              avatarId: avatarId,
              size: 48,
              borderWidth: 2,
              borderColor: CasinoColors.gold,
              showGlow: true,
              glowColor: CasinoColors.gold.withValues(alpha: 0.3),
              statusDotColor: statusColor,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: CasinoColors.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (hasFlag) ...[
                        CountryFlag(code: countryCode, size: 12),
                        const SizedBox(width: 6),
                      ],
                      if (elo != null)
                        _EloChip(elo: elo!)
                      else if (username.isNotEmpty)
                        Flexible(
                          child: Text(
                            '@$username',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: CasinoColors.goldSoft,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EloChip extends StatelessWidget {
  const _EloChip({required this.elo});

  final int elo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: CasinoColors.gold.withValues(alpha: 0.14),
        border: Border.all(color: CasinoColors.gold.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const HugeIcon(
            icon: AppIcons.medal,
            size: 11,
            color: CasinoColors.gold,
          ),
          const SizedBox(width: 3),
          Text(
            'ELO $elo',
            style: const TextStyle(
              color: CasinoColors.gold,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Gold card linking to the leaderboard, styled like the Find Match card.
class _LeagueCard extends StatelessWidget {
  const _LeagueCard({required this.rank, required this.onTap});

  final int? rank;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return Pressable(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: _goldGradient,
          boxShadow: [
            BoxShadow(
              color: CasinoColors.gold.withValues(alpha: 0.3),
              blurRadius: 14,
              spreadRadius: -4,
            ),
            const BoxShadow(
              color: Color(0x80000000),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: const Color(0xFF7A5A0E).withValues(alpha: 0.45),
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              end: -10,
              top: -8,
              child: SuitGlyph(
                suit: SuitShape.spades,
                size: 72,
                color: Colors.black.withValues(alpha: 0.08),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(8, 0, 8, 0),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: CardInk.black,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x55000000),
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const HugeIcon(
                      icon: AppIcons.trophy,
                      size: 21,
                      color: CasinoColors.gold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            casinoButtonLabel(context.l10n.leaderboard, locale),
                            maxLines: 1,
                            style: TextStyle(
                              fontFamily: CasinoFonts.displayFor(locale),
                              color: CardInk.black,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing:
                                  locale.languageCode == 'ar' ? 0 : 0.6,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          rank == null ? '—' : '#$rank',
                          maxLines: 1,
                          style: const TextStyle(
                            color: Color(0xFF4A3708),
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
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
