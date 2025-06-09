import 'package:flutter/material.dart';
import '../models/message.dart';
import '../config/message_report_config.dart';
import '../services/report_cache.dart';

/// Helper class for handling message status UI logic
class MessageStatusHelper {
  MessageStatusHelper._();

  /// Check if a message is hidden but can be revealed
  static bool isHiddenButRevealable(Message message) {
    final status =
        MessageReportConfig.getReportStatus(message.reportCount ?? 0);
    return status == 'hidden';
  }

  /// Check if a message is removed (severe)
  static bool isRemoved(Message message) {
    final status =
        MessageReportConfig.getReportStatus(message.reportCount ?? 0);
    return status == 'severe';
  }

  /// Check if a message should be visible to regular users
  static bool shouldShowMessage(Message message, {bool isAdmin = false}) {
    return MessageReportConfig.shouldShowMessage(
      message.reportCount ?? 0,
      isAdmin: isAdmin,
    );
  }

  /// Get replacement content for hidden messages
  static String getHiddenMessageContent(Message message) {
    final title = message.type == 'image' ? 'Image' : 'Message';
    final status =
        MessageReportConfig.getReportStatus(message.reportCount ?? 0);
    switch (status) {
      case 'hidden':
        return '- $title hidden -';
      case 'severe':
        return '- $title removed -';
      default:
        return '- $title unavailable -';
    }
  }

  /// Get content for copying (original for hidden, replacement for removed)
  static String getCopyContent(Message message, String originalContent) {
    final status =
        MessageReportConfig.getReportStatus(message.reportCount ?? 0);
    switch (status) {
      case 'hidden':
        return originalContent; // Copy original content for hidden messages
      case 'severe':
        return '- Message removed -'; // Copy replacement for removed messages
      default:
        return originalContent;
    }
  }

  /// Get the background color for messages based on status
  static Color? getMessageBackgroundColor(Message message, ThemeData theme) {
    final status =
        MessageReportConfig.getReportStatus(message.reportCount ?? 0);
    if (status == null) return null;

    switch (status) {
      case 'flagged':
        return theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3);
      case 'hidden':
        return theme.colorScheme.errorContainer.withValues(alpha: 0.1);
      case 'severe':
        return theme.colorScheme.errorContainer.withValues(alpha: 0.2);
      default:
        return null;
    }
  }

  /// Get border color for messages based on status
  static Color? getMessageBorderColor(Message message, ThemeData theme) {
    final status =
        MessageReportConfig.getReportStatus(message.reportCount ?? 0);
    if (status == null) return null;

    switch (status) {
      case 'flagged':
        return Colors.orange.withValues(alpha: 0.5);
      case 'hidden':
        return theme.colorScheme.error.withValues(alpha: 0.3);
      case 'severe':
        return theme.colorScheme.error;
      default:
        return null;
    }
  }

  /// Check if message content should be blurred or obscured
  static bool shouldBlurContent(Message message) {
    return MessageReportConfig.shouldBlurContent(message.reportCount ?? 0);
  }

  /// Get tooltip text for status indicators
  static String getStatusTooltip(Message message) {
    return MessageReportConfig.getStatusTooltip(message.reportCount ?? 0);
  }

  /// Check if the report option should be available in context menu
  static bool shouldShowReportOption(Message message, bool isAuthor) {
    if (isAuthor) return false;
    final status =
        MessageReportConfig.getReportStatus(message.reportCount ?? 0);
    return status != 'severe'; // Hide report option for removed messages
  }

  /// Check if a message can be reported (not recently reported)
  static Future<bool> canReportMessage(String messageId) async {
    final reportCache = ReportCacheService();
    await reportCache.initialize();
    final isRecentlyReported = await reportCache.isRecentlyReported(messageId);
    return !isRecentlyReported;
  }

  /// Check if report option should be shown considering cache
  static Future<bool> shouldShowReportOptionWithCache(
    Message message,
    bool isAuthor,
  ) async {
    if (!shouldShowReportOption(message, isAuthor)) return false;
    if (message.id == null) return false;
    return await canReportMessage(message.id!);
  }

  /// Check if a message was recently reported and should show placeholder
  static Future<bool> isRecentlyReported(Message message) async {
    if (message.id == null) return false;
    final reportCache = ReportCacheService();
    await reportCache.initialize();
    return await reportCache.isRecentlyReported(message.id!);
  }

  /// Check if message should show reported placeholder but is revealable
  static Future<bool> isReportedButRevealable(Message message) async {
    // Only show reported placeholder for messages that aren't already hidden/removed
    if (isRemoved(message) || isHiddenButRevealable(message)) return false;
    return await isRecentlyReported(message);
  }

  /// Get placeholder content for recently reported messages
  static String getReportedMessageContent(Message message) {
    final title = message.type == 'image' ? 'Image' : 'Message';
    return '- $title reported -';
  }

  /// Get content for copying reported messages (always return original for text)
  static String getReportedCopyContent(Message message, String originalContent) {
    // For text messages, always allow copying original content
    if (message.type == 'text') {
      return originalContent;
    }
    // For other types, show reported placeholder
    return getReportedMessageContent(message);
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
    final status =
        MessageReportConfig.getReportStatus(message.reportCount ?? 0);
    if (!isAuthor && status != 'severe') {
      actions.add('Report');
    }

    // Admin actions
    if (isAdmin) {
      actions.addAll([
        'View Reports',
        'Moderate',
        if (status != null) 'Clear Status',
      ]);
    }

    return actions;
  }

  /// Check if a message should show a content warning
  static bool shouldShowContentWarning(Message message) {
    return MessageReportConfig.shouldShowContentWarning(
        message.reportCount ?? 0);
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
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
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
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
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
    return MessageReportConfig.getSeverityLevel(message.reportCount ?? 0);
  }

  /// Get moderation priority (higher = more urgent)
  static int getModerationPriority(Message message) {
    return MessageReportConfig.getModerationPriority(message.reportCount ?? 0);
  }
}
