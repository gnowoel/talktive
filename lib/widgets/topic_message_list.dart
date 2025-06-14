import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/topic_message.dart';
import '../services/topic_message_cache.dart';
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
  bool _showAllMessages = false;
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
    if (_showAllMessages) return false; // User chose to see all messages
    if (_messages.isEmpty) return false; // No messages to show placeholder for

    final readCount = widget.readMessageCount ?? 0;
    return readCount > 0;
  }

  void _showAllMessagesPressed() {
    setState(() {
      _showAllMessages = true;
    });
    // Scroll to bottom after showing all messages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.scrollController.hasClients) {
        _scrollToBottom();
      }
    });
  }

  Widget _buildPlaceholder() {
    final readCount = widget.readMessageCount ?? 0;

    return Column(
      children: [
        Expanded(
          child: Center(
            child: SkippedMessagesPlaceholder(
              messageCount: readCount,
              onTap: _showAllMessagesPressed,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageListView() {
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: _handleScrollMetricsNotification,
      child: NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: ListView.builder(
          controller: widget.scrollController,
          itemCount: _messages.length,
          itemBuilder: (context, index) {
            final message = _messages[index];

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
      child: _shouldShowPlaceholder()
          ? _buildPlaceholder()
          : _buildMessageListView(),
    );
  }
}
