import 'package:serverpod/serverpod.dart';
// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;

/// Service for sending Firebase Cloud Messaging push notifications.
///
/// Uses Firebase HTTP v1 API with service account credentials.
/// Setup:
/// 1. Download service account JSON from Firebase Console
/// 2. Place it at config/firebase_service_account_key.json
class FCMService {
  static auth.ServiceAccountCredentials? _credentials;
  static String? _projectId;
  static bool _initialized = false;

  /// Initialize FCM Service with service account credentials.
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      final credentialsFile = File('config/firebase_service_account_key.json');

      if (!credentialsFile.existsSync()) {
        print(
          '⚠️  FCM Service not initialized: firebase_service_account_key.json not found',
        );
        print(
          '   Place service account JSON at config/firebase_service_account_key.json',
        );
        return;
      }

      final jsonContent = jsonDecode(await credentialsFile.readAsString());

      _credentials = auth.ServiceAccountCredentials.fromJson(jsonContent);
      _projectId = jsonContent['project_id'] as String?;

      if (_projectId == null) {
        print(
          '❌ FCM Service initialization failed: project_id not found in credentials',
        );
        return;
      }

      _initialized = true;
      print('✅ FCM Service initialized successfully for project: $_projectId');
    } catch (e, stack) {
      print('❌ FCM Service initialization failed: $e');
      print(stack);
      _initialized = false;
    }
  }

  /// Get an OAuth2 access token for FCM API.
  static Future<String?> _getAccessToken() async {
    if (_credentials == null) return null;

    try {
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      final client = await auth.clientViaServiceAccount(_credentials!, scopes);

      final accessToken = client.credentials.accessToken.data;
      client.close();

      return accessToken;
    } catch (e) {
      print('Failed to get FCM access token: $e');
      return null;
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
    if (!_initialized || _projectId == null) {
      session.log('FCM not initialized, skipping push notification');
      return false;
    }

    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        session.log('Failed to get FCM access token');
        return false;
      }

      final url =
          'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send';

      final message = {
        'message': {
          'token': token,
          'notification': {
            'title': title,
            'body': body,
            'image': ?imageUrl,
          },
          'data': ?data,
          'android': {
            'priority': 'high',
            'notification': {
              'sound': sound ?? 'default',
              'channel_id': 'talktive_messages',
            },
          },
          'apns': {
            'payload': {
              'aps': {
                'alert': {
                  'title': title,
                  'body': body,
                },
                'sound': sound ?? 'default',
                'badge': ?badge,
              },
            },
          },
        },
      };

      session.log('FCM DEBUG: Sending notification to $token');
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(message),
      );

      if (response.statusCode == 200) {
        session.log('FCM DEBUG: Successfully sent notification to $token');
        return true;
      } else {
        session.log(
          'FCM DEBUG: FCM send failed: ${response.statusCode} - ${response.body}',
          level: LogLevel.warning,
        );
        return false;
      }
    } catch (e) {
      session.log(
        'FCM DEBUG: Failed to send FCM notification: $e',
        level: LogLevel.error,
      );
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
    if (!_initialized || _projectId == null) {
      session.log('FCM not initialized, skipping data message');
      return false;
    }

    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        session.log('Failed to get FCM access token');
        return false;
      }

      final url =
          'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send';

      final message = {
        'message': {
          'token': token,
          'data': data,
          'android': {
            'priority': 'high',
          },
          'apns': {
            'headers': {
              'apns-priority': '10',
            },
            'payload': {
              'aps': {
                'content-available': 1,
              },
            },
          },
        },
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(message),
      );

      return response.statusCode == 200;
    } catch (e) {
      session.log('Failed to send FCM data message: $e', level: LogLevel.error);
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
    if (!_initialized || _projectId == null) {
      session.log('FCM not initialized, skipping topic message');
      return false;
    }

    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        session.log('Failed to get FCM access token');
        return false;
      }

      final url =
          'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send';

      final message = {
        'message': {
          'topic': topic,
          'notification': {
            'title': title,
            'body': body,
          },
          'data': ?data,
        },
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(message),
      );

      return response.statusCode == 200;
    } catch (e) {
      session.log(
        'Failed to send FCM topic message: $e',
        level: LogLevel.error,
      );
      return false;
    }
  }

  /// Subscribe a token to a topic.
  /// Note: This uses the IID API which may require additional setup.
  static Future<bool> subscribeToTopic(
    Session session,
    String token,
    String topic,
  ) async {
    if (!_initialized) {
      return false;
    }

    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        return false;
      }

      final url = 'https://iid.googleapis.com/iid/v1/$token/rel/topics/$topic';

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      session.log('Failed to subscribe to topic: $e', level: LogLevel.error);
      return false;
    }
  }

  /// Unsubscribe a token from a topic.
  static Future<bool> unsubscribeFromTopic(
    Session session,
    String token,
    String topic,
  ) async {
    if (!_initialized) {
      return false;
    }

    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        return false;
      }

      final url = 'https://iid.googleapis.com/iid/v1/$token/rel/topics/$topic';

      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      session.log(
        'Failed to unsubscribe from topic: $e',
        level: LogLevel.error,
      );
      return false;
    }
  }
}
