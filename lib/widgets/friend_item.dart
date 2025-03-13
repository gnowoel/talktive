import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../helpers/helpers.dart';
import '../models/friend.dart';
import '../models/user.dart';
import '../services/chat_cache.dart';
import '../services/firedata.dart';
import '../services/friend_cache.dart';
import '../services/messaging.dart';
import '../services/server_clock.dart';
import '../services/user_cache.dart';
import '../theme.dart';
import 'tag.dart';
import 'user_info_loader.dart';

class FriendItem extends StatefulWidget {
  final Friend friend;

  const FriendItem({super.key, required this.friend});

  @override
  State<FriendItem> createState() => _FriendItemState();
}

class _FriendItemState extends State<FriendItem> {
  late Firedata firedata;
  late UserCache userCache;
  late ChatCache chatCache;
  late FriendCache friendCache;
  late bool isFriend;

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    firedata = context.read<Firedata>();
    userCache = context.read<UserCache>();
    chatCache = context.read<ChatCache>();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    friendCache = Provider.of<FriendCache>(context);
    isFriend = friendCache.isFriend(widget.friend.id);
  }

  void _showUserInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return UserInfoLoader(
          userId: widget.friend.id,
          photoURL: widget.friend.photoURL,
          displayName: widget.friend.displayName,
        );
      },
    );
  }

  Future<void> _enterChat() async {
    _doAction(() async {
      final userId = userCache.user!.id;
      final friend = widget.friend;
      final chatId = ([userId, friend.id]..sort()).join();

      context.go('/chats');
      context.push(Messaging.encodeChatRoute(chatId, friend.displayName));
    });
  }

  Future<void> _greetUser() async {
    _doAction(() async {
      final self = userCache.user!;
      final other = User(
        id: widget.friend.id,
        createdAt: 0,
        updatedAt: 0,
        photoURL: widget.friend.photoURL,
        displayName: widget.friend.displayName,
        description: widget.friend.description,
      );

      final message = "Hi! I'm ${self.displayName!}. ${self.description}";
      final chat = await firedata.greetUser(self, other, message);

      if (mounted) {
        context.go('/chats');
        context.push(
          Messaging.encodeChatRoute(chat.id, other.displayName ?? ''),
        );
      }
    });
  }

  Future<void> _doAction(Future<void> Function() action) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      await action();
    } on AppException catch (e) {
      if (mounted) {
        ErrorHandler.showSnackBarMessage(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _handleTap() {
    final userId = userCache.user!.id;
    final chatId = ([userId, widget.friend.id]..sort()).join();

    if (chatCache.hasChat(chatId)) {
      _enterChat();
    } else {
      _greetUser();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final customColors = theme.extension<CustomColors>()!;
    final now = DateTime.fromMillisecondsSinceEpoch(ServerClock().now);
    final createdAt = DateTime.fromMillisecondsSinceEpoch(
      widget.friend.createdAt,
    );

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: colorScheme.surfaceContainerHigh,
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
        leading: GestureDetector(
          onTap: () => _showUserInfo(context),
          child: Text(widget.friend.photoURL, style: TextStyle(fontSize: 36)),
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
            Text(widget.friend.displayName, overflow: TextOverflow.ellipsis),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              formatText(widget.friend.description),
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
          onPressed: _handleTap,
          tooltip: 'Chat',
        ),
      ),
    );
  }
}
