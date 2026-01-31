import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/exception.dart';
import '../models/topic.dart';

import '../services/fireauth.dart';
import '../services/firestore.dart';
import '../services/follow_cache.dart';
import '../services/message_meta_cache.dart';
import '../services/paginated_message_service.dart';
import '../services/topic_cache.dart';
import '../services/topic_followers_cache.dart';
import '../services/user_cache.dart';
import '../theme.dart';

import '../widgets/layout.dart';
import '../widgets/status_notice.dart';
import '../widgets/topic_hearts.dart';
import '../widgets/two_person_topic_input.dart';
import '../widgets/paginated_message_list.dart';
import '../widgets/user_info_loader.dart';

class TwoPersonTopicPage extends StatefulWidget {
  final String topicId;
  final String topicCreatorId;

  const TwoPersonTopicPage({
    super.key,
    required this.topicId,
    required this.topicCreatorId,
  });

  @override
  State<TwoPersonTopicPage> createState() => _TwoPersonTopicPageState();
}

class _TwoPersonTopicPageState extends State<TwoPersonTopicPage> {
  late ThemeData theme;
  late Fireauth fireauth;
  late Firestore firestore;
  late UserCache userCache;
  late FollowCache followCache;
  late TopicFollowersCache topicFollowersCache;
  late MessageMetaCache messageMetaCache;
  late TopicCache topicCache;

  late PaginatedMessageService paginatedMessageService;
  late StreamSubscription topicSubscription;

  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  final GlobalKey<TwoPersonTopicInputState> _inputKey =
      GlobalKey<TwoPersonTopicInputState>();

  Topic? _topic;
  int _messageCount = 0;
  bool _userHasSentMessage = false;
  bool _hasSubscribedToMessageMeta = false;

