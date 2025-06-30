import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/topic_message.dart';
import '../services/fireauth.dart';
import '../services/firestore.dart';
import '../services/follow_cache.dart';
import '../services/message_meta_cache.dart';
import '../services/topic_followers_cache.dart';
import '../services/user_cache.dart';
import '../helpers/helpers.dart';
import '../helpers/topic_message_status_helper.dart';
import '../helpers/mention_helper.dart';
import '../theme.dart';
import 'bubble.dart';
import 'user_info_loader.dart';

class TopicTextMessageItem extends StatefulWidget {
  final String topicId;
  final String topicCreatorId;
  final TopicTextMessage message;
  final void Function(String)? onInsertMention;

  const TopicTextMessageItem({
    super.key,
    required this.topicId,
    required this.topicCreatorId,
    required this.message,
    this.onInsertMention,
  });

  @override
  State<TopicTextMessageItem> createState() => _TopicTextMessageItemState();
}

class _TopicTextMessageItemState extends State<TopicTextMessageItem> {
  late ThemeData theme;
  late Fireauth fireauth;
  late Firestore firestore;
  late UserCache userCache;
  late FollowCache followCache;
  late MessageMetaCache messageMetaCache;
  late TopicFollowersCache topicFollowersCache;
  bool _isRevealed = false;
  bool _isReportedRevealed = false;

  @override
  void initState() {
    super.initState();
    fireauth = context.read<Fireauth>();
    firestore = context.read<Firestore>();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
    userCache = Provider.of<UserCache>(context);
    followCache = Provider.of<FollowCache>(context);
    messageMetaCache = Provider.of<MessageMetaCache>(context);
    topicFollowersCache = Provider.of<TopicFollowersCache>(context);
  }

