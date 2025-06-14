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
  bool _showAllMessages = false;

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
    if (widget.reporterUserId != null)
      return false; // Never show placeholder in admin reports
    if (_showAllMessages) return false; // User chose to see all messages
    if (_isNew()) return false; // New chat, show info instead

    final readCount = widget.chat.readMessageCount ?? 0;
    return readCount > 25; // Only skip if more than 25 messages
  }

  void _showAllMessagesPressed() {
    setState(() {
      _showAllMessages = true;
    });
    // Scroll to bottom after showing more messages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.scrollController.hasClients) {
        _scrollToBottom();
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

    // Calculate how many messages to skip and show
    // Skip oldest messages but keep last 25 read messages for context
    final messagesToSkip = showPlaceholder ? readCount - 25 : 0;
    final visibleMessages = _messages.skip(messagesToSkip).toList();

    // Determine if we should show separator
    final showSeparator = widget.reporterUserId == null && // Not in admin view
        readCount > 0 && // There are read messages
        _messages.length > readCount; // There are unread messages

    // Calculate separator position in the item list
    int? separatorIndex;
    if (showSeparator) {
      final readMessagesInVisible = showPlaceholder ? 25 : readCount;
      final placeholderOffset = showPlaceholder ? 1 : 0;
      separatorIndex = placeholderOffset + readMessagesInVisible;
    }

    // Calculate total item count
    var itemCount = visibleMessages.length;
    if (showPlaceholder) itemCount += 1; // Add placeholder
    if (showSeparator) itemCount += 1; // Add separator

    return ListView.builder(
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
      },
    );
  }
}
