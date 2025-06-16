import 'package:flutter/material.dart';

class MessageSeparator extends StatelessWidget {
  final String? label;
  final bool showDot;

  const MessageSeparator({
    super.key,
    this.label,
    this.showDot = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final separatorColor = theme.colorScheme.outline.withValues(alpha: 0.3);
    final textColor = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    separatorColor,
                    separatorColor,
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.3, 0.7, 1.0],
                ),
              ),
            ),
          ),
          if (label != null) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: separatorColor,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showDot) ...[
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    separatorColor,
                    separatorColor,
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.3, 0.7, 1.0],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
