import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import '../legacy/helpers/platform.dart';
import '../legacy/helpers/routes.dart';
import '../legacy/router.dart';
import '../serverpod_client.dart';
import '../legacy/services/ad_service/go_router_room_helper.dart';

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
    final token = await instance.getToken();
    if (token != null) {
      await _registerTokenWithBackend(token);
    }
    return token;
  }

  Stream<String> subscribeToFcmToken() {
    if (!isAndroid) {
      // TODO: Support other platforms
      return const Stream.empty();
    }

    // Register new tokens with backend
    instance.onTokenRefresh.listen((token) {
      _registerTokenWithBackend(token);
    });

    return instance.onTokenRefresh;
  }

  Future<void> _registerTokenWithBackend(String token) async {
    try {
      String platform = 'android';
      if (Platform.isIOS) {
        platform = 'ios';
      }

      await client.notification.registerDeviceToken(token, platform);
      debugPrint('Device token registered with backend');
    } catch (e) {
      debugPrint('Error registering device token: $e');
    }
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

  Future<void> clearAllNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint('Error clearing notifications: $e');
    }
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
    if (data['appVersion'] == 'serverpod') {
      debugPrint('Messaging (Legacy): Ignoring serverpod message');
      return;
    }

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
    if (data['appVersion'] == 'serverpod') {
      debugPrint('Messaging (Legacy): Ignoring serverpod notification tap');
      return;
    }

    final context = rootNavigatorKey.currentContext;
    if (context == null) return;

    final type = data['type'] as String?;

    switch (type) {
      case 'message':
        // Navigate to plaza (public chat)
        GoRouter.of(context).go('/plaza');
        break;

      case 'moment_like':
      case 'moment_comment':
        // Navigate to moments screen
        GoRouter.of(context).go('/moments');
        break;

      case 'achievement':
        // Navigate to achievements screen
        GoRouter.of(context).go('/achievements');
        break;

      case 'streak':
        // Navigate to profile screen
        GoRouter.of(context).go('/profile');
        break;

      case 'lounge_invite':
        // Navigate to lounges screen
        GoRouter.of(context).go('/lounges');
        break;

      case 'chat':
        // Legacy chat handling
        final chatId = data['chatId'] as String?;
        final chatCreatedAt = data['chatCreatedAt'] as String?;
        if (chatId != null && chatCreatedAt != null) {
          GoRouter.of(context).go('/chats');
          GoRouterRoomHelper.pushWithoutAd(
            context,
            encodeChatRoute(chatId, chatCreatedAt),
          );
        }
        break;

      default:
        // Legacy topic handling
        final topicId = data['topicId'] as String?;
        final topicCreatorId = data['topicCreatorId'] as String?;
        if (topicId != null && topicCreatorId != null) {
          GoRouterRoomHelper.goWithoutAd(
            context,
            encodeTopicRoute(topicId, topicCreatorId),
          );
        }
    }
  }

  void _handleNotificationTap(String? payload) {
    if (payload != null) {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      _handleNotificationData(data);
    }
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

        if (data['type'] == 'chat') {
          final chatId = data['chatId'] as String;
          final chatCreatedAt = data['chatCreatedAt'] as String;

          return encodeChatLaunchRoute(chatId, chatCreatedAt);
        } else {
          final topicId = data['topicId'] as String;
          final topicCreatorId = data['topicCreatorId'] as String;

          return encodeTopicLaunchRoute(topicId, topicCreatorId);
        }
      } catch (e) {
        debugPrint('Error parsing notification payload: $e');
      }
    }
    return null;
  }
}
