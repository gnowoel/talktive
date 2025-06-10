import 'package:flutter/material.dart';
import '../models/topic_message.dart';
import '../config/message_report_config.dart';
import '../services/report_cache.dart';

/// Helper class for handling topic message status UI logic
class TopicMessageStatusHelper {
  TopicMessageStatusHelper._();

  /// Check if a topic message is hidden but can be revealed
  static bool isHiddenButRevealable(TopicMessage message) {
    final status =
        MessageReportConfig.getReportStatus(message.reportCount ?? 0);
    return status == 'hidden';
  }

  /// Check if a topic message is removed (severe)
  static bool isRemoved(TopicMessage message) {
    final status =
        MessageReportConfig.getReportStatus(message.reportCount ?? 0);
    return status == 'severe';
  }

  /// Check if a topic message should be visible to regular users
  static bool shouldShowMessage(TopicMessage message, {bool isAdmin = false}) {
    return MessageReportConfig.shouldShowMessage(
      message.reportCount ?? 0,
      isAdmin: isAdmin,
    );
  }

  /// Get replacement content for hidden topic messages
  static String getHiddenMessageContent(TopicMessage message) {
    final title = message is TopicImageMessage ? 'Image' : 'Message';
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
  static String getCopyContent(TopicMessage message, String originalContent) {
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

  /// Get the background color for topic messages based on status
  static Color? getMessageBackgroundColor(TopicMessage message, ThemeData theme) {
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

  /// Get border color for topic messages based on status
  static Color? getMessageBorderColor(TopicMessage message, ThemeData theme) {
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

  /// Check if topic message content should be blurred or obscured
  static bool shouldBlurContent(TopicMessage message) {
    return MessageReportConfig.shouldBlurContent(message.reportCount ?? 0);
  }

  /// Get tooltip text for status indicators
  static String getStatusTooltip(TopicMessage message) {
    return MessageReportConfig.getStatusTooltip(message.reportCount ?? 0);
  }

  /// Check if the report option should be available in context menu
  static bool shouldShowReportOption(TopicMessage message, bool isAuthor) {
    if (isAuthor) return false;
    final status =
        MessageReportConfig.getReportStatus(message.reportCount ?? 0);
    return status != 'severe'; // Hide report option for removed messages
  }

  /// Check if a topic message can be reported (not recently reported)
  static Future<bool> canReportMessage(String messageId) async {
    final reportCache = ReportCacheService();
    await reportCache.initialize();
    final isRecentlyReported = await reportCache.isRecentlyReported(messageId);
    return !isRecentlyReported;
  }

  /// Check if report option should be shown considering cache
  static Future<bool> shouldShowReportOptionWithCache(
    TopicMessage message,
    bool isAuthor,
  ) async {
    if (!shouldShowReportOption(message, isAuthor)) return false;
    if (message.id == null) return false;
    return await canReportMessage(message.id!);
  }

  /// Check if a topic message was recently reported and should show placeholder
  static Future<bool> isRecentlyReported(TopicMessage message) async {
    if (message.id == null) return false;
    final reportCache = ReportCacheService();
    await reportCache.initialize();
    return await reportCache.isRecentlyReported(message.id!);
  }

  /// Check if topic message should show reported placeholder but is revealable
  static Future<bool> isReportedButRevealable(TopicMessage message) async {
    // Only show reported placeholder for messages that aren't already hidden/removed
    if (isRemoved(message) || isHiddenButRevealable(message)) return false;
    return await isRecentlyReported(message);
  }

  /// Get placeholder content for recently reported topic messages
  static String getReportedMessageContent(TopicMessage message) {
    final title = message is TopicImageMessage ? 'Image' : 'Message';
    return '- $title reported -';
  }

  /// Get content for copying reported topic messages (always return original for text)
  static String getReportedCopyContent(TopicMessage message, String originalContent) {
    // For text messages, always allow copying original content
    if (message is TopicTextMessage) {
      return originalContent;
    }
    // For other types, show reported placeholder
    return getReportedMessageContent(message);
  }

  /// Get appropriate context menu options based on topic message status
  static List<String> getAvailableActions(
    TopicMessage message, {
    required bool isAuthor,
    required bool isAdmin,
  }) {
    final actions = <String>[];

    // Standard actions - only show copy for text messages
    if (!isAuthor && message is TopicTextMessage) {
      actions.add('Copy');
    }

    // Author actions
    if (isAuthor && !(message.recalled ?? false)) {
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

  /// Check if a topic message should show a content warning
  static bool shouldShowContentWarning(TopicMessage message) {
    return MessageReportConfig.shouldShowContentWarning(
        message.reportCount ?? 0);
  }

  /// Create a content warning widget for topic messages
  static Widget createContentWarning(
    TopicMessage message,
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
  static double getSeverityLevel(TopicMessage message) {
    return MessageReportConfig.getSeverityLevel(message.reportCount ?? 0);
  }

  /// Get moderation priority (higher = more urgent)
  static int getModerationPriority(TopicMessage message) {
    return MessageReportConfig.getModerationPriority(message.reportCount ?? 0);
  }
}