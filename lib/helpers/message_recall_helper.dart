import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../models/topic_message.dart';
import '../services/message_meta_cache.dart';

// Constants for validation and limits
const int _maxMessageIdLength = 100;

/// Helper extensions for checking message recall status
///
/// These extensions provide convenient methods to check if messages are recalled,
/// with automatic fallback to the original recalled field for backward compatibility.

extension ChatMessageRecallHelper on ChatMessage {
  /// Check if this chat message is recalled using MessageMetaCache with fallback
  ///
  /// This method first checks the MessageMetaCache for real-time recall status,
  /// and falls back to the message's original recalled field if cache is unavailable.
  bool isRecalledWithCache(MessageMetaCache? messageMetaCache) {
    try {
      if (messageMetaCache == null) {
        // No cache available, use original field
        if (kDebugMode) {
          debugPrint('ChatMessage: No messageMetaCache available, using original recalled field: $recalled');
        }
        return recalled;
      }

      final messageId = id ?? '';
      if (!MessageRecallHelper.isValidMessageId(messageId)) {
        // Invalid message ID, use original field
        if (kDebugMode) {
          debugPrint('ChatMessage: Invalid messageId "$messageId", using original recalled field: $recalled');
        }
        return recalled;
      }

      // Use cache with fallback to original field
      return messageMetaCache.isMessageRecalledWithFallback(messageId, recalled);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ChatMessage: Error checking recall status for message ${id ?? 'null'}: $e');
      }
      // On error, fall back to original field
      return recalled;
    }
  }

  /// Check if this chat message can be recalled by the current user
  ///
  /// A message can be recalled if:
  /// - It has not been recalled yet
  /// - It has a valid message ID
  /// - The user has appropriate permissions (checked elsewhere)
  bool canBeRecalled(MessageMetaCache? messageMetaCache) {
    try {
      // Check if message has valid ID first
      if (!MessageRecallHelper.isValidMessageId(id)) {
        return false;
      }

      // Check if message is already recalled
      if (isRecalledWithCache(messageMetaCache)) {
        return false;
      }

      // Additional validations can be added here
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ChatMessage: Error checking if message can be recalled for ${id ?? 'null'}: $e');
      }
      return false;
    }
  }

  /// Get user-friendly recall status text for this chat message
  String getRecallStatusText(MessageMetaCache? messageMetaCache) {
    try {
      if (isRecalledWithCache(messageMetaCache)) {
        return MessageRecallHelper.getRecallDisplayText(type);
      }
      return content;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ChatMessage: Error getting recall status text for ${id ?? 'null'}: $e');
      }
      // Fall back to original content on error
      return content;
    }
  }

  /// Get detailed recall information for debugging
  Map<String, dynamic> getRecallDebugInfo(MessageMetaCache? messageMetaCache) {
    return MessageRecallHelper.getRecallDebugInfo(this, messageMetaCache);
  }
}

