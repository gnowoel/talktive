import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../helpers/exception.dart';
import '../models/room.dart';
import '../services/avatar.dart';
import '../services/fireauth.dart';
import '../services/firedata.dart';

class Input extends StatefulWidget {
  final FocusNode focusNode;
  final Room room;

  const Input({
    super.key,
    required this.focusNode,
    required this.room,
  });

  @override
  State<Input> createState() => _InputState();
}

class _InputState extends State<Input> {
  late ThemeData theme;
  late Fireauth fireauth;
  late Firedata firedata;
  late Avatar avatar;

  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    fireauth = Provider.of<Fireauth>(context, listen: false);
    firedata = Provider.of<Firedata>(context, listen: false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
    avatar = Provider.of<Avatar>(context);
  }

  Future<void> _sendMessage() async {
    await _doAction(() async {
      const maxLength = 1024;

      final room = widget.room;
      final userId = fireauth.instance.currentUser!.uid;
      final userName = avatar.name;
      final userCode = avatar.code;

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

      if (!widget.room.isDeleted) {
        _controller.clear();
        await firedata.sendMessage(
          room,
          userId,
          userName,
          userCode,
          content,
        );
      }

      if (mounted) {
        if (widget.room.isDeleted) {
          ErrorHandler.showSnackBarMessage(
            context,
            AppException('The room has been deleted.'),
            severe: true,
          );
        } else if (widget.room.isClosed) {
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
    }
  }

  KeyEventResult _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final isCtrlOrCommandPressed = HardwareKeyboard.instance.isMetaPressed ||
          HardwareKeyboard.instance.isControlPressed;

      final isEnterPressed = event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.numpadEnter;

      if (isCtrlOrCommandPressed && isEnterPressed) {
        _sendMessage();
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 8, 4, 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: const BorderRadius.all(
            Radius.circular(32),
          ),
          border: Border.all(color: theme.colorScheme.surfaceContainerHighest),
        ),
        child: Row(
          children: [
            Expanded(
              child: KeyboardListener(
                focusNode: FocusNode(),
                onKeyEvent: _handleKeyEvent,
                child: TextField(
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
              onPressed: _sendMessage,
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
