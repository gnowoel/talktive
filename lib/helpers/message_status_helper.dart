import 'package:flutter/material.dart';
import '../models/message.dart';

/// Helper class for handling message status UI logic
class MessageStatusHelper {
  MessageStatusHelper._();

  /// Get the appropriate visual indicator for a message's report status
  static Widget? getStatusIndicator(Message message, {double size = 16}) {
    if (message.reportStatus == null) return null;

    switch (message.reportStatus) {
      case 'flagged':
        return Icon(
          Icons.flag_outlined,
          size: size,
          color: Colors.orange,
        );
      case 'hidden':
        return Icon(
          Icons.visibility_off,
          size: size,
          color: Colors.red,
        );
      case 'severe':
        return Icon(
          Icons.block,
          size: size,
          color: Colors.red.shade900,
        );
      default:
        return null;
    }
  }

  /// Check if a message should be visible to regular users
  static bool shouldShowMessage(Message message, {bool isAdmin = false}) {
    // Admins can always see messages
    if (isAdmin) return true;

    // Hide messages marked as hidden or severe
    if (message.reportStatus == 'hidden' || message.reportStatus == 'severe') {
      return false;
    }

    return true;
  }

  /// Get replacement content for hidden messages
  static String getHiddenMessageContent(Message message) {
    switch (message.reportStatus) {
      case 'hidden':
        return '- Message hidden due to reports -';
      case 'severe':
        return '- Message removed for policy violation -';
      default:
        return '- Message unavailable -';
    }
  }

  /// Get the background color for messages based on status
  static Color? getMessageBackgroundColor(Message message, ThemeData theme) {
    if (message.reportStatus == null) return null;

    switch (message.reportStatus) {
      case 'flagged':
        return theme.colorScheme.surfaceVariant.withOpacity(0.3);
      case 'hidden':
        return theme.colorScheme.errorContainer.withOpacity(0.1);
      case 'severe':
        return theme.colorScheme.errorContainer.withOpacity(0.2);
      default:
        return null;
    }
  }

  /// Get border color for messages based on status
  static Color? getMessageBorderColor(Message message, ThemeData theme) {
    if (message.reportStatus == null) return null;

    switch (message.reportStatus) {
      case 'flagged':
        return Colors.orange.withOpacity(0.5);
      case 'hidden':
        return theme.colorScheme.error.withOpacity(0.3);
      case 'severe':
        return theme.colorScheme.error;
      default:
        return null;
    }
  }

  /// Check if message content should be blurred or obscured
  static bool shouldBlurContent(Message message) {
    return message.reportStatus == 'flagged' && 
           (message.reportCount ?? 0) >= 2;
  }

  /// Get tooltip text for status indicators
  static String getStatusTooltip(Message message) {
    if (message.reportStatus == null) return '';

    final count = message.reportCount ?? 0;
    
    switch (message.reportStatus) {
      case 'flagged':
        return 'Flagged for review ($count report${count == 1 ? '' : 's'})';
      case 'hidden':
        return 'Hidden due to reports ($count report${count == 1 ? '' : 's'})';
      case 'severe':
        return 'Removed for policy violation ($count report${count == 1 ? '' : 's'})';
      default:
        return '';
    }
  }

  /// Create a warning banner widget for flagged messages
  static Widget? createWarningBanner(Message message, ThemeData theme) {
    if (message.reportStatus != 'flagged') return null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_amber,
            size: 14,
            color: Colors.orange.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            'Under review',
            style: TextStyle(
              fontSize: 11,
              color: Colors.orange.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Get appropriate context menu options based on message status
  static List<String> getAvailableActions(
    Message message, {
    required bool isAuthor,
    required bool isAdmin,
  }) {
    final actions = <String>[];

    // Standard actions
    if (!isAuthor) {
      actions.add('Copy');
    }

    // Author actions
    if (isAuthor && !message.recalled) {
      actions.add('Recall');
    }

    // Reporting actions
    if (!isAuthor && message.reportStatus != 'severe') {
      actions.add('Report');
    }

    // Admin actions
    if (isAdmin) {
      actions.addAll([
        'View Reports',
        'Moderate',
        if (message.reportStatus != null) 'Clear Status',
      ]);
    }

    return actions;
  }

  /// Check if a message should show a content warning
  static bool shouldShowContentWarning(Message message) {
    return message.reportStatus == 'flagged' && 
           (message.reportCount ?? 0) >= 1;
  }

  /// Create a content warning widget
  static Widget createContentWarning(
    Message message, 
    ThemeData theme, {
    required VoidCallback onProceed,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_amber,
            color: Colors.orange.shade700,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            'Content Warning',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'This message has been flagged by other users.',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onProceed,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            ),
            child: const Text('Show Anyway'),
          ),
        ],
      ),
    );
  }

  /// Calculate severity level based on report count and status
  static double getSeverityLevel(Message message) {
    if (message.reportStatus == null) return 0.0;

    switch (message.reportStatus) {
      case 'flagged':
        return 0.3;
      case 'hidden':
        return 0.7;
      case 'severe':
        return 1.0;
      default:
        return 0.0;
    }
  }

  /// Get moderation priority (higher = more urgent)
  static int getModerationPriority(Message message) {
    final count = message.reportCount ?? 0;
    
    switch (message.reportStatus) {
      case 'severe':
        return 100 + count;
      case 'hidden':
        return 50 + count;
      case 'flagged':
        return 10 + count;
      default:
        return 0;
    }
  }
}