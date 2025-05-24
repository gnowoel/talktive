import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/exception.dart';
import '../models/private_chat.dart';
import '../services/fireauth.dart';
import '../services/firedata.dart';
import '../services/message_cache.dart';
import '../widgets/hearts.dart';
import '../widgets/layout.dart';
import '../widgets/message_list.dart';
import '../widgets/user_info_loader.dart';

class ReportPage extends StatefulWidget {
  final String userId;
  final PrivateChat chat;

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
  late ReportMessageCache reportMessageCache;
  late StreamSubscription chatSubscription;
  late StreamSubscription messagesSubscription;

  late PrivateChat _chat;

  @override
  void initState() {
    super.initState();

    focusNode = FocusNode();
    scrollController = ScrollController();

    fireauth = context.read<Fireauth>();
    firedata = context.read<Firedata>();
    reportMessageCache = context.read<ReportMessageCache>();

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
              updatedAt: chat.updatedAt, // 0
            );
          });
          if (mounted) {
            ErrorHandler.showSnackBarMessage(
              context,
              AppException('The chat has been deleted.'),
              severe: true,
            );
          }
        } else {
          setState(() => _chat = chat);
        }
      }
    });

    final lastTimestamp = reportMessageCache.getLastTimestamp(widget.chat.id);

    messagesSubscription = firedata
        .subscribeToMessages(widget.chat.id, lastTimestamp)
        .listen((messages) {
          // There might be obsolete records from Friebase offline cache.
          reportMessageCache.addMessages(_chat.id, messages);
          final filteredMessages = messages
              .where((message) => message.createdAt >= _chat.createdAt)
              .toList();

          reportMessageCache.addMessages(widget.chat.id, filteredMessages);
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

  void _showOtherUserInfo(BuildContext context) {
    final userId = widget.userId;
    final otherId = _chat.id.replaceFirst(userId, '');

    showDialog(
      context: context,
      builder: (context) => UserInfoLoader(
        userId: otherId,
        photoURL: _chat.partner.photoURL ?? '',
        displayName: _chat.partner.displayName ?? '',
      ),
    );
  }

  void _showSelfUserInfo(BuildContext context) {
    final userId = widget.userId;

    showDialog(
      context: context,
      builder: (context) =>
          UserInfoLoader(userId: userId, photoURL: '', displayName: ''),
    );
  }

  void _showReportMenu(BuildContext context) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(1000, 0, 0, 0),
      items: [
        PopupMenuItem(
          child: ListTile(
            leading: Icon(Icons.person_outlined),
            title: Text('About reporter'),
          ),
          onTap: () {
            if (mounted) {
              _showSelfUserInfo(context);
            }
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => _showOtherUserInfo(context),
          child: Text(_chat.partner.displayName ?? ''),
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
                  chat: _chat,
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
