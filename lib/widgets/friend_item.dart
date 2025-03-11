import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../helpers/helpers.dart';
import '../models/friend.dart';
import '../services/fireauth.dart';
import '../services/messaging.dart';
import '../services/server_clock.dart';
import '../theme.dart';
import 'tag.dart';
import 'user_info_loader.dart';

class FriendItem extends StatefulWidget {
  final Friend friend;

  const FriendItem({
    super.key,
    required this.friend,
  });

  @override
  State<FriendItem> createState() => _FriendItemState();
}

class _FriendItemState extends State<FriendItem> {
  late Fireauth fireauth;

  @override
  void initState() {
    super.initState();
    fireauth = context.read<Fireauth>();
  }

  void _showUserInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return UserInfoLoader(
          userId: widget.friend.id,
          photoURL: widget.friend.userPhotoURL,
          displayName: widget.friend.userDisplayName,
        );
      },
    );
  }

  void _enterChat() {
    final userId = fireauth.instance.currentUser!.uid;
    final friend = widget.friend;
    final chatId = ([userId, friend.id]..sort()).join();

    context.go('/chats');
    context.push(
      Messaging.encodeChatRoute(chatId, friend.userDisplayName),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final customColors = theme.extension<CustomColors>()!;
    final now = DateTime.fromMillisecondsSinceEpoch(ServerClock().now);
    final createdAt =
        DateTime.fromMillisecondsSinceEpoch(widget.friend.createdAt);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: colorScheme.surfaceContainerHigh,
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
        leading: GestureDetector(
          onTap: () => _showUserInfo(context),
          child: Text(
            widget.friend.userPhotoURL,
            style: TextStyle(fontSize: 36),
          ),
        ),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.loyalty,
              size: 16,
              color: customColors.friendIndicator,
            ),
            const SizedBox(width: 4),
            Text(
              widget.friend.userDisplayName,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              formatText(widget.friend.userDescription),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(height: 1.2),
              maxLines: 2,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Tag(
                  tooltip: 'Friends since',
                  child: Text(
                    timeago.format(createdAt, locale: 'en_short', clock: now),
                    style: TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.chat_outlined),
          onPressed: _enterChat,
          tooltip: 'Chat',
        ),
      ),
    );
  }
}
