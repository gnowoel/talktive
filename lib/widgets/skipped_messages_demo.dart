import 'package:flutter/material.dart';
import 'message_separator.dart';
import 'skipped_messages_placeholder.dart';

class SkippedMessagesDemo extends StatefulWidget {
  const SkippedMessagesDemo({super.key});

  @override
  State<SkippedMessagesDemo> createState() => _SkippedMessagesDemoState();
}

class _SkippedMessagesDemoState extends State<SkippedMessagesDemo> {
  int _additionalMessagesRevealed = 0;
  int _selectedScenario = 0;

  // Different scenarios to demonstrate
  final List<_DemoScenario> _scenarios = [
    _DemoScenario(
      name: 'Few Messages (20 total, 15 read)',
      totalMessages: 20,
      readMessages: 15,
      description: 'No placeholder - below 25 message threshold',
    ),
    _DemoScenario(
      name: 'Some Messages (80 total, 60 read)',
      totalMessages: 80,
      readMessages: 60,
      description: 'First 10 + skip + last 15 read + 20 unread messages',
    ),
    _DemoScenario(
      name: 'All Read (40 total, 40 read)',
      totalMessages: 40,
      readMessages: 40,
      description: 'No separator - all messages are read',
    ),
    _DemoScenario(
      name: 'Many Messages (150 total, 120 read)',
      totalMessages: 150,
      readMessages: 120,
      description: 'First 10 + progressive loading of skipped + last context',
    ),
  ];

  void _onTapPlaceholder() {
    setState(() {
      _additionalMessagesRevealed += 25;
    });
  }

  void _reset() {
    setState(() {
      _additionalMessagesRevealed = 0;
    });
  }

  void _changeScenario(int index) {
    setState(() {
      _selectedScenario = index;
      _additionalMessagesRevealed = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scenario = _scenarios[_selectedScenario];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dynamic Threshold Demo'),
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
                    'First 10 messages + skip placeholder + last 15 read messages for context',
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

            // Progress indicator
            if (_additionalMessagesRevealed > 0) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Revealed ${25 + _additionalMessagesRevealed} messages',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],

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
    // Always show first 10 messages + last 15 read messages as context
    final firstMessagesCount =
        scenario.readMessages >= 10 ? 10 : scenario.readMessages;
    final lastReadContextCount = 15 + _additionalMessagesRevealed;

    // Calculate messages to skip between first 10 and last context
    final totalContextShown = firstMessagesCount + lastReadContextCount;
    final shouldShowPlaceholder = scenario.readMessages > totalContextShown;
    final messagesToSkip = shouldShowPlaceholder
        ? (scenario.readMessages > totalContextShown
            ? scenario.readMessages - totalContextShown
            : 0)
        : 0;

    // Determine if we should show separator
    final showSeparator = scenario.readMessages > 0 &&
        scenario.totalMessages > scenario.readMessages;

    // Calculate item positions
    final placeholderIndex = shouldShowPlaceholder ? firstMessagesCount : -1;
    int? separatorIndex;
    if (showSeparator) {
      if (shouldShowPlaceholder) {
        separatorIndex = firstMessagesCount + 1 + lastReadContextCount;
      } else {
        separatorIndex = scenario.readMessages;
      }
    }

    // Calculate total item count
    var itemCount = 0;
    if (shouldShowPlaceholder) {
      itemCount += firstMessagesCount; // First 10 messages
      itemCount += 1; // Placeholder
      itemCount += lastReadContextCount; // Last 15 read messages
    } else {
      itemCount += scenario.readMessages; // All read messages (no placeholder)
    }
    if (showSeparator) itemCount += 1; // Add separator
    itemCount +=
        (scenario.totalMessages - scenario.readMessages); // Add unread messages

    if (scenario.totalMessages == 0) {
      return const Center(
        child: Text('No messages to display'),
      );
    }

    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // Handle first 10 messages (always shown)
        if (shouldShowPlaceholder && index < firstMessagesCount) {
          final messageNumber = index + 1;
          return _buildMessageItem(messageNumber, 'First 10', scenario);
        }

        // Show placeholder
        if (shouldShowPlaceholder && index == placeholderIndex) {
          return SkippedMessagesPlaceholder(
            messageCount: messagesToSkip,
            onTap: _onTapPlaceholder,
          );
        }

        // Handle last read context messages (after placeholder)
        if (shouldShowPlaceholder &&
            index < firstMessagesCount + 1 + lastReadContextCount) {
          final contextIndex = index - firstMessagesCount - 1;
          final messageNumber =
              scenario.readMessages - lastReadContextCount + contextIndex + 1;
          return _buildMessageItem(messageNumber, 'Last Context', scenario);
        }

        // Show separator at calculated position
        if (showSeparator && index == separatorIndex) {
          return const MessageSeparator(
            label: 'New messages',
          );
        }

        // Handle unread messages or remaining read messages
        final separatorOffset = showSeparator ? 1 : 0;
        final contextOffset = shouldShowPlaceholder
            ? firstMessagesCount + 1 + lastReadContextCount
            : scenario.readMessages;
        final messageNumber = scenario.readMessages +
            (index - contextOffset - separatorOffset) +
            1;
        return _buildMessageItem(messageNumber, 'Unread', scenario);
      },
    );
  }

  Widget _buildMessageItem(
      int messageNumber, String messageType, _DemoScenario scenario) {
    final isOwnMessage = messageNumber % 3 == 0;

    // Determine message styling
    Color? messageColor;
    Color? borderColor;

    if (messageType == 'First 10') {
      messageColor = Theme.of(context).colorScheme.surfaceVariant;
      borderColor = Theme.of(context).colorScheme.tertiary.withOpacity(0.3);
    } else if (messageType == 'Last Context') {
      messageColor = Theme.of(context).colorScheme.surfaceVariant;
      borderColor = Theme.of(context).colorScheme.primary.withOpacity(0.3);
    } else if (messageType == 'Unread') {
      messageColor = null;
      borderColor = Theme.of(context).colorScheme.secondary.withOpacity(0.3);
    } else {
      messageColor = Theme.of(context).colorScheme.surfaceVariant;
      borderColor = null;
    }

    return Container(
      alignment: isOwnMessage ? Alignment.centerRight : Alignment.centerLeft,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: messageType == 'First 10'
                        ? Theme.of(context)
                            .colorScheme
                            .tertiary
                            .withOpacity(0.2)
                        : messageType == 'Last Context'
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
                      color: messageType == 'First 10'
                          ? Theme.of(context).colorScheme.tertiary
                          : messageType == 'Last Context'
                              ? Theme.of(context).colorScheme.primary
                              : messageType == 'Unread'
                                  ? Theme.of(context).colorScheme.secondary
                                  : Theme.of(context).colorScheme.outline,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (messageType == 'First 10') ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.priority_high,
                    size: 12,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ] else if (messageType == 'Last Context') ...[
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
