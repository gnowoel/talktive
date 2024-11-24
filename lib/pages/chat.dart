import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  final String chatId;

  const ChatPage({super.key, required this.chatId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late ThemeData theme;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: Text(widget.chatId),
        ),
      ),
    );
  }
}
