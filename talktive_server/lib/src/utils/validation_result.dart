import 'package:talktive_server/src/generated/protocol.dart';

/// Centralized result of a validation check.
class ValidationResult {
  final bool isValid;
  final String? error;
  final String? errorCode;
  final String? filteredContent;

  ValidationResult({
    required this.isValid,
    this.error,
    this.errorCode,
    this.filteredContent,
  });

  /// Factory for successful validation.
  factory ValidationResult.success({String? filteredContent}) =>
      ValidationResult(
        isValid: true,
        filteredContent: filteredContent,
      );

  /// Factory for failed validation.
  factory ValidationResult.failure(String error, {String? errorCode}) =>
      ValidationResult(
        isValid: false,
        error: error,
        errorCode: errorCode,
      );

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