extension TopicMessageRecallHelper on TopicMessage {
  /// Check if this topic message is recalled using MessageMetaCache with fallback
  ///
  /// This method first checks the MessageMetaCache for real-time recall status,
  /// and falls back to the message's original recalled field if cache is unavailable.
  bool isRecalledWithCache(MessageMetaCache? messageMetaCache) {
    try {
      final recalledValue = recalled ?? false;

      if (messageMetaCache == null) {
        // No cache available, use original field
        if (kDebugMode) {
          debugPrint('TopicMessage: No messageMetaCache available, using original recalled field: $recalledValue');
        }
        return recalledValue;
      }

      final messageId = id ?? '';
      if (!MessageRecallHelper.isValidMessageId(messageId)) {
        // Invalid message ID, use original field
        if (kDebugMode) {
          debugPrint('TopicMessage: Invalid messageId "$messageId", using original recalled field: $recalledValue');
        }
        return recalledValue;
      }

      // Use cache with fallback to original field
      return messageMetaCache.isMessageRecalledWithFallback(messageId, recalledValue);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('TopicMessage: Error checking recall status for message ${id ?? 'null'}: $e');
      }
      // On error, fall back to original field
      return recalled ?? false;
    }
  }

  /// Check if this topic message can be recalled by the current user
  ///
  /// A message can be recalled if:
  /// - It has not been recalled yet
  /// - It has a valid message ID
  /// - The user has appropriate permissions (checked elsewhere)
  bool canBeRecalled(MessageMetaCache? messageMetaCache) {
    try {
      // Check if message has valid ID first
      if (!MessageRecallHelper.isValidMessageId(id)) {
        return false;
      }

      // Check if message is already recalled
      if (isRecalledWithCache(messageMetaCache)) {
        return false;
      }

      // Additional validations can be added here
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('TopicMessage: Error checking if message can be recalled for ${id ?? 'null'}: $e');
      }
      return false;
    }
  }

  /// Get user-friendly recall status text for this topic message
  String getRecallStatusText(MessageMetaCache? messageMetaCache) {
    try {
      if (isRecalledWithCache(messageMetaCache)) {
        final messageType = this is TopicImageMessage ? 'image' : 'text';
        return MessageRecallHelper.getRecallDisplayText(messageType);
      }
      return content;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('TopicMessage: Error getting recall status text for ${id ?? 'null'}: $e');
      }
      // Fall back to original content on error
      return content;
    }
  }

  /// Get detailed recall information for debugging
  Map<String, dynamic> getRecallDebugInfo(MessageMetaCache? messageMetaCache) {
    return MessageRecallHelper.getRecallDebugInfo(this, messageMetaCache);
  }
}

/// Static utility class for message recall operations
class MessageRecallHelper {
  MessageRecallHelper._(); // Private constructor

  /// Check if any message is recalled using a unified approach
  ///
  /// This method works with both ChatMessage and TopicMessage objects
  /// and provides a consistent API for recall status checking.
  static bool isMessageRecalled(
    dynamic message,
    MessageMetaCache? messageMetaCache,
  ) {
    try {
      if (message == null) {
        if (kDebugMode) {
          debugPrint('MessageRecallHelper: Null message provided to isMessageRecalled');
        }
        return false;
      }

      if (message is ChatMessage) {
        return message.isRecalledWithCache(messageMetaCache);
      } else if (message is TopicMessage) {
        return message.isRecalledWithCache(messageMetaCache);
      } else {
        if (kDebugMode) {
          debugPrint(
              'MessageRecallHelper: Unknown message type: ${message.runtimeType}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('MessageRecallHelper: Error checking if message is recalled: $e');
      }
      return false;
    }
  }

  /// Check if any message can be recalled using a unified approach
  static bool canMessageBeRecalled(
    dynamic message,
    MessageMetaCache? messageMetaCache,
  ) {
    try {
      if (message == null) {
        if (kDebugMode) {
          debugPrint('MessageRecallHelper: Null message provided to canMessageBeRecalled');
        }
        return false;
      }

      if (message is ChatMessage) {
        return message.canBeRecalled(messageMetaCache);
      } else if (message is TopicMessage) {
        return message.canBeRecalled(messageMetaCache);
      } else {
        if (kDebugMode) {
          debugPrint(
              'MessageRecallHelper: Unknown message type: ${message.runtimeType}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('MessageRecallHelper: Error checking if message can be recalled: $e');
      }
      return false;
    }
  }

  /// Get recall status text for any message using a unified approach
  static String getMessageRecallStatusText(
    dynamic message,
    MessageMetaCache? messageMetaCache,
  ) {
    try {
      if (message == null) {
        if (kDebugMode) {
          debugPrint('MessageRecallHelper: Null message provided to getMessageRecallStatusText');
        }
        return '';
      }

      if (message is ChatMessage) {
        return message.getRecallStatusText(messageMetaCache);
      } else if (message is TopicMessage) {
        return message.getRecallStatusText(messageMetaCache);
      } else {
        if (kDebugMode) {
          debugPrint(
              'MessageRecallHelper: Unknown message type: ${message.runtimeType}');
        }
        return message?.content ?? '';
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('MessageRecallHelper: Error getting message recall status text: $e');
      }
      return message?.content ?? '';
    }
  }

  /// Validate if a message ID is suitable for recall operations
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
          debugPrint('MessageRecallHelper: Message ID too long: ${trimmedId.length} characters');
        }
        return false;
      }

      // Check for basic format (alphanumeric and basic punctuation)
      final validFormat = RegExp(r'^[a-zA-Z0-9_\-]+$').hasMatch(trimmedId);
      if (!validFormat) {
        if (kDebugMode) {
          debugPrint('MessageRecallHelper: Invalid message ID format: "$trimmedId"');
        }
        return false;
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('MessageRecallHelper: Error validating message ID "$messageId": $e');
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
              'MessageRecallHelper: Unknown message type: ${message.runtimeType}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('MessageRecallHelper: Error getting message ID: $e');
      }
      return null;
    }
  }

