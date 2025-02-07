import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/exception.dart';
import '../helpers/status.dart';
import '../models/chat.dart';
import '../models/user.dart';
import '../services/fireauth.dart';
import '../services/firedata.dart';
import '../services/message_cache.dart';
import '../services/server_clock.dart';
import '../widgets/hearts.dart';
import '../widgets/input.dart';
import '../widgets/layout.dart';
import '../widgets/message_list.dart';
import '../widgets/user_info_loader.dart';

class ChatPage extends StatefulWidget {
  final Chat chat;

  const ChatPage({
    super.key,
    required this.chat,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late ThemeData theme;
  late FocusNode focusNode;
  late ScrollController scrollController;
  late Fireauth fireauth;
  late Firedata firedata;
  late MessageCache messageCache;
  late StreamSubscription chatSubscription;
  late StreamSubscription messagesSubscription;

  late Chat _chat;

  int _messageCount = 0;

  @override
  void initState() {
    super.initState();

    focusNode = FocusNode();
    scrollController = ScrollController();

    fireauth = context.read<Fireauth>();
    firedata = context.read<Firedata>();
    messageCache = context.read<MessageCache>();

    _chat = widget.chat;

    final userId = fireauth.instance.currentUser!.uid;

    chatSubscription =
        firedata.subscribeToChat(userId, _chat.id).listen((chat) {
      if (_chat.isDummy) {
        if (chat.isDummy) {
          // Ignore to avoid being overwitten.
        } else {
          setState(() => _chat = chat);
        }
      } else {
        if (chat.isDummy) {
          setState(() {
            _chat = _chat.copyWith(
              createdAt: chat.createdAt, // 0
              updatedAt: chat.updatedAt, // 0
            );
          });
          if (mounted) {
            ErrorHandler.showSnackBarMessage(
              context,
              AppException('The room has been deleted.'),
              severe: true,
            );
          }
        } else {
          setState(() => _chat = chat);
        }
      }
    });

    final lastTimestamp = messageCache.getLastTimestamp(_chat.id);

    messagesSubscription = firedata
        .subscribeToMessages(_chat.id, lastTimestamp)
        .listen((messages) {
      messageCache.addMessages(_chat.id, messages);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
  }

  @override
  void dispose() {
    messagesSubscription.cancel();
    chatSubscription.cancel();
    scrollController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  void _showUserInfo(BuildContext context) {
    final userId = fireauth.instance.currentUser!.uid;
    final otherId = _chat.id.replaceFirst(userId, '');

    showDialog(
      context: context,
      builder: (context) => UserInfoLoader(
        userId: otherId,
        photoURL: _chat.partner.photoURL!,
        displayName: _chat.partner.displayName!,
      ),
    );
  }

  void _updateMessageCount(int count) {
    _messageCount = count;
  }

  Future<void> _updateReadMessageCount(Chat chat) async {
    final count = _messageCount;

    if (count == 0 || count == _chat.readMessageCount) {
      return;
    }

    await firedata.updateChat(
      fireauth.instance.currentUser!.uid,
      chat.id,
      readMessageCount: count,
    );
  }

  void _showReportMenu(BuildContext context) {
    final theme = Theme.of(context);

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(1000, 0, 0, 0),
      items: [
        PopupMenuItem(
          child: ListTile(
            leading: Icon(
              Icons.report_outlined,
              color: theme.colorScheme.error,
            ),
            title: Text(
              'Report chat',
              style: TextStyle(
                color: theme.colorScheme.error,
              ),
            ),
          ),
          onTap: () {
            if (mounted) {
              _showReportDialog();
            }
          },
        ),
      ],
    );
  }

  void _showReportDialog() {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.report_outlined,
          color: theme.colorScheme.error,
          size: 32,
        ),
        title: const Text('Report this chat?'),
        content: const Text(
            'If you believe this chat contains inappropriate content or violates our community guidelines, you can report it for review. This action cannot be undone.'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text(
              'Report',
              style: TextStyle(
                color: theme.colorScheme.error,
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              _reportChat();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _reportChat() async {
    final theme = Theme.of(context);

    try {
      final userId = fireauth.instance.currentUser!.uid;
      final partnerDisplayName = _chat.partner.displayName;

      // Add report to database
      await firedata.reportChat(
        userId: userId,
        chatId: _chat.id,
        partnerDisplayName: partnerDisplayName,
      );

      // Mute the chat (problematic, would somehow mess up the message cache)
      // await firedata.updateChat(
      //   userId,
      //   _chat.id,
      //   mute: true,
      // );

      await firedata.updateChat(
        userId,
        _chat.id,
        reported: true,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: theme.colorScheme.errorContainer,
          content: Text(
            'Thank you for your report. We will review it shortly.',
            style: TextStyle(
              color: theme.colorScheme.onErrorContainer,
            ),
          ),
        ),
      );
    } on AppException catch (e) {
      if (!mounted) return;
      ErrorHandler.showSnackBarMessage(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.fromMillisecondsSinceEpoch(ServerClock().now);
    final userStatus =
        getUserStatus(User.fromStub(key: '', value: _chat.partner), now);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _updateReadMessageCount(_chat);
        if (context.mounted) {
          Navigator.pop(context, result);
        }
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.surfaceContainerLow,
        appBar: AppBar(
          title: GestureDetector(
            onTap: () => _showUserInfo(context),
            child: Text(_chat.partner.displayName!),
          ),
          actions: [
            RepaintBoundary(
              child: Hearts(chat: _chat),
            ),
            if (_chat.reported == true) ...[
              const SizedBox(width: 16),
            ] else ...[
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => _showReportMenu(context),
                tooltip: 'More options',
              ),
            ],
          ],
        ),
        body: SafeArea(
          child: Layout(
            child: Column(
              children: [
                const SizedBox(height: 10),
                if (userStatus == 'warning') ...[
                  _buildWarningBox(),
                ] else if (userStatus == 'alert') ...[
                  _buildAlertBox(),
                ],
                Expanded(
                  child: MessageList(
                    chatId: _chat.id,
                    focusNode: focusNode,
                    scrollController: scrollController,
                    updateMessageCount: _updateMessageCount,
                  ),
                ),
                Input(
                  focusNode: focusNode,
                  chat: _chat,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlertBox() {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      color: theme.colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 16,
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              size: 16,
              color: theme.colorScheme.onTertiaryContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'This user has been reported for offensive messages. Be careful!',
                style: TextStyle(
                  color: theme.colorScheme.onTertiaryContainer,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningBox() {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 16,
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              size: 16,
              color: theme.colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'This user has been reported for inappropriate behavior. Stay safe!',
                style: TextStyle(
                  color: theme.colorScheme.onErrorContainer,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
