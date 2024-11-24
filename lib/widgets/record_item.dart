import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart';

import '../models/record.dart';
import '../models/room.dart';
import '../pages/room.dart';
import '../services/firedata.dart';
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
  late Firedata firedata;
  late History history;
  late StreamSubscription roomSubscription;

  late Room _room;

  @override
  void initState() {
    super.initState();

    firedata = Provider.of<Firedata>(context, listen: false);
    history = Provider.of<History>(context, listen: false);

    _room = Room.fromRecord(record: widget.record);

    roomSubscription =
        firedata.subscribeToRoom(widget.record.roomId).listen((room) {
      setState(() => _room = room);
    });
  }

  void enterRoom(Record record) {
    final dummy = Room.fromRecord(record: record);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoomPage(
          room: dummy,
          recordMessageCount: record.messageCount,
          recordScrollOffset: record.scrollOffset,
        ),
      ),
    );
  }

  @override
  void dispose() {
    roomSubscription.cancel();
    super.dispose();
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
        await history.hideRecord(roomId: roomId);
      },
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6),
        color: cardColor,
        child: GestureDetector(
          onTap: () => enterRoom(widget.record),
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
            trailing: _buildIconButton(),
          ),
        ),
      ),
    );
  }

  IconButton _buildIconButton() {
    final colorScheme = Theme.of(context).colorScheme;
    final hasNewMessages = _room.updatedAt > widget.record.roomUpdatedAt;

    if (!hasNewMessages) {
      return IconButton(
        icon: const Icon(Icons.keyboard_arrow_right),
        onPressed: () => enterRoom(widget.record),
        tooltip: 'Enter room',
      );
    }

    return IconButton(
      icon: Icon(
        Icons.keyboard_double_arrow_right,
        color: colorScheme.tertiary,
      ),
      onPressed: () => enterRoom(widget.record),
      tooltip: 'Enter room',
    );
  }
}
