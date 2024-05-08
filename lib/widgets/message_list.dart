import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/message.dart';
import '../models/room.dart';
import '../services/firedata.dart';

class MessageList extends StatefulWidget {
  final Room room;

  const MessageList({
    super.key,
    required this.room,
  });

  @override
  State<MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  late Firedata firedata;
  late StreamSubscription subscription;
  var messages = <Message>[];

  @override
  void initState() {
    super.initState();

    firedata = Provider.of<Firedata>(context, listen: false);
    final stream = firedata.receiveMessages(widget.room.id!);

    subscription = stream.listen((event) {
      setState(() {
        messages = event;
      });
    });
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: messages.length,
      itemBuilder: (context, index) {
        return Text(messages[index].content);
      },
    );
  }
}
