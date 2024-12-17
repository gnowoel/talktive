import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/helpers.dart';
import '../models/chat.dart';
import '../services/cache.dart';
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
  List<Chat> _chats = [];
  Timer? _timer;

  @override
  initState() {
    super.initState();
    _chats = [];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // TODO: Cache chats in a separate class.
    cache = Provider.of<Cache>(context);
    _setChatsAndTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _setChatsAndTimer() {
    _chats = cache.chats.where((chat) => chat.isActive).toList();

    final nextTime = getNextTime(_chats);

    if (nextTime == null) return;

    final duration = Duration(
      milliseconds: nextTime,
    );

    _timer?.cancel();

    _timer = Timer(duration, () {
      setState(() {
        _setChatsAndTimer();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const lines = ['Your recent chats', 'will appear here.', ''];

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surfaceContainerLow,
        title: const Text('Chats'),
      ),
      body: SafeArea(
        child: _chats.isEmpty
            ? Center(child: Info(lines: lines))
            : Layout(child: ChatList(chats: _chats)),
      ),
    );
  }
}
