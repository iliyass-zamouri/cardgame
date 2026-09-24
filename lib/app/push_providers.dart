import 'package:cardgame/app/auth_providers.dart';
import 'package:cardgame/data/auth/auth_config.dart';
import 'package:cardgame/services/push_notification_api_service.dart';
import 'package:cardgame/services/push_notification_service.dart';
import 'package:cardgame/services/push_prefs_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final pushPrefsRepositoryProvider = Provider<PushPrefsRepository>((ref) {
  throw UnimplementedError(
    'pushPrefsRepositoryProvider must be overridden in main()',
  );
});

final pushNotificationApiServiceProvider = Provider<PushNotificationApiService>(
  (ref) {
    return PushNotificationApiService(baseUrl: httpBaseUrl);
  },
);

final pushNotificationServiceProvider = Provider<PushNotificationService>((
  ref,
) {
  final service = PushNotificationService(
    api: ref.watch(pushNotificationApiServiceProvider),
  );
  ref.onDispose(() => service.dispose());
  return service;
});

final notifyPrefsProvider =
    AsyncNotifierProvider<NotifyPrefsNotifier, NotifyPrefs>(
      NotifyPrefsNotifier.new,
    );

class NotifyPrefsNotifier extends AsyncNotifier<NotifyPrefs> {
  @override
  Future<NotifyPrefs> build() async {
    final profile = ref.watch(playerProfileProvider).value;
    final playerId = profile?.playerId;
    if (playerId == null || playerId.isEmpty) {
      return const NotifyPrefs.allOn();
    }
    try {
      return await ref
          .read(pushNotificationApiServiceProvider)
          .getNotifyPrefs(playerId);
    } catch (_) {
      return const NotifyPrefs.allOn();
    }
  }

  Future<void> setInvites(bool value) => _patch(invites: value);
  Future<void> setSocial(bool value) => _patch(social: value);
  Future<void> setRanking(bool value) => _patch(ranking: value);
  Future<void> setMarketing(bool value) => _patch(marketing: value);

  Future<void> _patch({
    bool? invites,
    bool? social,
    bool? ranking,
    bool? marketing,
  }) async {
    final profile = ref.read(playerProfileProvider).value;
    final playerId = profile?.playerId;
    final previous = state.value ?? const NotifyPrefs.allOn();
    final optimistic = previous.copyWith(
      invites: invites,
      social: social,
      ranking: ranking,
      marketing: marketing,
    );
    state = AsyncData(optimistic);
    if (playerId == null || playerId.isEmpty) return;
    try {
      final updated = await ref
          .read(pushNotificationApiServiceProvider)
          .updateNotifyPrefs(
            playerId: playerId,
            invites: invites,
            social: social,
            ranking: ranking,
            marketing: marketing,
          );
      state = AsyncData(updated);
    } catch (_) {
      state = AsyncData(previous);
    }
  }
}

final notificationsInboxProvider =
    AsyncNotifierProvider<NotificationsInboxNotifier, NotificationsInbox>(
      NotificationsInboxNotifier.new,
    );

final notificationsUnreadCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsInboxProvider).value?.unreadCount ?? 0;
});

class NotificationsInboxNotifier extends AsyncNotifier<NotificationsInbox> {
  @override
  Future<NotificationsInbox> build() async {
    final profile = ref.watch(playerProfileProvider).value;
    final playerId = profile?.playerId;
    if (playerId == null || playerId.isEmpty) {
      return const NotificationsInbox.empty();
    }
    try {
      return await ref
          .read(pushNotificationApiServiceProvider)
          .listNotifications(playerId);
    } catch (_) {
      return const NotificationsInbox.empty();
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final profile = ref.read(playerProfileProvider).value;
      final playerId = profile?.playerId;
      if (playerId == null || playerId.isEmpty) {
        return const NotificationsInbox.empty();
      }
      return ref
          .read(pushNotificationApiServiceProvider)
          .listNotifications(playerId);
    });
  }

  Future<void> markRead(int id) async {
    final current = state.value;
    if (current == null) return;
    final profile = ref.read(playerProfileProvider).value;
    final playerId = profile?.playerId;
    if (playerId == null || playerId.isEmpty) return;

    final updated =
        current.notifications
            .map((n) => n.id == id ? n.copyWith(read: true) : n)
            .toList();
    final unread = updated.where((n) => !n.read).length;
    state = AsyncData(
      NotificationsInbox(
        notifications: updated,
        total: current.total,
        unreadCount: unread,
      ),
    );

    try {
      final result = await ref
          .read(pushNotificationApiServiceProvider)
          .markNotificationsRead(playerId: playerId, ids: [id]);
      state = AsyncData(
        NotificationsInbox(
          notifications: updated,
          total: result.total,
          unreadCount: result.unreadCount,
        ),
      );
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    final current = state.value;
    if (current == null || current.unreadCount == 0) return;
    final profile = ref.read(playerProfileProvider).value;
    final playerId = profile?.playerId;
    if (playerId == null || playerId.isEmpty) return;

    final updated =
        current.notifications.map((n) => n.copyWith(read: true)).toList();
    state = AsyncData(
      NotificationsInbox(
        notifications: updated,
        total: current.total,
        unreadCount: 0,
      ),
    );

    try {
      final result = await ref
          .read(pushNotificationApiServiceProvider)
          .markNotificationsRead(playerId: playerId, all: true);
      state = AsyncData(
        NotificationsInbox(
          notifications: updated,
          total: result.total,
          unreadCount: result.unreadCount,
        ),
      );
    } catch (_) {}
  }
}
