import 'package:flutter/material.dart';

import '../models/room.dart';
import '../models/chat.dart';
import '../models/topic.dart';
import 'chat_item.dart';
import 'topic_item_card.dart';

class ChatList extends StatefulWidget {
  final List<Room> items;

  const ChatList({super.key, required this.items});

  @override
  State<ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  late List<Room> _items;

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

  void _removeItem(Room item) {
    setState(() {
      _items.remove(item);
    });
  }

  void _restoreItem(Room item, int index) {
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

        if (item is Chat) {
          return ChatItem(
            key: ValueKey(item.id),
            chat: item,
            onRemove: _removeItem,
            onRestore: (chat) => _restoreItem(chat, index),
          );
        } else if (item is Topic) {
          return TopicItemCard(
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
