import 'package:cardgame/app/navigation_providers.dart';
import 'package:cardgame/app/push_providers.dart';
import 'package:cardgame/services/notification_deeplink.dart';
import 'package:cardgame/services/push_notification_api_service.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:cardgame/ui/theme/app_icons.dart';

Future<void> showNotificationsPanel(BuildContext context, WidgetRef ref) {
  ref.read(notificationsInboxProvider.notifier).refresh();
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.65),
    builder: (_) => const NotificationsPanel(),
  );
}

class NotificationsPanel extends ConsumerWidget {
  const NotificationsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncInbox = ref.watch(notificationsInboxProvider);
    final maxHeight = MediaQuery.of(context).size.height * 0.72;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 380, maxHeight: maxHeight),
          child: Material(
            color: CasinoColors.surface,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Notifications',
                          style: TextStyle(
                            color: CasinoColors.gold,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      if ((asyncInbox.value?.unreadCount ?? 0) > 0)
                        TextButton(
                          onPressed: () => ref
                              .read(notificationsInboxProvider.notifier)
                              .markAllRead(),
                          child: const Text(
                            'Mark all read',
                            style: TextStyle(color: CasinoColors.gold),
                          ),
                        ),
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const HugeIcon(icon: AppIcons.close, color: CasinoColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: asyncInbox.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          color: CasinoColors.gold,
                        ),
                      ),
                      error: (_, __) => const Center(
                        child: Text(
                          'No notifications yet',
                          style: TextStyle(color: CasinoColors.textMuted),
                        ),
                      ),
                      data: (inbox) {
                        if (inbox.notifications.isEmpty) {
                          return const Center(
                            child: Text(
                              'No notifications yet',
                              style: TextStyle(color: CasinoColors.textMuted),
                            ),
                          );
                        }
                        return ListView.separated(
                          itemCount: inbox.notifications.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = inbox.notifications[index];
                            return _NotificationTile(
                              notification: item,
                              onTap: () {
                                if (!item.read) {
                                  ref
                                      .read(
                                        notificationsInboxProvider.notifier,
                                      )
                                      .markRead(item.id);
                                }
                              },
                              onCta: () async {
                                if (!item.read) {
                                  await ref
                                      .read(
                                        notificationsInboxProvider.notifier,
                                      )
                                      .markRead(item.id);
                                }
                                if (!context.mounted) return;
                                Navigator.of(context).maybePop();
                                final nav = resolveNotificationNav({
                                  'type': item.type,
                                  ...item.data,
                                });
                                if (nav == null) return;
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  ref
                                      .read(notificationNavigatorProvider)
                                      .navigate(nav);
                                });
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onCta,
  });

  final PlayerNotification notification;
  final VoidCallback onTap;
  final VoidCallback onCta;

  @override
  Widget build(BuildContext context) {
    final cta = _ctaFor(notification);
    final unread = !notification.read;

    return Material(
      color: CasinoColors.bgElevated,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (unread)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: const BoxDecoration(
                        color: CasinoColors.gold,
                        shape: BoxShape.circle,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      notification.title,
                      style: TextStyle(
                        color:
                            unread ? CasinoColors.text : CasinoColors.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                notification.body,
                style: TextStyle(
                  color: unread ? CasinoColors.text : CasinoColors.textMuted,
                ),
              ),
              if (cta != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: onCta,
                    child: Text(
                      cta,
                      style: const TextStyle(color: CasinoColors.gold),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String? _ctaFor(PlayerNotification notification) {
  switch (notification.type) {
    case 'table_invite':
    case 'room_invite':
      return 'Join';
    case 'friend_request':
    case 'friend_accepted':
      return 'View';
    case 'rank_passed':
      return 'Leaderboard';
    case 'marketing':
      final route = notification.data['route']?.toString();
      if (route != null && route.isNotEmpty) return 'Open';
      return null;
    default:
      return null;
  }
}
