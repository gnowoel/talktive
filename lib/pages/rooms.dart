import 'package:flutter/material.dart';

import '../models/room.dart';
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
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const lines = ['No more rooms here.', 'Create one?', ''];

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surfaceContainerLow,
        title: const Text('Rooms'),
      ),
      body: SafeArea(
        child: widget.rooms.isEmpty
            ? const Center(child: Info(lines: lines))
            : _buildLayout(),
      ),
    );
  }

  LayoutBuilder _buildLayout() {
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
              child: RoomList(rooms: widget.rooms),
            ),
          );
        } else {
          return Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
            ),
            child: RoomList(rooms: widget.rooms),
          );
        }
      },
    );
  }
}
