import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chat.dart';
import '../services/cache.dart';
import '../widgets/chat_list.dart';
import '../widgets/info.dart';

class ChatsPage extends StatefulWidget {
  final List<Chat> chats;

  const ChatsPage({super.key, required this.chats});

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  late Cache cache;
  late List<Chat> _chats;

  @override
  void initState() {
    super.initState();
    _chats = widget.chats;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    cache = Provider.of<Cache>(context);
    if (_chats != cache.chats) {
      setState(() => _chats = cache.chats);
    }
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
              child: ChatList(chats: _chats),
            ),
          );
        } else {
          return Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
            ),
            child: ChatList(chats: _chats),
          );
        }
      },
    );
  }
}
