import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/topic.dart';
import '../services/fireauth.dart';
import '../services/firestore.dart';
import 'topic_item_card.dart';

class ChatList extends StatefulWidget {
  final List<Topic> items;

  const ChatList({super.key, required this.items});

  @override
  State<ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  static const Duration _undoDuration = Duration(seconds: 4);

  late List<Topic> _items;

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
    for (final timer in _undoTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  void _updateItems() {
    _items = widget.items
        .where((item) => !_removedItemIds.contains(item.id))
        .toList();
  }

  Future<void> _muteTopic(Topic topic) async {
    try {
      final currentUserId = context.read<Fireauth>().instance.currentUser!.uid;
      await context.read<Firestore>().muteTopic(currentUserId, topic.id);
    } catch (e) {
      debugPrint('Error muting topic: $e');
    }
  }

  void _removeTopic(Topic topic) {
    if (_removedItemIds.contains(topic.id)) {
      return;
    }

    setState(() {
      _removedItemIds.add(topic.id);
      _updateItems();
    });

    _lastSwipedItemId = topic.id;

    _undoTimers[topic.id]?.cancel();
    _undoTimers[topic.id] = Timer(_undoDuration, () {
      _muteTopic(topic);
      _undoTimers.remove(topic.id);
      if (mounted && _lastSwipedItemId == topic.id) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
    });

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(topic.isTwoPersonTopic ? 'Left chat' : 'Left moment'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => _restoreTopic(topic),
        ),
        duration: _undoDuration,
      ),
    );
  }

  void _restoreTopic(Topic topic) {
    _undoTimers[topic.id]?.cancel();
    _undoTimers.remove(topic.id);

    setState(() {
      _removedItemIds.remove(topic.id);
      _updateItems();
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final topic = _items[index];
        return TopicItemCard(
          key: ValueKey(topic.id),
          topic: topic,
          onRemove: _removeTopic,
        );
      },
    );
  }
}
