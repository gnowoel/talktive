import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../helpers/helpers.dart';
import '../models/user.dart';
import '../services/fireauth.dart';
import '../services/firedata.dart';
import '../services/messaging.dart';
import '../services/server_clock.dart';
import '../services/user_cache.dart';
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

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    fireauth = context.read<Fireauth>();
    firedata = context.read<Firedata>();
    userCache = context.read<UserCache>();
  }

  Future<void> _enterChat() async {
    _doAction(() async {
      final userId = fireauth.instance.currentUser!.uid;
      final partner = widget.user;
      final chatId = ([userId, partner.id]..sort()).join();

      context.go('/chats');
      context.push(Messaging.encodeChatRoute(chatId, partner.displayName!));
    });
  }

  Future<void> _greetUser() async {
    _doAction(() async {
      final self = userCache.user!;
      final other = widget.user;
      final message = "Hi! I'm ${self.displayName!}. ${self.description}";
      final chat = await firedata.greetUser(self, other, message);

      if (mounted) {
        context.go('/chats');
        context
            .push(Messaging.encodeChatRoute(chat.id, other.displayName ?? ''));
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

  Future<void> _showWarningDialog() async {
    final self = userCache.user!;
    final colorScheme = Theme.of(context).colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          self.withWarning ? 'Account Restricted' : 'Be Respectful',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (self.withWarning) ...[
              Text(
                'Your account has been temporarily restricted due to multiple reports of inappropriate behavior.',
                style: TextStyle(
                  height: 1.5,
                  color: colorScheme.error,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'You cannot start new conversations until this restriction expires.',
                style: TextStyle(
                  height: 1.5,
                ),
              ),
            ] else ...[
              const Text(
                'Your account has been previously reported for inappropriate messages.',
                style: TextStyle(
                  height: 1.5,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Please be polite when chatting with ${widget.user.displayName}.',
                style: TextStyle(
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Continued inappropriate behavior may result in longer restrictions.',
                style: TextStyle(
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(self.withWarning ? 'Close' : 'Cancel'),
          ),
          if (!self.withWarning)
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
    final self = userCache.user!;

    if (self.withWarning) {
      // Show warning dialog without option to proceed
      await _showWarningDialog();
    } else if (self.withAlert) {
      // Show warning dialog with option to proceed
      await _showWarningDialog();
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
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.fromMillisecondsSinceEpoch(ServerClock().now);
    final updatedAt =
        DateTime.fromMillisecondsSinceEpoch(widget.user.updatedAt);

    final cardColor = widget.hasKnown
        ? colorScheme.surfaceContainerHigh
        : (widget.hasSeen
            ? colorScheme.surfaceContainerHigh
            : colorScheme.secondaryContainer);
    final textColor = colorScheme.onSurface;

    final userStatus = getUserStatus(widget.user, now);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: cardColor,
      child: GestureDetector(
        onTap: _handleTap,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8, // Add some vertical padding
          ),
          leading: GestureDetector(
            onTap: () => _showUserInfo(context),
            child: Text(
              widget.user.photoURL!,
              style: TextStyle(fontSize: 36, color: textColor),
            ),
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
                style: TextStyle(
                  height: 1.2,
                ),
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
                    tooltip: 'Last seen',
                    child: Text(
                      timeago.format(updatedAt, locale: 'en_short', clock: now),
                      style: TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (userStatus == 'alert') ...[
                    const SizedBox(width: 4),
                    Tag(
                      status: 'alert',
                      tooltip: 'Reported for offensive messages',
                      child: Text(
                        'alert',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onTertiaryContainer,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ] else if (userStatus == 'warning') ...[
                    const SizedBox(width: 4),
                    Tag(
                      status: 'warning',
                      tooltip: 'Reported for inappropriate behavior',
                      child: Text(
                        'warning',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onErrorContainer,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
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
    final self = userCache.user!;

    if (widget.hasKnown) {
      return IconButton(
        icon: Icon(Icons.people_alt_outlined),
        onPressed: _enterChat,
        tooltip: 'Enter chat',
      );
    }

    if (widget.hasSeen) {
      return IconButton(
        icon: Icon(Icons.waving_hand_outlined),
        // Disable the button if user is under warning restriction
        onPressed: self.withWarning ? null : _handleGreet,
        tooltip: self.withWarning ? 'Restricted' : 'Say hi',
      );
    }

    return IconButton(
      icon: Icon(Icons.waving_hand_outlined),
      // Disable the button if user is under warning restriction
      onPressed: self.withWarning ? null : _handleGreet,
      tooltip: self.withWarning ? 'Restricted' : 'Say hi',
    );
  }
}
