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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const lines = ['Please add some', 'more users first.', ''];

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surfaceContainerLow,
        title: const Text('Recent chats'),
      ),
      body: SafeArea(
        child: _chats.isEmpty
            ? Center(child: Info(lines: lines))
            : Layout(child: ChatList(chats: _chats)),
      ),
    );
  }
}
