import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/helpers.dart';
import '../helpers/topic_message_status_helper.dart';
import '../models/topic_message.dart';
import '../services/fireauth.dart';
import '../services/firestore.dart';
import '../services/follow_cache.dart';
import '../services/user_cache.dart';
import '../theme.dart';
import 'bubble.dart';
import 'image_viewer.dart';
import 'user_info_loader.dart';

class TopicImageMessageItem extends StatefulWidget {
  final String topicId;
  final TopicImageMessage message;
  final void Function(String)? onInsertMention;

  const TopicImageMessageItem({
    super.key,
    required this.topicId,
    required this.message,
    this.onInsertMention,
  });

  @override
  State<TopicImageMessageItem> createState() => _TopicImageMessageItemState();
}

class _TopicImageMessageItemState extends State<TopicImageMessageItem> {
  late ThemeData theme;
  late Fireauth fireauth;
  late Firestore firestore;
  late UserCache userCache;
  late FollowCache followCache;
  late CachedNetworkImageProvider _imageProvider;
  late String _imageUrl;
  bool _isRevealed = false;
  bool _isReportedRevealed = false;

  @override
  void initState() {
    super.initState();
    fireauth = context.read<Fireauth>();
    firestore = context.read<Firestore>();
    _imageUrl = convertUri(widget.message.uri);
    _imageProvider = getCachedImageProvider(widget.message.uri);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
    userCache = Provider.of<UserCache>(context);
    followCache = Provider.of<FollowCache>(context);
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

    if (byMe && !(widget.message.recalled ?? false)) {
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
              Icon(Icons.report, size: 20),
              SizedBox(width: 8),
              Text('Report'),
            ],
          ),
          onTap: () => _showReportDialog(context),
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

  void _showRecallDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recall Image?'),
        content: const Text(
          'This image will be removed from the topic. The action cannot be undone.',
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
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

  Widget _buildToggleButton(bool byMe) {
    return FutureBuilder<bool>(
      future: TopicMessageStatusHelper.isReportedButRevealable(widget.message),
      builder: (context, reportedSnapshot) {
        final isReportedButRevealable = reportedSnapshot.data ?? false;
        final isHiddenButRevealable =
            TopicMessageStatusHelper.isHiddenButRevealable(widget.message);

        // Show toggle button for either hidden or reported but revealable messages
        if ((!isHiddenButRevealable && !isReportedButRevealable) ||
            (widget.message.recalled ?? false)) {
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

  Widget _buildMessageBox(
    BuildContext context,
    BoxConstraints constraints, {
    bool byMe = false,
  }) {
    if (widget.message.recalled ?? false) {
      return Bubble(content: '- Image recalled -', byMe: byMe, isMentioned: false);
    }

    return FutureBuilder<bool>(
      future: TopicMessageStatusHelper.isReportedButRevealable(widget.message),
      builder: (context, reportedSnapshot) {
        final isReportedButRevealable = reportedSnapshot.data ?? false;

        // Check if message should be shown based on report status
        final shouldShow = TopicMessageStatusHelper.shouldShowMessage(
          widget.message,
          isAdmin: false, // TODO: Add admin check if needed
        );

        // Images don't have text content to check for mentions
        final isMentioned = false;

        // Determine what content to display
        Widget contentWidget;

        if (isReportedButRevealable) {
          // Recently reported image - show placeholder or original based on toggle
          if (_isReportedRevealed) {
            contentWidget = _buildCachedImage(context, constraints);
          } else {
            final reportedContent =
                TopicMessageStatusHelper.getReportedMessageContent(
                    widget.message);
            contentWidget = Bubble(content: reportedContent, byMe: byMe, isMentioned: isMentioned);
          }
        } else if (shouldShow) {
          contentWidget = _buildCachedImage(context, constraints);
        } else if (TopicMessageStatusHelper.isHiddenButRevealable(
            widget.message)) {
          if (_isRevealed) {
            contentWidget = _buildCachedImage(context, constraints);
          } else {
            final hiddenContent =
                TopicMessageStatusHelper.getHiddenMessageContent(
                    widget.message);
            contentWidget = Bubble(content: hiddenContent, byMe: byMe, isMentioned: isMentioned);
          }
        } else {
          final hiddenContent =
              TopicMessageStatusHelper.getHiddenMessageContent(widget.message);
          contentWidget = Bubble(content: hiddenContent, byMe: byMe, isMentioned: isMentioned);
        }

        // Add gesture detector for context menu
        return GestureDetector(
          onLongPressStart: (details) =>
              _showContextMenu(context, details.globalPosition),
          child: contentWidget,
        );
      },
    );
  }

  void _showImageViewer(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ImageViewer(imageProvider: _imageProvider),
    );
  }

  Widget _buildCachedImage(BuildContext context, BoxConstraints constraints) {
    final halfWidth = constraints.maxWidth / 2;
    final theme = Theme.of(context);

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: halfWidth, maxHeight: halfWidth),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: GestureDetector(
          onTap: () => _showImageViewer(context),
          child: CachedNetworkImage(
            imageUrl: _imageUrl,
            imageBuilder: (context, imageProvider) =>
                Image(image: imageProvider, fit: BoxFit.contain),
            placeholder: (context, url) =>
                getImagePlaceholder(color: theme.colorScheme.primary),
            errorWidget: (context, url, error) => getImageErrorWidget(),
            cacheKey: widget.message.uri,
            memCacheWidth:
                (halfWidth * MediaQuery.of(context).devicePixelRatio).round(),
          ),
        ),
      ),
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
                    Flexible(child: LayoutBuilder(builder: _buildMessageBox)),
                  ],
                ),
                _buildToggleButton(false),
              ],
            ),
          ),
          const SizedBox(width: 32),
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
          const SizedBox(width: 32),
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
                      child: LayoutBuilder(
                        builder: (context, constraints) =>
                            _buildMessageBox(context, constraints, byMe: true),
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
