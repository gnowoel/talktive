import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class Messaging {
  final FirebaseMessaging instance;

  Messaging(this.instance);

  Future<String?> getToken() async {
    return await instance.getToken();
  }

  Stream<String> subscribeToFcmToken() {
    return instance.onTokenRefresh;
  }

  Future<void> addListeners() async {
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

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Handling foreground message: ${message.messageId}');
  }

  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    debugPrint('Handling notification tap when app is in background');
  }
}

// Must be top-level function
@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
}
