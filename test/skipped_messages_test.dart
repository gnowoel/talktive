import 'package:flutter_test/flutter_test.dart';

// Helper function to simulate the skipped messages logic
class SkippedMessagesLogic {
  static bool shouldShowPlaceholder({
    required int readMessageCount,
    required int additionalMessagesRevealed,
    required bool isNew,
    bool isReporter = false,
  }) {
    if (isReporter) return false; // Never show placeholder in admin reports
    if (isNew) return false; // New chat, show info instead

    final totalMessagesToShow = 25 + additionalMessagesRevealed;
    return readMessageCount >
        totalMessagesToShow; // Show placeholder if more messages available
  }

  static bool shouldShowConfirmationDialog(int readMessageCount) {
    // No confirmation dialog needed for the new simplified approach
    return false;
  }

  static List<int> getVisibleMessageIndices({
    required int totalMessages,
    required int readMessageCount,
    required bool showPlaceholder,
    required int additionalMessagesRevealed,
  }) {
    // Always show first 10 messages + last 15 read messages as context
    final firstMessagesCount = readMessageCount >= 10 ? 10 : readMessageCount;
    final lastReadContextCount = 15 + additionalMessagesRevealed;

    if (!showPlaceholder) {
      // No placeholder, show all read + unread messages
      return List.generate(totalMessages, (index) => index);
    }

    // Calculate messages to skip between first 10 and last context
    final totalContextShown = firstMessagesCount + lastReadContextCount;
    final messagesToSkip = readMessageCount > totalContextShown
        ? readMessageCount - totalContextShown
        : 0;

    final unreadCount = totalMessages - readMessageCount;
    List<int> indices = [];

    // Add first 10 messages (indices 0-9)
    for (int i = 0; i < firstMessagesCount; i++) {
      indices.add(i);
    }

    // Add last read context messages
    final lastContextStart = readMessageCount - lastReadContextCount;
    for (int i = 0; i < lastReadContextCount && lastContextStart + i < readMessageCount; i++) {
      indices.add(lastContextStart + i);
    }

    // Add unread messages
    for (int i = 0; i < unreadCount; i++) {
      indices.add(readMessageCount + i);
    }

    return indices;
  }

  static int getItemCount({
    required int readMessageCount,
    required int totalMessages,
    required bool showPlaceholder,
    required bool showSeparator,
    required int additionalMessagesRevealed,
  }) {
    final unreadCount = totalMessages - readMessageCount;

    var itemCount = 0;
    if (showPlaceholder) {
      final firstMessagesCount = readMessageCount >= 10 ? 10 : readMessageCount;
      final lastReadContextCount = 15 + additionalMessagesRevealed;

      itemCount += firstMessagesCount; // First 10 messages
      itemCount += 1; // Placeholder
      itemCount += lastReadContextCount; // Last 15 read messages
    } else {
      itemCount += readMessageCount; // All read messages (no placeholder)
    }
    if (showSeparator) itemCount += 1; // Add separator
    itemCount += unreadCount; // Add unread messages

    return itemCount;
  }

  static bool shouldShowSeparator({
    required int readMessageCount,
    required int totalMessages,
    bool isReporter = false,
  }) {
    if (isReporter) return false; // Not in admin view
    return readMessageCount > 0 && totalMessages > readMessageCount;
  }

  static int? getSeparatorIndex({
    required int readMessageCount,
    required bool showPlaceholder,
    required bool showSeparator,
    required int additionalMessagesRevealed,
  }) {
    if (!showSeparator) return null;

    if (showPlaceholder) {
      final firstMessagesCount = readMessageCount >= 10 ? 10 : readMessageCount;
      final lastReadContextCount = 15 + additionalMessagesRevealed;
      return firstMessagesCount + 1 + lastReadContextCount; // first + placeholder + last
    } else {
      return readMessageCount; // All read messages
    }
  }
}

