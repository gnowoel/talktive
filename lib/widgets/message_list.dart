import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/message.dart';
import '../models/room.dart';
import '../services/firedata.dart';
import 'message_item.dart';

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

  @override
  void initState() {
    super.initState();
    firedata = Provider.of<Firedata>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: firedata.receiveMessages(widget.room.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('${snapshot.error}');
        } else if (!snapshot.hasData) {
          return const SizedBox();
        } else {
          final messages = snapshot.data as List<Message>;
          return ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              return MessageItem(
                roomUserId: widget.room.userId,
                message: messages[index],
              );
            },
          );
        }
      },
    );
  }
}
