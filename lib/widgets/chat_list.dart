import 'package:flutter/material.dart';

import '../models/room.dart';
import '../models/chat.dart';
import '../models/topic.dart';
import 'chat_item_card.dart';
import 'topic_item_card.dart';

class ChatList extends StatefulWidget {
  final List<Room> items;

  const ChatList({super.key, required this.items});

  @override
  State<ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  late List<Room> _items;
  final Set<String> _removedItemIds = {};

  @override
  void initState() {
    super.initState();
    _updateItems();
  }

  @override
  void didUpdateWidget(ChatList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items != oldWidget.items) {
      // Remove IDs from _removedItemIds if they are no longer in the new list
      // (assuming backend has processed the removal)
      final newItemIds = widget.items.map((e) => e.id).toSet();
      _removedItemIds.removeWhere((id) => !newItemIds.contains(id));

      _updateItems();
    }
  }

  void _updateItems() {
    _items = widget.items
        .where((item) => !_removedItemIds.contains(item.id))
        .toList();
  }

  void _removeItem(Room item) {
    setState(() {
      _removedItemIds.add(item.id);
      _updateItems();
    });
  }

  void _restoreItem(Room item) {
    setState(() {
      _removedItemIds.remove(item.id);
      _updateItems();
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
          return ChatItemCard(
            key: ValueKey(item.id),
            chat: item,
            onRemove: _removeItem,
            onRestore: _restoreItem,
          );
        } else if (item is Topic) {
          return TopicItemCard(
            key: ValueKey(item.id),
            topic: item,
            onRemove: _removeItem,
            onRestore: _restoreItem,
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
