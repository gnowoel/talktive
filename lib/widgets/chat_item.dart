import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../helpers/helpers.dart';
import '../models/chat.dart';
import '../models/user.dart';
import '../services/cache.dart';
import '../services/fireauth.dart';
import '../services/firedata.dart';
import '../services/messaging.dart';
import 'tag.dart';
import 'user_info_loader.dart';

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
  late Firedata firedata;
  late bool byMe;
  late UserStub _partner;

  @override
  void initState() {
    super.initState();
    fireauth = context.read<Fireauth>();
    firedata = context.read<Firedata>();
    byMe = widget.chat.firstUserId == fireauth.instance.currentUser!.uid;
    _partner = widget.chat.partner;
  }

  Future<void> _muteChat() async {
    _doAction(() async {
      await firedata.updateChat(
        fireauth.instance.currentUser!.uid,
        widget.chat.id,
        mute: true,
      );
    });
  }

  Future<void> _enterChat() async {
    _doAction(() async {
      final chat = widget.chat;

      context.go('/chats');
      context
          .push(Messaging.encodeChatRoute(chat.id, _partner.displayName ?? ''));
    });
  }

  Future<void> _doAction(Future<void> Function() action) async {
    try {
      await action();
    } on AppException catch (e) {
      if (mounted) {
        ErrorHandler.showSnackBarMessage(context, e);
      }
    }
  }

  void _showUserInfo(BuildContext context) {
    final userId = fireauth.instance.currentUser!.uid;
    final otherId = widget.chat.id.replaceFirst(userId, '');

    showDialog(
      context: context,
      builder: (context) => UserInfoLoader(
        userId: otherId,
        photoURL: _partner.photoURL ?? '',
        displayName: _partner.displayName ?? '',
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
        (widget.chat.lastMessageContent ?? _partner.description!)
            .replaceAll(RegExp(r'\s+'), ' ');

    final revivedAt =
        DateTime.fromMillisecondsSinceEpoch(_partner.revivedAt ?? 0);
    final alert = now.isBefore(revivedAt);

    return Dismissible(
      key: Key(widget.chat.id),
      background: Icon(
        Icons.delete,
        color: colorScheme.error,
      ),
      onDismissed: (direction) async {
        await _muteChat();
      },
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6),
        color: cardColor,
        child: GestureDetector(
          onTap: _enterChat,
          child: ListTile(
            leading: GestureDetector(
              onTap: () => _showUserInfo(context),
              child: Text(
                _partner.photoURL!,
                style: TextStyle(fontSize: 36, color: textColor),
              ),
            ),
            title: Text(
              _partner.displayName!,
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
                      tooltip: '${getLongGenderName(_partner.gender!)}',
                      child: Text(
                        _partner.gender!,
                        style: TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Tag(
                      tooltip: '${getLanguageName(_partner.languageCode!)}',
                      child: Text(
                        _partner.languageCode!,
                        style: TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Tag(
                      tooltip: 'Last updated',
                      child: Text(
                        timeago.format(updatedAt,
                            locale: 'en_short', clock: now),
                        style: TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (alert) ...[
                      const SizedBox(width: 4),
                      Tag(
                        tooltip: 'Reported for inappropriate behavior',
                        child: Text(
                          'alert',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onErrorContainer,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        isCritical: true,
                      ),
                    ],
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
      ),
    );
  }
}
