import 'dart:async';

import 'package:cardgame/ui/screens/friends_screen.dart';
import 'package:cardgame/ui/screens/ranking/global_ranking_screen.dart';
import 'package:flutter/material.dart';

/// Logical notification destinations (not GoRouter paths).
enum NotificationDestination {
  friends,
  ranking,
  tableInvite,
  home,
}

class ResolvedNotificationNav {
  const ResolvedNotificationNav({
    required this.destination,
    this.roomId,
  });

  final NotificationDestination destination;
  final String? roomId;
}

/// Resolves FCM / inbox [data] into an in-app destination.
ResolvedNotificationNav? resolveNotificationNav(Map<String, dynamic> data) {
  final route = data['route']?.toString();
  if (route != null && route.isNotEmpty) {
    if (route == '/friends' || route.startsWith('/friends')) {
      return const ResolvedNotificationNav(
        destination: NotificationDestination.friends,
      );
    }
    if (route == '/ranking' || route.startsWith('/ranking')) {
      return const ResolvedNotificationNav(
        destination: NotificationDestination.ranking,
      );
    }
    if (route.startsWith('/join') || route.startsWith('/table')) {
      final uri = Uri.tryParse(route);
      final roomId =
          uri?.queryParameters['roomId'] ?? data['roomId']?.toString();
      if (roomId != null && roomId.isNotEmpty) {
        return ResolvedNotificationNav(
          destination: NotificationDestination.tableInvite,
          roomId: roomId.toUpperCase(),
        );
      }
    }
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

/// Navigates so the user can leave the target screen (system back / AppBar pop).
class NotificationNavigator {
  NotificationNavigator({
    required this.navigatorKey,
    required this.onJoinRoom,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final void Function(String roomId) onJoinRoom;

  void navigate(ResolvedNotificationNav nav) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    switch (nav.destination) {
      case NotificationDestination.friends:
        navigator.push(
          MaterialPageRoute<void>(builder: (_) => const FriendsScreen()),
        );
      case NotificationDestination.ranking:
        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => const GlobalRankingScreen(),
          ),
        );
      case NotificationDestination.home:
        navigator.popUntil((route) => route.isFirst);
      case NotificationDestination.tableInvite:
        final roomId = nav.roomId;
        navigator.popUntil((route) => route.isFirst);
        if (roomId == null || roomId.isEmpty) return;
        scheduleMicrotask(() => _confirmJoinTable(roomId));
    }
  }

  Future<void> _confirmJoinTable(String roomId) async {
    final context = navigatorKey.currentContext;
    if (context == null || !context.mounted) {
      onJoinRoom(roomId);
      return;
    }

    final join = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E24),
          title: const Text(
            'Table invite',
            style: TextStyle(color: Color(0xFFF5C542)),
          ),
          content: Text(
            'Join room $roomId?',
            style: const TextStyle(color: Color(0xFFF2F2F5)),
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
      onJoinRoom(roomId);
    }
  }
}
