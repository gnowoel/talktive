import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../models/topic_message.dart';
import '../services/message_meta_cache.dart';
import '../config/message_report_config.dart';

/// Enum for different message display states
enum MessageDisplayStatus {
  normal,
  flagged,
  reportedRevealable,
  hidden,
  severe,
  blocked,
}

// Constants for validation and limits
const int _maxMessageIdLength = 100;

/// Helper extensions for checking message report status
///
/// These extensions provide convenient methods to check if messages are reported,
/// with automatic fallback to the original reportCount field for backward compatibility.

extension ChatMessageReportHelper on ChatMessage {
  /// Get report count using MessageMetaCache with fallback
  ///
  /// This method first checks the MessageMetaCache for real-time report count,
  /// and falls back to the message's original reportCount field if cache is unavailable.
  int getReportCountWithCache(MessageMetaCache? messageMetaCache) {
    try {
      if (messageMetaCache == null) {
        // No cache available, use original field
        if (kDebugMode) {
          debugPrint(
              'ChatMessage: No messageMetaCache available, using original reportCount field: ${reportCount ?? 0}');
        }
        return reportCount ?? 0;
      }

      final messageId = id ?? '';
      if (!MessageReportHelper.isValidMessageId(messageId)) {
        // Invalid message ID, use original field
        if (kDebugMode) {
          debugPrint(
              'ChatMessage: Invalid messageId "$messageId", using original reportCount field: ${reportCount ?? 0}');
        }
        return reportCount ?? 0;
      }

      // Use cache with fallback to original field
      return messageMetaCache.getMessageReportCountWithFallback(
          messageId, reportCount ?? 0);
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            'ChatMessage: Error checking report count for message ${id ?? 'null'}: $e');
      }
      // On error, fall back to original field
      return reportCount ?? 0;
    }
  }

  /// Check if this chat message is flagged for review
  bool isFlaggedWithCache(MessageMetaCache? messageMetaCache) {
    try {
      final currentReportCount = getReportCountWithCache(messageMetaCache);
      return currentReportCount >= MessageReportConfig.flagThreshold &&
          currentReportCount < MessageReportConfig.hideThreshold;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            'ChatMessage: Error checking if message is flagged for ${id ?? 'null'}: $e');
      }
      return false;
    }
  }

  /// Check if this chat message is hidden due to reports
  bool isHiddenWithCache(MessageMetaCache? messageMetaCache) {
    try {
      final currentReportCount = getReportCountWithCache(messageMetaCache);
      return currentReportCount >= MessageReportConfig.hideThreshold &&
          currentReportCount < MessageReportConfig.severeThreshold;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            'ChatMessage: Error checking if message is hidden for ${id ?? 'null'}: $e');
      }
      return false;
    }
  }

  /// Check if this chat message is marked as severe
  bool isSevereWithCache(MessageMetaCache? messageMetaCache) {
    try {
      final currentReportCount = getReportCountWithCache(messageMetaCache);
      return currentReportCount >= MessageReportConfig.severeThreshold;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            'ChatMessage: Error checking if message is severe for ${id ?? 'null'}: $e');
      }
      return false;
    }
  }

  /// Check if this chat message has any report-related restrictions
  bool isReportedWithCache(MessageMetaCache? messageMetaCache) {
    try {
      final currentReportCount = getReportCountWithCache(messageMetaCache);
      return currentReportCount > 0;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            'ChatMessage: Error checking if message is reported for ${id ?? 'null'}: $e');
      }
      return false;
    }
  }

  /// Get the current report status using cache
  String? getReportStatusWithCache(MessageMetaCache? messageMetaCache) {
    try {
      final currentReportCount = getReportCountWithCache(messageMetaCache);
      return MessageReportConfig.getReportStatus(currentReportCount);
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            'ChatMessage: Error getting report status for ${id ?? 'null'}: $e');
      }
      return null;
    }
  }

  /// Get a user-friendly description of the message's report status using cache
  String getReportStatusDescriptionWithCache(
      MessageMetaCache? messageMetaCache) {
    try {
      final currentReportCount = getReportCountWithCache(messageMetaCache);
      return MessageReportConfig.getStatusDescription(currentReportCount);
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            'ChatMessage: Error getting report status description for ${id ?? 'null'}: $e');
      }
      return 'No reports';
    }
  }

  /// Check if message should be visible using cache data
  bool shouldShowWithCache(MessageMetaCache? messageMetaCache,
      {bool isAdmin = false}) {
    try {
      final currentReportCount = getReportCountWithCache(messageMetaCache);
      return MessageReportConfig.shouldShowMessage(currentReportCount,
          isAdmin: isAdmin);
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            'ChatMessage: Error checking if message should show for ${id ?? 'null'}: $e');
      }
      return true; // Default to showing on error
    }
  }

  /// Check if message needs content warning using cache data
  bool shouldShowContentWarningWithCache(MessageMetaCache? messageMetaCache) {
    try {
      final currentReportCount = getReportCountWithCache(messageMetaCache);
      return MessageReportConfig.shouldShowContentWarning(currentReportCount);
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            'ChatMessage: Error checking content warning for ${id ?? 'null'}: $e');
      }
      return false;
    }
  }

  /// Check if message is reported but still revealable using cache data
  bool isReportedButRevealableWithCache(MessageMetaCache? messageMetaCache) {
    try {
      final currentReportCount = getReportCountWithCache(messageMetaCache);
      return currentReportCount > 0 &&
          currentReportCount < MessageReportConfig.hideThreshold;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            'ChatMessage: Error checking if message is reported but revealable for ${id ?? 'null'}: $e');
      }
      return false;
    }
  }

  /// Get detailed report information for debugging
  Map<String, dynamic> getReportDebugInfo(MessageMetaCache? messageMetaCache) {
    return MessageReportHelper.getReportDebugInfo(this, messageMetaCache);
  }
}

