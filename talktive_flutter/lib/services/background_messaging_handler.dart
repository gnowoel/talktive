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
    // Note: Since this is a background isolate, we can't easily access Riverpod providers
    // unless we re-initialize things. For now, we just let it be handled by local notifications
    // if the payload has enough info, or we just log it.
    // The legacy Messaging.handleMessage also shows a local notification.
    
    // If it's a Serverpod message, we might want to still show a local notification 
    // using the parameters from the payload.
    await Messaging.handleMessage(message); 
  } else {
    debugPrint('Dispatching background message to Legacy handler');
    await Messaging.handleMessage(message);
  }
}
