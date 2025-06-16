import 'package:flutter/material.dart';
import 'message_separator.dart';

class SeparatorDemo extends StatelessWidget {
  const SeparatorDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Message Separator Demo'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Message Separators',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Subtle visual dividers to separate read and unread messages',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
              ),
              const SizedBox(height: 32),

              // Example 1: With label and dot
              _buildExample(
                context,
                title: 'With Label and Dot',
                description: 'The standard separator with "New messages" label',
                child: const MessageSeparator(
                  label: 'New messages',
                ),
              ),

              const SizedBox(height: 32),

              // Example 2: With custom label
              _buildExample(
                context,
                title: 'Custom Label',
                description: 'Separator with custom text',
                child: const MessageSeparator(
                  label: 'Unread',
                ),
              ),

              const SizedBox(height: 32),

              // Example 3: Without dot
              _buildExample(
                context,
                title: 'Without Dot',
                description: 'Clean separator without the indicator dot',
                child: const MessageSeparator(
                  label: 'New messages',
                  showDot: false,
                ),
              ),

              const SizedBox(height: 32),

              // Example 4: Line only
              _buildExample(
                context,
                title: 'Line Only',
                description: 'Minimal separator with just the gradient line',
                child: const MessageSeparator(),
              ),

              const SizedBox(height: 32),

              // Context example
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'In Context',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'How the separator appears in a message list:',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),

                    // Mock message
                    _buildMockMessage(context, 'Last read message',
                        isRead: true),

                    // Separator
                    const MessageSeparator(
                      label: 'New messages',
                    ),

                    // Mock message
                    _buildMockMessage(context, 'First unread message',
                        isRead: false),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExample(
    BuildContext context, {
    required String title,
    required String description,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.7),
              ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _buildMockMessage(BuildContext context, String text,
      {required bool isRead}) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isRead
              ? Theme.of(context).colorScheme.surfaceContainerHighest
              : Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(16),
          border: !isRead
              ? Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .secondary
                      .withValues(alpha: 0.3),
                )
              : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isRead
                ? Theme.of(context).colorScheme.onSurfaceVariant
                : Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
