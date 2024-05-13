import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/room.dart';
import '../services/history.dart';
import '../widgets/input.dart';
import '../widgets/message_list.dart';

class ChatPage extends StatefulWidget {
  final Room room;

  const ChatPage({
    super.key,
    required this.room,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late History history;

  @override
  void initState() {
    super.initState();
    history = Provider.of<History>(context, listen: false);
    _addHistoryRecord();
  }

  @override
  void dispose() {
    _addHistoryRecord();
    super.dispose();
  }

  Future<void> _addHistoryRecord() async {
    await history.saveRecord(widget.room);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text(widget.room.userName),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: MessageList(room: widget.room),
            ),
            Input(room: widget.room),
          ],
        ),
      ),
    );
  }
}
