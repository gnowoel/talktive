import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Bubble extends StatefulWidget {
  final String content;
  final bool byMe;
  final bool isBot;

  const Bubble({
    super.key,
    required this.content,
    this.byMe = false,
    this.isBot = false,
  });

  @override
  State<Bubble> createState() => _BubbleState();
}

class _BubbleState extends State<Bubble> {
  void _showContextMenu(BuildContext context, Offset position) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: [
        PopupMenuItem(
          child: Row(
            children: [
              const Icon(Icons.copy, size: 20),
              const SizedBox(width: 8),
              const Text('Copy'),
            ],
          ),
          onTap: () => _copyToClipboard(context),
        ),
      ],
    );
  }

  Future<void> _copyToClipboard(BuildContext context) async {
    // Capture the BuildContext before the async gap
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    await Clipboard.setData(ClipboardData(text: widget.content));
    if (!mounted) return;

    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Text('Message copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final containerColor =
        widget.isBot
            ? colorScheme.secondaryContainer
            : (widget.byMe
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHigh);

    final textColor =
        widget.isBot
            ? colorScheme.onSecondaryContainer
            : (widget.byMe
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurface);

    return GestureDetector(
      onLongPressStart:
          (details) => _showContextMenu(context, details.globalPosition),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: containerColor,
        ),
        child: Text(
          widget.content,
          style: TextStyle(fontSize: 16, color: textColor),
        ),
      ),
    );
  }
}
