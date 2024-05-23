import 'package:flutter/material.dart';

import '../models/message.dart';
import 'message_item.dart';

class MessageList extends StatefulWidget {
  final FocusNode focusNode;
  final ScrollController scrollController;
  final String roomUserId;
  final List<Message> messages;

  const MessageList({
    super.key,
    required this.focusNode,
    required this.scrollController,
    required this.roomUserId,
    required this.messages,
  });

  @override
  State<MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_handleInputFocus);
  }

  void _handleInputFocus() {
    if (widget.focusNode.hasFocus) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    final controller = widget.scrollController;
    final bottom = controller.position.maxScrollExtent;
    controller.jumpTo(bottom);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleInputFocus);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: widget.scrollController,
      itemCount: widget.messages.length,
      itemBuilder: (context, index) {
        return MessageItem(
          roomUserId: widget.roomUserId,
          message: widget.messages[index],
        );
      },
    );
  }
}
