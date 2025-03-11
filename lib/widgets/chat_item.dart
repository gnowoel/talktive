import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../helpers/helpers.dart';
import '../models/chat.dart';
import '../models/user.dart';
import '../services/fireauth.dart';
import '../services/firedata.dart';
import '../services/friend_cache.dart';
import '../services/messaging.dart';
import '../services/server_clock.dart';
import '../theme.dart';
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
  late FriendCache friendCache;
  late bool byMe;
  late User partner;
  late bool isFriend;

  @override
  void initState() {
    super.initState();
    fireauth = context.read<Fireauth>();
    firedata = context.read<Firedata>();

    final chatId = widget.chat.id;
    final selfId = fireauth.instance.currentUser!.uid;
    final otherId = chatId.replaceFirst(selfId, '');

    byMe = widget.chat.firstUserId == selfId;
    partner = User.fromStub(key: otherId, value: widget.chat.partner);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    friendCache = Provider.of<FriendCache>(context);
    isFriend = friendCache.isFriend(partner.id);
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
      context.push(
        Messaging.encodeChatRoute(chat.id, partner.displayName ?? ''),
      );
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
      builder:
          (context) => UserInfoLoader(
            userId: otherId,
            photoURL: partner.photoURL ?? '',
            displayName: partner.displayName ?? '',
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final customColors = theme.extension<CustomColors>()!;
    final now = DateTime.fromMillisecondsSinceEpoch(ServerClock().now);
    final updatedAt = DateTime.fromMillisecondsSinceEpoch(
      widget.chat.updatedAt,
    );

    final cardColor =
        byMe ? colorScheme.tertiaryContainer : colorScheme.surfaceContainerHigh;
    final textColor =
        byMe ? colorScheme.onTertiaryContainer : colorScheme.onSurface;

    final newMessageCount = chatUnreadMessageCount(widget.chat);
    final lastMessageContent = (widget.chat.lastMessageContent ??
            partner.description!)
        .replaceAll(RegExp(r'\s+'), ' ');

    final userStatus = partner.status;

    return Dismissible(
      key: Key(widget.chat.id),
      background: Container(
        color: colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16.0),
        child: Icon(Icons.delete, color: colorScheme.onError),
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
            contentPadding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
            leading: GestureDetector(
              onTap: () => _showUserInfo(context),
              child: Text(
                partner.photoURL!,
                style: TextStyle(fontSize: 36, color: textColor),
              ),
            ),
            title: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (isFriend) ...[
                  Icon(
                    Icons.loyalty,
                    size: 16,
                    color: customColors.friendIndicator,
                  ),
                  const SizedBox(width: 4),
                ],
                Text(partner.displayName!, overflow: TextOverflow.ellipsis),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  formatText(lastMessageContent),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(height: 1.2),
                  maxLines: 3,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Tag(
                      tooltip: '${getLongGenderName(partner.gender!)}',
                      child: Text(
                        partner.gender!,
                        style: TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Tag(
                      tooltip: '${getLanguageName(partner.languageCode!)}',
                      child: Text(
                        partner.languageCode!,
                        style: TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Tag(
                      tooltip: 'Level ${partner.level}',
                      child: Text(
                        'L${partner.level}',
                        style: TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Tag(
                      tooltip: 'Last updated',
                      child: Text(
                        timeago.format(
                          updatedAt,
                          locale: 'en_short',
                          clock: now,
                        ),
                        style: TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (userStatus == 'warning') ...[
                      const SizedBox(width: 4),
                      Tag(status: 'warning'),
                    ] else if (userStatus == 'alert') ...[
                      const SizedBox(width: 4),
                      Tag(status: 'alert'),
                    ] else if (userStatus == 'newcomer') ...[
                      const SizedBox(width: 4),
                      Tag(status: 'newcomer'),
                    ],
                  ],
                ),
              ],
            ),
            trailing:
                newMessageCount > 0
                    ? Badge(
                      label: Text(
                        '$newMessageCount',
                        style: TextStyle(fontSize: 14),
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