extension TopicMessageReportHelper on TopicMessage {
  /// Get report count using MessageMetaCache with fallback
  ///
  /// This method first checks the MessageMetaCache for real-time report count,
  /// and falls back to the message's original reportCount field if cache is unavailable.
  int getReportCountWithCache(MessageMetaCache? messageMetaCache) {
    try {
      final originalCount = reportCount ?? 0;

      if (messageMetaCache == null) {
        // No cache available, use original field
        if (kDebugMode) {
          debugPrint(
              'TopicMessage: No messageMetaCache available, using original reportCount field: $originalCount');
        }
        return originalCount;
      }

      final messageId = id ?? '';
      if (!MessageReportHelper.isValidMessageId(messageId)) {
        // Invalid message ID, use original field
        if (kDebugMode) {
          debugPrint(
              'TopicMessage: Invalid messageId "$messageId", using original reportCount field: $originalCount');
        }
        return originalCount;
      }

      // Use cache with fallback to original field
      return messageMetaCache.getMessageReportCountWithFallback(
          messageId, originalCount);
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            'TopicMessage: Error checking report count for message ${id ?? 'null'}: $e');
      }
      // On error, fall back to original field
      return reportCount ?? 0;
    }
  }

  /// Check if this topic message is flagged for review
  bool isFlaggedWithCache(MessageMetaCache? messageMetaCache) {
    try {
      final currentReportCount = getReportCountWithCache(messageMetaCache);
      return currentReportCount >= MessageReportConfig.flagThreshold &&
          currentReportCount < MessageReportConfig.hideThreshold;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            'TopicMessage: Error checking if message is flagged for ${id ?? 'null'}: $e');
      }
      return false;
    }
  }

  /// Check if this topic message is hidden due to reports
  bool isHiddenWithCache(MessageMetaCache? messageMetaCache) {
    try {
      final currentReportCount = getReportCountWithCache(messageMetaCache);
      return currentReportCount >= MessageReportConfig.hideThreshold &&
          currentReportCount < MessageReportConfig.severeThreshold;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            'TopicMessage: Error checking if message is hidden for ${id ?? 'null'}: $e');
      }
      return false;
    }
  }

  /// Check if this topic message is marked as severe
  bool isSevereWithCache(MessageMetaCache? messageMetaCache) {
    try {
      final currentReportCount = getReportCountWithCache(messageMetaCache);
      return currentReportCount >= MessageReportConfig.severeThreshold;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            'TopicMessage: Error checking if message is severe for ${id ?? 'null'}: $e');
      }
      return false;
    }
  }

  /// Check if this topic message has any report-related restrictions
  bool isReportedWithCache(MessageMetaCache? messageMetaCache) {
    try {
      final currentReportCount = getReportCountWithCache(messageMetaCache);
      return currentReportCount > 0;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            'TopicMessage: Error checking if message is reported for ${id ?? 'null'}: $e');
      }
      return false;
    }
  }

  /// Get the current report status using cache
  String? getReportStatusWithCache(MessageMetaCache? messageMetaCache) {
    try {
      final currentReportCount = getReportCountWithCache(messageMetaCache);
      return MessageReportConfig.getReportStatus(currentReportCount);
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            'TopicMessage: Error getting report status for ${id ?? 'null'}: $e');
      }
      return null;
    }
  }

  /// Get a user-friendly description of the message's report status using cache
  String getReportStatusDescriptionWithCache(
      MessageMetaCache? messageMetaCache) {
    try {
      final currentReportCount = getReportCountWithCache(messageMetaCache);
      return MessageReportConfig.getStatusDescription(currentReportCount);
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            'TopicMessage: Error getting report status description for ${id ?? 'null'}: $e');
      }
      return 'No reports';
    }
  }

  /// Check if message should be visible using cache data
  bool shouldShowWithCache(MessageMetaCache? messageMetaCache,
      {bool isAdmin = false}) {
    try {
      final currentReportCount = getReportCountWithCache(messageMetaCache);
      return MessageReportConfig.shouldShowMessage(currentReportCount,
          isAdmin: isAdmin);
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            'TopicMessage: Error checking if message should show for ${id ?? 'null'}: $e');
      }
      return true; // Default to showing on error
    }
  }

  /// Check if message needs content warning using cache data
  bool shouldShowContentWarningWithCache(MessageMetaCache? messageMetaCache) {
    try {
      final currentReportCount = getReportCountWithCache(messageMetaCache);
      return MessageReportConfig.shouldShowContentWarning(currentReportCount);
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            'TopicMessage: Error checking content warning for ${id ?? 'null'}: $e');
      }
      return false;
    }
  }

  /// Check if message is reported but still revealable using cache data
  bool isReportedButRevealableWithCache(MessageMetaCache? messageMetaCache) {
    try {
      final currentReportCount = getReportCountWithCache(messageMetaCache);
      return currentReportCount > 0 &&
          currentReportCount < MessageReportConfig.hideThreshold;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            'TopicMessage: Error checking if message is reported but revealable for ${id ?? 'null'}: $e');
      }
      return false;
    }
  }

  /// Get detailed report information for debugging
  Map<String, dynamic> getReportDebugInfo(MessageMetaCache? messageMetaCache) {
    return MessageReportHelper.getReportDebugInfo(this, messageMetaCache);
  }
}