void main() {
  group('Skipped Messages Logic Tests', () {
    test('should not show placeholder when read messages <= threshold', () {
      // Test cases where placeholder should NOT be shown
      expect(
        SkippedMessagesLogic.shouldShowPlaceholder(
          readMessageCount: 0,
          additionalMessagesRevealed: 0,
          isNew: false,
        ),
        false,
      );

      expect(
        SkippedMessagesLogic.shouldShowPlaceholder(
          readMessageCount: 5,
          additionalMessagesRevealed: 0,
          isNew: false,
        ),
        false,
      );

      expect(
        SkippedMessagesLogic.shouldShowPlaceholder(
          readMessageCount: 25,
          additionalMessagesRevealed: 0,
          isNew: false,
        ),
        false,
      );

      // With additional messages revealed - still no placeholder if total context covers all read
      expect(
        SkippedMessagesLogic.shouldShowPlaceholder(
          readMessageCount: 50,
          additionalMessagesRevealed: 25,
          isNew: false,
        ),
        false,
      );
    });

    test('should show placeholder when read messages > threshold', () {
      expect(
        SkippedMessagesLogic.shouldShowPlaceholder(
          readMessageCount: 26,
          additionalMessagesRevealed: 0,
          isNew: false,
        ),
        true,
      );

      expect(
        SkippedMessagesLogic.shouldShowPlaceholder(
          readMessageCount: 50,
          additionalMessagesRevealed: 0,
          isNew: false,
        ),
        true,
      );

      expect(
        SkippedMessagesLogic.shouldShowPlaceholder(
          readMessageCount: 150,
          additionalMessagesRevealed: 0,
          isNew: false,
        ),
        true,
      );

      // Should still show placeholder even with additional messages revealed
      expect(
        SkippedMessagesLogic.shouldShowPlaceholder(
          readMessageCount: 100,
          additionalMessagesRevealed: 25,
          isNew: false,
        ),
        true,
      );
    });

    test('should not show placeholder when all messages are revealed', () {
      expect(
        SkippedMessagesLogic.shouldShowPlaceholder(
          readMessageCount: 50,
          additionalMessagesRevealed: 25, // 25 + 25 = 50, so all are revealed
          isNew: false,
        ),
        false,
      );
    });

    test('should not show placeholder for new chats', () {
      expect(
        SkippedMessagesLogic.shouldShowPlaceholder(
          readMessageCount: 50,
          additionalMessagesRevealed: 0,
          isNew: true, // New chat
        ),
        false,
      );
    });

    test('should not show placeholder for reporter/admin view', () {
      expect(
        SkippedMessagesLogic.shouldShowPlaceholder(
          readMessageCount: 50,
          additionalMessagesRevealed: 0,
          isNew: false,
          isReporter: true, // Admin report view
        ),
        false,
      );
    });

    test('should not show confirmation dialog with new simplified approach',
        () {
      expect(SkippedMessagesLogic.shouldShowConfirmationDialog(50), false);
      expect(SkippedMessagesLogic.shouldShowConfirmationDialog(110), false);
      expect(SkippedMessagesLogic.shouldShowConfirmationDialog(111), false);
      expect(SkippedMessagesLogic.shouldShowConfirmationDialog(500), false);
    });

    test('should calculate visible messages correctly', () {
      // Test case: 50 total messages, 30 read, placeholder shown
      // Show first 10 + last 15 read + 20 unread = 45 visible
      final visibleIndices = SkippedMessagesLogic.getVisibleMessageIndices(
        totalMessages: 50,
        readMessageCount: 30,
        showPlaceholder: true,
        additionalMessagesRevealed: 0,
      );

      expect(visibleIndices.length, 45); // 10 first + 15 last + 20 unread = 45 visible
      expect(visibleIndices.first, 0); // First message is always index 0
      expect(visibleIndices.last, 49); // Ends at message 49 (last unread)

      // Check specific ranges
      expect(visibleIndices.take(10).toList(),
          [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]); // First 10 messages
      expect(visibleIndices.skip(10).take(15).toList(),
          [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29]); // Last 15 read messages
      expect(visibleIndices.skip(25).toList(),
          List.generate(20, (i) => 30 + i)); // 20 unread messages
    });

    test('should calculate visible messages when no placeholder', () {
      // Test case: 50 total messages, no placeholder
      final visibleIndices = SkippedMessagesLogic.getVisibleMessageIndices(
        totalMessages: 50,
        readMessageCount: 30,
        showPlaceholder: false,
        additionalMessagesRevealed: 0,
      );

      expect(visibleIndices.length, 50); // All messages visible
      expect(visibleIndices.first, 0); // Starts from message 0
      expect(visibleIndices.last, 49); // Ends at message 49
    });

    test('should calculate item count correctly', () {
      // Test case: 50 total, 30 read, with placeholder and separator
      expect(
        SkippedMessagesLogic.getItemCount(
          readMessageCount: 30,
          totalMessages: 50,
          showPlaceholder: true,
          showSeparator: true,
          additionalMessagesRevealed: 0,
        ),
        47, // 10 first + 1 placeholder + 15 last + 1 separator + 20 unread = 47
      );

      // Without placeholder: just all read + separator + unread
      expect(
        SkippedMessagesLogic.getItemCount(
          readMessageCount: 30,
          totalMessages: 50,
          showPlaceholder: false,
          showSeparator: true,
          additionalMessagesRevealed: 0,
        ),
        51, // 30 read + 1 separator + 20 unread = 51
      );

      // Without separator: first + placeholder + last + unread only
      expect(
        SkippedMessagesLogic.getItemCount(
          readMessageCount: 30,
          totalMessages: 50,
          showPlaceholder: true,
          showSeparator: false,
          additionalMessagesRevealed: 0,
        ),
        46, // 10 first + 1 placeholder + 15 last + 20 unread = 46
      );

      // Without placeholder or separator: just all read + unread
      expect(
        SkippedMessagesLogic.getItemCount(
          readMessageCount: 30,
          totalMessages: 50,
          showPlaceholder: false,
          showSeparator: false,
          additionalMessagesRevealed: 0,
        ),
        50, // 30 read + 20 unread = 50
      );
    });

    test('should determine when to show separator', () {
      // Should show separator when there are read and unread messages
      expect(
        SkippedMessagesLogic.shouldShowSeparator(
          readMessageCount: 10,
          totalMessages: 15,
        ),
        true,
      );

      // Should not show separator when all messages are read
      expect(
        SkippedMessagesLogic.shouldShowSeparator(
          readMessageCount: 15,
          totalMessages: 15,
        ),
        false,
      );

      // Should not show separator when no messages are read
      expect(
        SkippedMessagesLogic.shouldShowSeparator(
          readMessageCount: 0,
          totalMessages: 15,
        ),
        false,
      );

      // Should not show separator in reporter/admin view
      expect(
        SkippedMessagesLogic.shouldShowSeparator(
          readMessageCount: 10,
          totalMessages: 15,
          isReporter: true,
        ),
        false,
      );
    });

    test('should calculate separator index correctly', () {
      // With placeholder: 10 first + 1 placeholder + 15 last = index 26
      expect(
        SkippedMessagesLogic.getSeparatorIndex(
          readMessageCount: 30,
          showPlaceholder: true,
          showSeparator: true,
          additionalMessagesRevealed: 0,
        ),
        26, // 10 + 1 + 15 = 26
      );

      // Without placeholder: 25 context messages = index 25
      expect(
        SkippedMessagesLogic.getSeparatorIndex(
          readMessageCount: 25,
          showPlaceholder: false,
          showSeparator: true,
          additionalMessagesRevealed: 0,
        ),
        25,
      );

      // With additional messages revealed: 10 first + 1 placeholder + 40 last = index 51
      expect(
        SkippedMessagesLogic.getSeparatorIndex(
          readMessageCount: 60,
          showPlaceholder: true,
          showSeparator: true,
          additionalMessagesRevealed: 25,
        ),
        51, // 10 + 1 + 40 = 51
      );

      // Should return null when separator not shown
      expect(
        SkippedMessagesLogic.getSeparatorIndex(
          readMessageCount: 25,
          showPlaceholder: true,
          showSeparator: false,
          additionalMessagesRevealed: 0,
        ),
        null,
      );
    });

    group('Integration scenarios', () {
      test('scenario: few messages (20 total, 15 read)', () {
        const totalMessages = 20;
        const readMessages = 15;

        final showPlaceholder = SkippedMessagesLogic.shouldShowPlaceholder(
          readMessageCount: readMessages,
          additionalMessagesRevealed: 0,
          isNew: false,
        );

        expect(
            showPlaceholder, false); // Should not show placeholder (15 <= 25)

        final visibleIndices = SkippedMessagesLogic.getVisibleMessageIndices(
          totalMessages: totalMessages,
          readMessageCount: readMessages,
          showPlaceholder: showPlaceholder,
          additionalMessagesRevealed: 0,
        );

        expect(visibleIndices.length, 20); // All messages visible
      });

      test('scenario: first 10 + skip + last read context (50 total, 35 read)', () {
        const totalMessages = 50;
        const readMessages = 35;

        // Initial state: 0 additional messages revealed
        var showPlaceholder = SkippedMessagesLogic.shouldShowPlaceholder(
          readMessageCount: readMessages,
          additionalMessagesRevealed: 0,
          isNew: false,
        );

        expect(showPlaceholder, true); // Should show placeholder (35 > 10+15=25)

        var visibleIndices = SkippedMessagesLogic.getVisibleMessageIndices(
          totalMessages: totalMessages,
          readMessageCount: readMessages,
          showPlaceholder: showPlaceholder,
          additionalMessagesRevealed: 0,
        );

        // Should have: 10 first + 15 last read + 15 unread = 40 visible
        expect(visibleIndices.length, 40);
        expect(visibleIndices.first, 0); // First message is always index 0

        // Verify the structure: first 10 should be messages 0-9, last 15 should be messages 20-34
        expect(visibleIndices.take(10).toList(),
            List.generate(10, (i) => i)); // First 10 messages (0-9)
        expect(visibleIndices.skip(10).take(15).toList(),
            List.generate(15, (i) => 20 + i)); // Last 15 read messages (20-34)
        expect(visibleIndices.skip(25).toList(),
            List.generate(15, (i) => 35 + i)); // Unread messages (35-49)

        // After revealing 25 more messages (total 40 context messages)
        showPlaceholder = SkippedMessagesLogic.shouldShowPlaceholder(
          readMessageCount: readMessages,
          additionalMessagesRevealed: 25,
          isNew: false,
        );

        expect(
            showPlaceholder, false); // Should not show placeholder (35 <= 10+40=50)

        visibleIndices = SkippedMessagesLogic.getVisibleMessageIndices(
          totalMessages: totalMessages,
          readMessageCount: readMessages,
          showPlaceholder: showPlaceholder,
          additionalMessagesRevealed: 25,
        );

        expect(visibleIndices.length, 50); // All messages visible
        expect(visibleIndices.first, 0); // Starts from message 0
      });

      test(
          'scenario: many messages with progressive loading (100 total, 80 read)',
          () {
        const totalMessages = 100;
        const readMessages = 80;

        // Initial state: first 10 + last 15 read = 25 context
        var showPlaceholder = SkippedMessagesLogic.shouldShowPlaceholder(
          readMessageCount: readMessages,
          additionalMessagesRevealed: 0,
          isNew: false,
        );

        expect(showPlaceholder, true); // Should show placeholder (80 > 10+15=25)

        var visibleIndices = SkippedMessagesLogic.getVisibleMessageIndices(
          totalMessages: totalMessages,
          readMessageCount: readMessages,
          showPlaceholder: showPlaceholder,
          additionalMessagesRevealed: 0,
        );

        // Should have: 10 first + 15 last read + 20 unread = 45 visible
        expect(visibleIndices.length, 45);
        expect(visibleIndices.first, 0); // Always starts with first message

        // Verify structure: first 10, last 15 read, then unread
        expect(visibleIndices.take(10).toList(),
            List.generate(10, (i) => i)); // First 10 messages (0-9)
        expect(visibleIndices.skip(10).take(15).toList(),
            List.generate(15, (i) => 65 + i)); // Last 15 read messages (65-79)
        expect(visibleIndices.skip(25).toList(),
            List.generate(20, (i) => 80 + i)); // Unread messages (80-99)

        // After revealing 25 more messages: first 10 + last 40 read = 50 context
        showPlaceholder = SkippedMessagesLogic.shouldShowPlaceholder(
          readMessageCount: readMessages,
          additionalMessagesRevealed: 25,
          isNew: false,
        );

        expect(showPlaceholder, true); // Should still show placeholder (80 > 10+40=50)

        visibleIndices = SkippedMessagesLogic.getVisibleMessageIndices(
          totalMessages: totalMessages,
          readMessageCount: readMessages,
          showPlaceholder: showPlaceholder,
          additionalMessagesRevealed: 25,
        );

        // Should have: 10 first + 40 last read + 20 unread = 70 visible
        expect(visibleIndices.length, 70);
        expect(visibleIndices.first, 0); // Always starts with first message

        // After revealing 55 more messages total: first 10 + last 70 read = 80 context
        showPlaceholder = SkippedMessagesLogic.shouldShowPlaceholder(
          readMessageCount: readMessages,
          additionalMessagesRevealed: 55,
          isNew: false,
        );

        expect(showPlaceholder, false); // Should not show placeholder (80 <= 10+70=80)
      });
    });
  });
}
