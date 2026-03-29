import 'package:serverpod/serverpod.dart';
import '../services/input_validation_service.dart';
import '../utils/validation_result.dart';

/// Content filtering service for profanity and spam detection
class ContentFilterService {
  /// Common profanity words (basic list - expand as needed)
  static const List<String> profanityList = [
    'badword1',
    'badword2',
    'spam',
    'scam',
  ];

  /// Spam patterns
  static final List<RegExp> spamPatterns = [
    RegExp(r'(https?://|www\.)\S+', caseSensitive: false), // URLs
    RegExp(r'\b\d{10,}\b'), // Long numbers (phone numbers)
    RegExp(r'(.)\1{4,}'), // Repeated characters (aaaaa)
    RegExp(r'\b(buy|sell|click|free|win|prize)\b', caseSensitive: false),
  ];

  /// Check if content contains profanity
  static bool containsProfanity(String content) {
    final lowerContent = content.toLowerCase();

    for (final word in profanityList) {
      if (lowerContent.contains(word)) {
        return true;
      }
    }

    return false;
  }

  /// Check if content is spam
  static bool isSpam(String content) {
    // Check for spam patterns
    for (final pattern in spamPatterns) {
      if (pattern.hasMatch(content)) {
        return true;
      }
    }

    // Check for excessive caps
    final capsCount = content.replaceAll(RegExp(r'[^A-Z]'), '').length;
    final totalLetters = content.replaceAll(RegExp(r'[^a-zA-Z]'), '').length;
    if (totalLetters > 10 && (capsCount / totalLetters) > 0.7) {
      return true; // More than 70% caps
    }

    return false;
  }

  /// Filter content and return cleaned version or null if blocked
  static String? filterContent(String content, {bool strictMode = false}) {
    if (content.trim().isEmpty) {
      return null;
    }

    // Check for profanity
    if (containsProfanity(content)) {
      if (strictMode) {
        return null; // Block completely in strict mode
      }
      // Replace profanity with asterisks
      var filtered = content;
      for (final word in profanityList) {
        final regex = RegExp(word, caseSensitive: false);
        filtered = filtered.replaceAll(regex, '*' * word.length);
      }
      return filtered;
    }

    // Check for spam
    if (isSpam(content)) {
      return null; // Block spam completely
    }

    return content;
  }

  /// Validate message content before posting
  static Future<ValidationResult> validateMessage(
    Session session,
    String content,
    int userFloor,
  ) async {
    // Length check
    if (content.trim().isEmpty) {
      return ValidationResult.failure('Message cannot be empty');
    }

    if (content.length > InputValidationService.maxMessageLength) {
      return ValidationResult.failure(
        'Message too long (max ${InputValidationService.maxMessageLength} characters)',
      );
    }

    // Profanity check (stricter for low floor users)
    final strictMode = userFloor < 2;
    final filtered = filterContent(content, strictMode: strictMode);

    if (filtered == null) {
      return ValidationResult.failure(
        strictMode
            ? 'Message contains inappropriate content'
            : 'Message appears to be spam',
      );
    }

    return ValidationResult.success(filteredContent: filtered);
  }

  /// Check for repeated messages (spam detection)
  static Future<bool> isRepeatedMessage(
    Session session,
    String userId,
    String content,
  ) async {
    try {
      final cache = session.caches.global;
      final key = 'lastmsg:$userId';
      final entry = await cache.get<CacheString>(key);
      if (entry != null && entry.value == content) {
        return true; // Same message as last one
      }

      // Store this message for 5 minutes
      await cache.put(
        key,
        CacheString(value: content),
        lifetime: const Duration(minutes: 5),
      );
      return false;
    } catch (e, stack) {
      session.log(
        'Error checking repeated message: $e',
        level: LogLevel.warning,
        stackTrace: stack,
      );
      return false; // Fail open (allow message) on cache errors
    }
  }

  /// Report content for review (stores in Redis for admin review)
  static Future<void> flagContent(
    Session session,
    String contentId,
    String contentType,
    String reason,
  ) async {
    try {
      final key = 'flagged:$contentType:$contentId';
      final data = '$reason|${DateTime.now().toIso8601String()}';

      await session.caches.global.put(
        key,
        CacheString(value: data),
        lifetime: const Duration(days: 7),
      );
      session.log('Content flagged: $contentType:$contentId - $reason');
    } catch (e) {
      session.log('Error flagging content: $e', level: LogLevel.warning);
    }
  }
}
