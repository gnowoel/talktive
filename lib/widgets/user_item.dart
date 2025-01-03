import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../helpers/helpers.dart';
import '../models/user.dart';
// import '../pages/chat.dart';
import '../services/cache.dart';
import '../services/fireauth.dart';
import '../services/firedata.dart';
import 'tag.dart';

class UserItem extends StatefulWidget {
  final User user;
  final void Function(User) hideUser;

  const UserItem({
    super.key,
    required this.user,
    required this.hideUser,
  });

  @override
  State<UserItem> createState() => _UserItemState();
}

class _UserItemState extends State<UserItem> {
  late Fireauth fireauth;
  late Firedata firedata;

  @override
  void initState() {
    super.initState();
    fireauth = Provider.of<Fireauth>(context, listen: false);
    firedata = Provider.of<Firedata>(context, listen: false);
  }

  Future<void> _createPairAndHideUser() async {
    _doAction(() async {
      final userId = fireauth.instance.currentUser!.uid;
      final partner = widget.user;
      await firedata.createPair(userId, partner);
      widget.hideUser(widget.user);
    });
  }

  Future<void> _enterChat() async {
    _doAction(() async {
      // final userId = fireauth.instance.currentUser!.uid;
      // final partner = widget.user;
      // final chat = await firedata.createPair(userId, partner);
      widget.hideUser(widget.user);
      if (mounted) {
        context.go('/chats');
        context.push('/shares');
        // context.go('/chat/${chat.id}');
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.fromMillisecondsSinceEpoch(Cache().now);
    final updatedAt =
        DateTime.fromMillisecondsSinceEpoch(widget.user.updatedAt);

    final cardColor = colorScheme.surfaceContainerHigh;
    final textColor = colorScheme.onSurface;

    return Dismissible(
      key: Key(widget.user.id),
      background: Icon(
        Icons.delete,
        color: colorScheme.error,
      ),
      onDismissed: (direction) async {
        await _createPairAndHideUser();
      },
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6),
        color: cardColor,
        child: GestureDetector(
          onTap: _enterChat,
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
                        timeago.format(updatedAt,
                            locale: 'en_short', clock: now),
                        style: TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.add_circle),
              onPressed: _enterChat,
              tooltip: 'Chat',
            ),
          ),
        ),
      ),
    );
  }
}
