import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/image_message.dart';
import '../models/message.dart';
import '../models/text_message.dart';
import '../services/message_cache.dart';
import 'image_message_item.dart';
import 'info.dart';
import 'text_message_item.dart';

class MessageList extends StatefulWidget {
  final String chatId;
  final FocusNode focusNode;
  final ScrollController scrollController;
  final void Function(int) updateMessageCount;
  final String? reporterUserId;
  final bool isSticky;

  const MessageList({
    super.key,
    required this.chatId,
    required this.focusNode,
    required this.scrollController,
    required this.updateMessageCount,
    this.reporterUserId,
    this.isSticky = true,
  });

  @override
  State<MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  late bool _isSticky;
  late MessageCache messageCache;
  List<Message> _messages = [];
  ScrollNotification? _lastNotification;

  @override
  void initState() {
    super.initState();
    _isSticky = widget.isSticky;
    widget.focusNode.addListener(_handleInputFocus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    messageCache = Provider.of<MessageCache>(context);

    final messages = messageCache.getMessages(widget.chatId);
    if (messages.length != _messages.length) {
      _messages = messages;
      widget.updateMessageCount(messages.length);
    }
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
      ScrollMetricsNotification notification) {
    if (_isSticky) {
      _scrollToBottom();
    }
    return false;
  }

  bool _isNew() {
    return _messages.isEmpty;
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
      child: AbsorbPointer(
        child: Info(lines: lines),
      ),
    );
  }

  Widget _buildListView(BuildContext context) {
    return ListView.builder(
      controller: widget.scrollController,
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];

        if (message is ImageMessage) {
          return ImageMessageItem(
            key: ValueKey(message.id),
            message: message,
            reporterUserId: widget.reporterUserId,
          );
        }

        return TextMessageItem(
          key: ValueKey(message.id),
          message: message as TextMessage,
          reporterUserId: widget.reporterUserId,
        );
      },
    );
  }
}
