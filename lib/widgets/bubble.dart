import 'package:flutter/material.dart';

class Bubble extends StatelessWidget {
  final String content;
  final bool byMe;
  final bool byOp;
  final bool isBot;

  const Bubble({
    super.key,
    required this.content,
    this.byMe = false,
    this.byOp = false,
    this.isBot = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final containerColor = isBot
        ? colorScheme.secondaryContainer
        : (byMe
            ? colorScheme.primaryContainer
            : (byOp
                ? colorScheme.tertiaryContainer
                : colorScheme.surfaceContainerHigh));

    final textColor = isBot
        ? colorScheme.onSecondaryContainer
        : (byMe
            ? colorScheme.onPrimaryContainer
            : (byOp ? colorScheme.onTertiaryContainer : colorScheme.onSurface));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: containerColor,
      ),
      child: SelectionArea(
        child: Text(
          content,
          style: TextStyle(fontSize: 16, color: textColor),
        ),
      ),
    );
  }
}
