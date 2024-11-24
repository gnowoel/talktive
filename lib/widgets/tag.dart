import 'package:flutter/material.dart';

class Tag extends StatelessWidget {
  final Widget child;

  const Tag({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
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
    );
  }
}
