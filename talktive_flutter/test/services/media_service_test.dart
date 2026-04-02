import 'package:flutter_test/flutter_test.dart';
import 'package:talktive/services/media_service.dart';

void main() {
  group('MediaService.resolvePublicUrlFromDescription', () {
    test('prefers explicit publicUrl when present', () {
      final result = MediaService.resolvePublicUrlFromDescription({
        'url':
            'https://account.r2.cloudflarestorage.com/talktive-media/chats/file.jpg?X-Amz-Signature=abc',
        'path': 'chats/file.jpg',
        'publicUrl': 'https://cdn.example.com/chats/file.jpg',
      });

      expect(result, 'https://cdn.example.com/chats/file.jpg');
    });

    test('derives database storage public URL from upload URL', () {
      final result = MediaService.resolvePublicUrlFromDescription({
        'url':
            'http://localhost:8080/serverpod_cloud_storage?method=upload&storage=public&path=chats%2Ffile.jpg&key=abc',
        'path': 'chats/file.jpg',
      });

      expect(
        result,
        'http://localhost:8080/serverpod_cloud_storage?method=file&path=chats%2Ffile.jpg',
      );
    });

    test('derives R2 public URL from signed object PUT URL', () {
      final result = MediaService.resolvePublicUrlFromDescription({
        'url':
            'https://talktive-media.account.r2.cloudflarestorage.com/chats/file.jpg?X-Amz-Signature=abc',
        'path': 'chats/file.jpg',
      });

      expect(
        result,
        'https://talktive-media.account.r2.cloudflarestorage.com/chats/file.jpg',
      );
    });

    test('derives R2 public URL from bucket-root multipart style URL', () {
      final result = MediaService.resolvePublicUrlFromDescription({
        'url':
            'https://talktive-media.account.r2.cloudflarestorage.com/?X-Amz-Signature=abc',
        'path': 'chats/file.jpg',
      });

      expect(
        result,
        'https://talktive-media.account.r2.cloudflarestorage.com/chats/file.jpg',
      );
    });

    test('derives R2 public URL from path-style endpoint URL', () {
      final result = MediaService.resolvePublicUrlFromDescription({
        'url':
            'https://account.r2.cloudflarestorage.com/talktive-media?X-Amz-Signature=abc',
        'path': 'chats/file.jpg',
      });

      expect(
        result,
        'https://account.r2.cloudflarestorage.com/talktive-media/chats/file.jpg',
      );
    });
  });
}
