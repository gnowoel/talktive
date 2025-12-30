import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/room.dart';
import '../models/chat.dart';
import '../models/topic.dart';
import '../services/fireauth.dart';
import '../services/firestore.dart';
import '../services/firedata.dart';
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
  final Map<String, Timer> _undoTimers = {};
  String? _lastSwipedItemId;

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

      // Also clean up any timers for items that are gone effectively?
      // Actually strictly speaking we should let the timer fire to ensure mute happens
      // even if the list updates, unless the item comes back?
      // For safety, let's keep timers running unless explicitly restored.

      _updateItems();
    }
  }

  @override
  void dispose() {
    for (var timer in _undoTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  void _updateItems() {
    _items = widget.items
        .where((item) => !_removedItemIds.contains(item.id))
        .toList();
  }

  Future<void> _muteItem(Room item) async {
    try {
      final currentUserId = context.read<Fireauth>().instance.currentUser!.uid;
      if (item is Chat) {
        await context.read<Firedata>().muteChat(currentUserId, item.id);
      } else if (item is Topic) {
        await context.read<Firestore>().muteTopic(currentUserId, item.id);
      }
    } catch (e) {
      debugPrint('Error muting item: $e');
    }
  }

  void _removeItem(Room item) {
    // 1. Optimistic remove
    setState(() {
      _removedItemIds.add(item.id);
      _updateItems();
    });

    _lastSwipedItemId = item.id;

    // 2. Schedule actual mute/leave
    _undoTimers[item.id]?.cancel(); // Cancel any existing one just in case
    _undoTimers[item.id] = Timer(const Duration(seconds: 4), () {
      _muteItem(item);
      _undoTimers.remove(item.id);
      if (mounted) {
        // Optional: Local clean up if needed, but the list update from backend usually handles it
        // If this item is still the one showing the SnackBar, hide it
        if (_lastSwipedItemId == item.id) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        }
      }
    });

    // 3. Show SnackBar (purely visual/interactive now)
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          item is Topic && !item.isTwoPersonTopic ? 'Left moment' : 'Left chat',
        ),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            _restoreItem(item);
          },
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _restoreItem(Room item) {
    // Cancel the pending mute timer
    _undoTimers[item.id]?.cancel();
    _undoTimers.remove(item.id);

    setState(() {
      _removedItemIds.remove(item.id);
      _updateItems();
    });

    // Hide the SnackBar if we just undid it
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
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
          );
        } else if (item is Topic) {
          return TopicItemCard(
            key: ValueKey(item.id),
            topic: item,
            onRemove: _removeItem,
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
