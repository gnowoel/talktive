import 'package:flutter/material.dart';

import '../models/chat.dart';
import 'chat_item.dart';

class ChatList extends StatefulWidget {
  final List<Chat> chats;

  const ChatList({
    super.key,
    required this.chats,
  });

  @override
  State<ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  late List<Chat> _chats;

  @override
  void initState() {
    super.initState();
    _chats = List.from(widget.chats);
  }

  @override
  void didUpdateWidget(ChatList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.chats != oldWidget.chats) {
      _chats = List.from(widget.chats);
    }
  }

  void _removeChat(Chat chat) {
    setState(() {
      _chats.remove(chat);
    });
  }

  void _restoreChat(Chat chat, int index) {
    setState(() {
      _chats.insert(index, chat);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      itemCount: _chats.length,
      itemBuilder: (context, index) {
        final chat = _chats[index];
        return ChatItem(
          key: ValueKey(chat.id),
          chat: chat,
          onRemove: _removeChat,
          onRestore: (chat) => _restoreChat(chat, index),
        );
      },
    );
  }
}
