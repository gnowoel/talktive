import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:talktive/helpers/helpers.dart';

import '../models/room.dart';
import '../services/history.dart';
import '../widgets/info.dart';
import '../widgets/room_list.dart';

class RoomsPage extends StatefulWidget {
  final List<Room> rooms;

  const RoomsPage({
    super.key,
    required this.rooms,
  });

  @override
  State<RoomsPage> createState() => _RoomsPageState();
}

class _RoomsPageState extends State<RoomsPage> {
  late History history;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    history = Provider.of<History>(context);
  }

  List<Room> _unvisitedRooms(List<Room> rooms) {
    final recentRoomIds = history.recentRoomIds;
    return rooms.where((room) => !recentRoomIds.contains(room.id)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const lines = ['No more rooms here.', 'Check history for replies.', ''];
    final rooms = _unvisitedRooms(widget.rooms);
    final languageCode = getLanguageCode(context);
    final languageName = getLanguageName(languageCode);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surfaceContainerLow,
        title: languageName == null
            ? const Text('Rooms')
            : Text('Rooms in $languageName'),
      ),
      body: SafeArea(
        child: rooms.isEmpty
            ? const Center(child: Info(lines: lines))
            : _buildLayout(rooms),
      ),
    );
  }

  LayoutBuilder _buildLayout(List<Room> rooms) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final theme = Theme.of(context);
        if (constraints.maxWidth >= 600) {
          return Align(
            alignment: Alignment.center,
            child: Container(
              margin: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.all(
                  Radius.circular(24),
                ),
                border: Border.all(color: theme.colorScheme.secondaryContainer),
              ),
              constraints: const BoxConstraints(minWidth: 324, maxWidth: 576),
              child: RoomList(rooms: rooms),
            ),
          );
        } else {
          return Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
            ),
            child: RoomList(rooms: rooms),
          );
        }
      },
    );
  }
}
