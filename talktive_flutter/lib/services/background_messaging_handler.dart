import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../legacy/services/legacy_messaging.dart';
import 'serverpod_notification_service.dart';

/// Top-level background message handler that dispatches to version-specific handlers.
/// This must be a top-level function.
@pragma('vm:entry-point')
Future<void> backgroundMessagingHandler(RemoteMessage message) async {
  debugPrint('Background message received: ${message.messageId}');

  final data = message.data;
  final msgVersion = data['appVersion'] as String?;

  // Get currently active app version from SharedPreferences
  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance();
  } catch (e) {
    debugPrint('BackgroundMessaging: Failed to get SharedPreferences: $e');
  }

  final activeVersion = prefs?.getString('active_app_version');

  if (activeVersion == null) {
    debugPrint(
      'BackgroundMessaging: No active version selected, ignoring notification until app is opened.',
    );
    return;
  }

  if (msgVersion == 'serverpod') {
    if (activeVersion == 'serverpod') {
      debugPrint(
        'BackgroundMessaging: Dispatching serverpod message to Serverpod handler',
      );
      final svc = ServerpodNotificationService();
      await svc.initialize(); // Ensure channel is created in background isolate
      await svc.showNotification(message);
    } else {
      debugPrint(
        'BackgroundMessaging: Ignoring serverpod message because active version is $activeVersion',
      );
    }
  } else {
    // Treat messages WITHOUT 'serverpod' appVersion as 'firebase' (legacy)
    if (activeVersion == 'firebase') {
      debugPrint(
        'BackgroundMessaging: Dispatching legacy message to Messaging handler',
      );
      await LegacyMessaging.handleMessage(message);
    } else {
      debugPrint(
        'BackgroundMessaging: Ignoring legacy message because active version is $activeVersion',
      );
    }
  }
}
