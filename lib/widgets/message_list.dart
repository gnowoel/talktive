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
  final messages = <Message>[const Message(content: 'First message.')];

  @override
  void initState() {
    super.initState();

    firedata = Provider.of<Firedata>(context, listen: false);

    final ref = firedata.instance.ref('messages/${widget.room.id}');

    ref.onChildAdded.listen((event) {
      final value = event.snapshot.value;
      final Map<String, dynamic> json = Map<String, dynamic>.from(value as Map);
      final message = Message.fromJson(json);

      setState(() {
        messages.add(message);
      });
    });
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
