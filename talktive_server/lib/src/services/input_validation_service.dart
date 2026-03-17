import 'package:serverpod/serverpod.dart';
import 'package:talktive_server/src/generated/protocol.dart';

/// Centralized input validation service for all endpoints.
/// Provides consistent validation rules across the application.
class InputValidationService {
  // Text content limits
  static const int maxMessageLength = 2000;
  static const int maxCaptionLength = 500;
  static const int maxCommentLength = 500;
  static const int maxGroupNameLength = 50;
  static const int maxNameLength = 50;
  static const int maxGroupDescriptionLength = 500;
  static const int maxReportReasonLength = 500;
  static const int maxBioLength = 500;

  // Numeric limits
  static const int minGroupMembers = 2;
  static const int maxGroupMembers = 500;
  static const int maxListLimit = 100;
  static const int maxOffset = 10000;

  /// Validates a user name or group name.
  static ValidationResult validateName(
    String name, {
    String fieldName = 'Name',
  }) {
    if (name.trim().isEmpty) {
      return ValidationResult(
        isValid: false,
        error: '$fieldName cannot be empty',
      );
    }

    if (name.length > maxNameLength) {
      return ValidationResult(
        isValid: false,
        error: '$fieldName must be $maxNameLength characters or less',
      );
    }

    if (name.length < 2) {
      return ValidationResult(
        isValid: false,
        error: '$fieldName must be at least 2 characters',
      );
    }

    return ValidationResult(isValid: true);
  }

  /// Validates a message content string.
  static ValidationResult validateMessageContent(String content) {
    if (content.trim().isEmpty) {
      return ValidationResult(
        isValid: false,
        error: 'Message cannot be empty',
      );
    }

    if (content.length > maxMessageLength) {
      return ValidationResult(
        isValid: false,
        error: 'Message must be $maxMessageLength characters or less',
      );
    }

    return ValidationResult(isValid: true);
  }

  /// Validates a caption (for moments).
  static ValidationResult validateCaption(String caption) {
    if (caption.length > maxCaptionLength) {
      return ValidationResult(
        isValid: false,
        error: 'Caption must be $maxCaptionLength characters or less',
      );
    }

    return ValidationResult(isValid: true);
  }

  /// Validates a comment text.
  static ValidationResult validateComment(String text) {
    if (text.trim().isEmpty) {
      return ValidationResult(
        isValid: false,
        error: 'Comment cannot be empty',
      );
    }

    if (text.length > maxCommentLength) {
      return ValidationResult(
        isValid: false,
        error: 'Comment must be $maxCommentLength characters or less',
      );
    }

    return ValidationResult(isValid: true);
  }

  /// Validates a group name.
  static ValidationResult validateGroupName(String name) {
    return validateName(name, fieldName: 'Group name');
  }

  /// Validates a group description.
  static ValidationResult validateGroupDescription(String? description) {
    if (description != null && description.length > maxGroupDescriptionLength) {
      return ValidationResult(
        isValid: false,
        error:
            'Group description must be $maxGroupDescriptionLength characters or less',
      );
    }

    return ValidationResult(isValid: true);
  }

  /// Validates group member limits.
  static ValidationResult validateGroupMemberLimit(int maxMembers) {
    if (maxMembers < minGroupMembers || maxMembers > maxGroupMembers) {
      return ValidationResult(
        isValid: false,
        error:
            'Max members must be between $minGroupMembers and $maxGroupMembers',
      );
    }

    return ValidationResult(isValid: true);
  }

  /// Validates a report reason.
  static ValidationResult validateReportReason(String reason) {
    if (reason.trim().isEmpty) {
      return ValidationResult(
        isValid: false,
        error: 'Report reason cannot be empty',
      );
    }

    if (reason.length > maxReportReasonLength) {
      return ValidationResult(
        isValid: false,
        error:
            'Report reason must be $maxReportReasonLength characters or less',
      );
    }

    return ValidationResult(isValid: true);
  }

