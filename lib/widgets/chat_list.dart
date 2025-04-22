import 'package:flutter/material.dart';

import '../models/chat.dart';
import '../models/private_chat.dart';
import '../models/public_topic.dart';
import 'private_chat_item.dart';
import 'public_topic_item.dart';

class ChatList extends StatefulWidget {
  final List<Chat> items;

  const ChatList({super.key, required this.items});

  @override
  State<ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  late List<Chat> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.items);
  }

  @override
  void didUpdateWidget(ChatList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items != oldWidget.items) {
      _items = List.from(widget.items);
    }
  }

  void _removeItem(Chat item) {
    setState(() {
      _items.remove(item);
    });
  }

  void _restoreItem(Chat item, int index) {
    setState(() {
      _items.insert(index, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];

        if (item is PrivateChat) {
          return PrivateChatItem(
            key: ValueKey(item.id),
            chat: item,
            onRemove: _removeItem,
            onRestore: (chat) => _restoreItem(chat, index),
          );
        } else if (item is PublicTopic) {
          return PublicTopicItem(
            key: ValueKey(item.id),
            topic: item,
            onRemove: _removeItem,
            onRestore: (topic) => _restoreItem(topic, index),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
