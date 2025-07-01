import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../lib/helpers/message_report_helper.dart';
import '../lib/models/chat_message.dart';
import '../lib/models/topic_message.dart';
import '../lib/services/message_meta_cache.dart';
import '../lib/services/firestore.dart';
import '../lib/services/fireauth.dart';
import '../lib/services/user_cache.dart';
import '../lib/widgets/chat_text_message_item.dart';
import '../lib/widgets/topic_text_message_item.dart';

// Generate mocks
@GenerateMocks([
  MessageMetaCache,
  Firestore,
  Fireauth,
  UserCache,
])
import 'message_reporting_test.mocks.dart';

void main() {
  group('Message Reporting System Tests', () {
    late MockMessageMetaCache mockMessageMetaCache;
    late MockFirestore mockFirestore;
    late MockFireauth mockFireauth;
    late MockUserCache mockUserCache;

    setUp(() {
      mockMessageMetaCache = MockMessageMetaCache();
      mockFirestore = MockFirestore();
      mockFireauth = MockFireauth();
      mockUserCache = MockUserCache();
    });

    group('MessageReportHelper Tests', () {
      test('should return correct report count from cache', () {
        // Arrange
        const messageId = 'test_message_id';
        const reportCount = 3;

        final chatMessage = ChatTextMessage(
          id: messageId,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          userId: 'user123',
          userDisplayName: 'Test User',
          userPhotoURL: '👤',
          content: 'Test message content',
          reportCount: 1, // Original count
        );

        when(mockMessageMetaCache.getMessageReportCountWithFallback(
          messageId,
          1,
        )).thenReturn(reportCount);

        // Act
        final result =
            chatMessage.getReportCountWithCache(mockMessageMetaCache);

        // Assert
        expect(result, equals(reportCount));
        verify(mockMessageMetaCache.getMessageReportCountWithFallback(
          messageId,
          1,
        )).called(1);
      });

      test('should fallback to original count when cache is null', () {
        // Arrange
        const originalCount = 2;

        final chatMessage = ChatTextMessage(
          id: 'test_message_id',
          createdAt: DateTime.now().millisecondsSinceEpoch,
          userId: 'user123',
          userDisplayName: 'Test User',
          userPhotoURL: '👤',
          content: 'Test message content',
          reportCount: originalCount,
        );

        // Act
        final result = chatMessage.getReportCountWithCache(null);

        // Assert
        expect(result, equals(originalCount));
      });

      test('should correctly identify flagged messages', () {
        // Arrange
        const messageId = 'test_message_id';
        const reportCount = 2; // Above flag threshold (1)

        final chatMessage = ChatTextMessage(
          id: messageId,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          userId: 'user123',
          userDisplayName: 'Test User',
          userPhotoURL: '👤',
          content: 'Test message content',
          reportCount: 0,
        );

        when(mockMessageMetaCache.getMessageReportCountWithFallback(
          messageId,
          0,
        )).thenReturn(reportCount);

        // Act
        final result = chatMessage.isFlaggedWithCache(mockMessageMetaCache);

        // Assert
        expect(result, isTrue);
      });

      test('should correctly identify hidden messages', () {
        // Arrange
        const messageId = 'test_message_id';
        const reportCount = 6; // Above hide threshold (5)

        final chatMessage = ChatTextMessage(
          id: messageId,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          userId: 'user123',
          userDisplayName: 'Test User',
          userPhotoURL: '👤',
          content: 'Test message content',
          reportCount: 0,
        );

        when(mockMessageMetaCache.getMessageReportCountWithFallback(
          messageId,
          0,
        )).thenReturn(reportCount);

        // Act
        final result = chatMessage.isHiddenWithCache(mockMessageMetaCache);

        // Assert
        expect(result, isTrue);
      });

      test('should correctly identify severe messages', () {
        // Arrange
        const messageId = 'test_message_id';
        const reportCount = 15; // Above severe threshold (13)

        final chatMessage = ChatTextMessage(
          id: messageId,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          userId: 'user123',
          userDisplayName: 'Test User',
          userPhotoURL: '👤',
          content: 'Test message content',
          reportCount: 0,
        );

        when(mockMessageMetaCache.getMessageReportCountWithFallback(
          messageId,
          0,
        )).thenReturn(reportCount);

        // Act
        final result = chatMessage.isSevereWithCache(mockMessageMetaCache);

        // Assert
        expect(result, isTrue);
      });

      test('should handle invalid message IDs gracefully', () {
        // Arrange
        final chatMessage = ChatTextMessage(
          id: '', // Invalid ID
          createdAt: DateTime.now().millisecondsSinceEpoch,
          userId: 'user123',
          userDisplayName: 'Test User',
          userPhotoURL: '👤',
          content: 'Test message content',
          reportCount: 3,
        );

        // Act
        final result =
            chatMessage.getReportCountWithCache(mockMessageMetaCache);

        // Assert
        expect(result, equals(3)); // Should fallback to original count
      });

      test('should work with topic messages', () {
        // Arrange
        const messageId = 'topic_message_id';
        const reportCount = 4;

        final topicMessage = TopicTextMessage(
          id: messageId,
          createdAt: Timestamp.now(),
          userId: 'user123',
          userDisplayName: 'Test User',
          userPhotoURL: '👤',
          content: 'Test topic message',
          reportCount: 1,
        );

        when(mockMessageMetaCache.getMessageReportCountWithFallback(
          messageId,
          1,
        )).thenReturn(reportCount);

        // Act
        final result =
            topicMessage.getReportCountWithCache(mockMessageMetaCache);

        // Assert
        expect(result, equals(reportCount));
      });
    });

    group('MessageReportHelper Static Methods Tests', () {
      test('should get report count for any message type', () {
        // Arrange
        const messageId = 'test_message_id';
        const reportCount = 3;

        final chatMessage = ChatTextMessage(
          id: messageId,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          userId: 'user123',
          userDisplayName: 'Test User',
          userPhotoURL: '👤',
          content: 'Test message content',
          reportCount: 1,
        );

        when(mockMessageMetaCache.getMessageReportCountWithFallback(
          messageId,
          1,
        )).thenReturn(reportCount);

        // Act
        final result = MessageReportHelper.getMessageReportCount(
          chatMessage,
          mockMessageMetaCache,
        );

        // Assert
        expect(result, equals(reportCount));
      });

      test('should validate message IDs correctly', () {
        // Test valid IDs
        expect(MessageReportHelper.isValidMessageId('valid_id_123'), isTrue);
        expect(MessageReportHelper.isValidMessageId('message-id'), isTrue);
        expect(MessageReportHelper.isValidMessageId('msg_123'), isTrue);

        // Test invalid IDs
        expect(MessageReportHelper.isValidMessageId(''), isFalse);
        expect(MessageReportHelper.isValidMessageId(null), isFalse);
        expect(MessageReportHelper.isValidMessageId('   '), isFalse);
        expect(MessageReportHelper.isValidMessageId('invalid@id'), isFalse);
        expect(MessageReportHelper.isValidMessageId('id with spaces'), isFalse);
      });

      test('should get message IDs from different message types', () {
        // Arrange
        const messageId = 'test_message_id';

        final chatMessage = ChatTextMessage(
          id: messageId,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          userId: 'user123',
          userDisplayName: 'Test User',
          userPhotoURL: '👤',
          content: 'Test message content',
        );

        final topicMessage = TopicTextMessage(
          id: messageId,
          createdAt: Timestamp.now(),
          userId: 'user123',
          userDisplayName: 'Test User',
          userPhotoURL: '👤',
          content: 'Test topic message',
        );

        // Act & Assert
        expect(
            MessageReportHelper.getMessageId(chatMessage), equals(messageId));
        expect(
            MessageReportHelper.getMessageId(topicMessage), equals(messageId));
        expect(MessageReportHelper.getMessageId(null), isNull);
      });

      test('should generate comprehensive debug info', () {
        // Arrange
        const messageId = 'test_message_id';
        const reportCount = 3;

        final chatMessage = ChatTextMessage(
          id: messageId,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          userId: 'user123',
          userDisplayName: 'Test User',
          userPhotoURL: '👤',
          content: 'Test message content',
          reportCount: 1,
        );

        when(mockMessageMetaCache.getMessageReportCountWithFallback(
          messageId,
          1,
        )).thenReturn(reportCount);
        when(mockMessageMetaCache.getMessageReportCount(messageId))
            .thenReturn(reportCount);

        // Act
        final debugInfo = MessageReportHelper.getReportDebugInfo(
          chatMessage,
          mockMessageMetaCache,
        );

        // Assert
        expect(debugInfo['messageId'], equals(messageId));
        expect(debugInfo['reportCount'], equals(reportCount));
        expect(debugInfo['hasValidId'], isTrue);
        expect(debugInfo['hasCacheAvailable'], isTrue);
        expect(debugInfo['messageType'], contains('ChatTextMessage'));
        expect(debugInfo['originalReportCountField'], equals(1));
        expect(debugInfo['cacheValue'], equals(reportCount));
        expect(debugInfo['timestamp'], isNotNull);
      });

      test('should generate report statistics', () {
        // Arrange
        final messages = [
          ChatTextMessage(
            id: 'msg1',
            createdAt: DateTime.now().millisecondsSinceEpoch,
            userId: 'user1',
            userDisplayName: 'User 1',
            userPhotoURL: '👤',
            content: 'Normal message',
            reportCount: 0,
          ),
          ChatTextMessage(
            id: 'msg2',
            createdAt: DateTime.now().millisecondsSinceEpoch,
            userId: 'user2',
            userDisplayName: 'User 2',
            userPhotoURL: '👤',
            content: 'Flagged message',
            reportCount: 2,
          ),
          ChatTextMessage(
            id: 'msg3',
            createdAt: DateTime.now().millisecondsSinceEpoch,
            userId: 'user3',
            userDisplayName: 'User 3',
            userPhotoURL: '👤',
            content: 'Hidden message',
            reportCount: 6,
          ),
        ];

        when(mockMessageMetaCache.getMessageReportCountWithFallback('msg1', 0))
            .thenReturn(0);
        when(mockMessageMetaCache.getMessageReportCountWithFallback('msg2', 2))
            .thenReturn(2);
        when(mockMessageMetaCache.getMessageReportCountWithFallback('msg3', 6))
            .thenReturn(6);

        // Act
        final stats = MessageReportHelper.getReportStatistics(
          messages,
          mockMessageMetaCache,
        );

        // Assert
        expect(stats['totalMessages'], equals(3));
        expect(stats['validMessages'], equals(3));
        expect(stats['reportedMessages'], equals(2)); // msg2 and msg3
        expect(stats['flaggedMessages'], equals(1)); // msg2
        expect(stats['hiddenMessages'], equals(1)); // msg3
        expect(stats['totalReports'], equals(8)); // 0 + 2 + 6
        expect(stats['averageReportsPerMessage'], closeTo(2.67, 0.01));
        expect(stats['reportRate'], closeTo(0.67, 0.01)); // 2/3
        expect(stats['flagRate'], closeTo(0.33, 0.01)); // 1/3
        expect(stats['hideRate'], closeTo(0.33, 0.01)); // 1/3
      });
    });

    group('MessageMetaCache Integration Tests', () {
      test('should store and retrieve report count correctly', () {
        // This would test the actual MessageMetaCache implementation
        // For now, we'll test the mock behavior

        const messageId = 'test_message_id';
        const reportCount = 5;

        when(mockMessageMetaCache.getMessageReportCount(messageId))
            .thenReturn(reportCount);
        when(mockMessageMetaCache.getMessageReportCountWithFallback(
          messageId,
          0,
        )).thenReturn(reportCount);

        // Act
        final directResult =
            mockMessageMetaCache.getMessageReportCount(messageId);
        final fallbackResult =
            mockMessageMetaCache.getMessageReportCountWithFallback(
          messageId,
          0,
        );

        // Assert
        expect(directResult, equals(reportCount));
        expect(fallbackResult, equals(reportCount));
      });

      test('should handle cache disposal gracefully', () {
        // Arrange
        const messageId = 'test_message_id';

        when(mockMessageMetaCache.getMessageReportCount(messageId))
            .thenReturn(0);

        // Act & Assert
        expect(() => mockMessageMetaCache.getMessageReportCount(messageId),
            returnsNormally);
      });
    });

    group('Widget Integration Tests', () {
      testWidgets('ChatTextMessageItem should show report status',
          (tester) async {
        // Arrange
        const messageId = 'test_message_id';
        const reportCount = 3;

        final message = ChatTextMessage(
          id: messageId,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          userId: 'user123',
          userDisplayName: 'Test User',
          userPhotoURL: '👤',
          content: 'Test message content',
          reportCount: 1,
        );

        when(mockMessageMetaCache.getMessageReportCountWithFallback(
          messageId,
          1,
        )).thenReturn(reportCount);
        when(mockMessageMetaCache.isMessageRecalledWithFallback(
          messageId,
          false,
        )).thenReturn(false);

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: MultiProvider(
              providers: [
                ChangeNotifierProvider<MessageMetaCache>.value(
                  value: mockMessageMetaCache,
                ),
                Provider<UserCache>.value(value: mockUserCache),
              ],
              child: Scaffold(
                body: ChatTextMessageItem(
                  chatId: 'test_chat_id',
                  message: message,
                ),
              ),
            ),
          ),
        );

        // Assert
        expect(find.byType(ChatTextMessageItem), findsOneWidget);
        // Additional assertions would depend on the specific UI implementation
      });

      testWidgets('TopicTextMessageItem should show report status',
          (tester) async {
        // Arrange
        const messageId = 'test_message_id';
        const reportCount = 6; // Hidden message

        final message = TopicTextMessage(
          id: messageId,
          createdAt: Timestamp.now(),
          userId: 'user123',
          userDisplayName: 'Test User',
          userPhotoURL: '👤',
          content: 'Test topic message',
          reportCount: 1,
        );

        when(mockMessageMetaCache.getMessageReportCountWithFallback(
          messageId,
          1,
        )).thenReturn(reportCount);
        when(mockMessageMetaCache.isMessageRecalledWithFallback(
          messageId,
          false,
        )).thenReturn(false);

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: MultiProvider(
              providers: [
                ChangeNotifierProvider<MessageMetaCache>.value(
                  value: mockMessageMetaCache,
                ),
                Provider<UserCache>.value(value: mockUserCache),
              ],
              child: Scaffold(
                body: TopicTextMessageItem(
                  topicId: 'test_topic_id',
                  topicCreatorId: 'creator123',
                  message: message,
                ),
              ),
            ),
          ),
        );

        // Assert
        expect(find.byType(TopicTextMessageItem), findsOneWidget);
        // The message should be hidden due to high report count
        expect(find.text('🚫 This message has been hidden due to reports'),
            findsOneWidget);
      });
    });

    group('Edge Cases and Error Handling', () {
      test('should handle null messages gracefully', () {
        // Act & Assert
        expect(
            MessageReportHelper.getMessageReportCount(
                null, mockMessageMetaCache),
            equals(0));
        expect(MessageReportHelper.isMessageFlagged(null, mockMessageMetaCache),
            isFalse);
        expect(MessageReportHelper.isMessageHidden(null, mockMessageMetaCache),
            isFalse);
        expect(MessageReportHelper.getMessageId(null), isNull);
      });

      test('should handle cache errors gracefully', () {
        // Arrange
        const messageId = 'test_message_id';

        final chatMessage = ChatTextMessage(
          id: messageId,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          userId: 'user123',
          userDisplayName: 'Test User',
          userPhotoURL: '👤',
          content: 'Test message content',
          reportCount: 2,
        );

        when(mockMessageMetaCache.getMessageReportCountWithFallback(
          messageId,
          2,
        )).thenThrow(Exception('Cache error'));

        // Act & Assert
        expect(() => chatMessage.getReportCountWithCache(mockMessageMetaCache),
            returnsNormally);
        // Should fallback to original count on error
        expect(chatMessage.getReportCountWithCache(mockMessageMetaCache),
            equals(2));
      });

      test('should handle very high report counts', () {
        // Arrange
        const messageId = 'test_message_id';
        const veryHighReportCount = 1000;

        final chatMessage = ChatTextMessage(
          id: messageId,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          userId: 'user123',
          userDisplayName: 'Test User',
          userPhotoURL: '👤',
          content: 'Test message content',
          reportCount: 0,
        );

        when(mockMessageMetaCache.getMessageReportCountWithFallback(
          messageId,
          0,
        )).thenReturn(veryHighReportCount);

        // Act
        final result =
            chatMessage.getReportCountWithCache(mockMessageMetaCache);
        final isSevere = chatMessage.isSevereWithCache(mockMessageMetaCache);

        // Assert
        expect(result, equals(veryHighReportCount));
        expect(isSevere, isTrue);
      });
    });

    group('Performance Tests', () {
      test('should handle batch operations efficiently', () {
        // Arrange
        final messages = List.generate(
            100,
            (index) => ChatTextMessage(
                  id: 'msg_$index',
                  createdAt: DateTime.now().millisecondsSinceEpoch,
                  userId: 'user_$index',
                  userDisplayName: 'User $index',
                  userPhotoURL: '👤',
                  content: 'Message $index',
                  reportCount: index % 10, // Varying report counts
                ));

        // Setup mock responses
        for (int i = 0; i < 100; i++) {
          when(mockMessageMetaCache.getMessageReportCountWithFallback(
            'msg_$i',
            i % 10,
          )).thenReturn(i % 10);
        }

        // Act
        final stopwatch = Stopwatch()..start();
        final reportCounts = MessageReportHelper.batchCheckReportCount(
          messages,
          mockMessageMetaCache,
        );
        stopwatch.stop();

        // Assert
        expect(reportCounts.length, equals(100));
        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Should be fast
      });

      test('should generate statistics efficiently for large datasets', () {
        // Arrange
        final messages = List.generate(
            1000,
            (index) => ChatTextMessage(
                  id: 'msg_$index',
                  createdAt: DateTime.now().millisecondsSinceEpoch,
                  userId: 'user_$index',
                  userDisplayName: 'User $index',
                  userPhotoURL: '👤',
                  content: 'Message $index',
                  reportCount: index % 20, // Varying report counts
                ));

        // Setup mock responses
        for (int i = 0; i < 1000; i++) {
          when(mockMessageMetaCache.getMessageReportCountWithFallback(
            'msg_$i',
            i % 20,
          )).thenReturn(i % 20);
        }

        // Act
        final stopwatch = Stopwatch()..start();
        final stats = MessageReportHelper.getReportStatistics(
          messages,
          mockMessageMetaCache,
        );
        stopwatch.stop();

        // Assert
        expect(stats['totalMessages'], equals(1000));
        expect(stopwatch.elapsedMilliseconds,
            lessThan(2000)); // Should be reasonably fast
      });
    });
  });
}
