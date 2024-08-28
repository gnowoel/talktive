import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/room.dart';
import '../services/fireauth.dart';
import '../services/firedata.dart';
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
  late Fireauth fireauth;
  late Firedata firedata;

  bool _isEditable = false;

  @override
  void initState() {
    super.initState();
    fireauth = Provider.of<Fireauth>(context, listen: false);
    firedata = Provider.of<Firedata>(context, listen: false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
  }

  void _handleTap() {
    setState(() => _isEditable = true);
  }

  void _handleCheck(Room room, String topic) {
    firedata.updateRoomTopic(room, topic);
    setState(() => _isEditable = false);
  }

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: widget.room.topic);
    final currentUserId = fireauth.instance.currentUser!.uid;
    final isOp = widget.room.userId == currentUserId;

    if (isOp && _isEditable) {
      return AppBar(
        backgroundColor: theme.colorScheme.surfaceContainerLow,
        title: TextField(controller: controller),
        actions: [
          IconButton(
            onPressed: () => _handleCheck(widget.room, controller.text),
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
