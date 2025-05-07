import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../helpers/exception.dart';
import '../helpers/routes.dart';
import '../helpers/text.dart';
import '../models/public_topic.dart';
import '../services/fireauth.dart';
import '../services/firestore.dart';
import '../services/follow_cache.dart';
import '../services/server_clock.dart';
import '../theme.dart';
import 'tag.dart';
import 'user_info_loader.dart';

class TopicItem extends StatefulWidget {
  final PublicTopic topic;
  final bool hasJoined;
  final bool hasSeen;

  const TopicItem({
    super.key,
    required this.topic,
    required this.hasJoined,
    required this.hasSeen,
  });

  @override
  State<TopicItem> createState() => _TopicItemState();
}

class _TopicItemState extends State<TopicItem> {
  late Fireauth fireauth;
  late Firestore firestore;
  late FollowCache followCache;
  late bool byMe;
  late bool isFriend;
  bool _isProcessing = false;

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

  Future<void> _joinTopic() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final userId = fireauth.instance.currentUser!.uid;
      final topicId = widget.topic.id;

      await firestore.joinTopic(userId, topicId);

      if (mounted) {
        context.go('/chats');
        context.push(encodeTopicRoute(topicId));
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showSnackBarMessage(
          context,
          e is AppException ? e : AppException(e.toString()),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _enterTopic() {
    context.go('/chats');
    context.push(encodeTopicRoute(widget.topic.id));
  }

  void _showCreatorInfo(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => UserInfoLoader(
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

    final cardColor =
        widget.hasJoined
            ? colorScheme.surfaceContainerHigh
            : (widget.hasSeen
                ? colorScheme.surfaceContainerHigh
                : colorScheme.surfaceContainer);
    final textColor = colorScheme.onSurface;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: cardColor,
      clipBehavior: Clip.hardEdge,
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
        leading: GestureDetector(
          onTap: () => _showCreatorInfo(context),
          child: Text(
            widget.topic.creator.photoURL ?? '',
            style: TextStyle(fontSize: 36, color: textColor),
          ),
        ),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (byMe || isFriend) ...[
              Icon(Icons.grade, size: 16, color: customColors.friendIndicator),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(widget.topic.title, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              formatText(
                widget.topic.lastMessageContent,
              ), // firstMessageContent
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
        trailing: _buildIconButton(),
      ),
    );
  }

  Widget _buildIconButton() {
    if (widget.hasJoined) {
      return IconButton(
        icon: const Icon(Icons.keyboard_double_arrow_right),
        onPressed: () => _enterTopic(),
        tooltip: 'Enter topic',
      );
    }

    return IconButton(
      icon:
          _isProcessing
              ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
              : const Icon(Icons.keyboard_arrow_right),
      onPressed: _isProcessing ? null : () => _joinTopic(),
      tooltip: 'Join topic',
    );
  }
}
