import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/helpers.dart';
import '../models/chat.dart';
import '../services/cache.dart';
import '../widgets/chat_list.dart';
import '../widgets/info.dart';

class ChatsPage extends StatefulWidget {
  const ChatsPage({super.key});

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  late Cache cache;
  late List<Chat> _chats;
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

    if (_chats.isEmpty) return;

    _timer?.cancel();

    final times = _chats.map((chat) => getTimeLeft(chat)).toList();
    times.sort();
    final nextTime = times.first;

    _timer = Timer(Duration(milliseconds: nextTime), () {
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
            : _buildLayout(_chats),
      ),
    );
  }

  LayoutBuilder _buildLayout(List<Chat> chats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final theme = Theme.of(context);
        if (constraints.maxWidth >= 600) {
          return Align(
            alignment: Alignment.center,
            child: Container(
              margin: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.all(Radius.circular(24)),
                border: Border.all(color: theme.colorScheme.secondaryContainer),
              ),
              constraints: const BoxConstraints(minWidth: 324, maxWidth: 576),
              child: ChatList(chats: chats),
            ),
          );
        } else {
          return Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
            ),
            child: ChatList(chats: chats),
          );
        }
      },
    );
  }
}
