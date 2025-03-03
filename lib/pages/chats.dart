import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../helpers/helpers.dart';
import '../models/chat.dart';
import '../services/cache.dart';
import '../services/message_cache.dart';
import '../widgets/chat_list.dart';
import '../widgets/info.dart';
import '../widgets/layout.dart';

class ChatsPage extends StatefulWidget {
  const ChatsPage({super.key});

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  late Cache cache;
  late MessageCache messageCache;
  List<Chat> _chats = [];
  Timer? _timer;

  @override
  initState() {
    super.initState();
    messageCache = context.read<MessageCache>();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // TODO: Cache chats in a separate class.
    cache = Provider.of<Cache>(context);
    _setChatsAgain();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _setChatsAgain() {
    final activeChats = <Chat>[];
    final inactiveChats = <Chat>[];

    for (final chat in cache.chats) {
      if (chat.isActive) {
        activeChats.add(chat);
      } else {
        inactiveChats.add(chat);
      }
    }

    if (inactiveChats.isNotEmpty) {
      SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
        final inactiveChatIds = inactiveChats.map((chat) => chat.id).toList();
        messageCache.clear(inactiveChatIds);
      });
    }

    _chats = activeChats;
    final nextTime = getNextTime(_chats);
    if (nextTime == null) return;

    final duration = Duration(milliseconds: nextTime);
    _timer?.cancel();
    _timer = Timer(duration, () {
      setState(() {
        _setChatsAgain();
      });
    });
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Text('Quick Tips'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'If you receive inappropriate messages, please use the report feature to help keep our community safe.',
              style: TextStyle(height: 1.5),
            ),
            SizedBox(height: 16),
            Text(
              'You can swipe left or right on any chat to mute it if you no longer wish to participate.',
              style: TextStyle(height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const lines = ['Please add some', 'more users first.', ''];

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surfaceContainerLow,
        title: const Text('Recent chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
            tooltip: 'Help',
          ),
        ],
      ),
      body: SafeArea(
        child: _chats.isEmpty
            ? Center(child: Info(lines: lines))
            : Layout(child: ChatList(chats: _chats)),
      ),
    );
  }
}
