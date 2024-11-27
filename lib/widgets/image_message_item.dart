import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/image_message.dart';
import '../services/fireauth.dart';

class ImageMessageItem extends StatelessWidget {
  final ImageMessage message;

  const ImageMessageItem({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final fireauth = Provider.of<Fireauth>(context, listen: false);
    final currentUser = fireauth.instance.currentUser!;
    final byMe = message.userId == currentUser.uid;

    // Bot messages are always shown on the left
    return byMe ? _buildMessageItemRight() : _buildMessageItemLeft();
  }

  Widget _buildMessageItemLeft() {
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network(message.uri),
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network(message.uri),
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
