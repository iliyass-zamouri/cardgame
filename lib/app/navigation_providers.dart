import 'package:cardgame/services/notification_deeplink.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Root [NavigatorState] key for MaterialApp + notification deeplinks.
final rootNavigatorKeyProvider = Provider<GlobalKey<NavigatorState>>((ref) {
  return GlobalKey<NavigatorState>();
});

/// Bound by the root widget at startup; see [DeeplinkActions].
final deeplinkActionsProvider = Provider<DeeplinkActions>((ref) {
  return DeeplinkActions();
});

final notificationNavigatorProvider = Provider<NotificationNavigator>((ref) {
  return NotificationNavigator(
    navigatorKey: ref.watch(rootNavigatorKeyProvider),
    actions: ref.watch(deeplinkActionsProvider),
  );
});