/// Static utility class for message report operations
class MessageReportHelper {
  MessageReportHelper._(); // Private constructor

  /// Get report count for any message using a unified approach
  ///
  /// This method works with both ChatMessage and TopicMessage objects
  /// and provides a consistent API for report count checking.
  static int getMessageReportCount(
    dynamic message,
    MessageMetaCache? messageMetaCache,
  ) {
    try {
      if (message == null) {
        if (kDebugMode) {
          debugPrint(
              'MessageReportHelper: Null message provided to getMessageReportCount');
        }
        return 0;
      }

      if (message is ChatMessage) {
        return message.getReportCountWithCache(messageMetaCache);
      } else if (message is TopicMessage) {
        return message.getReportCountWithCache(messageMetaCache);
      } else {
        if (kDebugMode) {
          debugPrint(
              'MessageReportHelper: Unknown message type: ${message.runtimeType}');
        }
        return 0;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            'MessageReportHelper: Error getting message report count: $e');
      }
      return 0;
    }
  }

  /// Check if any message is flagged using a unified approach
  static bool isMessageFlagged(
    dynamic message,
    MessageMetaCache? messageMetaCache,
  ) {
    try {
      if (message == null) {
        if (kDebugMode) {
          debugPrint(
              'MessageReportHelper: Null message provided to isMessageFlagged');
        }
        return false;
      }

      if (message is ChatMessage) {
        return message.isFlaggedWithCache(messageMetaCache);
      } else if (message is TopicMessage) {
        return message.isFlaggedWithCache(messageMetaCache);
      } else {
        if (kDebugMode) {
          debugPrint(
              'MessageReportHelper: Unknown message type: ${message.runtimeType}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            'MessageReportHelper: Error checking if message is flagged: $e');
      }
      return false;
    }
  }

  /// Check if any message is hidden using a unified approach
  static bool isMessageHidden(
    dynamic message,
    MessageMetaCache? messageMetaCache,
  ) {
    try {
      if (message == null) {
        if (kDebugMode) {
          debugPrint(
              'MessageReportHelper: Null message provided to isMessageHidden');
        }
        return false;
      }

      if (message is ChatMessage) {
        return message.isHiddenWithCache(messageMetaCache);
      } else if (message is TopicMessage) {
        return message.isHiddenWithCache(messageMetaCache);
      } else {
        if (kDebugMode) {
          debugPrint(
              'MessageReportHelper: Unknown message type: ${message.runtimeType}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            'MessageReportHelper: Error checking if message is hidden: $e');
      }
      return false;
    }
  }

  /// Check if any message is severe using a unified approach
  static bool isMessageSevere(
    dynamic message,
    MessageMetaCache? messageMetaCache,
  ) {
    try {
      if (message == null) {
        if (kDebugMode) {
          debugPrint(
              'MessageReportHelper: Null message provided to isMessageSevere');
        }
        return false;
      }

      if (message is ChatMessage) {
        return message.isSevereWithCache(messageMetaCache);
      } else if (message is TopicMessage) {
        return message.isSevereWithCache(messageMetaCache);
      } else {
        if (kDebugMode) {
          debugPrint(
              'MessageReportHelper: Unknown message type: ${message.runtimeType}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            'MessageReportHelper: Error checking if message is severe: $e');
      }
      return false;
    }
  }

  /// Check if any message is reported using a unified approach
  static bool isMessageReported(
    dynamic message,
    MessageMetaCache? messageMetaCache,
  ) {
    try {
      if (message == null) {
        if (kDebugMode) {
          debugPrint(
              'MessageReportHelper: Null message provided to isMessageReported');
        }
        return false;
      }

      if (message is ChatMessage) {
        return message.isReportedWithCache(messageMetaCache);
      } else if (message is TopicMessage) {
        return message.isReportedWithCache(messageMetaCache);
      } else {
        if (kDebugMode) {
          debugPrint(
              'MessageReportHelper: Unknown message type: ${message.runtimeType}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            'MessageReportHelper: Error checking if message is reported: $e');
      }
      return false;
    }
  }

  /// Check if any message is reported but still revealable using a unified approach
  static bool isMessageReportedButRevealable(
    dynamic message,
    MessageMetaCache? messageMetaCache,
  ) {
    try {
      if (message == null) {
        if (kDebugMode) {
          debugPrint(
              'MessageReportHelper: Null message provided to isMessageReportedButRevealable');
        }
        return false;
      }

      if (message is ChatMessage) {
        return message.isReportedButRevealableWithCache(messageMetaCache);
      } else if (message is TopicMessage) {
        return message.isReportedButRevealableWithCache(messageMetaCache);
      } else {
        if (kDebugMode) {
          debugPrint(
              'MessageReportHelper: Unknown message type: ${message.runtimeType}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            'MessageReportHelper: Error checking if message is reported but revealable: $e');
      }
      return false;
    }
  }

  /// Get report status for any message using a unified approach
  static String? getMessageReportStatus(
    dynamic message,
    MessageMetaCache? messageMetaCache,
  ) {
    try {
      if (message == null) {
        if (kDebugMode) {
          debugPrint(
              'MessageReportHelper: Null message provided to getMessageReportStatus');
        }
        return null;
      }

      if (message is ChatMessage) {
        return message.getReportStatusWithCache(messageMetaCache);
      } else if (message is TopicMessage) {
        return message.getReportStatusWithCache(messageMetaCache);
      } else {
        if (kDebugMode) {
          debugPrint(
              'MessageReportHelper: Unknown message type: ${message.runtimeType}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            'MessageReportHelper: Error getting message report status: $e');
      }
      return null;
    }
  }

  /// Get report status description for any message using a unified approach
  static String getMessageReportStatusDescription(
    dynamic message,
    MessageMetaCache? messageMetaCache,
  ) {
    try {
      if (message == null) {
        if (kDebugMode) {
          debugPrint(
              'MessageReportHelper: Null message provided to getMessageReportStatusDescription');
        }
        return 'No reports';
      }

      if (message is ChatMessage) {
        return message.getReportStatusDescriptionWithCache(messageMetaCache);
      } else if (message is TopicMessage) {
        return message.getReportStatusDescriptionWithCache(messageMetaCache);
      } else {
        if (kDebugMode) {
          debugPrint(
              'MessageReportHelper: Unknown message type: ${message.runtimeType}');
        }
        return 'No reports';
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            'MessageReportHelper: Error getting message report status description: $e');
      }
      return 'No reports';
    }
  }

  /// Validate if a message ID is suitable for report operations
  static bool isValidMessageId(String? messageId) {
    try {
      if (messageId == null || messageId.isEmpty) {
        return false;
      }

      final trimmedId = messageId.trim();
      if (trimmedId.isEmpty) {
        return false;
      }

      // Check for reasonable length limits
      if (trimmedId.length > _maxMessageIdLength) {
        if (kDebugMode) {
          debugPrint(
              'MessageReportHelper: Message ID too long: ${trimmedId.length} characters');
        }
        return false;
      }

      // Check for basic format (alphanumeric and basic punctuation)
      final validFormat = RegExp(r'^[a-zA-Z0-9_\-]+$').hasMatch(trimmedId);
      if (!validFormat) {
        if (kDebugMode) {
          debugPrint(
              'MessageReportHelper: Invalid message ID format: "$trimmedId"');
        }
        return false;
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            'MessageReportHelper: Error validating message ID "$messageId": $e');
      }
      return false;
    }
  }

  /// Get message ID from any message object
  static String? getMessageId(dynamic message) {
    try {
      if (message == null) return null;

      if (message is ChatMessage) {
        return message.id;
      } else if (message is TopicMessage) {
        return message.id;
      } else {
        if (kDebugMode) {
          debugPrint(
              'MessageReportHelper: Unknown message type: ${message.runtimeType}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('MessageReportHelper: Error getting message ID: $e');
      }
      return null;
    }
  }

  /// Check if report functionality is available for a message
  ///
  /// This checks both the message validity and the cache availability
  static bool isReportFunctionalityAvailable(
    dynamic message,
    MessageMetaCache? messageMetaCache,
  ) {
    try {
      if (message == null || messageMetaCache == null) {
        return false;
      }

      final messageId = getMessageId(message);
      if (!isValidMessageId(messageId)) {
        return false;
      }

      // Additional checks can be added here (e.g., user permissions, time limits)
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            'MessageReportHelper: Error checking report functionality availability: $e');
      }
      return false;
    }
  }

  /// Get debug information about report status
  static Map<String, dynamic> getReportDebugInfo(
    dynamic message,
    MessageMetaCache? messageMetaCache,
  ) {
    try {
      final messageId = getMessageId(message);
      final reportCount = getMessageReportCount(message, messageMetaCache);
      final isReported = isMessageReported(message, messageMetaCache);
      final isFlagged = isMessageFlagged(message, messageMetaCache);
      final isHidden = isMessageHidden(message, messageMetaCache);
      final isSevere = isMessageSevere(message, messageMetaCache);
      final reportStatus = getMessageReportStatus(message, messageMetaCache);
      final originalReportCount = _getOriginalReportCountField(message);

      return {
        'messageId': messageId,
        'hasValidId': isValidMessageId(messageId),
        'hasCacheAvailable': messageMetaCache != null,
        'reportCount': reportCount,
        'isReported': isReported,
        'isFlagged': isFlagged,
        'isHidden': isHidden,
        'isSevere': isSevere,
        'reportStatus': reportStatus,
        'messageType': message?.runtimeType.toString() ?? 'null',
        'originalReportCountField': originalReportCount,
        'cacheValue': messageId != null && messageMetaCache != null
            ? messageMetaCache.getMessageReportCount(messageId)
            : null,
        'reportFunctionalityAvailable':
            isReportFunctionalityAvailable(message, messageMetaCache),
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'messageType': message?.runtimeType.toString() ?? 'null',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Helper to get the original reportCount field value
  static int? _getOriginalReportCountField(dynamic message) {
    try {
      if (message is ChatMessage) {
        return message.reportCount;
      } else if (message is TopicMessage) {
        return message.reportCount;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            'MessageReportHelper: Error getting original reportCount field: $e');
      }
      return null;
    }
  }

  /// Batch check report status for multiple messages
  static Map<String, int> batchCheckReportCount(
    List<dynamic> messages,
    MessageMetaCache? messageMetaCache,
  ) {
    final results = <String, int>{};

    try {
      for (final message in messages) {
        final messageId = getMessageId(message);
        if (messageId != null) {
          results[messageId] = getMessageReportCount(message, messageMetaCache);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            'MessageReportHelper: Error in batch check report count: $e');
      }
    }

    return results;
  }

  /// Get report statistics for debugging and monitoring
  static Map<String, dynamic> getReportStatistics(
    List<dynamic> messages,
    MessageMetaCache? messageMetaCache,
  ) {
    try {
      int totalMessages = messages.length;
      int reportedMessages = 0;
      int flaggedMessages = 0;
      int hiddenMessages = 0;
      int severeMessages = 0;
      int validMessages = 0;
      int invalidIds = 0;
      int totalReports = 0;

      for (final message in messages) {
        final messageId = getMessageId(message);
        if (isValidMessageId(messageId)) {
          validMessages++;
          final reportCount = getMessageReportCount(message, messageMetaCache);
          totalReports += reportCount;

          if (reportCount > 0) reportedMessages++;
          if (isMessageFlagged(message, messageMetaCache)) flaggedMessages++;
          if (isMessageHidden(message, messageMetaCache)) hiddenMessages++;
          if (isMessageSevere(message, messageMetaCache)) severeMessages++;
        } else {
          invalidIds++;
        }
      }

      return {
        'totalMessages': totalMessages,
        'validMessages': validMessages,
        'reportedMessages': reportedMessages,
        'flaggedMessages': flaggedMessages,
        'hiddenMessages': hiddenMessages,
        'severeMessages': severeMessages,
        'totalReports': totalReports,
        'averageReportsPerMessage':
            validMessages > 0 ? (totalReports / validMessages) : 0.0,
        'reportRate':
            validMessages > 0 ? (reportedMessages / validMessages) : 0.0,
        'flagRate': validMessages > 0 ? (flaggedMessages / validMessages) : 0.0,
        'hideRate': validMessages > 0 ? (hiddenMessages / validMessages) : 0.0,
        'severeRate':
            validMessages > 0 ? (severeMessages / validMessages) : 0.0,
        'invalidIds': invalidIds,
        'cacheAvailable': messageMetaCache != null,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}