  /// Check if recall functionality is available for a message
  ///
  /// This checks both the message validity and the cache availability
  static bool isRecallFunctionalityAvailable(
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
        debugPrint('MessageRecallHelper: Error checking recall functionality availability: $e');
      }
      return false;
    }
  }

  /// Get debug information about recall status
  static Map<String, dynamic> getRecallDebugInfo(
    dynamic message,
    MessageMetaCache? messageMetaCache,
  ) {
    try {
      final messageId = getMessageId(message);
      final isRecalled = isMessageRecalled(message, messageMetaCache);
      final canBeRecalled = canMessageBeRecalled(message, messageMetaCache);
      final originalRecalled = _getOriginalRecalledField(message);

      return {
        'messageId': messageId,
        'hasValidId': isValidMessageId(messageId),
        'hasCacheAvailable': messageMetaCache != null,
        'isRecalled': isRecalled,
        'canBeRecalled': canBeRecalled,
        'messageType': message?.runtimeType.toString() ?? 'null',
        'originalRecalledField': originalRecalled,
        'cacheValue': messageId != null && messageMetaCache != null
            ? messageMetaCache.isMessageRecalled(messageId)
            : null,
        'recallFunctionalityAvailable': isRecallFunctionalityAvailable(message, messageMetaCache),
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

  /// Helper to get the original recalled field value
  static bool? _getOriginalRecalledField(dynamic message) {
    try {
      if (message is ChatMessage) {
        return message.recalled;
      } else if (message is TopicMessage) {
        return message.recalled;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('MessageRecallHelper: Error getting original recalled field: $e');
      }
      return null;
    }
  }

  /// Get standardized recall display text based on message type
  static String getRecallDisplayText(String messageType) {
    switch (messageType.toLowerCase()) {
      case 'image':
        return '- Image recalled -';
      case 'text':
      default:
        return '- Message recalled -';
    }
  }

  /// Batch check recall status for multiple messages
  static Map<String, bool> batchCheckRecallStatus(
    List<dynamic> messages,
    MessageMetaCache? messageMetaCache,
  ) {
    final results = <String, bool>{};

    try {
      for (final message in messages) {
        final messageId = getMessageId(message);
        if (messageId != null) {
          results[messageId] = isMessageRecalled(message, messageMetaCache);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('MessageRecallHelper: Error in batch check recall status: $e');
      }
    }

    return results;
  }

  /// Get recall statistics for debugging and monitoring
  static Map<String, dynamic> getRecallStatistics(
    List<dynamic> messages,
    MessageMetaCache? messageMetaCache,
  ) {
    try {
      int totalMessages = messages.length;
      int recalledMessages = 0;
      int validMessages = 0;
      int invalidIds = 0;

      for (final message in messages) {
        final messageId = getMessageId(message);
        if (isValidMessageId(messageId)) {
          validMessages++;
          if (isMessageRecalled(message, messageMetaCache)) {
            recalledMessages++;
          }
        } else {
          invalidIds++;
        }
      }

      return {
        'totalMessages': totalMessages,
        'validMessages': validMessages,
        'recalledMessages': recalledMessages,
        'invalidIds': invalidIds,
        'recallRate': validMessages > 0 ? (recalledMessages / validMessages) : 0.0,
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
