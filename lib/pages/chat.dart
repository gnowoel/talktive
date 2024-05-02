import 'package:flutter/material.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Chat'),
      ),
      body: const SafeArea(
        child: Center(
          child: Text('(empty)'),
        ),
      ),
    );
  }
}
