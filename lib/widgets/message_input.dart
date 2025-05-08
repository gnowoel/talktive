import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../services/storage.dart';

class MessageInput extends StatefulWidget {
  final FocusNode focusNode;
  final Future<void> Function(String) onSendMessage;
  final Future<void> Function(String)? onSendImage;

  const MessageInput({
    super.key,
    required this.focusNode,
    required this.onSendMessage,
    this.onSendImage,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  late Storage storage;
  final _controller = TextEditingController();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    storage = context.read<Storage>();
  }

  Future<void> _sendTextMessage() async {
    try {
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
      await widget.onSendMessage(content);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _sendImageMessage() async {
    if (widget.onSendImage == null) return;

    try {
      final xFile = await ImagePicker().pickImage(
        imageQuality: 70,
        maxWidth: 1440,
        source: ImageSource.gallery,
        requestFullMetadata: false,
      );

      if (xFile == null) return;

      setState(() => _isUploading = true);

      final data = await xFile.readAsBytes();
      final path = 'topics/${xFile.name}';
      final uri = await storage.saveData(path, data);

      await widget.onSendImage!(uri);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: const BorderRadius.all(Radius.circular(32)),
          border: Border.all(color: theme.colorScheme.surfaceContainerHighest),
        ),
        child: Row(
          children: [
            if (widget.onSendImage != null)
              IconButton(
                onPressed: _isUploading ? null : _sendImageMessage,
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
                tooltip: 'Send picture',
              ),
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
              onPressed: _sendTextMessage,
              icon: Icon(Icons.share, color: theme.colorScheme.primary),
              tooltip: 'Share publicly',
            ),
          ],
        ),
      ),
    );
  }
}
