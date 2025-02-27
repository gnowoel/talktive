import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/exception.dart';
import '../models/chat.dart';
import '../services/fireauth.dart';
import '../services/firedata.dart';
import '../services/message_cache.dart';
import '../widgets/hearts.dart';
import '../widgets/layout.dart';
import '../widgets/message_list.dart';
import '../widgets/user_info_loader.dart';

class ReportPage extends StatefulWidget {
  final String userId;
  final Chat chat;

  const ReportPage({super.key, required this.userId, required this.chat});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  late ThemeData theme;
  late FocusNode focusNode;
  late ScrollController scrollController;
  late Fireauth fireauth;
  late Firedata firedata;
  late MessageCache messageCache;
  late StreamSubscription chatSubscription;
  late StreamSubscription messagesSubscription;

  late Chat _chat;

  @override
  void initState() {
    super.initState();

    focusNode = FocusNode();
    scrollController = ScrollController();

    fireauth = context.read<Fireauth>();
    firedata = context.read<Firedata>();
    messageCache = context.read<MessageCache>();

    _chat = widget.chat;

    final userId = widget.userId;

    chatSubscription = firedata.subscribeToChat(userId, widget.chat.id).listen((
      chat,
    ) {
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

    final lastTimestamp = messageCache.getLastTimestamp(widget.chat.id);

    messagesSubscription = firedata
        .subscribeToMessages(widget.chat.id, lastTimestamp)
        .listen((messages) {
          messageCache.addMessages(widget.chat.id, messages);
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
    final userId = widget.userId;
    final otherId = _chat.id.replaceFirst(userId, '');

    showDialog(
      context: context,
      builder:
          (context) => UserInfoLoader(
            userId: otherId,
            photoURL: _chat.partner.photoURL!,
            displayName: _chat.partner.displayName!,
          ),
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
              style: TextStyle(color: theme.colorScheme.error),
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
      builder:
          (context) => AlertDialog(
            icon: Icon(
              Icons.report_outlined,
              color: theme.colorScheme.error,
              size: 32,
            ),
            title: const Text('Report this chat?'),
            content: const Text(
              'If you believe this chat contains inappropriate content or violates our community guidelines, you can report it for review. This action cannot be undone.',
            ),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: Text(
                  'Report',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  // Do nothing for now;
                },
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => _showUserInfo(context),
          child: Text(_chat.partner.displayName!),
        ),
        actions: [
          RepaintBoundary(child: Hearts(chat: _chat)),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showReportMenu(context),
            tooltip: 'More options',
          ),
        ],
      ),
      body: SafeArea(
        child: Layout(
          child: Column(
            children: [
              const SizedBox(height: 10),
              Expanded(
                child: MessageList(
                  chatId: _chat.id,
                  focusNode: focusNode,
                  scrollController: scrollController,
                  updateMessageCount: (int count) {},
                  reporterUserId: widget.userId,
                  isSticky: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
