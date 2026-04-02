import 'package:test/test.dart';
import 'package:talktive_server/src/services/file_storage_service.dart';

void main() {
  group('FileStorageService._extractPathFromUrl', () {
    test('extracts path from localhost URL', () {
      const url =
          'http://localhost:8080/serverpod_cloud_storage?method=file&path=chats/uuid.jpg';
      final path = FileStorageService.extractPathFromUrl(url);
      expect(path, equals('chats/uuid.jpg'));
    });

    test('extracts path from R2 dev URL', () {
      const url = 'https://pub-123.r2.dev/chats/uuid.jpg';
      final path = FileStorageService.extractPathFromUrl(url);
      expect(path, equals('chats/uuid.jpg'));
    });

    test('extracts path from custom CDN URL', () {
      const url = 'https://media.talktive.app/moments/another-uuid.jpg';
      final path = FileStorageService.extractPathFromUrl(url);
      expect(path, equals('moments/another-uuid.jpg'));
    });

    test('extracts path from URL with bucket name (robustness check)', () {
      const url =
          'https://storage.googleapis.com/talktive-media/avatars/user123.jpg';
      final path = FileStorageService.extractPathFromUrl(url);
      // Current implementation returns 'talktive-media/avatars/user123.jpg'
      // We want it to be robust enough to find 'avatars/user123.jpg'
      expect(path, equals('avatars/user123.jpg'));
    });

    test('returns null for invalid URLs', () {
      expect(FileStorageService.extractPathFromUrl('not-a-url'), isNull);
      expect(FileStorageService.extractPathFromUrl(''), isNull);
    });

    test('handles voices path', () {
      const url = 'https://media.talktive.app/voices/audio1.m4a';
      final path = FileStorageService.extractPathFromUrl(url);
      expect(path, equals('voices/audio1.m4a'));
    });
  });
}

// Note: I need to make _extractPathFromUrl public or use a wrapper for testing.
// For now I'll assume I'll make it public or it's already accessible via a test-only header.
// Actually, I'll just change the visibility in the service file.
