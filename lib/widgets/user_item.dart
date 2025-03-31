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
import '../services/messaging.dart';
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

      context.go('/chats');
      context.push(Messaging.encodeChatRoute(chatId, chatCreatedAt));
    });
  }

  Future<void> _greetUser() async {
    _doAction(() async {
      final self = userCache.user!;
      final other = widget.user;
      final message = "Hi! I'm ${self.displayName!}. ${self.description}";
      final chat = await firedata.greetUser(self, other, message);
      final chatCreatedAt = chat.createdAt.toString();

      if (mounted) {
        context.go('/chats');
        context.push(Messaging.encodeChatRoute(chat.id, chatCreatedAt));
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
    final self = userCache.user;
    final other = widget.user;

    if (self == null) return false;

    if (self.withWarning) return false;

    if (other.gender == 'F' && other.isNewcomer) {
      if (self.isNewcomer || self.withAlert) {
        return false;
      }
    }

    return true;
  }

  Future<void> _showRestrictionDialog() async {
    final self = userCache.user!;
    final colorScheme = Theme.of(context).colorScheme;

    String title;
    List<Widget> content;

    if (self.withWarning) {
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
    } else if (self.withAlert) {
      title = 'Temporarily Restricted';
      content = [
        Text(
          'Due to previous reports, you cannot chat with new female users at this time.',
          style: TextStyle(height: 1.5, color: colorScheme.error),
        ),
        const SizedBox(height: 16),
        const Text(
          'This restriction helps maintain a safe environment for all users.',
          style: TextStyle(height: 1.5),
        ),
      ];
    } else if (self.isNewcomer) {
      title = 'Female Protection';
      content = [
        Text(
          'Your account needs to be at least 24 hours old to chat with new female users. Sorry about the inconvenience.',
          style: TextStyle(height: 1.5, color: colorScheme.error),
        ),
        const SizedBox(height: 16),
        const Text(
          'This restriction helps protect our community from harassment.',
          style: TextStyle(height: 1.5),
        ),
      ];
    } else {
      return;
    }

    await showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
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
      builder:
          (context) => AlertDialog(
            title: const Text('Warning'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your account has been reported for inappropriate messages.',
                  style: TextStyle(height: 1.5, color: colorScheme.error),
                ),
                const SizedBox(height: 16),
                Text(
                  'Please be respectful when chatting with ${widget.user.displayName}.',
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

  void _handleTap() {
    if (widget.hasKnown) {
      _enterChat();
    } else {
      _handleGreet();
    }
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

    final cardColor =
        widget.hasKnown
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
      child: GestureDetector(
        onTap: _handleTap,
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
                Icon(
                  Icons.grade,
                  size: 16,
                  color: customColors.friendIndicator,
                ),
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
                    tooltip: 'Level ${widget.user.level}',
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
                  if (userStatus == 'warning') ...[
                    const SizedBox(width: 4),
                    Tag(status: 'warning'),
                  ] else if (userStatus == 'alert') ...[
                    const SizedBox(width: 4),
                    Tag(status: 'alert'),
                  ] else if (userStatus == 'newcomer') ...[
                    const SizedBox(width: 4),
                    Tag(status: 'newcomer'),
                  ],
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

    if (!_canChatWithUser()) {
      return IconButton(
        icon: const Icon(Icons.waving_hand_outlined),
        onPressed: null,
        tooltip: 'Restricted',
      );
    }

    return IconButton(
      icon: const Icon(Icons.waving_hand_outlined),
      onPressed: _handleGreet,
      tooltip: 'Say hi',
    );
  }
}
