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
    final path = _extractPathFromUrl(url);
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
  static String? _extractPathFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;

      // Development (Localhost): http://localhost:8080/serverpod_cloud_storage?method=file&path=chats/uuid.jpg
      if (url.contains('serverpod_cloud_storage')) {
        return uri.queryParameters['path'];
      }

      // Production (Cloudflare R2 Custom Domain or standard URL):
      // https://pub-xyz.r2.dev/chats/uuid.jpg OR https://media.talktive.app/chats/uuid.jpg
      // Most CDN/R2 setups have the path as the segments after the domain.

      // Filter out empty segments
      final cleanSegments = segments.where((s) => s.isNotEmpty).toList();
      if (cleanSegments.isEmpty) return null;

      // Handle cases where the first segment might be a bucket name (optional in some configs)
      // For Talktive, we expect standard paths: chats/..., voices/..., etc.
      return cleanSegments.join('/');
    } catch (_) {
      return null;
    }
  }
}