  /// Validates pagination parameters.
  static ValidationResult validatePagination({
    required int limit,
    required int offset,
  }) {
    if (limit < 1 || limit > maxListLimit) {
      return ValidationResult(
        isValid: false,
        error: 'Limit must be between 1 and $maxListLimit',
      );
    }

    if (offset < 0 || offset > maxOffset) {
      return ValidationResult(
        isValid: false,
        error: 'Offset must be between 0 and $maxOffset',
      );
    }

    return ValidationResult(isValid: true);
  }

  /// Validates a UUID string.
  static ValidationResult validateUuid(String uuid) {
    try {
      UuidValue.fromString(uuid);
      return ValidationResult(isValid: true);
    } catch (e) {
      return ValidationResult(
        isValid: false,
        error: 'Invalid user ID format',
      );
    }
  }

  /// Validates a URL string.
  static ValidationResult validateUrl(String? url) {
    if (url == null || url.isEmpty) {
      return ValidationResult(isValid: true); // Optional URL
    }

    try {
      final uri = Uri.parse(url);
      if (!uri.hasScheme || (!uri.isScheme('http') && !uri.isScheme('https'))) {
        return ValidationResult(
          isValid: false,
          error: 'URL must use http or https protocol',
        );
      }
      return ValidationResult(isValid: true);
    } catch (e) {
      return ValidationResult(
        isValid: false,
        error: 'Invalid URL format',
      );
    }
  }

  /// Validates an image URL (must be present and valid).
  static ValidationResult validateImageUrl(String imageUrl) {
    if (imageUrl.trim().isEmpty) {
      return ValidationResult(
        isValid: false,
        error: 'Image URL is required',
      );
    }

    return validateUrl(imageUrl);
  }

  /// Validates a gender string.
  static ValidationResult validateGender(String gender) {
    const validGenders = ['male', 'female', 'non-binary', 'prefer-not-to-say'];
    if (!validGenders.contains(gender.toLowerCase())) {
      return ValidationResult(
        isValid: false,
        error: 'Invalid gender selection',
      );
    }
    return ValidationResult(isValid: true);
  }

  /// Validates a bio text.
  static ValidationResult validateBio(String? bio) {
    if (bio != null && bio.length > maxBioLength) {
      return ValidationResult(
        isValid: false,
        error: 'Bio must be $maxBioLength characters or less',
      );
    }

    return ValidationResult(isValid: true);
  }

  /// Validates an ID (must be positive).
  static ValidationResult validateId(int id, String fieldName) {
    if (id <= 0) {
      return ValidationResult(
        isValid: false,
        error: '$fieldName must be a positive number',
      );
    }

    return ValidationResult(isValid: true);
  }

  /// Validates a list of strings (e.g., interests, languages).
  static ValidationResult validateStringList(
    List<String>? items,
    String fieldName, {
    int maxItems = 10,
    int maxItemLength = 50,
  }) {
    if (items == null || items.isEmpty) {
      return ValidationResult(isValid: true); // Optional list
    }

    if (items.length > maxItems) {
      return ValidationResult(
        isValid: false,
        error: '$fieldName cannot have more than $maxItems items',
      );
    }

    for (final item in items) {
      if (item.trim().isEmpty) {
        return ValidationResult(
          isValid: false,
          error: '$fieldName cannot contain empty items',
        );
      }

      if (item.length > maxItemLength) {
        return ValidationResult(
          isValid: false,
          error: '$fieldName items must be $maxItemLength characters or less',
        );
      }
    }

    return ValidationResult(isValid: true);
  }
}

/// Result of a validation check.
class ValidationResult {
  final bool isValid;
  final String? error;
  final String? errorCode;

  ValidationResult({
    required this.isValid,
    this.error,
    this.errorCode,
  });

  /// Throws a TalktiveException if validation failed.
  void throwIfInvalid() {
    if (!isValid) {
      throw TalktiveException(
        message: error ?? 'Validation failed',
        code: errorCode ?? 'VALIDATION_ERROR',
      );
    }
  }
}
