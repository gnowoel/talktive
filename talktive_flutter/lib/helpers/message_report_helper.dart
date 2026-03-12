import 'package:flutter/foundation.dart';
import '../models/topic_message.dart';
import '../services/message_meta_cache.dart';
import '../config/message_report_config.dart';

// Constants for validation and limits
const int _maxMessageIdLength = 100;

/// Helper extensions for checking message report status
extension TopicMessageReportHelper on TopicMessage {
  int getReportCountWithCache(MessageMetaCache? messageMetaCache) {
    try {
      final originalCount = reportCount ?? 0;

      if (messageMetaCache == null) {
        if (kDebugMode) {
          debugPrint(
            'TopicMessage: No messageMetaCache available, using original reportCount field: $originalCount',
          );
        }
        return originalCount;
      }

      final messageId = id ?? '';
      if (!MessageReportHelper.isValidMessageId(messageId)) {
        if (kDebugMode) {
          debugPrint(
            'TopicMessage: Invalid messageId "$messageId", using original reportCount field: $originalCount',
          );
        }
        return originalCount;
      }

      return messageMetaCache.getMessageReportCountWithFallback(
        messageId,
        originalCount,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'TopicMessage: Error checking report count for message ${id ?? 'null'}: $e',
        );
      }
      return reportCount ?? 0;
    }
  }

  bool isFlaggedWithCache(MessageMetaCache? messageMetaCache) {
    try {
      final currentReportCount = getReportCountWithCache(messageMetaCache);
      return currentReportCount >= MessageReportConfig.flagThreshold &&
          currentReportCount < MessageReportConfig.hideThreshold;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'TopicMessage: Error checking if message is flagged for ${id ?? 'null'}: $e',
        );
      }
      return false;
    }
  }

  bool isHiddenWithCache(MessageMetaCache? messageMetaCache) {
    try {
      final currentReportCount = getReportCountWithCache(messageMetaCache);
      return currentReportCount >= MessageReportConfig.hideThreshold &&
          currentReportCount < MessageReportConfig.severeThreshold;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'TopicMessage: Error checking if message is hidden for ${id ?? 'null'}: $e',
        );
      }
      return false;
    }
  }

  bool isSevereWithCache(MessageMetaCache? messageMetaCache) {
    try {
      final currentReportCount = getReportCountWithCache(messageMetaCache);
      return currentReportCount >= MessageReportConfig.severeThreshold;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'TopicMessage: Error checking if message is severe for ${id ?? 'null'}: $e',
        );
      }
      return false;
    }
  }

  bool isReportedWithCache(MessageMetaCache? messageMetaCache) {
    try {
      final currentReportCount = getReportCountWithCache(messageMetaCache);
      return currentReportCount > 0;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'TopicMessage: Error checking if message is reported for ${id ?? 'null'}: $e',
        );
      }
      return false;
    }
  }

  String? getReportStatusWithCache(MessageMetaCache? messageMetaCache) {
    try {
      final currentReportCount = getReportCountWithCache(messageMetaCache);
      return MessageReportConfig.getReportStatus(currentReportCount);
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'TopicMessage: Error getting report status for ${id ?? 'null'}: $e',
        );
      }
      return null;
    }
  }

  String getReportStatusDescriptionWithCache(
    MessageMetaCache? messageMetaCache,
  ) {
    try {
      final currentReportCount = getReportCountWithCache(messageMetaCache);
      return MessageReportConfig.getStatusDescription(currentReportCount);
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'TopicMessage: Error getting report status description for ${id ?? 'null'}: $e',
        );
      }
      return 'No reports';
    }
  }

  bool shouldShowWithCache(
    MessageMetaCache? messageMetaCache, {
    bool isAdmin = false,
  }) {
    try {
      final currentReportCount = getReportCountWithCache(messageMetaCache);
      return MessageReportConfig.shouldShowMessage(
        currentReportCount,
        isAdmin: isAdmin,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'TopicMessage: Error checking if message should show for ${id ?? 'null'}: $e',
        );
      }
      return true;
    }
  }

  bool shouldShowContentWarningWithCache(MessageMetaCache? messageMetaCache) {
    try {
      final currentReportCount = getReportCountWithCache(messageMetaCache);
      return MessageReportConfig.shouldShowContentWarning(currentReportCount);
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'TopicMessage: Error checking content warning for ${id ?? 'null'}: $e',
        );
      }
      return false;
    }
  }

  bool isReportedButRevealableWithCache(MessageMetaCache? messageMetaCache) {
    try {
      final currentReportCount = getReportCountWithCache(messageMetaCache);
      return currentReportCount > 0 &&
          currentReportCount < MessageReportConfig.hideThreshold;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'TopicMessage: Error checking if message is reported but revealable for ${id ?? 'null'}: $e',
        );
      }
      return false;
    }
  }

  Map<String, dynamic> getReportDebugInfo(MessageMetaCache? messageMetaCache) {
    return MessageReportHelper.getReportDebugInfo(this, messageMetaCache);
  }
}

/// Static utility class for message report operations
class MessageReportHelper {
  MessageReportHelper._(); // Private constructor

