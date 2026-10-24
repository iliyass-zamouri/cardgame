import 'dart:async';
import 'dart:math' as math;

import 'package:cardgame/app/auth_providers.dart';
import 'package:cardgame/app/daily_reward_providers.dart';
import 'package:cardgame/app/friends_providers.dart';
import 'package:cardgame/app/game_session_controller.dart';
import 'package:cardgame/app/game_session_state.dart';
import 'package:cardgame/app/home_menu_providers.dart';
import 'package:cardgame/app/player_profile_repository.dart';
import 'package:cardgame/app/push_providers.dart';
import 'package:cardgame/app/ranking_providers.dart';
import 'package:cardgame/app/session_auth_status.dart';
import 'package:cardgame/data/auth/apple_sign_in_service.dart';
import 'package:cardgame/data/avatars/avatar_catalog.dart';
import 'package:cardgame/data/app/home_menu_config.dart';
import 'package:cardgame/data/auth/guest_google_link.dart';
import 'package:cardgame/l10n/l10n_ext.dart';
import 'package:cardgame/services/analytics_service.dart';
import 'package:cardgame/ui/flame/suit_shapes.dart';
import 'package:cardgame/ui/screens/collection_screen.dart';
import 'package:cardgame/ui/screens/daily_reward/daily_entry_pill.dart';
import 'package:cardgame/ui/screens/daily_reward/daily_reward_modal.dart';
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
import 'package:cardgame/ui/theme/wide_layout.dart';
import 'package:cardgame/ui/widgets/country_flag.dart';
import 'package:cardgame/ui/widgets/hud_counter.dart';
import 'package:cardgame/ui/widgets/player_avatar.dart';
import 'package:cardgame/ui/widgets/reward_fly_overlay.dart';
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
  HomeNavTab _tab = HomeNavTab.home;
  final _pagesKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeSoftPrompts());
  }

  Future<void> _maybeSoftPrompts() async {
    if (_softPromptChecked || !mounted || TrailerMode.enabled) return;
    _softPromptChecked = true;

    // A waiting streak reward goes first and takes this visit's slot.
    final showedDaily = await _maybeDailyRewards();
    if (!mounted || showedDaily) return;
    final showedPush = await _maybeSoftPushPrompt();
    if (!mounted) return;
    if (showedPush) return;
    await _maybeGuestLinkPrompt();
  }

  /// The welcome-back gift and the streak, when something waits to be
  /// claimed. New players are offered the tutorial first and meet the streak
  /// on their next start. Returns true if anything was shown.
  Future<bool> _maybeDailyRewards() async {
    DailyRewardView? view;
    try {
      // On a cold start the saved profile may still be loading.
      final profile = await ref
          .read(playerProfileProvider.future)
          .timeout(const Duration(seconds: 4));
      if (profile.isEmpty || !profile.tutorialDone || !mounted) return false;
      view = await ref
          .read(dailyRewardProvider.future)
          .timeout(const Duration(seconds: 6));
    } catch (_) {
      return false;
    }
    if (!mounted || view == null || !view.status.needsAttention) return false;
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return false;
    await openDailyRewards(context, ref, source: 'launch');
    return true;
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
          title: Text(
            'Stay in the loop',
            style: TextStyle(color: CasinoColors.gold),
          ),
          content: Text(
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
    final offerApple = AppleSignInService.isSupported;
    final action = await showDialog<_GuestLinkPromptAction>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: CasinoColors.surface,
          title: Text(
            l10n.saveProgressTitle,
            style: TextStyle(color: CasinoColors.gold),
          ),
          content: Text(
            offerApple ? l10n.saveProgressBodyIos : l10n.saveProgressBody,
            style: TextStyle(color: CasinoColors.text),
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
            if (offerApple)
              TextButton(
                onPressed:
                    () => Navigator.of(
                      dialogContext,
                    ).pop(_GuestLinkPromptAction.linkApple),
                child: Text(
                  l10n.linkAppleAccount,
                  style: TextStyle(color: CasinoColors.gold),
                ),
              ),
            TextButton(
              onPressed:
                  () => Navigator.of(
                    dialogContext,
                  ).pop(_GuestLinkPromptAction.link),
              child: Text(
                l10n.linkGoogleAccount,
                style: TextStyle(color: CasinoColors.gold),
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
      case _GuestLinkPromptAction.linkApple:
        await prefs.markShown();
        if (!mounted) return;
        final isApple = action == _GuestLinkPromptAction.linkApple;
        final result = await linkOrSignInWithProvider(
          provider:
              isApple ? OAuthLinkProvider.apple : OAuthLinkProvider.google,
          context: context,
          ref: ref,
        );
        if (!mounted) return;
        if (result.outcome == GuestGoogleLinkOutcome.linked) {
          CasinoToast.show(
            context,
            isApple ? l10n.linkAppleSuccess : l10n.linkGoogleSuccess,
          );
        } else if (result.outcome == GuestGoogleLinkOutcome.switched) {
          CasinoToast.show(
            context,
            isApple ? l10n.linkAppleSwitched : l10n.linkGoogleSwitched,
          );
        } else if (result.outcome == GuestGoogleLinkOutcome.failed &&
            result.errorMessage != null) {
          CasinoToast.show(context, result.errorMessage!, success: false);
        }
    }
  }

  void _select(HomeNavTab tab) {
    if (tab != _tab) setState(() => _tab = tab);
  }

  RailDockItem _navItem(HomeNavTab tab, int friendsBadge, bool selected) {
    final l10n = context.l10n;
    final (art, label) = switch (tab) {
      HomeNavTab.shop => (NavArt.shop, l10n.shop),
      HomeNavTab.friends => (NavArt.friends, l10n.friends),
      HomeNavTab.home => (NavArt.home, l10n.home),
      HomeNavTab.collection => (NavArt.collection, l10n.collection),
      HomeNavTab.rules => (NavArt.rules, l10n.howToPlay),
    };
    return RailDockItem(
      art: art,
      label: label,
      badge: tab == HomeNavTab.friends ? friendsBadge : 0,
      selected: selected,
      onTap: () => _select(tab),
    );
  }

  static Widget _page(HomeNavTab tab) => switch (tab) {
    HomeNavTab.home => const _HomeTab(),
    HomeNavTab.shop => const MarketplaceScreen(),
    HomeNavTab.friends => const FriendsScreen(),
    HomeNavTab.collection => const CollectionScreen(),
    HomeNavTab.rules => const HowToPlayScreen(),
  };

  @override
  Widget build(BuildContext context) {
    final menu = ref.watch(homeMenuProvider);
    final friendsBadge = ref.watch(connectedFriendsCountProvider);
    // The server may drop the open tab; fall back to home.
    final current = menu.nav.contains(_tab) ? _tab : HomeNavTab.home;
    final items = [
      for (final tab in menu.nav) _navItem(tab, friendsBadge, tab == current),
    ];
    // Keyed so the pages keep their state as a window resize swaps layouts.
    final pages = _TabStack(key: _pagesKey, current: current, builder: _page);

    return PopScope(
      canPop: current == HomeNavTab.home,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _select(HomeNavTab.home);
      },
      child: Scaffold(
        backgroundColor: CasinoColors.feltDeep,
        body:
            WideLayout.of(context)
                ? Row(
                  children: [
                    HomeNavRail(items: items),
                    Expanded(child: pages),
                  ],
                )
                : Stack(
                  children: [
                    // Pages run down to the arc's ends so the arc curves
                    // over them instead of over a straight cut.
                    Positioned.fill(
                      bottom:
                          HomeNavBar.barHeight +
                          MediaQuery.paddingOf(context).bottom,
                      child: MediaQuery.removePadding(
                        context: context,
                        removeBottom: true,
                        child: pages,
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: HomeNavBar(items: items),
                    ),
                  ],
                ),
      ),
    );
  }
}

void _pushScreen(BuildContext context, Widget screen) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (context) => screen));
}

