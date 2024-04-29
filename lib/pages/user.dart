import 'package:flutter/material.dart';

import '../services/avatar.dart';

class UserPage extends StatelessWidget {
  const UserPage({super.key});

  @override
  Widget build(BuildContext context) {
    final avatar = Avatar();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                avatar.current.emoji,
                style: const TextStyle(fontSize: 64),
              ),
              Text(avatar.current.name),
              IconButton(
                onPressed: () {
                  avatar.refresh();
                },
                icon: const Icon(Icons.refresh),
              ),
              FilledButton(
                onPressed: () {},
                child: const Text('Chat'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
