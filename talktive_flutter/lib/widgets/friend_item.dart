import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../helpers/helpers.dart';
import '../models/follow.dart';
import '../models/user.dart';
import '../services/firestore.dart';
import '../services/follow_cache.dart';
import '../services/server_clock.dart';
import '../services/user_cache.dart';
import '../services/ad_service/go_router_room_helper.dart';
import '../theme.dart';
import 'tag.dart';
import 'user_info_loader.dart';

class FriendItem extends StatefulWidget {
  final Follow friend;

  const FriendItem({super.key, required this.friend});

  @override
  State<FriendItem> createState() => _FriendItemState();
}

class _FriendItemState extends State<FriendItem> {
  late Firestore firestore;
  late UserCache userCache;
  late FollowCache followCache;
  late bool isFriend;

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    firestore = context.read<Firestore>();
    userCache = context.read<UserCache>();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    followCache = Provider.of<FollowCache>(context);
    isFriend = followCache.isFollowing(widget.friend.id);
  }

  void _showUserInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return UserInfoLoader(
          userId: widget.friend.id,
          photoURL: widget.friend.user.photoURL ?? '',
          displayName: widget.friend.user.displayName ?? '',
        );
      },
    );
  }

  Future<void> _greetUser() async {
    _doAction(() async {
      final self = userCache.user!;
      final other = User.fromStub(
        key: widget.friend.id,
        value: widget.friend.user,
      );

      // Prevent users from chatting with themselves
      if (self.id == other.id) {
        throw AppException('You cannot start a conversation with yourself.');
      }

      // Validate user data before attempting to greet
      if (self.description == null || self.description!.trim().isEmpty) {
        throw AppException(
          'Please add a description to your profile before starting a conversation.',
        );
      }

      if (other.id.isEmpty) {
        throw AppException('Invalid user selected. Please try again.');
      }

      final message = self.description!.trim();
      // Create a private topic for two users
      final topic = await firestore.createTopic(
        user: self,
        title: '${self.displayName} & ${other.displayName}',
        message: message,
        tribeId: null, // No tribe for private conversations
        isPublic: false, // Private topic for two users
        targetUserId: other.id, // Restrict to just these two users
      );

      if (mounted) {
        await context.goToTopic(topic.id, topic.creator.id);
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

  bool _canChatWithUser() {
    final self = userCache.user!;
    final other = User.fromStub(
      key: widget.friend.id,
      value: widget.friend.user,
    );

    // Check basic message sending permission
    if (!canSendMessage(self)) return false;

    // Check specific greeting permission for new female users
    if (other.isFemaleNewcomer) {
      return canGreetFemaleNewcomer(self);
    }

    return true;
  }

  Future<void> _showRestrictionDialog() async {
    final self = userCache.user!;
    final other = User.fromStub(
      key: widget.friend.id,
      value: widget.friend.user,
    );
    final colorScheme = Theme.of(context).colorScheme;

    String title;
    List<Widget> content;

    // Check if user can send messages at all
    if (!canSendMessage(self)) {
      title = 'Account Restricted';
      content = [
        Text(
          'Your account has been temporarily restricted due to multiple reports of inappropriate behavior.',
          style: TextStyle(height: 1.5, color: colorScheme.error),
        ),
        const SizedBox(height: 16),
        const Text(
          'You cannot start new conversations until this restriction expires.',
          style: TextStyle(height: 1.5),
        ),
      ];
    } else if (other.isFemaleNewcomer && !canGreetFemaleNewcomer(self)) {
      title = 'Female Protection';
      content = [
        Text(
          'Sorry, you need level 5, good reputatioin and no restrictions to chat with new female users.',
          style: TextStyle(height: 1.5, color: colorScheme.error),
        ),
        const SizedBox(height: 16),
        const Text(
          'This helps maintain a safe environment for all users.',
          style: TextStyle(height: 1.5),
        ),
      ];
    } else {
      return;
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

  Future<void> _showAlertDialog() async {
    final colorScheme = Theme.of(context).colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Warning'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your account has been reported for inappropriate communications.',
              style: TextStyle(height: 1.5, color: colorScheme.error),
            ),
            const SizedBox(height: 16),
            Text(
              'Please be respectful when chatting with ${widget.friend.user.displayName}.',
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
      await _greetUser();
    }
  }

  void _handleGreet() async {
    if (!_canChatWithUser()) {
      await _showRestrictionDialog();
      return;
    }

    final self = userCache.user!;
    if (self.withAlert) {
      await _showAlertDialog();
    } else {
      await _greetUser();
    }
  }

  Widget _buildRelationshipTag() {
    final theme = Theme.of(context);
    final isMutual = followCache.isMutualFriend(widget.friend.id);
    final isFollowing = followCache.isFollowing(widget.friend.id);
    final isFollower = followCache.isFollowedBy(widget.friend.id);

    IconData icon;
    String tooltip;

    if (isMutual) {
      icon = Icons.sync_alt;
      tooltip = 'Mutual Friend';
    } else if (isFollowing) {
      icon = Icons.arrow_forward;
      tooltip = 'Following';
    } else if (isFollower) {
      icon = Icons.arrow_back;
      tooltip = 'Follower';
    } else {
      return const SizedBox.shrink();
    }

    return Tag(
      tooltip: tooltip,
      child: Icon(icon, size: 16, color: theme.colorScheme.primary),
    );
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
          child: Text(
            widget.friend.user.photoURL ?? '',
            style: TextStyle(fontSize: 36),
          ),
        ),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (isFriend) ...[
              Icon(Icons.grade, size: 16, color: customColors.friendIndicator),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                widget.friend.user.displayName ?? '',
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
              formatText(widget.friend.user.description ?? ''),
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
                const SizedBox(width: 8),
                _buildRelationshipTag(),
              ],
            ),
          ],
        ),
        trailing: _buildIconButton(),
      ),
    );
  }

  IconButton _buildIconButton() {
    if (!_canChatWithUser()) {
      return IconButton(
        icon: Icon(Icons.chat_outlined),
        onPressed: _handleGreet,
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
          : Icon(Icons.chat_outlined),
      onPressed: _handleGreet,
      tooltip: 'Start chatting',
    );
  }
}
