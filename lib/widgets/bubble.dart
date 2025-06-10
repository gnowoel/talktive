import 'package:flutter/material.dart';

class Bubble extends StatelessWidget {
  final String content;
  final bool byMe;
  final bool byOp;
  final bool isMentioned;

  const Bubble({
    super.key,
    required this.content,
    this.byMe = false,
    this.byOp = false,
    this.isMentioned = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Color containerColor;
    if (isMentioned && !byMe) {
      // Highlight mentions with a subtle accent
      containerColor = colorScheme.primaryContainer.withValues(alpha: 0.3);
    } else if (byMe) {
      containerColor = colorScheme.primaryContainer;
    } else if (byOp) {
      containerColor = colorScheme.tertiaryContainer;
    } else {
      containerColor = colorScheme.surfaceContainerHigh;
    }

    final textColor = byMe
        ? colorScheme.onPrimaryContainer
        : (byOp ? colorScheme.onTertiaryContainer : colorScheme.onSurface);

    final pattern = RegExp(r"^-.*-$");
    final inItalics = pattern.hasMatch(content);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: containerColor,
        border: isMentioned && !byMe
            ? Border.all(
                color: colorScheme.primary.withValues(alpha: 0.4),
                width: 1.5,
              )
            : null,
      ),
      child: Text(
        content,
        style: TextStyle(
          fontSize: 16,
          color: textColor,
          fontStyle: inItalics ? FontStyle.italic : null,
        ),
      ),
    );
  }
}
