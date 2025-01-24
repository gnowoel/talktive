import 'package:flutter/material.dart';

class Tag extends StatelessWidget {
  final String tooltip;
  final Widget child;
  final bool? isCritical;

  const Tag({
    super.key,
    required this.tooltip,
    required this.child,
    this.isCritical,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isCritical ?? false) {
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
