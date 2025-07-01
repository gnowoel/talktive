import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/chat_message.dart';
import '../services/fireauth.dart';
import '../services/firedata.dart';
import '../services/firestore.dart';
import '../services/message_meta_cache.dart';
import '../services/user_cache.dart';
import '../helpers/helpers.dart';
import '../helpers/message_status_helper.dart';
import '../helpers/message_recall_helper.dart';
import '../helpers/message_report_helper.dart';
import '../helpers/mention_helper.dart';
import 'bubble.dart';
import 'user_info_loader.dart';

class ChatTextMessageItem extends StatefulWidget {
  final String chatId;
  final ChatTextMessage message;
  final String? reporterUserId;
  final void Function(String)? onInsertMention;

  const ChatTextMessageItem({
    super.key,
    required this.chatId,
    required this.message,
    this.reporterUserId,
    this.onInsertMention,
  });

  @override
  State<ChatTextMessageItem> createState() => _ChatTextMessageItemState();
}

class _ChatTextMessageItemState extends State<ChatTextMessageItem> {
  late ThemeData theme;
  late Fireauth fireauth;
  late Firedata firedata;
  late Firestore firestore;
  late MessageMetaCache messageMetaCache;
  late UserCache userCache;
  bool _isRevealed = false;
  bool _isReportedRevealed = false;

  @override
  void initState() {
    super.initState();
    fireauth = context.read<Fireauth>();
    firedata = context.read<Firedata>();
    firestore = context.read<Firestore>();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
    messageMetaCache = Provider.of<MessageMetaCache>(context, listen: true);
    userCache = Provider.of<UserCache>(context);
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
    final byMe = widget.reporterUserId == null
        ? widget.message.userId == currentUser.uid
        : widget.message.userId == widget.reporterUserId;
    final hasReportPermission = canReportOthers(userCache.user);

    // Check report eligibility first (async operation)
    bool canShowReport = false;
    if (!byMe && hasReportPermission && widget.message.id != null) {
      canShowReport = await MessageStatusHelper.shouldShowReportOptionWithCache(
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
    if (byMe && widget.message.canBeRecalled(messageMetaCache)) {
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
    // Capture the BuildContext before the async gap
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    String contentToCopy;
    if (widget.message.isRecalledWithCache(messageMetaCache)) {
      contentToCopy = widget.message.getRecallStatusText(messageMetaCache);
    } else {
      // Check if message is recently reported
      final isReported = await MessageStatusHelper.isRecentlyReported(
        widget.message,
      );
      if (isReported) {
        contentToCopy = MessageStatusHelper.getReportedCopyContent(
          widget.message,
          widget.message.content,
        );
      } else {
        contentToCopy = MessageStatusHelper.getCopyContent(
          widget.message,
          widget.message.content,
        );
      }
    }

    await Clipboard.setData(ClipboardData(text: contentToCopy));
    if (!mounted) return;

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
          'This message will be removed from the chat. The action cannot be undone.',
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
              _recallMessage();
            },
          ),
        ],
      ),
    );
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
              _reportMessage();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _recallMessage() async {
    try {
      await firedata.recallMessage(widget.chatId, widget.message.id!);
      if (this.context.mounted) {
        ScaffoldMessenger.of(this.context).showSnackBar(
          const SnackBar(
            content: Text('Message recalled successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (this.context.mounted) {
        ScaffoldMessenger.of(
          this.context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Widget _buildToggleButton(bool byMe) {
    return Consumer<MessageMetaCache>(
      builder: (context, cache, child) {
        // Use MessageReportHelper with cache for real-time updates
        final isHidden = widget.message.isHiddenWithCache(cache);
        final reportCount = widget.message.getReportCountWithCache(cache);
        final isReportedButRevealable =
            reportCount > 0 && reportCount < 5; // Adjust threshold as needed
        final isHiddenButRevealable = isHidden;

        // Show toggle button for either hidden or reported but revealable messages
        if ((!isHiddenButRevealable && !isReportedButRevealable) ||
            widget.reporterUserId != null ||
            widget.message.isRecalledWithCache(cache)) {
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isRevealed ? Icons.visibility_off : Icons.visibility,
                      size: 14,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.6,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isRevealed ? 'Hide' : 'Show',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
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

  Future<void> _reportMessage() async {
    try {
      final currentUser = fireauth.instance.currentUser!;

      // No need to wait, show snack bar message immediately
      firestore.reportMessage(
        chatId: widget.chatId,
        messageId: widget.message.id!,
        reporterUserId: currentUser.uid,
      );

      if (this.context.mounted) {
        ScaffoldMessenger.of(this.context).showSnackBar(
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
      if (this.context.mounted) {
        ScaffoldMessenger.of(
          this.context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Widget _buildMessageBox({required String content, bool byMe = false}) {
    return Consumer<MessageMetaCache>(
      builder: (context, cache, child) {
        if (widget.message.isRecalledWithCache(cache)) {
          return Bubble(
            content: widget.message.getRecallStatusText(cache),
            byMe: byMe,
          );
        }

        // Check if this message mentions the current user
        final currentUserName = userCache.user?.displayName ?? '';
        final isMentioned = !byMe && currentUserName.isNotEmpty
            ? MentionHelper.containsExactMention(content, currentUserName)
            : false;

        // Use MessageReportHelper with cache for real-time updates
        final reportCount = widget.message.getReportCountWithCache(cache);
        final isHidden = widget.message.isHiddenWithCache(cache);
        final isFlagged = widget.message.isFlaggedWithCache(cache);
        final isSevere = widget.message.isSevereWithCache(cache);
        final isReportedButRevealable =
            reportCount > 0 && reportCount < 5; // Adjust threshold as needed
        final isHiddenButRevealable = isHidden && !isSevere;

        // Determine what content to display
        String displayContent;

        if (isReportedButRevealable) {
          // Recently reported message - show placeholder or original based on toggle
          displayContent = _isReportedRevealed
              ? content
              : '⚠️ This message has been reported and is under review';
        } else if (isHidden) {
          // Message is hidden due to reports
          displayContent = isHiddenButRevealable && _isRevealed
              ? content
              : '🚫 This message has been hidden due to reports';
        } else if (isFlagged) {
          // Message is flagged but still visible
          displayContent = content;
        } else {
          // Normal message
          displayContent = content;
        }

        // Create the bubble widget with appropriate styling
        Widget bubble = Bubble(
          content: displayContent,
          byMe: byMe,
          isMentioned: isMentioned,
        );

        // Add gesture detector for context menu (no tap-to-toggle)
        if (widget.reporterUserId == null) {
          bubble = GestureDetector(
            onLongPressStart: (details) =>
                _showContextMenu(context, details.globalPosition),
            child: bubble,
          );
        }

        return bubble;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = fireauth.instance.currentUser!;
    final byMe = widget.reporterUserId == null
        ? widget.message.userId == currentUser.uid
        : widget.message.userId == widget.reporterUserId;

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
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Flexible(
                      child: _buildMessageBox(content: widget.message.content),
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
