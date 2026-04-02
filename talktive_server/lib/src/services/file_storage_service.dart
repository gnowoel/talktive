import 'package:serverpod/serverpod.dart';

/// Service for managing physical file storage on the server.
/// Handles deletion of media files from configured storage providers.
class FileStorageService {
  /// Deletes a piece of media from the server's storage based on its URL.
  /// This uses Serverpod's storage abstraction to handle both local disk (dev)
  /// and Cloudflare R2 (prod).
  static Future<void> deleteMedia(Session session, String? url) async {
    if (url == null || url.isEmpty) return;

    // Extract path from URL
    final path = extractPathFromUrl(url);
    if (path == null) {
      session.log(
        'TALKTIVE: Could not extract path from media URL: $url',
        level: LogLevel.warning,
      );
      return;
    }

    try {
      final exists = await session.storage.fileExists(
        storageId: 'public',
        path: path,
      );

      if (exists) {
        await session.storage.deleteFile(
          storageId: 'public',
          path: path,
        );
        session.log(
          'TALKTIVE: Successfully deleted file: $path',
          level: LogLevel.info,
        );
      }
    } catch (e) {
      session.log(
        'TALKTIVE: Error deleting file ($path): $e',
        level: LogLevel.error,
      );
    }
  }

  /// Extracts the relative storage path from a full public URL.
  /// Handles both localhost (dev) and R2 (prod) formats.
  static String? extractPathFromUrl(String url) {
    try {
      final uri = Uri.parse(url);

      // Basic validation: must have a scheme and host (or be a relative path which we don't support here)
      if (!uri.hasScheme || uri.host.isEmpty) {
        return null;
      }

      final segments = uri.pathSegments;

      // Development (Localhost): http://localhost:8080/serverpod_cloud_storage?method=file&path=chats/uuid.jpg
      if (url.contains('serverpod_cloud_storage')) {
        return uri.queryParameters['path'];
      }

      // Filter out empty segments
      final cleanSegments = segments.where((s) => s.isNotEmpty).toList();
      if (cleanSegments.isEmpty) return null;

      // Robustness check for Cloudflare R2 / S3 standard URLs:
      // https://<bucket>.<account_id>.r2.cloudflarestorage.com/chats/uuid.jpg (Path is chats/uuid.jpg)
      // https://<account_id>.r2.cloudflarestorage.com/<bucket>/chats/uuid.jpg (Path is chats/uuid.jpg)

      if (url.contains('cloudflarestorage.com') ||
          url.contains('talktive-media')) {
        // If the first segment is the known bucket name, skip it
        if (cleanSegments.first == 'talktive-media') {
          return cleanSegments.skip(1).join('/');
        }
      }

      // Default: the entire path after the domain is the storage path
      return cleanSegments.join('/');
    } catch (_) {
      return null;
    }
  }
}
