import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'messaging.dart';

/// Top-level background message handler that dispatches to version-specific handlers.
/// This must be a top-level function.
@pragma('vm:entry-point')
Future<void> backgroundMessagingHandler(RemoteMessage message) async {
  debugPrint('Background message received: ${message.messageId}');
  
  final data = message.data;
  final appVersion = data['appVersion'] as String?;
  
  if (appVersion == 'serverpod') {
    debugPrint('Dispatching background message to Serverpod handler');
    // For Serverpod background messages, we rely on the same Messaging logic 
    // to show a native local notification since we are in a background isolate.
    await Messaging.handleMessage(message, force: true); 
  } else {
    debugPrint('Dispatching background message to Legacy handler');
    await Messaging.handleMessage(message);
  }
}
