import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'client_provider.dart';
import 'notification_provider.dart';
import 'router_provider.dart';
import 'private_chat_provider.dart';
import 'lounge_provider.dart';
import 'gamification_provider.dart';
import 'auth_provider.dart';

part 'fcm_provider.g.dart';

/// Provider for Firebase Cloud Messaging for the Serverpod version.
/// Background messages are handled centrally in background_messaging_handler.dart.
@riverpod
class FCMManager extends _$FCMManager {
  FirebaseMessaging? _messaging;

  @override
  FutureOr<String?> build() async {
    final authState = ref.watch(authProvider);
    
    // We only trigger FCM initialization if the user selects the serverpod version
    // and is authenticated.
    return authState.when(
      data: (auth) async {
        if (auth is Authenticated) {
          debugPrint('FCMManager: User authenticated (${auth.userName}), initializing FCM...');
          return await initialize();
        } else if (auth is Unauthenticated) {
          debugPrint('FCMManager: User unauthenticated, cleaning up FCM...');
          await unregister();
          return null;
        }
        return null;
      },
      loading: () => null,
      error: (_, __) => null,
    );
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

      // FCMManager ignores background message registration here as it's handled in main.dart
      // via background_messaging_handler.dart to avoid isolate conflicts.

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
        .read(inAppNotificationProvider.notifier)
        .show(
          DuoNotification(
            title: title,
            message: body,
            emoji: emoji,
            onTap: () => _handleNotificationTap(message),
          ),
        );

    // Explicitly refresh providers to ensure unread counts update immediately
    debugPrint('FCM DEBUG: Refreshing chat and lounge lists...');
    ref.read(privateChatListProvider.notifier).refresh();
    ref.read(loungeListProvider.notifier).refresh();

    // Refresh gamification and activity for relevant events
    final type = message.data['type'] as String?;
    if (type == 'level_up' || type == 'achievement' || type == 'streak') {
      debugPrint('FCM DEBUG: Refreshing gamification and activity status...');
      ref.read(gamificationProvider.notifier).refresh();
      ref.read(activityHistoryProvider.notifier).refresh();
    }
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
      case 'mention':
        return '🏷️';
      case 'lounge_invite':
        return '🎫';
      case 'level_up':
        return '🆙';
      default:
        return '🔔';
    }
  }

  /// Handle notification tap (navigate to appropriate screen).
  void _handleNotificationTap(RemoteMessage message) {
    if (message.data['appVersion'] != 'serverpod') return;

    final data = message.data;

    // Mark as read if notification history ID is present
    final notificationIdStr = data['notificationId'] as String?;
    if (notificationIdStr != null) {
      final id = int.tryParse(notificationIdStr);
      if (id != null) {
        debugPrint('FCM DEBUG: Marking notification $id as read from tap');
        ref.read(activityHistoryProvider.notifier).markAsRead([id]);
      }
    }

    // Refresh gamification and activity if it was a milestone notification
    final type = data['type'] as String?;
    if (type == 'level_up' || type == 'achievement' || type == 'streak') {
      debugPrint('FCM DEBUG: Tapped milestone, refreshing stats...');
      ref.read(gamificationProvider.notifier).refresh();
      ref.read(activityHistoryProvider.notifier).refresh();
    }

    final route = data['route'] as String?;
    if (route != null) {
      final currentRoute = ref.read(routerProvider).location;
      if (currentRoute == route) {
        debugPrint('Already on $route, skipping push');
        return;
      }
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
