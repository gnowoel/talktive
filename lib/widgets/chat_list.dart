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

  static const Duration _undoDuration = Duration(seconds: 4);

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
      final newItemIds = widget.items.map((e) => e.id).toSet();

      final removedIdsNowGone =
          _removedItemIds.where((id) => !newItemIds.contains(id)).toList();
      for (final id in removedIdsNowGone) {
        _removedItemIds.remove(id);
        _undoTimers.remove(id)?.cancel();
        if (_lastSwipedItemId == id) {
          _lastSwipedItemId = null;
        }
      }

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
    if (_removedItemIds.contains(item.id)) {
      return;
    }

    // 1. Optimistic remove
    setState(() {
      _removedItemIds.add(item.id);
      _updateItems();
    });

    _lastSwipedItemId = item.id;

    // 2. Schedule actual mute/leave
    _undoTimers[item.id]?.cancel();
    _undoTimers[item.id] = Timer(_undoDuration, () {
      _muteItem(item);
      _undoTimers.remove(item.id);
      if (mounted) {
        if (_lastSwipedItemId == item.id) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        }
      }
    });

    // 3. Show SnackBar (purely visual/interactive now)
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
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
        duration: _undoDuration,
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
