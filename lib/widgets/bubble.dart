import 'package:flutter/material.dart';

class Bubble extends StatelessWidget {
  final String content;
  final bool byMe;
  final bool byOp;
  final bool recalled;

  const Bubble({
    super.key,
    required this.content,
    this.byMe = false,
    this.byOp = false,
    this.recalled = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final containerColor = byMe
        ? colorScheme.primaryContainer
        : (byOp
            ? colorScheme.tertiaryContainer
            : colorScheme.surfaceContainerHigh);

    final textColor = byMe
        ? colorScheme.onPrimaryContainer
        : (byOp ? colorScheme.onTertiaryContainer : colorScheme.onSurface);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: containerColor,
      ),
      child: Text(
        content,
        style: TextStyle(
          fontSize: 16,
          color: textColor,
          fontStyle: recalled ? FontStyle.italic : null,
        ),
      ),
    );
  }
}
