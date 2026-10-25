import 'dart:async';

import 'package:cardgame/ui/screens/collection_screen.dart';
import 'package:cardgame/ui/screens/friends_screen.dart';
import 'package:cardgame/ui/screens/home/stake_selector_modal.dart';
import 'package:cardgame/ui/screens/how_to_play_screen.dart';
import 'package:cardgame/ui/screens/marketplace_screen.dart';
import 'package:cardgame/ui/screens/profile/player_profile_screen.dart';
import 'package:cardgame/ui/screens/ranking/global_ranking_screen.dart';
import 'package:cardgame/ui/screens/settings_screen.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:flutter/material.dart';

/// Logical notification destinations (not GoRouter paths). The admin push
/// composer offers the same routes, from server/push/deeplinks.js.
enum NotificationDestination {
  home,
  play,
  robot,
  tableInvite,
  daily,
  shop,
  collection,
  friends,
  ranking,
  profile,
  notifications,
  settings,
  rules,
  tutorial,
}

/// Routes that need no parameters.
const _plainRoutes = {
  '/': NotificationDestination.home,
  '/robot': NotificationDestination.robot,
  '/daily': NotificationDestination.daily,
  '/collection': NotificationDestination.collection,
  '/friends': NotificationDestination.friends,
  '/profile': NotificationDestination.profile,
  '/notifications': NotificationDestination.notifications,
  '/settings': NotificationDestination.settings,
  '/rules': NotificationDestination.rules,
  '/tutorial': NotificationDestination.tutorial,
};

class ResolvedNotificationNav {
  const ResolvedNotificationNav({
    required this.destination,
    this.roomId,
    this.potId,
    this.shopTab,
    this.rankingTab,
  });

  final NotificationDestination destination;
  final String? roomId;

  /// Pot to focus in the picker, one of [StakeSelectorScreen.potOptions].
  final String? potId;
  final MarketplaceTab? shopTab;
  final RankingTab? rankingTab;
}

/// Resolves FCM / inbox [data] into an in-app destination.
ResolvedNotificationNav? resolveNotificationNav(Map<String, dynamic> data) {
  final route = data['route']?.toString().trim();
  if (route != null && route.isNotEmpty) {
    final resolved = _resolveRoute(route, data);
    if (resolved != null) return resolved;
  }

  switch (data['type']?.toString()) {
    case 'table_invite':
    case 'room_invite':
      final roomId = data['roomId']?.toString() ?? data['code']?.toString();
      if (roomId != null && roomId.isNotEmpty) {
        return ResolvedNotificationNav(
          destination: NotificationDestination.tableInvite,
          roomId: roomId.toUpperCase(),
        );
      }
      return const ResolvedNotificationNav(
        destination: NotificationDestination.home,
      );
    case 'friend_request':
    case 'friend_accepted':
      return const ResolvedNotificationNav(
        destination: NotificationDestination.friends,
      );
    case 'rank_passed':
      return const ResolvedNotificationNav(
        destination: NotificationDestination.ranking,
      );
    case 'marketing':
      return null;
    default:
      return null;
  }
}

ResolvedNotificationNav? _resolveRoute(
  String route,
  Map<String, dynamic> data,
) {
  final uri = Uri.tryParse(route);
  if (uri == null) return null;
  var path = uri.path.isEmpty ? '/' : uri.path;
  if (path.length > 1 && path.endsWith('/')) {
    path = path.substring(0, path.length - 1);
  }
  final query = uri.queryParameters;

  final plain = _plainRoutes[path];
  if (plain != null) return ResolvedNotificationNav(destination: plain);

  switch (path) {
    case '/play':
      final pot = query['pot'];
      return ResolvedNotificationNav(
        destination: NotificationDestination.play,
        // An unknown pot still opens the picker, on its first card.
        potId: StakeSelectorScreen.potIndexOf(pot) == null ? null : pot,
      );
    case '/shop':
      return ResolvedNotificationNav(
        destination: NotificationDestination.shop,
        shopTab: MarketplaceTab.values.asNameMap()[query['tab']],
      );
    case '/ranking':
      return ResolvedNotificationNav(
        destination: NotificationDestination.ranking,
        rankingTab: RankingTab.values.asNameMap()[query['tab']],
      );
    case '/join':
    case '/table':
      final roomId = query['roomId'] ?? data['roomId']?.toString();
      if (roomId == null || roomId.isEmpty) return null;
      return ResolvedNotificationNav(
        destination: NotificationDestination.tableInvite,
        roomId: roomId.toUpperCase(),
      );
  }
  return null;
}

