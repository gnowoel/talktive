import 'package:flutter/material.dart';

import '../models/message.dart';
import '../models/room.dart';
import 'info.dart';
import 'message_item.dart';

class MessageList extends StatefulWidget {
  final FocusNode focusNode;
  final ScrollController scrollController;
  final void Function(double) updateScrollOffset;
  final Room room;
  final List<Message> messages;

  const MessageList({
    super.key,
    required this.focusNode,
    required this.scrollController,
    required this.updateScrollOffset,
    required this.room,
    required this.messages,
  });

  @override
  State<MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  ScrollNotification? _lastNotification;

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
        widget.updateScrollOffset(metrics.pixels);
      }
    }

    return false;
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleInputFocus);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.room.isNew) {
      return _buildInfo();
    }

    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: widget.messages.isEmpty ? _buildEmpty() : _buildListView(context),
    );
  }

  Widget _buildInfo() {
    const lines = ['Send a message.', 'Then just wait.'];

    return const SizedBox.expand(
      child: AbsorbPointer(
        child: Info(lines: lines),
      ),
    );
  }

  Widget _buildEmpty() {
    return const SizedBox();
  }

  Widget _buildListView(BuildContext context) {
    return ListView.builder(
      controller: widget.scrollController,
      itemCount: widget.messages.length,
      itemBuilder: (context, index) {
        return MessageItem(
          roomUserId: widget.room.userId,
          message: widget.messages[index],
        );
      },
    );
  }
}
