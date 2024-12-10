import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class Messaging {
  Messaging._();
  static final Messaging _instance = Messaging._();
  factory Messaging() => _instance;

  final instance = FirebaseMessaging.instance;

  Future<void> init() async {
    await _requestPermission();

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  Future<void> _requestPermission() async {
    if (!kIsWeb) {
      final settings = await instance.requestPermission();

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('Notfication permission granted');
      }
    }
  }

  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('Handling background message: ${message.messageId}');
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Handling foreground message: ${message.messageId}');
  }

  Future<String?> getToken() async {
    return await instance.getToken();
  }
}
