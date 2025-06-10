import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../helpers/exception.dart';
import '../models/public_topic.dart';
import '../services/storage.dart';
import '../services/user_cache.dart';
import 'status_notice.dart';

class TopicInput extends StatefulWidget {
  final PublicTopic? topic;
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
  Timer? _refreshTimer;
  final _controller = TextEditingController();
  bool _enabled = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    storage = context.read<Storage>();
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
    
    // Insert mention at cursor position
    final newText = currentText.replaceRange(
      selection.start,
      selection.end,
      mention,
    );
    
    _controller.text = newText;
    _controller.selection = TextSelection.collapsed(
      offset: selection.start + mention.length,
    );
    
    // Focus the input field
    widget.focusNode.requestFocus();
  }

  void _refreshAgain() {
    if (widget.topic == null) return;

    _refreshTimer?.cancel();

    final timeLeft = _getTimeLeft();
    if (timeLeft == 0) return;

    _enabled = true;

    final duration = Duration(milliseconds: timeLeft);

    _refreshTimer = Timer(duration, () {
      if (mounted) {
        setState(() => _enabled = false);
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

  String _showText({required String enabledText, required bool reviewOnly}) {
    if (_enabled) {
      if (reviewOnly) {
        return 'Review only';
      } else {
        return enabledText;
      }
    }

    final topic = widget.topic;

    if (topic != null) {
      if (topic.isDummy) return 'Topic deleted';
      if (topic.isClosed) return 'Topic closed';
    }

    return '';
  }

  Widget _buildStatusNotice() {
    String message;

    if (widget.topic?.isDummy == true) {
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
    final userCache = context.watch<UserCache>();
    final user = userCache.user!;
    final reviewOnly = user.isTrainee;

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
                  onPressed: (!_enabled || reviewOnly || _isUploading)
                      ? null
                      : _sendImageMessage,
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
                  tooltip: _showText(
                    enabledText: 'Send picture',
                    reviewOnly: reviewOnly,
                  ),
                ),
                Expanded(
                  child: KeyboardListener(
                    focusNode: FocusNode(),
                    onKeyEvent:
                        (!_enabled || reviewOnly) ? null : _handleKeyEvent,
                    child: TextField(
                      enabled: _enabled && !reviewOnly,
                      focusNode: widget.focusNode,
                      minLines: 1,
                      maxLines: 12,
                      controller: _controller,
                      decoration: InputDecoration.collapsed(
                        hintText: _showText(
                          enabledText: 'Share publicly',
                          reviewOnly: reviewOnly,
                        ),
                        hintStyle: TextStyle(color: theme.colorScheme.outline),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed:
                      (!_enabled || reviewOnly) ? null : _sendTextMessage,
                  icon: Icon(Icons.send, color: theme.colorScheme.primary),
                  tooltip: _showText(
                    enabledText: 'Send message',
                    reviewOnly: reviewOnly,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
