import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: FilledButton(
            onPressed: () {
              print('Sign In button pressed.');
            },
            child: const Text('Sign In'),
          ),
        ),
      ),
    );
  }
}
