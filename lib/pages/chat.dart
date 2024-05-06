import 'package:flutter/material.dart';

import '../models/room.dart';

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
        child: Center(
          child: Text('(${room.id})'),
        ),
      ),
    );
  }
}
