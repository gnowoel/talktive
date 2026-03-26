import 'dart:convert';
import 'dart:io';
import 'package:serverpod/serverpod.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;

/// Service for managing physical file storage on the server.
/// Handles deletion of media files from the local storage or external providers.
class FileStorageService {
  /// Base directory for local uploads (should match StaticRoute in server.dart)
  static const String _localUploadDir = 'uploads';

  static auth.ServiceAccountCredentials? _credentials;
  static bool _initialized = false;

  /// Initialize the storage service with Firebase credentials if available.
  static Future<void> _initialize() async {
    if (_initialized) return;
    try {
      final credentialsFile = File('config/firebase_service_account_key.json');
      if (credentialsFile.existsSync()) {
        final jsonContent = jsonDecode(await credentialsFile.readAsString());
        _credentials = auth.ServiceAccountCredentials.fromJson(jsonContent);
        _initialized = true;
      }
    } catch (e) {
      stdout.writeln('TALKTIVE: FileStorageService initialization warning: $e');
    }
  }

  /// Deletes a piece of media from the server's storage based on its URL.
  /// This handles both local paths and external Firebase Storage URLs.
  static Future<void> deleteMedia(Session session, String? url) async {
    if (url == null || url.isEmpty) return;

    // 1. Check for local storage (mapped to /uploads/)
    if (url.contains('/uploads/')) {
      await _deleteLocalFile(session, url);
    } 
    // 2. Check for Firebase Storage (GCS)
    else if (url.contains('firebasestorage.googleapis.com')) {
      await _deleteFirebaseFile(session, url);
    }
  }

  /// Safely deletes a file from the local 'uploads' directory.
  static Future<void> _deleteLocalFile(Session session, String url) async {
    try {
      final uri = Uri.parse(url);
      final filename = uri.pathSegments.last;

      if (filename.isEmpty) return;

      final file = File('$_localUploadDir/$filename');
      
      if (await file.exists()) {
        await file.delete();
        session.log('TALKTIVE: Physically deleted local file: $filename', level: LogLevel.info);
      }
    } catch (e) {
      session.log('TALKTIVE: Error deleting local file ($url): $e', level: LogLevel.error);
    }
  }

  /// Deletes a file from Firebase Cloud Storage using the GCS JSON API.
  static Future<void> _deleteFirebaseFile(Session session, String url) async {
    try {
      await _initialize();
      if (_credentials == null) {
        session.log('TALKTIVE: Firebase credentials not found, cannot delete: $url', level: LogLevel.warning);
        return;
      }

      // Parse Firebase URL: https://firebasestorage.googleapis.com/v0/b/[BUCKET]/o/[OBJECT]?alt=media
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;

      // Segments usually look like: ['v0', 'b', 'BUCKET', 'o', 'OBJECT']
      if (segments.length < 5 || segments[1] != 'b' || segments[3] != 'o') {
        session.log('TALKTIVE: Invalid Firebase Storage URL format: $url', level: LogLevel.warning);
        return;
      }

      final bucket = segments[2];
      // The object path is the 4th segment and beyond, often URL-encoded (e.g., uploads%2Fimage.png)
      // Uri.parse already decodes path segments, but Firebase URLs represent the path as a single segment after /o/
      final objectPath = segments[4];

      final scopes = ['https://www.googleapis.com/auth/devstorage.full_control'];
      final client = await auth.clientViaServiceAccount(_credentials!, scopes);

      try {
        // GCS JSON API: DELETE https://storage.googleapis.com/storage/v1/b/[BUCKET]/o/[OBJECT]
        // Note: objectPath must be percent-encoded for the URL
        final encodedObjectPath = Uri.encodeComponent(objectPath);
        final deleteUrl = 'https://storage.googleapis.com/storage/v1/b/$bucket/o/$encodedObjectPath';

        final response = await client.delete(Uri.parse(deleteUrl));

        if (response.statusCode == 204 || response.statusCode == 200) {
          session.log('TALKTIVE: Successfully deleted Firebase file: $objectPath from $bucket', level: LogLevel.info);
        } else if (response.statusCode == 404) {
          session.log('TALKTIVE: Firebase file already gone or not found (404): $objectPath', level: LogLevel.debug);
        } else {
          session.log('TALKTIVE: Failed to delete Firebase file: ${response.statusCode} - ${response.body}', level: LogLevel.error);
        }
      } finally {
        client.close();
      }
    } catch (e) {
      session.log('TALKTIVE: Error deleting Firebase file ($url): $e', level: LogLevel.error);
    }
  }
}
