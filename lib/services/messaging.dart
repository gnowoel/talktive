import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class Messaging {
  Messaging._();
  static final Messaging _instance = Messaging._();
  factory Messaging() => _instance;

  final instance = FirebaseMessaging.instance;

  Future<void> init() async {
    await _requestPermission();

    // Get FCM token
    final token = await instance.getToken();
    debugPrint('FCM Token: $token');

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification open events when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    instance.getInitialMessage().then((message) {
      if (message != null) {
        debugPrint('Initial message: ${message.messageId}');
      }
    });
  }

  Future<void> _requestPermission() async {
    if (!kIsWeb) {
      final settings = await instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('Notfication permission granted');
      }
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Handling foreground message: ${message.messageId}');
  }

  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    debugPrint('Handling notification tap when app is in background');
  }

  Future<String?> getToken() async {
    return await instance.getToken();
  }
}

// Must be top-level function
@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
}
