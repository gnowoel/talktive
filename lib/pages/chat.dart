import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/exception.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../services/fireauth.dart';
import '../services/firedata.dart';
import '../widgets/hearts.dart';
import '../widgets/input.dart';
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
  late StreamSubscription chatSubscription;
  late StreamSubscription messagesSubscription;

  late Chat _chat;
  late List<Message> _messages;

  @override
  void initState() {
    super.initState();

    focusNode = FocusNode();
    scrollController = ScrollController();

    fireauth = Provider.of<Fireauth>(context, listen: false);
    firedata = Provider.of<Firedata>(context, listen: false);

    _chat = widget.chat;
    _messages = [];

    final userId = fireauth.instance.currentUser!.uid;

    chatSubscription =
        firedata.subscribeToChat(userId, widget.chat.id).listen((chat) {
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

    messagesSubscription =
        firedata.subscribeToMessages(widget.chat.id).listen((messages) {
      setState(() => _messages = messages);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
  }

  Future<void> _updateReadMessageCount(Chat chat) async {
    final userId = fireauth.instance.currentUser!.uid;
    await firedata.updateChatReadMessageCount(
      chat.id,
      userId,
      _messages.length,
    );
  }

  @override
  void dispose() {
    messagesSubscription.cancel();
    chatSubscription.cancel();

    scrollController.dispose();
    focusNode.dispose();

    _updateReadMessageCount(_chat);

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
          RepaintBoundary(
            child: Hearts(chat: _chat),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: _buildLayoutBuilder(),
      ),
    );
  }

  Widget _buildLayoutBuilder() {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth >= 600) {
        return Align(
          alignment: Alignment.center,
          child: Container(
            margin: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.all(
                Radius.circular(24),
              ),
              border: Border.all(color: theme.colorScheme.secondaryContainer),
            ),
            constraints: const BoxConstraints(minWidth: 324, maxWidth: 576),
            child: _buildColumn(),
          ),
        );
      } else {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
          ),
          child: _buildColumn(),
        );
      }
    });
  }

  Widget _buildColumn() {
    return Column(
      children: [
        const SizedBox(height: 10),
        Expanded(
          child: MessageList(
            focusNode: focusNode,
            scrollController: scrollController,
            messages: _messages,
          ),
        ),
        Input(
          focusNode: focusNode,
          chat: _chat,
        ),
      ],
    );
  }
}
