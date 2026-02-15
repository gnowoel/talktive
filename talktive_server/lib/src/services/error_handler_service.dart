import 'package:serverpod/serverpod.dart';

/// Centralized error handling service for consistent error responses.
class ErrorHandlerService {
  /// Handles exceptions and returns user-friendly error messages.
  static String handleException(Exception e, Session session) {
    final errorMessage = e.toString().replaceFirst('Exception: ', '');

    // Log the error
    session.log(
      'Error: $errorMessage',
      level: LogLevel.error,
    );

    // Return sanitized error message
    return errorMessage;
  }

  /// Handles general errors and returns user-friendly error messages.
  static String handleError(Object error, StackTrace stack, Session session) {
    // Log the full error with stack trace
    session.log(
      'Unexpected error: $error\n$stack',
      level: LogLevel.error,
    );

    // Return generic error message (don't expose internal details)
    return 'An unexpected error occurred. Please try again.';
  }

  /// Wraps endpoint methods with consistent error handling.
  static Future<T> wrapEndpoint<T>(
    Session session,
    Future<T> Function() operation, {
    String? operationName,
  }) async {
    try {
      return await operation();
    } on Exception catch (e) {
      final message = handleException(e, session);
      throw Exception(message);
    } catch (e, stack) {
      final message = handleError(e, stack, session);
      throw Exception(message);
    }
  }

  /// Common error messages
  static const String notAuthenticated = 'Not authenticated';
  static const String notFound = 'Resource not found';
  static const String accessDenied = 'Access denied';
  static const String invalidInput = 'Invalid input';
  static const String rateLimitExceeded = 'Rate limit exceeded';
  static const String serverError = 'Server error occurred';
}

/// Custom exception types for better error handling
class AuthenticationException implements Exception {
  final String message;
  AuthenticationException(this.message);

  @override
  String toString() => message;
}

class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);

  @override
  String toString() => message;
}

class NotFoundException implements Exception {
  final String message;
  NotFoundException(this.message);

  @override
  String toString() => message;
}

class PermissionException implements Exception {
  final String message;
  PermissionException(this.message);

  @override
  String toString() => message;
}

class RateLimitException implements Exception {
  final String message;
  RateLimitException(this.message);

  @override
  String toString() => message;
}
