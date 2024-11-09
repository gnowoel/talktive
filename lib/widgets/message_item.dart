import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/message.dart';
import '../services/fireauth.dart';
import 'bubble.dart';

class MessageItem extends StatelessWidget {
  final String roomUserId;
  final Message message;

  const MessageItem({
    super.key,
    required this.roomUserId,
    required this.message,
  });

  bool get _isBot => message.userId == 'bot';

  @override
  Widget build(BuildContext context) {
    final fireauth = Provider.of<Fireauth>(context, listen: false);
    final currentUser = fireauth.instance.currentUser!;
    final byMe = message.userId == currentUser.uid;

    // Bot messages are always shown on the left
    return byMe ? _buildMessageItemRight() : _buildMessageItemLeft();
  }

  Widget _buildMessageItemLeft() {
    final byOp = message.userId == roomUserId;

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Tooltip(
            message: message.userName,
            child: Text(
              message.userCode,
              style: const TextStyle(fontSize: 24),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Flexible(
                  child: Bubble(
                    content: message.content,
                    byOp: byOp,
                    isBot: _isBot,
                  ),
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
                  child: Bubble(
                    content: message.content,
                    byMe: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: message.userName,
            child: Text(
              message.userCode,
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ],
      ),
    );
  }
}
