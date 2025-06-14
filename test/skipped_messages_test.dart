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

    return readMessageCount > 10; // Only skip if more than 10 messages
  }

  static bool shouldShowConfirmationDialog(int readMessageCount) {
    return readMessageCount > 100;
  }

  static List<int> getVisibleMessageIndices({
    required int totalMessages,
    required int readMessageCount,
    required bool showPlaceholder,
  }) {
    final messagesToSkip = showPlaceholder ? readMessageCount : 0;
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
    test('should not show placeholder when read messages <= 10', () {
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
          readMessageCount: 10,
          showAllMessages: false,
          isNew: false,
        ),
        false,
      );
    });

    test('should show placeholder when read messages > 10', () {
      expect(
        SkippedMessagesLogic.shouldShowPlaceholder(
          readMessageCount: 11,
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

    test('should show confirmation dialog when read messages > 100', () {
      expect(SkippedMessagesLogic.shouldShowConfirmationDialog(50), false);
      expect(SkippedMessagesLogic.shouldShowConfirmationDialog(100), false);
      expect(SkippedMessagesLogic.shouldShowConfirmationDialog(101), true);
      expect(SkippedMessagesLogic.shouldShowConfirmationDialog(500), true);
    });

    test('should calculate visible messages correctly', () {
      // Test case: 50 total messages, 30 read, placeholder shown
      final visibleIndices = SkippedMessagesLogic.getVisibleMessageIndices(
        totalMessages: 50,
        readMessageCount: 30,
        showPlaceholder: true,
      );

      expect(visibleIndices.length, 20); // 50 - 30 = 20 visible
      expect(visibleIndices.first, 30); // Starts from message 30
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
      test('scenario: few messages (8 total, 5 read)', () {
        const totalMessages = 8;
        const readMessages = 5;

        final showPlaceholder = SkippedMessagesLogic.shouldShowPlaceholder(
          readMessageCount: readMessages,
          showAllMessages: false,
          isNew: false,
        );

        expect(showPlaceholder, false); // Should not show placeholder

        final visibleIndices = SkippedMessagesLogic.getVisibleMessageIndices(
          totalMessages: totalMessages,
          readMessageCount: readMessages,
          showPlaceholder: showPlaceholder,
        );

        expect(visibleIndices.length, 8); // All messages visible
      });

      test('scenario: some messages (25 total, 15 read)', () {
        const totalMessages = 25;
        const readMessages = 15;

        final showPlaceholder = SkippedMessagesLogic.shouldShowPlaceholder(
          readMessageCount: readMessages,
          showAllMessages: false,
          isNew: false,
        );

        expect(showPlaceholder, true); // Should show placeholder

        final visibleIndices = SkippedMessagesLogic.getVisibleMessageIndices(
          totalMessages: totalMessages,
          readMessageCount: readMessages,
          showPlaceholder: showPlaceholder,
        );

        expect(visibleIndices.length, 10); // 25 - 15 = 10 visible
        expect(visibleIndices.first, 15); // Starts from message 15

        final itemCount = SkippedMessagesLogic.getItemCount(
          visibleMessageCount: visibleIndices.length,
          showPlaceholder: showPlaceholder,
        );

        expect(itemCount, 11); // 10 messages + 1 placeholder
      });

      test('scenario: many messages (150 total, 120 read)', () {
        const totalMessages = 150;
        const readMessages = 120;

        final showPlaceholder = SkippedMessagesLogic.shouldShowPlaceholder(
          readMessageCount: readMessages,
          showAllMessages: false,
          isNew: false,
        );

        expect(showPlaceholder, true); // Should show placeholder

        final showConfirmation =
            SkippedMessagesLogic.shouldShowConfirmationDialog(readMessages);

        expect(showConfirmation, true); // Should show confirmation dialog

        final visibleIndices = SkippedMessagesLogic.getVisibleMessageIndices(
          totalMessages: totalMessages,
          readMessageCount: readMessages,
          showPlaceholder: showPlaceholder,
        );

        expect(visibleIndices.length, 30); // 150 - 120 = 30 visible
        expect(visibleIndices.first, 120); // Starts from message 120
      });
    });
  });
}
