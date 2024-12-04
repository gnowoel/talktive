import 'package:flutter/material.dart';

class Tag extends StatelessWidget {
  final String tooltip;
  final Widget child;

  const Tag({
    super.key,
    required this.tooltip,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
