import 'package:flutter/material.dart';

class UserPage extends StatelessWidget {
  const UserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '\u{1f44c}',
                style: TextStyle(fontSize: 64),
              ),
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
