import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chat.dart';
import '../services/fireauth.dart';
import '../services/firedata.dart';
import '../widgets/chat_list.dart';
import '../widgets/info.dart';

class ChatsPage extends StatefulWidget {
  const ChatsPage({super.key});

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  late Fireauth fireauth;
  late Firedata firedata;
  late StreamSubscription chatsSubscription;
  late List<Chat> _chats;
  bool _isPopulated = false;

  @override
  void initState() {
    super.initState();

    fireauth = Provider.of<Fireauth>(context, listen: false);
    firedata = Provider.of<Firedata>(context, listen: false);
    _chats = [];

    final userId = fireauth.instance.currentUser!.uid;
    chatsSubscription = firedata.subscribeToChats(userId).listen((chats) {
      setState(() {
        _chats = chats;
        _isPopulated = true;
      });
    });
  }

  @override
  void dispose() {
    chatsSubscription.cancel();
    super.dispose();
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
            ? (_isPopulated
                ? Center(child: Info(lines: lines))
                : const SizedBox())
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
