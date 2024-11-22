import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart';

import '../models/user.dart';

class UserItem extends StatefulWidget {
  final User user;

  const UserItem({
    super.key,
    required this.user,
  });

  @override
  State<UserItem> createState() => _UserItemState();
}

class _UserItemState extends State<UserItem> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final updatedAt =
        DateTime.fromMillisecondsSinceEpoch(widget.user.updatedAt);

    final cardColor = colorScheme.surfaceContainerHigh;
    final textColor = colorScheme.onSurface;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: cardColor,
      child: GestureDetector(
        onTap: () {},
        child: ListTile(
          leading: Text(
            widget.user.photoURL!,
            style: TextStyle(fontSize: 36, color: textColor),
          ),
          title: Text(
            widget.user.displayName!,
            style: TextStyle(color: textColor),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            format(updatedAt),
            style: TextStyle(color: textColor),
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            icon: const Icon(Icons.keyboard_arrow_right),
            onPressed: () => {},
            tooltip: 'Chat',
          ),
        ),
      ),
    );
  }
}
