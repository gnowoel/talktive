import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../helpers/helpers.dart';
import '../models/topic.dart';
import '../services/follow_cache.dart';
import '../services/storage.dart';
import '../services/user_cache.dart';
import 'status_notice.dart';

class TopicInput extends StatefulWidget {
  final Topic? topic;
  final FocusNode focusNode;
  final Future<void> Function(String) onSendTextMessage;
  final Future<void> Function(String) onSendImageMessage;
  final void Function(String)? onInsertMention;

  const TopicInput({
    super.key,
    required this.topic,
    required this.focusNode,
    required this.onSendTextMessage,
    required this.onSendImageMessage,
    this.onInsertMention,
  });

  @override
  State<TopicInput> createState() => TopicInputState();
}

class TopicInputState extends State<TopicInput> {
  late ThemeData theme;
  late Storage storage;
  late UserCache userCache;
  late FollowCache followCache;
  Timer? _refreshTimer;
  final _controller = TextEditingController();
  bool _enabled = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    storage = context.read<Storage>();
    userCache = context.read<UserCache>();
    followCache = context.read<FollowCache>();
    _refreshAgain();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
  }

  @override
  void didUpdateWidget(TopicInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.topic?.updatedAt != oldWidget.topic?.updatedAt) {
      _refreshAgain();
    }

    // Update the callback reference
    if (widget.onInsertMention != oldWidget.onInsertMention) {
      // Callback reference has changed, widget will handle this
    }
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

  void _refreshAgain() {
    if (widget.topic == null) return;

    _refreshTimer?.cancel();

    final timeLeft = _getTimeLeft();
    final user = userCache.user;
    final hasPermission = canSendMessage(user);

    _enabled = hasPermission && timeLeft > 0 &&
               !widget.topic!.isDummy && !widget.topic!.isClosed;

    if (timeLeft == 0) return;

    final duration = Duration(milliseconds: timeLeft);

    _refreshTimer = Timer(duration, () {
      if (mounted) {
        setState(() {
          final user = userCache.user;
          final hasPermission = canSendMessage(user);
          _enabled = hasPermission &&
                     !widget.topic!.isDummy && !widget.topic!.isClosed;
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

  Future<void> _sendTextMessage() async {
    try {
      if (widget.topic?.isDummy == true) {
        throw AppException('The topic has been deleted.');
      }

      if (widget.topic?.isClosed == true) {
        throw AppException('The topic has been closed.');
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _sendImageMessage() async {
    if (widget.topic == null) return;

    try {
      if (widget.topic?.isDummy == true) {
        throw AppException('The topic has been deleted.');
      }

      if (widget.topic?.isClosed == true) {
        throw AppException('The topic has been closed.');
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
      final isCtrlOrCommandPressed = HardwareKeyboard.instance.isMetaPressed ||
          HardwareKeyboard.instance.isControlPressed;

      final isEnterPressed = event.logicalKey == LogicalKeyboardKey.enter ||
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

    if (!canSendMessage(user)) {
      return 'Account restricted';
    }

    final topic = widget.topic;

    if (topic != null) {
      if (topic.isDummy) return 'Topic deleted';
      if (topic.isClosed) return 'Topic closed';
    }

    return '';
  }

  Widget _buildStatusNotice() {
    final user = userCache.user;
    String message;

    if (!canSendMessage(user)) {
      message =
          'Your account has been temporarily restricted due to multiple reports of inappropriate behavior. You cannot send messages until this restriction expires.';
    } else if (widget.topic?.isDummy == true) {
      message =
          'This topic has been deleted to protect your privacy. Go to the Topics tab to start a new one at any time';
    } else if (widget.topic?.isClosed == true) {
      message =
          'This topic has expired and will be deleted soon. Go to the Topics tab to start a new one at any time.';
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
        if (widget.topic != null && !_enabled) _buildStatusNotice(),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Container(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: const BorderRadius.all(Radius.circular(32)),
              border: Border.all(
                color: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed:
                      (!_enabled || _isUploading) ? null : _sendImageMessage,
                  icon: _isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        )
                      : Icon(
                          Icons.attach_file,
                          color: theme.colorScheme.primary,
                        ),
                  tooltip: _showText(enabledText: 'Send picture'),
                ),
                Expanded(
                  child: KeyboardListener(
                    focusNode: FocusNode(),
                    onKeyEvent: !_enabled ? null : _handleKeyEvent,
                    child: TextField(
                      enabled: _enabled,
                      focusNode: widget.focusNode,
                      minLines: 1,
                      maxLines: 12,
                      controller: _controller,
                      decoration: InputDecoration.collapsed(
                        hintText: _showText(enabledText: 'Share publicly'),
                        hintStyle: TextStyle(color: theme.colorScheme.outline),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: !_enabled ? null : _sendTextMessage,
                  icon: Icon(Icons.send, color: theme.colorScheme.primary),
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
