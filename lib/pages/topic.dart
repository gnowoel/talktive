import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/exception.dart';
import '../models/topic.dart';
import '../services/fireauth.dart';
import '../services/firestore.dart';
import '../services/follow_cache.dart';
import '../services/topic_message_cache.dart';
import '../services/user_cache.dart';
import '../theme.dart';

import '../widgets/layout.dart';
import '../widgets/topic_hearts.dart';
import '../widgets/topic_input.dart';
import '../widgets/topic_message_list.dart';
import '../widgets/user_info_loader.dart';

class TopicPage extends StatefulWidget {
  final String topicId;
  final String topicCreatorId;

  const TopicPage({
    super.key,
    required this.topicId,
    required this.topicCreatorId,
  });

  @override
  State<TopicPage> createState() => _TopicPageState();
}

class _TopicPageState extends State<TopicPage> {
  late ThemeData theme;
  late Fireauth fireauth;
  late Firestore firestore;
  late UserCache userCache;
  late FollowCache followCache;
  late TopicMessageCache topicMessageCache;
  late StreamSubscription topicSubscription;
  late StreamSubscription messagesSubscription;

  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  final GlobalKey<TopicInputState> _inputKey = GlobalKey<TopicInputState>();

  Topic? _topic;
  int _messageCount = 0;
  bool _userHasSentMessage = false;
  bool _isInviting = false;

