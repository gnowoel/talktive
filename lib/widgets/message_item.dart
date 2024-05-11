import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/message.dart';
import '../services/fireauth.dart';
import 'bubble.dart';

class MessageItem extends StatelessWidget {
  final Message message;

  const MessageItem({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final fireauth = Provider.of<Fireauth>(context, listen: false);
    final currentUser = fireauth.instance.currentUser!;
    final byMe = message.userId == currentUser.uid;

    return byMe ? _buildMessageItemRight() : _buildMessageItemLeft();
  }

  Widget _buildMessageItemLeft() {
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
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Flexible(
                  child: Bubble(content: message.content),
                ),
              ],
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildMessageItemRight() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const SizedBox(width: 48),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Bubble(content: message.content),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            message.userCode,
            style: const TextStyle(fontSize: 24),
          ),
        ],
      ),
    );
  }
}
