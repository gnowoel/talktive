import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/topic_message.dart';
import '../services/topic_message_cache.dart';
import 'message_separator.dart';
import 'skipped_messages_placeholder.dart';
import 'topic_text_message_item.dart';
import 'topic_image_message_item.dart';

class TopicMessageList extends StatefulWidget {
  final String topicId;
  final String topicCreatorId;
  final FocusNode focusNode;
  final ScrollController scrollController;
  final void Function(int) updateMessageCount;
  final void Function(String)? onInsertMention;
  final int? readMessageCount;

  const TopicMessageList({
    super.key,
    required this.topicId,
    required this.topicCreatorId,
    required this.focusNode,
    required this.scrollController,
    required this.updateMessageCount,
    this.onInsertMention,
    this.readMessageCount,
  });

  @override
  State<TopicMessageList> createState() => _TopicMessageListState();
}

class _TopicMessageListState extends State<TopicMessageList> {
  late TopicMessageCache topicMessageCache;
  List<TopicMessage> _messages = [];
  bool _isSticky = true;
  int _additionalMessagesRevealed = 0;
  ScrollNotification? _lastNotification;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_handleInputFocus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    topicMessageCache = Provider.of<TopicMessageCache>(context);
    final messages = topicMessageCache.getMessages(widget.topicId);

    if (messages.length != _messages.length) {
      widget.updateMessageCount(messages.length);
    }

    _messages = messages;
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleInputFocus);
    super.dispose();
  }

  void _handleInputFocus() {
    if (widget.scrollController.hasClients && widget.focusNode.hasFocus) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    final controller = widget.scrollController;
    final bottom = controller.position.maxScrollExtent;
    controller.jumpTo(bottom);
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    final metrics = notification.metrics;

    if (_lastNotification.runtimeType != notification.runtimeType) {
      _lastNotification = notification;

      if (notification is ScrollEndNotification) {
        if (metrics.extentAfter == 0) {
          if (!_isSticky) {
            setState(() => _isSticky = true);
          }
        }
      }

      if (notification is ScrollUpdateNotification) {
        if (metrics.extentAfter != 0) {
          if (_isSticky) {
            setState(() => _isSticky = false);
          }
        }
      }
    }

    return false;
  }

  bool _handleScrollMetricsNotification(
    ScrollMetricsNotification notification,
  ) {
    if (_isSticky) {
      _scrollToBottom();
    }
    return false;
  }

  bool _shouldShowPlaceholder() {
    if (_messages.isEmpty) return false; // No messages to show placeholder for

    final readCount = widget.readMessageCount ?? 0;
    final totalMessagesToShow = 25 + _additionalMessagesRevealed;
    return readCount >
        totalMessagesToShow; // Show placeholder if more messages available
  }

  void _showAllMessagesPressed() {
    setState(() {
      _additionalMessagesRevealed += 25;
    });
    // Scroll to bottom after showing more messages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.scrollController.hasClients) {
        _scrollToBottom();
      }
    });
  }

  Widget _buildMessageListView() {
    final showPlaceholder = _shouldShowPlaceholder();
    final readCount = widget.readMessageCount ?? 0;

    // Calculate how many messages to skip and show
    // Skip oldest messages but keep context messages (25 + additional revealed)
    final totalMessagesToShow = 25 + _additionalMessagesRevealed;
    final messagesToSkip =
        showPlaceholder ? readCount - totalMessagesToShow : 0;
    final visibleMessages = _messages.skip(messagesToSkip).toList();

    // Determine if we should show separator
    final showSeparator = readCount > 0 && // There are read messages
        _messages.length > readCount; // There are unread messages

    // Calculate separator position in the item list
    int? separatorIndex;
    if (showSeparator) {
      final totalMessagesToShow = 25 + _additionalMessagesRevealed;
      final readMessagesInVisible =
          showPlaceholder ? totalMessagesToShow : readCount;
      final placeholderOffset = showPlaceholder ? 1 : 0;
      separatorIndex = placeholderOffset + readMessagesInVisible;
    }

    // Calculate total item count
    var itemCount = visibleMessages.length;
    if (showPlaceholder) itemCount += 1; // Add placeholder
    if (showSeparator) itemCount += 1; // Add separator

    return NotificationListener<ScrollMetricsNotification>(
      onNotification: _handleScrollMetricsNotification,
      child: NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: ListView.builder(
          controller: widget.scrollController,
          itemCount: itemCount,
          itemBuilder: (context, index) {
            // Show placeholder as first item
            if (showPlaceholder && index == 0) {
              return SkippedMessagesPlaceholder(
                messageCount: messagesToSkip,
                onTap: _showAllMessagesPressed,
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
            if (showPlaceholder) messageIndex -= 1; // Account for placeholder
            if (showSeparator && index > separatorIndex!)
              messageIndex -= 1; // Account for separator

            final message = visibleMessages[messageIndex];

            if (message is TopicImageMessage) {
              return TopicImageMessageItem(
                topicId: widget.topicId,
                key: ValueKey(message.id),
                message: message,
                onInsertMention: widget.onInsertMention,
              );
            }

            return TopicTextMessageItem(
              key: ValueKey(message.id),
              topicId: widget.topicId,
              topicCreatorId: widget.topicCreatorId,
              message: message as TopicTextMessage,
              onInsertMention: widget.onInsertMention,
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_messages.isEmpty) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 3));
    }

    return Listener(
      onPointerDown: (details) => FocusScope.of(context).unfocus(),
      onPointerMove: (details) => FocusScope.of(context).unfocus(),
      child: _buildMessageListView(),
    );
  }
}
