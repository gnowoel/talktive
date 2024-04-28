import 'dart:math';

import 'package:flutter/material.dart';
import 'package:unicode_emojis/unicode_emojis.dart';

class UserPage extends StatelessWidget {
  const UserPage({super.key});

  @override
  Widget build(BuildContext context) {
    const List<Emoji> emojis = UnicodeEmojis.allEmojis;
    Emoji emoji = emojis[Random().nextInt(emojis.length)];

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
