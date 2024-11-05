import 'package:flutter/material.dart';

import '../models/room.dart';
import 'room_item.dart';

class RoomList extends StatefulWidget {
  final List<Room> rooms;

  const RoomList({
    super.key,
    required this.rooms,
  });

  @override
  State<RoomList> createState() => _RoomListState();
}

class _RoomListState extends State<RoomList> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      itemCount: widget.rooms.length,
      itemBuilder: (context, index) {
        return RoomItem(room: widget.rooms[index]);
      },
    );
  }
}
