import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../helpers/helpers.dart';
import '../models/user.dart';
import '../services/chat_cache.dart';
import '../services/fireauth.dart';
import '../services/firedata.dart';
import '../services/follow_cache.dart';
import '../services/server_clock.dart';
import '../services/user_cache.dart';
import '../theme.dart';
import 'tag.dart';
import 'user_info_loader.dart';

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
  late UserCache userCache;
  late ChatCache chatCache;
  late FollowCache followCache;
  late bool isFriend;

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    fireauth = context.read<Fireauth>();
    firedata = context.read<Firedata>();
    userCache = context.read<UserCache>();
    chatCache = context.read<ChatCache>();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    followCache = Provider.of<FollowCache>(context);
    isFriend = followCache.isFollowing(widget.user.id);
  }

  Future<void> _enterChat() async {
    _doAction(() async {
      final userId = fireauth.instance.currentUser!.uid;
      final partner = widget.user;
      final chatId = ([userId, partner.id]..sort()).join();
      final chat = chatCache.getChat(chatId);
      final chatCreatedAt = chat?.createdAt.toString() ?? '0';

      context.go(encodeChatRoute(chatId, chatCreatedAt));
    });
  }

  Future<void> _greetUser() async {
    _doAction(() async {
      final self = userCache.user!;
      final other = widget.user;
      final message = '${self.description}';
      final chat = await firedata.greetUser(self, other, message);
      final chatCreatedAt = chat.createdAt.toString();

      if (mounted) {
        context.go(encodeChatRoute(chat.id, chatCreatedAt));
      }
    });
  }

  Future<void> _doAction(Future<void> Function() action) async {
    if (_isProcessing) return;

    if (!mounted) return;
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
    final self = userCache.user;
    final other = widget.user;

    if (self == null) return false;

    // Check basic message sending permission
    if (!canSendMessage(self)) return false;

    // Check specific greeting permission for female users
    if (other.isFemaleNewcomer) {
      return canGreetFemaleNewcomer(self, followCache);
    }

    return true;
  }

  Future<void> _showRestrictionDialog() async {
    final self = userCache.user!;
    final other = widget.user;
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
    } else if (other.isFemaleNewcomer &&
        !canGreetFemaleNewcomer(self, followCache)) {
      title = 'Female Protection';
      content = [
        Text(
          'Sorry, you need to reach level 6 and have at least 1 follower to chat with new female users.',
          style: TextStyle(height: 1.5, color: colorScheme.error),
        ),
        const SizedBox(height: 16),
        const Text(
          'This restriction helps maintain a safe environment for all users.',
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
    if (widget.hasKnown) {
      await _enterChat();
      return;
    }

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

    final cardColor = widget.hasKnown
        ? colorScheme.surfaceContainerHigh
        : (widget.hasSeen
            ? colorScheme.surfaceContainerHigh
            : colorScheme.secondaryContainer);
    final textColor = colorScheme.onSurface;

    final userStatus = widget.user.status;

    return Card(
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
                  // Priority order: warning > alert > very_poor > poor > newcomer > excellent > good
                  if (userStatus == 'warning') {
                    return [const SizedBox(width: 4), Tag(status: 'warning')];
                  } else if (userStatus == 'alert') {
                    return [const SizedBox(width: 4), Tag(status: 'alert')];
                  } else if (widget.user.reputationLevel == 'very_poor') {
                    return [const SizedBox(width: 4), Tag(status: 'very_poor')];
                  } else if (widget.user.reputationLevel == 'poor') {
                    return [const SizedBox(width: 4), Tag(status: 'poor')];
                  } else if (userStatus == 'newcomer') {
                    return [const SizedBox(width: 4), Tag(status: 'newcomer')];
                    // } else if (widget.user.reputationLevel == 'excellent') {
                    //   return [const SizedBox(width: 4), Tag(status: 'excellent')];
                    // } else if (widget.user.reputationLevel == 'good') {
                    //   return [const SizedBox(width: 4), Tag(status: 'good')];
                  }
                  return <Widget>[];
                }(),
              ],
            ),
          ],
        ),
        trailing: _buildIconButton(),
      ),
    );
  }

  Widget _buildIconButton() {
    if (widget.hasKnown) {
      return IconButton(
        icon: const Icon(Icons.people_alt_outlined),
        onPressed: _handleTap,
        tooltip: 'Enter chat',
      );
    }

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
