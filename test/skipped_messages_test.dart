import 'package:flutter_test/flutter_test.dart';

// Helper function to simulate the skipped messages logic
class SkippedMessagesLogic {
  static bool shouldShowPlaceholder({
    required int readMessageCount,
    required bool showAllMessages,
    required bool isNew,
    bool isReporter = false,
  }) {
    if (isReporter) return false; // Never show placeholder in admin reports
    if (showAllMessages) return false; // User chose to see all messages
    if (isNew) return false; // New chat, show info instead

    return readMessageCount > 20; // Only skip if more than 20 messages
  }

  static bool shouldShowConfirmationDialog(int readMessageCount) {
    final messagesToSkip = readMessageCount - 10;
    return messagesToSkip > 100;
  }

  static List<int> getVisibleMessageIndices({
    required int totalMessages,
    required int readMessageCount,
    required bool showPlaceholder,
  }) {
    // Skip oldest messages but keep last 10 read messages for context
    final messagesToSkip = showPlaceholder ? readMessageCount - 10 : 0;
    return List.generate(
      totalMessages - messagesToSkip,
      (index) => index + messagesToSkip,
    );
  }

  static int getItemCount({
    required int visibleMessageCount,
    required bool showPlaceholder,
  }) {
    return showPlaceholder ? visibleMessageCount + 1 : visibleMessageCount;
  }
}

