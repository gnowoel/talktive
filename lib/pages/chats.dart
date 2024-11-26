import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chat.dart';
import '../services/fireauth.dart';
import '../services/firedata.dart';

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

  @override
  void initState() {
    super.initState();

    fireauth = Provider.of<Fireauth>(context, listen: false);
    firedata = Provider.of<Firedata>(context, listen: false);
    _chats = [];

    final userId = fireauth.instance.currentUser!.uid;
    chatsSubscription = firedata.subscribeToChats(userId).listen((chats) {
      setState(() => _chats = chats);
    });
  }

  @override
  void dispose() {
    chatsSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
      ),
      body: SafeArea(
        child: ListView.builder(
          itemCount: _chats.length,
          itemBuilder: (context, index) {
            return Text(_chats[index].partner.displayName!);
          },
        ),
      ),
    );
  }
}
