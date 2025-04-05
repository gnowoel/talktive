import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../helpers/helpers.dart';
import '../models/chat.dart';
import '../models/user.dart';
import '../services/fireauth.dart';
import '../services/firedata.dart';
import '../services/storage.dart';
import '../services/user_cache.dart';
import 'status_notice.dart';

class Input extends StatefulWidget {
  final FocusNode focusNode;
  final Chat chat;
  final bool chatPopulated;

  const Input({
    super.key,
    required this.focusNode,
    required this.chat,
    required this.chatPopulated,
  });

  @override
  State<Input> createState() => _InputState();
}

class _InputState extends State<Input> {
  late ThemeData theme;
  late Fireauth fireauth;
  late Firedata firedata;
  late Storage storage;
  late bool _enabled;
  late Timer timer;

  bool _isUploading = false;

  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();

    fireauth = Provider.of<Fireauth>(context, listen: false);
    firedata = Provider.of<Firedata>(context, listen: false);
    storage = Provider.of<Storage>(context, listen: false);

    _enabled = widget.chat.isNotDummy && widget.chat.isNotClosed;

    timer = Timer(Duration(milliseconds: getTimeLeft(widget.chat)), () {
      setState(() {
        _enabled = widget.chat.isNotDummy && widget.chat.isNotClosed;
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
  }

  @override
  void didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);

    timer.cancel();

    setState(() {
      _enabled = widget.chat.isNotDummy && widget.chat.isNotClosed;
    });

    timer = Timer(Duration(milliseconds: getTimeLeft(widget.chat)), () {
      setState(() {
        _enabled = widget.chat.isNotDummy && widget.chat.isNotClosed;
      });
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  Future<void> _sendTextMessage(User user) async {
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

  Future<void> _sendImageMessage(User user) async {
    await _doAction(() async {
      if (widget.chat.isDummy) {
        if (mounted) {
          ErrorHandler.showSnackBarMessage(
            context,
            AppException('The room has been deleted.'),
            severe: true,
          );
        }
        return;
      } else if (widget.chat.isClosed) {
        if (mounted) {
          ErrorHandler.showSnackBarMessage(
            context,
            AppException('The room has been closed.'),
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

  KeyEventResult _handleKeyEvent(KeyEvent event, User user) {
    if (event is KeyDownEvent) {
      final isCtrlOrCommandPressed =
          HardwareKeyboard.instance.isMetaPressed ||
          HardwareKeyboard.instance.isControlPressed;

      final isEnterPressed =
          event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.numpadEnter;

      if (isCtrlOrCommandPressed && isEnterPressed) {
        _sendTextMessage(user);
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  Widget _buildStatusNotice() {
    String message;

    if (widget.chat.isDummy) {
      message =
          'This chat has been deleted to protect your privacy. You can start a new conversation with your partner anytime.';
    } else if (widget.chat.isClosed) {
      message =
          'This chat has expired and will be automatically deleted soon. Once deleted, you can start a new conversation with your partner again.';
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.chatPopulated && !_enabled) _buildStatusNotice(),
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
                  onPressed: _enabled ? () => _sendImageMessage(user) : null,
                  icon:
                      _isUploading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 3),
                          )
                          : Icon(
                            Icons.attach_file,
                            color: theme.colorScheme.primary,
                          ),
                  tooltip: _enabled ? 'Send picture' : 'Chat closed',
                ),
                Expanded(
                  child: KeyboardListener(
                    focusNode: FocusNode(),
                    onKeyEvent:
                        _enabled
                            ? (event) => _handleKeyEvent(event, user)
                            : null,
                    child: TextField(
                      enabled: _enabled,
                      focusNode: widget.focusNode,
                      minLines: 1,
                      maxLines: 12,
                      controller: _controller,
                      decoration: InputDecoration.collapsed(
                        hintText: _enabled ? 'Enter message' : 'Chat closed',
                        hintStyle: TextStyle(color: theme.colorScheme.outline),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _enabled ? () => _sendTextMessage(user) : null,
                  icon: Icon(Icons.send, color: theme.colorScheme.primary),
                  tooltip: _enabled ? 'Send message' : 'Chat closed',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
