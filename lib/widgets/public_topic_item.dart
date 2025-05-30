import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../helpers/helpers.dart';
import '../models/public_topic.dart';
import '../services/fireauth.dart';
import '../services/firestore.dart';
import '../services/follow_cache.dart';
import '../services/server_clock.dart';
import '../theme.dart';
import 'tag.dart';
import 'user_info_loader.dart';

class PublicTopicItem extends StatefulWidget {
  final PublicTopic topic;
  final Function(PublicTopic) onRemove;
  final Function(PublicTopic) onRestore;

  const PublicTopicItem({
    super.key,
    required this.topic,
    required this.onRemove,
    required this.onRestore,
  });

  @override
  State<StatefulWidget> createState() => _PublicTopicItemState();
}

class _PublicTopicItemState extends State<PublicTopicItem> {
  late Fireauth fireauth;
  late Firestore firestore;
  late FollowCache followCache;
  late bool byMe;
  late bool isFriend;

  @override
  void initState() {
    super.initState();
    fireauth = context.read<Fireauth>();
    firestore = context.read<Firestore>();
    byMe = widget.topic.creator.id == fireauth.instance.currentUser!.uid;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    followCache = Provider.of<FollowCache>(context);
    isFriend = followCache.isFollowing(widget.topic.creator.id);
  }

  Future<void> _muteTopic() async {
    _doAction(() async {
      await firestore.muteTopic(
        fireauth.instance.currentUser!.uid,
        widget.topic.id,
      );
    });
  }

  void _handleDismiss(DismissDirection direction) {
    // Remove the chat from the list
    widget.onRemove(widget.topic);

    // Show snackbar with undo option
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context)
        .showSnackBar(
          SnackBar(
            content: const Text('Left topic'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                // Restore the topic
                widget.onRestore(widget.topic);
              },
            ),
            duration: const Duration(seconds: 3),
          ),
        )
        .closed
        .then((reason) {
      // Only mute the chat if the SnackBar was closed by timeout
      // and not by user action (pressing undo)
      if (reason == SnackBarClosedReason.timeout) {
        _muteTopic();
      }
    });
  }

  Future<void> _enterTopic() async {
    _doAction(() async {
      final topic = widget.topic;

      context.go(encodeTopicRoute(topic.id, topic.creator.id));
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

  void _showCreatorInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => UserInfoLoader(
        userId: widget.topic.creator.id,
        photoURL: widget.topic.creator.photoURL ?? '',
        displayName: widget.topic.creator.displayName ?? '',
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
      widget.topic.updatedAt,
    );

    final cardColor = colorScheme.surfaceContainerHigh;
    final textColor = colorScheme.onSurface;

    final newMessageCount = widget.topic.unreadCount;
    final lastMessageContent =
        (widget.topic.lastMessageContent ?? '').replaceAll(RegExp(r'\s+'), ' ');

    final topic = widget.topic;
    final creator = topic.creator;

    return Dismissible(
      key: Key(topic.id),
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
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: _enterTopic,
          child: ListTile(
            contentPadding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
            leading: GestureDetector(
              onTap: () => _showCreatorInfo(context),
              child: Text(
                creator.photoURL ?? '',
                style: TextStyle(fontSize: 36, color: textColor),
              ),
            ),
            title: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (byMe || isFriend) ...[
                  Icon(
                    Icons.grade,
                    size: 16,
                    color: customColors.friendIndicator,
                  ),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    widget.topic.title,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
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
                      tooltip: 'Messages',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.message_outlined, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.topic.messageCount}',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Tag(
                      tooltip: 'Last updated',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.schedule, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            timeago.format(
                              updatedAt,
                              locale: 'en_short',
                              clock: now,
                            ),
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
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