/// Keeps every visited tab page mounted (state, scroll and loaded data
/// survive switches) but only builds a page on its first visit. Hidden pages
/// are offstage with tickers paused; the incoming page fades in on top.
class _TabStack extends StatefulWidget {
  const _TabStack({super.key, required this.current, required this.builder});

  final HomeNavTab current;
  final Widget Function(HomeNavTab tab) builder;

  @override
  State<_TabStack> createState() => _TabStackState();
}

class _TabStackState extends State<_TabStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
    value: 1,
  )..addStatusListener((status) {
    if (status == AnimationStatus.completed && _outgoing != null) {
      setState(() => _outgoing = null);
    }
  });
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _fade,
    curve: Curves.easeOut,
  );

  /// Built pages, cached so switching tabs never rebuilds them.
  late final Map<HomeNavTab, Widget> _pages = {
    widget.current: widget.builder(widget.current),
  };

  /// Page still shown under the incoming one while it fades in.
  HomeNavTab? _outgoing;

  @override
  void didUpdateWidget(_TabStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    final current = widget.current;
    if (current == oldWidget.current) return;
    _pages.putIfAbsent(current, () => widget.builder(current));
    if (MediaQuery.disableAnimationsOf(context)) {
      _outgoing = null;
      _fade.value = 1;
    } else {
      _outgoing = oldWidget.current;
      _fade.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  Widget _layer(HomeNavTab tab) {
    final active = tab == widget.current;
    return Offstage(
      key: ValueKey(tab),
      offstage: !active && tab != _outgoing,
      child: TickerMode(
        enabled: active,
        child: IgnorePointer(
          ignoring: !active,
          // Always wrapped the same way so pages keep their state.
          child: FadeTransition(
            opacity: active ? _opacity : kAlwaysCompleteAnimation,
            child: RepaintBoundary(child: _pages[tab]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // The current page paints last so it fades in over the outgoing one.
    return Stack(
      fit: StackFit.expand,
      children: [
        for (final tab in _pages.keys)
          if (tab != widget.current) _layer(tab),
        _layer(widget.current),
      ],
    );
  }
}

/// The home tab: profile bar, logo, hero fan and the play actions.
class _HomeTab extends ConsumerWidget {
  const _HomeTab();

  Widget _modeCard(
    BuildContext context,
    WidgetRef ref,
    HomeMode mode,
    double height,
    bool connected,
  ) {
    final l10n = context.l10n;
    final notifier = ref.read(gameSessionProvider.notifier);
    return switch (mode) {
      HomeMode.createRoom => ModePlayingCard(
        label: l10n.createRoom,
        suit: SuitShape.hearts,
        icon: AppIcons.addHome,
        height: height,
        onTap: connected ? notifier.createRoom : null,
      ),
      HomeMode.joinRoom => ModePlayingCard(
        label: l10n.joinRoom,
        suit: SuitShape.diamonds,
        icon: AppIcons.login,
        height: height,
        onTap: connected ? () => _showJoinRoomDialog(context) : null,
      ),
      HomeMode.playVsRobot => ModePlayingCard(
        label: l10n.playVsRobot,
        suit: SuitShape.clubs,
        icon: AppIcons.game,
        height: height,
        onTap: () => notifier.playVsRobot(robotName: l10n.robotName),
      ),
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final modes = ref.watch(homeMenuProvider.select((menu) => menu.modes));
    final connection = ref.watch(
      gameSessionProvider.select((state) => state.connection),
    );
    final connected = connection == ConnectionStatus.connected;
    final profile =
        ref.watch(playerProfileProvider).value ?? PlayerProfile.empty;
    final displayName = profile.isEmpty ? l10n.player : profile.name;
    final unread = ref.watch(notificationsUnreadCountProvider);
    final dailyVisible = ref.watch(dailyEntryVisibleProvider);

    Widget logo(double width) => DealIn(
      from: const Offset(0, -0.3),
      child: Image.asset(
        'assets/logo/text.png',
        width: width,
        fit: BoxFit.contain,
      ),
    );
    final tagline = Text(
      l10n.tagline,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: CasinoColors.goldSoft,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
      ),
    );
    const daily = DealIn(
      delay: Duration(milliseconds: 80),
      child: DailyEntryPill(),
    );
    final playCard = DealIn(
      delay: const Duration(milliseconds: 150),
      child: PrimaryPlayCard(
        title: l10n.findMatch,
        subtitle: l10n.winnerTakesAll,
        icon: AppIcons.bolt,
        onTap: connected ? () => showStakeSelectorModal(context) : null,
      ),
    );
    Widget modeRow(double height) => Row(
      children: [
        for (final (i, mode) in modes.indexed) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            key: ValueKey(mode),
            child: _dealtMode(
              i,
              modes.length,
              _modeCard(context, ref, mode, height, connected),
            ),
          ),
        ],
      ],
    );
    final banner = AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      child:
          connected
              ? const SizedBox(width: double.infinity)
              : _ConnectionBanner(connection: connection),
    );

    final Widget body;
    if (WideLayout.of(context)) {
      // Side by side: the logo and fan on one side, the ways to play on the
      // other, centred at a comfortable width however wide the window.
      body = Padding(
        padding: const EdgeInsets.fromLTRB(28, 12, 28, 20),
        child: Column(
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: WideLayout.contentMaxWidth,
              ),
              child: banner,
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final height = constraints.maxHeight;
                  final width = math.min(
                    constraints.maxWidth,
                    WideLayout.contentMaxWidth,
                  );
                  final logoWidth = (width * 0.32).clamp(280.0, 380.0);
                  // The fan takes what the logo and tagline leave, kept
                  // under the logo's weight.
                  final heroHeight = (height - logoWidth / 3 - 48).clamp(
                    0.0,
                    250.0,
                  );
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: height),
                      child: Center(
                        child: SizedBox(
                          width: width,
                          child: Row(
                            children: [
                              Expanded(
                                flex: 11,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    logo(logoWidth),
                                    tagline,
                                    const SizedBox(height: 12),
                                    if (heroHeight >= 120)
                                      HeroCardFan(
                                        deckSkinId: profile.deckId,
                                        height: heroHeight,
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 48),
                              Expanded(
                                flex: 9,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    if (dailyVisible) ...[
                                      daily,
                                      const SizedBox(height: 16),
                                    ],
                                    playCard,
                                    if (modes.isNotEmpty) ...[
                                      const SizedBox(height: 16),
                                      modeRow(140),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    } else {
      body = SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              banner,
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final height = constraints.maxHeight;
                    final compact = height < 560;
                    final logoWidth = compact ? 220.0 : 280.0;
                    final modeHeight = compact ? 116.0 : 132.0;
                    // Hero fan takes whatever the fixed content leaves.
                    final fixedHeight =
                        logoWidth / 3 +
                        18 +
                        (dailyVisible ? DailyEntryPill.height + 12 : 0) +
                        92 +
                        (modes.isEmpty ? 0 : 14 + modeHeight) +
                        18 +
                        HomeNavBar.arcDrop;
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
                            logo(logoWidth),
                            tagline,
                            if (heroHeight >= 100)
                              HeroCardFan(
                                deckSkinId: profile.deckId,
                                height: heroHeight,
                              )
                            else
                              const SizedBox(height: 20),
                            if (dailyVisible) ...[
                              daily,
                              const SizedBox(height: 12),
                            ],
                            playCard,
                            if (modes.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              modeRow(modeHeight),
                            ],
                            // Clears the nav arc rising over the bottom.
                            const SizedBox(height: 8 + HomeNavBar.arcDrop),
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
      );
    }

    // Opaque so it can fade in over another tab.
    return FeltTableBackground(
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
            onProfile: () => _pushScreen(context, const PlayerProfileScreen()),
            onLeague: () => _pushScreen(context, const GlobalRankingScreen()),
            onMarketplace:
                () => _pushScreen(context, const MarketplaceScreen()),
            onNotifications: () => showNotificationsPanel(context, ref),
            onSettings: () => _pushScreen(context, const SettingsScreen()),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

enum _GuestLinkPromptAction { later, dontAsk, link, linkApple }

/// Deals mode card [index] of [count] in from below, fanning the outer cards
/// in from opposite sides like a dealt hand.
Widget _dealtMode(int index, int count, Widget card) {
  // -1 for the leftmost card, 1 for the rightmost.
  final spread = count < 2 ? 0.0 : index * 2 / (count - 1) - 1;
  return DealIn(
    delay: Duration(milliseconds: 260 + 80 * index),
    from: Offset(-0.4 * spread, 0.6),
    rotation: 0.25 * spread,
    child: card,
  );
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
      shape: feltDialogShape,
      title: Text(
        l10n.joinRoomTitle,
        style: TextStyle(
          color: CasinoColors.text,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.joinRoomHint,
            style: TextStyle(color: CasinoColors.textMuted, fontSize: 14),
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
                style: TextStyle(
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
                    borderSide: BorderSide(
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

  /// Height of the profile and leaderboard cards.
  static const _cardHeight = 70.0;

  /// Widths the wide bar gives its cards and pills when there's room.
  static const _profileWidth = 340.0;
  static const _leagueWidth = 230.0;
  static const _pillWidth = 200.0;

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
    final wide = WideLayout.of(context);
    final radius =
        wide
            ? BorderRadius.circular(20)
            : const BorderRadius.vertical(bottom: Radius.circular(24));
    final top = MediaQuery.paddingOf(context).top;
    final money = _ResourcePill(
      key: HudAnchors.money,
      currency: CurrencyType.money,
      value: this.money,
      onTap: onMarketplace,
    );
    final chips = _ResourcePill(
      key: HudAnchors.chips,
      currency: CurrencyType.chips,
      value: this.chips,
      onTap: onMarketplace,
    );
    final notifications = _RailIconButton(
      icon: AppIcons.notifications,
      tooltip: 'Notifications',
      badge: unreadNotifications,
      onTap: onNotifications,
    );
    final settings = _RailIconButton(
      icon: AppIcons.settings,
      tooltip: l10n.settings,
      onTap: onSettings,
    );
    final profile = _ProfileCard(
      name: name,
      username: username,
      avatarId: avatarId,
      statusColor: statusColor,
      countryCode: myRank?.countryCode,
      totalPoints: ranked?.totalPoints ?? 0,
      onTap: onProfile,
    );
    final league = _LeagueCard(rank: myRank?.rank, onTap: onLeague);

    final Widget content;
    if (wide) {
      // One row: who you are on the left, your purse and alerts on the right.
      content = Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // The cards and pills keep their natural widths, with any extra
            // room opening up between the two groups; a narrower panel
            // shrinks them all alike.
            const gaps = 10 + 24 + 10 + 16 + 8 + 2 * 36.0;
            const natural = _profileWidth + _leagueWidth + 2 * _pillWidth;
            final k = math.min(1.0, (constraints.maxWidth - gaps) / natural);
            return Row(
              children: [
                SizedBox(
                  width: _profileWidth * k,
                  height: _cardHeight,
                  child: profile,
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: _leagueWidth * k,
                  height: _cardHeight,
                  child: league,
                ),
                const Spacer(),
                SizedBox(width: _pillWidth * k, child: money),
                const SizedBox(width: 10),
                SizedBox(width: _pillWidth * k, child: chips),
                const SizedBox(width: 16),
                notifications,
                const SizedBox(width: 8),
                settings,
              ],
            );
          },
        ),
      );
    } else {
      content = Padding(
        padding: EdgeInsets.fromLTRB(12, top + 8, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: money),
                const SizedBox(width: 8),
                Expanded(child: chips),
                const SizedBox(width: 8),
                notifications,
                const SizedBox(width: 6),
                settings,
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: _cardHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 3, child: profile),
                  const SizedBox(width: 8),
                  Expanded(flex: 2, child: league),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final bar = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: const [
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
            // A floating panel is rimmed all round, like the play panels.
            if (wide)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    border: Border.all(
                      color: CasinoColors.gold.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
            content,
          ],
        ),
      ),
    );
    if (!wide) return bar;
    // A wide window floats the bar over the felt, as wide as the page
    // content below it rather than the whole window.
    return Padding(
      padding: EdgeInsets.fromLTRB(28, top + 14, 28, 0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: WideLayout.contentMaxWidth,
          ),
          child: bar,
        ),
      ),
    );
  }
}

LinearGradient get _goldGradient => LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [CasinoColors.goldHi, CasinoColors.gold, CasinoColors.goldLo],
);

/// A top-bar currency counter; tapping it opens the shop.
class _ResourcePill extends StatelessWidget {
  const _ResourcePill({
    super.key,
    required this.currency,
    required this.value,
    required this.onTap,
  });

  final CurrencyType currency;
  final int value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: HudCounter(currency: currency, value: value),
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
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [const Color(0xFF4A2C1B), CasinoColors.leatherDeep],
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

/// Ivory player card in the style of the profile screen's hero card:
/// avatar, display-font name with flag, @username and level badge.
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.name,
    required this.username,
    required this.avatarId,
    required this.statusColor,
    required this.countryCode,
    required this.totalPoints,
    required this.onTap,
  });

  final String name;
  final String username;
  final String avatarId;
  final Color statusColor;
  final String? countryCode;
  final int totalPoints;
  final VoidCallback onTap;

  static const _deepGold = Color(0xFF8A6512);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Same progression as the profile screen: 100 XP per level.
    final level = (totalPoints / 100).floor() + 1;
    final rankTitle = PlayerProfileScreen.getRankTitle(level, l10n);
    return IvoryCard(
      suit: SuitShape.clubs,
      radius: 14,
      padding: const EdgeInsetsDirectional.fromSTEB(10, 6, 14, 6),
      onTap: onTap,
      child: Row(
        children: [
          PlayerAvatar(
            avatarId: avatarId,
            size: 50,
            borderWidth: 2,
            borderColor: CasinoColors.gold,
            showGlow: true,
            statusDotColor: statusColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: CasinoFonts.displayOf(context),
                          color: CardInk.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          height: 1.15,
                        ),
                      ),
                    ),
                    if (flagEmoji(countryCode).isNotEmpty) ...[
                      const SizedBox(width: 6),
                      CountryFlag(code: countryCode, size: 14),
                    ],
                  ],
                ),
                if (username.isNotEmpty)
                  Text(
                    '@$username',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _deepGold,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7),
                    gradient: LinearGradient(
                      colors: [CasinoColors.goldHi, CasinoColors.gold],
                    ),
                  ),
                  child: Text(
                    '${l10n.levelNumber(level)} · $rankTitle',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: CardInk.black,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
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
                    child: HugeIcon(
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
                style: TextStyle(
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
