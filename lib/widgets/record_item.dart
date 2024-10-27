import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart';

import '../models/record.dart';
import '../models/room.dart';
import '../pages/chat.dart';
import '../services/history.dart';

class RecordItem extends StatefulWidget {
  final Record record;

  const RecordItem({
    super.key,
    required this.record,
  });

  @override
  State<RecordItem> createState() => _RecordItemState();
}

class _RecordItemState extends State<RecordItem> {
  late History history;

  @override
  void initState() {
    super.initState();
    history = Provider.of<History>(context, listen: false);
  }

  void enterChat(Record record) {
    final dummy = Room.fromRecord(record: record);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          room: dummy,
          recordMessageCount: record.messageCount,
          recordScrollOffset: record.scrollOffset,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final byMe = widget.record.roomUserId == 'me';
    final createdAt =
        DateTime.fromMillisecondsSinceEpoch(widget.record.createdAt);

    final cardColor =
        byMe ? colorScheme.tertiaryContainer : colorScheme.surfaceContainerHigh;
    final textColor =
        byMe ? colorScheme.onTertiaryContainer : colorScheme.onSurface;

    final roomId = widget.record.roomId;

    return Dismissible(
      key: Key(roomId),
      onDismissed: (direction) async {
        await history.removeRecord(roomId: roomId);
      },
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6),
        color: cardColor,
        child: GestureDetector(
          onTap: () => enterChat(widget.record),
          child: ListTile(
            leading: Text(
              widget.record.roomUserCode,
              style: TextStyle(fontSize: 36, color: textColor),
            ),
            title: Text(
              widget.record.roomTopic,
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
              onPressed: () => enterChat(widget.record),
              tooltip: 'Enter room',
            ),
          ),
        ),
      ),
    );
  }
}
