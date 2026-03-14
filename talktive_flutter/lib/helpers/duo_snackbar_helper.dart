import 'package:flutter/material.dart';
import 'package:talktive_client/talktive_client.dart';
import '../config/theme.dart';

/// Helper class for showing consistent Duolingo-style SnackBars for the Serverpod version.
class DuoSnackBarHelper {
  /// Shows a success SnackBar with a green background.
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Text('✅ ', style: TextStyle(fontSize: 18)),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.duoGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Shows an error SnackBar with a red background.
  /// Handles TalktiveException and ServerpodClientException.
  static void showError(BuildContext context, dynamic error) {
    String message;
    if (error is String) {
      message = error;
    } else if (error is TalktiveException) {
      message = error.message;
    } else if (error is ServerpodClientException) {
      message =
          (error.message == 'Internal server error' && error.statusCode == 500)
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
        content: Row(
          children: [
            const Text('⚠️ ', style: TextStyle(fontSize: 18)),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.duoRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Shows an info SnackBar with the primary purple background.
  static void showInfo(BuildContext context, String message, {String? emoji}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (emoji != null) Text('$emoji ', style: const TextStyle(fontSize: 18)),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Shows a warning SnackBar with an orange background.
  static void showWarning(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Text('🔔 ', style: TextStyle(fontSize: 18)),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.duoOrange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
