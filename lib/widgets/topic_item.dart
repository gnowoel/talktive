import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:talktive/helpers/text.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../helpers/exception.dart';
import '../helpers/permissions.dart';
import '../helpers/routes.dart';
import '../models/topic.dart';
import '../models/tribe.dart';
import '../services/fireauth.dart';
import '../services/firestore.dart';
import '../services/follow_cache.dart';
import '../services/server_clock.dart';
import '../services/tribe_cache.dart';
import '../services/user_cache.dart';
import '../theme.dart';
import 'tag.dart';
import 'user_info_loader.dart';

class TopicItem extends StatefulWidget {
  final Topic topic;
  final bool hasJoined;
  final bool hasSeen;
  final bool showTribeTag;
  final void Function(Tribe)? onTribeSelected;

  const TopicItem({
    super.key,
    required this.topic,
    required this.hasJoined,
    required this.hasSeen,
    this.showTribeTag = false,
    this.onTribeSelected,
  });

  @override
  State<TopicItem> createState() => _TopicItemState();
}

class _TopicItemState extends State<TopicItem> {
  late Fireauth fireauth;
  late Firestore firestore;
  late UserCache userCache;
  late FollowCache followCache;
  late bool byMe;
  late bool isFriend;
  bool _isProcessing = false;
  late TribeCache tribeCache;

  @override
  void initState() {
    super.initState();
    fireauth = context.read<Fireauth>();
    firestore = context.read<Firestore>();
    userCache = context.read<UserCache>();
    byMe = widget.topic.creator.id == fireauth.instance.currentUser!.uid;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    followCache = Provider.of<FollowCache>(context);
    tribeCache = Provider.of<TribeCache>(context);
    isFriend = followCache.isFollowing(widget.topic.creator.id);
  }

  Future<void> _joinTopic() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final userId = fireauth.instance.currentUser!.uid;
      final topicId = widget.topic.id;
      final topicCreatorId = widget.topic.creator.id;

      await firestore.joinTopic(userId, topicId);

      if (mounted) {
        context.go(encodeTopicRoute(topicId, topicCreatorId));
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

  bool _canJoinTopic() {
    final self = userCache.user;
    if (self == null) return false;
    return canJoinTopic(self);
  }

  Future<void> _handleTap() async {
    final self = userCache.user;
    if (self == null) return;

    if (widget.hasJoined) {
      await _enterTopic();
      return;
    }

    if (!_canJoinTopic()) {
      await _showRestrictionDialog();
      return;
    }

    await _joinTopic();
  }

  Future<void> _enterTopic() async {
    context.go(encodeTopicRoute(widget.topic.id, widget.topic.creator.id));
  }

  Future<void> _showRestrictionDialog() async {
    final self = userCache.user!;
    final colorScheme = Theme.of(context).colorScheme;

    String title;
    List<Widget> content;

    if (!canSendMessage(self)) {
      title = 'Account Restricted';
      content = [
        Text(
          'Your account has been temporarily restricted due to multiple reports of inappropriate behavior.',
          style: TextStyle(height: 1.5, color: colorScheme.error),
        ),
        const SizedBox(height: 16),
        const Text(
          'You cannot join topics until this restriction expires.',
          style: TextStyle(height: 1.5),
        ),
      ];
    } else {
      title = 'Cannot Join Topic';
      content = [
        const Text(
          'You cannot join topics at this time.',
          style: TextStyle(height: 1.5),
        ),
      ];
    }

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: content,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
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

  void _onTribeTap() {
    if (widget.topic.tribeId != null && widget.onTribeSelected != null) {
      final tribe = tribeCache.getTribeById(widget.topic.tribeId!);
      if (tribe != null) {
        widget.onTribeSelected!(tribe);
      }
    }
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

    final cardColor = widget.hasJoined
        ? colorScheme.surfaceContainerHigh
        : (widget.hasSeen
            ? colorScheme.surfaceContainerHigh
            : colorScheme.secondaryContainer);
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.topic.tribeId != null && widget.showTribeTag) ...[
              GestureDetector(
                onTap: _onTribeTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer.withValues(
                      alpha: 0.7,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tribeCache.getTribeById(widget.topic.tribeId!)?.name ??
                        widget.topic.tribeId!,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ),
            ],
            Row(
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
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showTribeTag) ...[
              const SizedBox(height: 2),
            ] else ...[
              const SizedBox(height: 4),
              Text(
                formatText(
                  // It's actually firstMessageContent
                  widget.topic.lastMessageContent,
                ),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(height: 1.2),
                maxLines: 3,
              ),
              const SizedBox(height: 4),
            ],
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
        onPressed: _handleTap,
        tooltip: 'Enter topic',
      );
    }

    if (!_canJoinTopic()) {
      return IconButton(
        icon: const Icon(Icons.block_outlined),
        onPressed: _handleTap,
        tooltip: 'Restricted',
      );
    }

    return IconButton(
      icon: _isProcessing
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.keyboard_arrow_right),
      onPressed: _isProcessing ? null : _handleTap,
      tooltip: 'Join topic',
    );
  }
}
