import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:talktive/widgets/status_notice.dart';

import '../helpers/exception.dart';
import '../models/chat.dart';
import '../models/user.dart';
import '../services/fireauth.dart';
import '../services/firedata.dart';
import '../services/follow_cache.dart';

import '../services/paginated_message_service.dart';
import '../theme.dart';
import '../widgets/hearts.dart';
import '../widgets/input.dart';
import '../widgets/layout.dart';

import '../widgets/paginated_message_list.dart';
import '../widgets/user_info_loader.dart';

class ChatPage extends StatefulWidget {
  final Chat chat;

  const ChatPage({super.key, required this.chat});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late ThemeData theme;
  late Fireauth fireauth;
  late Firedata firedata;
  late FollowCache followCache;

  late PaginatedMessageService paginatedMessageService;
  late StreamSubscription chatSubscription;
  late Chat _chat;

  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  final GlobalKey<InputState> _inputKey = GlobalKey<InputState>();

  int _messageCount = 0;
  bool _chatPopulated = false;

  @override
  void initState() {
    super.initState();

    fireauth = context.read<Fireauth>();
    firedata = context.read<Firedata>();

    paginatedMessageService = context.read<PaginatedMessageService>();

    _chat = widget.chat;

    final selfId = fireauth.instance.currentUser!.uid;

    chatSubscription = firedata.subscribeToChat(selfId, _chat.id).listen((
      chat,
    ) {
      if (!mounted) return;

      if (_chat.isDummy) {
        if (chat.isDummy) {
          // Ignore to avoid being overwitten.
        } else {
          setState(() {
            _chat = chat;
            _chatPopulated = true;
          });
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
          setState(() {
            _chat = chat;
            _chatPopulated = true;
          });
        }
      }
    });

    // Real-time message updates are now handled by the paginated service
    // Load initial messages through the paginated service
    paginatedMessageService.loadChatMessages(
      _chat.id,
      isInitialLoad: true,
      chatCreatedAt: _chat.createdAt,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
    followCache = Provider.of<FollowCache>(context);
  }

  @override
  void dispose() {
    chatSubscription.cancel();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _showUserInfo(BuildContext context) {
    final selfId = fireauth.instance.currentUser!.uid;
    final otherId = _chat.id.replaceFirst(selfId, '');

    showDialog(
      context: context,
      builder: (context) => UserInfoLoader(
        userId: otherId,
        photoURL: _chat.partner.photoURL ?? '',
        displayName: _chat.partner.displayName ?? '',
      ),
    );
  }

  void _updateMessageCount(int count) {
    _messageCount = count;
  }

  void _insertMention(String displayName) {
    _inputKey.currentState?.insertMention(displayName);
  }

  Future<void> _updateReadMessageCount(Chat chat) async {
    final count = _messageCount;
    final selfId = fireauth.instance.currentUser!.uid;

    if (count == 0 || count == _chat.readMessageCount) {
      return;
    }

    await firedata.updateChat(selfId, chat.id, readMessageCount: count);
  }

  @override
  Widget build(BuildContext context) {
    final customColors = theme.extension<CustomColors>()!;

    final chatId = _chat.id;
    final selfId = fireauth.instance.currentUser!.uid;
    final otherId = chatId.replaceFirst(selfId, '');
    final partner = User.fromStub(key: otherId, value: _chat.partner);

    final partnerDisplayName = partner.displayName;
    final partnerStatus = partner.status;
    final isFriend = followCache.isFollowing(partner.id);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        _updateReadMessageCount(_chat); // No wait
        if (context.mounted) {
          Navigator.pop(context, result);
        }
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.surfaceContainerLow,
        appBar: AppBar(
          backgroundColor: theme.colorScheme.surfaceContainerLow,
          title: GestureDetector(
            onTap: () => _showUserInfo(context),
            child: Row(
              children: [
                if (isFriend &&
                    partnerDisplayName != null &&
                    partnerDisplayName.isNotEmpty) ...[
                  Icon(
                    Icons.grade,
                    size: 20,
                    color: customColors.friendIndicator,
                  ),
                  const SizedBox(width: 5),
                ],
                Expanded(child: Text(partnerDisplayName ?? '')),
              ],
            ),
          ),
          actions: [
            RepaintBoundary(child: Hearts(chat: _chat)),
            const SizedBox(width: 16),
          ],
        ),
        body: SafeArea(
          child: Layout(
            child: Column(
              children: [
                const SizedBox(height: 10),
                if (partnerStatus == 'warning') ...[
                  _buildWarningBox(),
                ] else if (partnerStatus == 'alert') ...[
                  _buildAlertBox(),
                ],
                Expanded(
                  child: PaginatedMessageList.chat(
                    id: _chat.id,
                    chat: _chat,
                    focusNode: _focusNode,
                    scrollController: _scrollController,
                    updateMessageCount: _updateMessageCount,
                    onInsertMention: _insertMention,
                  ),
                ),
                Input(
                  key: _inputKey,
                  focusNode: _focusNode,
                  chat: _chat,
                  chatPopulated: _chatPopulated,
                  onInsertMention: _insertMention,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlertBox() {
    return StatusNotice(
      content:
          'This user has been reported for sending offensive messages. Be careful!',
      icon: Icons.error_outline,
      backgroundColor: theme.colorScheme.tertiaryContainer,
      foregroundColor: theme.colorScheme.onTertiaryContainer,
    );
  }

  Widget _buildWarningBox() {
    return StatusNotice(
      content:
          'This user has been reported for inappropriate behavior. Stay safe!',
      icon: Icons.error_outline,
      backgroundColor: theme.colorScheme.errorContainer,
      foregroundColor: theme.colorScheme.onErrorContainer,
    );
  }
}