void main() {
  group('Skipped Messages Logic Tests', () {
    test('should not show placeholder when read messages <= 20', () {
      // Test cases where placeholder should NOT be shown
      expect(
        SkippedMessagesLogic.shouldShowPlaceholder(
          readMessageCount: 0,
          showAllMessages: false,
          isNew: false,
        ),
        false,
      );

      expect(
        SkippedMessagesLogic.shouldShowPlaceholder(
          readMessageCount: 5,
          showAllMessages: false,
          isNew: false,
        ),
        false,
      );

      expect(
        SkippedMessagesLogic.shouldShowPlaceholder(
          readMessageCount: 20,
          showAllMessages: false,
          isNew: false,
        ),
        false,
      );
    });

    test('should show placeholder when read messages > 20', () {
      expect(
        SkippedMessagesLogic.shouldShowPlaceholder(
          readMessageCount: 21,
          showAllMessages: false,
          isNew: false,
        ),
        true,
      );

      expect(
        SkippedMessagesLogic.shouldShowPlaceholder(
          readMessageCount: 50,
          showAllMessages: false,
          isNew: false,
        ),
        true,
      );

      expect(
        SkippedMessagesLogic.shouldShowPlaceholder(
          readMessageCount: 150,
          showAllMessages: false,
          isNew: false,
        ),
        true,
      );
    });

    test('should not show placeholder when user chose to see all messages', () {
      expect(
        SkippedMessagesLogic.shouldShowPlaceholder(
          readMessageCount: 50,
          showAllMessages: true, // User chose to see all
          isNew: false,
        ),
        false,
      );
    });

    test('should not show placeholder for new chats', () {
      expect(
        SkippedMessagesLogic.shouldShowPlaceholder(
          readMessageCount: 50,
          showAllMessages: false,
          isNew: true, // New chat
        ),
        false,
      );
    });

    test('should not show placeholder for reporter/admin view', () {
      expect(
        SkippedMessagesLogic.shouldShowPlaceholder(
          readMessageCount: 50,
          showAllMessages: false,
          isNew: false,
          isReporter: true, // Admin report view
        ),
        false,
      );
    });

    test('should show confirmation dialog when messages to skip > 100', () {
      expect(SkippedMessagesLogic.shouldShowConfirmationDialog(50),
          false); // 50-10=40 to skip
      expect(SkippedMessagesLogic.shouldShowConfirmationDialog(110),
          false); // 110-10=100 to skip
      expect(SkippedMessagesLogic.shouldShowConfirmationDialog(111),
          true); // 111-10=101 to skip
      expect(SkippedMessagesLogic.shouldShowConfirmationDialog(500),
          true); // 500-10=490 to skip
    });

    test('should calculate visible messages correctly', () {
      // Test case: 50 total messages, 30 read, placeholder shown
      // Skip 20 oldest (30-10), keep 10 context + 20 unread = 30 visible
      final visibleIndices = SkippedMessagesLogic.getVisibleMessageIndices(
        totalMessages: 50,
        readMessageCount: 30,
        showPlaceholder: true,
      );

      expect(visibleIndices.length, 30); // 50 - (30-10) = 30 visible
      expect(
          visibleIndices.first, 20); // Starts from message 20 (skip first 20)
      expect(visibleIndices.last, 49); // Ends at message 49
    });

    test('should calculate visible messages when no placeholder', () {
      // Test case: 50 total messages, no placeholder
      final visibleIndices = SkippedMessagesLogic.getVisibleMessageIndices(
        totalMessages: 50,
        readMessageCount: 30,
        showPlaceholder: false,
      );

      expect(visibleIndices.length, 50); // All messages visible
      expect(visibleIndices.first, 0); // Starts from message 0
      expect(visibleIndices.last, 49); // Ends at message 49
    });

    test('should calculate item count correctly', () {
      // With placeholder: visible messages + 1 (for placeholder)
      expect(
        SkippedMessagesLogic.getItemCount(
          visibleMessageCount: 20,
          showPlaceholder: true,
        ),
        21,
      );

      // Without placeholder: just visible messages
      expect(
        SkippedMessagesLogic.getItemCount(
          visibleMessageCount: 20,
          showPlaceholder: false,
        ),
        20,
      );
    });

    group('Integration scenarios', () {
      test('scenario: few messages (15 total, 12 read)', () {
        const totalMessages = 15;
        const readMessages = 12;

        final showPlaceholder = SkippedMessagesLogic.shouldShowPlaceholder(
          readMessageCount: readMessages,
          showAllMessages: false,
          isNew: false,
        );

        expect(
            showPlaceholder, false); // Should not show placeholder (12 <= 20)

        final visibleIndices = SkippedMessagesLogic.getVisibleMessageIndices(
          totalMessages: totalMessages,
          readMessageCount: readMessages,
          showPlaceholder: showPlaceholder,
        );

        expect(visibleIndices.length, 15); // All messages visible
      });

      test('scenario: some messages (42 total, 24 read)', () {
        const totalMessages = 42;
        const readMessages = 24;

        final showPlaceholder = SkippedMessagesLogic.shouldShowPlaceholder(
          readMessageCount: readMessages,
          showAllMessages: false,
          isNew: false,
        );

        expect(showPlaceholder, true); // Should show placeholder (24 > 20)

        final visibleIndices = SkippedMessagesLogic.getVisibleMessageIndices(
          totalMessages: totalMessages,
          readMessageCount: readMessages,
          showPlaceholder: showPlaceholder,
        );

        expect(visibleIndices.length, 28); // 42 - (24-10) = 28 visible
        expect(
            visibleIndices.first, 14); // Starts from message 14 (skip first 14)

        final itemCount = SkippedMessagesLogic.getItemCount(
          visibleMessageCount: visibleIndices.length,
          showPlaceholder: showPlaceholder,
        );

        expect(itemCount, 29); // 28 messages + 1 placeholder
      });

      test('scenario: many messages (200 total, 150 read)', () {
        const totalMessages = 200;
        const readMessages = 150;

        final showPlaceholder = SkippedMessagesLogic.shouldShowPlaceholder(
          readMessageCount: readMessages,
          showAllMessages: false,
          isNew: false,
        );

        expect(showPlaceholder, true); // Should show placeholder (150 > 20)

        final showConfirmation =
            SkippedMessagesLogic.shouldShowConfirmationDialog(readMessages);

        expect(showConfirmation,
            true); // Should show confirmation dialog (150-10=140 > 100)

        final visibleIndices = SkippedMessagesLogic.getVisibleMessageIndices(
          totalMessages: totalMessages,
          readMessageCount: readMessages,
          showPlaceholder: showPlaceholder,
        );

        expect(visibleIndices.length, 60); // 200 - (150-10) = 60 visible
        expect(visibleIndices.first,
            140); // Starts from message 140 (skip first 140)
      });
    });
  });
}
