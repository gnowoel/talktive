import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart';

import '../models/room.dart';
import '../pages/chat.dart';

class RoomItem extends StatefulWidget {
  final Room room;

  const RoomItem({
    super.key,
    required this.room,
  });

  @override
  State<RoomItem> createState() => _RoomItemState();
}

class _RoomItemState extends State<RoomItem> {
  void enterChat(Room room) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          room: widget.room,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final createdAt =
        DateTime.fromMillisecondsSinceEpoch(widget.room.createdAt);

    final cardColor = colorScheme.surfaceContainerHigh;
    final textColor = colorScheme.onSurface;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: cardColor,
      child: GestureDetector(
        onTap: () => enterChat(widget.room),
        child: ListTile(
          leading: Text(
            widget.room.userCode,
            style: TextStyle(fontSize: 36, color: textColor),
          ),
          title: Text(
            widget.room.topic,
            style: TextStyle(color: textColor),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            format(createdAt),
            style: TextStyle(color: textColor),
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            icon: const Icon(Icons.keyboard_arrow_right),
            onPressed: () => enterChat(widget.room),
            tooltip: 'Enter room',
          ),
        ),
      ),
    );
  }
}
