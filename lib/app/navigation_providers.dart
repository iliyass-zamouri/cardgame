import 'package:cardgame/services/notification_deeplink.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Root [NavigatorState] key for MaterialApp + notification deeplinks.
final rootNavigatorKeyProvider = Provider<GlobalKey<NavigatorState>>((ref) {
  return GlobalKey<NavigatorState>();
});

class JoinRoomBinder {
  void Function(String roomId)? callback;

  void call(String roomId) => callback?.call(roomId);
}

final joinRoomBinderProvider = Provider<JoinRoomBinder>((ref) {
  return JoinRoomBinder();
});

final notificationNavigatorProvider = Provider<NotificationNavigator>((ref) {
  final binder = ref.watch(joinRoomBinderProvider);
  return NotificationNavigator(
    navigatorKey: ref.watch(rootNavigatorKeyProvider),
    onJoinRoom: binder.call,
  );
});
