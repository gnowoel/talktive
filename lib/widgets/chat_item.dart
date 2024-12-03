import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../helpers/helpers.dart';
import '../models/chat.dart';
import '../pages/chat.dart';
import '../services/cache.dart';
import '../services/fireauth.dart';
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
  late Fireauth fireauth;
  late bool byMe;

  @override
  void initState() {
    super.initState();
    fireauth = context.read<Fireauth>();
    byMe = widget.chat.firstUserId == fireauth.instance.currentUser!.uid;
  }

  void enterChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(chat: widget.chat),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.fromMillisecondsSinceEpoch(Cache().now);
    final updatedAt =
        DateTime.fromMillisecondsSinceEpoch(widget.chat.updatedAt);

    final cardColor =
        byMe ? colorScheme.tertiaryContainer : colorScheme.surfaceContainerHigh;
    final textColor =
        byMe ? colorScheme.onTertiaryContainer : colorScheme.onSurface;

    final newMessageCount = chatUnreadMessageCount(widget.chat);
    final lastMessageContent =
        (widget.chat.lastMessageContent ?? widget.chat.partner.description!)
            .replaceAll(RegExp(r'\s+'), ' ');

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: cardColor,
      child: GestureDetector(
        onTap: enterChat,
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
                lastMessageContent,
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
                      timeago.format(updatedAt, locale: 'en_short', clock: now),
                      style: TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: newMessageCount > 0
              ? Badge(
                  label: Text(
                    '$newMessageCount',
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                  backgroundColor: colorScheme.error,
                )
              : Badge(
                  label: Text(
                    '$newMessageCount',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.surfaceContainerLow,
                    ),
                  ),
                  backgroundColor: colorScheme.outline,
                ),
        ),
      ),
    );
  }
}
