import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../helpers/helpers.dart';
import '../models/chat.dart';
import '../models/user.dart';
import '../services/fireauth.dart';
import '../services/firedata.dart';
import '../services/messaging.dart';
import '../services/server_clock.dart';
import 'tag.dart';
import 'user_info_loader.dart';

class ChatItem extends StatefulWidget {
  final Chat chat;
  final Function(Chat) onRemove;
  final Function(Chat) onRestore;

  const ChatItem({
    super.key,
    required this.chat,
    required this.onRemove,
    required this.onRestore,
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

  void _handleDismiss(DismissDirection direction) {
    // Remove the chat from the list
    widget.onRemove(widget.chat);

    // Show snackbar with undo option
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context)
        .showSnackBar(
          SnackBar(
            content: const Text('Chat deleted'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                // Restore the chat
                widget.onRestore(widget.chat);
              },
            ),
            duration: const Duration(seconds: 5),
          ),
        )
        .closed
        .then((reason) {
      // Only mute the chat if the SnackBar was closed by timeout
      // and not by user action (pressing undo)
      if (reason == SnackBarClosedReason.timeout) {
        _muteChat();
      }
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
    final now = DateTime.fromMillisecondsSinceEpoch(ServerClock().now);
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

    final userStatus =
        getUserStatus(User.fromStub(key: '', value: _partner), now);

    return Dismissible(
      key: Key(widget.chat.id),
      background: Container(
        color: colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16.0),
        child: Icon(
          Icons.delete,
          color: colorScheme.onError,
        ),
      ),
      direction: DismissDirection.endToStart, // Only allow right to left swipe
      onDismissed: _handleDismiss,
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 12),
        color: cardColor,
        child: GestureDetector(
          onTap: _enterChat,
          child: ListTile(
            // contentPadding: const EdgeInsets.symmetric(
            //   horizontal: 16,
            //   vertical: 8, // Add some vertical padding
            // ),
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
                  style: TextStyle(
                    height: 1.2,
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 4),
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
                    if (userStatus == 'alert') ...[
                      const SizedBox(width: 4),
                      Tag(
                        status: 'alert',
                        tooltip: 'Reported for offensive messages',
                        child: Text(
                          'alert',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onTertiaryContainer,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ] else if (userStatus == 'warning') ...[
                      const SizedBox(width: 4),
                      Tag(
                        status: 'warning',
                        tooltip: 'Reported for inappropriate behavior',
                        child: Text(
                          'warning',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onErrorContainer,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
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