/// The page a destination opens above home, or null when it isn't a page.
Widget? notificationPageFor(ResolvedNotificationNav nav) {
  return switch (nav.destination) {
    NotificationDestination.shop => MarketplaceScreen(
      initialTab: nav.shopTab ?? MarketplaceTab.decks,
    ),
    NotificationDestination.collection => const CollectionScreen(),
    NotificationDestination.friends => const FriendsScreen(),
    NotificationDestination.ranking => GlobalRankingScreen(
      initialTab: nav.rankingTab ?? RankingTab.leaderboard,
    ),
    NotificationDestination.profile => const PlayerProfileScreen(),
    NotificationDestination.settings => const SettingsScreen(),
    NotificationDestination.rules => const HowToPlayScreen(),
    NotificationDestination.tutorial => const HowToPlayScreen(autoStart: true),
    _ => null,
  };
}

/// App actions a deeplink needs that live behind providers. The root widget
/// binds them once at startup, since it holds a [WidgetRef].
class DeeplinkActions {
  void Function(String roomId)? joinRoom;

  /// False while a match is running or being searched for.
  bool Function()? canStartMatch;

  Future<void> Function(BuildContext context)? openDailyRewards;
  Future<void> Function(BuildContext context)? openInbox;
  void Function(BuildContext context)? playVsRobot;
}

/// Navigates so the user can leave the target screen (system back / AppBar pop).
class NotificationNavigator {
  NotificationNavigator({
    required this.navigatorKey,
    required this.actions,
    this.pageBuilder = notificationPageFor,
    this.openPotPicker = _openPotPicker,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final DeeplinkActions actions;
  final Widget? Function(ResolvedNotificationNav nav) pageBuilder;
  final Future<void> Function(BuildContext context, String? potId)
  openPotPicker;

  static Future<void> _openPotPicker(BuildContext context, String? potId) =>
      showStakeSelectorModal(context, initialPotId: potId);

  void navigate(ResolvedNotificationNav nav) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    // Every destination opens straight above home, so back always returns
    // there and a second tap replaces the first instead of stacking.
    navigator.popUntil((route) => route.isFirst);
    final context = navigatorKey.currentContext;
    if (context == null) return;
    final canStartMatch = actions.canStartMatch?.call() ?? true;

    switch (nav.destination) {
      case NotificationDestination.home:
        return;
      case NotificationDestination.tableInvite:
        final roomId = nav.roomId;
        if (roomId == null || roomId.isEmpty) return;
        scheduleMicrotask(() => _confirmJoinTable(roomId));
      case NotificationDestination.play:
        if (canStartMatch) unawaited(openPotPicker(context, nav.potId));
      case NotificationDestination.robot:
        if (canStartMatch) actions.playVsRobot?.call(context);
      case NotificationDestination.daily:
        unawaited(actions.openDailyRewards?.call(context));
      case NotificationDestination.notifications:
        unawaited(actions.openInbox?.call(context));
      default:
        final page = pageBuilder(nav);
        if (page == null) return;
        navigator.push(MaterialPageRoute<void>(builder: (_) => page));
    }
  }

  Future<void> _confirmJoinTable(String roomId) async {
    final context = navigatorKey.currentContext;
    if (context == null || !context.mounted) {
      actions.joinRoom?.call(roomId);
      return;
    }

    final join = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E24),
          title: Text(
            'Table invite',
            style: TextStyle(color: CasinoColors.gold),
          ),
          content: Text(
            'Join room $roomId?',
            style: TextStyle(color: CasinoColors.text),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Join'),
            ),
          ],
        );
      },
    );

    if (join == true) {
      actions.joinRoom?.call(roomId);
    }
  }
}
