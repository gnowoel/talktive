import 'package:flutter/material.dart';
import 'package:talktive_client/talktive_client.dart';
import '../config/theme.dart';

/// Helper class for showing consistent SnackBars across the app.
class SnackBarHelper {
  /// Shows a success SnackBar with a green background.
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Shows an error SnackBar with a red background.
  /// Automatically handles TalktiveException, ServerpodClientException, and generic errors.
  static void showError(BuildContext context, dynamic error) {
    String message;
    if (error is String) {
      message = error;
    } else if (error is TalktiveException) {
      message = error.message;
    } else if (error is ServerpodClientException) {
      message = (error.message == 'Internal server error' && error.statusCode == 500)
          ? 'Something went wrong on our end. Please try again later.'
          : error.message;
    } else {
      final errorStr = error.toString();
      message = errorStr.contains('Exception: ') 
          ? errorStr.split('Exception: ')[1] 
          : errorStr;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Shows an info SnackBar with the primary color background.
  static void showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Shows a warning SnackBar with an orange background.
  static void showWarning(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.duoOrange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
