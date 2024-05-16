import 'package:flutter/material.dart';

import '../models/message.dart';
import 'message_item.dart';

class MessageList extends StatelessWidget {
  final String roomUserId;
  final List<Message> messages;

  const MessageList({
    super.key,
    required this.roomUserId,
    required this.messages,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: messages.length,
      itemBuilder: (context, index) {
        return MessageItem(
          roomUserId: roomUserId,
          message: messages[index],
        );
      },
    );
  }
}
