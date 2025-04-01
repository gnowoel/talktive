import 'package:flutter/material.dart';

class Bubble extends StatelessWidget {
  final String content;
  final bool byMe;
  final bool isBot;

  const Bubble({
    super.key,
    required this.content,
    this.byMe = false,
    this.isBot = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final containerColor =
        isBot
            ? colorScheme.secondaryContainer
            : (byMe
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHigh);

    final textColor =
        isBot
            ? colorScheme.onSecondaryContainer
            : (byMe ? colorScheme.onPrimaryContainer : colorScheme.onSurface);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: containerColor,
      ),
      child: Text(content, style: TextStyle(fontSize: 16, color: textColor)),
    );
  }
}
