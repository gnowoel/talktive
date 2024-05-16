import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/message.dart';
import '../models/room.dart';
import '../services/firedata.dart';
import '../services/history.dart';
import '../widgets/health.dart';
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
  late Firedata firedata;
  late History history;
  late StreamSubscription subscription;
  List<Message>? _messages;

  @override
  void initState() {
    super.initState();

    firedata = Provider.of<Firedata>(context, listen: false);
    history = Provider.of<History>(context, listen: false);

    _addHistoryRecord();

    subscription = firedata.receiveMessages(widget.room.id).listen((messages) {
      setState(() {
        _messages = messages;
      });
    });
  }

  @override
  void dispose() {
    subscription.cancel();
    _addHistoryRecord();
    super.dispose();
  }

  Future<void> _addHistoryRecord() async {
    await history.saveRecord(widget.room);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.room.userName),
        actions: const [
          Health(),
          SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          if (constraints.maxWidth >= 600) {
            return Align(
              alignment: Alignment.center,
              child: Container(
                margin: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: const BorderRadius.all(
                    Radius.circular(24),
                  ),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                constraints: const BoxConstraints(minWidth: 324, maxWidth: 576),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Expanded(
                      child: MessageList(
                        roomUserId: widget.room.userId,
                        messages: _messages ?? <Message>[],
                      ),
                    ),
                    Input(roomId: widget.room.id),
                  ],
                ),
              ),
            );
          } else {
            return Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Expanded(
                    child: MessageList(
                      roomUserId: widget.room.userId,
                      messages: _messages ?? <Message>[],
                    ),
                  ),
                  Input(roomId: widget.room.id),
                ],
              ),
            );
          }
        }),
      ),
    );
  }
}
