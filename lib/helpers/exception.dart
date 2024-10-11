import 'package:flutter/material.dart';

class AppException implements Exception {
  final String message;

  AppException(this.message);

  @override
  String toString() => message;
}

class ErrorHandler {
  static void showSnackBarMessage(BuildContext context, AppException exception,
      {bool severe = false}) {
    final theme = Theme.of(context);

    Color? backgroundColor;
    Color? textColor;

    if (severe == true) {
      backgroundColor = theme.colorScheme.errorContainer;
      textColor = theme.colorScheme.onErrorContainer;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: backgroundColor,
        content: Text(
          exception.toString(),
          style: TextStyle(
            color: textColor,
          ),
        ),
      ),
    );
  }
}
