import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/text_message.dart';
import '../services/fireauth.dart';
import '../services/firedata.dart';
import 'bubble.dart';
import 'user_info_loader.dart';

class TextMessageItem extends StatefulWidget {
  final String chatId;
  final TextMessage message;
  final String? reporterUserId;

  const TextMessageItem({
    super.key,
    required this.chatId,
    required this.message,
    this.reporterUserId,
  });

  @override
  State<TextMessageItem> createState() => _TextMessageItemState();
}

class _TextMessageItemState extends State<TextMessageItem> {
  late Fireauth fireauth;
  late Firedata firedata;
  bool get _isBot => widget.message.userId == 'bot';

  @override
  void initState() {
    super.initState();
    fireauth = context.read<Fireauth>();
    firedata = context.read<Firedata>();
  }

  void _showUserInfo(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => UserInfoLoader(
            userId: widget.message.userId,
            photoURL: widget.message.userPhotoURL,
            displayName: widget.message.userDisplayName,
          ),
    );
  }

  void _showContextMenu(BuildContext context, Offset position) {
    final currentUser = fireauth.instance.currentUser!;
    final byMe =
        widget.reporterUserId == null
            ? widget.message.userId == currentUser.uid
            : widget.message.userId == widget.reporterUserId;

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
    if (byMe && !widget.message.recalled) {
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

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: menuItems,
    );
  }

  Future<void> _copyToClipboard(BuildContext context) async {
    // Capture the BuildContext before the async gap
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    await Clipboard.setData(
      ClipboardData(
        text:
            widget.message.recalled
                ? '- Message recalled -'
                : widget.message.content,
      ),
    );
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
      builder:
          (context) => AlertDialog(
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
                  _recallMessage(context);
                },
              ),
            ],
          ),
    );
  }

  Future<void> _recallMessage(BuildContext context) async {
    try {
      await firedata.recallMessage(widget.chatId, widget.message.id!);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Widget _buildMessageBox({
    required String content,
    bool byMe = false,
    bool isBot = false,
  }) {
    if (widget.message.recalled) {
      return Bubble(
        content: '- Message recalled -',
        byMe: byMe,
        isBot: isBot,
        recalled: true,
      );
    }

    if (widget.reporterUserId != null) {
      return Bubble(content: content, byMe: byMe, isBot: isBot);
    }

    return GestureDetector(
      onLongPressStart:
          (details) => _showContextMenu(context, details.globalPosition),
      child: Bubble(content: content, byMe: byMe, isBot: isBot),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = fireauth.instance.currentUser!;
    final byMe =
        widget.reporterUserId == null
            ? widget.message.userId == currentUser.uid
            : widget.message.userId == widget.reporterUserId;

    // Bot messages are always shown on the left
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
            child: Tooltip(
              message: widget.message.userDisplayName,
              child: Text(
                widget.message.userPhotoURL,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Flexible(
                  child: _buildMessageBox(
                    content: widget.message.content,
                    isBot: _isBot,
                  ),
                ),
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
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const SizedBox(width: 48),
          Expanded(
            child: Row(
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
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _showUserInfo(context),
            child: Tooltip(
              message: widget.message.userDisplayName,
              child: Text(
                widget.message.userPhotoURL,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
