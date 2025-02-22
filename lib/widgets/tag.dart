import 'package:flutter/material.dart';

class Tag extends StatelessWidget {
  final String? status;
  final String tooltip;
  final Widget child;

  const Tag({
    super.key,
    this.status,
    required this.tooltip,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (status == 'warning') {
      return Tooltip(
        message: tooltip,
        child: Container(
          margin: const EdgeInsets.only(top: 6, bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer,
            // border: Border.all(color: theme.colorScheme.error),
            border: Border.all(color: theme.colorScheme.inversePrimary),
            borderRadius: BorderRadius.all(
              Radius.circular(16),
            ),
          ),
          child: child,
        ),
      );
    }

    if (status == 'alert') {
      return Tooltip(
        message: tooltip,
        child: Container(
          margin: const EdgeInsets.only(top: 6, bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.tertiaryContainer,
            // border: Border.all(color: theme.colorScheme.error),
            border: Border.all(color: theme.colorScheme.inversePrimary),
            borderRadius: BorderRadius.all(
              Radius.circular(16),
            ),
          ),
          child: child,
        ),
      );
    }

    if (status == 'newcomer') {
      return Tooltip(
        message: tooltip,
        child: Container(
          margin: const EdgeInsets.only(top: 6, bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            // border: Border.all(color: theme.colorScheme.error),
            border: Border.all(color: theme.colorScheme.inversePrimary),
            borderRadius: BorderRadius.all(
              Radius.circular(16),
            ),
          ),
          child: child,
        ),
      );
    }

    return Tooltip(
      message: tooltip,
      child: Container(
        margin: const EdgeInsets.only(top: 6, bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceBright,
          border: Border.all(color: theme.colorScheme.inversePrimary),
          borderRadius: BorderRadius.all(
            Radius.circular(16),
          ),
        ),
        child: child,
      ),
    );
  }
}
