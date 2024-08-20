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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      title: Text(widget.room.userName),
      actions: [
        Health(room: widget.room),
        const SizedBox(width: 16),
      ],
    );
  }
}
