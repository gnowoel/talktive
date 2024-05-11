import 'package:flutter/material.dart';

import '../models/message.dart';
import 'bubble.dart';

class MessageItem extends StatelessWidget {
  final Message message;

  const MessageItem({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.userCode,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 8),
          Bubble(content: message.content),
        ],
      ),
    );
  }
}
