import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../helpers/helpers.dart';
import '../models/chat.dart';
import '../services/fireauth.dart';
import '../services/firedata.dart';
import '../services/storage.dart';
import '../services/user_cache.dart';
import 'status_notice.dart';

class ChatInput extends StatefulWidget {
  final FocusNode focusNode;
  final Chat chat;
  final bool chatPopulated;
  final void Function(String)? onInsertMention;

  const ChatInput({
    super.key,
    required this.focusNode,
    required this.chat,
    required this.chatPopulated,
    this.onInsertMention,
  });

  @override
  State<ChatInput> createState() => ChatInputState();
}

class ChatInputState extends State<ChatInput> {
  late ThemeData theme;
  late Fireauth fireauth;
  late Firedata firedata;
  late Storage storage;
  late UserCache userCache;
  Timer? _refreshTimer;
  final _controller = TextEditingController();
  bool _enabled = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();

    fireauth = context.read<Fireauth>();
    firedata = context.read<Firedata>();
    storage = context.read<Storage>();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
    userCache = Provider.of<UserCache>(context);
    _refreshAgain();
  }

  @override
  void didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.chat.updatedAt != oldWidget.chat.updatedAt) {
      _refreshAgain();
    }

    // Update the callback reference
    if (widget.onInsertMention != oldWidget.onInsertMention) {
      // Callback reference has changed, widget will handle this
    }
  }

  void _refreshAgain() {
    _refreshTimer?.cancel();

    final timeLeft = _getTimeLeft();
    final user = userCache.user;
    final hasPermission = canSendMessage(user);

    _enabled = hasPermission &&
        timeLeft > 0 &&
        widget.chat.isNotDummy &&
        widget.chat.isNotClosed;

    if (timeLeft == 0) return;

    final duration = Duration(milliseconds: timeLeft);

    _refreshTimer = Timer(duration, () {
      setState(() {
        final user = userCache.user;
        final hasPermission = canSendMessage(user);
        _enabled =
            hasPermission && widget.chat.isNotDummy && widget.chat.isNotClosed;
      });
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  int _getTimeLeft() {
    return widget.chat.getTimeLeft();
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
    final user = userCache.user!;

    await _doAction(() async {
      const maxLength = 1024;

      final chat = widget.chat;

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

      if (!widget.chat.isDummy && !widget.chat.isClosed) {
        _controller.clear();
        await firedata.sendTextMessage(
          chat,
          user.id,
          user.displayName!,
          user.photoURL!,
          content,
        );
      }

      if (mounted) {
        if (widget.chat.isDummy) {
          ErrorHandler.showSnackBarMessage(
            context,
            AppException('The chat has been deleted.'),
            severe: true,
          );
        } else if (widget.chat.isClosed) {
          ErrorHandler.showSnackBarMessage(
            context,
            AppException('The chat has been closed.'),
          );
        }
      }
    });
  }

  Future<void> _sendImageMessage() async {
    final user = userCache.user!;

    await _doAction(() async {
      if (widget.chat.isDummy) {
        if (mounted) {
          ErrorHandler.showSnackBarMessage(
            context,
            AppException('The chat has been deleted.'),
            severe: true,
          );
        }
        return;
      } else if (widget.chat.isClosed) {
        if (mounted) {
          ErrorHandler.showSnackBarMessage(
            context,
            AppException('The chat has been closed.'),
          );
        }
        return;
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
      final path = 'chats/${widget.chat.id}/${xFile.name}';
      final uri = await storage.saveData(path, data);

      await firedata.sendImageMessage(
        widget.chat,
        user.id,
        user.displayName!,
        user.photoURL!,
        uri,
      );
    });
  }

  Future<void> _doAction(Future<void> Function() action) async {
    try {
      await action();
    } on AppException catch (e) {
      if (mounted) {
        ErrorHandler.showSnackBarMessage(context, e);
      }
    } finally {
      if (_isUploading) {
        setState(() => _isUploading = false);
      }
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

    final chat = widget.chat;

    if (chat.isDummy) return 'Chat deleted';
    if (chat.isClosed) return 'Chat closed';

    return '';
  }

  Widget _buildStatusNotice() {
    final user = userCache.user;
    String message;

    if (!canSendMessage(user)) {
      message =
          'Your account has been temporarily restricted due to multiple reports of inappropriate behavior. You cannot send messages until this restriction expires.';
    } else if (widget.chat.isDummy) {
      message =
          'This chat has been deleted to protect your privacy. You can start a new conversation with your partner anytime.';
    } else if (widget.chat.isClosed) {
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
        if (widget.chatPopulated &&
            (!_enabled || userCache.user?.withAlert == true))
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
                  onPressed: _enabled ? _sendImageMessage : null,
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
