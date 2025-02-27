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
  Messaging._();

  static final Messaging _instance = Messaging._();

  factory Messaging() => _instance;

  final FirebaseMessaging instance = FirebaseMessaging.instance;

  Future<String?> getToken() async {
    return await instance.getToken();
  }

  Stream<String> subscribeToFcmToken() {
    return instance.onTokenRefresh;
  }

  Future<void> localSetup() async {
    try {
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
      await _createNotificationChannel();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _createNotificationChannel() async {
    const androidNotificationChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      importance: Importance.max,
      playSound: true,
      enableLights: true,
      enableVibration: true,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidNotificationChannel);
  }

  Future<void> addListeners() async {
    try {
      // Check if app was launched from notification
      final initialMessage = await instance.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationData(initialMessage.data);
      }

      // Handle notification opens when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        _handleNotificationData(message.data);
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final data = message.data;
    final title = data['title'];
    final body = data['body'];

    if (title == null || body == null) return;

    // await _showLocalNotification(title, body, data);
  }

  static Future<void> handleMessage(RemoteMessage message) async {
    final data = message.data;
    final title = data['title'];
    final body = data['body'];

    if (title == null || body == null) return;

    await _showLocalNotification(title, body, data);
  }

  static Future<void> _showLocalNotification(
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    final androidNotificationDetails = AndroidNotificationDetails(
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

  void _handleNotificationData(Map<String, dynamic> data) {
    final chatId = data['chatId'];
    final partnerDisplayName = data['partnerDisplayName'];

    GoRouter.of(rootNavigatorKey.currentContext!).go('/chats');
    GoRouter.of(
      rootNavigatorKey.currentContext!,
    ).push(encodeChatRoute(chatId, partnerDisplayName));
  }

  void _handleNotificationTap(String? payload) {
    if (payload != null) {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final chatId = data['chatId'] as String;
      final partnerDisplayName = data['partnerDisplayName'] as String;

      GoRouter.of(rootNavigatorKey.currentContext!).go('/chats');
      GoRouter.of(
        rootNavigatorKey.currentContext!,
      ).push(encodeChatRoute(chatId, partnerDisplayName));
    }
  }

  static String encodeChatRoute(String chatId, String partnerDisplayName) {
    final encodedName = Uri.encodeComponent(partnerDisplayName);
    return '/chats/$chatId?partnerDisplayName=$encodedName';
  }

  // TODO: Not the right place to define this method
  static String encodeReportRoute(
    String userId,
    String chatId,
    String? partnerDisplayName,
  ) {
    final encodeUserId = Uri.encodeComponent(userId);
    final encodedName = Uri.encodeComponent(partnerDisplayName ?? '');
    return '/admin/reports/$chatId?userId=$encodeUserId&partnerDisplayName=$encodedName';
  }

  static String _encodeLaunchRoute(String chatId, String partnerDisplayName) {
    final encodedName = Uri.encodeComponent(partnerDisplayName);
    return '/launch/$chatId?partnerDisplayName=$encodedName';
  }

  static Future<String?> getInitialRoute() async {
    final NotificationAppLaunchDetails? details =
        await _flutterLocalNotificationsPlugin
            .getNotificationAppLaunchDetails();

    if (details?.didNotificationLaunchApp == true &&
        details?.notificationResponse?.payload != null) {
      try {
        final data =
            jsonDecode(details!.notificationResponse!.payload!)
                as Map<String, dynamic>;
        final chatId = data['chatId'] as String;
        final partnerDisplayName = data['partnerDisplayName'] as String;

        return _encodeLaunchRoute(chatId, partnerDisplayName);
      } catch (e) {
        debugPrint('Error parsing notification payload: $e');
      }
    }
    return null;
  }
}
