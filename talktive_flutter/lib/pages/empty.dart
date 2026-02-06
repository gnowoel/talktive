import 'package:flutter/material.dart';

class EmptyPage extends StatelessWidget {
  final bool hasAppBar;
  final Widget? child;

  const EmptyPage({
    super.key,
    this.hasAppBar = true,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      appBar: hasAppBar
          ? AppBar(backgroundColor: theme.colorScheme.surfaceContainerLow)
          : null,
      body: SafeArea(
        child: Center(
          child: child,
        ),
      ),
    );
  }
}
