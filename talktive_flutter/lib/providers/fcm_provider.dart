import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'client_provider.dart';
import 'notification_provider.dart';
import 'router_provider.dart';
import 'private_chat_provider.dart';
import 'group_provider.dart';

part 'fcm_provider.g.dart';

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (message.data['appVersion'] != 'serverpod') return;
  debugPrint('Handling background message: ${message.messageId}');
  // Handle background notification
}

/// Provider for Firebase Cloud Messaging.
@riverpod
class FCMManager extends _$FCMManager {
  FirebaseMessaging? _messaging;

  @override
  FutureOr<String?> build() async {
    return await initialize();
  }

  /// Initialize FCM and request permissions.
  Future<String?> initialize() async {
    try {
      _messaging = FirebaseMessaging.instance;

      // Request permission (iOS)
      final settings = await _messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('User denied notification permissions');
        return null;
      }

      // Get FCM token
      final token = await _messaging!.getToken();
      debugPrint('FCM Token: $token');

      if (token != null) {
        // Register token with server
        await _registerToken(token);
      }

      // Listen for token refresh
      _messaging!.onTokenRefresh.listen((newToken) {
        debugPrint('FCM Token refreshed: $newToken');
        _registerToken(newToken);
      });

      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Foreground message: ${message.notification?.title}');
        // Show local notification or update UI
        _handleForegroundMessage(message);
      });

      // Handle notification taps (app opened from notification)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('Notification tapped: ${message.data}');
        _handleNotificationTap(message);
      });

      // Check if app was opened from a terminated state via notification
      final initialMessage = await _messaging!.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('App opened from notification: ${initialMessage.data}');
        _handleNotificationTap(initialMessage);
      }

      return token;
    } catch (e) {
      debugPrint('FCM initialization error: $e');
      return null;
    }
  }

  /// Register FCM token with server.
  Future<void> _registerToken(String token) async {
    try {
      debugPrint('FCM DEBUG: Registering token: $token');
      final client = ref.read(clientProvider);
      final platform = defaultTargetPlatform == TargetPlatform.iOS
          ? 'ios'
          : 'android';

      await client.notification.registerDeviceToken(token, platform);
      debugPrint('FCM DEBUG: Token registered with server successfully');
    } catch (e) {
      debugPrint('FCM DEBUG: Failed to register token: $e');
    }
  }

  /// Handle foreground message (show local notification).
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('FCM DEBUG: Incoming foreground message: ${message.data}');
    if (message.data['appVersion'] != 'serverpod') {
      debugPrint(
        'FCM DEBUG: Ignoring message (wrong appVersion: ${message.data['appVersion']})',
      );
      return;
    }

    final route = message.data['route'] as String?;
    if (route != null) {
      final currentRoute = ref.read(routerProvider).location;
      debugPrint(
        'FCM DEBUG: currentRoute: $currentRoute, messageRoute: $route',
      );
      if (currentRoute == route) {
        debugPrint('Silencing toast, user is actively on: $route');
        return;
      }
    }

    final title = message.notification?.title ?? 'Notification';
    final body = message.notification?.body ?? 'New update';
    final emoji = _getEmojiForType(message.data['type'] ?? '');

    debugPrint('FCM DEBUG: Showing DuoNotification: $title - $body');
    ref
        .read(notificationProvider.notifier)
        .show(
          DuoNotification(
            title: title,
            message: body,
            emoji: emoji,
            onTap: () => _handleNotificationTap(message),
          ),
        );

    // Invalidate chat list providers to update unread counts immediately
    ref.invalidate(privateChatListProvider);
    ref.invalidate(groupListProvider);
  }

  String _getEmojiForType(String type) {
    switch (type) {
      case 'message':
        return '💬';
      case 'moment_like':
        return '❤️';
      case 'moment_comment':
        return '💬';
      case 'achievement':
        return '🏆';
      case 'streak':
        return '🔥';
      case 'group_invite':
        return '🎫';
      default:
        return '🔔';
    }
  }

  /// Handle notification tap (navigate to appropriate screen).
  void _handleNotificationTap(RemoteMessage message) {
    if (message.data['appVersion'] != 'serverpod') return;

    final data = message.data;
    final route = data['route'] as String?;

    if (route != null) {
      debugPrint('Navigating to from notification: $route');
      ref.read(routerProvider).push(route);
    }
  }

  /// Unregister FCM token (call on logout).
  Future<void> unregister() async {
    try {
      final token = await _messaging?.getToken();
      if (token != null) {
        final client = ref.read(clientProvider);
        await client.notification.unregisterDeviceToken(token);
        await _messaging?.deleteToken();
        debugPrint('Token unregistered');
      }
    } catch (e) {
      debugPrint('Failed to unregister token: $e');
    }
  }

  /// Subscribe to a topic.
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging?.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Failed to subscribe to topic: $e');
    }
  }

  /// Unsubscribe from a topic.
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging?.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Failed to unsubscribe from topic: $e');
    }
  }
}