  @override
  void initState() {
    super.initState();

    fireauth = context.read<Fireauth>();
    firestore = context.read<Firestore>();
    topicFollowersCache = context.read<TopicFollowersCache>();

    paginatedMessageService = context.read<PaginatedMessageService>();

    // Reset pagination state to ensure fresh loading when entering topic
    paginatedMessageService.resetTopicPagination(widget.topicId);

    final userId = fireauth.instance.currentUser!.uid;

    topicSubscription =
        firestore.subscribeToTopic(userId, widget.topicId).listen((topic) {
      if (!mounted) return;

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
            AppException('The chat has been deleted.'),
            severe: true,
          );
        }
      } else {
        setState(() => _topic = topic);
        // Sync total message count with pagination service first
        paginatedMessageService.updateTopicTotalMessageCount(
          widget.topicId,
          topic.messageCount,
        );
        // Then update topic cache with the latest data
        topicCache.updateTopic(topic);
      }
    });

    // Subscribe to topic followers for real-time blocking updates
    topicFollowersCache.subscribeToTopic(widget.topicId);

    // Real-time message updates are now handled by the paginated service
    // SimplePaginatedMessageList will handle loading its own messages
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
    userCache = Provider.of<UserCache>(context);
    followCache = Provider.of<FollowCache>(context);
    messageMetaCache = Provider.of<MessageMetaCache>(context);
    topicCache = Provider.of<TopicCache>(context);

    // Subscribe to message metadata for real-time recall updates
    if (!_hasSubscribedToMessageMeta) {
      messageMetaCache.subscribeToTopic(widget.topicId);
      _hasSubscribedToMessageMeta = true;
    }

    _userHasSentMessage = _checkUserMessageStatus();
  }

  @override
  void dispose() {
    topicSubscription.cancel();
    topicFollowersCache.unsubscribe();
    // Clean up message metadata cache
    messageMetaCache.unsubscribe();
    _scrollController.dispose();
    _focusNode.dispose();
    // Clean up paginated service state for this topic
    paginatedMessageService.clearTopicData(widget.topicId);
    super.dispose();
  }

  Future<void> _sendTextMessage(String content) async {
    try {
      final user = userCache.user;
      if (user == null) {
        throw AppException('User not authenticated');
      }

      await firestore.sendTopicTextMessage(
        topicId: widget.topicId,
        userId: user.id,
        userDisplayName: user.displayName ?? '',
        userPhotoURL: user.photoURL ?? '',
        content: content,
      );

      // Update user message status after successful send
      if (mounted) {
        setState(() {
          _userHasSentMessage = true;
        });
      }
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
      final user = userCache.user;
      if (user == null) {
        throw AppException('User not authenticated');
      }

      await firestore.sendTopicImageMessage(
        topicId: widget.topicId,
        userId: user.id,
        userDisplayName: user.displayName ?? '',
        userPhotoURL: user.photoURL ?? '',
        uri: uri,
      );

      // Update user message status after successful send
      if (mounted) {
        setState(() {
          _userHasSentMessage = true;
        });
      }
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
    if (_messageCount != count) {
      _messageCount = count;

      // Always sync with the total count from pagination service
      final totalCount =
          paginatedMessageService.getTopicTotalMessageCount(widget.topicId);
      if (totalCount != null && _topic != null) {
        // Update the local topic object with the accurate count if different
        if (totalCount != _topic!.messageCount) {
          final updatedTopic = _topic!.copyWith(messageCount: totalCount);
          setState(() {
            _topic = updatedTopic;
          });
          // Immediately update the cache to ensure consistency
          topicCache.updateTopic(updatedTopic);
        }
      }
      // Update user message status based on message count
      final newStatus = _checkUserMessageStatus();
      if (_userHasSentMessage != newStatus) {
        setState(() {
          _userHasSentMessage = newStatus;
        });
      }
    }
  }

  bool _checkUserMessageStatus() {
    // Check if the current user has sent any messages in this topic
    // This will be updated when messages are loaded through the service
    final state = paginatedMessageService.getTopicState(widget.topicId);
    if (state?.messages.isNotEmpty == true) {
      final currentUserId = fireauth.instance.currentUser?.uid;
      return state!.messages.any((message) => message.userId == currentUserId);
    }
    return false;
  }

  void _insertMention(String displayName) {
    _inputKey.currentState?.insertMention(displayName);
  }

  Future<void> _updateReadMessageCount() async {
    try {
      final selfId = fireauth.instance.currentUser?.uid;
      if (selfId == null || _topic == null) return;

      // Use the latest message count from pagination service
      final latestTotalCount =
          paginatedMessageService.getTopicTotalMessageCount(widget.topicId);
      final count = latestTotalCount ?? _messageCount;

      // Skip if no change needed
      if (count == 0 || count == _topic!.readMessageCount) {
        return;
      }

      // Store original topic for rollback
      final originalTopic = _topic!;

      // Create updated topic with both message count and read count
      final updatedTopic = _topic!.copyWith(
        readMessageCount: count,
        messageCount: latestTotalCount ?? _topic!.messageCount,
      );
      // Optimistically update UI and cache
      setState(() {
        _topic = updatedTopic;
      });
      topicCache.updateTopic(updatedTopic);

      try {
        await firestore.updateTopicReadMessageCount(
          selfId,
          widget.topicId,
          readMessageCount: count,
        );
      } catch (updateError) {
        // Revert optimistic update on failure
        if (mounted) {
          setState(() {
            _topic = originalTopic;
          });
          topicCache.updateTopic(originalTopic);
        }
        debugPrint('Failed to update read message count: $updateError');
        rethrow; // Re-throw to be caught by outer catch
      }
    } catch (e) {
      // Log the error but don't show to user
      debugPrint('Error in _updateReadMessageCount: $e');
    }
  }

  void _showUserInfo(BuildContext context) {
    if (_topic == null) return;

    // In two-person topics, the _topic.creator always contains the OTHER person's info
    // because the createTopic function stores the other participant as the "creator"
    showDialog(
      context: context,
      builder: (context) => UserInfoLoader(
        userId: _topic!.creator.id,
        photoURL: _topic!.creator.photoURL ?? '',
        displayName: _topic!.creator.displayName ?? '',
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

  String? _getOtherPersonStatus() {
    if (_topic == null) return null;

    // In two-person topics, _topic.creator always contains the OTHER person's info
    return _topic!.creator.status;
  }

  @override
  Widget build(BuildContext context) {
    final customColors = theme.extension<CustomColors>()!;

    final creator = _topic?.creator;
    final displayName = creator?.displayName;
    final isFriend = followCache.isFollowing(creator?.id ?? '');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _updateReadMessageCount();
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
            const SizedBox(width: 16),
          ],
        ),
        body: SafeArea(
          child: Layout(
            child: Column(
              children: [
                const SizedBox(height: 10),
                if (_getOtherPersonStatus() == 'warning') ...[
                  _buildWarningBox(),
                ] else if (_getOtherPersonStatus() == 'alert') ...[
                  _buildAlertBox(),
                ],
                Expanded(
                  child: PaginatedMessageList(
                    id: widget.topicId,
                    topicCreatorId: widget.topicCreatorId,
                    focusNode: _focusNode,
                    scrollController: _scrollController,
                    updateMessageCount: _updateMessageCount,
                    onInsertMention: _insertMention,
                    readMessageCount: _topic?.readMessageCount ?? 0,
                    isTwoPersonTopic: true,
                  ),
                ),
                TwoPersonTopicInput(
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
