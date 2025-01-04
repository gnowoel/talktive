import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import '../router.dart';

final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const _channelId = 'high_importance_channel';
const _channelName = 'High Importance Notifications';

class Messaging {
  final FirebaseMessaging instance;

  Messaging(this.instance);

  Future<String?> getToken() async {
    return await instance.getToken();
  }

  Stream<String> subscribeToFcmToken() {
    return instance.onTokenRefresh;
  }

  Future<void> localSetup() async {
    const initializationSettingsAndroid = AndroidInitializationSettings(
      'app_icon',
    );

    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        _handleNotificationTap(details.payload);
      },
    );

    // Create notification channel
    const androidNotificationChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      importance: Importance.high,
      playSound: true,
      enableLights: true,
      enableVibration: true,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidNotificationChannel);
  }

  Future<void> addListeners() async {
    // Check if app was launched from notification
    final initialMessage = await instance.getInitialMessage();
    if (initialMessage != null) {
      handleBackgroundMessage(initialMessage);
    }

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(handleBackgroundMessage);

    // Handle notification opens when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      handleBackgroundMessage(message);
    });
  }

  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _showLocalNotification(
      notification.title ?? '',
      notification.body ?? '',
      message.data,
    );
  }

  static Future<void> _showLocalNotification(
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    final androidNotificationDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableLights: true,
      enableVibration: true,
      icon: 'app_icon',
      channelShowBadge: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    try {
      await _flutterLocalNotificationsPlugin.show(
        0,
        title,
        body,
        notificationDetails,
        payload: jsonEncode(data),
      );
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }

  void _handleNotificationTap(String? payload) {
    if (payload != null) {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final chatId = data['chatId'] as String;
      final partnerDisplayName = data['partnerDisplayName'] as String;

      GoRouter.of(rootNavigatorKey.currentContext!).go('/chats');
      GoRouter.of(rootNavigatorKey.currentContext!).push(
        '/chats/$chatId',
        extra: <String, String>{
          'partnerDisplayName': partnerDisplayName,
        },
      );
    }
  }
}
