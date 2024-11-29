import 'package:flutter/material.dart';

import '../models/chat.dart';
import '../models/image_message.dart';
import '../models/message.dart';
import '../models/text_message.dart';
import 'image_message_item.dart';
import 'info.dart';
import 'text_message_item.dart';

class MessageList extends StatefulWidget {
  final FocusNode focusNode;
  final ScrollController scrollController;
  final Chat chat;
  final List<Message> messages;

  const MessageList({
    super.key,
    required this.focusNode,
    required this.scrollController,
    required this.chat,
    required this.messages,
  });

  @override
  State<MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  ScrollNotification? _lastNotification;
  bool _isSticky = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_handleInputFocus);
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
    return widget.messages.isEmpty;
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
    const lines = ['Say hi or send a picture', 'to your new friend.'];

    return const SizedBox.expand(
      child: AbsorbPointer(
        child: Info(lines: lines),
      ),
    );
  }

  Widget _buildListView(BuildContext context) {
    return ListView.builder(
      controller: widget.scrollController,
      itemCount: widget.messages.length,
      itemBuilder: (context, index) {
        final message = widget.messages[index];

        if (message is ImageMessage) {
          return ImageMessageItem(
            message: message,
          );
        }

        return TextMessageItem(
          message: message as TextMessage,
        );
      },
    );
  }
}
