import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../helpers/helpers.dart';
import '../models/chat.dart';
import '../models/user.dart';
import '../services/cache.dart';
import '../services/fireauth.dart';
import '../services/firedata.dart';
import '../services/storage.dart';

class Input extends StatefulWidget {
  final FocusNode focusNode;
  final Chat chat;

  const Input({
    super.key,
    required this.focusNode,
    required this.chat,
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

    timer = Timer(
      Duration(milliseconds: getTimeLeft(widget.chat)),
      () {
        setState(() {
          _enabled = widget.chat.isNotDummy && widget.chat.isNotClosed;
        });
      },
    );
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

    timer = Timer(
      Duration(milliseconds: getTimeLeft(widget.chat)),
      () {
        setState(() {
          _enabled = widget.chat.isNotDummy && widget.chat.isNotClosed;
        });
      },
    );
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
      final xFile = await ImagePicker().pickImage(
        imageQuality: 70,
        maxWidth: 1440,
        source: ImageSource.gallery,
      );

      if (xFile == null) return;

      if (!widget.chat.isDummy && !widget.chat.isClosed) {
        final chat = widget.chat;

        final file = File(xFile.path);
        final path = 'chats/${chat.id}/${xFile.name}';

        setState(() => _isUploading = true);
        if (kDebugMode) {
          await Future.delayed(Duration(seconds: 2));
        }
        final uri = await storage.saveFile(path, file);

        await firedata.sendImageMessage(
          chat,
          user.id,
          user.displayName!,
          user.photoURL!,
          uri,
        );
      }

      if (mounted) {
        if (widget.chat.isDummy) {
          ErrorHandler.showSnackBarMessage(
            context,
            AppException('The room has been deleted.'),
            severe: true,
          );
        } else if (widget.chat.isClosed) {
          ErrorHandler.showSnackBarMessage(
            context,
            AppException('The room has been closed.'),
          );
        }
      }
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
      final isCtrlOrCommandPressed = HardwareKeyboard.instance.isMetaPressed ||
          HardwareKeyboard.instance.isControlPressed;

      final isEnterPressed = event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.numpadEnter;

      if (isCtrlOrCommandPressed && isEnterPressed) {
        _sendTextMessage(user);
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select((Cache cache) => cache.user);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: const BorderRadius.all(
            Radius.circular(32),
          ),
          border: Border.all(color: theme.colorScheme.surfaceContainerHighest),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: _enabled ? () => _sendImageMessage(user!) : null,
              icon: _isUploading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                      ),
                    )
                  : Icon(
                      Icons.attach_file,
                      color: theme.colorScheme.primary,
                    ),
              tooltip: 'Send picture',
            ),
            Expanded(
              child: KeyboardListener(
                focusNode: FocusNode(),
                onKeyEvent:
                    _enabled ? (event) => _handleKeyEvent(event, user!) : null,
                child: TextField(
                  enabled: _enabled,
                  focusNode: widget.focusNode,
                  minLines: 1,
                  maxLines: 12,
                  controller: _controller,
                  decoration: InputDecoration.collapsed(
                    hintText: 'Enter message',
                    hintStyle: TextStyle(color: theme.colorScheme.outline),
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: _enabled ? () => _sendTextMessage(user!) : null,
              icon: Icon(
                Icons.send,
                color: theme.colorScheme.primary,
              ),
              tooltip: 'Send message',
            ),
          ],
        ),
      ),
    );
  }
}
