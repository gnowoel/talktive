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

    // Always show first 10 messages + last 15 read messages as context
    final firstMessagesCount = readCount >= 10 ? 10 : readCount;
    final lastReadContextCount = 15 + _additionalMessagesRevealed;

    // Calculate messages to skip between first 10 and last context
    final totalContextShown = firstMessagesCount + lastReadContextCount;
    final messagesToSkip = showPlaceholder
        ? (readCount > totalContextShown ? readCount - totalContextShown : 0)
        : 0;

    // Determine if we should show separator
    final showSeparator = readCount > 0 && // There are read messages
        _messages.length > readCount; // There are unread messages

    // Calculate item positions
    final placeholderIndex = showPlaceholder ? firstMessagesCount : -1;
    int? separatorIndex;
    if (showSeparator) {
      if (showPlaceholder) {
        separatorIndex = firstMessagesCount + 1 + lastReadContextCount;
      } else {
        separatorIndex = readCount;
      }
    }

    // Calculate total item count
    var itemCount = 0;
    if (showPlaceholder) {
      itemCount += firstMessagesCount; // First 10 messages
      itemCount += 1; // Placeholder
      itemCount += lastReadContextCount; // Last 15 read messages
    } else {
      itemCount += readCount; // All read messages (no placeholder)
    }
    if (showSeparator) itemCount += 1; // Add separator
    itemCount += (_messages.length - readCount); // Add unread messages

    return NotificationListener<ScrollMetricsNotification>(
      onNotification: _handleScrollMetricsNotification,
      child: NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: ListView.builder(
          controller: widget.scrollController,
          itemCount: itemCount,
          itemBuilder: (context, index) {
            // Handle first 10 messages (always shown)
            if (showPlaceholder && index < firstMessagesCount) {
              final message = _messages[index];
              return _buildMessageItem(message);
            }

            // Show placeholder
            if (showPlaceholder && index == placeholderIndex) {
              return SkippedMessagesPlaceholder(
                messageCount: messagesToSkip,
                onTap: _showAllMessagesPressed,
              );
            }

            // Handle last read context messages (after placeholder)
            if (showPlaceholder &&
                index < firstMessagesCount + 1 + lastReadContextCount) {
              final contextIndex = index - firstMessagesCount - 1;
              final messageIndex =
                  readCount - lastReadContextCount + contextIndex;
              final message = _messages[messageIndex];
              return _buildMessageItem(message);
            }

            // Show separator at calculated position
            if (showSeparator && index == separatorIndex) {
              return const MessageSeparator(
                label: 'New messages',
              );
            }

            // Handle unread messages or remaining read messages
            final separatorOffset = showSeparator ? 1 : 0;
            final contextOffset = showPlaceholder
                ? firstMessagesCount + 1 + lastReadContextCount
                : readCount;
            final messageIndex =
                readCount + (index - contextOffset - separatorOffset);
            final message = _messages[messageIndex];
            return _buildMessageItem(message);
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

  Widget _buildMessageItem(TopicMessage message) {
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
  }
}
