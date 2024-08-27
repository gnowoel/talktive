import 'package:flutter/material.dart';

import '../models/room.dart';
import '../widgets/health.dart';

class ChatAppBar extends StatefulWidget implements PreferredSizeWidget {
  final Room room;

  const ChatAppBar({
    super.key,
    required this.room,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<ChatAppBar> createState() => _ChatAppBarState();
}

class _ChatAppBarState extends State<ChatAppBar> {
  late ThemeData theme;

  bool _isEditable = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
  }

  void _handleTap() {
    setState(() {
      _isEditable = true;
    });
  }

  void _handleCheck() {
    setState(() {
      _isEditable = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: widget.room.topic);

    if (_isEditable) {
      return AppBar(
        backgroundColor: theme.colorScheme.surfaceContainerLow,
        title: TextField(
          controller: controller,
        ),
        actions: [
          IconButton(
            onPressed: _handleCheck,
            icon: const Icon(Icons.check),
          ),
          const SizedBox(width: 16),
        ],
      );
    } else {
      return AppBar(
        backgroundColor: theme.colorScheme.surfaceContainerLow,
        title: GestureDetector(
          onTap: _handleTap,
          child: Text(widget.room.topic),
        ),
        actions: [
          Health(room: widget.room),
          const SizedBox(width: 16),
        ],
      );
    }
  }
}
