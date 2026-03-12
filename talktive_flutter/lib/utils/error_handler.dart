import 'package:talktive_client/talktive_client.dart';
import 'package:flutter/material.dart';

/// Centralized error handling utility for the Flutter app.
class ErrorHandler {
  /// Shows a user-friendly error message in a SnackBar.
  static void showError(BuildContext context, Object error) {
    final message = getErrorMessage(error);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Shows a success message in a SnackBar.
  static void showSuccess(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Shows an info message in a SnackBar.
  static void showInfo(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Shows an error dialog with more details.
  static Future<void> showErrorDialog(
    BuildContext context,
    Object error, {
    String? title,
  }) async {
    final message = getErrorMessage(error);

    if (!context.mounted) return;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title ?? 'Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Wraps an async operation with error handling.
  static Future<T?> handleAsync<T>(
    BuildContext context,
    Future<T> Function() operation, {
    String? successMessage,
    bool showErrorDialog = false,
  }) async {
    try {
      final result = await operation();

      if (successMessage != null && context.mounted) {
        showSuccess(context, successMessage);
      }

      return result;
    } catch (e) {
      if (!context.mounted) return null;

      if (showErrorDialog) {
        await ErrorHandler.showErrorDialog(context, e);
      } else {
        showError(context, e);
      }

      return null;
    }
  }

  /// Extracts a user-friendly error message from various error types.
  static String getErrorMessage(Object error) {
    if (error is TalktiveException) {
      return error.message;
    } else if (error is ServerpodClientException) {
      return (error.message == 'Internal server error' && error.statusCode == 500)
          ? 'Something went wrong on our end. Please try again later.'
          : error.message;
    } else if (error is Exception) {
      final message = error.toString();
      if (message.startsWith('Exception: ')) {
        return message.substring(11);
      }
      return message;
    }

    // Generic error
    return error.toString();
  }

  /// Checks if an error is an authentication error.
  static bool isAuthError(Object error) {
    final message = getErrorMessage(error).toLowerCase();
    return message.contains('not authenticated') ||
        message.contains('authentication') ||
        message.contains('unauthorized');
  }

  /// Checks if an error is a network error.
  static bool isNetworkError(Object error) {
    final message = getErrorMessage(error).toLowerCase();
    return message.contains('network') ||
        message.contains('connection') ||
        message.contains('timeout') ||
        message.contains('socket');
  }

  /// Checks if an error is a validation error.
  static bool isValidationError(Object error) {
    final message = getErrorMessage(error).toLowerCase();
    return message.contains('invalid') ||
        message.contains('must be') ||
        message.contains('cannot be') ||
        message.contains('required');
  }
}
