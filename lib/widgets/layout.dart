import 'package:flutter/material.dart';

class Layout extends StatelessWidget {
  final Widget child;

  const Layout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final theme = Theme.of(context);
        if (constraints.maxWidth >= 600) {
          return Align(
            alignment: Alignment.center,
            child: Container(
              margin: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.all(Radius.circular(24)),
                border: Border.all(color: theme.colorScheme.secondaryContainer),
              ),
              constraints: const BoxConstraints(minWidth: 324, maxWidth: 576),
              child: child,
            ),
          );
        } else {
          return Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
            ),
            child: child,
          );
        }
      },
    );
  }
}
