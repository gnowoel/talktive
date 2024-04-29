import 'package:flutter/material.dart';

import '../services/avatar.dart';

class UserPage extends StatelessWidget {
  const UserPage({super.key});

  @override
  Widget build(BuildContext context) {
    final avatarService = AvatarService();
    final emoji = avatarService.current;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                emoji.emoji,
                style: const TextStyle(fontSize: 64),
              ),
              Text(emoji.name),
              const SizedBox(height: 25),
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
