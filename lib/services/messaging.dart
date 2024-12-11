import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
    );
  }

  Future<void> addListeners() async {
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
  }
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
      notification.title, // Notification title
      notification.body, // Notification body
      notificationDetails,
    );
  }
}
