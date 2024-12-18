import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

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
      // Handle notification taps when app is in foreground
      onDidReceiveNotificationResponse: (details) {
        _handleNotificationTap(details.payload);
      },
    );
  }

  Future<void> addListeners() async {
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    // Check if app was launched from notification
    final initialMessage = await instance.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationData(initialMessage.data);
    }

    // Handle notification opens when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleNotificationData(message.data);
    });
  }

  void _handleNotificationData(Map<String, dynamic> data) {
    final chatId = data['chatId'];
    if (chatId != null) {
      GoRouter.of(_navigationKey.currentContext!).push('/chat/$chatId');
    }
  }

  void _handleNotificationTap(String? payload) {
    if (payload != null) {
      final chatId = payload;
      GoRouter.of(_navigationKey.currentContext!).push('/chat/$chatId');
    }
  }

  // Access navigation context
  static final _navigationKey = GlobalKey<NavigatorState>();
  static GlobalKey<NavigatorState> get navigationKey => _navigationKey;
}

// Must be top-level function
@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  _showNotification(message);
}

Future<void> _showNotification(RemoteMessage message) async {
  const androidNotificationDetails = AndroidNotificationDetails(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
    enableLights: true,
    enableVibration: true,
  );

  var notificationDetails = const NotificationDetails(
    android: androidNotificationDetails,
  );

  var notification = message.notification;
  if (notification != null) {
    await _flutterLocalNotificationsPlugin.show(
      0, // ID of notification
      notification.title,
      notification.body,
      notificationDetails,
      payload: message.data['chatId'], // Pass chatId as payload
    );
  }
}
