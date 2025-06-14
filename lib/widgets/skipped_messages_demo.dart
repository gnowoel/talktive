import 'package:flutter/material.dart';
import 'message_separator.dart';
import 'skipped_messages_placeholder.dart';

class SkippedMessagesDemo extends StatefulWidget {
  const SkippedMessagesDemo({super.key});

  @override
  State<SkippedMessagesDemo> createState() => _SkippedMessagesDemoState();
}

class _SkippedMessagesDemoState extends State<SkippedMessagesDemo> {
  bool _showAllMessages = false;
  int _selectedScenario = 0;

  // Different scenarios to demonstrate
  final List<_DemoScenario> _scenarios = [
    _DemoScenario(
      name: 'Few Messages (15 total, 12 read)',
      totalMessages: 15,
      readMessages: 12,
      description: 'No placeholder, separator shows between read/unread',
    ),
    _DemoScenario(
      name: 'Some Messages (42 total, 24 read)',
      totalMessages: 42,
      readMessages: 24,
      description: 'Skip 14, show 10 context, separator, then 18 unread',
    ),
    _DemoScenario(
      name: 'All Read (30 total, 30 read)',
      totalMessages: 30,
      readMessages: 30,
      description: 'No separator - all messages are read',
    ),
    _DemoScenario(
      name: 'Many Messages (200 total, 150 read)',
      totalMessages: 200,
      readMessages: 150,
      description: 'Skip 140, show 10 context, separator, then 50 unread',
    ),
  ];

  void _onTapPlaceholder() async {
    final scenario = _scenarios[_selectedScenario];
    final messagesToSkip = scenario.readMessages - 10;

    // Show confirmation dialog if more than 100 messages to skip
    if (messagesToSkip > 100) {
      final confirmed = await _showConfirmationDialog(messagesToSkip);
      if (confirmed != true) return;
    }

    setState(() {
      _showAllMessages = true;
    });
  }

  Future<bool?> _showConfirmationDialog(int messageCount) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Load All Messages'),
        content: Text(
          'Loading $messageCount additional messages may take some time and could affect performance. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Load'),
          ),
        ],
      ),
    );
  }

  void _reset() {
    setState(() {
      _showAllMessages = false;
    });
  }

  void _changeScenario(int index) {
    setState(() {
      _selectedScenario = index;
      _showAllMessages = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scenario = _scenarios[_selectedScenario];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Message Separator Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reset,
            tooltip: 'Reset Demo',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Scenario selector
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Demo Scenarios',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Visual separators help users identify where new messages begin',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
                        ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(_scenarios.length, (index) {
                    final isSelected = index == _selectedScenario;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: InkWell(
                        onTap: () => _changeScenario(index),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .outline
                                      .withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _scenarios[index].name,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? Theme.of(context)
                                              .colorScheme
                                              .onPrimaryContainer
                                          : null,
                                    ),
                              ),
                              Text(
                                _scenarios[index].description,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: isSelected
                                          ? Theme.of(context)
                                              .colorScheme
                                              .onPrimaryContainer
                                              .withOpacity(0.7)
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.7),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

            // Demo content
            Expanded(
              child: _buildMessageList(scenario),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList(_DemoScenario scenario) {
    final shouldShowPlaceholder =
        scenario.readMessages > 20 && !_showAllMessages;

    // Calculate messages to skip (keeping last 10 for context)
    final messagesToSkip =
        shouldShowPlaceholder ? scenario.readMessages - 10 : 0;

    // Generate visible messages
    final visibleMessages = List.generate(
      scenario.totalMessages - messagesToSkip,
      (index) => index + messagesToSkip,
    );

    // Determine if we should show separator
    final showSeparator =
        scenario.readMessages > 0 && // There are read messages
            scenario.totalMessages >
                scenario.readMessages; // There are unread messages

    // Calculate separator position in the item list
    int? separatorIndex;
    if (showSeparator) {
      final readMessagesInVisible =
          shouldShowPlaceholder ? 10 : scenario.readMessages;
      final placeholderOffset = shouldShowPlaceholder ? 1 : 0;
      separatorIndex = placeholderOffset + readMessagesInVisible;
    }

    // Calculate total item count
    var itemCount = visibleMessages.length;
    if (shouldShowPlaceholder) itemCount += 1; // Add placeholder
    if (showSeparator) itemCount += 1; // Add separator

    if (scenario.totalMessages == 0) {
      return const Center(
        child: Text('No messages to display'),
      );
    }

    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // Show placeholder as first item
        if (shouldShowPlaceholder && index == 0) {
          return SkippedMessagesPlaceholder(
            messageCount: messagesToSkip,
            onTap: _onTapPlaceholder,
          );
        }

        // Show separator at calculated position
        if (showSeparator && index == separatorIndex) {
          return const MessageSeparator(
            label: 'New messages',
          );
        }

        // Calculate message index, accounting for placeholder and separator
        var messageIndex = index;
        if (shouldShowPlaceholder) messageIndex -= 1; // Account for placeholder
        if (showSeparator && separatorIndex != null && index > separatorIndex)
          messageIndex -= 1; // Account for separator

        final messageNumber = visibleMessages[messageIndex] + 1;
        final isOwnMessage = messageNumber % 3 == 0;

        // Determine message type for display
        String messageType;
        Color? messageColor;
        Color? borderColor;

        if (messageNumber <= scenario.readMessages - messagesToSkip) {
          messageType = 'Read';
          messageColor = Theme.of(context).colorScheme.surfaceVariant;
          borderColor = null;
        } else if (messageNumber <= scenario.readMessages) {
          messageType = 'Context';
          messageColor = Theme.of(context).colorScheme.surfaceVariant;
          borderColor = Theme.of(context).colorScheme.primary.withOpacity(0.3);
        } else {
          messageType = 'Unread';
          messageColor = null;
          borderColor =
              Theme.of(context).colorScheme.secondary.withOpacity(0.3);
        }

        return Container(
          alignment:
              isOwnMessage ? Alignment.centerRight : Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: messageColor ??
                  (isOwnMessage
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surfaceVariant),
              borderRadius: BorderRadius.circular(16),
              border: borderColor != null
                  ? Border.all(color: borderColor, width: 1)
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Message $messageNumber',
                  style: TextStyle(
                    color: isOwnMessage && messageColor == null
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: messageType == 'Context'
                            ? Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.2)
                            : messageType == 'Unread'
                                ? Theme.of(context)
                                    .colorScheme
                                    .secondary
                                    .withOpacity(0.2)
                                : Theme.of(context)
                                    .colorScheme
                                    .outline
                                    .withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        messageType,
                        style: TextStyle(
                          color: messageType == 'Context'
                              ? Theme.of(context).colorScheme.primary
                              : messageType == 'Unread'
                                  ? Theme.of(context).colorScheme.secondary
                                  : Theme.of(context).colorScheme.outline,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (messageType == 'Context') ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.visibility_outlined,
                        size: 12,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ] else if (messageType == 'Unread') ...[
                      const SizedBox(width: 4),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DemoScenario {
  final String name;
  final int totalMessages;
  final int readMessages;
  final String description;

  const _DemoScenario({
    required this.name,
    required this.totalMessages,
    required this.readMessages,
    required this.description,
  });
}