  void _showUserInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => UserInfoLoader(
        userId: widget.message.userId,
        photoURL: widget.message.userPhotoURL,
        displayName: widget.message.userDisplayName,
      ),
    );
  }

  void _showContextMenu(BuildContext context, Offset position) async {
    final currentUser = fireauth.instance.currentUser!;
    final byMe = widget.message.userId == currentUser.uid;
    final hasReportPermission = canReportOthers(userCache.user);

    // Blocked users cannot access context menu
    if (topicFollowersCache.isUserBlocked(currentUser.uid)) {
      return;
    }

    // Check if current user can block others (admin/moderator or topic creator)
    final canBlock = !byMe &&
        (userCache.user?.isAdminOrModerator == true ||
            currentUser.uid == widget.topicCreatorId);

    // Check report eligibility first (async operation)
    bool canShowReport = false;
    if (!byMe && hasReportPermission && widget.message.id != null) {
      canShowReport =
          await TopicMessageStatusHelper.shouldShowReportOptionWithCache(
        widget.message,
        byMe,
      );
    }

    // Build menu after async operations are complete
    if (!mounted) return;

    final menuItems = <PopupMenuEntry>[];

    // Always show Copy option
    menuItems.add(
      PopupMenuItem(
        child: Row(
          children: const [
            Icon(Icons.copy, size: 20),
            SizedBox(width: 8),
            Text('Copy'),
          ],
        ),
        onTap: () => _copyToClipboard(context),
      ),
    );

    // Show Recall option only for own messages that haven't been recalled
    if (byMe && !messageMetaCache.isMessageRecalledWithFallback(
        widget.message.id ?? '', widget.message.recalled ?? false)) {
      menuItems.add(
        PopupMenuItem(
          child: Row(
            children: const [
              Icon(Icons.replay, size: 20),
              SizedBox(width: 8),
              Text('Recall'),
            ],
          ),
          onTap: () => _showRecallDialog(context),
        ),
      );
    }

    // Add report option if eligible
    if (canShowReport) {
      menuItems.add(
        PopupMenuItem(
          child: Row(
            children: const [
              Icon(Icons.report_outlined, size: 20),
              SizedBox(width: 8),
              Text('Report'),
            ],
          ),
          onTap: () => _showReportDialog(context),
        ),
      );
    }

    // Add block option if user has permission and target user is not already blocked
    if (canBlock && !topicFollowersCache.isUserBlocked(widget.message.userId)) {
      menuItems.add(
        PopupMenuItem(
          child: Row(
            children: const [
              Icon(Icons.block, size: 20),
              SizedBox(width: 8),
              Text('Block'),
            ],
          ),
          onTap: () => _showBlockDialog(context),
        ),
      );
    }

    if (menuItems.isNotEmpty) {
      showMenu(
        context: this.context,
        position: RelativeRect.fromLTRB(
          position.dx,
          position.dy,
          position.dx + 1,
          position.dy + 1,
        ),
        items: menuItems,
      );
    }
  }

  Future<void> _copyToClipboard(BuildContext context) async {
    // Capture the ScaffoldMessenger before the async operation
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    String contentToCopy;
    if (messageMetaCache.isMessageRecalledWithFallback(
        widget.message.id ?? '', widget.message.recalled ?? false)) {
      contentToCopy = '- Message recalled -';
    } else {
      // Check if message is recently reported
      final isReported =
          await TopicMessageStatusHelper.isRecentlyReported(widget.message);
      if (isReported) {
        contentToCopy = TopicMessageStatusHelper.getReportedCopyContent(
            widget.message, widget.message.content,
            followersCache: topicFollowersCache);
      } else {
        contentToCopy = TopicMessageStatusHelper.getCopyContent(
            widget.message, widget.message.content,
            followersCache: topicFollowersCache);
      }
    }

    await Clipboard.setData(ClipboardData(text: contentToCopy));
    if (!mounted) return;

    // Use the captured ScaffoldMessenger instead of getting it from context
    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Text('Message copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showRecallDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recall Message?'),
        content: const Text(
          'This message will be removed from the topic. The action cannot be undone.',
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Recall'),
            onPressed: () {
              Navigator.of(context).pop();
              _recallMessage(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _recallMessage(BuildContext context) async {
    if (widget.message.id == null) return;

    try {
      await firestore.recallTopicMessage(
        topicId: widget.topicId,
        messageId: widget.message.id!,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.report_outlined,
          color: theme.colorScheme.error,
          size: 32,
        ),
        title: const Text('Report this message?'),
        content: const Text(
          'If you believe this is an inappropriate message, you can report it for review. This action cannot be undone.',
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
              _reportMessage(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _reportMessage(BuildContext context) async {
    try {
      final currentUser = fireauth.instance.currentUser!;

      // No need to wait, show snack bar message immediately
      firestore.reportTopicMessage(
        topicId: widget.topicId,
        messageId: widget.message.id!,
        reporterUserId: currentUser.uid,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: theme.colorScheme.errorContainer,
            content: Text(
              'Thank you for your report. We will review it shortly.',
              style: TextStyle(color: theme.colorScheme.onErrorContainer),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  void _showBlockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.block_outlined,
          color: theme.colorScheme.error,
          size: 32,
        ),
        title: const Text('Block this user?'),
        content: const Text(
          'Blocking this user will ban them from this topic. All their messages will be hidden, and they will lose access to all interactions within the topic.',
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text(
              'Block',
              style: TextStyle(color: theme.colorScheme.error),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              _blockUser(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _blockUser(BuildContext context) async {
    try {
      await firestore.blockUserFromTopic(
        topicId: widget.topicId,
        userId: widget.message.userId,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: theme.colorScheme.errorContainer,
            content: Text(
              'User has been blocked from this topic.',
              style: TextStyle(color: theme.colorScheme.onErrorContainer),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Widget _buildToggleButton(bool byMe) {
    return FutureBuilder<bool>(
      future: TopicMessageStatusHelper.isReportedButRevealable(widget.message),
      builder: (context, reportedSnapshot) {
        final isReportedButRevealable = reportedSnapshot.data ?? false;
        final isHiddenButRevealable =
            TopicMessageStatusHelper.isHiddenButRevealable(widget.message);

        // Show toggle button for either hidden or reported but revealable messages
        if ((!isHiddenButRevealable && !isReportedButRevealable) ||
            messageMetaCache.isMessageRecalledWithFallback(
                widget.message.id ?? '', widget.message.recalled ?? false)) {
          return const SizedBox.shrink();
        }

        // Determine which toggle state to use
        final isRevealed =
            isReportedButRevealable ? _isReportedRevealed : _isRevealed;
        final toggleAction = isReportedButRevealable
            ? () => setState(() => _isReportedRevealed = !_isReportedRevealed)
            : () => setState(() => _isRevealed = !_isRevealed);

        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Align(
            alignment: byMe ? Alignment.centerRight : Alignment.centerLeft,
            child: InkWell(
              onTap: toggleAction,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isRevealed ? Icons.visibility_off : Icons.visibility,
                      size: 14,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isRevealed ? 'Hide' : 'Show',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageBox({
    required String content,
    bool byMe = false,
    bool byOp = false,
  }) {
    if (messageMetaCache.isMessageRecalledWithFallback(
        widget.message.id ?? '', widget.message.recalled ?? false)) {
      return Bubble(
        content: '- Message recalled -',
        byMe: byMe,
        byOp: byOp,
      );
    }

    return FutureBuilder<bool>(
      future: TopicMessageStatusHelper.isReportedButRevealable(widget.message),
      builder: (context, reportedSnapshot) {
        final isReportedButRevealable = reportedSnapshot.data ?? false;

        // Check if message should be shown based on report status
        final shouldShow = TopicMessageStatusHelper.shouldShowMessage(
          widget.message,
          isAdmin: false, // TODO: Add admin check if needed
          followersCache: topicFollowersCache,
        );

        // Determine what content to display
        String displayContent;

        // Check if message is from a blocked user first (highest priority)
        if (topicFollowersCache.isUserBlocked(widget.message.userId)) {
          displayContent =
              TopicMessageStatusHelper.getBlockedUserMessageContent(
                  widget.message);
        } else if (isReportedButRevealable) {
          // Recently reported message - show placeholder or original based on toggle
          displayContent = _isReportedRevealed
              ? content
              : TopicMessageStatusHelper.getReportedMessageContent(
                  widget.message);
        } else if (shouldShow) {
          displayContent = content;
        } else if (TopicMessageStatusHelper.isHiddenButRevealable(
            widget.message)) {
          displayContent = _isRevealed
              ? content
              : TopicMessageStatusHelper.getHiddenMessageContent(
                  widget.message);
        } else {
          displayContent =
              TopicMessageStatusHelper.getHiddenMessageContent(widget.message);
        }

        // Check if this message mentions the current user
        final currentUserName = userCache.user?.displayName ?? '';
        final isMentioned = !byMe && currentUserName.isNotEmpty
            ? MentionHelper.containsExactMention(content, currentUserName)
            : false;

        // Create the bubble widget with appropriate styling
        Widget bubble = Bubble(
          content: displayContent,
          byMe: byMe,
          byOp: byOp,
          isMentioned: isMentioned,
        );

        // Add gesture detector for context menu
        return GestureDetector(
          onLongPressStart: (details) =>
              _showContextMenu(context, details.globalPosition),
          child: bubble,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = fireauth.instance.currentUser!;
    final byMe = widget.message.userId == currentUser.uid;

    return byMe
        ? _buildMessageItemRight(context)
        : _buildMessageItemLeft(context);
  }

  Widget _buildMessageItemLeft(BuildContext context) {
    final byOp = widget.message.userId == widget.topicCreatorId;

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _showUserInfo(context),
            onLongPress: () {
              if (widget.onInsertMention != null) {
                widget.onInsertMention!(widget.message.userDisplayName);
              }
            },
            child: Text(
              widget.message.userPhotoURL,
              style: const TextStyle(fontSize: 24),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (followCache.isFollowing(widget.message.userId)) ...[
                        Icon(
                          Icons.grade,
                          size: 16,
                          color:
                              theme.extension<CustomColors>()!.friendIndicator,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        widget.message.userDisplayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Flexible(
                      child: _buildMessageBox(
                        content: widget.message.content,
                        byOp: byOp,
                      ),
                    ),
                  ],
                ),
                _buildToggleButton(false),
              ],
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildMessageItemRight(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 48),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 4, bottom: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (followCache.isFollowing(widget.message.userId)) ...[
                        Icon(
                          Icons.grade,
                          size: 16,
                          color:
                              theme.extension<CustomColors>()!.friendIndicator,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        widget.message.userDisplayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: _buildMessageBox(
                        content: widget.message.content,
                        byMe: true,
                      ),
                    ),
                  ],
                ),
                _buildToggleButton(true),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _showUserInfo(context),
            onLongPress: () {
              if (widget.onInsertMention != null) {
                widget.onInsertMention!(widget.message.userDisplayName);
              }
            },
            child: Text(
              widget.message.userPhotoURL,
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ],
      ),
    );
  }
}
