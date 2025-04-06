import 'package:flutter/material.dart';

class AppException implements Exception {
  final String message;

  AppException(this.message);

  @override
  String toString() => message;
}

class ErrorHandler {
  static void showSnackBarMessage(
    BuildContext context,
    AppException exception, {
    bool severe = false,
  }) {
    final theme = Theme.of(context);

    Color? backgroundColor;
    Color? textColor;

    if (severe == true) {
      backgroundColor = theme.colorScheme.errorContainer;
      textColor = theme.colorScheme.onErrorContainer;
    }

    final errorMessage = _getErrorMessage(exception.toString());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: backgroundColor,
        content: Text(errorMessage, style: TextStyle(color: textColor)),
      ),
    );
  }

  static String _getErrorMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'weak-password':
        return 'The password is too weak.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return code;
    }
  }
}