  @override
  void initState() {
    super.initState();

    fireauth = context.read<Fireauth>();
    firestore = context.read<Firestore>();
    topicMessageCache = context.read<TopicMessageCache>();

    final userId = fireauth.instance.currentUser!.uid;

    topicSubscription =
        firestore.subscribeToTopic(userId, widget.topicId).listen((topic) {
      if (topic.isDummy) {
        setState(() {
          if (_topic == null) {
            _topic = topic.copyWith(id: widget.topicId);
          } else {
            _topic = _topic!.copyWith(updatedAt: 0);
          }
        });
        if (mounted) {
          ErrorHandler.showSnackBarMessage(
            context,
            AppException('The topic has been deleted.'),
            severe: true,
          );
        }
      } else {
        setState(() => _topic = topic);
      }
    });

    final lastTimestamp = topicMessageCache.getLastTimestamp(widget.topicId);

    messagesSubscription = firestore
        .subscribeToTopicMessages(widget.topicId, lastTimestamp)
        .listen((messages) {
      topicMessageCache.addMessages(widget.topicId, messages);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
    userCache = Provider.of<UserCache>(context);
    followCache = Provider.of<FollowCache>(context);
    topicMessageCache = Provider.of<TopicMessageCache>(context);
    _userHasSentMessage = _checkUserMessageStatus();
  }

  @override
  void dispose() {
    messagesSubscription.cancel();
    topicSubscription.cancel();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _sendTextMessage(String content) async {
    try {
      final user = userCache.user!;

      await firestore.sendTopicTextMessage(
        topicId: widget.topicId,
        userId: user.id,
        userDisplayName: user.displayName ?? '',
        userPhotoURL: user.photoURL ?? '',
        content: content,
      );
    } catch (e) {
      if (mounted) {
        ErrorHandler.showSnackBarMessage(
          context,
          e is AppException ? e : AppException(e.toString()),
        );
      }
    }
  }

  Future<void> _sendImageMessage(String uri) async {
    try {
      final user = userCache.user!;

      await firestore.sendTopicImageMessage(
        topicId: widget.topicId,
        userId: user.id,
        userDisplayName: user.displayName ?? '',
        userPhotoURL: user.photoURL ?? '',
        uri: uri,
      );
    } catch (e) {
      if (mounted) {
        ErrorHandler.showSnackBarMessage(
          context,
          e is AppException ? e : AppException(e.toString()),
        );
      }
    }
  }

  void _updateMessageCount(int count) {
    _messageCount = count;
  }

  bool _checkUserMessageStatus() {
    final userId = fireauth.instance.currentUser!.uid;
    final messages = topicMessageCache.getMessages(widget.topicId);

    final userMessages = messages.where((msg) => msg.userId == userId).toList();

    return userMessages.isNotEmpty;
  }

  Future<bool?> _showInviteConfirmationDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite Followers'),
        content: const Text(
          'This will notify your followers and add this topic to their chat list. Do you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _inviteFollowers() async {
    if (_isInviting) return;

    setState(() => _isInviting = true);

    try {
      final userId = fireauth.instance.currentUser!.uid;
      final result =
          await firestore.inviteFollowersToTopic(userId, widget.topicId);

      if (mounted) {
        final invitedCount = result['invitedCount'] as int;
        final message = result['message'] as String;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              invitedCount > 0
                  ? 'Invited $invitedCount followers to join this topic!'
                  : message,
            ),
            backgroundColor:
                invitedCount > 0 ? theme.colorScheme.primary : null,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showSnackBarMessage(
          context,
          e is AppException ? e : AppException(e.toString()),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isInviting = false);
      }
    }
  }

  void _insertMention(String displayName) {
    _inputKey.currentState?.insertMention(displayName);
  }

  Future<void> _updateReadMessageCount() async {
    final selfId = fireauth.instance.currentUser!.uid;
    final count = _messageCount;

    if (count == 0 || count == _topic?.readMessageCount) {
      return;
    }

    await firestore.updateTopicReadMessageCount(
      selfId,
      widget.topicId,
      readMessageCount: count,
    );
  }

  void _showCreatorInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => UserInfoLoader(
        userId: widget.topicCreatorId,
        photoURL: _topic?.creator.photoURL ?? '',
        displayName: _topic?.creator.displayName ?? '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customColors = theme.extension<CustomColors>()!;

    final creator = _topic?.creator;
    final displayName = creator?.displayName;
    final isFriend = followCache.isFollowing(widget.topicCreatorId);
    final byMe = widget.topicCreatorId == fireauth.instance.currentUser!.uid;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        _updateReadMessageCount(); // No wait
        if (context.mounted) {
          Navigator.pop(context, result);
        }
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.surfaceContainerLow,
        appBar: AppBar(
          backgroundColor: theme.colorScheme.surfaceContainerLow,
          title: GestureDetector(
            onTap: () => _showCreatorInfo(context),
            child: Row(
              children: [
                if ((byMe || isFriend) &&
                    displayName != null &&
                    displayName.isNotEmpty) ...[
                  Icon(
                    Icons.grade,
                    size: 20,
                    color: customColors.friendIndicator,
                  ),
                  const SizedBox(width: 5),
                ],
                Expanded(child: Text(_topic?.title ?? '')),
              ],
            ),
          ),
          actions: [
            RepaintBoundary(child: TopicHearts(topic: _topic)),
            if (_userHasSentMessage) ...[
              PopupMenuButton<String>(
                onSelected: _isInviting
                    ? null
                    : (value) async {
                        if (value == 'invite') {
                          final confirmed =
                              await _showInviteConfirmationDialog();
                          if (confirmed == true) {
                            _inviteFollowers();
                          }
                        }
                      },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'invite',
                    enabled: !_isInviting,
                    child: Row(
                      children: [
                        _isInviting
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    theme.colorScheme.primary,
                                  ),
                                ),
                              )
                            : const Icon(Icons.person_add, size: 18),
                        const SizedBox(width: 8),
                        Text(_isInviting ? 'Inviting...' : 'Invite Followers'),
                      ],
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(width: 16),
            ],
          ],
        ),
        body: SafeArea(
          child: Layout(
            child: Column(
              children: [
                const SizedBox(height: 10),
                Expanded(
                  child: TopicMessageList(
                    topicId: widget.topicId,
                    topicCreatorId: widget.topicCreatorId,
                    focusNode: _focusNode,
                    scrollController: _scrollController,
                    updateMessageCount: _updateMessageCount,
                    onInsertMention: _insertMention,
                    readMessageCount: _topic?.readMessageCount,
                  ),
                ),
                TopicInput(
                  key: _inputKey,
                  topic: _topic,
                  focusNode: _focusNode,
                  onSendTextMessage: _sendTextMessage,
                  onSendImageMessage: _sendImageMessage,
                  onInsertMention: _insertMention,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
