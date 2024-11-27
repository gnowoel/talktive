import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../models/chat.dart';
import 'tag.dart';

class ChatItem extends StatefulWidget {
  final Chat chat;

  const ChatItem({
    super.key,
    required this.chat,
  });

  @override
  State<StatefulWidget> createState() => _ChatItemState();
}

class _ChatItemState extends State<ChatItem> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final updatedAt =
        DateTime.fromMillisecondsSinceEpoch(widget.chat.updatedAt);

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
            widget.chat.partner.photoURL!,
            style: TextStyle(fontSize: 36, color: textColor),
          ),
          title: Text(
            widget.chat.partner.displayName!,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.chat.lastMessageContent ??
                    widget.chat.partner.description!,
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                children: [
                  Tag(
                    child: Text(
                      widget.chat.partner.gender!,
                      style: TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Tag(
                    child: Text(
                      widget.chat.partner.languageCode!,
                      style: TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Tag(
                    child: Text(
                      timeago.format(updatedAt, locale: 'en_short'),
                      style: TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // trailing: Icon(Icons.check_circle_outline),
          trailing: Badge(
            label: const Text('7', style: TextStyle(fontSize: 14)),
            backgroundColor: colorScheme.error,
          ),
        ),
      ),
    );
  }
}
