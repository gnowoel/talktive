import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../helpers/helpers.dart';
import '../models/topic.dart';
import '../services/fireauth.dart';

import '../services/ad_service/go_router_room_helper.dart';
import '../services/follow_cache.dart';
import '../services/server_clock.dart';
import '../theme.dart';
import './tag.dart';
import './user_info_loader.dart';
import '../helpers/snackbar_helper.dart';

class TwoPersonTopicItemCard extends StatefulWidget {
  final Topic topic;
  final Function(Topic) onRemove;

  const TwoPersonTopicItemCard({
    super.key,
    required this.topic,
    required this.onRemove,
  });

  @override
  State<StatefulWidget> createState() => _TwoPersonTopicItemCardState();
}

class _TwoPersonTopicItemCardState extends State<TwoPersonTopicItemCard> {
  late Fireauth fireauth;
  late FollowCache followCache;
  late bool byMe;
  late bool isFriend;

  @override
  void initState() {
    super.initState();
    fireauth = context.read<Fireauth>();
    byMe = widget.topic.creator.id == fireauth.instance.currentUser!.uid;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    followCache = Provider.of<FollowCache>(context);
    isFriend = followCache.isFollowing(widget.topic.creator.id);
  }

  void _handleDismiss(DismissDirection direction) {
    widget.onRemove(widget.topic);
  }

  Future<void> _enterTopic() async {
    _doAction(() async {
      final topic = widget.topic;

      await context.goToTopic(topic.id, topic.creator.id);
    });
  }

  Future<void> _doAction(Future<void> Function() action) async {
    try {
      await action();
    } on AppException catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, e);
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

    final cardColor = colorScheme.tertiaryContainer;
    final textColor = colorScheme.onTertiaryContainer;

    final newMessageCount = widget.topic.unreadCount;
    final lastMessageContent = (widget.topic.lastMessageContent ?? '')
        .replaceAll(RegExp(r'\s+'), ' ');

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
                    creator.displayName ?? 'Chat',
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
                    // Display partner info for two-person topics
                    Tag(
                      tooltip: '${getLongGenderName(creator.gender!)}',
                      child: Text(
                        creator.gender!,
                        style: TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Tag(
                      tooltip: '${getLanguageName(creator.languageCode!)}',
                      child: Text(
                        creator.languageCode!,
                        style: TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Tag(
                      tooltip: 'Floor',
                      child: Text(
                        'F${creator.level}',
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
                    ...() {
                      final userStatus = creator.status;
                      if (userStatus == 'warning') {
                        return [
                          const SizedBox(width: 4),
                          Tag(status: 'warning'),
                        ];
                      } else if (userStatus == 'alert') {
                        return [const SizedBox(width: 4), Tag(status: 'alert')];
                      } else if (userStatus == 'newcomer') {
                        return [
                          const SizedBox(width: 4),
                          Tag(status: 'newcomer'),
                        ];
                      }
                      return <Widget>[];
                    }(),
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
