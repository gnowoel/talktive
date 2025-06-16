import 'package:flutter/material.dart';

class SkippedMessagesPlaceholder extends StatelessWidget {
  final int messageCount;
  final VoidCallback onTapUp;
  final VoidCallback onTapDown;

  const SkippedMessagesPlaceholder({
    super.key,
    required this.messageCount,
    required this.onTapUp,
    required this.onTapDown,
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
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                // Up arrow button
                Tooltip(
                  message: 'Show more recent messages',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onTapUp,
                      borderRadius: BorderRadius.circular(16),
                      splashColor:
                          theme.colorScheme.primary.withValues(alpha: 0.1),
                      highlightColor:
                          theme.colorScheme.primary.withValues(alpha: 0.05),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.keyboard_double_arrow_up_rounded,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Skipped $messageCount message${messageCount == 1 ? '' : 's'}.',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                // Down arrow button
                Tooltip(
                  message: 'Show more older messages',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onTapDown,
                      borderRadius: BorderRadius.circular(16),
                      splashColor:
                          theme.colorScheme.primary.withValues(alpha: 0.1),
                      highlightColor:
                          theme.colorScheme.primary.withValues(alpha: 0.05),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.keyboard_double_arrow_down_rounded,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
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
