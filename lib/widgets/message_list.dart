import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/image_message.dart';
import '../models/message.dart';
import '../models/chat.dart';
import '../models/text_message.dart';
import '../services/message_cache.dart';
import 'image_message_item.dart';
import 'info.dart';
import 'message_separator.dart';
import 'skipped_messages_placeholder.dart';
import 'text_message_item.dart';

class MessageList extends StatefulWidget {
  final Chat chat;
  final FocusNode focusNode;
  final ScrollController scrollController;
  final void Function(int) updateMessageCount;
  final String? reporterUserId;
  final bool isSticky;
  final void Function(String)? onInsertMention;

  const MessageList({
    super.key,
    required this.chat,
    required this.focusNode,
    required this.scrollController,
    required this.updateMessageCount,
    this.reporterUserId,
    this.isSticky = true,
    this.onInsertMention,
  });

  @override
  State<MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  late bool _isSticky;
  late ChatMessageCache chatMessageCache;
  late ReportMessageCache reportMessageCache;
  List<Message> _messages = [];
  ScrollNotification? _lastNotification;
  int _additionalMessagesRevealedUp = 0;
  int _additionalMessagesRevealedDown = 0;

  @override
  void initState() {
    super.initState();
    _isSticky = widget.isSticky;
    widget.focusNode.addListener(_handleInputFocus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // TODO: Split into two separate widgets to improve performance
    chatMessageCache = Provider.of<ChatMessageCache>(context);
    reportMessageCache = Provider.of<ReportMessageCache>(context);

    final messages = widget.reporterUserId == null
        ? chatMessageCache.getMessages(widget.chat)
        : reportMessageCache.getMessages(widget.chat);

    if (messages.length != _messages.length) {
      // We don't update the read message count in admin reports
      if (widget.reporterUserId == null) {
        widget.updateMessageCount(messages.length);
      }
    }

    _messages = messages;
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

  bool _isNew() {
    return widget.chat.isDummy || _messages.isEmpty;
  }

  bool _shouldShowPlaceholder() {
    if (widget.reporterUserId != null) {
      return false; // Never show placeholder in admin reports
    }
    if (_isNew()) return false; // New chat, show info instead

    final readCount = widget.chat.readMessageCount ?? 0;
    final totalMessagesToShow =
        25 + _additionalMessagesRevealedUp + _additionalMessagesRevealedDown;
    return readCount > totalMessagesToShow;
  }

  void _showMoreMessagesUp() {
    if (!widget.scrollController.hasClients) return;

    // Capture current scroll position
    final currentOffset = widget.scrollController.offset;

    setState(() {
      _additionalMessagesRevealedUp += 25;
    });

    // Preserve scroll position after rebuild
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.scrollController.hasClients) {
        widget.scrollController.jumpTo(currentOffset);
      }
    });
  }

  void _showMoreMessagesDown() {
    if (!widget.scrollController.hasClients) return;

    // Capture current scroll position
    final currentOffset = widget.scrollController.offset;

    setState(() {
      _additionalMessagesRevealedDown += 25;
    });

    // Preserve scroll position after rebuild
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.scrollController.hasClients) {
        widget.scrollController.jumpTo(currentOffset);
      }
    });
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleInputFocus);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (details) => FocusScope.of(context).unfocus(),
      onPointerMove: (details) => FocusScope.of(context).unfocus(),
      child: NotificationListener<ScrollMetricsNotification>(
        onNotification: _handleScrollMetricsNotification,
        child: NotificationListener<ScrollNotification>(
          onNotification: _handleScrollNotification,
          child: _isNew() ? _buildInfo() : _buildListView(context),
        ),
      ),
    );
  }

  Widget _buildInfo() {
    const lines = ['Say hi or send a photo', 'to your new friend.'];

    return const SizedBox.expand(
      child: AbsorbPointer(child: Info(lines: lines)),
    );
  }

  Widget _buildListView(BuildContext context) {
    final showPlaceholder = _shouldShowPlaceholder();
    final readCount = widget.chat.readMessageCount ?? 0;

    // Always show first 10 messages + last 15 read messages as context
    final baseFirstCount = readCount >= 10 ? 10 : readCount;
    final firstMessagesCount =
        (baseFirstCount + _additionalMessagesRevealedDown).clamp(0, readCount);

    final baseLastCount = 15;
    final maxContextCount =
        (readCount - firstMessagesCount).clamp(0, readCount);
    final lastReadContextCount = (baseLastCount + _additionalMessagesRevealedUp)
        .clamp(0, maxContextCount);

    // Calculate messages to skip between first 10 and last context
    final totalContextShown = firstMessagesCount + lastReadContextCount;
    final messagesToSkip = showPlaceholder
        ? (readCount > totalContextShown ? readCount - totalContextShown : 0)
        : 0;

    // Determine if we should show separator
    final showSeparator = widget.reporterUserId == null && // Not in admin view
        readCount > 0 && // There are read messages
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
    final unreadCount =
        (_messages.length - readCount).clamp(0, _messages.length);
    itemCount += unreadCount; // Add unread messages

    return ListView.builder(
      controller: widget.scrollController,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // Handle first 10 messages (always shown)
        if (showPlaceholder && index < firstMessagesCount) {
          if (index >= _messages.length) return const SizedBox.shrink();
          final message = _messages[index];
          return _buildMessageItem(message);
        }

        // Show placeholder
        if (showPlaceholder && index == placeholderIndex) {
          return SkippedMessagesPlaceholder(
            messageCount: messagesToSkip,
            onTapUp: _showMoreMessagesUp,
            onTapDown: _showMoreMessagesDown,
          );
        }

        // Handle last read context messages (after placeholder)
        if (showPlaceholder &&
            index < firstMessagesCount + 1 + lastReadContextCount) {
          final contextIndex = index - firstMessagesCount - 1;
          final messageIndex = readCount - lastReadContextCount + contextIndex;

          // Add bounds checking to prevent range errors
          if (messageIndex < 0 ||
              messageIndex >= _messages.length ||
              contextIndex < 0 ||
              messageIndex < firstMessagesCount) {
            return const SizedBox.shrink();
          }

          final message = _messages[messageIndex];
          return _buildMessageItem(message);
        }

        // Handle all read messages when no placeholder is shown
        if (!showPlaceholder && index < readCount) {
          if (index >= _messages.length) return const SizedBox.shrink();
          final message = _messages[index];
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

        // Add bounds checking to prevent range errors
        if (messageIndex < 0 || messageIndex >= _messages.length) {
          return const SizedBox.shrink();
        }

        final message = _messages[messageIndex];
        return _buildMessageItem(message);
      },
    );
  }

  Widget _buildMessageItem(Message message) {
    if (message is ImageMessage) {
      return ImageMessageItem(
        key: ValueKey(message.id),
        chatId: widget.chat.id,
        message: message,
        reporterUserId: widget.reporterUserId,
        onInsertMention: widget.onInsertMention,
      );
    }

    return TextMessageItem(
      key: ValueKey(message.id),
      chatId: widget.chat.id,
      message: message as TextMessage,
      reporterUserId: widget.reporterUserId,
      onInsertMention: widget.onInsertMention,
    );
  }
}
