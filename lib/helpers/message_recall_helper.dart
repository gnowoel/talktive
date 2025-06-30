import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../models/topic_message.dart';
import '../services/message_meta_cache.dart';

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
    if (messageMetaCache == null) {
      // No cache available, use original field
      return recalled;
    }

    final messageId = id ?? '';
    if (messageId.isEmpty) {
      // No message ID, use original field
      return recalled;
    }

    // Use cache with fallback to original field
    return messageMetaCache.isMessageRecalledWithFallback(messageId, recalled);
  }

  /// Check if this chat message can be recalled by the current user
  ///
  /// A message can be recalled if:
  /// - It has not been recalled yet
  /// - It has a valid message ID
  /// - The user has appropriate permissions (checked elsewhere)
  bool canBeRecalled(MessageMetaCache? messageMetaCache) {
    return (id?.isNotEmpty ?? false) && !isRecalledWithCache(messageMetaCache);
  }

  /// Get user-friendly recall status text for this chat message
  String getRecallStatusText(MessageMetaCache? messageMetaCache) {
    if (isRecalledWithCache(messageMetaCache)) {
      return type == 'image' ? '- Image recalled -' : '- Message recalled -';
    }
    return content;
  }
}

extension TopicMessageRecallHelper on TopicMessage {
  /// Check if this topic message is recalled using MessageMetaCache with fallback
  ///
  /// This method first checks the MessageMetaCache for real-time recall status,
  /// and falls back to the message's original recalled field if cache is unavailable.
  bool isRecalledWithCache(MessageMetaCache? messageMetaCache) {
    if (messageMetaCache == null) {
      // No cache available, use original field
      return recalled ?? false;
    }

    final messageId = id ?? '';
    if (messageId.isEmpty) {
      // No message ID, use original field
      return recalled ?? false;
    }

    // Use cache with fallback to original field
    return messageMetaCache.isMessageRecalledWithFallback(
        messageId, recalled ?? false);
  }

  /// Check if this topic message can be recalled by the current user
  ///
  /// A message can be recalled if:
  /// - It has not been recalled yet
  /// - It has a valid message ID
  /// - The user has appropriate permissions (checked elsewhere)
  bool canBeRecalled(MessageMetaCache? messageMetaCache) {
    return (id?.isNotEmpty ?? false) && !isRecalledWithCache(messageMetaCache);
  }

  /// Get user-friendly recall status text for this topic message
  String getRecallStatusText(MessageMetaCache? messageMetaCache) {
    if (isRecalledWithCache(messageMetaCache)) {
      if (this is TopicImageMessage) {
        return '- Image recalled -';
      } else {
        return '- Message recalled -';
      }
    }
    return content;
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
    if (message == null) return false;

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
  }

  /// Check if any message can be recalled using a unified approach
  static bool canMessageBeRecalled(
    dynamic message,
    MessageMetaCache? messageMetaCache,
  ) {
    if (message == null) return false;

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
  }

  /// Get recall status text for any message using a unified approach
  static String getMessageRecallStatusText(
    dynamic message,
    MessageMetaCache? messageMetaCache,
  ) {
    if (message == null) return '';

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
  }

  /// Validate if a message ID is suitable for recall operations
  static bool isValidMessageId(String? messageId) {
    return messageId != null &&
        messageId.isNotEmpty &&
        messageId.trim().isNotEmpty;
  }

  /// Get message ID from any message object
  static String? getMessageId(dynamic message) {
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
  }

  /// Check if recall functionality is available for a message
  ///
  /// This checks both the message validity and the cache availability
  static bool isRecallFunctionalityAvailable(
    dynamic message,
    MessageMetaCache? messageMetaCache,
  ) {
    final messageId = getMessageId(message);
    return isValidMessageId(messageId) && messageMetaCache != null;
  }

  /// Get debug information about recall status
  static Map<String, dynamic> getRecallDebugInfo(
    dynamic message,
    MessageMetaCache? messageMetaCache,
  ) {
    final messageId = getMessageId(message);
    final isRecalled = isMessageRecalled(message, messageMetaCache);
    final canBeRecalled = canMessageBeRecalled(message, messageMetaCache);

    return {
      'messageId': messageId,
      'hasValidId': isValidMessageId(messageId),
      'hasCacheAvailable': messageMetaCache != null,
      'isRecalled': isRecalled,
      'canBeRecalled': canBeRecalled,
      'messageType': message.runtimeType.toString(),
      'originalRecalledField': _getOriginalRecalledField(message),
      'cacheValue': messageId != null && messageMetaCache != null
          ? messageMetaCache.isMessageRecalled(messageId)
          : null,
    };
  }

  /// Helper to get the original recalled field value
  static bool? _getOriginalRecalledField(dynamic message) {
    if (message is ChatMessage) {
      return message.recalled;
    } else if (message is TopicMessage) {
      return message.recalled;
    }
    return null;
  }
}
