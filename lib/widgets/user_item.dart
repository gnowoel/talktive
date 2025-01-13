import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../helpers/helpers.dart';
import '../models/user.dart';
import '../services/cache.dart';
import '../services/fireauth.dart';
import '../services/firedata.dart';
import '../services/messaging.dart';
import 'tag.dart';

class UserItem extends StatefulWidget {
  final User user;
  final bool hasKnown;
  final bool hasSeen;

  const UserItem({
    super.key,
    required this.user,
    required this.hasKnown,
    required this.hasSeen,
  });

  @override
  State<UserItem> createState() => _UserItemState();
}

class _UserItemState extends State<UserItem> {
  late Fireauth fireauth;
  late Firedata firedata;
  late Cache cache;

  @override
  void initState() {
    super.initState();
    fireauth = context.read<Fireauth>();
    firedata = context.read<Firedata>();
    cache = context.read<Cache>();
  }

  Future<void> _enterChat() async {
    _doAction(() async {
      final userId = fireauth.instance.currentUser!.uid;
      final partner = widget.user;
      final chatId = ([userId, partner.id]..sort()).join();

      context.go('/chats');
      context.push(Messaging.encodeChatRoute(chatId, partner.displayName!));
    });
  }

  Future<void> _greetUser() async {
    _doAction(() async {
      final self = cache.user!;
      final other = widget.user;
      final message = "Hi! I'm ${self.displayName!}. ${self.description}";
      final chat = await firedata.greetUser(self, other, message);

      if (mounted) {
        context.go('/chats');
        context.push(Messaging.encodeChatRoute(chat.id, other.displayName!));
      }
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

  void _handleTap() {
    widget.hasKnown ? _enterChat() : _greetUser();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.fromMillisecondsSinceEpoch(Cache().now);
    final updatedAt =
        DateTime.fromMillisecondsSinceEpoch(widget.user.updatedAt);

    final cardColor = colorScheme.surfaceContainerHigh;
    final textColor = colorScheme.onSurface;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: cardColor,
      child: GestureDetector(
        onTap: _handleTap,
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
                    tooltip: '${getLongGenderName(widget.user.gender!)}',
                    child: Text(
                      widget.user.gender!,
                      style: TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Tag(
                    tooltip: '${getLanguageName(widget.user.languageCode!)}',
                    child: Text(
                      widget.user.languageCode!,
                      style: TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Tag(
                    tooltip: 'Last seen',
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
          trailing: _buildIconButton(),
        ),
      ),
    );
  }

  IconButton _buildIconButton() {
    if (widget.hasKnown) {
      return IconButton(
        icon: Icon(Icons.people_alt_outlined),
        onPressed: _enterChat,
        tooltip: 'Enter chat',
      );
    }

    if (widget.hasSeen) {
      return IconButton(
        icon: Icon(Icons.waving_hand_outlined),
        onPressed: _greetUser,
        tooltip: 'Say hi',
      );
    }

    return IconButton(
      icon: Icon(Icons.waving_hand),
      onPressed: _greetUser,
      tooltip: 'Say hi',
    );
  }
}
