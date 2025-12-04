import 'dart:async';

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../helpers/helpers.dart';
import '../models/user.dart';

import '../services/fireauth.dart';
import '../services/firedata.dart';
import '../services/firestore.dart';
import '../services/follow_cache.dart';
import '../services/server_clock.dart';
import '../services/user_cache.dart';
import '../services/ad_service/go_router_room_helper.dart';
import '../theme.dart';
import 'tag.dart';
import 'user_info_loader.dart';

class UserItem extends StatefulWidget {
  final User user;
  final bool hasSeen;
  final Function(User)? onRemove;
  final Function(User)? onRestore;

  const UserItem({
    super.key,
    required this.user,
    required this.hasSeen,
    this.onRemove,
    this.onRestore,
  });

  @override
  State<UserItem> createState() => _UserItemState();
}

class _UserItemState extends State<UserItem> {
  late Fireauth fireauth;
  late Firedata firedata;
  late Firestore firestore;
  late UserCache userCache;
  late FollowCache followCache;
  late bool isFriend;

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    fireauth = context.read<Fireauth>();
    firedata = context.read<Firedata>();
    firestore = context.read<Firestore>();
    userCache = context.read<UserCache>();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    followCache = Provider.of<FollowCache>(context);
    isFriend = followCache.isFollowing(widget.user.id);
  }

  Future<void> _greetUser() async {
    _doAction(() async {
      final self = userCache.user!;
      final other = widget.user;

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
      // Create a private topic for two users instead of a chat
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

  Future<void> _unlistUser() async {
    _doAction(() async {
      await firestore.applyUserAlert(
        fireauth.instance.currentUser!.uid,
        widget.user.id,
      );

      // Update the user cache with new revivedAt value (24 hours from now)
      final now = DateTime.now().millisecondsSinceEpoch;
      final oneDayFromNow = now + (24 * 60 * 60 * 1000);

      final updatedUser = widget.user.copyWith(
        revivedAt: oneDayFromNow,
      );

      // Update the Firestore cache directly
      firestore.updateUserInCache(updatedUser);
    });
  }

  void _handleDismiss(DismissDirection direction) {
    // Remove the user from the list
    if (widget.onRemove != null) {
      widget.onRemove!(widget.user);
    }

    // Show snackbar with undo option
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context)
        .showSnackBar(
          SnackBar(
            content: const Text('User given 1-day timeout'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                // Restore the user
                if (widget.onRestore != null) {
                  widget.onRestore!(widget.user);
                }
              },
            ),
            duration: const Duration(seconds: 3),
          ),
        )
        .closed
        .then((reason) {
      // Only unlist the user if the SnackBar was closed by timeout
      // and not by user action (pressing undo)
      if (reason == SnackBarClosedReason.timeout) {
        _unlistUser();
      }
    });
  }

  Future<void> _doAction(Future<void> Function() action) async {
    setState(() {
      _isProcessing = true;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ErrorHandler.showSnackBarMessage(
          context,
          e is AppException ? e : AppException(e.toString()),
        );
      }
    }
    if (mounted) {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  bool _canChatWithUser() {
    final self = userCache.user;
    final other = widget.user;

    if (self == null) return false;

    // Prevent users from chatting with themselves
    if (self.id == other.id) return false;

    // Check basic message sending permission
    if (!canSendMessage(self)) return false;

    // Check specific greeting permission for female users
    if (other.isFemaleNewcomer) {
      return canGreetFemaleNewcomer(self);
    }

    return true;
  }

  Future<void> _showRestrictionDialog() async {
    final self = userCache.user!;
    final other = widget.user;
    final colorScheme = Theme.of(context).colorScheme;

    String title;
    List<Widget> content;

    // Check if user is trying to chat with themselves
    if (self.id == other.id) {
      title = 'Invalid Action';
      content = [
        Text(
          'You cannot start a conversation with yourself.',
          style: TextStyle(height: 1.5, color: colorScheme.error),
        ),
        const SizedBox(height: 16),
        const Text(
          'Please select a different user to chat with.',
          style: TextStyle(height: 1.5),
        ),
      ];
    } else if (!canSendMessage(self)) {
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

  Future<void> _handleTap() async {
    if (!_canChatWithUser()) {
      await _showRestrictionDialog();
      return;
    }

    await _greetUser();
  }

  void _showUserInfo(BuildContext context) {
    final user = widget.user;
    showDialog(
      context: context,
      builder: (context) {
        return UserInfoLoader(
          userId: user.id,
          photoURL: user.photoURL ?? '',
          displayName: user.displayName ?? '',
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final customColors = theme.extension<CustomColors>()!;
    final now = DateTime.fromMillisecondsSinceEpoch(ServerClock().now);
    final updatedAt = DateTime.fromMillisecondsSinceEpoch(
      widget.user.updatedAt,
    );

    final cardColor = widget.hasSeen
        ? colorScheme.surfaceContainerHigh
        : colorScheme.secondaryContainer;
    final textColor = colorScheme.onSurface;

    final userStatus = widget.user.status;

    final currentUser = userCache.user;
    final canUnlist = (currentUser?.isAdminOrModerator == true) &&
        currentUser?.id != widget.user.id &&
        widget.onRemove != null &&
        widget.onRestore != null;

    final cardContent = Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: cardColor,
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
        leading: GestureDetector(
          onTap: () => _showUserInfo(context),
          child: Text(
            widget.user.photoURL!,
            style: TextStyle(fontSize: 36, color: textColor),
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
                widget.user.displayName!,
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
              formatText(widget.user.description),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(height: 1.2),
              maxLines: 3,
            ),
            const SizedBox(height: 4),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
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
                    tooltip: 'Experience Level',
                    child: Text(
                      'L${widget.user.level}',
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
                  // Show single most relevant status tag (priority-based)
                  ...() {
                    // Priority order: warning > alert > moderator > very_poor > poor > newcomer > excellent > good
                    if (userStatus == 'warning') {
                      return [const SizedBox(width: 4), Tag(status: 'warning')];
                    } else if (userStatus == 'alert') {
                      return [const SizedBox(width: 4), Tag(status: 'alert')];
                    } else if (widget.user.isModerator &&
                        !widget.user.isAdmin) {
                      return [const SizedBox(width: 4), Tag(status: 'mod')];
                      // } else if (widget.user.reputationLevel == 'very_poor') {
                      //   return [
                      //     const SizedBox(width: 4),
                      //     Tag(status: 'very_poor')
                      //   ];
                      // } else if (widget.user.reputationLevel == 'poor') {
                      //   return [const SizedBox(width: 4), Tag(status: 'poor')];
                    } else if (userStatus == 'newcomer') {
                      return [
                        const SizedBox(width: 4),
                        Tag(status: 'newcomer'),
                      ];
                      // } else if (widget.user.reputationLevel == 'excellent') {
                      //   return [const SizedBox(width: 4), Tag(status: 'excellent')];
                      // } else if (widget.user.reputationLevel == 'good') {
                      //   return [const SizedBox(width: 4), Tag(status: 'good')];
                    }
                    return <Widget>[];
                  }(),
                ],
              ),
            ),
          ],
        ),
        trailing: _buildIconButton(),
      ),
    );

    if (canUnlist) {
      return Dismissible(
        key: Key(widget.user.id),
        background: Container(
          color: colorScheme.error,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 2.0),
          child: Icon(Icons.schedule, color: colorScheme.onError),
        ),
        direction:
            DismissDirection.startToEnd, // Only allow left to right swipe
        onDismissed: _handleDismiss,
        child: cardContent,
      );
    }

    return cardContent;
  }

  Widget _buildIconButton() {
    if (!_canChatWithUser()) {
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
          : const Icon(Icons.waving_hand_outlined),
      onPressed: _handleTap,
      tooltip: 'Say hi',
    );
  }
}
