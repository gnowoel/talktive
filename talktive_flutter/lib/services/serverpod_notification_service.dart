import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service dedicated to handling notifications for the Serverpod version.
/// This ensures total separation from the legacy Firebase version.
class ServerpodNotificationService {
  ServerpodNotificationService._();
  static final ServerpodNotificationService _instance =
      ServerpodNotificationService._();
  factory ServerpodNotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'high_importance_channel';
  static const _channelName = 'High Importance Notifications';

  /// Initialization for background/foreground system notifications.
  Future<void> initialize() async {
    try {
      const initializationSettingsAndroid = AndroidInitializationSettings(
        'app_icon',
      );
      const initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );

      await _notificationsPlugin.initialize(settings: initializationSettings);

      // Create high importance channel
      const androidNotificationChannel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        importance: Importance.max,
        playSound: true,
        enableLights: true,
        enableVibration: true,
      );

      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(androidNotificationChannel);

      debugPrint('ServerpodNotificationService: Initialized successfully');
    } catch (e) {
      debugPrint('ServerpodNotificationService: Initialization error: $e');
    }
  }

  /// Handles showing a notification from a RemoteMessage in the system tray.
  /// Typically used by the background messaging handler.
  Future<void> showNotification(RemoteMessage message) async {
    final data = message.data;
    if (data['appVersion'] != 'serverpod') {
      debugPrint(
        'ServerpodNotificationService: Ignoring non-serverpod message',
      );
      return;
    }

    final title =
        data['title'] ?? (message.notification?.title ?? 'Notification');
    final body = data['body'] ?? (message.notification?.body ?? 'New message');

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableLights: true,
      enableVibration: true,
      icon: 'app_icon',
      channelShowBadge: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    try {
      await _notificationsPlugin.show(
        id: message.messageId.hashCode,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: jsonEncode(data),
      );
      debugPrint('ServerpodNotificationService: Notification displayed');
    } catch (e) {
      debugPrint(
        'ServerpodNotificationService: Error showing notification: $e',
      );
    }
  }

  /// Utility to clear notifications.
  Future<void> clearAll() async {
    await _notificationsPlugin.cancelAll();
  }
}
