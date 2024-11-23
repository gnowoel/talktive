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
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.user.description!,
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                children: [
                  Tag(
                    child: Text(
                      widget.user.gender!,
                      style: TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Tag(
                    child: Text(
                      widget.user.languageCode!,
                      style: TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Tag(
                    child: Text(
                      format(updatedAt, locale: 'en_short'),
                      style: TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.keyboard_arrow_right),
            onPressed: () => {},
            tooltip: 'Chat now',
          ),
        ),
      ),
    );
  }
}

class Tag extends StatelessWidget {
  final Widget child;

  const Tag({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(top: 6, bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceBright,
        border: Border.all(color: theme.colorScheme.inversePrimary),
        borderRadius: BorderRadius.all(
          Radius.circular(16),
        ),
      ),
      child: child,
    );
  }
}
