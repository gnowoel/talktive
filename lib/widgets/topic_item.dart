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
import '../services/tribe_cache.dart';
import '../services/user_cache.dart';
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
        context.go('/chats');
        context.push(encodeTopicRoute(topicId, topicCreatorId));
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

    if (self.withWarning) return false;

    return true;
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

    if (self.withAlert) {
      await _showAlertDialog();
      return;
    }

    if (self.isTrainee) {
      await _showTraineeDialog();
      return;
    }

    await _joinTopic();
  }

  Future<void> _enterTopic() async {
    context.go('/chats');
    context.push(encodeTopicRoute(widget.topic.id, widget.topic.creator.id));
  }

  Future<void> _showRestrictionDialog() async {
    final colorScheme = Theme.of(context).colorScheme;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Account Restricted'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your account has been temporarily restricted due to multiple reports of inappropriate behavior.',
              style: TextStyle(height: 1.5, color: colorScheme.error),
            ),
            const SizedBox(height: 16),
            const Text(
              'You cannot join topics until this restriction expires.',
              style: TextStyle(height: 1.5),
            ),
          ],
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

  Future<void> _showAlertDialog() async {
    final colorScheme = Theme.of(context).colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Temporarily Restricted'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your account has temporary restrictions due to reports of inappropriate communications.',
              style: TextStyle(height: 1.5, color: colorScheme.error),
            ),
            const SizedBox(height: 16),
            Text(
              'You can still view the conversation, but cannot post messages until this restriction expires.',
              style: const TextStyle(height: 1.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Further reports may result in more severe restrictions.',
              style: TextStyle(height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('I Understand'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _joinTopic();
    }
  }

  Future<void> _showTraineeDialog() async {
    final colorScheme = Theme.of(context).colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Review Only'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To participate in topics, your account must be at least 24 hours old and at level 4 or above.',
              style: TextStyle(height: 1.5, color: colorScheme.error),
            ),
            const SizedBox(height: 16),
            Text(
              'You can still view the conversation, but cannot post messages until these requirements are met.',
              style: const TextStyle(height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('I Understand'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _joinTopic();
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

  void _onTribeTap() {
    if (widget.topic.tribe != null) {
      context.push('/topics/tribe/${widget.topic.tribe}');
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
            if (widget.topic.tribe != null)
              GestureDetector(
                onTap: _onTribeTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(
                      alpha: 0.7,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tribeCache.getTribeById(widget.topic.tribe!)?.name ??
                        widget.topic.tribe!,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
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
