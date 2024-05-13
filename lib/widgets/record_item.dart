import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart';

import '../models/record.dart';
import '../models/room.dart';
import '../pages/chat.dart';
import '../services/fireauth.dart';

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
  void enterChat(Record record) {
    final dummy = Room.fromRecord(record: record);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChatPage(room: dummy)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fireauth = Provider.of<Fireauth>(context, listen: false);
    final byMe = widget.record.roomUserId == fireauth.instance.currentUser!.uid;
    final createdAt =
        DateTime.fromMillisecondsSinceEpoch(widget.record.createdAt);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: byMe ? Colors.amber[50] : null,
      child: GestureDetector(
        onTap: () => enterChat(widget.record),
        child: ListTile(
          leading: Text(
            widget.record.roomUserCode,
            style: const TextStyle(fontSize: 36),
          ),
          title: Text(
            widget.record.roomUserName,
          ),
          subtitle: Text(
            format(createdAt),
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            icon: const Icon(Icons.keyboard_arrow_right),
            onPressed: () => enterChat(widget.record),
          ),
        ),
      ),
    );
  }
}
