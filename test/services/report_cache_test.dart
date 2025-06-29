import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talktive/services/report_cache.dart';
import 'package:talktive/models/chat_message.dart';
import 'package:talktive/helpers/message_status_helper.dart';

void main() {
  group('ReportCacheService', () {
    late ReportCacheService reportCache;

    setUp(() async {
      // Initialize SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
      reportCache = ReportCacheService();
      await reportCache.initialize();
    });

    tearDown(() async {
      await reportCache.clearCache();
    });

    test('should initialize successfully', () async {
      expect(reportCache, isNotNull);
      final count = await reportCache.getCachedReportsCount();
      expect(count, equals(0));
    });

    test('should add and check reported messages', () async {
      const messageId = 'test_message_123';

      // Initially should not be reported
      final initiallyReported = await reportCache.isRecentlyReported(messageId);
      expect(initiallyReported, isFalse);

      // Add to cache
      await reportCache.addReportedMessage(messageId);

      // Should now be reported
      final nowReported = await reportCache.isRecentlyReported(messageId);
      expect(nowReported, isTrue);

      // Should have timestamp
      final timestamp = await reportCache.getReportTimestamp(messageId);
      expect(timestamp, isNotNull);
      expect(
        timestamp!.isBefore(DateTime.now().add(Duration(seconds: 1))),
        isTrue,
      );
    });

    test('should persist data across service instances', () async {
      const messageId = 'persistent_test_456';

      // Add message to cache
      await reportCache.addReportedMessage(messageId);

      // Create new instance and initialize
      final newCache = ReportCacheService();
      await newCache.initialize();

      // Should still be reported
      final isReported = await newCache.isRecentlyReported(messageId);
      expect(isReported, isTrue);
    });

    test('should handle multiple messages', () async {
      const messages = ['msg1', 'msg2', 'msg3'];

      // Add all messages
      for (final msg in messages) {
        await reportCache.addReportedMessage(msg);
      }

      // Check count
      final count = await reportCache.getCachedReportsCount();
      expect(count, equals(3));

      // Check all are reported
      for (final msg in messages) {
        final isReported = await reportCache.isRecentlyReported(msg);
        expect(isReported, isTrue);
      }
    });

    test('should clear cache', () async {
      const messageId = 'clear_test_789';

      // Add message
      await reportCache.addReportedMessage(messageId);
      expect(await reportCache.isRecentlyReported(messageId), isTrue);

      // Clear cache
      await reportCache.clearCache();

      // Should no longer be reported
      expect(await reportCache.isRecentlyReported(messageId), isFalse);
      expect(await reportCache.getCachedReportsCount(), equals(0));
    });

    test('should handle invalid data gracefully', () async {
      // Simulate corrupted SharedPreferences data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('reported_messages_cache', 'invalid_json');

      // Should initialize without throwing
      final corruptedCache = ReportCacheService();
      await corruptedCache.initialize();

      // Should start with empty cache
      final count = await corruptedCache.getCachedReportsCount();
      expect(count, equals(0));
    });

    test('should handle same message reported multiple times', () async {
      const messageId = 'duplicate_test_101';

      // Add same message multiple times
      await reportCache.addReportedMessage(messageId);
      await reportCache.addReportedMessage(messageId);
      await reportCache.addReportedMessage(messageId);

      // Should still count as one
      final count = await reportCache.getCachedReportsCount();
      expect(count, equals(1));

      final isReported = await reportCache.isRecentlyReported(messageId);
      expect(isReported, isTrue);
    });

    test('should get all cached reports for debugging', () async {
      const messages = ['debug1', 'debug2'];

      // Add messages
      for (final msg in messages) {
        await reportCache.addReportedMessage(msg);
      }

      // Get all cached reports
      final allReports = await reportCache.getAllCachedReports();
      expect(allReports.length, equals(2));
      expect(allReports.containsKey('debug1'), isTrue);
      expect(allReports.containsKey('debug2'), isTrue);

      // Check timestamps are valid
      for (final timestamp in allReports.values) {
        expect(
          timestamp.isBefore(DateTime.now().add(Duration(seconds: 1))),
          isTrue,
        );
        expect(
          timestamp.isAfter(DateTime.now().subtract(Duration(minutes: 1))),
          isTrue,
        );
      }
    });

    test('should handle empty message ID gracefully', () async {
      // Should not throw for empty string
      await reportCache.addReportedMessage('');
      final isEmpty = await reportCache.isRecentlyReported('');
      expect(isEmpty, isTrue);
    });

    // Note: Testing actual expiration (24 hours) would require mocking DateTime
    // or waiting 24+ hours, which is not practical for unit tests.
    // In a real test suite, you might use a package like clock to mock time.
  });

  group('MessageStatusHelper Content Generation', () {
    test('should generate correct reported message content', () {
      // Mock text message
      final textMessage = TestMessage(id: 'text_123', type: 'text');
      final textContent = MessageStatusHelper.getReportedMessageContent(
        textMessage,
      );
      expect(textContent, equals('- Message reported -'));

      // Mock image message
      final imageMessage = TestMessage(id: 'image_456', type: 'image');
      final imageContent = MessageStatusHelper.getReportedMessageContent(
        imageMessage,
      );
      expect(imageContent, equals('- Image reported -'));
    });

    test('should handle copy content for reported messages', () {
      const originalContent = 'This is the original message content';

      // Text message should allow copying original content
      final textMessage = TestMessage(id: 'text_copy', type: 'text');
      final textCopyContent = MessageStatusHelper.getReportedCopyContent(
        textMessage,
        originalContent,
      );
      expect(textCopyContent, equals(originalContent));

      // Image message should show reported placeholder
      final imageMessage = TestMessage(id: 'image_copy', type: 'image');
      final imageCopyContent = MessageStatusHelper.getReportedCopyContent(
        imageMessage,
        originalContent,
      );
      expect(imageCopyContent, equals('- Image reported -'));
    });
  });
}

// Create a minimal ChatMessage implementation for testing
class TestMessage extends ChatMessage {
  const TestMessage({
    super.id,
    super.createdAt = 0,
    super.type = 'text',
    super.recalled = false,
    super.revivedAt,
    super.reportCount,
  });

  @override
  String get userId => 'test-user-id';

  @override
  String get userDisplayName => 'Test User';

  @override
  String get userPhotoURL => 'https://example.com/photo.jpg';

  @override
  String get content => 'Test message content';
}
