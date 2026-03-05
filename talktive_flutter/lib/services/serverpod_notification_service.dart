import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import '../serverpod_client.dart';

/// Notification service for the Serverpod version of the app.
/// Handles FCM token registration and notification routing.
class ServerpodNotificationService {
  ServerpodNotificationService._();
  static final ServerpodNotificationService _instance =
      ServerpodNotificationService._();
  factory ServerpodNotificationService() => _instance;

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'high_importance_channel';
  static const _channelName = 'High Importance Notifications';

  /// Initialize the notification service
  Future<void> initialize() async {
    try {
      // Request permission for iOS
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
            alert: true,
            announcement: false,
            badge: true,
            carPlay: false,
            criticalAlert: false,
            provisional: false,
            sound: true,
          );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted notification permission');

        // Get the token and register with backend
        String? token = await _firebaseMessaging.getToken();
        if (token != null) {
          debugPrint('FCM Token: $token');
          await _registerTokenWithBackend(token);
        }

        // Listen to token refresh
        _firebaseMessaging.onTokenRefresh.listen((newToken) {
          debugPrint('FCM Token refreshed: $newToken');
          _registerTokenWithBackend(newToken);
        });

        // Initialize local notifications
        await _initializeLocalNotifications();

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // Handle notification taps when app is in background
        FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

        // Check if app was opened from a terminated state
        RemoteMessage? initialMessage = await _firebaseMessaging
            .getInitialMessage();
        if (initialMessage != null) {
          _handleNotificationTap(initialMessage);
        }
      } else {
        debugPrint('User declined or has not accepted notification permission');
      }
    } catch (e) {
      debugPrint('Error initializing notification service: $e');
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const initializationSettingsAndroid = AndroidInitializationSettings(
      'app_icon',
    );
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: DarwinInitializationSettings(),
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) {
          final data = jsonDecode(details.payload!) as Map<String, dynamic>;
          _handleNotificationData(data);
        }
      },
    );

    // Create notification channel for Android
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

  /// Register FCM token with backend
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

  /// Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final data = message.data;
    final notification = message.notification;

    if (notification != null) {
      await _showLocalNotification(
        notification.title ?? 'Talktive',
        notification.body ?? '',
        data,
      );
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification(
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    const androidNotificationDetails = AndroidNotificationDetails(
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

    const notificationDetails = NotificationDetails(
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

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    _handleNotificationData(message.data);
  }

  /// Handle notification data and navigate to appropriate screen
  void _handleNotificationData(Map<String, dynamic> data) {
    // Get the router from the ServerpodApp's context
    // Note: This requires the app to be initialized
    final type = data['type'] as String?;

    debugPrint('Handling notification: type=$type, data=$data');

    // Store the notification data for the app to handle
    // The app will check this on startup and navigate accordingly
    _pendingNotificationData = data;
  }

  Map<String, dynamic>? _pendingNotificationData;

  /// Get and clear pending notification data
  Map<String, dynamic>? getPendingNotificationData() {
    final data = _pendingNotificationData;
    _pendingNotificationData = null;
    return data;
  }

  /// Navigate to screen based on notification type
  /// This should be called from the app after the router is initialized
  void navigateFromNotification(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final type = data['type'] as String?;

    switch (type) {
      case 'message':
        // Navigate to plaza (public chat)
        GoRouter.of(context).go('/plaza');
        break;

      case 'private_chat_message':
        final channelId = data['channelId'];
        if (channelId != null) {
          GoRouter.of(context).go('/chats/thread/$channelId');
        } else {
          GoRouter.of(context).go('/chats');
        }
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

      case 'group_invite':
        // Navigate to groups screen
        GoRouter.of(context).go('/groups');
        break;

      default:
        debugPrint('Unknown notification type: $type');
    }
  }
}
