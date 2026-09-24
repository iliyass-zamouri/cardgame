import 'dart:async';
import 'dart:io';

import 'package:cardgame/services/notification_deeplink.dart';
import 'package:cardgame/services/push_notification_api_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Background isolate entry — must be top-level.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp();
    } catch (_) {}
  }
}

class PushNotificationService {
  PushNotificationService({required PushNotificationApiService api})
    : _api = api;

  static const androidChannelId = 'shadowhand_default';
  static const androidChannelName = 'Shadow Hand';

  final PushNotificationApiService _api;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  NotificationNavigator? _navigator;
  String? _playerId;
  String? _token;
  ResolvedNotificationNav? _pendingNav;
  bool _started = false;
  StreamSubscription<String>? _tokenSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedSub;

  bool _permissionRequested = false;

  VoidCallback? onInboxChanged;

  Future<void> start({required NotificationNavigator navigator}) async {
    if (kIsWeb) return;
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }
    if (Firebase.apps.isEmpty) {
      debugPrint('[push] Firebase not initialized — skip FCM');
      return;
    }
    if (_started) {
      _navigator = navigator;
      flushPendingRoute();
      return;
    }
    _started = true;
    _navigator = navigator;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    final androidPlugin =
        _local
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        androidChannelId,
        androidChannelName,
        description: 'Game invites, friends, ranking, and news',
        importance: Importance.high,
      ),
    );

    final messaging = FirebaseMessaging.instance;
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    final existing = await messaging.getNotificationSettings();
    debugPrint('[push] existing permission=${existing.authorizationStatus}');
    if (existing.authorizationStatus == AuthorizationStatus.authorized ||
        existing.authorizationStatus == AuthorizationStatus.provisional) {
      await _completePermissionSetup(messaging, androidPlugin);
    } else {
      _foregroundSub = FirebaseMessaging.onMessage.listen(_showForeground);
      _openedSub = FirebaseMessaging.onMessageOpenedApp.listen(
        _handleMessageTap,
      );
      final initial = await messaging.getInitialMessage();
      if (initial != null) {
        scheduleMicrotask(() => _handleMessageTap(initial));
      }
    }

    flushPendingRoute();
  }

  Future<bool> requestPermissionAndRegister() async {
    if (kIsWeb) return false;
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return false;
    }
    if (Firebase.apps.isEmpty) return false;
    if (_permissionRequested && _token != null) return true;

    final messaging = FirebaseMessaging.instance;
    final androidPlugin =
        _local
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    await _completePermissionSetup(messaging, androidPlugin);
    return _token != null && _token!.isNotEmpty;
  }

  Future<void> _completePermissionSetup(
    FirebaseMessaging messaging,
    AndroidFlutterLocalNotificationsPlugin? androidPlugin,
  ) async {
    _permissionRequested = true;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('[push] permission=${settings.authorizationStatus}');

    if (Platform.isAndroid) {
      await androidPlugin?.requestNotificationsPermission();
    }

    _foregroundSub ??= FirebaseMessaging.onMessage.listen(_showForeground);
    _openedSub ??= FirebaseMessaging.onMessageOpenedApp.listen(
      _handleMessageTap,
    );

    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      scheduleMicrotask(() => _handleMessageTap(initial));
    }

    _tokenSub ??= messaging.onTokenRefresh.listen((token) {
      _token = token;
      unawaited(_registerCurrentToken());
    });

    try {
      _token = await messaging.getToken();
      debugPrint('[push] token=${_token == null ? 'null' : 'ok'}');
      await _registerCurrentToken();
    } catch (error) {
      debugPrint('[push] getToken failed: $error');
    }
  }

  Future<void> bindPlayerId(String? playerId) async {
    final trimmed = playerId?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      _playerId = null;
      return;
    }
    if (_playerId == trimmed) {
      flushPendingRoute();
      return;
    }
    _playerId = trimmed;
    await _registerCurrentToken();
    flushPendingRoute();
  }

  Future<void> unregisterCurrentDevice() async {
    final token = _token;
    final playerId = _playerId;
    if (token == null || token.isEmpty) return;
    try {
      await _api.unregisterDevice(token: token, playerId: playerId);
    } catch (e) {
      debugPrint('[push] unregister failed: $e');
    }
  }

  void flushPendingRoute() {
    final pending = _pendingNav;
    final navigator = _navigator;
    if (pending == null || navigator == null) return;
    if (_playerId == null || _playerId!.isEmpty) return;
    _pendingNav = null;
    navigator.navigate(pending);
  }

  Future<void> _registerCurrentToken() async {
    final playerId = _playerId;
    final token = _token;
    if (playerId == null || token == null || token.isEmpty) return;
    final platform = Platform.isIOS ? 'ios' : 'android';
    try {
      await _api.registerDevice(
        playerId: playerId,
        token: token,
        platform: platform,
      );
      debugPrint('[push] registered token for $playerId');
    } catch (error) {
      debugPrint('[push] register failed: $error');
    }
  }

  Future<void> _showForeground(RemoteMessage message) async {
    onInboxChanged?.call();
    // Table invites already get the in-app WS toast — skip duplicate banner.
    final type = message.data['type']?.toString();
    if (type == 'table_invite' || type == 'room_invite') return;
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] as String?;
    final body = notification?.body ?? message.data['body'] as String?;
    if (title == null && body == null) return;

    final details = const NotificationDetails(
      android: AndroidNotificationDetails(
        androidChannelId,
        androidChannelName,
        channelDescription: 'Game invites, friends, ranking, and news',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _local.show(
      message.hashCode,
      title ?? 'ShadowHand',
      body ?? '',
      details,
      payload: _encodePayload(message.data),
    );
  }

  void _onLocalNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    try {
      final data = _decodePayload(payload);
      _navigateForData(data);
    } catch (error) {
      debugPrint('[push] local tap parse failed: $error');
    }
  }

  void _handleMessageTap(RemoteMessage message) {
    _navigateForData(message.data);
  }

  void _navigateForData(Map<String, dynamic> data) {
    final resolved =
        resolveNotificationNav(data) ??
        const ResolvedNotificationNav(
          destination: NotificationDestination.home,
        );
    final navigator = _navigator;
    if (navigator == null || _playerId == null || _playerId!.isEmpty) {
      _pendingNav = resolved;
      return;
    }
    navigator.navigate(resolved);
  }

  String _encodePayload(Map<String, dynamic> data) {
    return data.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent('${e.value}')}',
        )
        .join('&');
  }

  Map<String, dynamic> _decodePayload(String payload) {
    final out = <String, dynamic>{};
    if (payload.isEmpty) return out;
    for (final part in payload.split('&')) {
      final idx = part.indexOf('=');
      if (idx <= 0) continue;
      final key = Uri.decodeComponent(part.substring(0, idx));
      final value = Uri.decodeComponent(part.substring(idx + 1));
      out[key] = value;
    }
    return out;
  }

  Future<void> dispose() async {
    await _tokenSub?.cancel();
    await _foregroundSub?.cancel();
    await _openedSub?.cancel();
  }
}
