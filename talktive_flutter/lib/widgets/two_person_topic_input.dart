import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../helpers/helpers.dart';
import '../models/topic.dart';
import '../services/fireauth.dart';
import '../services/storage.dart';
import '../services/topic_followers_cache.dart';
import '../services/user_cache.dart';
import 'status_notice.dart';

class TwoPersonTopicInput extends StatefulWidget {
  final Topic? topic;
  final FocusNode focusNode;
  final Future<void> Function(String) onSendTextMessage;
  final Future<void> Function(String) onSendImageMessage;
  final void Function(String)? onInsertMention;

  const TwoPersonTopicInput({
    super.key,
    required this.topic,
    required this.focusNode,
    required this.onSendTextMessage,
    required this.onSendImageMessage,
    this.onInsertMention,
  });

  @override
  State<TwoPersonTopicInput> createState() => TwoPersonTopicInputState();
}

class TwoPersonTopicInputState extends State<TwoPersonTopicInput> {
  late ThemeData theme;
  late Fireauth fireauth;
  late Storage storage;
  late UserCache userCache;
  late TopicFollowersCache topicFollowersCache;
  Timer? _refreshTimer;
  final _controller = TextEditingController();
  bool _enabled = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    fireauth = context.read<Fireauth>();
    storage = context.read<Storage>();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
    userCache = Provider.of<UserCache>(context);
    topicFollowersCache = Provider.of<TopicFollowersCache>(context);
    _refreshAgain();
  }

  @override
  void didUpdateWidget(TwoPersonTopicInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.topic?.updatedAt != oldWidget.topic?.updatedAt) {
      _refreshAgain();
    }

    // Update the callback reference
    if (widget.onInsertMention != oldWidget.onInsertMention) {
      // Callback reference has changed, widget will handle this
    }
  }

  void _refreshAgain() {
    if (widget.topic == null) return;

    _refreshTimer?.cancel();

    final timeLeft = _getTimeLeft();
    final user = userCache.user;
    final hasPermission = canSendMessage(user);
    final currentUserId = fireauth.instance.currentUser?.uid;
    final isBlocked =
        currentUserId != null &&
        topicFollowersCache.isUserBlocked(currentUserId);

    _enabled =
        hasPermission &&
        timeLeft > 0 &&
        !widget.topic!.isDummy &&
        !widget.topic!.isClosed &&
        !isBlocked;

    if (timeLeft == 0) return;

    final duration = Duration(milliseconds: timeLeft);

    _refreshTimer = Timer(duration, () {
      if (mounted) {
        setState(() {
          final user = userCache.user;
          final hasPermission = canSendMessage(user);
          final currentUserId = fireauth.instance.currentUser?.uid;
          final isBlocked =
              currentUserId != null &&
              topicFollowersCache.isUserBlocked(currentUserId);
          _enabled =
              hasPermission &&
              !widget.topic!.isDummy &&
              !widget.topic!.isClosed &&
              !isBlocked;
        });
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  int _getTimeLeft() {
    return widget.topic?.getTimeLeft() ?? 0;
  }

  bool _canSendPicture() {
    final user = userCache.user;
    return canSendPrivatePicture(user);
  }

  Future<void> _showPictureRestrictionDialog() async {
    final colorScheme = Theme.of(context).colorScheme;

    const title = 'Cannot Send Picture';
    final content = [
      Text(
        'Sorry, you need floor 4, decent reputation and no restrictions to send pictures.',
        style: TextStyle(height: 1.5, color: colorScheme.error),
      ),
      const SizedBox(height: 16),
      const Text(
        'This helps maintain quality discussions in our community.',
        style: TextStyle(height: 1.5),
      ),
    ];

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: content,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSendImageMessage() async {
    if (!_canSendPicture()) {
      await _showPictureRestrictionDialog();
      return;
    }
    await _sendImageMessage();
  }

  void insertMention(String displayName) {
    final mention = '@$displayName ';
    final currentText = _controller.text;
    final selection = _controller.selection;

    // Handle invalid selection by using end of text
    int start = selection.start;
    int end = selection.end;

    if (start < 0 || start > currentText.length) {
      start = currentText.length;
    }
    if (end < 0 || end > currentText.length) {
      end = currentText.length;
    }
    if (start > end) {
      start = end;
    }

    // Insert mention at cursor position
    final newText = currentText.replaceRange(start, end, mention);

    _controller.text = newText;
    _controller.selection = TextSelection.collapsed(
      offset: start + mention.length,
    );

    // Focus the input field
    widget.focusNode.requestFocus();
  }

  Future<void> _sendTextMessage() async {
    try {
      if (widget.topic?.isDummy == true) {
        throw AppException('The chat has been deleted.');
      }

      if (widget.topic?.isClosed == true) {
        throw AppException('The chat has been closed.');
      }

      const maxLength = 1024;
      var content = _controller.text.trim();

      if (content.length > maxLength) {
        content = '${content.substring(0, maxLength)}...';
      }

      if (content.isEmpty) {
        if (_controller.text.isNotEmpty) {
          _controller.clear();
        }
        return;
      }

      _controller.clear();
      await widget.onSendTextMessage(content);
    } catch (e) {
      if (mounted) {
        ErrorHandler.showSnackBarMessage(
          context,
          e is AppException ? e : AppException(e.toString()),
        );
      }
    }
  }

  Future<void> _sendImageMessage() async {
    if (widget.topic == null) return;

    try {
      if (widget.topic?.isDummy == true) {
        throw AppException('The chat has been deleted.');
      }

      if (widget.topic?.isClosed == true) {
        throw AppException('The chat has been closed.');
      }

      final xFile = await ImagePicker().pickImage(
        imageQuality: 70,
        maxWidth: 1440,
        source: ImageSource.gallery,
        requestFullMetadata: false,
      );

      if (xFile == null) return;

      setState(() => _isUploading = true);

      final data = await xFile.readAsBytes();
      final path = 'topics/${widget.topic!.id}/${xFile.name}';
      final uri = await storage.saveData(path, data);

      await widget.onSendImageMessage(uri);
    } catch (e) {
      if (mounted) {
        ErrorHandler.showSnackBarMessage(
          context,
          e is AppException ? e : AppException(e.toString()),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  KeyEventResult _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final isCtrlOrCommandPressed =
          HardwareKeyboard.instance.isMetaPressed ||
          HardwareKeyboard.instance.isControlPressed;

      final isEnterPressed =
          event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.numpadEnter;

      if (isCtrlOrCommandPressed && isEnterPressed) {
        _sendTextMessage();
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  String _showText({required String enabledText}) {
    if (_enabled) {
      return enabledText;
    }

    final user = userCache.user;
    final currentUserId = fireauth.instance.currentUser?.uid;

    if (currentUserId != null &&
        topicFollowersCache.isUserBlocked(currentUserId)) {
      return 'You are blocked';
    }

    if (!canSendMessage(user)) {
      return 'Account restricted';
    }

    final topic = widget.topic;

    if (topic != null) {
      if (topic.isDummy) return 'Chat deleted';
      if (topic.isClosed) return 'Chat closed';
    }

    return '';
  }

  Widget _buildStatusNotice() {
    final user = userCache.user;
    final currentUserId = fireauth.instance.currentUser?.uid;
    String message;

    if (currentUserId != null &&
        topicFollowersCache.isUserBlocked(currentUserId)) {
      message =
          'You have been blocked from this chat and cannot send messages.';
    } else if (!canSendMessage(user)) {
      message =
          'Your account has been temporarily restricted due to multiple reports of inappropriate behavior. You cannot send messages until this restriction expires.';
    } else if (widget.topic?.isDummy == true) {
      message =
          'This chat has been deleted to protect your privacy. You can start a new conversation with your partner anytime.';
    } else if (widget.topic?.isClosed == true) {
      message =
          'This chat has expired and will be deleted soon. Once deleted, you can start a new conversation with your partner again.';
    } else if (user?.withAlert == true) {
      message =
          'Your account has received reports for inappropriate communications. Please be respectful when chatting. Further reports may result in more severe restrictions.';
    } else {
      return const SizedBox.shrink();
    }

    return StatusNotice(
      content: message,
      icon: Icons.info_outline,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      foregroundColor: theme.colorScheme.onSurface,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.topic != null &&
            (!_enabled ||
                userCache.user?.withAlert == true ||
                (fireauth.instance.currentUser?.uid != null &&
                    topicFollowersCache.isUserBlocked(
                      fireauth.instance.currentUser!.uid,
                    ))))
          _buildStatusNotice(),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Container(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiaryContainer,
              borderRadius: const BorderRadius.all(Radius.circular(32)),
              border: Border.all(color: theme.colorScheme.tertiaryContainer),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: _enabled ? _handleSendImageMessage : null,
                  icon: _isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        )
                      : Icon(
                          Icons.attach_file,
                          color: theme.colorScheme.tertiary,
                        ),
                  tooltip: _showText(enabledText: 'Send picture'),
                ),
                Expanded(
                  child: KeyboardListener(
                    focusNode: FocusNode(),
                    onKeyEvent: _enabled ? _handleKeyEvent : null,
                    child: TextField(
                      enabled: _enabled,
                      focusNode: widget.focusNode,
                      minLines: 1,
                      maxLines: 12,
                      controller: _controller,
                      style: TextStyle(
                        color: theme.colorScheme.onTertiaryContainer,
                      ),
                      decoration: InputDecoration.collapsed(
                        hintText: _showText(enabledText: 'Chat privately'),
                        hintStyle: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _enabled ? _sendTextMessage : null,
                  icon: Icon(Icons.send, color: theme.colorScheme.tertiary),
                  tooltip: _showText(enabledText: 'Send message'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