  static int getMessageReportCount(
    dynamic message,
    MessageMetaCache? messageMetaCache,
  ) {
    try {
      if (message == null) return 0;
      if (message is TopicMessage) {
        return message.getReportCountWithCache(messageMetaCache);
      } else {
        if (kDebugMode) {
          debugPrint(
            'MessageReportHelper: Unknown message type: ${message.runtimeType}',
          );
        }
        return 0;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'MessageReportHelper: Error getting message report count: $e',
        );
      }
      return 0;
    }
  }

  static bool isMessageFlagged(
    dynamic message,
    MessageMetaCache? messageMetaCache,
  ) {
    try {
      if (message == null) return false;
      if (message is TopicMessage) {
        return message.isFlaggedWithCache(messageMetaCache);
      } else {
        if (kDebugMode) {
          debugPrint(
            'MessageReportHelper: Unknown message type: ${message.runtimeType}',
          );
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'MessageReportHelper: Error checking if message is flagged: $e',
        );
      }
      return false;
    }
  }

  static bool isMessageHidden(
    dynamic message,
    MessageMetaCache? messageMetaCache,
  ) {
    try {
      if (message == null) return false;
      if (message is TopicMessage) {
        return message.isHiddenWithCache(messageMetaCache);
      } else {
        if (kDebugMode) {
          debugPrint(
            'MessageReportHelper: Unknown message type: ${message.runtimeType}',
          );
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'MessageReportHelper: Error checking if message is hidden: $e',
        );
      }
      return false;
    }
  }

  static bool isMessageSevere(
    dynamic message,
    MessageMetaCache? messageMetaCache,
  ) {
    try {
      if (message == null) return false;
      if (message is TopicMessage) {
        return message.isSevereWithCache(messageMetaCache);
      } else {
        if (kDebugMode) {
          debugPrint(
            'MessageReportHelper: Unknown message type: ${message.runtimeType}',
          );
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'MessageReportHelper: Error checking if message is severe: $e',
        );
      }
      return false;
    }
  }

  static bool isMessageReported(
    dynamic message,
    MessageMetaCache? messageMetaCache,
  ) {
    try {
      if (message == null) return false;
      if (message is TopicMessage) {
        return message.isReportedWithCache(messageMetaCache);
      } else {
        if (kDebugMode) {
          debugPrint(
            'MessageReportHelper: Unknown message type: ${message.runtimeType}',
          );
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'MessageReportHelper: Error checking if message is reported: $e',
        );
      }
      return false;
    }
  }

  static bool isMessageReportedButRevealable(
    dynamic message,
    MessageMetaCache? messageMetaCache,
  ) {
    try {
      if (message == null) return false;
      if (message is TopicMessage) {
        return message.isReportedButRevealableWithCache(messageMetaCache);
      } else {
        if (kDebugMode) {
          debugPrint(
            'MessageReportHelper: Unknown message type: ${message.runtimeType}',
          );
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'MessageReportHelper: Error checking if message is reported but revealable: $e',
        );
      }
      return false;
    }
  }

  static String? getMessageReportStatus(
    dynamic message,
    MessageMetaCache? messageMetaCache,
  ) {
    try {
      if (message == null) return null;
      if (message is TopicMessage) {
        return message.getReportStatusWithCache(messageMetaCache);
      } else {
        if (kDebugMode) {
          debugPrint(
            'MessageReportHelper: Unknown message type: ${message.runtimeType}',
          );
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'MessageReportHelper: Error getting message report status: $e',
        );
      }
      return null;
    }
  }

  static String getMessageReportStatusDescription(
    dynamic message,
    MessageMetaCache? messageMetaCache,
  ) {
    try {
      if (message == null) return 'No reports';
      if (message is TopicMessage) {
        return message.getReportStatusDescriptionWithCache(messageMetaCache);
      } else {
        if (kDebugMode) {
          debugPrint(
            'MessageReportHelper: Unknown message type: ${message.runtimeType}',
          );
        }
        return 'No reports';
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'MessageReportHelper: Error getting message report status description: $e',
        );
      }
      return 'No reports';
    }
  }

  static bool isValidMessageId(String? messageId) {
    try {
      if (messageId == null || messageId.isEmpty) return false;
      final trimmedId = messageId.trim();
      if (trimmedId.isEmpty) return false;
      if (trimmedId.length > _maxMessageIdLength) return false;
      final validFormat = RegExp(r'^[a-zA-Z0-9_\-]+$').hasMatch(trimmedId);
      if (!validFormat) return false;
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'MessageReportHelper: Error validating message ID "$messageId": $e',
        );
      }
      return false;
    }
  }

  static String? getMessageId(dynamic message) {
    try {
      if (message == null) return null;
      if (message is TopicMessage) {
        return message.id;
      } else {
        if (kDebugMode) {
          debugPrint(
            'MessageReportHelper: Unknown message type: ${message.runtimeType}',
          );
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

  static bool isReportFunctionalityAvailable(
    dynamic message,
    MessageMetaCache? messageMetaCache,
  ) {
    try {
      if (message == null || messageMetaCache == null) return false;
      final messageId = getMessageId(message);
      if (!isValidMessageId(messageId)) return false;
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'MessageReportHelper: Error checking report functionality availability: $e',
        );
      }
      return false;
    }
  }

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
        'reportFunctionalityAvailable': isReportFunctionalityAvailable(
          message,
          messageMetaCache,
        ),
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

  static int? _getOriginalReportCountField(dynamic message) {
    try {
      if (message is TopicMessage) {
        return message.reportCount;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'MessageReportHelper: Error getting original reportCount field: $e',
        );
      }
      return null;
    }
  }
}
