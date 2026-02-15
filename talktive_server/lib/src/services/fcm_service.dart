import 'package:serverpod/serverpod.dart';
import 'package:firebase_admin/firebase_admin.dart';
import 'dart:io';

/// Service for sending Firebase Cloud Messaging push notifications.
///
/// Setup:
/// 1. Download service account JSON from Firebase Console
/// 2. Set GOOGLE_APPLICATION_CREDENTIALS environment variable
/// 3. Or place firebase-adminsdk.json in config/
class FCMService {
  static FirebaseAdminApp? _app;
  static bool _initialized = false;

  /// Initialize Firebase Admin SDK.
  /// Call this once at server startup.
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Try to get credentials from environment variable
      final credentialsPath =
          Platform.environment['GOOGLE_APPLICATION_CREDENTIALS'];

      if (credentialsPath != null && File(credentialsPath).existsSync()) {
        _app = FirebaseAdminApp.initializeApp(
          'talktive',
          Credential.fromServiceAccountParams(
            clientId: '', // Will be read from JSON
            privateKey: '', // Will be read from JSON
            email: '', // Will be read from JSON
          ),
        );
        _initialized = true;
        print('✅ FCM Service initialized successfully');
      } else {
        // Try default location
        final defaultPath = 'config/firebase-adminsdk.json';
        if (File(defaultPath).existsSync()) {
          _app = FirebaseAdminApp.initializeApp(
            'talktive',
            Credential.fromServiceAccountParams(
              clientId: '',
              privateKey: '',
              email: '',
            ),
          );
          _initialized = true;
          print('✅ FCM Service initialized from default location');
        } else {
          print('⚠️  FCM Service not initialized: No credentials found');
          print(
            '   Set GOOGLE_APPLICATION_CREDENTIALS or place firebase-adminsdk.json in config/',
          );
        }
      }
    } catch (e) {
      print('❌ FCM Service initialization failed: $e');
      _initialized = false;
    }
  }

  /// Send a push notification to a single device token.
  static Future<bool> sendToToken(
    Session session,
    String token,
    String title,
    String body, {
    Map<String, String>? data,
    String? imageUrl,
    String? sound,
    int? badge,
  }) async {
    if (!_initialized || _app == null) {
      session.log('FCM not initialized, skipping push notification');
      return false;
    }

    try {
      final messaging = Messaging(_app!);

      final message = Message(
        token: token,
        notification: Notification(
          title: title,
          body: body,
          imageUrl: imageUrl,
        ),
        data: data,
        android: AndroidConfig(
          priority: AndroidMessagePriority.high,
          notification: AndroidNotification(
            sound: sound ?? 'default',
            channelId: 'talktive_messages',
            priority: AndroidNotificationPriority.high,
          ),
        ),
        apns: ApnsConfig(
          payload: ApnsPayload(
            aps: Aps(
              alert: ApsAlert(
                title: title,
                body: body,
              ),
              sound: sound ?? 'default',
              badge: badge,
            ),
          ),
        ),
      );

      await messaging.send(message);
      return true;
    } catch (e) {
      session.log('Failed to send FCM notification: $e');
      return false;
    }
  }

  /// Send a push notification to multiple device tokens.
  static Future<Map<String, bool>> sendToTokens(
    Session session,
    List<String> tokens,
    String title,
    String body, {
    Map<String, String>? data,
    String? imageUrl,
    String? sound,
    int? badge,
  }) async {
    final results = <String, bool>{};

    for (final token in tokens) {
      final success = await sendToToken(
        session,
        token,
        title,
        body,
        data: data,
        imageUrl: imageUrl,
        sound: sound,
        badge: badge,
      );
      results[token] = success;
    }

    return results;
  }

  /// Send a data-only message (silent notification).
  static Future<bool> sendDataMessage(
    Session session,
    String token,
    Map<String, String> data,
  ) async {
    if (!_initialized || _app == null) {
      session.log('FCM not initialized, skipping data message');
      return false;
    }

    try {
      final messaging = Messaging(_app!);

      final message = Message(
        token: token,
        data: data,
        android: AndroidConfig(
          priority: AndroidMessagePriority.high,
        ),
        apns: ApnsConfig(
          headers: {
            'apns-priority': '10',
          },
          payload: ApnsPayload(
            aps: Aps(
              contentAvailable: true,
            ),
          ),
        ),
      );

      await messaging.send(message);
      return true;
    } catch (e) {
      session.log('Failed to send FCM data message: $e');
      return false;
    }
  }

  /// Send to a topic (for broadcast messages).
  static Future<bool> sendToTopic(
    Session session,
    String topic,
    String title,
    String body, {
    Map<String, String>? data,
  }) async {
    if (!_initialized || _app == null) {
      session.log('FCM not initialized, skipping topic message');
      return false;
    }

    try {
      final messaging = Messaging(_app!);

      final message = Message(
        topic: topic,
        notification: Notification(
          title: title,
          body: body,
        ),
        data: data,
      );

      await messaging.send(message);
      return true;
    } catch (e) {
      session.log('Failed to send FCM topic message: $e');
      return false;
    }
  }

  /// Subscribe a token to a topic.
  static Future<bool> subscribeToTopic(
    Session session,
    String token,
    String topic,
  ) async {
    if (!_initialized || _app == null) {
      return false;
    }

    try {
      final messaging = Messaging(_app!);
      await messaging.subscribeToTopic([token], topic);
      return true;
    } catch (e) {
      session.log('Failed to subscribe to topic: $e');
      return false;
    }
  }

  /// Unsubscribe a token from a topic.
  static Future<bool> unsubscribeFromTopic(
    Session session,
    String token,
    String topic,
  ) async {
    if (!_initialized || _app == null) {
      return false;
    }

    try {
      final messaging = Messaging(_app!);
      await messaging.unsubscribeFromTopic([token], topic);
      return true;
    } catch (e) {
      session.log('Failed to unsubscribe from topic: $e');
      return false;
    }
  }
}
