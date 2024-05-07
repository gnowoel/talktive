import 'package:flutter/material.dart';

import '../models/room.dart';

class MessageList extends StatelessWidget {
  final Room room;

  const MessageList({
    super.key,
    required this.room,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(room.userCode),
    );
  }
}
