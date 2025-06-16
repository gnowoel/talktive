import 'package:flutter/material.dart';

class Tag extends StatelessWidget {
  final String? status;
  final String? tooltip;
  final Widget? child;

  const Tag({
    super.key,
    this.status,
    this.tooltip,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (status == 'warning') {
      return Tooltip(
        message: 'Reported for inappropriate behavior',
        child: Container(
          margin: const EdgeInsets.only(top: 6, bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer,
            border: Border.all(color: theme.colorScheme.inversePrimary),
            borderRadius: BorderRadius.all(
              Radius.circular(16),
            ),
          ),
          child: Text(
            'warning',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onErrorContainer,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    if (status == 'alert') {
      return Tooltip(
        message: 'Reported for offensive messages',
        child: Container(
          margin: const EdgeInsets.only(top: 6, bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.tertiaryContainer,
            border: Border.all(color: theme.colorScheme.inversePrimary),
            borderRadius: BorderRadius.all(
              Radius.circular(16),
            ),
          ),
          child: Text(
            'alert',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onTertiaryContainer,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    if (status == 'newcomer') {
      return Tooltip(
        message: 'Created in less than 1 day',
        child: Container(
          margin: const EdgeInsets.only(top: 6, bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            border: Border.all(color: theme.colorScheme.inversePrimary),
            borderRadius: BorderRadius.all(
              Radius.circular(16),
            ),
          ),
          child: Text(
            'new',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onPrimaryContainer,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    if (status == 'excellent') {
      return Tooltip(
        message: 'Excellent reputation - highly trusted user',
        child: Container(
          margin: const EdgeInsets.only(top: 6, bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            border: Border.all(color: theme.colorScheme.inversePrimary),
            borderRadius: BorderRadius.all(
              Radius.circular(16),
            ),
          ),
          child: Text(
            'trusted',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSecondaryContainer,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    if (status == 'poor') {
      return Tooltip(
        message: 'Poor reputation - some reports received',
        child: Container(
          margin: const EdgeInsets.only(top: 6, bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer.withValues(alpha: 0.7),
            border: Border.all(color: theme.colorScheme.inversePrimary),
            borderRadius: BorderRadius.all(
              Radius.circular(16),
            ),
          ),
          child: Text(
            'caution',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onErrorContainer,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    if (status == 'very_poor') {
      return Tooltip(
        message: 'Very poor reputation - multiple reports received',
        child: Container(
          margin: const EdgeInsets.only(top: 6, bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer,
            border: Border.all(color: theme.colorScheme.error),
            borderRadius: BorderRadius.all(
              Radius.circular(16),
            ),
          ),
          child: Text(
            'avoid',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onErrorContainer,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    if (tooltip == null || child == null) {
      return const SizedBox.shrink();
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
