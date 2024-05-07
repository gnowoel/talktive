import 'package:flutter/material.dart';

import '../models/room.dart';
import '../widgets/input_field.dart';
import '../widgets/message_list.dart';

class ChatPage extends StatelessWidget {
  final Room room;

  const ChatPage({
    super.key,
    required this.room,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text(room.userName),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: MessageList(room: room),
            ),
            InputField(room: room),
          ],
        ),
      ),
    );
  }
}
